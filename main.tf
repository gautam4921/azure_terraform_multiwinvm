# Introducing locals at the top of main.tf as follows
locals {
  vm_datadiskdisk_count_map = { for k in toset(var.instances) : k => var.nb_disks_per_instance }
  luns                      = { for k in local.datadisk_lun_map : k.datadisk_name => k.lun }
  datadisk_lun_map = flatten([
    for vm_name, count in local.vm_datadiskdisk_count_map : [
      for i in range(count) : {
        datadisk_name = format("datadisk_%s_disk%02d", vm_name, i)
        lun           = i
      }
    ]
  ])
}
resource "azurerm_resource_group" "rg" {
  name     = "count-test-win"
  location = "eastus"
}

# Storage account for Boot diagnostics
resource "azurerm_storage_account" "azbootdiag" {
  name                     = "azeusbootdiag010324"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_replication_type = "LRS"
  account_tier             = "Standard"
}

#Create a network security group 
resource "azurerm_network_security_group" "NSG" {
  name                = "Nsg-prod-eus"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name                       = "RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
# Public IP creation for vm
resource "azurerm_public_ip" "azpip" {
  count               = var.vm_count
  name                = "pip-${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
  depends_on          = [azurerm_resource_group.rg,]
  

}
resource "azurerm_virtual_network" "test" {
  name                = "test-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "test" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Associate subnet to network security group 
resource "azurerm_subnet_network_security_group_association" "asnsga-01" {
  subnet_id                 = azurerm_subnet.test.id
  network_security_group_id = azurerm_network_security_group.NSG.id
}

resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "winvm-nic-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.test.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azpip["${count.index}"].id
    #@public_ip_address_id        = count.index == 1 ? azurerm_public_ip.azpip01[count.index].id : null
    # Public IPs are created using azurerm_public_ip block ,Having the address in your azurerm_network_interface you could do the following using Conditional Expressions
    # url : https://stackoverflow.com/questions/65935259/terraform-add-public-ip-to-only-one-azure-vm 
    # url : https://discuss.hashicorp.com/t/how-to-output-multiple-public-ips/8323
    # network_security_group_id = [azurerm_network_security_group.example.id]
    
  }
}

#  Attach/Connect vmnic to to NSG 
#  resource "azurerm_network_interface_security_group_association" "vmnicnsga" {
#  count                     = var.vm_count
#  network_interface_id      = count.index == 1 ? azurerm_network_interface_security_group_association.vmnicnsga[count.index].id : null
#  network_security_group_id = azurerm_network_security_group.NSG.id
#  depends_on = [ azurerm_network_interface.nic,azurerm_network_security_group.NSG,azurerm_resource_group.rg ]
#  }

resource "azurerm_network_interface_security_group_association" "nsga" {
  count = var.vm_count
  #count                    = length(azurerm_network_interface.example.*.id)
  network_interface_id      = element(azurerm_network_interface.nic.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.NSG.id
  depends_on                = [var.resource_group_name, azurerm_network_interface.nic, azurerm_subnet.test]
}
# Refrence url : https://stackoverflow.com/questions/61134957/azure-associating-security-group-with-multiple-network-interfaces-and-load-balan
# for associating vm network interface to NSG Created 

resource "azurerm_windows_virtual_machine" "vm" {
  count = var.vm_count
  #name                 = "win-vm-${count.index}"
  name                  = element(var.instances, count.index)
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_B1s"
  admin_username        = "gautam"
  admin_password        = "Bangalore@123"
  network_interface_ids = [azurerm_network_interface.nic[count.index].id]
  
  os_disk {
    name                 = "win-vm-osdisk-${count.index}"
    #name                = "${each.key}-OS-DISK-00"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.azbootdiag.primary_blob_endpoint
  }
}
output "azpip01" {
  description = "PIPs of all vms provisoned"
  value       = azurerm_windows_virtual_machine.vm.*.public_ip_address
}

resource "azurerm_managed_disk" "example" {
  count                = 3
  name                 = "win-vm-${count.index + 1}-md"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10
}

resource "azurerm_virtual_machine_data_disk_attachment" "example" {
  count              = 3
  managed_disk_id    = azurerm_managed_disk.example[count.index].id
  virtual_machine_id = azurerm_windows_virtual_machine.vm[count.index].id
  lun                = "10"
  caching            = "ReadWrite"
}
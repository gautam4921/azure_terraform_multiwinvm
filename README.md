# azure_terraform_multiwinvm
Creating multi azure windows vm using terraform 
D:\Terraform Projects\Resource_group>terraform state list            
azurerm_managed_disk.example[0]
azurerm_managed_disk.example[1]
azurerm_managed_disk.example[2]
azurerm_network_interface.nic[0]
azurerm_network_interface.nic[1]
azurerm_network_interface.nic[2]
azurerm_network_interface_security_group_association.nsga[0]
azurerm_network_interface_security_group_association.nsga[1]
azurerm_network_interface_security_group_association.nsga[2]
azurerm_network_security_group.NSG
azurerm_public_ip.azpip[0]
azurerm_public_ip.azpip[1]
azurerm_public_ip.azpip[2]
azurerm_resource_group.rg
azurerm_storage_account.azbootdiag
azurerm_subnet.test
azurerm_subnet_network_security_group_association.asnsga-01
azurerm_virtual_machine_data_disk_attachment.example[0]
azurerm_virtual_machine_data_disk_attachment.example[1]
azurerm_virtual_machine_data_disk_attachment.example[2]
azurerm_virtual_network.test
azurerm_windows_virtual_machine.vm[0]
azurerm_windows_virtual_machine.vm[1]
azurerm_windows_virtual_machine.vm[2]

Outputs:

azpip01 = [
  "40.114.92.97",
  "40.117.231.227",
  "13.82.218.124",
]

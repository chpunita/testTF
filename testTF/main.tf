resource "azurerm_resource_group" "rg" {
  #for_each = var.myinfra_config
  name     =  var.myinfra_config["vms1"].resource_group_name
  location = var.myinfra_config["vms1"].resource_group_location
}

resource "azurerm_storage_account" "storage" {
  #for_each = var.myinfra_config
  name                     = var.myinfra_config["vms1"].storage_account
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = var.myinfra_config["vms1"].account_tier
  account_replication_type = var.myinfra_config["vms1"].account_replication_type
  tags = {
    environment = "staging"
  }
}

resource "azurerm_storage_container" "mycont" {
  depends_on = [ azurerm_storage_account.storage]
  name                  = "mycontainer"
  storage_account_id    = azurerm_storage_account.storage.id
  container_access_type = "private"
}

resource "azurerm_virtual_network" "vnet" {
  for_each = var.myinfra_config
  depends_on = [ azurerm_storage_account.storage]
  name                = each.value.vnet_name
  address_space       = each.value.address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    environment = "staging"
  }
}

resource "azurerm_subnet" "subnet" {
  for_each = var.myinfra_config
  name                 = each.value.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  #virtual_network_name = azurerm_virtual_network.vnet.name
  virtual_network_name = "${each.value.vnet_name}"
  address_prefixes     = each.value.address_prefixes
}

resource "azurerm_network_interface" "nic" {
  for_each = var.myinfra_config
  depends_on = [azurerm_subnet.subnet]
  name                = each.value.nic_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = each.value.ip_name
    #subnet_id                     = azurerm_subnet.subnet.id
    subnet_id                     = azurerm_subnet.subnet[each.key].id
    private_ip_address_allocation = each.value.private_ip_address_allocation
    #public_ip_address_id          = azurerm_public_ip.pip.id
    public_ip_address_id          = azurerm_public_ip.pip[each.key].id
  }
}

resource "azurerm_network_security_group" "nsg" {
  for_each = var.myinfra_config
  name                = each.value.nsg_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


resource "azurerm_public_ip" "pip" {
  for_each = var.myinfra_config
  name                = each.value.public_ip_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = each.value.allocation_method
  sku                 = "Standard"
}


resource "azurerm_network_interface_security_group_association" "nsgassoc" {
  depends_on = [ azurerm_network_interface.nic, azurerm_network_security_group.nsg ]
  for_each = var.myinfra_config
  #network_interface_id      = azurerm_network_interface.nic.id
  network_interface_id = azurerm_network_interface.nic[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
  #network_security_group_id = azurerm_network_security_group.nsg.id
}


resource "azurerm_linux_virtual_machine" "myvm" {
  for_each = var.myinfra_config
   depends_on = [ azurerm_network_interface.nic ] 
   name = each.value.vm_name
   resource_group_name      = azurerm_resource_group.rg.name
   location                 = azurerm_resource_group.rg.location
   size = each.value.vm_size
   admin_username = each.value.admin_username
   admin_password = each.value.admin_password
   network_interface_ids = [azurerm_network_interface.nic[each.key].id,]
  disable_password_authentication = false
 
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
 
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
 
}

# resource "azurerm_virtual_machine" "vm" {
#   depends_on = [azurerm_network_interface.nic]
#   name                  = each.value.vm_name"]
#   location              = azurerm_resource_group.rg.location
#   resource_group_name   = azurerm_resource_group.rg.name
#   network_interface_ids = [azurerm_network_interface.nic.id]
#   vm_size               = each.value.vm_size"]

#   delete_os_disk_on_termination = true
 
   
#   storage_os_disk {
#     name              = "myosdisk2"
#     caching           = "ReadWrite"
#     create_option     = "FromImage"
#     #managed_disk_id   = "/subscriptions/e614c005-fbcf-4e74-809b-f099ff6f5246/resourceGroups/localrepo_rg2/providers/Microsoft.Compute/disks/myosdisk1"
#     #os_type              = "Linux"
#     managed_disk_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "0001-com-ubuntu-server-jammy"
#     sku       = "22_04-lts"
#     version   = "latest"
#   }

#   #disable_password_authentication = false
  
#   # os profile is not needed when attaching an existing OS disk
#   os_profile {
#     computer_name  = "hostname"
#     admin_username = var.myinfra_config.admin_username
#     admin_password = var.myinfra_config.admin_password
#   }

#   os_profile_linux_config {
#     disable_password_authentication = false
#   }
#   tags = {
#     environment = "staging"
#   }
# }




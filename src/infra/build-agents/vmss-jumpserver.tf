# Deploys a scale set of jump server which can be used to manually connect against the private resources like AKS for debugging etc.
# We don't really expect to ever need more than one instance (mostly it can probably be scaled to 0), but using a VMSS makes it much easier to dynamically provision them and to keep them up-to-date

resource "azurerm_linux_virtual_machine_scale_set" "jumpserver" {
  name                = "${local.prefix}-jumpservers-vmss"
  resource_group_name = azurerm_resource_group.deployment.name
  location            = azurerm_resource_group.deployment.location
  sku                 = "Standard_B2s"
  instances           = 1 # We deploy 1 instance to start with. All other scaling (up or down) is expected to happen manually through the Portal as needed

  overprovision          = false
  single_placement_group = false

  admin_username = "adminuser"
  admin_password = azurerm_key_vault_secret.vmsecret.value

  disable_password_authentication = false

  custom_data = base64encode(data.local_file.cloudinit.content)

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "${local.prefix}-jumpserver-vmss-nic"
    primary = true

    ip_configuration {
      name      = "${local.prefix}-jumpserver-vmss-ipconfig"
      primary   = true
      subnet_id = azurerm_subnet.jumpservers_vmss.id
    }
  }

  boot_diagnostics {
    storage_account_uri = null
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to instance count as this can be manually scaled up and down as needed
      instances
    ]
  }
}

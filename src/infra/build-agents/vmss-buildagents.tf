resource "azurerm_linux_virtual_machine_scale_set" "buildagents" {
  name                = "${local.prefix}-buildagents-vmss"
  resource_group_name = azurerm_resource_group.deployment.name
  location            = azurerm_resource_group.deployment.location
  sku                 = "Standard_F8s_v2" # If you want to change this to a different SKU size, you need to check if this supports Ephemeral OS disks. Optionally, you can also disabled Ephemeral disks below
  instances           = 1                 # We deploy 1 instance to start with. All other scaling (up or down) will be later controlled by Azure DevOps

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
    caching              = "ReadOnly" # = Ephemeral disk

    diff_disk_settings {
      option = "Local" # = Ephemeral disk
    }
  }

  network_interface {
    name    = "${local.prefix}-buildagents-vmss-nic"
    primary = true

    ip_configuration {
      name      = "${local.prefix}-buildagents-vmss-ipconfig"
      primary   = true
      subnet_id = azurerm_subnet.buildagents_vmss.id
    }
  }

  boot_diagnostics {
    storage_account_uri = null
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes to extension, tags, instances and
      # others as they're managed by Azure DevOps
      extension,
      tags,
      automatic_instance_repair,
      automatic_os_upgrade_policy,
      instances,
    ]
  }
}

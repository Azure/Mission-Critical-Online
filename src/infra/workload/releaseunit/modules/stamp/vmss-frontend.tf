resource "azurerm_linux_virtual_machine_scale_set" "stamp_frontend" {
  name                = "${local.prefix}-${local.location_short}-fe-vmss"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name
  sku                 = var.vmss_sku_size
  instances           = var.vmss_replicas_autoscale_minimum

  admin_username                  = "adminuser"
  disable_password_authentication = true

  zones = ["1", "2", "3"]

  admin_ssh_key {
    username   = "adminuser"
    public_key = trimspace(tls_private_key.vmss_frontend_private_key.public_key_openssh)
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  custom_data = base64encode(data.template_file.cloudinit_frontend.rendered)

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.private.primary_blob_endpoint
  }

  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name      = "internal-fe"
      primary   = true
      subnet_id = azurerm_subnet.compute_frontend.id
      application_gateway_backend_address_pool_ids = [
        "${azurerm_application_gateway.stamp.id}/backendAddressPools/${azurerm_virtual_network.stamp.name}-beap"
      ]
    }
  }

  lifecycle {
    ignore_changes = [
      instances
    ]
  }
}

# load cloudinit.conf
data "template_file" "cloudinit_frontend" {
  template = file("${path.module}/cloudinit-frontend.conf")

  vars = {}
}

# generate private key for vmss ssh access
resource "tls_private_key" "vmss_frontend_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# autoscale configuration for frontend vmss
resource "azurerm_monitor_autoscale_setting" "stamp_frontend" {
  name                = "${local.prefix}-${local.location_short}-fe-vmss-autoscale"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.stamp_frontend.id

  profile {
    name = "defaultProfile"

    capacity {
      default = var.vmss_replicas_autoscale_minimum # set default to minimum
      minimum = var.vmss_replicas_autoscale_minimum
      maximum = var.vmss_replicas_autoscale_maximum
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.stamp_frontend.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 75
        metric_namespace   = "microsoft.compute/virtualmachinescalesets"
        dimensions {
          name     = "AppName"
          operator = "Equals"
          values   = ["App1"]
        }
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.stamp_frontend.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 25
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = true
      send_to_subscription_co_administrator = true
      custom_emails                         = ["admin@contoso.com"]
    }
  }
}
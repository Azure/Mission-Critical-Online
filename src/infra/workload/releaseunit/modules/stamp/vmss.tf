resource "azurerm_linux_virtual_machine_scale_set" "stamp" {
  name                = "${local.prefix}-${local.location_short}-vmss"
  location            = azurerm_resource_group.stamp.location
  resource_group_name = azurerm_resource_group.stamp.name
  sku                 = var.vmss_sku_size
  instances           = var.vmss_replicas_autoscale_minimum

  admin_username                  = "adminuser"
  disable_password_authentication = true

  zones = ["1", "2", "3"]

  admin_ssh_key {
    username   = "adminuser"
    public_key = trimspace(tls_private_key.vmss_private_key.public_key_openssh)
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

  custom_data = base64encode(data.template_file.cloudinit.rendered)

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.private.primary_blob_endpoint
  }

  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.compute.id
    }
  }

  lifecycle {
    ignore_changes = [
      instances
    ]
  }
}

# load cloudinit.conf
data "template_file" "cloudinit" {
  template = file("${path.module}/cloudinit.conf")

  vars = {}
}

# generate private key for vmss ssh access
resource "tls_private_key" "vmss_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
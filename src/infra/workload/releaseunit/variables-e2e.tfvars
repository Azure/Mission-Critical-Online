# Variable file for E2E env
vnet_address_space = "10.1.0.0/18" # /18 allows for up to 4 stamps

vmss_sku_size                   = "Standard_D2s_v3" # Adjust as needed for your workload
vmss_replicas_autoscale_minimum = 2
vmss_replicas_autoscale_maximum = 3

event_hub_thoughput_units     = 1
event_hub_enable_auto_inflate = false

ai_adaptive_sampling = true # enables/disables adaptive sampling for Application Insights; disabled means that 100 % of telemetry will be collected

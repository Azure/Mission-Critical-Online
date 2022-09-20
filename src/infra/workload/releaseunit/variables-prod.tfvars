# Variable file for PROD env
vnet_address_space = "10.1.0.0/16" # /16 allows for up to 16 stamps

vmss_sku_size                   = "Standard_D2s_v3" # Adjust as needed for your workload
vmss_replicas_autoscale_minimum = 2
vmss_replicas_autoscale_maximum = 3

event_hub_thoughput_units         = 1
event_hub_enable_auto_inflate     = true
event_hub_auto_inflate_maximum_tu = 10

ai_adaptive_sampling = false # enables/disables adaptive sampling for Application Insights; disabled means that 100 % of telemetry will be collected
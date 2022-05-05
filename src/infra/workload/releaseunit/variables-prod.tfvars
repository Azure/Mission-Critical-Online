# Variable file for PROD env
vnet_address_space = "10.1.0.0/16" # /16 allows for up to 16 stamps

aks_system_node_pool_sku_size          = "Standard_F8s_v2" # be aware of the disk size requirement for emphemral disks. Thus we currently cannot use a smaller SKU
aks_system_node_pool_autoscale_minimum = 3
aks_system_node_pool_autoscale_maximum = 9

event_hub_thoughput_units         = 1
event_hub_enable_auto_inflate     = true
event_hub_auto_inflate_maximum_tu = 10

ai_adaptive_sampling = false # enables/disables adaptive sampling for Application Insights; disabled means that 100 % of telemetry will be collected
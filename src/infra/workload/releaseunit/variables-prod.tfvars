# Variable file for PROD env
vnet_address_space = "10.1.0.0/16" # /16 allows for up to 16 stamps

aks_system_node_pool_sku_size          = "Standard_D2s_v3" # Adjust as needed for your workload
aks_system_node_pool_autoscale_minimum = 3
aks_system_node_pool_autoscale_maximum = 6

aks_user_node_pool_sku_size          = "Standard_F8s_v2" # Adjust as needed for your workload
aks_user_node_pool_autoscale_minimum = 3
aks_user_node_pool_autoscale_maximum = 12

apim_sku = "Premium_1"

event_hub_thoughput_units         = 1
event_hub_enable_auto_inflate     = true
event_hub_auto_inflate_maximum_tu = 10

ai_adaptive_sampling = false # enables/disables adaptive sampling for Application Insights; disabled means that 100 % of telemetry will be collected
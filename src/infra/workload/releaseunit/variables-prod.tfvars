# Variable file for PROD env
vnet_address_space = "10.1.0.0/21" # /21 allows for up to 4 stamps

aks_node_size                   = "Standard_F8s_v2" # be aware of the disk size requirement for emphemral disks. Thus we currently cannot use a smaller SKU
aks_node_pool_autoscale_minimum = 3
aks_node_pool_autoscale_maximum = 9

event_hub_thoughput_units         = 1
event_hub_enable_auto_inflate     = true
event_hub_auto_inflate_maximum_tu = 10

# Self-hosted agent pools with Azure DevOps

This part of the repository contains the required Terraform templates to deploy the infrastructure used for self-hosted Azure DevOps build agent pools, based on Virtual Machine Scale Sets (VMSS).

Furthermore, it deploys a VMSS which is used as Jump Servers to connect to the private resources, such as private AKS clusters, for debugging etc. To connect to the Jump Servers, Azure Bastion is used. This way, even the Jump Servers do not require any public IPs.

---

[Back to documentation root](/docs/README.md)

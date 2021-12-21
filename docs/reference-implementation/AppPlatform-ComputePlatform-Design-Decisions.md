# Compute Platform design decisions

## Compute layer

**Azure Kubernetes Service (AKS)** is used as the compute platform as it is most versatile and as Kubernetes is the de-facto compute platform standard for modern applications, both inside and outside of Azure.

AlwaysOn uses Linux-only clusters as there is no requirement for any Windows-based containers and Linux is the more mature platform in terms of Kubernetes.

Furthermore, AKS provides support for Availability Zone-spanning node pools.

---
[AlwaysOn - Full List of Documentation](/docs/README.md)

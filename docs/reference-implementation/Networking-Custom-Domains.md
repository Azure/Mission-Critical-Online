# Custom Domain support

AlwaysOn fully supports the use of custom domain names e.g. `contoso.com`. In the [Terraform reference implementation](/src/infra/workload/README.md), custom domains can be optionally used for both `int` and `prod` environments. For E2E environments, custom domains can also be added, however, it was decided not to use custom domain names in the reference implementation owing to the short-lived nature of E2E coupled with the increased deployment time when using custom domains with the encompassing SSL certificate in Front Door.

To enable full automation of the deployment, the custom domain is expected to be managed through an Azure DNS Zone. The infrastructure deployment pipeline dynamically creates CNAME records in the Azure DNS zone and maps these automatically to the Azure Front Door instance. Azure DNS zone also enables the Front Door-managed SSL certificates so that there is no need for manual certificate renewals on Front Door.

For `prod` the default domain will be `www.contoso.com`. For `int` and other pre-prod environments, it is suggested that sub-domains such as `int.contoso.com` are used. To keep the access separation these sub-domains should reside in their own Azure DNS zones within the respective subscriptions. For consistency the entry points are formatted similar to `www.int.contoso.com`. For E2E environments which use a custom domain name, it is suggested to use the `sbx` ("sandbox") sub-domain so that the resulting entry point will be similar to `env123.sbx.contoso.com`.

Environments which are not provisioned with custom domains can be accessed through the default Front Door endpoint, for example `env123.azurefd.net`.

> Note: On the cluster ingress controllers, custom domains are not used in either case; instead an Azure-provided DNS name such as _[prefix]-cluster.[region].cloudapp.azure.com_ is used with Let's Encrypt enabled to issue free SSL certificates for those endpoints.

---
[AlwaysOn - Full List of Documentation](/docs/README.md)

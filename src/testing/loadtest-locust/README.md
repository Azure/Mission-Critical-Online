# Load Testing with Locust

[locust.io](https://locust.io) is an easy to use, scriptable and scalable open source load and performance testing tool.

The AlwaysOn reference implementation leverages Locust in two different ways:

* **Embedded** is used to automatically run load tests as part of the end-to-end (e2e) validation pipeline using a fixed set of parameters. This is intended to compare each e2e run (currently manually) and the changes that were made against a given performance baseline.

* **Standalone** is a separate pipeline that spins up a Locust deployment with a WebUI to conduct customized load tests on-demand.

## Infrastructure

The standalone as well as the embedded Locust implementation used for AlwaysOn consists of one master node and one or more worker nodes distributed across multiple Azure regions. The worker nodes execute the load testing tasks and communicate with the master node on port `5557/TCP`. The master node is orchestrating the worker nodes, gathering the load test data and (in standalone-mode only) hosting a web interface on port `8089/TCP` to conduct and monitor load tests.

All nodes are represented as individual container instances, hosted on Azure Container Instances (ACI) and are deployed via Terraform. The Terraform definition is stored in the `src/infra/loadtest-locust` directory.

![locust architecture](screenshots/locust_architecture.png)

### Standalone

The standalone environment can be scaled-up and down via the **Azure.AlwaysOn Deploy Locust (standalone)** pipeline in Azure DevOps. The number of worker nodes can be defined for each individual pipeline run:

![locust pipeline dialog options](screenshots/locust_pipeline_dialog.png)

To scale the infrastructure down you can simply execute the pipeline with "Number of Worker Nodes" set to zero. Setting the number of workers to `0` will tear down all workers and will remove the master node as well.

Further configuration changes can by done by modifying the `variables.tf` file. Here are the most relevant configuration options:

* `locust_worker_locations` is a list of datacenter regions the workers will be spread across
* `locust_version` contains the locust image and tag e.g. `locustio/locust:2.2.2`

The additional infrastructure consisting of an Azure Storage Account hosting the `locustfile.py` test definition as well as an Azure Key Vault hosting the randomly generated password used to access the locust web interface. Those two resources will remain, even if the Locust workers are scaled down to zero.

Check out [Globally distributed load tests in Azure with Locust](https://medium.com/microsoftazure/globally-distributed-load-tests-in-azure-with-locust-aeb3a365cd60?source=friends_link&sk=af2c76b46c2cfebd4c972106c9ecbadc) to learn more about Locust on ACI.

### Embedded

The embedded version of Locust is "embedded" into the **Azure.AlwaysOn E2E Release** pipeline and can be enabled by selecting "Run embedded load testing" when running the pipeline.

![Run E2E pipeline with Load Test](screenshots/locust_run_e2e_pipeline.png)

This results in an additional pipeline stage:

![Embedded locust pipeline stage](screenshots/locust_embedded_stage.png)

And uploads the load test results at the end at the end of each successful run as pipeline artifacts:

![Locust pipeline artifacts](screenshots/locust_embedded_artifacts.png)

## Authentication

Most of the REST methods on the AlwaysOn API are protected with authentication. In order to call the API and run tests, Locust needs to present the `Authorization: Bearer XXX` HTTP header, containing a valid access token. Current implementation is using the `aad_b2c_auth` function and environmental variables, which need to be present on worker nodes.

```python
    def aad_b2c_auth(self):
        # Configuration of authentication - these values should reflect the Azure B2C tenant used by the load test target.
        tenant = os.environ["TENANT_NAME"]
        ropc_policy = os.environ["ROPC_POLICY_NAME"]
        client_id = os.environ["CLIENT_ID"]
        scope = f"https://{tenant}.onmicrosoft.com/{client_id}/Games.Access"

        url = f'https://{tenant}.b2clogin.com/{tenant}.onmicrosoft.com/{ropc_policy}/oauth2/v2.0/token?client_id={client_id}&username={self.username}&password={self.password}&grant_type=password&tenant={tenant}.onmicrosoft.com&scope={scope}'

        response = self.client.post(url, name="Get access token")
        self.access_token = json.loads(response._content)['access_token']
        self.headers = {'Authorization': 'Bearer ' + self.access_token}
        logging.info(f"(aad_b2c_auth) Fetched access token for user {self.username}")
```

The **default access token expiration is 60 minutes** by AAD. When the APIs respond with a 401-Unauthenticated error, Locust attempts to acquire a new token from AAD.

See [Authentication](/docs/reference-implementation/AppDesign-Application-Design.md#Authentication) to understand how Azure AD B2C is set up and what the configuration values mean. We're using the "headless access" method with a list of pre-generated testing users.

Testing user accounts need to be present in the B2C tenant before running the test. Then all accounts are stored in the `/src/config/identity/test-users-<tenant>.csv` file and picked randomly during the test. Every tenant (dev, prod) can have a different set of testing users (the reference implementation has 1000 accounts for dev and only a handful for prod). The load tests expects all users to have the same password. The password needs to be stored in the corresponding environment [variable group](/.ado/pipelines/README.md#variable-groups) in Azure DevOps in a variable named `loadtestUserPassword`.

The test-users file is a simple CSV in the following format:

```
username,userId
```

For example:

```
loadtester-0@demo.always-on.app,ab392890-27f6-40d0-b1de-11079a01943e
loadtester-1@demo.always-on.app,e2a72251-db24-47c4-a5aa-0ae3a925b4d9
loadtester-2@demo.always-on.app,47b26fd7-bd20-474f-82e4-9ea1696b2b1a
loadtester-3@demo.always-on.app,c4edc75f-afb6-4ba6-9a4e-9d955e026e03
```

All testing user accounts should be low-privilege.

## Load Testing

All tests are defined in the [`locustfile.py`](./locustfile.py) Python file. They're defined as a sequence of API calls - each test user gets an access token, plays an AI game, sends a full game result, requests their own player statistics and requests their own game results.

Locust supports weight specification on individual tasks, so the test is configured in a way that sending new game results is more frequent than fetching statistics, to reflect realistic usage pattern.

The `locusfile.py` Python file is automatically uploaded into the File Share of a dedicated Azure Storage Account:

![locustfile.py stored in a dedicated Azure Storage Account](screenshots/locustfile_storageaccount.png)

From there it is mounted into the worker and master container instances:

![locustfile.py mounted and used in master](screenshots/locustfile_storageaccount_master.png)

Here an example with one master and two worker containers:

![Resource Group with master and worker containers](screenshots/locust_master_and_workers.png)

## Locust Web Interface

The locust web interface is only available in the Standalone-version, it is hosted by the master container instance on port `8089`. It is protected with basic web-auth, the password is randomly generated and stored in Azure Key Vault. Our pipeline will return the public DNS FQDN of our master node at the end of each successful pipeline run.

> **Important!** To login to the locust web interface, you have to retrieve the password from Azure Key Vault. The **username** is always **locust**.

![locust web interface](screenshots/locust_loadtesting_webinterface1.png)

It allows you to specify a **Number of total users to simulate** as well as the **Spawn rate** (users spawned/per second).

![locust web interface running a test](screenshots/locust_loadtesting_webinterface2.png)

![locust web interface diagrams while running a test](screenshots/locust_loadtesting_webinterface3.png)

---

[Back to documentation root](/docs/README.md)

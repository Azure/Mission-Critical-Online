# Load testing with Azure Load Test Service (MALT)

Azure Mission-Critical uses the Microsoft Azure Load Test Service (MALT) for load testing. MALT is a Apache JMeter-based managed service and is implemented as a standalone as well as as a pipeline-embedded solution in Azure Mission-Critical.

Standalone creates the Load test infrastructure, creates a test and uploads the JMeter load test definition created and optimized for the Azure Mission-Critical sample application and its APIs. 

![MALT Standalone pipeline](screenshots/malt_standalone_pipeline.png)

The load test target FQDN can be either specified at pipeline runtime or later by modifying the test definition via Azure Portal:

![MALT Standalone pipeline options](screenshots/malt_standalone_pipeline_options.png)

The embedded implementation is part of the end-to-end (e2e) pipeline and can be easily leveraged by checking the "Run load test" checkbox.

![MALT Embedded pipeline options](screenshots/malt_embedded_pipeline_options.png)

---

[Back to documentation root](/docs/README.md)

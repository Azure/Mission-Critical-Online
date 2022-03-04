# Unit tests

The Azure Mission-Critical online reference implementation uses NUnit for unit testing the .NET Core part, but any other framework could be chosen as well (MSTest, xUnit). We developed only a handful of sample unit tests to demonstrate how they would be plugged into the whole development & deployment process.

Unit tests are executed automatically by Azure DevOps before container builds. If any test fails, the pipeline will stop and build & deployment will not proceed.

---

[Back to documentation root](/docs/README.md)

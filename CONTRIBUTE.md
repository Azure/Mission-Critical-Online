# How to Contribute to AlwaysOn

## Content

The structure of the AlwaysOn repository is broken down into three overarching directories:

* `/docs/` contains the majority of AlwaysOn documentation, covering the architectural framework and design approach as well as detailed documentation to accompany the reference implementation.
* `/src/` contains all source code and technical artifacts for the reference implementation along with low level implementation documentation.
* `/.ado/pipelines` contains the Azure DevOps pipelines to build and deploy the core reference implementation.

## Content Changes and Pull Requests

To add or edit content within the AlwaysOn repository, please take a fork of the repository to iterate on changes before subsequently opening a Pull Request (PR) to get your forked branch merged into the main branch for the AlwaysOn repository. Your PR will be reviewed by the core engineering team for the AlwaysOn project, and once approved, your content accessible to everybody.

> **Important!** Please make sure that your PR is focused on a specific area of AlwaysOn to facilitate a targeted review, as this will speed up the process to get your changes merged into our repository.

## Documentation Conventions

* Overarching topics concerning the AlwaysOn architecture, design principles, design decisions, and cross-component integration are documented as separate markdown documents within the `/docs/` directory.

* Each source code component within the reference implementation has it's own `README.md` file which explains how that particular component works, how it is supposed to be used, and how it may interact with other aspects of the AlwaysOn solution.
  * Within the `main` branch, each `README.md` file must accurately represent the state of the associated component which will serve as a core aspect of PR reviews. Any modifications to source components must therefore be reflected in the documentation as well.

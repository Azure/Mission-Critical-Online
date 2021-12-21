# GitHub Action-based CI/CD implementation

Next to the Azure DevOps-based build and deployment pipelines (CI/CD), we also started to implement the same tasks using GitHub Actions.

However, it was decided to focus on one reference implementation for now and Azure DevOps (ADO) Pipelines was chosen. The reasons for this are laid out in the [DevOps Design Decisions](./DevOps-Design-Decisions.md) article.

The GitHub Action workflows were fully functional as of April 2021 to build and deploy the entire solution. However, it was yet lacking more thought-out orchestration or approval steps. The workflows are archived in a separate branch and might be picked up again at a later time: https://github.com/Azure/AlwaysOn/tree/archive/devops-github-actions/.github/workflows

---
[AlwaysOn - Full List of Documentation](/docs/README.md)

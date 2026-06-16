# DEVOPS-REQUIREMENTS.md

# Overview

This repository is part of a training course.

The course is structured as a sequence of independent Git repositories:

```text
azure01-...
azure02-...
azure03-...
azure04-...
azure05-...
```

Each repository represents the completed source code for a course section.

Repositories are created by copying the previous repository and continuing development.

The objective of this task is to create a complete deployment and release system suitable for this workflow.

The solution must remain simple and course-friendly.

Do not introduce enterprise complexity.

---

# Current State

The current repository contains:

```text
apps/
infra/
scripts/
```

and currently deploys:

- Azure Storage Account
- Static Website Hosting
- Custom Domain
- HTTPS

using:

- Bicep
- Azure CLI
- GitHub Actions (to be added)
- pnpm

The current deployment model supports a single environment.

---

# Required End State

The repository must support:

```text
Development
Testing
Staging
Production
```

using:

```text
Git branches
+
Azure Resource Groups
+
GitHub Actions
```

---

# Branch Model

Create four permanent branches:

```text
main
testing
staging
production
```

Branch purposes:

| Branch     | Purpose              |
| ---------- | -------------------- |
| main       | Active development   |
| testing    | Testing deployment   |
| staging    | Product owner review |
| production | Public release       |

---

# Release Flow

Promotions occur only in one direction:

```text
main
  ↓
testing
  ↓
staging
  ↓
production
```

No direct deployment from main.

No deployment from feature branches.

---

# Release Scripts

Create scripts:

```bash
pnpm release:testing
pnpm release:staging
pnpm release:production
```

Behaviour:

## release:testing

Promote:

```text
main -> testing
```

Push testing branch.

GitHub Actions deploys testing.

---

## release:staging

Promote:

```text
testing -> staging
```

Push staging branch.

GitHub Actions deploys staging.

---

## release:production

Promote:

```text
staging -> production
```

Push production branch.

GitHub Actions deploys production.

---

# Azure Environment Model

Use a single Azure subscription.

Create three independent environments.

---

## Testing

Resource Group:

```text
all-checks-out-testing-rg
```

URL:

```text
testing.all-checks-out.com
```

---

## Staging

Resource Group:

```text
all-checks-out-staging-rg
```

URL:

```text
staging.all-checks-out.com
```

---

## Production

Resource Group:

```text
all-checks-out-production-rg
```

URL:

```text
all-checks-out.com
```

---

# Isolation Requirements

Each environment must have its own:

- resource group
- storage account
- static website
- configuration

No runtime resources should be shared.

---

# Environment Configuration

Introduce environment-aware configuration.

Example:

```text
environments/
  testing.json
  staging.json
  production.json
```

or equivalent.

The deployment system must know:

- environment name
- resource group
- Azure region
- application name
- domain name

Avoid hard-coded values.

---

# GitHub Actions

Create workflows that automatically deploy when code is pushed.

---

## Testing Deployment

Trigger:

```text
testing branch
```

Deploy:

```text
all-checks-out-testing-rg
```

URL:

```text
testing.all-checks-out.com
```

---

## Staging Deployment

Trigger:

```text
staging branch
```

Deploy:

```text
all-checks-out-staging-rg
```

URL:

```text
staging.all-checks-out.com
```

---

## Production Deployment

Trigger:

```text
production branch
```

Deploy:

```text
all-checks-out-production-rg
```

URL:

```text
all-checks-out.com
```

---

# Deployment Responsibilities

Each deployment workflow must:

1. Login to Azure.
2. Deploy infrastructure via Bicep.
3. Build UI.
4. Upload UI.
5. Configure static website.
6. Report deployed URL.

---

# Infrastructure Deployment Scripts

Create:

```bash
pnpm deploy:testing
pnpm deploy:staging
pnpm deploy:production
```

These should perform the same deployment locally that GitHub Actions performs remotely.

---

# What-If Scripts

Create:

```bash
pnpm whatif:testing
pnpm whatif:staging
pnpm whatif:production
```

Use Azure What-If deployment mode.

---

# Destroy Scripts

The system must support complete environment removal.

---

## Testing

```bash
pnpm destroy:testing
```

Deletes:

```text
all-checks-out-testing-rg
```

---

## Staging

```bash
pnpm destroy:staging
```

Deletes:

```text
all-checks-out-staging-rg
```

---

## Production

```bash
pnpm destroy:production
```

Deletes:

```text
all-checks-out-production-rg
```

Production deletion must require an explicit confirmation prompt.

Example:

```text
Type DELETE-PRODUCTION to continue:
```

---

# DNS Requirements

The project currently uses Cloudflare.

Continue using Cloudflare.

Document every DNS record required.

Expected records:

```text
testing.all-checks-out.com
staging.all-checks-out.com
all-checks-out.com
```

Document:

- record type
- target hostname
- SSL requirements
- Cloudflare settings

---

# HTTPS Requirements

All environments must support:

```text
HTTPS
```

No HTTP-only deployments.

HTTPS should be automatically configured where possible.

Document any manual steps required.

---

# Repository Bootstrap Script

This course uses one repository per section.

When a repository is copied:

```text
azure03 -> azure04
azure04 -> azure05
```

a developer should be able to initialise a completely new repository using a single command.

---

## Required Script

Create:

```bash
pnpm repo:init
```

or equivalent.

---

## Behaviour

If:

```text
.git
```

already exists:

Fail immediately.

---

Otherwise:

1. Initialise Git.
2. Create main branch.
3. Create first commit.
4. Create testing branch.
5. Create staging branch.
6. Create production branch.

Result:

```text
main
testing
staging
production
```

---

## Optional Remote Setup

Support:

```bash
pnpm repo:init <github-url>
```

If a URL is supplied:

- add remote origin
- push all branches

---

# Safety Requirements

Never automatically deploy to production.

Only:

```bash
pnpm release:production
```

may trigger production deployment.

---

# Documentation

Create:

```text
docs/
```

containing:

## Branch Strategy

Explain:

```text
main
testing
staging
production
```

---

## Release Process

Explain:

```bash
pnpm release:testing
pnpm release:staging
pnpm release:production
```

---

## Deployment Process

Explain:

- local deployment
- GitHub Actions deployment

---

## Environment Architecture

Explain:

- testing
- staging
- production

Include diagrams.

---

## Destroy Process

Explain:

```bash
pnpm destroy:testing
pnpm destroy:staging
pnpm destroy:production
```

---

# Simplicity Requirement

This is a course project.

Do not introduce:

- Pull Requests
- Azure DevOps
- Kubernetes
- Terraform
- Approval Gates
- Manual Release Pipelines
- Enterprise Change Control

Use only:

- Git
- pnpm
- Shell Scripts
- Bicep
- Azure CLI
- GitHub Actions

---

# Success Criteria

After implementation the following workflow must work:

```bash
pnpm repo:init
```

creates:

```text
main
testing
staging
production
```

---

```bash
pnpm release:testing
```

deploys to:

```text
testing.all-checks-out.com
```

---

```bash
pnpm release:staging
```

deploys to:

```text
staging.all-checks-out.com
```

---

```bash
pnpm release:production
```

deploys to:

```text
all-checks-out.com
```

---

```bash
pnpm destroy:testing
```

removes the testing environment.

---

```bash
pnpm destroy:staging
```

removes the staging environment.

---

```bash
pnpm destroy:production
```

removes the production environment after explicit confirmation.

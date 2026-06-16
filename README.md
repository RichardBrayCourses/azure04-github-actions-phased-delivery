# Azure 04 - GitHub Actions Phased Delivery

## Overview

This lesson turns the static website deployment into a simple phased delivery system.

The repository supports three deployed environments:

- Testing
- Staging
- Production

Development happens on `main`, but `main` does not deploy automatically. Releases are promoted through permanent branches:

```text
main
  |
  v
testing
  |
  v
staging
  |
  v
production
```

Each deployed environment has its own Azure resource group, storage account, static website endpoint, and Cloudflare DNS record.

## Project Structure

```text
.
├── .github
│   └── workflows
│       └── deploy.yml
├── apps
│   └── ui
├── docs
├── environments
│   ├── production.json
│   ├── staging.json
│   └── testing.json
├── infra
│   └── main.bicep
├── scripts
├── package.json
├── pnpm-lock.yaml
└── pnpm-workspace.yaml
```

## Prerequisites

You need:

- Node.js
- pnpm
- Azure CLI
- an Azure subscription
- a signed-in Azure CLI session for local deployments
- a registered domain managed in Cloudflare
- a GitHub repository with an `AZURE_CREDENTIALS` secret for GitHub Actions

Install dependencies:

```bash
pnpm install
```

Check your Azure CLI account:

```bash
az account show --output table
```

Sign in if needed:

```bash
az login
```

## Environment Configuration

Environment settings live in:

```text
environments/testing.json
environments/staging.json
environments/production.json
```

| Environment | Branch | Resource group | Public URL |
| --- | --- | --- | --- |
| Testing | `testing` | `all-checks-out-testing-rg` | `https://testing.all-checks-out.com` |
| Staging | `staging` | `all-checks-out-staging-rg` | `https://staging.all-checks-out.com` |
| Production | `production` | `all-checks-out-production-rg` | `https://all-checks-out.com` |

## Local Deployment

Deploy testing:

```bash
pnpm run deploy:testing
```

Deploy staging:

```bash
pnpm run deploy:staging
```

Deploy production:

```bash
pnpm run deploy:production
```

Each deployment creates or updates the resource group, deploys Bicep, enables static website hosting, builds the UI, uploads the UI, and prints the deployed URLs.

## What-If

Preview infrastructure changes:

```bash
pnpm run whatif:testing
pnpm run whatif:staging
pnpm run whatif:production
```

## Release Commands

Promote `main` to `testing`:

```bash
pnpm run release:testing
```

Promote `testing` to `staging`:

```bash
pnpm run release:staging
```

Promote `staging` to `production`:

```bash
pnpm run release:production
```

The release scripts fast-forward the target branch and push it to GitHub. GitHub Actions deploys only from `testing`, `staging`, and `production`.

## GitHub Actions

The workflow is defined in:

```text
.github/workflows/deploy.yml
```

It runs on pushes to:

- `testing`
- `staging`
- `production`

It does not run on `main`.

The workflow logs in to Azure, deploys infrastructure, builds the UI, uploads the UI, enables static website hosting, and prints the environment URL.

## Repository Bootstrap

When this course repository is copied into a new folder, initialise it with:

```bash
pnpm run repo:init
```

This fails if `.git` already exists. Otherwise it creates:

```text
main
testing
staging
production
```

To add a GitHub remote and push all branches:

```bash
pnpm run repo:init <github-url>
```

## Destroy

Destroy testing:

```bash
pnpm run destroy:testing
```

Destroy staging:

```bash
pnpm run destroy:staging
```

Destroy production:

```bash
pnpm run destroy:production
```

Production deletion requires this exact confirmation:

```text
DELETE-PRODUCTION
```

## DNS And HTTPS

Cloudflare remains the DNS provider.

After each environment is deployed, copy the printed Azure static website host and create a proxied Cloudflare DNS record:

| Record | Type | Target | Proxy status |
| --- | --- | --- | --- |
| `testing.all-checks-out.com` | `CNAME` | testing Azure static website host | Proxied |
| `staging.all-checks-out.com` | `CNAME` | staging Azure static website host | Proxied |
| `all-checks-out.com` | `CNAME` or CNAME flattening | production Azure static website host | Proxied |

Recommended Cloudflare settings:

- SSL/TLS encryption mode: `Full`
- Always Use HTTPS: enabled
- Automatic HTTPS Rewrites: enabled

More detail is in [docs/devops-operations.md](docs/devops-operations.md).

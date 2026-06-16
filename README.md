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

## What Changes Where?

Read this before running commands.

| Command | Your machine | Azure | GitHub |
| --- | --- | --- | --- |
| `pnpm install` | Installs project dependencies into `node_modules`. | No change. | No change. |
| `pnpm run whatif:testing` | Runs an Azure CLI preview. | Reads Azure and may create the resource group if it is missing. It does not deploy the website. | No change. |
| `pnpm run deploy:testing` | Builds the UI locally. | Creates or updates the testing resource group, storage account, static website hosting, and uploaded website files. | No change. |
| `pnpm run release:testing` | Runs Git commands locally. | Not directly. Azure changes later when GitHub Actions deploys. | Pushes the `testing` branch, which triggers GitHub Actions. |
| `pnpm run repo:init` | Creates a new local Git repository and branches. | No change. | Only changes GitHub if you pass a GitHub URL, because it then pushes branches. |

The environment name matters:

- `*:testing` affects only the testing environment.
- `*:staging` affects only the staging environment.
- `*:production` affects only the production environment.

For example, this command changes Azure testing:

```bash
pnpm run deploy:testing
```

It does not change staging, production, or GitHub.

## If You Just Ran deploy:testing

If you ran:

```bash
pnpm run deploy:testing
```

then you did affect Azure.

You changed only the testing environment:

```text
Resource group: all-checks-out-testing-rg
Public URL:     https://testing.all-checks-out.com
Azure URL:      the *.web.core.windows.net URL printed by the script
```

You did not push Git branches. You did not trigger GitHub Actions. You did not change staging or production.

The command performed these actions:

1. Created or updated the testing Azure resource group.
2. Deployed the Bicep template.
3. Enabled Azure Storage static website hosting.
4. Built the UI on your machine.
5. Uploaded the built UI files to Azure Storage.
6. Printed the Azure static website URL and the intended public URL.

The public Cloudflare URL works only after the matching Cloudflare DNS record exists.

## The Three Deployment Commands

There are three similar-looking commands, but they do different jobs.

| Command | What it does | When to use it |
| --- | --- | --- |
| `pnpm run whatif:testing` | Previews the Azure infrastructure change for testing. It does not build or upload the website. | Use this before deploying when you want to see what Azure would change. |
| `pnpm run deploy:testing` | Deploys testing directly from your local machine. It deploys infrastructure, builds the UI, uploads it, and prints the URLs. | Use this when you want to deploy manually from your terminal. |
| `pnpm run release:testing` | Promotes `main` to the `testing` branch and pushes it. GitHub Actions then deploys testing. | Use this for the normal course release flow. |

The same pattern exists for staging and production:

```bash
pnpm run whatif:staging
pnpm run deploy:staging
pnpm run release:staging

pnpm run whatif:production
pnpm run deploy:production
pnpm run release:production
```

In normal day-to-day use, prefer the `release:*` commands. They exercise the branch model and GitHub Actions deployment path.

## Do I Need To Run repo:init First?

Run `repo:init` only when this course folder has been copied into a brand new folder that does not already have a `.git` directory.

If this repository is already a Git repository, do not run it.

Use:

```bash
pnpm run repo:init
```

or, if you already have the GitHub repository URL:

```bash
pnpm run repo:init <github-url>
```

That creates the four permanent branches:

```text
main
testing
staging
production
```

## Deploying Into Testing From Scratch

This is the first deployment story. Start here.

There are two ways to deploy testing:

- Normal course path: `release:testing` pushes a branch and lets GitHub Actions deploy.
- Manual path: `deploy:testing` deploys directly from your terminal to Azure.

Use the normal course path once GitHub Actions has been configured. Use the manual path when you are deliberately testing Azure deployment from your own machine.

1. Install dependencies:

```bash
pnpm install
```

2. If this is a brand new copied course folder with no `.git` directory, initialise the repository:

```bash
pnpm run repo:init <github-url>
```

Skip this step if `.git` already exists.

3. Configure GitHub Actions with the `AZURE_CREDENTIALS` secret.

4. Make sure your current development work is committed on `main`.

5. Optionally preview the Azure infrastructure change. This contacts Azure but does not build or upload the website:

```bash
pnpm run whatif:testing
```

6. Promote `main` to `testing`. This changes GitHub by pushing the `testing` branch:

```bash
pnpm run release:testing
```

7. GitHub Actions then changes Azure by deploying the testing branch to:

```text
https://testing.all-checks-out.com
```

Manual alternative:

Use this command only if you want your terminal to change Azure directly instead of using GitHub Actions:

```bash
pnpm run deploy:testing
```

## Deploying Into Staging From Scratch

Staging receives code only after testing has been deployed and checked.

1. Confirm the testing environment is good:

```text
https://testing.all-checks-out.com
```

2. Optionally preview the staging infrastructure change. This contacts Azure but does not build or upload the website:

```bash
pnpm run whatif:staging
```

3. Promote `testing` to `staging`. This changes GitHub by pushing the `staging` branch:

```bash
pnpm run release:staging
```

4. GitHub Actions then changes Azure by deploying the staging branch to:

```text
https://staging.all-checks-out.com
```

Manual alternative:

Use this command only if you want your terminal to change Azure staging directly:

```bash
pnpm run deploy:staging
```

## Deploying Into Production From Scratch

Production receives code only after staging has been reviewed.

1. Confirm the staging environment is approved:

```text
https://staging.all-checks-out.com
```

2. Optionally preview the production infrastructure change. This contacts Azure but does not build or upload the website:

```bash
pnpm run whatif:production
```

3. Promote `staging` to `production`. This changes GitHub by pushing the `production` branch:

```bash
pnpm run release:production
```

4. GitHub Actions then changes Azure by deploying the production branch to:

```text
https://all-checks-out.com
```

Manual alternative:

Use this command only if you want your terminal to change Azure production directly:

```bash
pnpm run deploy:production
```

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

## Local Deployment Reference

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

## What-If Reference

Preview infrastructure changes:

```bash
pnpm run whatif:testing
pnpm run whatif:staging
pnpm run whatif:production
```

## Release Command Reference

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

## Repository Bootstrap Reference

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

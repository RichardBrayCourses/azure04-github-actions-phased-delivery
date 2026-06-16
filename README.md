# Azure 04 - GitHub Actions Phased Delivery

## The Simple Idea

This repository deploys the same static website into three separate Azure environments:

| Environment | Branch | Azure resource group | Public URL |
| --- | --- | --- | --- |
| Testing | `testing` | `all-checks-out-testing-rg` | `https://testing.all-checks-out.com` |
| Staging | `staging` | `all-checks-out-staging-rg` | `https://staging.all-checks-out.com` |
| Production | `production` | `all-checks-out-production-rg` | `https://all-checks-out.com` |

Development happens on `main`, but `main` does not deploy automatically.

Code is promoted in one direction:

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

Each environment has its own Azure resource group, storage account, static website endpoint, configuration file, and Cloudflare DNS record.

## The Three Command Families

These commands look similar, but they do different jobs.

| Command family | Example | Meaning |
| --- | --- | --- |
| `whatif:*` | `pnpm run whatif:testing` | Ask Azure what infrastructure would change. This is a preview. |
| `deploy:*` | `pnpm run deploy:testing` | Deploy directly from your terminal to Azure. |
| `release:*` | `pnpm run release:testing` | Promote a Git branch and let GitHub Actions deploy. |

Normal course flow uses `release:*`.

Manual troubleshooting or first Azure smoke tests can use `deploy:*`.

## Install The GitHub CLI

The GitHub CLI is called `gh`. This README uses it to create GitHub secrets from the terminal.

macOS with Homebrew:

```bash
brew install gh
```

Windows with WinGet:

```powershell
winget install --id GitHub.cli
```

After installing, sign in:

```bash
gh auth login
```

Check that `gh` can see the current repository:

```bash
gh repo view
```

Official install page: <https://cli.github.com/>

## What Changes Where?

Read this before running commands.

| Command | Your machine | Azure | GitHub | Cloudflare |
| --- | --- | --- | --- | --- |
| `pnpm install` | Installs dependencies into `node_modules`. | No change. | No change. | No change. |
| `pnpm run type-check` | Runs TypeScript checks. | No change. | No change. | No change. |
| `pnpm run ui:build` | Builds `apps/ui/dist`. | No change. | No change. | No change. |
| `pnpm run repo:init` | Creates a local Git repo if needed, then creates any missing course branches. Existing branches are skipped. | No change. | If `origin` exists, pushes all four branches idempotently. | No change. |
| `pnpm run repo:init <github-url>` | Creates a local Git repo if needed, creates any missing course branches, and configures `origin`. | No change. | Adds or verifies `origin` and pushes all four branches idempotently. | No change. |
| `pnpm run whatif:testing` | Runs Azure CLI. | Reads Azure and may create the testing resource group if missing. Does not upload the website. | No change. | No change. |
| `pnpm run deploy:testing` | Builds the UI locally. | Creates or updates testing infrastructure and uploads the website. | No change. | No change. |
| `pnpm run release:testing` | Runs Git commands locally. | Not directly. Azure changes later when GitHub Actions deploys. | Pushes `testing`, triggering GitHub Actions. | No change. |
| `pnpm run release:staging` | Runs Git commands locally. | Not directly. Azure changes later when GitHub Actions deploys. | Pushes `staging`, triggering GitHub Actions. | No change. |
| `pnpm run release:production` | Runs Git commands locally. | Not directly. Azure changes later when GitHub Actions deploys. | Pushes `production`, triggering GitHub Actions. | No change. |
| `pnpm run destroy:testing` | Runs Azure CLI. | Deletes `all-checks-out-testing-rg`. | No change. | No change. |
| Cloudflare DNS change | No local project change. | No change. | No change. | Creates or updates public domain routing. |

The environment name matters:

- `*:testing` affects only testing.
- `*:staging` affects only staging.
- `*:production` affects only production.

For example:

```bash
pnpm run deploy:testing
```

changes Azure testing only. It does not change staging, production, GitHub, or Cloudflare.

## What Happens Once And What Happens Many Times?

| Journey event | How often? | Main command or action |
| --- | --- | --- |
| Install dependencies on your machine | Once per machine, then again when dependencies change | `pnpm install` |
| Initialise, repair, or publish course branches | Once per copied repo, or whenever one of the four local or remote branches is missing | `pnpm run repo:init` |
| Configure GitHub Actions access to Azure | Once per GitHub repo, then again only if you need to replace the credential | `pnpm run setup:github-azure` |
| Deploy testing for the first time | Once initially, then as needed | `pnpm run release:testing` or `pnpm run deploy:testing` |
| Configure testing custom domain | Once, then only if the Azure host changes | Add `testing` CNAME, then run `pnpm run testing:connect-domain` |
| Promote tested work into staging | Many times | `pnpm run release:staging` |
| Configure staging custom domain | Once, then only if the Azure host changes | Add `staging` CNAME, then run `pnpm run staging:connect-domain` |
| Promote approved work into production | Many times, carefully | `pnpm run release:production` |
| Configure production custom domain | Once, then only if the Azure host changes | Add apex CNAME / CNAME flattening, then run `pnpm run production:connect-domain` |
| Preview Azure infrastructure changes | Whenever useful | `pnpm run whatif:testing` |
| Remove an Azure environment | Rarely | `pnpm run destroy:testing` |

## Full Journey: From Fresh Clone To All Three Environments

This is the main path through the lesson.

## Step 1: Set Up The Repo On Your Machine

Run this after cloning the repository:

```bash
pnpm install
```

This affects only your machine.

Optional local checks:

```bash
pnpm run type-check
pnpm run ui:build
```

These also affect only your machine.

## Step 2: Create Or Repair The Course Branches

Run this if the repository is brand new, if one of the course branches is missing locally, or if one of the published GitHub branches is missing:

```bash
pnpm run repo:init
```

If you already have the GitHub repository URL:

```bash
pnpm run repo:init <github-url>
```

This creates:

```text
main
testing
staging
production
```

If one or more local branches already exists, the script skips it and creates only the missing branches.

If `origin` is configured, the script also pushes all four branches. Existing published branches are updated normally by Git. Missing published branches are created.

`repo:init` is a bootstrap and repair command. Do not run it as part of normal deployment.

## Step 3: Set Up GitHub Actions Once

GitHub Actions needs permission to deploy into Azure.

Make sure you are signed in to both CLIs:

```bash
gh auth login
az login
```

Then run:

```bash
pnpm run setup:github-azure
```

This command:

1. Finds existing app registrations and service principals whose names start with `all-checks-out-github-actions`.
2. Shows them to you.
3. If any matching identities exist, asks before deleting them.
4. Creates a fresh timestamped service principal.
5. Updates the GitHub `AZURE_CREDENTIALS` secret.
6. Deletes the temporary local secret file.

On a clean first setup, there is usually nothing to delete, so the script should not ask for confirmation.

Check that GitHub has the secret:

```bash
gh secret list
```

The workflow expects the secret to be named `AZURE_CREDENTIALS`. The setup script uses that name.

Make sure these branches exist on GitHub. You can create or repair them with `pnpm run repo:init` if `origin` is configured:

```text
main
testing
staging
production
```

After this, pushes to `testing`, `staging`, and `production` can deploy through GitHub Actions.

Microsoft's Azure Login documentation explains this service-principal secret pattern here: <https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-secret>

## Step 4: Deploy Testing For The First Time

Preferred course path:

```bash
pnpm run release:testing
```

This promotes:

```text
main -> testing
```

It pushes the `testing` branch to GitHub. GitHub Actions then deploys the testing Azure environment.

Manual Azure path:

```bash
pnpm run deploy:testing
```

Use the manual path when GitHub Actions is not ready yet, or when you deliberately want your terminal to deploy Azure testing directly.

Testing URL:

```text
https://testing.all-checks-out.com
```

## Step 5: Connect Testing Domain

### Step 5a: Get The Testing Cloudflare Target

Run:

```bash
pnpm run testing:get-storage-account
```

It prints one value, for example:

```text
allcheckouttest2lwwkfpxl.z33.web.core.windows.net
```

That printed value is the Cloudflare `Target`.

### Step 5b: Create The Testing DNS Record In Cloudflare

Create or update this Cloudflare DNS record:

```text
Type: CNAME
Name: testing
Target: allcheckouttest2lwwkfpxl.z33.web.core.windows.net
Proxy status: DNS only
```

Use the exact value printed by `pnpm run testing:get-storage-account` as the target.

Keep it as **DNS only** for now. Azure must be able to see the real CNAME before Cloudflare starts proxying it.

### Step 5c: Wait Until Public DNS Shows The CNAME

Run:

```bash
dig +short CNAME testing.all-checks-out.com
```

Wait until it prints the same target value:

```text
allcheckouttest2lwwkfpxl.z33.web.core.windows.net.
```

If it prints nothing, or prints Cloudflare IP addresses when you run `dig +short testing.all-checks-out.com`, the record is still proxied or DNS has not settled yet.

### Step 5d: Connect The Testing Domain In Azure

Run:

```bash
pnpm run testing:connect-domain
```

This Azure step matters. Cloudflare routes `testing.all-checks-out.com` to Azure, but Azure Storage must also be configured to accept that custom host name.

If you skip this, the browser can show:

```text
The request URI is invalid.
HttpStatusCode: 400
ErrorCode: InvalidUri
```

### Step 5e: Turn Cloudflare Proxying Back On

After `pnpm run testing:connect-domain` succeeds, edit the same Cloudflare DNS record:

```text
Proxy status: Proxied
```

Recommended Cloudflare settings:

- SSL/TLS encryption mode: `Full`
- Always Use HTTPS: enabled
- Automatic HTTPS Rewrites: enabled

### Step 5f: Test The Testing URL

Open:

```text
https://testing.all-checks-out.com
```

## Step 6: Promote Testing To Staging

After testing looks good:

```bash
pnpm run release:staging
```

This promotes:

```text
testing -> staging
```

It pushes the `staging` branch to GitHub. GitHub Actions then deploys the staging Azure environment.

Staging URL:

```text
https://staging.all-checks-out.com
```

Manual staging deployment:

```bash
pnpm run deploy:staging
```

Use this only when you deliberately want your terminal to deploy Azure staging directly.

## Step 7: Connect Staging Domain

### Step 7a: Get The Staging Cloudflare Target

Run:

```bash
pnpm run staging:get-storage-account
```

Copy the single value it prints. That printed value is the Cloudflare `Target`.

### Step 7b: Create The Staging DNS Record In Cloudflare

Create or update this Cloudflare DNS record:

```text
Type: CNAME
Name: staging
Target: <the value printed by pnpm run staging:get-storage-account>
Proxy status: DNS only
```

Keep it as **DNS only** for now.

### Step 7c: Wait Until Public DNS Shows The CNAME

Run:

```bash
dig +short CNAME staging.all-checks-out.com
```

Wait until it prints the same target value you copied in Step 7a.

### Step 7d: Connect The Staging Domain In Azure

Run:

```bash
pnpm run staging:connect-domain
```

### Step 7e: Turn Cloudflare Proxying Back On

After `pnpm run staging:connect-domain` succeeds, edit the same Cloudflare DNS record:

```text
Proxy status: Proxied
```

### Step 7f: Test The Staging URL

```text
https://staging.all-checks-out.com
```

## Step 8: Promote Staging To Production

After staging is approved:

```bash
pnpm run release:production
```

This promotes:

```text
staging -> production
```

It pushes the `production` branch to GitHub. GitHub Actions then deploys the production Azure environment.

Production URL:

```text
https://all-checks-out.com
```

Manual production deployment:

```bash
pnpm run deploy:production
```

Use this only when you deliberately want your terminal to deploy Azure production directly.

## Step 9: Connect Production Domain

### Step 9a: Get The Production Cloudflare Target

Run:

```bash
pnpm run production:get-storage-account
```

Copy the single value it prints. That printed value is the Cloudflare `Target`.

### Step 9b: Create The Production DNS Record In Cloudflare

Create or update this Cloudflare DNS record:

```text
Type: CNAME
Name: @
Target: <the value printed by pnpm run production:get-storage-account>
Proxy status: DNS only
```

Keep it as **DNS only** for now.

Cloudflare may show this as CNAME flattening for the apex domain.

### Step 9c: Wait Until Public DNS Shows The CNAME

Run:

```bash
dig +short CNAME all-checks-out.com
```

Wait until it prints the same target value you copied in Step 9a.

### Step 9d: Connect The Production Domain In Azure

Run:

```bash
pnpm run production:connect-domain
```

### Step 9e: Turn Cloudflare Proxying Back On

After `pnpm run production:connect-domain` succeeds, edit the same Cloudflare DNS record:

```text
Proxy status: Proxied
```

### Step 9f: Test The Production URL

```text
https://all-checks-out.com
```

## Normal Day-To-Day Release Flow

After first-time setup, the repeated flow is:

```bash
pnpm run release:testing
pnpm run release:staging
pnpm run release:production
```

Use them in order.

Do not deploy directly from `main`.

Do not deploy from feature branches.

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

## Previewing Azure Changes

Use What-If when you want to preview infrastructure changes:

```bash
pnpm run whatif:testing
pnpm run whatif:staging
pnpm run whatif:production
```

What-If does not build or upload the website.

The current script creates the resource group first if it is missing, because Azure group-level What-If needs a resource group to run against.

## Removing Environments

Destroy commands delete Azure resource groups. They do not change GitHub or Cloudflare.

Testing:

```bash
pnpm run destroy:testing
```

Staging:

```bash
pnpm run destroy:staging
```

Production:

```bash
pnpm run destroy:production
```

Production deletion requires this exact confirmation:

```text
DELETE-PRODUCTION
```

## Reference: Project Structure

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

## Reference: Prerequisites

You need:

- Node.js
- pnpm
- Azure CLI
- an Azure subscription
- a signed-in Azure CLI session for local deployments
- a registered domain managed in Cloudflare
- a GitHub repository with an `AZURE_CREDENTIALS` secret for GitHub Actions

Check your Azure CLI account:

```bash
az account show --output table
```

Sign in if needed:

```bash
az login
```

## Reference: Environment Configuration

Environment settings live in:

```text
environments/testing.json
environments/staging.json
environments/production.json
```

## Reference: Local Deployment Commands

```bash
pnpm run deploy:testing
pnpm run deploy:staging
pnpm run deploy:production
```

Each deployment creates or updates the resource group, deploys Bicep, enables static website hosting, builds the UI, uploads the UI, and prints the deployed URLs.

## Reference: Release Commands

```bash
pnpm run release:testing
pnpm run release:staging
pnpm run release:production
```

The release scripts fast-forward the target branch and push it to GitHub.

GitHub Actions deploys only from:

- `testing`
- `staging`
- `production`

It does not deploy from `main`.

## Reference: GitHub Actions

The workflow is defined in:

```text
.github/workflows/deploy.yml
```

It runs on pushes to:

- `testing`
- `staging`
- `production`

The workflow logs in to Azure, deploys infrastructure, builds the UI, uploads the UI, enables static website hosting, and prints the environment URL.

The workflow uses current major versions of the standard setup actions:

- `actions/checkout@v5`
- `pnpm/action-setup@v6`
- `actions/setup-node@v5`
- `azure/login@v3`

The workflow sets:

```yaml
FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true
```

This opts GitHub's JavaScript actions into Node.js 24. This is separate from the Node.js version used to build the app.

## Reference: DNS And HTTPS

Cloudflare remains the DNS provider.

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

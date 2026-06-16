# ALL CHECKS OUT - DEVELOPMENT ROADMAP

## Phase Summary

- **Azure02 - Baseline Repository**  
  Create a clean version of the application that deploys using Azure-generated URLs and contains no custom domain or DNS configuration.

- **Azure03 - Registered Domain**  
  Add support for www.all-checks-out.com through the registered domain, Cloudflare DNS and the Azure static website endpoint.

- **Azure04 - GitHub Actions Phased Delivery**  
  Add automated GitHub Actions deployment, branch promotion and independent testing, staging and production environments using registered domains.

- **Azure05 - Entra Authentication**  
  Add Microsoft Entra login, logout, token management and API authorization.

- **Azure06 - Azure SQL**  
  Replace the existing persistence mechanism with Azure SQL, Entity Framework Core and modern ASP.NET Core data access patterns.

- **Azure07 - Document Storage**  
  Store uploaded documents in Azure Blob Storage and manage document metadata in Azure SQL.

- **Azure08 - AI Verification**  
  Analyse and verify uploaded documents using Azure AI services and implement verification workflows.

- **Azure09 - Domain Model Review**  
  Review the completed application and identify bounded contexts and candidate service ownership boundaries.

- **Azure10 - Microservices**  
  Split the backend into independently deployable services based on the boundaries identified in Azure09.

- **Azure11 - Microfrontends**  
  Split the frontend into independently deployable applications aligned with backend service ownership.

- **Azure12 - Production Hardening**  
  Add monitoring, logging, alerting, backups, security reviews and operational procedures for long-term production operation.

## Current State

- Azure01 completed
- Single frontend application
- Single backend application
- Azure deployment working
- Public website currently running at www.all-checks-out.com
- No GitHub Actions deployment pipeline
- No testing environment
- No staging environment
- No production environment separation
- No Entra authentication
- No Azure SQL
- No Blob Storage document management
- No AI document verification
- No microservices
- No microfrontends

---

# Azure02 - Baseline Repository

## Tasks

- [ ] Create Azure02 repository
- [ ] Remove all custom domain configuration
- [ ] Remove all DNS configuration
- [ ] Remove all SSL certificate configuration related to custom domains
- [ ] Remove all documentation related to domain registration
- [ ] Deploy using Azure-generated URL only
- [ ] Verify clean deployment from a new Azure subscription
- [ ] Verify complete setup can be performed from repository documentation

## Notes

Azure02 becomes the clean baseline project for the Azure course.

---

# Azure03 - Registered Domain Repository

## Tasks

- [ ] Create Azure03 repository from Azure02
- [ ] Purchase or transfer all-checks-out.com domain
- [ ] Configure Cloudflare DNS
- [ ] Configure www.all-checks-out.com
- [ ] Point the registered domain to the Azure static website endpoint
- [ ] Document complete migration process from Azure02
- [ ] Document DNS changes
- [ ] Verify the registered domain URL works correctly

## Notes

Azure03 contains the first registered-domain deployment for www.all-checks-out.com.

---

# Azure04 - GitHub Actions Phased Delivery

## Repository

https://github.com/RichardBrayCourses/azure04-github-actions-phased-delivery

## Tasks

- [ ] Create Azure04 repository from Azure03
- [ ] Create testing, staging and production branch strategy
- [ ] Create GitHub Actions deployment workflow
- [ ] Configure GitHub Actions access to Azure
- [ ] Create environment-specific configuration files
- [ ] Create testing Azure environment
- [ ] Create staging Azure environment
- [ ] Create production Azure environment
- [ ] Configure testing.all-checks-out.com
- [ ] Configure staging.all-checks-out.com
- [ ] Configure www.all-checks-out.com for production
- [ ] Create local what-if, deploy, release and destroy commands
- [ ] Promote main to testing
- [ ] Promote testing to staging
- [ ] Promote staging to production
- [ ] Document rollback and recovery process

## Decisions

- Testing, staging and production use separate Azure resource groups
- GitHub Actions deploys from environment branches only
- Releases flow from main to testing, then staging, then production
- Registered domains are configured for all three public environments

## Notes

Azure04 makes deployment repeatable before authentication and data features are added.

---

# Azure05 - Entra Authentication

## Repository

https://github.com/RichardBrayCourses/azure05-entra-authentication

## Tasks

- [ ] Create Entra tenant configuration
- [ ] Create application registration
- [ ] Configure frontend login
- [ ] Configure frontend logout
- [ ] Configure access tokens
- [ ] Configure protected API endpoints
- [ ] Add authenticated user profile endpoint
- [ ] Add authorization infrastructure
- [ ] Create user database tables
- [ ] Automatically provision users on first login
- [ ] Configure identity settings for testing, staging and production

## Notes

All future functionality should assume authenticated users.

---

# Azure06 - Azure SQL Migration

## Tasks

- [ ] Create Azure SQL database
- [ ] Create ASP.NET Core data access layer
- [ ] Introduce Entity Framework Core
- [ ] Create migrations project
- [ ] Create database deployment process
- [ ] Replace existing persistence mechanism
- [ ] Implement repository pattern where appropriate
- [ ] Add integration tests
- [ ] Add local SQL development environment
- [ ] Configure database settings for testing, staging and production

## Notes

Use current ASP.NET Core best practices rather than older controller architectures.

---

# Azure07 - Document Storage

## Tasks

- [ ] Create Blob Storage account
- [ ] Create document container
- [ ] Create upload API
- [ ] Create download API
- [ ] Create delete API
- [ ] Create metadata database tables
- [ ] Store document metadata in SQL
- [ ] Move document storage from local filesystem to Blob Storage
- [ ] Add security and authorization checks
- [ ] Add document versioning strategy
- [ ] Configure storage settings for testing, staging and production

## Notes

Blob Storage becomes the system of record for uploaded documents.

---

# Azure08 - AI Document Verification

## Tasks

- [ ] Evaluate Azure AI services
- [ ] Evaluate Azure AI Document Intelligence
- [ ] Define verification workflow
- [ ] Create document verification service
- [ ] Extract document data
- [ ] Store extracted data
- [ ] Record verification decisions
- [ ] Add manual review workflow
- [ ] Add verification history
- [ ] Add verification audit trail
- [ ] Configure AI resources for testing, staging and production

## Notes

Uploaded documents should be automatically analysed and verified where possible.

---

# Azure09 - Domain Model Review

## Tasks

- [ ] Review existing entity model
- [ ] Identify bounded contexts
- [ ] Identify ownership boundaries
- [ ] Identify reporting requirements
- [ ] Identify document workflows
- [ ] Identify notification workflows
- [ ] Identify external integrations
- [ ] Produce candidate service boundaries

## Notes

Do not split into microservices until core functionality is complete.

---

# Azure10 - Microservices

## Candidate Services

### Identity Service

- Authentication
- Authorization
- User management

### Case Service

- Cases
- Workflows
- Status management

### Participant Service

- Participants
- Relationships
- Contact details

### Document Service

- Uploads
- Metadata
- Blob Storage

### Verification Service

- AI verification
- Manual review
- Verification history

### Notification Service

- Email
- Alerts
- Workflow notifications

### Reporting Service

- Dashboards
- Analytics
- Exports

## Tasks

- [ ] Define service contracts
- [ ] Define database ownership
- [ ] Define event contracts
- [ ] Introduce service-to-service communication
- [ ] Introduce eventing architecture
- [ ] Extract services incrementally

---

# Azure11 - Microfrontends

## Candidate Frontends

### Shell

- Navigation
- Authentication
- Shared layout

### Cases

- Case management

### Participants

- Participant management

### Documents

- Document management

### Administration

- System administration

### Reporting

- Dashboards and reporting

## Tasks

- [ ] Select MFE architecture
- [ ] Create shell application
- [ ] Create shared design system
- [ ] Create shared authentication package
- [ ] Create deployment strategy
- [ ] Create independent build pipelines
- [ ] Extract frontends incrementally

## Notes

Microfrontends should follow service ownership boundaries.

---

# Azure12 - Production Hardening

## Tasks

- [ ] Application Insights
- [ ] Centralized logging
- [ ] Alerting
- [ ] Health checks
- [ ] Backup strategy
- [ ] Disaster recovery plan
- [ ] Security review
- [ ] Penetration testing
- [ ] Cost monitoring
- [ ] Operational runbooks

---

# Deferred Decisions

## Microservices

Do not finalise service boundaries until:

- Entra authentication exists
- Azure SQL exists
- Blob Storage exists
- AI verification exists
- Testing, staging and production environments exist

## Microfrontends

Do not finalise frontend boundaries until:

- Service boundaries are agreed
- Navigation model is understood
- User roles are understood
- Operational ownership is understood

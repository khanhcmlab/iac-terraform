# iac-terraform

Multi-environment Infrastructure as Code (IaC) project using **Terraform** and **GitHub Actions**.

Manages three environments — `dev`, `qa`, and `prod` — through directory isolation, shared reusable modules, S3 remote state, and a fully automated CI/CD pipeline with OIDC authentication and a manual approval gate for production.

---

## Table of Contents

1. [Repository Structure](#repository-structure)
2. [Environment Strategy](#environment-strategy)
3. [Variable Structure](#variable-structure)
4. [State Management](#state-management)
5. [Execution Workflow (Local Commands)](#execution-workflow-local-commands)
6. [GitHub Actions CI/CD Workflow](#github-actions-cicd-workflow)
7. [GitHub Setup Checklist](#github-setup-checklist)

---

## Repository Structure

```
iac-terraform/
├── .github/
│   └── workflows/
│       └── terraform.yml          # CI/CD pipeline
├── environments/
│   ├── dev/
│   │   ├── backend.tf             # S3 remote state – dev key
│   │   ├── main.tf                # Provider + module wiring
│   │   ├── variables.tf           # Variable declarations
│   │   ├── outputs.tf             # Exposed outputs
│   │   └── terraform.tfvars       # Non-sensitive env-specific values
│   ├── qa/
│   │   └── ...                    # Same structure, qa-specific values
│   └── prod/
│       └── ...                    # Same structure, prod-specific values
└── modules/
    └── vpc/                       # Reusable VPC module
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## Environment Strategy

**Recommendation: Directory Isolation over Terraform Workspaces.**

| Concern | Workspaces | Directory Isolation ✅ |
|---|---|---|
| State separation | Single backend, multiple state files | Fully isolated backends |
| Config drift risk | High – shared `main.tf` for all envs | Low – each env owns its files |
| Plan/apply blast radius | Accidental env switch possible | Impossible by design |
| DRY compliance | Good | Good (via shared modules) |
| PR visibility | Harder | Clear – diff shows exact env |

Each environment directory calls the same shared modules (`modules/vpc`, etc.) but supplies different `terraform.tfvars` and an independent `backend.tf`. This gives full isolation with zero code duplication in business logic.

---

## Variable Structure

Environment-specific, **non-sensitive** values live in `terraform.tfvars` per environment:

```hcl
# environments/dev/terraform.tfvars
project_name         = "iac-demo"
env                  = "dev"
aws_region           = "us-east-1"
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]
enable_nat_gateway   = false
```

**Sensitive values** (database passwords, API keys, etc.) must **never** be placed in `.tfvars`. Inject them at CI time as GitHub Secrets and consume them as `TF_VAR_*` environment variables:

```yaml
# In the workflow step
env:
  TF_VAR_db_password: ${{ secrets.DB_PASSWORD }}
```

---

## State Management

Each environment has an isolated S3 state key and uses a shared DynamoDB table for locking:

| Environment | S3 Key | DynamoDB Table |
|---|---|---|
| dev  | `dev/terraform.tfstate`  | `terraform-state-lock` |
| qa   | `qa/terraform.tfstate`   | `terraform-state-lock` |
| prod | `prod/terraform.tfstate` | `terraform-state-lock` |

**Bootstrap the backend once** before running any Terraform commands:

```bash
# Create the S3 bucket
aws s3api create-bucket \
  --bucket my-terraform-state-bucket \
  --region us-east-1

# Enable versioning (allows state rollback)
aws s3api put-bucket-versioning \
  --bucket my-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Enable server-side encryption
aws s3api put-bucket-encryption \
  --bucket my-terraform-state-bucket \
  --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Block all public access
aws s3api put-public-access-block \
  --bucket my-terraform-state-bucket \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

---

## Execution Workflow (Local Commands)

### dev

```bash
cd environments/dev

terraform init
terraform validate
terraform fmt -check -recursive

terraform plan -var-file="terraform.tfvars" -out=tfplan
terraform apply tfplan
```

### qa

```bash
cd environments/qa

terraform init
terraform validate
terraform fmt -check -recursive

terraform plan -var-file="terraform.tfvars" -out=tfplan
terraform apply tfplan
```

### prod

```bash
cd environments/prod

terraform init
terraform validate
terraform fmt -check -recursive

terraform plan -var-file="terraform.tfvars" -out=tfplan

# Review the plan carefully before applying to production
terraform apply tfplan
```

To **destroy** an environment (use with caution):

```bash
terraform destroy -var-file="terraform.tfvars"
```

---

## GitHub Actions CI/CD Workflow

The pipeline lives in [`.github/workflows/terraform.yml`](.github/workflows/terraform.yml).

### Triggers

| Event | Branch | Effect |
|---|---|---|
| Pull Request | `main` | `terraform plan` for **dev** |
| Pull Request | `release/qa` | `terraform plan` for **qa** |
| Pull Request | `release/prod` | `terraform plan` for **prod** |
| Push / merge | `main` | `terraform apply` for **dev** |
| Push / merge | `release/qa` | `terraform apply` for **qa** |
| Push / merge | `release/prod` | `terraform apply` for **prod** (pending approval) |
| `workflow_dispatch` | any | Manually target env + action |

### Jobs

1. **detect-environments** – uses `dorny/paths-filter` to determine which environments have changed files, avoiding unnecessary runs.
2. **terraform-dev** – runs against `environments/dev/`; auto-applies on push to `main`.
3. **terraform-qa** – runs against `environments/qa/`; auto-applies on push to `release/qa`.
4. **terraform-prod** – runs against `environments/prod/`; **pauses for manual approval** via GitHub Environment protection rules before `apply`.

### Authentication (OIDC)

No long-lived AWS keys are used. The workflow uses `aws-actions/configure-aws-credentials` with OIDC:

```yaml
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
    aws-region:     ${{ secrets.AWS_REGION }}
```

The IAM role's trust policy must allow the GitHub OIDC provider:

```json
{
  "Effect": "Allow",
  "Principal": {
    "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
  },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
    },
    "StringLike": {
      "token.actions.githubusercontent.com:sub": "repo:khanhcmlab/iac-terraform:*"
    }
  }
}
```

### Production Approval Gate

The `terraform-prod` job references the `prod` **GitHub Environment**. To enforce manual approval:

1. Go to **Settings → Environments → prod**.
2. Add **Required reviewers** (e.g., team leads).
3. Optionally restrict to the `release/prod` branch only.

When the job reaches the prod environment, GitHub will pause and send a review request to the designated approvers before any `terraform apply` executes.

---

## GitHub Setup Checklist

- [ ] **Create GitHub Environments**: `dev`, `qa`, `prod` (Settings → Environments).
- [ ] **Add protection rules** for `prod`: Required reviewers + branch restriction.
- [ ] **Add Secrets per Environment**:
  - `AWS_ROLE_TO_ASSUME` – IAM Role ARN for OIDC assumption.
  - `AWS_REGION` – e.g. `us-east-1`.
- [ ] **Bootstrap S3 backend**: run the AWS CLI commands in [State Management](#state-management).
- [ ] **Update `backend.tf`** in each environment with your actual S3 bucket name.
- [ ] **Create GitHub OIDC provider** in AWS IAM and configure the trust policy.
- [ ] **Create branches** `release/qa` and `release/prod` with appropriate branch protection rules.

---

## DevContainer

This repository includes a DevContainer configuration for a consistent development environment.

```powershell
powershell -ExecutionPolicy Bypass -File .devcontainer/scripts/initialize-command.ps1
devpod up --devcontainer-path .devcontainer/devcontainer.json --ide vscode --dotfiles https://github.com/dewwripper/dotfiles --dotfiles-script .setup-no-install.sh .
```
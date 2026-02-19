# Deployment Pipeline Setup

This project uses **Azure Developer CLI (`azd`)** with GitHub Actions to build a container image and deploy it to Azure App Service.

## Prerequisites

- [Azure Developer CLI](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) installed
- A GitHub repository with this code pushed
- An Azure subscription

## Configure the Pipeline

Run the following command from the repo root:

```bash
azd pipeline config
```

This will:

1. Create an Azure AD app registration with federated credentials for GitHub Actions OIDC auth.
2. Set the following **GitHub repository variables** automatically:

| Variable                  | Description                          |
|---------------------------|--------------------------------------|
| `AZURE_CLIENT_ID`        | Service principal / app client ID    |
| `AZURE_TENANT_ID`        | Azure AD tenant ID                   |
| `AZURE_SUBSCRIPTION_ID`  | Target Azure subscription ID         |
| `AZURE_ENV_NAME`         | azd environment name (e.g. `dev`)    |
| `AZURE_LOCATION`         | Azure region (e.g. `westus3`)        |

> **Note:** These are stored as GitHub **Variables** (not Secrets) because they are non-sensitive identifiers used with OIDC federated credentials—no client secret is involved.

## How It Works

On every push to `main` (or manual dispatch), the workflow:

1. Checks out the code.
2. Authenticates to Azure via OIDC federated credentials.
3. Runs `azd provision` to ensure infrastructure is up to date.
4. Runs `azd deploy` which builds the Docker image from `src/Dockerfile`, pushes it to the Azure Container Registry, and updates the App Service to run the new image.

## Manual Deployment

To deploy locally without the pipeline:

```bash
azd up
```

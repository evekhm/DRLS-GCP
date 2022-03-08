# The Ultimate Guide for Deploying DRLS on GCP using GiLab CI/CD

## Pre-requisites

... 

## Steps
- Branch-off this repository -> [BRANCH_NAME]

### CI/CD Settings
- Add CI/CD  Variable of type File for the SERVICE_ACCOUNT:
- [Settings-> CI/CD](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/DRLS-GCP/-/settings/ci_cd)
Examples: `SERVICE_ACCOUNT_dev_evekhm` 
    - Download json key, copy/paste and save it as a File inside
    - Type: File
    - Make sure to uncheck 'Protected variable' checkbox

- Modify .gitlab_ci.yml file 
  - PROJECT_ID:<your_project_id>
  - KUBE_CONTEXT:<agent>
  - SERVICE_ACCOUNT_FILE:<your_service_account_value_name>
  - TODO: .......

TODO:
> VARS for different deployments
> CI/CD Logic....for DRLS and Applications
> find-out how to run keycloak

## Setting Up GCP Project Environments
For each GCP Project configured to work with Gitlab CI/CD following needs to be performed as part of the setup:

- Install GitLab Agent and configure KUBE_CONTEXT_[DEMO/TEST/DEV]
- Configure PROJECT_ID_[DEMO/TEST/DEV]
- Enable API services and Create service account + Download Service Account Key (SERVICE_ACCOUNT_FILE_[DEMO/TEST/DEV])

CI/CD Settings Variables Defined in Gitlab:
- CI_DEPLOY_USER and CI_DEPLOY_PASSWORD - group token  manually created on the level of on the level of 
> Project->Settings->Repository->Deploy Token, scopes - read_repository, read_registry
> Use Created Deploy settings as Variables CI_DEPLOY_USER=username and CI_DEPLOY_PASSWORD=password inside the manifest Project.
- CDS_LIBRARY_TOKEN
- SERVICE_ACCOUNT_FILE_env - Per Project Environment, Service Account key to perform CI/CD operations.
- VSAC_API_KEY
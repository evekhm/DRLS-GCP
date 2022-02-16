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



# The Ultimate Guide for Deploying DRLS on GCP using GiLab CI/CD
## Purpose of this guide

This document details the installation process for Gitlab CI/CD Integration.
Read [here](GitLabCICD_UseCases.md) about the supported use cases. 

## Pre-requisites
Git Lab Premium account and following projects hosted in GitLab in the same Group:

 **Seven Application Projects** originally branched off from DaVinci (`gcpDev` branch being the `main`),
composing Microservice Architecture for the DRLS flow. All the projects (except CDS-Library) should have Container Registry enabled :
- [CRD](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/crd)
- [CDS-Library](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/CDS-Library)
- [crd-request-generator](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/crd-request-generator)
- [dtr](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/dtr)
- [prior-auth](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/prior-auth)
- [test-ehr](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/test-ehr)
- [auth](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/auth)

**Project to manage GCP Setup**, including GitLab Agent configuration (to be extended with DTP):
- [gke-deploy-env](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/gke-deploy-env)

**Project to manage Deployment and CI/CD flow** containing GKE manifests file for the applications:
- [DRLS-GCP](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/DRLS-GCP)


## Steps
It is enough to have a shared project/cluster for all demo/test/development environments.
It is also possible to have a dedicated cluster or even the GCP Project for any of the environments.

GitLab Agent is installed per cluster. So when having  different clusters per environment, a dedicated Gitlab Agent needs to be installed. 
For more details see [here](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/gke-deploy-env/-/blob/main/README.md)

#### Step 1
Setup GCP Project to be used for CI/CD Deployment and install Gitlab Agent as described [here](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/gke-deploy-env/-/blob/main/README.md)

#### Step 2
Update CI/CD Settings
   - Modify [Settings-> CI/CD](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/DRLS-GCP/-/settings/ci_cd)
   - 
     - When sharing same project, just one variable  `SERVICE_ACCOUNT_FILE` needs to be added. This is also a fall back variable.
     - If different projects are used per environment, SERVICE_ACCOUNT_FILE needs to be specified per deployment in the following way:
        * `SERVICE_ACCOUNT_FILE_DEV` - per development environment
        * `SERVICE_ACCOUNT_FILE_TEST` - per test environment
        * `SERVICE_ACCOUNT_FILE_DEMO` - per demo environment

     - Add `SERVICE_ACCOUNT_FILE` or `SERVICE_ACCOUNT_FILE_<env>` to CI/CD settings
       - Use the json key file downloaded in step 2, copy/paste and save it as a variable inside CI/CD Settings of the DRLS-GCP project
       - Type: File
       - Make sure to uncheck 'Protected variable' checkbox

   - Modify [.gitlab_ci.yml](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/DRLS-GCP/.gitlab_ci.yml) file
     - Update KUBE_CONTEXT to use the AGENT_NAME (use same one if shared)  created during the [Step 1](#step1).
     
```shell
    KUBE_CONTEXT_DEMO: ${CI_PROJECT_NAMESPACE}/gke-deploy-env:<AGENT_NAME>
    KUBE_CONTEXT_TEST: ${CI_PROJECT_NAMESPACE}/gke-deploy-env:<AGENT_NAME>
    KUBE_CONTEXT_DEV: ${CI_PROJECT_NAMESPACE}/gke-deploy-env:<AGENT_NAME>
   ```
- Modify [.gitlab_ci.yml](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/DRLS-GCP/.gitlab_ci.yml) file
    - Update PROJECT_ID for each environment (use same one if shared) as created during the [Step 1](#step1).
```shell
    #Sharing same Project ID, but could use different projects per environment
    PROJECT_ID_TEST: <PROJECT_ID>
    PROJECT_ID_DEMO: <PROJECT_ID>
    PROJECT_ID_DEV:  <PROJECT_ID>
```

> When using different projects per environment:
Make sure PROJECT_ID<env>, KUBE_CONTEXT_env and SERVICE_ACCOUNT_FILE_<env> are setup correspondingly.

#### Step 3  
Deploy
   - Run CI/CD Pipeline for the initial Deployment


### CI/CD Settings
- Add CI/CD  Variable of type File for the SERVICE_ACCOUNT:
- [Settings-> CI/CD](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/DRLS-GCP/-/settings/ci_cd)
Examples: `SERVICE_ACCOUNT_FILE` 
    - Download json key, copy/paste and save it as a File inside
    - Type: File
    - Make sure to uncheck 'Protected variable' checkbox

- Modify .gitlab_ci.yml file 
  - PROJECT_ID:<your_project_id>
  - KUBE_CONTEXT:<agent>

If you want to use different cluster per environment, you need 

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
- CI_DEPLOY_USER and CI_DEPLOY_PASSWORD - group token  manually created on the level of the group  
> Project->Settings->Repository->Deploy Token, scopes - read_repository, read_registry
> Use Created Deploy settings as Variables CI_DEPLOY_USER=username and CI_DEPLOY_PASSWORD=password inside the manifest Project.
- SERVICE_ACCOUNT_FILE_<env> - Per Project Environment, (en=DEV|TEST|DEMO). When not specified per environment, falls back to SERVICE_ACCOUNT_FILE.
- VSAC_API_KEY
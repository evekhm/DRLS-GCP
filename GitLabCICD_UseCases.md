## Overview

There are **Seven Application Projects** originally branched off from DaVinci (`gcpDev` branch being the `main`),
composing Microservice Architecture for the DRLS flow:
- [CRD](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/CRD) 
- [CDS-Library](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/CDS-Library)
- [crd-request-generator](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/crd-request-generator)
- [dtr](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/dtr)
- [prior-auth](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/prior-auth)
- [test-ehr](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/test-ehr)
- [keycloak](TODO) TODO

> The above projects will be referenced as Applications with the corresponding names.

> All the projects above (except CDS-Library)  have an associated Container Registry 
for the images used in the deployments. 

There is a **project to manage GCP Setup**, including GitLab Agent configuration (to be extended with DTP):
- [gke-deploy-env](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/gke-deploy-env)

There is a **project to manage Deployment and CI/CD flow** containing GKE manifests file for the applications: 
- [DRLS-GCP](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/DRLS-GCP)


## CI/CD Environments
CI/CD covers Following Environments:
- *Development environment(s)* - personalized GCP environment(s), can be created/setup and used per developer.
- *Test environment* - pre-configured GCP environment used for testing before manually releasing application images or changes to the project setup or deployment flow.
The namespace separation (named after the feature branch) will be used during the deployment.
- *Demo environment* - running stable demo using released images and main branch for the CI/CD deployment.

## High Level Feature Release Example
**Use Case:** As a developer, I want to be able to work on my own GCP environment while branching off components I need,
with automatic CI/CD pipeline .

**Translates to:** As a developer, I want to be able to build a new feature for the DRLS-flow (possibly touching multiple applications/projects) and do the following: 
- Deploy and test inside my Development environment, 
- Deploy and test potential merge request inside the Test environment,
- Request feature to be released (includes releasing of the new application image(s)).  

###Steps:
- (One time only) :
  - Developer creates new GCP Project, installs GitLab Agent (requires changes to [gke-deploy-env](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/gke-deploy-env))
    and prepares personal Development environment following [these steps](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/gke-deploy-env/-/blob/main/README.md).
  - It is also possible to use already existing GCP project provisioned for test/demo environments (To be discussed).
- Developer branches off from the `main` Application(s) branch as *myFeature* branch. 
  - When multiple applications need to be changed, same *myFeature* name is used as a branch name on all other repositories. 
- Developer branches off from the `main` [DRLS-GCP](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/DRLS-GCP) branch as *myFeature* branch.
  - Developer modifies [.gitlab-ci.yml](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/DRLS-GCP/-/blob/main/.gitlab-ci.yml)
  - It is up to developer to decide which namespace to use during the deployment into the Development environment and decide on additional configurations. 
  to include GCP Project settings and set CI/CD to work with the *myFeature* branch changes.  [TODO Add Instructions and Examples]
- Developer commits changes to the Application feature branch.
  - This triggers CI/CD to build and push new `test` image into the Application Container Registry with `application_name/branch_name:latest` tag (logic handled inside the Application .gitlab-ci.yml).
  - This in turn triggers downstream deployment and patching of the image into the Development environment. (logic handled inside the branched-off DRLS-GCP [.gitlab-ci.yml](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/DRLS-GCP/-/blob/main/.gitlab-ci.yml)
- Developer tests changes using the Deployment environment, when successfully tested, proceeds with the next steps.
- Developer initiates Merge Request(s) for the Application(s) `main` branch(es):
  - This triggers deployment into the Test environment using *myFeature* as a namespace.
  - If there are multiple applications changed (thus multiple merge requested on each application branch), all of that would result in the updated Test environment with *myFeature* namespace and required images patched. 
- Developer uses Test environment for the final integration test.  
- Assigned reviewer approves merge request:
  - Performs QA of the Test environment  [*myFeature*] namespace and does code review. 
  - (Manual? in case we need to verify later)
- Automatic release on the merge request approval:
  - As soon as code is pushed to the `main` of the application branch, the image is automatically built and released as `application_name:latest` inside the Application project Container Registry.
  - This triggers deployment into the Demo environment with the latest released images.
    - Manually deletes Test deployment with *myFeature* namespace using CI/CD pipeline Job (Probably, could be automated with the merge Request Acceptance)
- Cleaning up:
  - Initially, manual action from CI/CD Pipeline to clean up resources:
    - Developer selects `cleanup` Pipeline action to remove applications from the Development environment.
    - Developer and Approver selects `cleanup` Pipeline action to remove applications from the Test environment *myFeature* namespace.

## CI/CD Flows
### Development Environment
#### Prerequisites
Following pre-requisites are required for the CI/CD to work:
- GCP Project is provisioned with Gitlab Agent setup, Service Account and APIs enabled (to be extended with DTP provisioning step). Currently, [these steps](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/gke-deploy-env/-/blob/main/README.md) are required. 
- Branched-off [DRLS-GCP](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/DRLS-GCP) project and modify  [.gitlab-ci.yml](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/DRLS-GCP/-/blob/main/.gitlab-ci.yml) file:
  - Registered new development environment by providing settings of the GCP Project GitLab Agent created before
  - Registered name of the *myFeature* branch name. The default fall back when branch not available would be stable released applications
    - Exception is `keycloak`, since it needs to be built per deployment.

#### Initial Deployment
Initial deployment into the personal Development environment can be done either manually from the CI/CD Pipeline on the branched-off 
[DRLS-GCP](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/DRLS-GCP) project, or will happen automatically on a commit to the registered *myFeature* branch.

#### Feature Deployment
Commits into the `feature` **application** branch with *<branch_name>*:
- Will trigger new image to be built and pushed into the Application Container Registry with `application_name/branch_name:latest` and `application_name/branch_name_:test_COMMIT_SHA` tags.
  - E.g.:
    - `registry.gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/crd/gcpdev:latest`
    - `registry.gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/crd/gcpdev:test_4tHSG586`
  - Note, that in reality it will be using 'normalized' branch name, such as CI_COMMIT_REF_SLUG
- Then this  triggers downstream deployment (with APPLICATION and IMAGE_TAG as variables) and patching of the image into the development environment. 
- The officially released application image will be used for those applications that do not have  *<branch_name>*.

### Test Environment
Merge Request into the `main` **application** branch from  *<branch_name>*:
- Will trigger `application_name/branch_name:latest` to be used in the Test environment inside <branch_name> namespace.

### Demo Environment
Demo environment only uses Application released stable images with `application_name:latest` tag.

Commits to the main branch of the Application will trigger:
- Application image to be released and tagged as `application_name:latest`.
  - E.g., `registry.gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/crd:latest`
- Deployment into the `demo` environment of the released image.

## CI/CD Implementation Logic

- DRLS-GCP project CI/CD Pipeline (main branch):
  - Deploys to the Test environment on merge requests using the source branch name as a namespace
  - Deploys to the Demo environment when commits on the main branch or when downstream pipeline is triggered from the commits into the *main* application branch.
- DRLS-GCP project CI/CD Pipeline (development *myFeature* branch):
  - Deploys to the Development environment on the branch commits or when downstream pipeline is triggered from the commits into the *myFeature* branch of the applications.


# The Ultimate Guide for Deploying DRLS on GCP

## Purpose of this guide

This document details the installation process for the dockerized version of the **Documentation Requirements Lookup Service (DRLS) Prior Auth Workflow** system for GCP Development. 
Be aware that each component of DRLS has its own README where you will find more detailed documentation. This document **is not designed to replace those individual READMEs**.

Read [here]() for the guide on CI/CD deployment using GitLab

Following commands should be run from GCP Terminal.
> Because keycloak needs to be re-built, running remotely via gcloud sdk requires environment to build contaienr and push it to GitLab repository. Those instructions are missing. 

## Table of Contents
- [Prerequisites](#prerequisites)
- [GCP Project Setup](#gcpsetup)
- [Deployment](#deployment)
- [Verify DRLS Prior Auth is working](#verify-drls-is-working)
- [Tear Down](#teardown)

## Prerequisites  <a name="prerequisites"></a>


### GitLab Access
> Currently, this flow requires special access for the GitLab Repository and Container Registry, so a Personal Access Token is needed for the setup. 
You will need to have permissions for the [HCLS Project](https://gitlab.com/gcp-solutions/hcls/claims-modernization/) and generated Personal Access Token with `read_registry` and `read_repository` scope.
In case of planning on contributing back, the scope needs also to include `write_registry` and `write_repository`.

Check GitLab instructions [here](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#create-a-personal-access-token).

### VSAC Key
Additionally, you must have credentials (api key) access to the **[Value Set Authority Center (VSAC)](https://vsac.nlm.nih.gov/)**. These credentials are required for allowing DRLS to pull down updates to value sets that are housed in VSAC. If you don't already have VSAC credentials, you should [create them using UMLS](https://www.nlm.nih.gov/research/umls/index.html).


## GCP Project Setup <a name="gcpsetup"></a>

### Setting Environment Variables

When Running remotely using Cloud SDK:


Create new GCP project and activate Cloud Shell. Following commands should be executed in the Cloud Shell of your GCP Project.

1. Set Project ID

Set the PROJECT_ID environment variable to point to the GCP project and activate the config (replace <your_project_id> below):

```sh
  export PROJECT_ID=<your_project_id>
  gcloud config set project $PROJECT_ID 
```


2. Set VSAC keys
> At this point, you should have credentials to access VSAC. If not, please refer to [Prerequisites](#prerequisites) for how to create these credentials and return here after you have confirmed you can access VSAC.
> To download the full ValueSets, your VSAC account will need to be added to the CMS-DRLS author group on https://vsac.nlm.nih.gov/. You will need to request membership access from an admin. If this is not configured, you will get `org.hl7.davinci.endpoint.vsac.errors.VSACValueSetNotFoundException: ValueSet 2.16.840.1.113762.1.4.1219.62 Not Found` errors.

Use your *vsac_api_key* to set VSAC credentials (otherwise the flow will not work):

```sh
  export VSAC_API_KEY=vsac_api_key
```

3. Gitlab Token nad UserName created previously:
```sh
export TOKEN=<your_token>
export USERNAME=<your_username>
```

### Download Required Sources

> At this point, you should have Access Token Generated for GitLab. If not, please refer to [Prerequisites](#prerequisites).


Create a root directory for the DRLS demo work (we will call this `<drlsroot>` for the remainder of this setup guide). 
 ```bash
 mkdir <drlsroot> && cd <drlsroot>
 ```

Clone this repository:
```sh
  git clone https://oauth2:$TOKEN@gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/DRLS-GCP.git
```

### For Argolis Only

For the `Argolis` environment, following known Org Constraints need to be disabled using Cloud Shell before deploying the cluster:

```sh
   gcloud services enable orgpolicy.googleapis.com
   gcloud org-policies reset constraints/compute.vmExternalIpAccess --project $PROJECT_ID
```

Settings for the manual Deployment (such as KUBE namespace ):
```shell
source DRLS-GCP/shared/SET.manual
```

## Deployment  <a name="deployment"></a>
Following command does the installation and deployment of the DRLS components.

```sh
  DRLS-GCP/manual-ci.sh -p $PROJECT_ID -t $TOKEN -u $USERNAME 
```

Behind the hoods, following steps are executed:

- Provision Resources: Enable APIs, network and Cluster Creation (to be integrated with DTP).
  * Resources are managed by a separate project: [gke-deploy-env](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/gke-deploy-env)
- Prepare Cluster: create GitLab access secret, Kubernetes Workload identity.  
- Deploy Services required for the DRLS flow into the GKE cluster.
  * This operation will provision service host IPs required for further deployment configurations.
- Build keycloak image
  * A dedicated keycloak image per deployment needs to be built (will be hosted using GCP container registry of the project(. This is required to embed <TEST_EHR> service IP as allowed for re-direction))
- Deploy DRLS components
  * Now everything is ready to get images (both from the GitLab and the keycloak) deployed into the GCP cluster.


Wait for the pods to be created and get into Running state:
```sh

  kubectl get pods -n $KUBE_NAMESPACE --watch
```
You should be getting five pods: 
- crd
- crd-request-generator
- dtr
- keycloak
- test-ehr

Example Output:
```
crd-5f9599cb48-jdb27                     1/1     Running   0          7m32s
crd-request-generator-6d6fdb4994-7m4fn   1/1     Running   0          7m12s
dtr-0                                    1/1     Running   0          7m25s
keycloak-799c968c6f-rc2ht                1/1     Running   0          7m38s
test-ehr-768645cdf4-ntg9t                1/1     Running   0          7m19s
```
## Verify DRLS is working

NOTE: Currently deployed applications have around five to seven minutes required for starting up. Make sure to wait for them to be ready, before trying the steps below.
In the instructions below replace <APPLICATION> with the corresponding IP.

Print out the `steps`:
```sh
  DRLS-GCP/jobs/print_steps.sh
```


Sample Output:
```
==> ### Register the test-ehr ###
Go to http://34.67.137.51:3005/register
- Client Id        : app-login
- Fhir Server (iss): http://35.224.229.97:8080/test-ehr/r4

==> ### Run the DRLS Flow ###
Go to http://34.135.12.152:3000/ehr-server/reqgen
```
  
### Register the test-ehr

1. Go to `<DTR>`/register.
   - Client Id: **app-login**
   - Fhir Server (iss): **`<TEST_EHR>`/test-ehr/r4**
2. Click **Submit**

## Run the DRLS Flow 
1. Go to `<CRD_REQUEST_GENERATOR_HOST:3000>`/ehr-server/reqgen.
2. Click **Patient Select** button in upper left.
3. Find **William Oster** in the list of patients and click the dropdown menu next to his name.
4. Select **E0470** in the dropdown menu.
5. Click anywhere in the row for William Oster.
6. Click **Submit** at the bottom of the page.
7. After several seconds you should receive a response in the form of two **CDS cards**:
    - **Respiratory Assist Device**
    - **Positive Airway Pressure Device**
8. Select **Order Form** on one of those CDS cards.
9. If you are asked for login credentials, use **alice** for username and **alice** for password.
10. A webpage should open in a new tab, and after a few seconds, a questionnaire should appear.

Congratulations! DRLS is fully installed and ready for you to use!

## Tear Down  <a name="teardown"></a>
Following command will delete all resources in the KUBE_NAMESPACE and prevent from running resources when unwanted. 
```sh
  DRLS-GCP/jobs/destroy.sh
```



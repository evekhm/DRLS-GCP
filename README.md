# The Ultimate Guide for Deploying DRLS on GCP

## Purpose of this guide

This document details the installation process for the dockerized version of the **Documentation Requirements Lookup Service (DRLS) Prior Auth Workflow** system for GCP Development. 
Be aware that each component of DRLS has its own README where you will find more detailed documentation. This document **is not designed to replace those individual READMEs**.

To set up system for Local Development follow instruction [here](SetupLocalRunOnMac.md)

## Table of Contents
- [Prerequisites](#prerequisites)
- [GCP Project Setup](#gcpsetup)
- [Deployment](#deployment)
- [Verify DRLS Prior Auth is working](#verify-drls-is-working)
- [Tear Down](#teardown)

## Prerequisites  <a name="prerequisites"></a>


### GitLab Access
> Currently, this flow requires special access for the GitLab Repository and Container Registry, so a Personal Access Token is needed for the setup. 
You will need to have permissions for the [HCLS Project](https://gitlab.com/gcp-solutions/hcls/claims-modernization/epa) and generated Personal Access Token with `read_registry` and `read_repository` scope.
In case of planning on contributing back, the scope needs also to include `write_registry` and `write_repository`.

Check GitLab instructions [here](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#create-a-personal-access-token).

### VSAC Key
Additionally, you must have credentials (api key) access to the **[Value Set Authority Center (VSAC)](https://vsac.nlm.nih.gov/)**. These credentials are required for allowing DRLS to pull down updates to value sets that are housed in VSAC. If you don't already have VSAC credentials, you should [create them using UMLS](https://www.nlm.nih.gov/research/umls/index.html).


## GCP Project Setup <a name="gcpsetup"></a>

### Setting Environment Variables
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

### Download Required Sources

> At this point, you should have Access Token Generated for GitLab. If not, please refer to [Prerequisites](#prerequisites).

```sh
export TOKEN=<your_token>
```

Create a root directory for the DRLS demo work (we will call this `<drlsroot>` for the remainder of this setup guide). 
 ```bash
 mkdir <drlsroot> && cd <drlsroot>
 ```

Clone this repository as well as CDS-Library repository which stores common files necessary to make the [Coverage Requirements Discovery (CRD)](https://github.com/HL7-DaVinci/CRD), [Documentation Templates and Rules (DTR)](https://github.com/HL7-DaVinci/dtr) and [Prior Authorization Support (PAS)](https://github.com/HL7-DaVinci/prior-auth) use cases work. 
CDS-Library will be uploaded as Cloud Storage inside your project and used by CRD service when serving back the CDS cards.

```sh
  git clone https://oauth2:$TOKEN@gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/DRLS-GCP.git
  git clone https://oauth2:$TOKEN@gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/CDS-Library.git
```

### For Argolis Only

For the `Argolis` environment, following known Org Constraints need to be disabled using Cloud Shell before deploying the cluster:

```sh
   gcloud services enable orgpolicy.googleapis.com
   gcloud org-policies reset constraints/compute.vmExternalIpAccess --project $PROJECT_ID
```

## Deployment  <a name="deployment"></a>

### 1. Provision Resources on the GKE Cluster

Using following script to create the GKE cluster using auto-pilot and upload CDS-Library to the Cloud Storage of the Project.
```sh
  DRLS-GCP/setup_cluster.sh
```

When prompted, Authorize Cloud Shell for API execution.
> In case the above operation exited with an error, depending on the error, try resolving it (such as disabling constraints)  and re-run the command again.
> Steps that were successfully executed will be skipped, while the failed steps will be tried again.

### 2. Deploy Services
Deploy services required for the DRLS flow into the GKE cluster.
This operation will provision service host IPs required for further deployment configurations.
Following command will generate `.env` file, used later for the deployment. 

```sh
  DRLS-GCP/deploy_services.sh
```

### 3. Build keycloak image 

You will need to build/push locally keycloak image to have <TEST_EHR> service IP embedded into it.
Later keycloak will be replaced with IAP for GCP.

```sh
  DRLS-GCP/build_keycloak.sh
```

 For `Argolis` Only:
> 
> Following step is required for permissions to pull image form the container registry:
```sh
   CONTAINER_BT=gs://artifacts.${PROJECT_ID}.appspot.com/
   gsutil iam set gs://"${CONTAINER_BT}" serviceAccount:"$(gcloud projects describe "$PROJECT_ID" --format='get(projectNumber)')"-compute@developer.gserviceaccount.com:roles/storage.objectViewer
```


### 4. Create and Deploy Secret for GitLab Contaienr Registry Access 

All other images (except keycloak) are released and stored in the Private GitLab container registry.
You need to create secret to allow access to those images.

- Login into the GitLab Container Registry using TOKEN:
``` sh
   docker login registry.gitlab.com -u <username> -p $TOKEN
```
The login process creates or updates a config.json file that holds an authorization token required to pull images.
View the `config.json` file:
``` sh
   cat $HOME/.docker/config.json
```

- Deploy secret into the cluster:
```sh
kubectl create secret generic regcred \
    --from-file=.dockerconfigjson=$HOME/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson
```

### 5. Deploy DRLS components into the GKE
Now everything is ready to get images (both from the GitLab and the keycloak) deployed into the GCP cluster.
```sh
  DRLS-GCP/apply_workers.sh
```

Wait for the pods to be created and get into Running state:
```sh
  kubectl get pods --watch
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
  
To see IPs for the deployed services:
```sh
  cat DRLS-GCP/.env
```
  
### Register the test-ehr

1. Go to http://DTR/register.
   - Client Id: **app-login**
   - Fhir Server (iss): **http://TEST_EHR/test-ehr/r4**
2. Click **Submit**

## Run the DRLS Flow 
1. Go to http://CRD_REQUEST_GENERATOR_HOST:3000/ehr-server/reqgen.
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
Following command will delete deployment and prevent from running resources when unwanted. 
```sh
  DRLS-GCP/delete_deployment.sh
```



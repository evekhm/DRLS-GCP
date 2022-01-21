# The Ultimate Guide for Deploying DRLS on GCP

## Prerequisites

### GitLab Container Registry Access
Currently, this flow uses private Container Registry, so special access rights and Personal Access Token is needed to be setup for GitLab. You will need to have *read_registry* permissions for the [HCLS Project](https://gitlab.com/gcp-solutions/hcls/claims-modernization/epa) and generated Personal Access Token with *read_registry* scope.

Check GitLab instructions [here](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#create-a-personal-access-token).

### VSAC Key
Additionally, you must have credentials (api key) access to the **[Value Set Authority Center (VSAC)](https://vsac.nlm.nih.gov/)**. These credentials are required for allowing DRLS to pull down updates to value sets that are housed in VSAC. If you don't already have VSAC credentials, you should [create them using UMLS](https://www.nlm.nih.gov/research/umls/index.html).


## GCP Project Setup

Create new GCP project and activate Cloud Shell.

Set the PROJECT_ID to the project in use and activate the config (replace <your_project_id> below):

```sh
  export PROJECT_ID=<your_project_id>
  gcloud config set project $PROJECT_ID 
```

This step requires a VSAC_API_KEY. Refer to prerequisite on how to get a VSAC_API_KEY.
Use your *vsac_api_key* to set VSAC credentials (otherwise the flow will not work):

```sh
  export VSAC_API_KEY=vsac_api_key
```

Login into the GitLab Container Registry using generated token:
``` sh
   docker login registry.gitlab.com -u <username> -p <token>
```
The login process creates or updates a config.json file that holds an authorization token required to pull images.
View the config.json file:
``` sh
   cat $HOME/.docker/config.json
```

Create demo directory and clone this repository into it:

```sh
  mkdir priauth-demo && cd priauth-demo
  git clone https://github.com/evekhm/DRLS-GCP.git
```

Checkout required repositories for DRLS workflow:

```sh
  DRLS-GCP/get_projects.sh
```

## Deployment

Prepare the cluster and upload CDS-Library to the Cloud Storage of the Project.
When prompted, Authorize Cloud Shell for API execution.

```sh
  DRLS-GCP/setup_cluster.sh
```

Deploy services required for the DRLS flow into the newly created cluster to get their host IPs required for further deployment configurations.
Following command will generate `.env` file which later is used for the deployments. 

```sh
  DRLS-GCP/deploy_services.sh
```


You will need to build/push locally keycloak image to have <TEST_EHR> service IP embedded into it.
Later keycloak will be replaced with IAP for GCP.

```sh
  DRLS-GCP/build_keycloak.sh
```

Create Cluster Secret to Pull Images from the Private Registry:
```sh
kubectl create secret generic regcred \
    --from-file=.dockerconfigjson=$HOME/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson
```

Now everything is ready to get images deployed into the GCP cluster.
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

Sampel Output:
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

## Tear Down 
Following command will delete deployment and prevent from running resources when unwanted. 
```sh
  DRLS-GCP/delete_deployment.sh
```


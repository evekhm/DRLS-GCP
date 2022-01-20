# DRLS-GCP

## Prerequisites

### GitLab Container Registry Access
Currently, this flow uses private Container Registry, so special access rights and Personal Access Token needs to be setup for GitLab. You will need to have *read_registry* permissions for the https://gitlab.com/gcp-solutions/hcls/claims-modernization/epa Project and generated Personal Access Token with *read_registry* scope.

Check GitLab instructions [here](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#create-a-personal-access-token).

### VSAC Key

## GCP Project Setup

Create new GCP project and activate Cloud Shell.

Setup env variables:
Set PROJECT_ID to the active project:
```sh
  export PROJECT_ID=$DEVSHELL_PROJECT_ID
```

Use your VSAC_API_KEY to set into system environment variable (otherwise the flow will not work):
For more details about getting VSAC_API_KEY check [here]()
```sh
  export VSAC_API_KEY=<your_key>
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

Now ready to get everything Deployed to GCP.
```sh
  DRLS-GCP/apply_workers.sh
```

To see IPs for the deployed services:
```sh
  cat DRLS-GCP/.env
```

In the instructions below replace <APPLICATION> with the corresponding IP.

### Register the test-ehr

1. Go to http://<DTR>:3005/register.
   - Client Id: **app-login**
   - Fhir Server (iss): **http://<TEST_EHR>:8080/test-ehr/r4**
2. Click **Submit**
3. 
## Run the DRLS Flow 
1. Go to <CRD_REQUEST_GENERATOR_HOST>:3000/ehr-server/reqgen.
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

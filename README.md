# DRLS-GCP

TODO:
profile: -Dspring.profiles.active=gcp
Not working, needs application.yml to be set for profile.
Why?

## Prerequisites

### GCP Project Setup
- Create new project in `gcct-demos` folder
- Activate Google Cloud configuration (if working locally)
```sh
  gcloud auth login
```
- Setup env variables for PROJECT_ID
```sh
  export PROJECT_ID=<your_project_id>
```

Use your VSAC_API_KEY to set into system environment variable (otherwise the flow will not work):

```sh
  export VSAC_API_KEY=<your_key>
```

- Create working directory WORKDIR  and clone this repository into it:

```sh
  git clone https://github.com/evekhm/DRLS-GCP.git
```

Authenticate Shell Console and following prompted instructions:
```sh
gcloud auth login
```

Checkout required repositories for DRLS workflow:

```sh
  DRLS-GCP/get_projects.sh
```

## Deployment

Prepare the cluster and upload CDS-Library to Cloud Storage

```sh
  DRLS-GCP/setup_cluster.sh
```

Deploy services to get their IPs required for deployment/built configuations.
Following command will generate `.env` file which later will be used for deployments. 

```sh
  DRLS-GCP/deploy_services.sh
```

Now ready to get everything Deployed to GCP.
You will need to build/deploy keycloak image to have <TEST_EHR> service IP embedded inside.
Later keycloak will be replaced with IAP for GCP.

```sh
  DRLS-GCP/build_keycloak.sh
```


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
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
  export WORKDIR=priauth
  mkdir $WORKDIR && cd $WORKDIR
  git clone https://github.com/evekhm/DRLS-GCP.git
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

Now ready to get everything BUILT as Images and Deployed to GCP.
This operation will take some time, since real images are built from the sources and pushed to GCP Container Registry.


```sh
  DRLS-GCP/deploy_workers.sh
```

To see deployed external Ips for the services:
```sh
  cat DRLS-GCP/.env
```

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
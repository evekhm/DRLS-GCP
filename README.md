# The Ultimate Guide for Deploying DRLS on GCP

## Table of Contents
- [Overview](#overview)
- [CI/CD Integration with GitLab](#cicd)
- [Consumed Resources](#resources)
- [Prerequisites](#prerequisites)
- [GCP Project Setup](#gcpsetup)
- [Deployment](#deployment)
- [Verify DRLS Prior Auth is working](#verify-drls-is-working)
- [Tear Down](#teardown)
- [Useful Commands](#commands)

## Overview

This document details the installation process for the dockerized version of the **Documentation Requirements Lookup Service (DRLS) Prior Auth Workflow** system for GCP Development. 
Be aware that each component of DRLS has its own README where you will find more detailed documentation. This document **is not designed to replace those individual READMEs**.

## CI/CD Integration using GitLab <a name="cicd"></a>
**If you are a Developer and want to contribute, check this [guide](DevDeployment.md) on the steps how to setup Argolis Deployment environment as part of CI/CD.**

Refer to this [documentation](GitLabREADME.md) for more details about CI/CD deployment using GitLab. 

Additional information on GitLab Deployment [Use Cases](GitLabCICD_UseCases.md).

## Consumed Resources <a name="resources"></a>
Each deployed Prior-Auth Solution consumes following resources:
- [GKE](https://cloud.google.com/kubernetes-engine/pricing) Autopilot cluster:
  - 6 deployed services/workloads
  - 6 GKE Ingress objects setup with NEG ([Container native LB*](https://cloud.google.com/kubernetes-engine/docs/how-to/container-native-load-balancing))
    - 6 GCE_VM_IP_PORT NEGs (zonal NEGs) 
  - GCP Cloud Storage
- [Network Premium Tier](https://cloud.google.com/network-tiers/pricing):
  - 1 VPC Network
  - 6 [Global external HTTP(S) Load Balancers (classic)](https://cloud.google.com/load-balancing/docs/https)
    - 12 [URL maps](https://cloud.google.com/load-balancing/docs/url-map) (HTTP+HTTPS for each service) 
    - 6 Reserved static IP addresses (used for the EndPoints to provide domain name)
    - 6 Google managed SSL Global Certificates
    - 6 Global Target HTTP proxies; 6 Global Target HTTPS(s) proxies

*Container-native load balancing enables load balancers to target Pods directly and to make load distribution decisions at the Pod-level instead of at the VM-level.

## Known Constraints
Due to the existing out-of-the-box quotas (30 URL maps, 21 Static IP addresses globally, 30 SSL certificates) only *two*  instances of
Prior-Autherization full end-to-end solutions can be deployed within one GCP Project (even when using different GKE clusters and namespaces).

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

*Important:* PROJECT ID should not exceed 20 characters long, for the deployment to work out-of-the-box without any modifications.
Due to the way endpoints are generated for the demo purposes (and PROJECT ID is the part of the domain name to pass the trusted domain verification), we have to stay within the limits of the allowed domain name: 63 characters at max.

If you really need to adapt this Deployment to work with PROJECT ID that exceeds 20 characters, there is a manual step (a hack), you still might do (will be mentioned below).
Encouraged, to stay within 20 characters limit.



Set the PROJECT_ID environment variable to point to the GCP project and activate the config (replace <your_project_id> below):

```sh
  export PROJECT_ID=<your_project_id>
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

4. (Optional) Set ZONE REGION CLUSTER name not to use the defaults
```shell
export CLUSTER=<cluster-name>
export REGION=<your-region>
export ZONE=<your-zone>
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
   gcloud org-policies reset constraints/iam.disableServiceAccountKeyCreation --project $PROJECT_ID
   
```


## Deployment  <a name="deployment"></a>

> As mentioned above, if your PROJECT-ID happened to exceed 20 characters, you can manually modify the way endpoints look, by manually changing Lines: 4-9 in the  *DRLS-GCP/shared/.endpoints* file.
> Things you can actually change for the domain - is the part before the `.endpoints`
> 
> For example: `prior-auth.${KUBE_NAMESPACE}.endpoints.${PROJECT_ID}.cloud.goog` could become `pa.endpoints.${PROJECT_ID}.cloud.goog`

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
- Deploy DRLS components
  * Now everything is ready to get images deployed into the GCP cluster.


Wait for the pods to be created and get into Running state: (default )
```sh

  kubectl get pods -n demo-manual --watch
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

## EndPoints

There are two ways to see the list of created EndPoints.

Via commandline:
```shell
gcloud endpoints services list
```

Via the GCP UI, go to [EndPoints](https://pantheon.corp.google.com/endpoints/)

The entry point for the flow is the test emr service:
```shell
gcloud endpoints services list | grep emr
```

[//]: # (### Register the test-ehr)

[//]: # ()
[//]: # (1. Go to `<DTR>`/register.)

[//]: # (   - Client Id: **app-login**)

[//]: # (   - Fhir Server &#40;iss&#41;: **`<TEST_EHR>`/test-ehr/r4**)

[//]: # (2. Click **Submit**)

## Run the DRLS Flow 
1. Get the emr deploy address: 
```shell
gcloud endpoints services list --filter="TITLE=( crd-request-generator-service )" --format "list(NAME)"
```
2. Go to the address retrieved above in the web browser.
5. Click **Patient Select** button in upper left.
6. Find **William Oster** in the list of patients and click the dropdown menu next to his name.
7. Select **E0470** in the dropdown menu.
8. Click anywhere in the row for William Oster.
9. Click **Submit** at the bottom of the page.
10. After several seconds you should receive a response in the form of two **CDS cards**:
     - **Respiratory Assist Device**
     - **Positive Airway Pressure Device**
11. Select **Order Form** on one of those CDS cards.
12. If you are asked for login credentials, use **alice** for username and **alice** for password.
13. A webpage should open in a new tab, and after a few seconds, a questionnaire should appear.

Congratulations! DRLS is fully installed and ready for you to use!

## Tear Down  <a name="teardown"></a>
Following command will delete all resources in the KUBE_NAMESPACE and prevent from running resources when unwanted. 
```sh
  DRLS-GCP/jobs/destroy.sh
```
## Useful commands <a name="commands"></a>

List of created SSL certificates:
```shell
gcloud compute ssl-certificates list 
```

Delete Managed certificate:
```shell
gcloud compute ssl-certificates delete <name> 
```

List of reserved IP addresses:
```shell
gcloud compute addresses list --global --format "table(name, address, status)"
```

Delete reserved address:
```shell
gcloud compute addresses delete <name> --global
```
List of Cloud Endpoints:
```shell
gcloud endpoints services list
```

Delete Cloud End Point: (operation has grace period of 30 days )
```shell
gcloud endpoints services delete <service_name> --project=<project_id> --async
```


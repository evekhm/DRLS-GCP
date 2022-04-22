# Overview
Here are the steps explaining how to create your own Argolis environment for the Development of the PA Solution.
We are very excited about your code changes, and want to make this process as smooth as possible!

# Prerequisites  <a name="prerequisites"></a>

### GitLab Access
> Currently, this flow requires special access for the GitLab Repository and Container Registry, so a Personal Access Token is needed for the setup.
You will need to have permissions for the [HCLS Project](https://gitlab.com/gcp-solutions/hcls/claims-modernization) and generated Personal Access Token with `read_registry` and `read_repository` scope.
In case of planning on contributing back, the scope needs also to include `write_registry` and `write_repository`.

- Create a [Personal Access Token](https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html#create-a-personal-access-token) further referred as TOKEN.
- Save this token in your password management tool. It will not be accessible after this page is closed.


# Steps
## 1. Branching
First things first. Be sure to branch off from the default branch and push your changes to GitLab for the desired Project/Application.
If you are modifying multiple components from different repositories, you must use the same branch name, lets call it `YOUR-FEATURE`.

## 2. Argolis Setup
Some manual steps are required to get the Argolis Environment configured for the deployment.
1. Create Argolis Project with Billing Account.
2. In the Cloud Shell Terminal:

- Set Environment Variables:
  ```shell
  export PROJECT_ID=<your_project_id>
  export TOKEN=<your_gitlab_token>
  export USERNAME=<your_gitlab_username>
  export WORKDIR=argolis-pa-demo
  ```

To get access to GitLab sources following command needs to be run:
  ```shell
  docker login -u $USERNAME -p $TOKEN registry.gitlab.com
  ```


```shell
mkdir "$WORKDIR" && cd "$WORKDIR"
git clone https://oauth2:$TOKEN@gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/gke-deploy-env.git gke-deploy-env
bash gke-deploy-env/argolis_prepare.sh
```

## 3. Gitlab Agent Setup
Go to [gke-deploy-env](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/gke-deploy-env).

### Register
- Copy [.gitlab/agents/argolis/config.yaml](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/gke-deploy-env/-/tree/main/.gitlab/agents/argolis/config.yaml) to `.gitlab/agents/<USERNAME>-agent/config.yaml`
- Push changes to default branch.
- Optionally check about detailed GitLab Agent Registration [Instructions](https://docs.gitlab.com/ee/user/clusters/agent/install/index.html#create-the-agents-configuration-file).

- Go to [Kubernetes page of this project](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/gke-deploy-env/-/clusters) and select Actions->Connect with Agent.
    - Select the `<USERNAME>-agent` you used -> Register 
    - Open a CLI and connect to the cluster you created in the step above.
    - Copy the  `docker run` command.


### Install
- Go to the Argolis Cloud Shell:
  - Connect to the created Cluster
  - Run the copied command
  - Verify that Agents appears as `Connected` (Might take few minutes)


## 4. DRLS-GCP Setup
1. Branch off [DRLS-GCP Project](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/DRLS-GCP) using `YOUR-FEATURE` name. 
2. Update [Settings-> CI/CD](https://gitlab.com/gcp-solutions/hcls/claims-modernization/pa-ref-impl/DRLS-GCP/-/settings/ci_cd)

- Add `<USERNAME>-SERVICE_ACCOUNT_FILE` file downloaded in Step 2.
  - Use the json key file downloaded in step 2, copy/paste and save it as a variable inside CI/CD Settings of the DRLS-GCP project
  - Type: File
  - Make sure to uncheck 'Protected variable' checkbox

3. Modify .gitlab-ci.yml following variables accordingly on `YOUR-FEATURE` branch and push the changes:

Replace <USERNAME> and  <YOUR-PROJECT-ID> accordingly:
```shell
KUBE_CONTEXT_DEV: ${CI_PROJECT_NAMESPACE}/gke-deploy-env:<USERNAME>-agent
PROJECT_ID_DEV:  <YOUR-PROJECT-ID>
SERVICE_ACCOUNT_FILE_DEV: <USERNAME>-SERVICE_ACCOUNT_FILE
```


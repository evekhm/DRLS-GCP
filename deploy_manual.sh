# Executes steps as Gitlab CI/CD would do
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#  USER/TOKEN - GitLab User and Token
#  SERVICE_ACCOUNT - Name of the Manually created SERVICE_ACCOUNT
#  SERVICE_ACCOUNT_FILE - downloaded JSON KEY for the Service Account
#  PROJECT_ID
#  CLUSTER

# ARGPARSE
while getopts a:p:u:t:c: flag
do
    case "${flag}" in
        a) SERVICE_ACCOUNT=${OPTARG};;
        c) CLUSTER=${OPTARG};;
        p) PROJECT_ID=${OPTARG};;
        u) CI_DEPLOY_USER=${OPTARG};;
        t) CI_DEPLOY_PASSWORD=${OPTARG};;
        *) echo "Wrong arguments provided" && exit
    esac
done

source shared/SET.manual
source "${DIR}/shared/vars"

#Steps:
## 1. Manual Steps: Pre-requisites
# Create GCP Project
# Create Service Account, export SERVICE_ACCOUNT=<name>

#Argolis
# Run
#gcloud services enable orgpolicy.googleapis.com
#gcloud org-policies reset constraints/compute.vmExternalIpAccess --project "${PROJECT_ID}"

##############################To be part of DTP#################################
#  - Use Infrastructure Project for Provisioning


# Currently Done manually when setting up GitLab CI/CD
PROJECT=gke-deploy-env
PROJECT_REPO=${CI_SERVER_HOST}/${APPLICATION_NAMESPACE}/${PROJECT}.git

cd "$DIR/../" || exit
if [ ! -d "$PROJECT" ]; then
  git clone https://"${CI_DEPLOY_USER}":"${CI_DEPLOY_PASSWORD}"@"${PROJECT_REPO}" $PROJECT
fi
cd "$PROJECT" || exit
bash ./provision.sh -p "$PROJECT_ID" -a "$SERVICE_ACCOUNT"
source vars
cd ..
############################### End of DTP######################################


############ Done Part of GitLab CI/CD Steps ##################

# setup cluster (done as part of GitLab prepare stage)
bash "${DIR}"/execute_prepare.sh


# Done by GitLab CI/CD template
create_secret() {
    echo "Creating secret $SECRET in namespace $KUBE_NAMESPACE required for private repository access"
    if kubectl get secrets --namespace="$KUBE_NAMESPACE" | grep $SECRET; then
      echo "$SECRET exists in namespace $KUBE_NAMESPACE, skipping..."
    else
      echo "Logging into $CI_REGISTRY with deploy token $CI_DEPLOY_USER"
      docker login -u $CI_DEPLOY_USER -p $CI_DEPLOY_PASSWORD $CI_REGISTRY
      kubectl create secret generic $SECRET --from-file=.dockerconfigjson=$HOME/.docker/config.json --type=kubernetes.io/dockerconfigjson --namespace=$KUBE_NAMESPACE
      kubectl get secrets --namespace="$KUBE_NAMESPACE" | grep $SECRET
    fi
}
# Create KSA, secret (done part of .deploy template)
create_secret

# 4. Build keycloak
bash "${DIR}"/build_keycloak.sh

# Deploy All Applications
# create_CDS_Library_zip
#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution

# Executes steps as Gitlab CI/CD would do
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."

#  USER/TOKEN - GitLab User and Token
#  SERVICE_ACCOUNT - Name of the Manually created SERVICE_ACCOUNT
#  PROJECT_ID
echo "======= Running  $(basename "$0") with KUBE_NAMESPACE=$KUBE_NAMESPACE  PROJECT_ID=$PROJECT_ID ======="

source "${DIR}/shared/SET.manual"
source "${DIR}/shared/vars"

function usage(){
    echo "Sample usage: $(basename "$0") -p <PROJECT_ID> -t <TOKEN> -u <USERNAME> "
    echo "Defaults:"g
    echo "   PROJECT_ID=$PROJECT_ID"
    echo "   CLUSTER=$CLUSTER"
    echo "   ZONE=$ZONE"
    echo "   REGION=$REGION"
    echo "   ARGOLIS=$ARGOLIS"
    echo "   KUBE_NAMESPACE=$KUBE_NAMESPACE"
    echo "   USERNAME=$USERNAME"
    echo "   BUCKET_NAME=$BUCKET_NAME"
    echo "   DB_NAME=$DB_NAME"
    echo "   NETWORK=$NETWORK"
    exit 1
}
# ARGPARSE
while getopts p:u:t:h flag
do
    case "${flag}" in
        p) PROJECT_ID=${OPTARG};;
        h) HELP='true';;
        u) USERNAME=${OPTARG};;
        t) TOKEN=${OPTARG};;
        *) echo "Wrong arguments provided" && usage
    esac
done

CI_DEPLOY_USER=$USERNAME
CI_DEPLOY_PASSWORD=$TOKEN

export CI_DEPLOY_USER
export CI_DEPLOY_PASSWORD


if [ -n "$HELP" ]; then
  usage
fi

if [ -z  ${PROJECT_ID+x} ]  || [ -z ${CI_DEPLOY_USER+x} ] || [ -z ${CI_DEPLOY_PASSWORD+x} ]; then
  echo "Missing (any of) the required parameters PROJECT_ID=$PROJECT_ID USERNAME=$USERNAME TOKEN."
  usage
fi


gcloud config set project $PROJECT_ID

function provision(){
  # Currently Done manually when setting up GitLab CI/CD
  local PROJECT=gke-deploy-env
  local PROJECT_REPO=${CI_SERVER_HOST}/${APPLICATION_NAMESPACE}/${PROJECT}.git
  local DD="$ROOT/$PROJECT"
  if [ ! -d "$DD" ]; then
    git clone https://"${CI_DEPLOY_USER}":"${CI_DEPLOY_PASSWORD}"@"${PROJECT_REPO}" "$DD"
  else
    cd "$DD" || exit
    git pull
    cd ..
  fi

  bash "${DD}"/provision_demo.sh -p "$PROJECT_ID"
}



##############################To be part of DTP#################################
#  - Use Infrastructure Project for Provisioning
provision
############################### End of DTP######################################


############ Done Part of GitLab CI/CD Steps ##################

# setup cluster (done as part of GitLab prepare stage)
"${DIR}"/jobs/prepare_cluster.sh

source "${DIR}"/shared/.endpoints

# Deploy All Applications
bash "${DIR}"/jobs/deploy_applications.sh

bash "${DIR}"/steps
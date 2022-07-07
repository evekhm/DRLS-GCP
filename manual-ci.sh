#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution

# Executes steps as Gitlab CI/CD would do
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT="$DIR/.."

#  USER/TOKEN - GitLab User and Token
#  SERVICE_ACCOUNT - Name of the Manually created SERVICE_ACCOUNT
#  PROJECT_ID

function usage(){
    echo "Missing (any of) the required parameters PROJECT_ID=$PROJECT_ID USERNAME=$USERNAME TOKEN."
    echo "Sample usage: $(basename "$0") -p <PROJECT_ID> -t <TOKEN> -u <USERNAME> "
    exit 1
}
# ARGPARSE
while getopts p:u:t: flag
do
    case "${flag}" in
        p) PROJECT_ID=${OPTARG};;
        u) CI_DEPLOY_USER=${OPTARG};;
        t) CI_DEPLOY_PASSWORD=${OPTARG};;
        *) echo "Wrong arguments provided" && usage
    esac
done

if [ -z  ${PROJECT_ID+x} ]  || [ -z ${CI_DEPLOY_USER+x} ] || [ -z ${CI_DEPLOY_PASSWORD+x} ]; then
  usage
fi

export CI_DEPLOY_USER
export CI_DEPLOY_PASSWORD


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

source "${DIR}/shared/SET.manual"

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

bash "${DIR}"/jobs/print_steps.sh
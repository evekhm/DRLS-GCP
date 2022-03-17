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


#Argolis
# Run
#gcloud services enable orgpolicy.googleapis.com
#gcloud org-policies reset constraints/compute.vmExternalIpAccess --project "${PROJECT_ID}"

function provision(){
  # Currently Done manually when setting up GitLab CI/CD
  local PROJECT=gke-deploy-env
  local PROJECT_REPO=${CI_SERVER_HOST}/${APPLICATION_NAMESPACE}/${PROJECT}.git
  local DD="$ROOT/$PROJECT"
  if [ ! -d "$DD" ]; then
    git clone https://"${CI_DEPLOY_USER}":"${CI_DEPLOY_PASSWORD}"@"${PROJECT_REPO}" "$DD"
  fi

  bash "${DD}"/services_enable.sh -p "$PROJECT_ID"
  bash "${DD}"/create_cluster.sh -p "$PROJECT_ID"
}

##############################To be part of DTP#################################
#  - Use Infrastructure Project for Provisioning
provision
############################### End of DTP######################################


############ Done Part of GitLab CI/CD Steps ##################
source "${DIR}/shared/SET.manual"
# setup cluster (done as part of GitLab prepare stage)
"${DIR}"/jobs/prepare_cluster.sh

#Build keycloak, prevent writing to 'released' images
APPLICATION=auth
IMAGE_REPO="${CI_REGISTRY}/${APPLICATION_NAMESPACE}/${APPLICATION}/manual"
IMAGE_TAG="$IMAGE_REPO:$PROJECT_ID-$KUBE_NAMESPACE"
IMAGE="$IMAGE_TAG" LATEST="$IMAGE_TAG" bash "${DIR}"/jobs/build_keycloak.sh

# Deploy All Applications All except auth
bash "${DIR}"/jobs/deploy_applications.sh -x ${APPLICATION}
IMAGE=$IMAGE_TAG bash "${DIR}"/jobs/deploy_application.sh -a ${APPLICATION}

bash "${DIR}"/jobs/print_steps.sh
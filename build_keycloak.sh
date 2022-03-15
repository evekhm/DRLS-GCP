#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution

# File from the previous step with Service IPs
echo "Running build_keycloak VARIABLES_FILE=$VARIABLES_FILE ..."

cat "${VARIABLES_FILE}"
source "${VARIABLES_FILE}"

APPLICATION=auth
IMAGE_REPO="${CI_REGISTRY}/${APPLICATION_NAMESPACE}/${APPLICATION}/${IMAGE_TYPE}"
PROJECT_REPO=${CI_SERVER_HOST}/${APPLICATION_NAMESPACE}/${APPLICATION}.git
IMAGE="${IMAGE_REPO}":"${CI_JOB_ID}"
LATEST="${IMAGE_REPO}:latest"

echo  "IMAGE=$IMAGE, IMAGE_LATEST=$LATEST, PROJECT_REPO=$PROJECT_REPO"

# TEST_EHR IP needs to be embedded into the Image
git clone https://"${CI_DEPLOY_USER}":"${CI_DEPLOY_PASSWORD}"@"${PROJECT_REPO}" $APPLICATION
cd $APPLICATION
sed  's|__TEST_EHR__|'"$TEST_EHR"'|g; ' config/ClientFhirServerRealm.sample.json > config/ClientFhirServerRealm.json
docker login -u "${CI_REGISTRY_USER}" -p "${CI_REGISTRY_PASSWORD}" "${CI_REGISTRY}"
docker build -f Dockerfile -t "$IMAGE" -t "$LATEST" .
docker push "$IMAGE"
docker push "$LATEST"
echo "Done build_keycloak !"




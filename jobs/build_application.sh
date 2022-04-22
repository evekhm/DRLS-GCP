#!/usr/bin/env bash
set -e # Exit if error is detected during pipeline execution
PWD=$(pwd)
JOBS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# ARGPARSE
while getopts a: flag
do
    case "${flag}" in
        a) APPLICATION=${OPTARG};;
        *) echo "Wrong arguments provided" && exit
    esac
done

echo "=======  Running $(basename "$0") APPLICATION=$APPLICATION ======= "
if [ -z "$APPLICATION" ]; then
  echo "Error APPLICATION is not set"
  echo "Example usage: $(basename "$0") -a <application_name>"
  exit
fi

REPO_SUB="$(printf "${REPO_SUB}" | tr -c 'a-zA-Z0-9_.-' - | sed 's/^[.-]*//' | cut -c -128 | tr '[:upper:]' '[:lower:]')" #Hack because CI_MERGE_REQUEST_SOURCE_BRANCH_NAME does not have a SLUG
IMAGE_REPO="${CI_REGISTRY}/${APPLICATION_NAMESPACE}/${APPLICATION}/${REPO_SUB}${IMAGE_TYPE}"
PROJECT_REPO=${CI_SERVER_HOST}/${APPLICATION_NAMESPACE}/${APPLICATION}.git

DD="$JOBS_DIR/../../$APPLICATION"
if [ ! -d "$DD" ]; then
  git clone https://"${CI_DEPLOY_USER}":"${CI_DEPLOY_PASSWORD}"@"${PROJECT_REPO}" "$DD"
fi

cd "$DD" || exit
if [ -n "$CI_JOB_ID" ]; then
  VERSION=$CI_JOB_ID
else
  DATE=$( date '+%F-%H-%M-%S' )
  SHA=$(git log -1 --pretty=%h)
  VERSION="${SHA}-${DATE}"
fi

IMAGE=${IMAGE:-"${IMAGE_REPO}":"${VERSION}"}
LATEST=${LATEST:-"${IMAGE_REPO}:latest"}

echo  "IMAGE=$IMAGE, IMAGE_LATEST=$LATEST"
docker login -u "${CI_DEPLOY_USER}" -p "${CI_DEPLOY_PASSWORD}" "${CI_REGISTRY}"

IMAGE=$IMAGE LATEST=$LATEST bash "$JOBS_DIR"/../applications/"$APPLICATION"/bin/docker_build

docker push "$IMAGE"
docker push "$LATEST"
cd "$PWD" || exit
echo "Done build $APPLICATION !"




#!/usr/bin/env bash
# Example APPLICATION=crd deploy_application_job.sh
set -e # Exit if error is detected during pipeline execution

JOBS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APPLICATIONS_DIR="$JOBS_DIR"/../applications

# ARGPARSE Currently can exclude only one application, could be extended to a list later
while getopts x: flag
do
    case "${flag}" in
        x) EXCLUDE=${OPTARG};;
        *) echo "Wrong arguments provided" && exit
    esac
done


for DIR in "${APPLICATIONS_DIR}"/*/
do
    DD=$(basename "${DIR%*/}")
    if [ "$DD" == "$EXCLUDE" ]; then
      echo ">>>>> Skipping $DD (Excluded) <<<<<<"
    else
       "${JOBS_DIR}/deploy_application.sh" -a "$DD"
    fi
done

kubectx
kubens
echo "DONE!"

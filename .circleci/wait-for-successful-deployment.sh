#!/bin/bash

# Wait until the desired docker image is running in the target namespace and
# all pods running other (old) images have been stopped
#
# Use in the CircleCI pipeline to check that a deployment has completed successfully
#
# Usage:
#   bash wait-for-successful-deployment.sh "<kube namespace>" "<app name>" "<docker image tag>"
#
# Exit status code:
#   0 (success) when all pods are running the image
#   1 (failure) if gave up waiting for all pods to run the image

# Configure bash to exit with an error code if any command in this script fails
# Read more: https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -euo pipefail

NAMESPACE="$1"
APP_NAME="$2"
IMAGE_TAG="$3"

# Wait for approx 5 minutes before giving up
MAX_ATTEMPTS=30 # Number of checks to perform before giving up
SLEEP_SECONDS=10 # Number of seconds to wait between each check

i=1
while [ $i -le $MAX_ATTEMPTS ]
do
  echo "Attempt $i of $MAX_ATTEMPTS"

  # Find pods with status 'Running'
  RUNNING_PODS=$(kubectl -n $NAMESPACE get pods --selector=app=$APP_NAME --field-selector=status.phase=Running --output yaml)

  # Count the total number of pods running
  RUNNING_POD_COUNT=$(echo "$RUNNING_PODS" | yq eval ".items | length" -)

  # Extract a list of docker images running on those pods
  RUNNING_POD_IMAGES=$(echo "$RUNNING_PODS" | yq eval ".items.[].spec.containers.[].image" -)

  # Count the number of pods running the desired docker image
  # Note: `grep -c` gives a non-zero exit code if 0 matches are found, so `|| true` is used to avoid that behaviour
  RUNNING_DESIRED_IMAGE_COUNT=$(echo "$RUNNING_POD_IMAGES" | grep -c ":$IMAGE_TAG" || true)

  if [ "$RUNNING_DESIRED_IMAGE_COUNT" -eq 0 ]; then
    echo "No pods are running the desired image"
  elif [ "$RUNNING_DESIRED_IMAGE_COUNT" -lt "$RUNNING_POD_COUNT" ]; then
    # Not all pods are running the new image yet
    echo "$RUNNING_DESIRED_IMAGE_COUNT out of $RUNNING_POD_COUNT pods are running the desired image"
  else
    # All pods are now running the new image
    echo "All $RUNNING_POD_COUNT pods are now running the desired image"
    # End the script with a 'success' exit code
    exit 0
  fi

  echo # line break to separate attempts
  sleep $SLEEP_SECONDS
  i=$[$i+1]
done

echo "Giving up - something must have gone wrong with the deployment"
echo # line break
echo "This is the current state of pods running in $NAMESPACE:"
kubectl -n $NAMESPACE get pods

# End the script with a 'failure' exit code
exit 1

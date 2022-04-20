DEPLOYMENT=$1
IMAGE=$2
PROJECT_ID=$(gcloud config get-value project 2> /dev/null);
echo "Patching $DEPLOYMENT with image $IMAGE"

sed
kubectl patch deployment $DEPLOYMENT -p \
      "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"$DEPLOYMENT\",\"image\":\"gcr.io/$PROJECT_ID/$IMAGE\"}]}}}}"

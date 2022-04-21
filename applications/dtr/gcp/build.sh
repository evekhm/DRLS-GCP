IMAGE=$1
TAG=gcr.io/$PROJECT_ID/$IMAGE
echo "Building image $TAG..."
PROJECT_ID=$(gcloud config get-value project 2> /dev/null);
REGION=$(gcloud config get-value compute/region 2> /dev/null);

gcloud builds submit --region=$REGION --tag $TAG
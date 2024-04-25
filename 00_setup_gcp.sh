#!/bin/bash

source args

## enable APIS ------------------------------------------------------------
echo "Enabling Google Cloud APIs..."

gcloud services enable \
    discoveryengine.googleapis.com \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com \
    run.googleapis.com 


## artifact registry --------------------------------------------------------
echo "Create artifact registry if needed..."

## Create artifact registry only if it does not already exist
# Check if the repository already exists
if gcloud artifacts repositories describe $DOCKER_REPO --location=$REGION &> /dev/null; then
  echo "Repository $DOCKER_REPO already exists:"
  gcloud artifacts repositories describe $DOCKER_REPO --location=$REGION
else
  # Create the repository if it doesn't exist
  echo "Respository does not exist. Creating...."
  gcloud artifacts repositories create $DOCKER_REPO \
    --repository-format=docker \
    --location=$REGION \
    --description="Docker repository for demo search app"
  echo "Repository created."
  gcloud artifacts repositories describe $DOCKER_REPO --location=$REGION
fi 

## service account --------------------------------------------------------
echo "Create service account if needed..."

# create service account only if it does not already exist
if gcloud iam service-accounts list | grep $SVC_ACCOUNT_EMAIL &> /dev/null; then
  echo "Service account $SVC_ACCOUNT_EMAILalready exists:"
  gcloud iam service-accounts describe $SVC_ACCOUNT_EMAIL
else
  # Create the service account if it doesn't exist
  echo "Service account does not exist. Creating...."
  gcloud iam service-accounts create $SVC_ACCOUNT_EMAIL \
        --description="For demo Vertex AI search app" \
        --display-name=$SVC_ACCOUNT_NAME
  echo "Service account created."
  gcloud iam service-accounts describe $SVC_ACCOUNT_EMAIL
fi

echo "Bind IAM policies to service account..."

if ! gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --format='value(bindings.role)' \
  --filter="bindings.role=roles/ai-platform.user AND bindings.members:$SVC_ACCOUNT_EMAIL" &> /dev/null; then
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SVC_ACCOUNT_EMAIL" \
    --role="roles/ai-platform.user"
fi

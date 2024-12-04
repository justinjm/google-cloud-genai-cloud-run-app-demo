#!/bin/bash

source args

## enable APIS ------------------------------------------------------------
echo "Enabling Google Cloud APIs..."

enabled_services=$(gcloud services list --enabled | awk '{print $1}')

# 2. Services we WANT to ensure are enabled
services_to_enable=(
  "storage.googleapis.com"
  "artifactregistry.googleapis.com" 
  "cloudbuild.googleapis.com"
  "discoveryengine.googleapis.com"
  "run.googleapis.com"
  )

# 3. Check each desired service against the enabled list
for service in "${services_to_enable[@]}"; do
    if ! echo "$enabled_services" | grep -q "$service"; then
        echo "Enabling $service..."
        gcloud services enable "$service"
    else
        echo "$service is already enabled."
    fi
done

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

## TODO - grant default compute service account 
# - grant storage object admin access 
# - artifact repo access 

# Grant Storage Admin role for storage access
if ! gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --format='value(bindings.role)' \
  --filter="bindings.role=roles/storage.objectAdmin AND bindings.members:$DEFAULT_SVC_ACCOUNT_EMAIL" &> /dev/null; then
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$DEFAULT_SVC_ACCOUNT_EMAIL" \
    --role="roles/storage.objectAdmin"
fi

if ! gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --format='value(bindings.role)' \
  --filter="bindings.role=roles/artifactregistry.writer AND bindings.members:$DEFAULT_SVC_ACCOUNT_EMAIL" &> /dev/null; then
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$DEFAULT_SVC_ACCOUNT_EMAIL" \
    --role="roles/artifactregistry.writer"
fi

## service account --------------------------------------------------------
echo "Create service account if needed..."

# create service account only if it does not already exist
if gcloud iam service-accounts list | grep $SVC_ACCOUNT_EMAIL &> /dev/null; then
  echo "Service account $SVC_ACCOUNT_EMAIL already exists:"
  gcloud iam service-accounts describe $SVC_ACCOUNT_EMAIL
else
  # Create the service account if it doesn't exist
  echo "Service account does not exist. Creating...."
  gcloud iam service-accounts create $SVC_ACCOUNT_NAME \
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

if ! gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --format='value(bindings.role)' \
  --filter="bindings.role=roles/discoveryengine.editor AND bindings.members:$SVC_ACCOUNT_EMAIL" &> /dev/null; then
  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SVC_ACCOUNT_EMAIL" \
    --role="roles/discoveryengine.editor"
fi
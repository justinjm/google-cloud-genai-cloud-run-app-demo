#!/bin/bash

source args

# Ask the user if they want to proceed with the build and deploy
echo "You are currently set to the project $PROJECT_ID."
echo "Do you want to proceed with the build and deploy to Cloud Run (y/n)?"
read -r ANSWER

# If the user answers "y", proceed with the build and deploy
if [[ $ANSWER == "y" ]]; then
  echo "starting build of container image in cloud build from local source code..."

  gcloud builds submit --region=$REGION --tag=$IMAGE_URI --timeout=1h ./build

  echo "starting deploy to cloud run..."

  gcloud run deploy $CLOUD_RUN_SERVICE_NAME \
    --image $IMAGE_URI \
    --region=$REGION \
    --cpu 4 \
    --min-instances=1 \
    --max-instances=2 \
    --allow-unauthenticated \
    --memory 2Gi \
    --timeout 30m \
    --service-account=$SVC_ACCOUNT_EMAIL

# If the user answers "n", exit the script
elif [[ $ANSWER == "n" ]]; then
  echo "Build and deploy cancelled."
  exit 0
# If the user enters anything other than "y" or "n", prompt them again
else
  echo "Invalid answer. Please enter either 'y' or 'n'."
  read -r ANSWER
fi
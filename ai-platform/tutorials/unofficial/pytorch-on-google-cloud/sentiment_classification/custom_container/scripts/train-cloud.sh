#!/bin/bash
# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================
# This script performs cloud training for a PyTorch model.

echo "Submitting AI Platform PyTorch job"

# PROJECT_ID: Change to your project id
PROJECT_ID=rthallam-demo-project

# BUCKET_NAME: Change to your bucket name.
BUCKET_NAME=rthallam-demo-project

# JOB_NAME: the name of your job running on AI Platform.
JOB_PREFIX=pytorch_job_bert_classifier
JOB_NAME=${JOB_PREFIX}_$(date +%Y%m%d_%H%M%S)

# This can be a GCS location to a zipped and uploaded package
PACKAGE_PATH=./trainer

# REGION: select a region from https://cloud.google.com/ai-platform/training/docs/regions
# or use the default '`us-central1`'. The region is where the job will be run.
REGION=us-central1

# JOB_DIR: Where to store prepared package and upload output model.
JOB_DIR=gs://${BUCKET_NAME}/${JOB_PREFIX}/models/${JOB_NAME}

# IMAGE_REPO_NAME: set a local repo name to distinquish our image
IMAGE_REPO_NAME=pytorch_gpu_bert_classifier

# IMAGE_TAG: an easily identifiable tag for your docker image
IMAGE_TAG=imdb_bert_pytorch_gpu

# IMAGE_URI: the complete URI location for Cloud Container Registry
IMAGE_URI=gcr.io/${PROJECT_ID}/${IMAGE_REPO_NAME}:${IMAGE_TAG}

# Build the docker image
docker build -f Dockerfile -t ${IMAGE_URI} ./

# Deploy the docker image to Cloud Container Registry
docker push ${IMAGE_URI}

gcloud ai-platform jobs submit training ${JOB_NAME} \
    --region ${REGION} \
    --master-image-uri ${IMAGE_URI} \
    --scale-tier=CUSTOM \
    --master-machine-type=n1-standard-8 \
    --master-accelerator=type=nvidia-tesla-t4,count=2 \
    --job-dir ${JOB_DIR} \
    -- \
    --model-name="finetuned-bert-classifier"

# Stream the logs from the job
gcloud ai-platform jobs stream-logs ${JOB_NAME}

# Verify the model was exported
echo "Verify the model was exported:"
gsutil ls ${JOB_DIR}/
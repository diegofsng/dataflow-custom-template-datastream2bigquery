#!/bin/bash

# After the Cloud Build has finished and has generated the Docker artifact and Jar Artifact, we should run the next:

# The docker image will need to refer to sha tag
# example:
# <REGION>-docker.pkg.dev/<PROJECT_ID>/<REPOSITORY>/<IMAGE>@sha256:<SHA_TAG>

PROJECT="<PROJECT-ID>"
REGION="us-central1"
SUBNETWORK="regions/<REGION>/subnetworks/<SUBNETWORK_NAME>"
IMAGE_NAME=datastream-to-bigquery
BUCKET_NAME="gs://<BUCKET-NAME>"
METADATA_FILE_LOCATION=${BUCKET_NAME}/images/${IMAGE_NAME}-image-spec.json
DOCKER_IMAGE_TAG="<change for the name of docker image>"
BASE_CONTAINER_IMAGE=gcr.io/dataflow-templates-base/java17-template-launcher-base # CHANGE IF IT IS NEEDED TO RUN IN A DIFFERENT JAVA VERSION
SHA_IMAGE_VERSION_TAG='<SHA TAG OF IMAGE>'
APP_ROOT=/template/${IMAGE_NAME}
DATAFLOW_JAVA_COMMAND_SPEC=${APP_ROOT}/resources/${IMAGE_NAME}-command-spec.json
TOPIC=projects/data-test-df/topics/my_integration_notifs
SUBSCRIPTION=projects/data-test-df/subscriptions/pubsubdata
DEADLETTER_TABLE=${PROJECT}:${DATASET_TEMPLATE}.dead_letter

# DATAFLOW CONFIGURATION FLAGS
# MODIFY ACCORDINGLY
INPUT_FILE_PATTERN=gs://<BUCKET_DATASTREAM_FILE_LOCATION>/<ROUTE>.avro
GCS_PUBSUB_SUBSCRIPTION=<PUBSUB_SUBSCRIPTION>
OUTPUT_STAGING_DATASET_TEMPLATE=<STAGE_DATASET_TEMPLATE>
OUTPUT_DATASET_TEMPLATE=<OUTPUT_DATASET_TEMPLATE>
DEADLETTER_QUEUE_DIRECTORY=<deadLetterQueueDirectory>
FILE_READ_CONCURRENCY=50
MERGE_FREQUENCY_MINUTES=1
DLQ_RETRY_MINUTES=10
APPLY_MERGE=true
MERGE_CONCURRENCY=50
AUTOSCALING_ALGORITHM=THROUGHPUT_BASED
NUM_WORKERS=5
MAX_NUM_WORKERS=20
WORKER_MACHINE_TYPE=n2-standard-4
STORAGE_WRITE_API_TRIGGERING_FREQUENCY_SEC=60
USE_STORAGE_WRITE_API=true


gcloud config set project ${PROJECT}

# Upload of the metadata file to GS location. Be sure to create modify the metadata.json with the correct information
gsutil cp metadata.json ${METADATA_FILE_LOCATION}

# As we manually modified the metadata.json, we won't need to create a new version of it. 
# Be sure to upload metadata.json to the corresponding Cloud Storage Bucket as Dataflow will need to read this file
# This parameter will be needed to be set in the gcloud beta flex execution
# echo '
# {
#     "defaultEnvironment": { },
#     "image": "'${DOCKER_IMAGE_TAG}':'${SHA_IMAGE_VERSION_TAG}'",
#         "metadata": {
#         "name": "Datastream to BigQuery",
#             "description": "Streaming pipeline. Ingests messages from a stream in Datastream, transforms them, and writes them to a pre-existing BigQuery dataset as a set of tables.",
#                 "parameters": [
#                     {
#                         "label": "File location for Datastream file output in Cloud Storage.",
#                         "help_text": "This is the file location for Datastream file output in Cloud Storage, in the format: gs://${BUCKET}/${ROOT_PATH}/.",
#                         "name": "inputFilePattern",
#                         "param_type": "GCS_READ_FILE"
#                     },
#                     {
#                         "label": "The Pub/Sub subscription on the Cloud Storage bucket.",
#                         "help_text": "The Pub/Sub subscription used by Cloud Storage to notify Dataflow of new files available for processing, in the format: projects/{PROJECT_NAME}/subscriptions/{SUBSCRIPTION_NAME}",
#                         "name": "gcsPubSubSubscription",
#                         "is_optional": false,
#                         "regexes": [
#                             "^projects\\/[^\\n\\r\\/]+\\/subscriptions\\/[^\\n\\r\\/]+$|^$"
#                         ],
#                         "param_type": "PUBSUB_SUBSCRIPTION"
#                     },
#                     {
#                         "label": "Datastream output file format (avro/json).",
#                         "help_text": "The format of the output files produced by Datastream. Value can be avro or json.",
#                         "name": "inputFileFormat",
#                         "param_type": "TEXT",
#                         "is_optional": false
#                     },
#                     {
#                         "name": "rfcStartDateTime",
#                         "label": "The starting DateTime used to fetch from GCS (https://tools.ietf.org/html/rfc3339).",
#                         "help_text": "The starting DateTime used to fetch from GCS (https://tools.ietf.org/html/rfc3339).",
#                         "param_type": "TEXT",
#                         "is_optional": true
#                     },
#                     {
#                         "name": "fileReadConcurrency",
#                         "label": "File read concurrency.",
#                         "help_text": "The number of concurrent DataStream files to read. Default is 10.",
#                         "regexes": [
#                             "^[1-9][0-9]*$"
#                         ],
#                         "param_type": "TEXT",
#                         "is_optional": true
#                     },
#                     {
#                         "name": "javascriptTextTransformGcsPath",
#                         "label": "GCS location of your JavaScript UDF",
#                         "help_text": "The full URL of your .js file. Example: gs://your-bucket/your-function.js",
#                         "regexes": [
#                             "^gs:\\/\\/[^\\n\\r]+$"
#                         ],
#                         "param_type": "GCS_READ_FILE",
#                         "is_optional": true
#                     },
#                     {
#                         "name": "javascriptTextTransformFunctionName",
#                         "label": "The name of the JavaScript function you wish to call as your UDF",
#                         "help_text": "The function name should only contain letters, digits and underscores. Example: transform or transform_udf1.",
#                         "regexes": [
#                             "[a-zA-Z0-9_]+"
#                         ],
#                         "param_type": "TEXT",
#                         "is_optional": true
#                     },
#                     {
#                         "name": "outputStagingDatasetTemplate",
#                         "label": "Name or template for the dataset to contain staging tables.",
#                         "help_text": "This is the name for the dataset to contain staging tables. This parameter supports templates (e.g. {_metadata_dataset}_log or my_dataset_log). Normally, this parameter is a dataset name.",
#                         "param_type": "TEXT"
#                     },
#                     {
#                         "name": "outputDatasetTemplate",
#                         "label": "Template for the dataset to contain replica tables.",
#                         "help_text": "This is the name for the dataset to contain replica tables. This parameter supports templates (e.g. {_metadata_dataset} or my_dataset). Normally, this parameter is a dataset name.",
#                         "param_type": "TEXT"
#                     },
#                     {
#                         "label": "Project name for BigQuery datasets.",
#                         "help_text": "Project for BigQuery datasets to output data into. The default for this parameter is the project where the Dataflow pipeline is running.",
#                         "name": "outputProjectId",
#                         "is_optional": true,
#                         "param_type": "TEXT"
#                     },
#                     {
#                         "label": "Template for the name of staging tables.",
#                         "name": "outputStagingTableNameTemplate",
#                         "help_text": "This is the template for the name of staging tables (e.g. {_metadata_table}). Default is {_metadata_table}.",
#                         "is_optional": true,
#                         "param_type": "TEXT"
#                     },
#                     {
#                         "label": "Template for the name of replica tables.",
#                         "name": "outputTableNameTemplate",
#                         "help_text": "This is the template for the name of replica tables (e.g. {_metadata_table}). Default is {_metadata_table}.",
#                         "is_optional": true,
#                         "param_type": "TEXT"
#                     },
#                     {
#                         "label": "Dead letter queue directory.",
#                         "name": "deadLetterQueueDirectory",
#                         "help_text": "This is the file path for Dataflow to write the dead letter queue output. This path should not be in the same path as the Datastream file output.",
#                         "is_optional": false,
#                         "param_type": "TEXT"
#                     },
#                     {
#                         "label": "Name or template for the stream to poll for schema information.",
#                         "name": "streamName",
#                         "help_text": "This is the name or template for the stream to poll for schema information. Default is {_metadata_stream}. The default value is enough under most conditions.",
#                         "is_optional": true,
#                         "param_type": "TEXT"
#                     },
#                     {
#                         "name": "dataStreamRootUrl",
#                         "label": "Datastream API URL (only required for testing)",
#                         "help_text": "Datastream API URL",
#                         "param_type": "TEXT",
#                         "is_optional": true
#                     },
#                     {
#                         "name": "useStorageWriteApi",
#                         "label": "Storage Write activation",
#                         "help_text": "Activate storage write",
#                         "param_type": "TEXT",
#                         "is_optional": true
#                     },
#                     {
#                         "name": "storageWriteApiTriggeringFrequencySec",
#                         "label": "Frequency storage API",
#                         "help_text": "Activate storage write",
#                         "param_type": "TEXT",
#                         "is_optional": true
#                     },
#                     {
#                         "name": "mergeFrequencyMinutes",
#                         "label": "The number of minutes between merges for a given table.",
#                         "help_text": "The number of minutes between merges for a given table.",
#                         "param_type": "TEXT",
#                         "is_optional": true
#                     },
#                     {
#                         "name": "dlqRetryMinutes",
#                         "label": "The number of minutes between DLQ Retries.",
#                         "help_text": "The number of minutes between DLQ Retries.",
#                         "param_type": "TEXT",
#                         "is_optional": true
#                     },
#                     {
#                         "name": "applyMerge",
#                         "label": "A switch to disable MERGE queries for the job.",
#                         "help_text": "A switch to disable MERGE queries for the job.",
#                         "param_type": "TEXT",
#                         "is_optional": true
#                     },
#                     {
#                         "name": "mergeConcurrency",
#                         "label": "Concurrent queries for merge.",
#                         "help_text": "The number of concurrent BigQuery MERGE queries. Only effective when applyMerge is set to true. Default is 30.",
#                         "regexes": [
#                             "^[1-9][0-9]*$"
#                         ],
#                         "param_type": "TEXT",
#                         "is_optional": true
#                     },
#                     {
#                         "name": "autoscalingAlgorithm",
#                         "label": "Autoscaling algorithm to use",
#                         "help_text": "Autoscaling algorithm to use: THROUGHPUT_BASED",
#                         "param_type": "TEXT",
#                         "is_optional": true
#                     },
#                     {
#                         "name": "numWorkers",
#                         "label": "Number of workers Dataflow will start with",
#                         "help_text": "Number of workers Dataflow will start with",
#                         "param_type": "TEXT",
#                         "is_optional": true
#                     },
#                     {
#                         "name": "maxNumWorkers",
#                         "label": "Maximum number of workers Dataflow job will use",
#                         "help_text": "Maximum number of workers Dataflow job will use",
#                         "param_type": "TEXT",
#                         "is_optional": true
#                     },
#                     {
#                         "name": "numberOfWorkerHarnessThreads",
#                         "label": "Dataflow job will use max number of threads per worker",
#                         "help_text": "Maximum number of threads per worker Dataflow job will use",
#                         "param_type": "TEXT",
#                         "is_optional": true
#                     },
#                     {
#                         "name": "dumpHeapOnOOM",
#                         "label": "Dataflow will dump heap on an OOM error",
#                         "help_text": "Dataflow will dump heap on an OOM error",
#                         "param_type": "TEXT",
#                         "is_optional": true
#                     },
#                     {
#                         "name": "saveHeapDumpsToGcsPath",
#                         "label": "Dataflow will dump heap on an OOM error to supplied GCS path",
#                         "help_text": "Dataflow will dump heap on an OOM error to supplied GCS path",
#                         "param_type": "TEXT",
#                         "is_optional": true
#                     },
#                     {
#                         "name": "workerMachineType",
#                         "label": "Worker Machine Type to use in Dataflow Job",
#                         "help_text": "Machine Type to Use: n1-standard-4",
#                         "param_type": "TEXT",
#                         "is_optional": true
#                     },
#                     {
#                         "name": "maxStreamingRowsToBatch",
#                         "label": "Max number of rows per BigQueryIO batch",
#                         "help_text": "Max number of rows per BigQueryIO batch",
#                         "param_type": "TEXT",
#                         "is_optional": true
#                     },
#                     {
#                         "name": "maxStreamingBatchSize",
#                         "label": "Maximum byte size of a single streaming insert to BigQuery.",
#                         "help_text": "Sets the maximum byte size of a single streaming insert to BigQuery. This option could fix row too large errors.",
#                         "param_type": "TEXT",
#                         "regexes": [
#                             "^[1-9][0-9]+$"
#                         ],
#                         "is_optional": true
#                     }
#                 ]
#     },
#     "sdkInfo": {
#         "language": "JAVA"
#     }
# }'

gsutil cp metadata.json ${TEMPLATE_IMAGE_SPEC}
rm image_spec.json

JOB_NAME="${IMAGE_NAME}-`date +%Y%m%d-%H%M%S-%N`"
gcloud beta dataflow flex-template run ${JOB_NAME} \
        --project=${PROJECT} \
        --region=${REGION} \
        --subnetwork ${SUBNETWORK} \
        --enable-streaming-engine \
        --additional-experiments streaming_mode_at_least_once \
        --template-file-gcs-location=${METADATA_FILE_LOCATION} \
        --parameters=inputFilePattern=${INPUT_FILE_PATTERN} \
        --parameters=gcsPubSubSubscription=${GCS_PUBSUB_SUBSCRIPTION} \
        --parameters=inputFileFormat=avro \
        --parameters=outputStagingDatasetTemplate=${OUTPUT_STAGING_DATASET_TEMPLATE} \
        --parameters=outputDatasetTemplate=${OUTPUT_DATASET_TEMPLATE} \
        --parameters=outputStagingTableNameTemplate="{_metadata_table}_log" \
        --parameters=outputTableNameTemplate="{_metadata_table}" \
        --parameters=deadLetterQueueDirectory=${DEADLETTER_QUEUE_DIRECTORY} \
        --parameters=rfcStartDateTime=1970-01-01T00:00:00.00Z \
        --parameters=fileReadConcurrency=${FILE_READ_CONCURRENCY} \
        --parameters=mergeFrequencyMinutes=${MERGE_FREQUENCY_MINUTES} \
        --parameters=dlqRetryMinutes=${DLQ_RETRY_MINUTES} \
        --parameters=applyMerge=${APPLY_MERGE} \
        --parameters=mergeConcurrency=${MERGE_CONCURRENCY} \
        --parameters=autoscalingAlgorithm=${AUTOSCALING_ALGORITHM} \
        --parameters=numWorkers=${NUM_WORKERS} \
        --parameters=maxNumWorkers=${MAX_NUM_WORKERS} \
        --parameters=usePublicIps=false \
        --parameters=dataStreamRootUrl=https://datastream.googleapis.com/ \
        --parameters=useStorageWriteApi=${USE_STORAGE_WRITE_API} \
        --parameters=storageWriteApiTriggeringFrequencySec=${STORAGE_WRITE_API_TRIGGERING_FREQUENCY_SEC} \
        --parameters=experiments=use_runner_v2 \
        --parameters=workerMachineType=${WORKER_MACHINE_TYPE}
#!/bin/bash

# command to execute the Cloud Build execution
# Replace BRANCH_NAME and REVISION_ID values as needed.

gcloud builds submit . \
    --config=cloudbuild_mod.yaml \
    --substitutions=BRANCH_NAME="add-bq-storage-write-test-datastream",REVISION_ID="<REVISION_ID>" \
    --timeout=7200
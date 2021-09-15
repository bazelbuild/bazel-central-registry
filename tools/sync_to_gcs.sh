#!/bin/bash

# Copyright 2021 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script syncs the current registry content to GCS.
# You'll need write access to gs://bcr.bazel.build to run this script.

set -x
set -e

BUCKET_NAME=bcr.bazel.build
gsutil cp ./bazel_registry.json gs://${BUCKET_NAME}/
# Make sure the content is updated immediately after we upload to GCS.
gsutil -h "Cache-Control:no-cache" -m rsync -d -r ./modules gs://${BUCKET_NAME}/modules

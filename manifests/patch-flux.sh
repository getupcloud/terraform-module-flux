#!/bin/bash

f=${1:-install-latest.yaml}

echo Patching securityContext...
yq e --inplace 'select(.kind == "Deployment").spec.template.spec.securityContext.runAsUser = 100' $f
yq e --inplace 'select(.kind == "Deployment").spec.template.spec.securityContext.runAsGroup = 101' $f

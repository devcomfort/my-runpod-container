#!/bin/bash

if [ "$#" -lt 1 ]; then
    echo "Usage: ./bake.sh <template> ...arguments"
    exit 1
fi

TEMPLATE=$1
shift

if [ ! -f "builds/$TEMPLATE/docker-bake.hcl" ]; then
    echo "Bake file not found for template $TEMPLATE"
    exit 1
fi

docker buildx bake -f builds/shared/versions.hcl -f "builds/$TEMPLATE/docker-bake.hcl" "$@"

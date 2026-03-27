#!/bin/bash

BRANCH=$1

docker stop $BRANCH
docker rm $BRANCH

echo "Container $BRANCH removido"
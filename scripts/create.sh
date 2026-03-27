#!/bin/bash

BRANCH=$1

if docker ps -a | grep -q "$BRANCH"; then
  echo "Container já existe"
  exit 0
fi

docker run -d \
  --name $BRANCH \
  --network preview-net \
  --add-host=host.docker.internal:host-gateway \
  -e DB_HOST=host.docker.internal \
  -e REDIS_HOST=host.docker.internal \
  app-base

echo "Container $BRANCH criado"
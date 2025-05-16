#!/bin/zsh

set -e

export SDKMAN_DIR="$HOME/.sdkman"
[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

echo "loading the env vars and exporting them"
# load the .env file variable here
SCRIPT_DIR=$(dirname "$0")
set -a
[ -f "$SCRIPT_DIR/.env" ] && . "$SCRIPT_DIR/.env"
set +a


# Variables
AWS_ACCOUNT_ID=721431533455
AWS_REGION=ap-southeast-2
ECR_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
CATALOG_SERVICE="catalog-service"
CONFIG_SERVICE="config-service"


echo "building catalog service jar"
# build first catalog service using ./gradlew clean assemble
cd ../catalog-service

sdk env

./gradlew clean assemble

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")


# build the docker image now
echo "Now building the docker image for catalog service"

docker build --platform=linux/amd64 -t "${CATALOG_SERVICE}:${TIMESTAMP}" -t "${ECR_URL}/${CATALOG_SERVICE}:${TIMESTAMP}" .

echo "building config service jar"

cd ../config-service

sdk env

./gradlew clean assemble

# build the docker image now
echo "Now building the docker image for config service"

docker build --platform=linux/amd64 -t "${CONFIG_SERVICE}:${TIMESTAMP}" -t "${ECR_URL}/${CONFIG_SERVICE}:${TIMESTAMP}" .
echo "deply value is ::::::$deploy"

if [ "$deploy" = "true" ]; then
    echo "creating the ecr repos"
    #HTTP_PROXY=http://host.docker.internal:3129
    #HTTPS_PROXY=http://host.docker.internal:3129
    #NO_PROXY=localhost,127.0.0.1,host.docker.internal
    # create ecr repositories
    aws ecr describe-repositories --repository-names $CATALOG_SERVICE --region $AWS_REGION --no-verify || aws ecr create-repository --repository-name $CATALOG_SERVICE --region $AWS_REGION --no-verify
    aws ecr describe-repositories --repository-names $CONFIG_SERVICE --region $AWS_REGION --no-verify || aws ecr create-repository --repository-name $CONFIG_SERVICE --region $AWS_REGION --no-verify

    echo "ECR Login"
    aws ecr get-login-password --region $AWS_REGION --no-verify | docker login --username AWS --password-stdin $ECR_URL

    echo "Tag and Push the image with ECR tag for catalog service"
    echo "catalog-service tag generated :::::::::$ECR_URL/catalog-service:$TIMESTAMP"
    docker push "$ECR_URL/catalog-service:$TIMESTAMP"

    echo "Tag and Push the image with ECR tag for config service"
    echo "config-service tag generated:::::::::$ECR_URL/config-service:$TIMESTAMP"
    docker push "$ECR_URL/config-service:$TIMESTAMP"

    # Check the images in the ECR and list them
    echo "Checking and listing images in ECR"
    aws ecr list-images --repository-name $CATALOG_SERVICE --region $AWS_REGION --no-verify
    aws ecr list-images --repository-name $CONFIG_SERVICE --region $AWS_REGION --no-verify
fi


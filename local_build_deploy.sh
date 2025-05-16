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


CATALOG_SERVICE="catalog-service"


echo "building catalog service jar"
# build first catalog service using ./gradlew clean assemble
cd ../catalog-service

sdk env

./gradlew clean assemble

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")


# build the docker image now
echo "Now building the docker image for catalog service"

docker build --platform=linux/amd64 -t "${CATALOG_SERVICE}:${TIMESTAMP}" .

echo "building config service jar"



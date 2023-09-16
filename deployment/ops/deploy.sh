#!/bin/bash

#. Variables passed by the "bitbucket-pipeline.yml" file.
CONTAINER_TAG=$1
ENVIRONMENT=$2
CONTAINER_COUNT=$3
WEBHOOK_URL=$4
DEPLOY_SERVICE=$5
ARTIFACT_BUCKET="deploy.mobisy.com"

#1. Function to download the artifacts for all services from S3 bucket.
download_artifact(){
  #. $1 => environment name
  echo "###############################################################"
  echo $CREDENTIALS > deployables/ell/src/main/resources/credentials.json
  mkdir ops/$1/ell/tokens
  echo "downloading the StoredCredentials for { ell/$1 } environment"
  aws s3 cp s3://$ARTIFACT_BUCKET/$1/StoredCredential ops/$1/ell/tokens/
  echo "downloading the retailer-module credentials for { consumer/$1 } environment"
  aws s3 cp --recursive s3://$ARTIFACT_BUCKET/$1/fcm_credentials/ deployables/notification-consumer/src/main/resources/
  echo "###############################################################"
}

#2. Function to create environment.
create_environment(){
  #. $1 => git branch to deploy
  #. Right now, we are not using the branch checkout on runtime. Hence,
  #  we do not need to checkout the branches. But this variable has 
  #  been passed just in case if we want to do operations based upon 
  #  the branches.
  echo "###############################################################"
  echo "compiling the code using $(mvn --version)"
  mvn clean package
  if [ $? == 0 ]; then
    curl -X POST $WEBHOOK_URL -H "Content-Type: application/json" -d "{ \"text\": \"Code Compilation success.\" }"
  else
    curl -X POST $WEBHOOK_URL -H "Content-Type: application/json" -d "{ \"text\": \"Code Compilation error.\" }"
    exit 1
  fi
  echo "###############################################################"
}

#3. Function to build the code for deployment.
build(){
  #. $1 => deploy service/container image name
  #. $2 => environment name
  echo "sending the alert to flock messanger"
  curl -X POST $WEBHOOK_URL -H "Content-Type: application/json" -d "{ \"text\": \"Deploying { $1 } to { $2 } cluster.\" }"
  echo "###############################################################"
  echo "building the { $1 } docker container image"
  cp ops/$2/$1/Dockerfile . && docker build -t $1 . --rm
  echo "###############################################################"
}

#4. Function to push the docker images to ECR.
push (){
  #. $1 => service image name
  #. $2 => container image tag
  echo "###############################################################"
  docker tag $1:latest 596849958460.dkr.ecr.ap-southeast-1.amazonaws.com/$1:$2
  docker push 596849958460.dkr.ecr.ap-southeast-1.amazonaws.com/$1:$2
  docker rmi --force 596849958460.dkr.ecr.ap-southeast-1.amazonaws.com/$1:$2
  echo "###############################################################"
}

#5. Function to deploy the docker images to ECS Fargate.
deploy(){
  #. $1 => cluster service name
  #. $2 => cluster name (as per environment)
  #. $3 => number of containers to maintain
  echo "###############################################################"
  echo "deploying { $1 } to { $2 } ECS cluster"
  echo "sending the alert on flock messanger."
  aws ecs update-service --cluster $2 --service $1 --desired-count $3 --region ap-southeast-1 --force-new-deployment
  if [ $? == 0 ]; then
    curl -X POST $WEBHOOK_URL -H "Content-Type: application/json" -d "{ \"text\": \"Deployment of { $1 } to { $2 } cluster has been successful. Please wait for 3 minutes before the new container is usable.\" }"
  else
    curl -X POST $WEBHOOK_URL -H "Content-Type: application/json" -d "{ \"text\": \"Deployment of { $1 } to { $2 } cluster has been failed.\" }"
  fi
  echo "###############################################################"
}

#6. Function to deploy all the services.
deploy_all_services(){
  echo "###############################################################"
  echo "deploying all the deployable services..."
  services=(access-service
            notification-consumer
            ell
            notification-producer
            retailer-module
            map-service
  )
  echo "creating the environment..."
  create_environment
  echo "deploying { ${services[@]} } services"
  for service in ${services[@]}; do
    build $service $ENVIRONMENT
    push $service $CONTAINER_TAG
    deploy $service $ENVIRONMENT $CONTAINER_COUNT
  done
  echo "###############################################################"
}

#7.
get_module(){
  echo "###############################################################"
  #. $1 => name of the file from last commit
  local path=$1
  while true; do
    path=$(dirname $path)
    if [ -f "$path/pom.xml" ]; then
      echo "$path"
      return
    elif [[ "./" =~ "$path" ]]; then
      return
    fi
  done
  echo "###############################################################"
}

echo "#################################################################"
echo "Downloading the credentials from the S3 bucket"
download_artifact "$2"
echo "#################################################################"

echo "#################################################################"
if [[ -z "$DEPLOY_SERVICE" ]]; then
  echo "No input from account variable. Take the default action."
else
  if [[ "$DEPLOY_SERVICE" == "all" ]]; then
    deploy_all_services
  fi
  create_environment
  for deploy_service in $(echo $DEPLOY_SERVICE | sed "s/,/ /g"); do
    echo "deploying the { $deploy_service } service..."
    echo "creating the environment..."
    build $deploy_service $ENVIRONMENT
    push $deploy_service $CONTAINER_TAG
    deploy $deploy_service $ENVIRONMENT $CONTAINER_COUNT
  done
  exit 0
fi
echo "#################################################################"

#. Knitting the above functions together.
echo "#################################################################"
#declare -a modules
#modules=("${modules[@]}" "$module")
modules=()
CURRENT_COMMIT=$(git rev-parse --short $BITBUCKET_COMMIT)
PREVIOUS_COMMIT=$(git rev-parse --short $CURRENT_COMMIT^1)
for file in $(git diff --name-only $CURRENT_COMMIT $PREVIOUS_COMMIT); do
  module=$(get_module "$file")
  if [ "" != "$module" ] && [[ ! " ${modules[@]} " =~ " $module " ]]; then
    modules+=("$module")
  fi
done

#. Checking if there is any change in the repository. If no change then
#  exit the pipeline without doing anything.
((( ${#modules[@]} )) && create_environment) || ( echo "nothing to deploy here..." && exit 0 )

for mod in ${modules[*]}; do
  [[ "$mod" == services/* ]] && ( echo "deploying all the services." && \
                                  deploy_all_services && exit 0 )
  [[ "$mod" == deployables/* ]] && ( echo "deploying the { $mod } serivce ..." && \
                                     DEPLOY_SERVICE=$(echo $mod | cut -d'/' -f2) && \
                                     build $DEPLOY_SERVICE $ENVIRONMENT && \
                                     push $DEPLOY_SERVICE $CONTAINER_TAG && \
                                     deploy $DEPLOY_SERVICE $ENVIRONMENT $CONTAINER_COUNT ) 
done

echo "#################################################################"

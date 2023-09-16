# Deployment Pipeline

---

We are using pipelines feature from bitbucket, as we are hosting our
code base at the same place. This document is intended to give the
detailed information about our implementation and how to manage it. For
example: adding the new services, updating the code base etc.
The following components can be seen in all the bitbucket repositories:

1. Bitbucket deployment variables.

2. "[bitbucket-pipelines.yml](https://bitbucket.org/bizom/scripts/src/master/deployment/bitbucket-pipelines.yml)" file.

3. "[ops](https://bitbucket.org/bizom/scripts/src/master/deployment/ops/)" folder.

---

### Bitbucket deployment variables:
These variables can be found under `Deployments` section in bitbucket
repository `Settings`. We have environment dependent variables. For
example, under `dev` environment we will see the following variables
declared:
```
a. CONTAINER_TAG
b. ENVIRONMENT
c. CONTAINER_COUNT
d. AWS_ACCESS_KEY_ID
e. AWS_SECRET_ACCESS_KEY
```
There are another type of variables bitbucket supports, i.e. repository
variables. Under this section we have declared the following variable:
```
f. WEBHOOK_URL
```
All these variables are read by the bitbucket pipelines, created using
the `bitbucket-pipelines.yml` file (explained in next section). When a
pipeline runs, bitbucket launches a docker container and exports all
these variables into the environment.
 
### "[bitbucket-pipelines.yml](https://bitbucket.org/bizom/scripts/src/master/deployment/bitbucket-pipelines.yml)" file:
This file creates the environment for the container images creation and
deployment. We have support for two types of deployment:
1. Automated deployment: If there is any changes committed in
`development` branch, then the pipeline runs and deploys the modules
automatically. This feature is defined under the `branches` section of
the file. If we replace `development` under the `branches` with any
other branch then pipeline will deploy from that branch automatically.
```
pipelines:
  branches:
    development:
      << do automated deployments >>
    some_other_branch:
      << do other automated deployments >>
  << custom deployments >>
```

2. Manual deployment: If you want to manually deploy any service then go
to the `Branches` from the left menu. Then click on the `3 dots ( ... )`
in front of that branch, click on `Run pipeline for a branch`. It will
show a drop-down menus where we can choose to deploy in a specific
environment (eg `deploy-to-dev`), as declared follows. It will ask for
the value of the `DEPLOY_SERVICE` variable.
```
pipelines:
  << automated deployments >>
  custom:
    deploy-to-dev:
      - variables:
        - name: DEPLOY_SERVICE
    deploy-to-staging:
      - variables:
        - name: DEPLOY_SERVICE
    deploy-to-prod:
      - variables:
        - name: DEPLOY_SERVICE
```

* `DEPLOY_SERVICE` variable takes an array of arguments, which means we
  can specify 1 value or comma-separated multiple values. For example,
  we can deploy `ell` or `ell,access-service,notification-producer`.
* To use the `aws` command we need to install `awscli` and other
  dependencies in the bitbucket pipeline environment everytime it runs.
  This slows down the performance of the pipeline. To enhance the
  performance of the pipeline, we created a base image which has already
  all the packages and dependencies essential for the pipeline are
  installed. In order to fetch this base image we have added the
  following block:
```
image:
  name: 596849958460.dkr.ecr.ap-southeast-1.amazonaws.com/bizom:latest
  aws:
    access-key: $AWS_ACCESS_KEY_ID
    secret-key: $AWS_SECRET_ACCESS_KEY
```
* We use Amazon Elastic Container Repository (AWS ECR) to store our
  docker container images. In order to use it we need to get a login
  token using the secret-key/value pair. This pair is defined in the
  bitbucket's deployment variables. The following command does this
  trick:
```
$(aws ecr get-login --no-include-email --region ap-southeast-1)
```
* As our services are written in java and maven is needed to compile
  them off, we need to download the maven repository everytime when we
  compile it. The packages downloaded are kept in the `~/.m2` directory.
  In order to save time during this ~1.3 GB libraries download, we are
  using the caching feature of the bitbucket pipelines. Similarly 
  docker images are made up of several read-only layers with top read-
  write layer. We are caching these docker layers as well in order to 
  improve performance. The below block does this:
```
caches:
  - maven
  - docker
```
* The `deployment` block tells the pipeline from where to read the
  `deployment variables`. For example, the following block tells it to
  use the variables defined in the `staging` section of the
  `Settings/Deployments` in the bitbucket user-interface.
```
deployment: staging
```
* The following block tells us about how much memory the deployment
  steps can take. Regular steps have 4096 MB of memory in total, large
  build steps (which you can define using size: 2x) have 8192 MB total.
  For more information on service memory limits follow the docs [here](https://confluence.atlassian.com/bitbucket/use-services-and-databases-in-bitbucket-pipelines-874786688.html).
```
- step:
    size: 2x
```
* `after-script` section runs the steps after the pipeline has finished,
  like sending alert on flock on the status of the pipeline. In our case
  we are running `alert.sh` script under the `ops` folder.
```
after-script:
  - ops/alert.sh
```
* The final section of the
  "[bitbucket-pipelines.yml](https://bitbucket.org/bizom/scripts/src/master/deployment/bitbucket-pipelines.yml)" file calls our
  custom deployment script
"[deploy.sh](https://bitbucket.org/bizom/scripts/src/master/deployment/ops/deploy.sh)". On this script check the
  next section of this documentation.
```
script:
  - $(aws ecr get-login --no-include-email --region ap-southeast-1) && ops/deploy.sh "dev" "dev" "1" $WEBHOOK_URL $DEPLOY_SERVICE
```

### "[ops](https://bitbucket.org/bizom/scripts/src/master/deployment/ops/)" folder.

The final section of the [bitbucket-pipelines.yml](https://bitbucket.org/bizom/scripts/src/master/deployment/bitbucket-pipelines.yml) file hands over the
control of the execution to the
"[deploy.sh](https://bitbucket.org/bizom/scripts/src/master/deployment/ops/deploy.sh)" bash script. The content of
the `ops` folder is as follows:

```
ops
├── alert.sh
├── deploy.sh
├── dev
│   ├── access-service
│   │   └── Dockerfile
│   ├── ell
│   │   └── Dockerfile
│   ├── map-service
│   │   └── Dockerfile
│   ├── notification-consumer
│   │   └── Dockerfile
│   ├── notification-producer
│   │   └── Dockerfile
│   └── retailer-module
│       └── Dockerfile
├── prod
│   ├── access-service
│   │   └── Dockerfile
│   ├── ell
│   │   └── Dockerfile
│   ├── map-service
│   │   └── Dockerfile
│   ├── notification-consumer
│   │   └── Dockerfile
│   ├── notification-producer
│   │   └── Dockerfile
│   └── retailer-module
│       └── Dockerfile
└── staging
    ├── access-service
    │   └── Dockerfile
    ├── ell
    │   └── Dockerfile
    ├── map-service
    │   └── Dockerfile
    ├── notification-consumer
    │   └── Dockerfile
    ├── notification-producer
    │   └── Dockerfile
    └── retailer-module
        └── Dockerfile
```

####
"[ops/alert.sh](https://bitbucket.org/bizom/scripts/src/master/deployment/ops/alert.sh)"
This script gets the exit status & link to the pipeline, compiles a
message and sends to the notification-channel in flock using the
`WEBHOOK_URL` defined in the repository variables. A sample alert is as
follows (where "pipeline" and commit-id are hyperlinks):
```
Branch [release/generic-outlet-service-3.0-RELEASE] pipeline deployment finished. Triggered by commit: de4655479890a0df12b4fcdefb3ba08bf64b9.
```

### "[ops/deploy.sh](https://bitbucket.org/bizom/scripts/src/master/deployment/ops/deploy.sh)"
This is the main script which does the actual deployments on AWS ECS
Fargate. There are currently 7 bash functions in total. It takes the
following arguments from the `bitbucket-pipelines.yml`:
```
ops/deploy.sh "dev" "dev" "1" $WEBHOOK_URL $DEPLOY_SERVICE
means:
a. CONTAINER_TAG   = "dev"
b. ENVIRONMENT     = "dev"
c. CONTAINER_COUNT = "1"
d. WEBHOOK_URL     = fetched from the repository variables
e. DEPLOY_SERVICE  = user supplied for manual deployment
```
The summary of the 7 bash functions is as follows:

1. download_artifact():
There are some credentials/keys which are kept on S3 and are needed on
the compile time. This function downloads them from S3 bucket. The
`ARTIFACT_BUCKET` variable tells the script which S3 bucket should be
used. Inside the bucket there is one folder for each environment, for 
example: `dev`,`staging` and `prod`. Inside these folders, there are 
sub-folders for the individual services. The current bucket is:
```
ARTIFACT_BUCKET="deploy.mobisy.com"
```

2. create_environment():
This function compiles the codebase using `mvn clean package` command
and sends alert on the flock notification channel about the status of
the compilation process whether it succeeded or failed. We can see the
following message in flock after success:
```
Code Compilation success.
```

3. build():
It copies the `Dockerfile` from the `ops/$environment/$service` folder
and builds the docker images after successfull code compilation.
```
cp ops/$environment/$service/Dockerfile . && docker build -t $environment . --rm
```

4. push ():
It first tags the docker image built by the previous function with the
environment name. This is done because we are using the same repository
for each service for all environments in AWS ECR. Tagging is the only
way to tell the difference among differnt environment's images. After
tagging it pushes the images to AWS ECR and cleans up the pipeline
environment.
```
docker tag $service:latest 596849958460.dkr.ecr.ap-southeast-1.amazonaws.com/$environment:$service
docker push 596849958460.dkr.ecr.ap-southeast-1.amazonaws.com/$environment:$service
docker rmi --force 596849958460.dkr.ecr.ap-southeast-1.amazonaws.com/$environment:$service
```

5. deploy():
This function deploys the image pushed by the previous function, to AWS
ECS Fargate and sends one alert on flock.
```
aws ecs update-service --cluster $environment --service $service
--desired-count $CONTAINER_COUNT --region ap-southeast-1 --force-new-deployment
Sample alert:
Deployment of { generic-outlet-service } to { staging } cluster has been successful. Please wait for 3 minutes before the new container is usable.
```

6. deploy_all_services():
As the name suggests, this function deploys all the services in the
specified environment. It can be invoked by `manual` deployment with
`all` keyword passed, instead of comma-separated list of services.
Inside it calls the above documented functions together and runs the for
loop on each service.
```
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
```

7. get_module():
This function is called during the automated deployment of the services.
It returns the name of module changed in the last commit to the branch
we are running the pipeline for. For example, if the last commit changed
the file kept at `deployables/ell/pom.xml` location then this function
will return `deployables/ell` value only.

* All these functions are knitted together in the last block of the
  code. An array `modules` is populated by calling the `get_module`
  function in a loop for all the changed files.
```
modules=()
CURRENT_COMMIT=$(git rev-parse --short $BITBUCKET_COMMIT)
PREVIOUS_COMMIT=$(git rev-parse --short $CURRENT_COMMIT^1)
for file in $(git diff --name-only $CURRENT_COMMIT $PREVIOUS_COMMIT); do
  module=$(get_module "$file")
  if [ "" != "$module" ] && [[ ! " ${modules[@]} " =~ " $module " ]]; then
    modules+=("$module")
  fi
done
```
* Then we parse the names of all the services which were changed with
  the last commit by stripping the `deployables` section. For example,
  the array member `deployables/ell` will become `ell` now. Then we call
  the `build()`, `push()` and `deploy()` functions one by one, by
  passing the name of the service to be deployed in which environment.
```
for mod in ${modules[\*]}; do
  [[ "$mod" == services/\* ]] && ( echo "deploying all the services." && \
                                  deploy_all_services && exit 0 )
  [[ "$mod" == deployables/\* ]] && ( echo "deploying the { $mod } serivce ..." && \
                                     DEPLOY_SERVICE=$(echo $mod | cut -d'/' -f2) && \
                                     build $DEPLOY_SERVICE $ENVIRONMENT && \
                                     push $DEPLOY_SERVICE $CONTAINER_TAG && \
                                     deploy $DEPLOY_SERVICE $ENVIRONMENT $CONTAINER_COUNT ) 
done
```
* If there is any change in `services` folder, then `all` the services
  will get deployed. This is because `services` folder contains common
  libraries used by multiple services. If there is any change in 
  `deployables/$service` folder then only that service will get deployed


### "ops/$environment/$service/Dockerfile"
There is one Dockerfile for each service for each environment. Here is a
sample Dcokerfile for `ell` service for `dev` environment, kept at
[ops/dev/ell/Dockerfile](https://bitbucket.org/bizom/scripts/src/master/deployment/ops/dev/ell/Dockerfile):
```
FROM openjdk:11
ENV SPRING_PROFILES_ACTIVE dev
ENV LOG_PATH /tmp/ell-platform.log
RUN mkdir -p /root/bizom/tokens /root/tomcat/logs
RUN ln -sf /dev/stdout /root/tomcat/logs/ell-platform.log
WORKDIR /root/bizom/
COPY ./deployables/ell/target/ell-1.0-SNAPSHOT.war /root/bizom
COPY ./ops/dev/ell/tokens/\* /root/bizom/tokens
EXPOSE 8080
CMD ["java", "-jar", "/root/bizom/ell-1.0-SNAPSHOT.war"]
```
* The first line tells us the base image to be used, in our case its
  `openjdk:11`. Then the environment variables inside the service are
  set. `SPRING_PROFILES_ACTIVE` variable tells the service to use
  specific profile. This profile will be downloaded from the
  `config-server` on runtime. There are two repositories which hold all
  the configuration profiles, named
  [bizom-configurations](https://bitbucket.org/bizom/bizom-configurations)
  for the `dev/staging` environments and
  [bizom-prod-config](https://bitbucket.org/bizom/bizom-prod-config) for
  production environment. `bizom-prod-config` repository have limited
  access but `bizom-configurations` repository is accessible to all.
  These configuration files contain the information about the database
  endpoints and other logging information. We are running one config-
  server for each environment.
* Then the next steps copy the tokens/keys or other artifacts downloaded
  by the `download_artifact()` function, into the newly created docker
  image by adding another layer. Then the compiled war file is loaded
  into the docker image. In this example we are exposing port 8080 tcp.
  And in the last, we specify which command docker container should
  execute when it is launched.

---
### Logging
---

* For logging we are using AWS cloudwatch service. The overall flow is
as follows:
```
ECS container task ===>>> AWS Cloudwatch ===>>> Elasticsearch service =
==>>> Kibana Dashboard
```
From AWS Cloudwatch to Elasticsearch, the logs are pushed using the
Lambda function written in nodejs. It pushes the logs to Elasticsearch
service, as soon as the ECS containers write them into the cloudwatch.

* All the ECS logs are coming in real-time now. We were facing issues
with the timings of the logs from cloudwatch, as they were coming into 
Elasticsearch in batches. Here are some of the findings/changes/fixes:

* Changing the following code-block in Lambda function 
```
"LogsToElasticsearch":

        var action = { "index": {} };
        action.index._index = indexName;
        action.index._type = 'bizom';
        action.index._id = logEvent.id;
```
        
* We have set the value for the "action.index._type" to "bizom". By 
default it take s the value of "name of the cloudwatch log group", 
which creates problems, if we have multiple log groups in cloudwatch.
In that case it will set the "action.index._type" to the firt log group
whoever sends the data. Other than the first log group, all logs are 
rejected. Hence, we need to use the common name for all the cloudwatch 
log groups.

```
  function post(body, callback) {
    var requestParams = buildRequest(endpoint, body);
    var request = https.request(requestParams, function(response) {
      var responseBody = '';
      response.on('data', function(chunk) {
        responseBody = chunk;
      });
    }
  }
```

* In this code, we have changed the line "responseBody = chunk;". By 
default it appends the logs into the buffer, as they are generated.
However, if any service is running in debug mode or generating too 
many logs in per unit time, then it will wait until the services stops
writing the logs or the buffer goes out. In this case we would not be
able to get the logs in almost real-time. To fix this problem, we have
removed the appending logic from the mentioned code line. Now, we are
pushing the logs as soon as they get written in the cloudwatch log 
groups.

---
### Monitoring
---

* For monitoring ECS (other AWS infrastructure as well) we are using 
"Grafana" dashboard backed by AWS cloudwatch. Grafana queries the
cloudwatch and show the graphs for several metrics, like CPU and Memory
utilization. The endpoint to this is "monitor.bizom.in". Please ask
DevOps team to get the access account for the same. 

* For application monitoring we do not have anything in place. For
example the JVM memory consumed by our java application. For this
purpose we need to add some mechanism which can ping the services
endpoints periodically and upload the results in real-time. At the time
of writing this documentation, it is not in place and only under
consideration.

---
### Alerting
---

* For Alerting, we are using "Grafana Alerts". For example, if we have
the CPU utilization above a certain threshold, say 80%, The Grafana will
send alerts over email and telegram. It also sends the screenshot of the
graph where the resource utilization went above the threshold.
NOTE: Grafana queries the cloudwatch for the data.

* We are also having the alerts on whenever the ECS task changes its
state to "STOPPED". That means, it will send the email alert when any
container is killed due to any reasons, like OutOfMemory or crosses the
CPU threshold or during deployments etc. We can send specific alerts as
well but right now we are not aware of the exact error strings to
generate alerts. Hence, we are sending out the generic alerts on all
"STOPPED" containers in all 3 environments.

```
ECS task status ===>>> AWS Cloudwatch Events ===>>> SNS ===>>> Email
```
The current event pattern is as follows:
```
{
  "source": [ "aws.ecs" ],
  "detail-type": [ "ECS Task State Change" ],
  "detail": {
    "lastStatus": [
      "STOPPED"
    ]
  }
}
```
We can use the exact error string "lastStatus" to generate the alerts on
the events like, application crashes. This part is also under
consideration at the time of writing this documentation.

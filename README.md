# Coworking Space Service Extension
The Coworking Space Service is a set of APIs that enables users to request one-time tokens and administrators to authorize access to a coworking space. This service follows a microservice pattern and the APIs are split into distinct services that can be deployed and managed independently of one another.

For this project, you are a DevOps engineer who will be collaborating with a team that is building an API for business analysts. The API provides business analysts basic analytics data on user activity in the service. The application they provide you functions as expected locally and you are expected to help build a pipeline to deploy it in Kubernetes.

## Getting Started

### Deployment Guide for Coworking Analytics Application

Overview

This repository contains the infrastructure and application code for the Coworking Analytics application. The deployment process leverages modern DevOps practices, including Infrastructure as Code (IaC) and Continuous Integration/Continuous Deployment (CI/CD) to ensure a seamless and automated deployment pipeline. This document is intended to provide an experienced software developer with an understanding of the deployment architecture, tools used, and instructions for releasing new builds.
Technologies and Tools
1. Kubernetes (EKS)

    Amazon EKS (Elastic Kubernetes Service): A managed Kubernetes service that simplifies running Kubernetes on AWS without needing to install and operate your own Kubernetes control plane or nodes.
    Kubernetes Objects: We use Kubernetes objects like Deployments, Services, ConfigMaps, and Secrets to manage application components.

2. Docker

    Docker: The application is containerized using Docker. Each version of the application is built as a Docker image and pushed to Amazon ECR (Elastic Container Registry).
    Dockerfile: The Dockerfile describes the environment setup, dependencies, and execution command for the container.

3. Amazon ECR

    Amazon ECR: A fully-managed Docker container registry that makes it easy for developers to store, manage, and deploy Docker container images. The Docker images are tagged with the build number and pushed to ECR as part of the CI/CD pipeline.

4. AWS CodeBuild

    AWS CodeBuild: A fully managed build service that compiles source code, runs tests, and produces software packages that are ready to deploy. CodeBuild is used to build the Docker image and push it to ECR.

5. Kubernetes Configuration

    ConfigMaps and Secrets: Used for managing application configurations and sensitive data (such as database credentials) respectively.

### Dependencies
#### Local Environment
1. Python Environment - run Python 3.6+ applications and install Python dependencies via `pip`
2. Docker CLI - build and run Docker images locally
3. `kubectl` - run commands against a Kubernetes cluster
4. `helm` - apply Helm Charts to a Kubernetes cluster

#### Remote Resources
1. AWS CodeBuild - build Docker images remotely

The deployment process begins with the CI/CD pipeline configured in AWS CodeBuild:

    Source Code Changes: Developers push code changes to the repository (e.g., on GitHub).
    Build Process:
        CodeBuild triggers a build, pulling the latest code and Dockerfile.
        The Docker image is built and tagged with the build number.
        The image is pushed to Amazon ECR.
    Kubernetes Deployment:
        The deployment is configured to automatically pull the latest image from ECR.
        The Kubernetes cluster (EKS) is updated with the new image, ensuring a smooth rollout using Kubernetes' rolling update strategy.

2. AWS ECR - host Docker images
3. Kubernetes Environment with AWS EKS - run applications in k8s
4. AWS CloudWatch - monitor activity and logs in EKS
5. GitHub - pull and clone code

### Setup
#### 1. Configure a Database
Set up a Postgres database using a Helm Chart.

1. Set up Bitnami Repo
```bash
helm repo add <REPO_NAME> https://charts.bitnami.com/bitnami
```

2. Install PostgreSQL Helm Chart
```
helm install <SERVICE_NAME> <REPO_NAME>/postgresql
```

This should set up a Postgre deployment at `<SERVICE_NAME>-postgresql.default.svc.cluster.local` in your Kubernetes cluster. You can verify it by running `kubectl svc`

By default, it will create a username `postgres`. The password can be retrieved with the following command:
```bash
export POSTGRES_PASSWORD=$(kubectl get secret --namespace default <SERVICE_NAME>-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)

echo $POSTGRES_PASSWORD
```

<sup><sub>* The instructions are adapted from [Bitnami's PostgreSQL Helm Chart](https://artifacthub.io/packages/helm/bitnami/postgresql).</sub></sup>

3. Test Database Connection
The database is accessible within the cluster. This means that when you will have some issues connecting to it via your local environment. You can either connect to a pod that has access to the cluster _or_ connect remotely via [`Port Forwarding`](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/)

* Connecting Via Port Forwarding
```bash
kubectl port-forward --namespace default svc/<SERVICE_NAME>-postgresql 5432:5432 &
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432
```

* Connecting Via a Pod
```bash
kubectl exec -it <POD_NAME> bash
PGPASSWORD="<PASSWORD HERE>" psql postgres://postgres@<SERVICE_NAME>:5432/postgres -c <COMMAND_HERE>
```

4. Run Seed Files
We will need to run the seed files in `db/` in order to create the tables and populate them with data.

```bash
kubectl port-forward --namespace default svc/<SERVICE_NAME>-postgresql 5432:5432 &
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432 < <FILE_NAME.sql>
```

### 2. Running the Analytics Application Locally
In the `analytics/` directory:

1. Install dependencies
```bash
pip install -r requirements.txt
```
2. Run the application (see below regarding environment variables)
```bash
<ENV_VARS> python app.py
```

There are multiple ways to set environment variables in a command. They can be set per session by running `export KEY=VAL` in the command line or they can be prepended into your command.

* `DB_USERNAME`
* `DB_PASSWORD`
* `DB_HOST` (defaults to `127.0.0.1`)
* `DB_PORT` (defaults to `5432`)
* `DB_NAME` (defaults to `postgres`)

If we set the environment variables by prepending them, it would look like the following:
```bash
DB_USERNAME=username_here DB_PASSWORD=password_here python app.py
```
The benefit here is that it's explicitly set. However, note that the `DB_PASSWORD` value is now recorded in the session's history in plaintext. There are several ways to work around this including setting environment variables in a file and sourcing them in a terminal session.

3. Verifying The Application
* Generate report for check-ins grouped by dates
`curl <BASE_URL>/api/reports/daily_usage`

* Generate report for check-ins grouped by users
`curl <BASE_URL>/api/reports/user_visits`

### 3. Deployment Configuration

The Kubernetes deployment is managed using YAML configuration files stored in the deployment directory. These files define the infrastructure and application setup including Deployments, Services, ConfigMaps, and Secrets.

    Deployments: Manage the application lifecycle, including rolling updates.
    Services: Expose the application to the outside world through a LoadBalancer.
    ConfigMaps and Secrets: Store environment variables and sensitive information.

### 4. Monitoring and Logging

Kubernetes' built-in monitoring and logging tools provide insights into the application's performance and health. Developers can use tools like kubectl logs and kubectl describe to debug issues.
Releasing New Builds

### 5. To release a new build, follow these steps:

    Push Code Changes:
        Commit and push your changes to the repository. This will trigger the CI/CD pipeline.

    Monitor the Build:
        AWS CodeBuild will automatically start building the new Docker image and push it to ECR.

    Deploy to Kubernetes:
        Once the image is pushed, the Kubernetes deployment will be updated automatically if configured to pull the latest image tag. Otherwise, you may need to manually update the image field in the Deployment YAML and apply it using:

        
    ```bash
    kubectl apply -f ./deployment/coworking.yaml
    ```

### 6. Verify the Deployment:

    Ensure that the application is running correctly by checking the status of the pods, services, and logs:

    
    ```bash
    kubectl get pods
    kubectl get svc
    kubectl logs <pod_name>
    ```

Rollback if Necessary:

    If an issue is detected, you can rollback to a previous version by updating the Docker image tag in the deployment YAML and re-applying it.

# to create a trigger event with merge request
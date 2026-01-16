# OpenShift Tekton CI/CD Pipeline - Deployment Guide

## Overview

This repository contains a complete 6-step Tekton CI/CD pipeline for OpenShift:

1. **cleanup** - Cleans workspace of Python artifacts
2. **git-clone** - Clones source code from GitHub
3. **flake8** - Runs Python linting
4. **nose** - Executes unit tests
5. **buildah** - Builds container image
6. **deploy** - Deploys to OpenShift

## Repository Structure

```
coursera-final-project/
├── .tekton/
│   ├── tasks.yml          # Custom Tekton tasks (cleanup, run-tests, flake8-lint, buildah-build, deploy)
│   ├── pipeline.yaml      # Pipeline orchestrating all 6 steps
│   └── pipelinerun.yaml   # PipelineRun to execute the pipeline
├── k8s/
│   └── deployment.yaml    # Kubernetes deployment and service manifests
├── Dockerfile             # Container image definition
└── README.md
```

## Prerequisites

Before running this pipeline, ensure you have:

- ✅ Access to OpenShift Skills Network Lab environment
- ✅ Tekton Pipelines installed on your OpenShift cluster
- ✅ Logged into OpenShift via CLI (`oc login`)
- ✅ Created a project/namespace (e.g., `sn-labs-tekletsadika`)
- ✅ Proper RBAC permissions to create Tekton resources

## Deployment Instructions

### Step 1: Verify Your OpenShift Project

```bash
# Check current project
oc project

# If needed, switch to your project
oc project sn-labs-tekletsadika
```

### Step 2: Apply Tekton Tasks

Apply the custom tasks to your cluster:

```bash
oc apply -f .tekton/tasks.yml
```

This creates 4 custom tasks:
- `cleanup-workspace`
- `run-tests`
- `flake8-lint`
- `buildah-build`
- `deploy`

**Verify tasks:**
```bash
oc get tasks
```

### Step 3: Apply the Pipeline

Create the pipeline that orchestrates all steps:

```bash
oc apply -f .tekton/pipeline.yaml
```

**Verify pipeline:**
```bash
oc get pipeline coursera-cicd-pipeline
```

### Step 4: Run the Pipeline

Execute the pipeline by creating a PipelineRun:

```bash
oc create -f .tekton/pipelinerun.yaml
```

> **Note:** The PipelineRun uses `generateName`, so each execution creates a unique run with a generated suffix.

### Step 5: Monitor Pipeline Execution

**Option 1: Using OpenShift Web Console**
1. Navigate to **Pipelines** → **PipelineRuns**
2. Click on the latest `coursera-cicd-pipelinerun-*` to view details
3. Watch the progress of each step

**Option 2: Using CLI**

```bash
# List all pipeline runs
oc get pipelinerun

# Watch a specific pipeline run (replace with actual name)
oc get pipelinerun coursera-cicd-pipelinerun-xxxxx -w

# View logs of a specific task (e.g., flake8)
tkn pipelinerun logs coursera-cicd-pipelinerun-xxxxx -f -t flake8
```

### Step 6: Verify Deployment

After successful pipeline execution, verify the deployed application:

```bash
# Check deployment status
oc get deployment coursera-app

# Check pods
oc get pods -l app=coursera-app

# Check service
oc get svc coursera-app

# Expose the service (if not already exposed)
oc expose svc/coursera-app

# Get the route URL
oc get route coursera-app
```

## Pipeline Parameters

The pipeline accepts the following parameters (defined in `pipelinerun.yaml`):

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
| `repo-url` | `https://github.com/tekletsadik19/coursera-final-project.git` | Git repository URL |
| `image-name` | `image-registry.openshift-image-registry.svc:5000/sn-labs-tekletsadika/coursera-app:latest` | Container image reference |

## Workspace Configuration

The pipeline uses a shared workspace across all tasks with a PersistentVolumeClaim:
- **Size:** 1Gi
- **Access Mode:** ReadWriteOnce
- **Lifecycle:** Created automatically per PipelineRun

## Task Details

### 1. Cleanup (`cleanup-workspace`)
- **Image:** `alpine:3.19`
- **Purpose:** Removes Python virtual environments and cache files

### 2. Git Clone (`git-clone`)
- **Type:** ClusterTask (Tekton Hub)
- **Purpose:** Clones repository from GitHub

### 3. Flake8 Lint (`flake8-lint`)
- **Image:** `python:3.11-slim`
- **Purpose:** Runs Python linting to enforce code quality
- **Checks:** Syntax errors, undefined names, complexity

### 4. Nose Tests (`run-tests`)
- **Image:** `python:3.11-slim`
- **Purpose:** Executes unit tests using nosetests

### 5. Buildah Build (`buildah-build`)
- **Image:** `quay.io/buildah/stable:latest`
- **Purpose:** Builds and pushes container image
- **Security:** Requires privileged mode

### 6. Deploy (`deploy`)
- **Image:** `quay.io/openshift/origin-cli:latest`
- **Purpose:** Applies Kubernetes manifests to deploy the application

## Troubleshooting

### Pipeline Fails at Git Clone
**Issue:** git-clone ClusterTask not found

**Solution:** Install Tekton Hub tasks:
```bash
tkn hub install task git-clone
```

### Buildah Build Fails
**Issue:** Permission denied or security context error

**Solution:** Ensure buildah has privileged security context (already configured in `tasks.yml`)

### Deploy Fails
**Issue:** Insufficient permissions

**Solution:** Grant service account permissions:
```bash
oc adm policy add-role-to-user edit system:serviceaccount:sn-labs-tekletsadika:pipeline
```

### Image Push Fails
**Issue:** Cannot push to internal registry

**Solution:** Verify registry access and credentials:
```bash
oc get route -n openshift-image-registry
```

## Re-running the Pipeline

To run the pipeline again after code changes:

```bash
# Simply create a new PipelineRun
oc create -f .tekton/pipelinerun.yaml

# Or use Tekton CLI
tkn pipeline start coursera-cicd-pipeline \
  --param repo-url=https://github.com/tekletsadik19/coursera-final-project.git \
  --param image-name=image-registry.openshift-image-registry.svc:5000/sn-labs-tekletsadika/coursera-app:latest \
  --workspace name=shared-workspace,volumeClaimTemplateFile=- \
  --showlog
```

## Clean Up

To remove all resources:

```bash
# Delete all pipeline runs
oc delete pipelinerun --all

# Delete pipeline
oc delete pipeline coursera-cicd-pipeline

# Delete tasks
oc delete -f .tekton/tasks.yml

# Delete application
oc delete -f k8s/deployment.yaml
```

## Summary

This pipeline provides a complete CI/CD workflow from source code to deployed application on OpenShift, including:
- ✅ Code quality checks (flake8)
- ✅ Automated testing (nose)
- ✅ Container image building (buildah)
- ✅ Automated deployment (oc apply)

For questions or issues, refer to the [Tekton documentation](https://tekton.dev/docs/) or [OpenShift Pipelines documentation](https://docs.openshift.com/container-platform/latest/cicd/pipelines/understanding-openshift-pipelines.html).

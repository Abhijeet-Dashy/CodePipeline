# DevSecOps CI/CD with GitHub Actions, Sealed Secrets, and Security Scanning

This project demonstrates a secure CI/CD pipeline using GitHub Actions. The workflow integrates automated security scanning for both infrastructure code and container images and employs Sealed Secrets for secure management of Kubernetes secrets.

## ✨ Core Concepts

This pipeline automates the process of building, scanning, and deploying an application, ensuring security is embedded at every stage (DevSecOps).

  * **CI/CD with GitHub Actions:** The entire workflow is defined in `.github/workflows/cicd.yml` and is triggered automatically on every `git push` to the main branch.
  * **Infrastructure as Code (IaC) Security:** We use **`tfsec`** to scan Terraform code for security misconfigurations before any infrastructure is provisioned.
  * **Container Image Security:** We use **`Trivy`** to scan the Docker image for known vulnerabilities (CVEs) after it's built. The pipeline will fail if critical vulnerabilities are found.
  * **Secure Secret Management:** Kubernetes secrets are managed using **Sealed Secrets**. Plain-text secrets are encrypted locally into a `SealedSecret` custom resource, which is safe to commit to a public Git repository. Only the Sealed Secrets controller running in the cluster can decrypt it.

-----

## ⚙️ Pipeline Workflow

The pipeline executes the following steps in sequence:

1.  **Push Trigger:** A developer pushes code to the `main` branch.
2.  **Workflow Starts:** The GitHub Actions workflow is automatically triggered.
3.  **Security Scans (CI):**
      * The Terraform code in the `infra/` directory is scanned by `tfsec`.
      * A Docker image is built from the `app/` directory.
      * The newly built Docker image is scanned by `Trivy`.
4.  **Deployment (CD):**
      * If all scans pass, the workflow proceeds to deployment.
      * The encrypted `sealed-secret.yaml` is applied to the Kubernetes cluster. The in-cluster controller decrypts it and creates a standard `Secret`.
      * The application's `deployment.yaml` is applied, which mounts the newly created secret.
      * (Optional) Terraform is run to apply any infrastructure changes.

-----

## 🚀 Getting Started

### Prerequisites

  * A GitHub account.
  * A Kubernetes cluster (e.g., GKE, EKS, Minikube).
  * `kubectl` CLI configured to access your cluster.
  * A container registry account (e.g., Docker Hub).
  * [Sealed Secrets Controller](https://www.google.com/search?q=https://github.com/bitnami-labs/sealed-secrets%23installation) installed in your cluster.
  * `kubeseal` CLI installed locally.

### Setup Instructions

1.  **Clone the Repository**

    ```bash
    git clone https://github.com/your-username/your-repo-name.git
    cd your-repo-name
    ```

2.  **Install Sealed Secrets Controller**
    Install the controller into your Kubernetes cluster. This component is responsible for decrypting the sealed secrets.

    ```bash
    kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/latest/download/controller.yaml
    ```

3.  **Create and Seal a Kubernetes Secret**
    a. Create a standard Kubernetes secret manifest (`my-secret.yaml`), but **do not apply it**.

    ```yaml
    # my-secret.yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: my-app-secret
    type: Opaque
    stringData:
      DATABASE_URL: "postgres://user:password@host:port/dbname"
    ```

    b. Use the `kubeseal` CLI to encrypt your secret. This command fetches the public key from the controller in your cluster and creates an encrypted `SealedSecret` file.

    ```bash
    # This sealed-secret.yaml file is safe to commit to Git
    kubeseal < my-secret.yaml > k8s/sealed-secret.yaml
    ```

    c. You can now safely delete the original `my-secret.yaml` file.

4.  **Configure GitHub Repository Secrets**
    Navigate to your GitHub repository's `Settings > Secrets and variables > Actions` and add the following secrets:

      * `KUBE_CONFIG`: The base64-encoded configuration file for your Kubernetes cluster. You can get this by running: `cat ~/.kube/config | base64`.
      * `DOCKER_USERNAME`: Your Docker Hub username.
      * `DOCKER_PASSWORD`: Your Docker Hub password or access token.

-----

## 📁 Project Structure

```
.
├── .github/workflows/
│   └── cicd.yml           # GitHub Actions workflow definition
├── app/
│   ├── Dockerfile         # Dockerfile for the application
│   └── ...                # Application source code
├── infra/
│   └── main.tf            # Terraform infrastructure code
├── k8s/
│   ├── deployment.yaml    # Kubernetes deployment manifest
│   └── sealed-secret.yaml # The encrypted secret (safe to commit)
└── README.md
```

-----

## 🤖 GitHub Actions Workflow

The file `.github/workflows/cicd.yml` orchestrates the entire process. Below is a simplified example of the key jobs.

```yaml
# .github/workflows/cicd.yml
name: DevSecOps CI/CD Pipeline

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  security-scans:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: tfsec Scan
        uses: aquasecurity/tfsec-action@v1.0.0
        with:
          working_directory: infra

      - name: Build Docker Image
        run: docker build -t my-app:${{ github.sha }} ./app

      - name: Trivy Image Scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'my-app:${{ github.sha }}'
          format: 'table'
          exit-code: '1'
          ignore-unfixed: true
          vuln-type: 'os,library'
          severity: 'CRITICAL,HIGH'

  deploy:
    needs: security-scans
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' # Only deploy on push to main
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Kubeconfig
        run: |
          echo "${{ secrets.KUBE_CONFIG }}" | base64 --decode > kubeconfig.yaml
          export KUBECONFIG=kubeconfig.yaml

      - name: Apply Sealed Secret
        run: kubectl apply -f k8s/sealed-secret.yaml

      - name: Deploy to Kubernetes
        run: kubectl apply -f k8s/deployment.yaml
```

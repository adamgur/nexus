# Use an official lightweight Linux distribution
FROM ubuntu:22.04

# Set the working directory
WORKDIR /root

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    wget \
    unzip \
    tar \
    ca-certificates \
    && apt-get clean

# Install Docker CLI
RUN curl -fsSL https://download.docker.com/linux/static/stable/x86_64/docker-24.0.6.tgz | tar xz \
    && mv docker/docker /usr/local/bin/ \
    && rm -rf docker/

# Install ArgoCD CLI
RUN curl -sLO https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64 \
    && chmod +x argocd-linux-amd64 \
    && mv argocd-linux-amd64 /usr/local/bin/argocd

# Install Helm
RUN curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# Install yq
RUN curl -sL https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# Install envsubst
RUN apt-get install -y gettext-base

# Verify installation
RUN docker --version && \
    argocd version --client && \
    helm version && \
    kubectl version --client && \
    yq --version

# Set entrypoint
CMD ["/bin/bash"]

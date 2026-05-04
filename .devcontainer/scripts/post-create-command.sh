#.devcontainer/scripts/post-create-command.sh

#!/bin/bash
set -Eeuo pipefail

error() {
    echo "Error during initialization"
    exit 1
}

trap error ERR

main() {
    echo "Post Create Command started..."
    
    # Install Azure CLI with brew
    if ! command -v az &>/dev/null; then
        echo "Installing Azure CLI..."
        brew install azure-cli || {
            echo "Failed to install Azure CLI."
            exit 1
        }
    else
        echo "Azure CLI is already installed."
    fi

    # Install kubectx
    if ! command -v kubectx &>/dev/null; then
        echo "Installing kubectx..."
        brew install kubectx || {
            echo "Failed to install kubectx."
            exit 1
        }
    else
        echo "kubectx is already installed."
    fi

    # Install Terraform version 1.8.1
    if ! command -v terraform &>/dev/null; then
        echo "Installing Terraform..."
        brew tap hashicorp/tap || {
            echo "Failed to tap HashiCorp repository."
            exit 1
        }
        brew install hashicorp/tap/terraform || {
            echo "Failed to install Terraform."
            exit 1
        }
    else
        echo "Terraform is already installed."
    fi
   
   # Install Azure Kubelogin
    if ! command -v kubelogin &>/dev/null; then
        echo "Installing Azure Kubelogin..."
        brew install Azure/kubelogin/kubelogin || {
            echo "Failed to install Azure Kubelogin."
            exit 1
        }
    else
        echo "Azure Kubelogin is already installed."
    fi
    
    

    echo "Post Create Command completed."
}

main "$@"
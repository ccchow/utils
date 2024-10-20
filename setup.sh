#!/bin/bash

# Default Variables
MOUNT_POINT="/mnt/data"
SYMLINK_TARGETS=(
    "$HOME/data"
    # Add more paths where you want to create symbolic links
)
DATA_DEVICE="/dev/sdb"  # Replace with the actual device name or identifier
FILE_SYSTEM_TYPE="ext4"  # Replace with the actual file system type if different

# Paths for conda, pip, Hugging Face, and Docker
PERSISTENT_CONDA_DIR="$MOUNT_POINT/conda"
PERSISTENT_PIP_CACHE_DIR="$MOUNT_POINT/pip_cache"
PERSISTENT_HF_CACHE_DIR="$MOUNT_POINT/huggingface_cache"
HUGGINGFACE_TOKEN_FILE="$MOUNT_POINT/huggingface_token.txt"
PERSISTENT_DOCKER_CACHE_DIR="$MOUNT_POINT/docker_cache"

# Parse arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --mount-point)
            MOUNT_POINT="$2"
            shift; shift
            ;;
        --data-device)
            DATA_DEVICE="$2"
            shift; shift
            ;;
        --file-system-type)
            FILE_SYSTEM_TYPE="$2"
            shift; shift
            ;;
        --persistent-conda-dir)
            PERSISTENT_CONDA_DIR="$2"
            shift; shift
            ;;
        --persistent-pip-cache-dir)
            PERSISTENT_PIP_CACHE_DIR="$2"
            shift; shift
            ;;
        --persistent-hf-cache-dir)
            PERSISTENT_HF_CACHE_DIR="$2"
            shift; shift
            ;;
        --huggingface-token-file)
            HUGGINGFACE_TOKEN_FILE="$2"
            shift; shift
            ;;
        --persistent-docker-cache-dir)
            PERSISTENT_DOCKER_CACHE_DIR="$2"
            shift; shift
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

# Function to mount the data folder
# mount_data_folder() {
#     echo "Mounting data folder..."

#     # Create mount point if it doesn't exist
#     if [ ! -d "$MOUNT_POINT" ]; then
#         sudo mkdir -p "$MOUNT_POINT"
#     fi

#     # Mount the data volume
#     sudo mount -t "$FILE_SYSTEM_TYPE" "$DATA_DEVICE" "$MOUNT_POINT"

#     if [ $? -ne 0 ]; then
#         echo "Failed to mount data folder."
#         exit 1
#     fi

#     echo "Data folder mounted at $MOUNT_POINT."
# }

# Function to create symbolic links
create_symbolic_links() {
    for SYMLINK_TARGET in "${SYMLINK_TARGETS[@]}"; do
        if [ -L "$SYMLINK_TARGET" ]; then
            echo "Symbolic link $SYMLINK_TARGET already exists."
        else
            ln -s "$MOUNT_POINT" "$SYMLINK_TARGET"
            echo "Created symbolic link from $SYMLINK_TARGET to $MOUNT_POINT"
        fi
    done
}

# Function to set up conda
setup_conda() {
    echo "Setting up Conda..."

    # Check if conda is installed in the persistent directory
    if [ ! -d "$PERSISTENT_CONDA_DIR" ]; then
        echo "Conda not found in persistent storage. Installing Miniconda..."

        # Download and install Miniconda to the persistent directory
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh
        bash /tmp/miniconda.sh -b -p "$PERSISTENT_CONDA_DIR"
        rm /tmp/miniconda.sh
    else
        echo "Conda found in persistent storage."
    fi

    # Set up environment variables to use the persistent conda installation
    export PATH="$PERSISTENT_CONDA_DIR/bin:$PATH"

    # Initialize conda
    source "$PERSISTENT_CONDA_DIR/etc/profile.d/conda.sh"
    conda init bash

    echo "Conda setup complete."
}

# Function to set up pip cache
setup_pip_cache() {
    echo "Setting up pip cache..."

    # Create pip cache directory if it doesn't exist
    if [ ! -d "$PERSISTENT_PIP_CACHE_DIR" ]; then
        mkdir -p "$PERSISTENT_PIP_CACHE_DIR"
    fi

    # Set pip cache directory environment variable
    export PIP_CACHE_DIR="$PERSISTENT_PIP_CACHE_DIR"

    echo "Pip cache directory set to $PIP_CACHE_DIR."
}

# Function to set up Hugging Face cache
setup_huggingface_cache() {
    echo "Setting up Hugging Face cache..."

    # Create Hugging Face cache directory if it doesn't exist
    if [ ! -d "$PERSISTENT_HF_CACHE_DIR" ]; then
        mkdir -p "$PERSISTENT_HF_CACHE_DIR"
    fi

    # Set Hugging Face cache directory environment variable
    export HF_HOME="$PERSISTENT_HF_CACHE_DIR"

    # Configure Hugging Face token if the token file exists
    if [ -f "$HUGGINGFACE_TOKEN_FILE" ]; then
        HUGGINGFACE_TOKEN=$(cat "$HUGGINGFACE_TOKEN_FILE")
        export HUGGINGFACE_TOKEN
        echo "Hugging Face token configured."
    else
        echo "Hugging Face token file not found at $HUGGINGFACE_TOKEN_FILE."
    fi

    echo "Hugging Face cache directory set to $HF_HOME."
}

# Function to set up Docker cache
setup_docker_cache() {
    echo "Setting up Docker cache..."

    # Create Docker cache directory if it doesn't exist
    if [ ! -d "$PERSISTENT_DOCKER_CACHE_DIR" ]; then
        mkdir -p "$PERSISTENT_DOCKER_CACHE_DIR"
    fi

    # Configure Docker to use the persistent cache directory
    sudo mkdir -p /etc/docker
    echo "{
  \"data-root\": \"$PERSISTENT_DOCKER_CACHE_DIR\"
}" | sudo tee /etc/docker/daemon.json > /dev/null

    # Restart Docker to apply changes
    sudo systemctl restart docker

    echo "Docker cache directory set to $PERSISTENT_DOCKER_CACHE_DIR."
}

# Main script execution
echo "Starting setup..."

# Mount the data folder
# mount_data_folder

# Create symbolic links
create_symbolic_links

# Set up pip cache
setup_pip_cache

# Set up Hugging Face cache
setup_huggingface_cache

# Set up Docker cache
setup_docker_cache

# Set up Conda
setup_conda

echo "Setup complete."

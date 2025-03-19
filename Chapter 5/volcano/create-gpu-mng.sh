# This script creates a GPU managed node group in an EKS cluster.
# This script has been tested on Linux
# Usage: ./create-gpu-mng.sh --auto-approve (optional)
# --auto-approve flag skips confirmation prompts.

# Constants
CLUSTER_NAME="mlops-cluster"
GPU_NODEGROUP_NAME="gpu-nodes"
INSTANCE_TYPE="g6.xlarge"
DISK_SIZE=100
MIN_SIZE=2
MAX_SIZE=2
DESIRED_SIZE=2
NODE_ROLE_IAM_POLICIES=(
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
)

# Function to log messages
# Usage: log "Message"
log() {
    echo -e "[INFO] $1"
}

# Cleanup function to delete IAM role if script fails
cleanup_iam_role() {
    if [[ -n "$NODE_IAM_ROLE_ARN" ]]; then
        log "Cleaning up IAM role: $NODE_IAM_ROLE_NAME..."
        for policy in "${NODE_ROLE_IAM_POLICIES[@]}"; do
            aws iam detach-role-policy --role-name "$NODE_IAM_ROLE_NAME" --policy-arn "$policy" 2>/dev/null || log "Failed to detach policy: $policy"
        done
        aws iam delete-role --role-name "$NODE_IAM_ROLE_NAME" || log "Failed to delete IAM role: $NODE_IAM_ROLE_NAME"
        log "IAM role cleanup completed."
    fi
}

# Function to handle errors and exit. 
# It deletes the NODE IAM role if it was created.
# Usage: error_exit "Error message"
error_exit() {
    echo -e "[ERROR] $1"
    cleanup_iam_role
    exit 1
}

# Validate dependencies
command -v aws >/dev/null 2>&1 || error_exit "AWS CLI is not installed. Please install it and configure credentials."
command -v kubectl >/dev/null 2>&1 || error_exit "kubectl is not installed. Please install it."
command -v jq >/dev/null 2>&1 || error_exit "jq is required but not installed. Install it with 'sudo apt-get install jq' or equivalent."

enable_cluster_addon() {
  addon_name="$1"
  addon_status=$(aws eks describe-addon --addon-name vpc-cni \
    --cluster-name $CLUSTER_NAME --query addon.status --output text) || echo "NOT_FOUND"
  if ! [[ "$addon_status" == "ACTIVE" ]]; then
    log "Enabling cluster addon $addon_name"
    res=$(aws eks create-addon --cluster-name ${CLUSTER_NAME} \
      --addon-name $addon_name) || error_exit "Failed to create addon $addon_name."
  else
    log "Addon $addon_name is already enabled."
  fi
}

setup_iam_role() {
  log "Creating IAM role for the node group..."
  NODE_IAM_ROLE_NAME="${CLUSTER_NAME}-${GPU_NODEGROUP_NAME}"
  AWS_ACCOUNT_NUM=$(aws sts get-caller-identity --query "Account" --output text) || error_exit "Failed to get AWS account number."
  NODE_IAM_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_NUM}:role/${NODE_IAM_ROLE_NAME}"

  # Check if IAM role already exists. If it does, prompt for deletion.
   if aws iam get-role --role-name "$NODE_IAM_ROLE_NAME" &>/dev/null; then
        log "IAM role $NODE_IAM_ROLE_NAME already exists."

        if [[ "$AUTO_APPROVE" == false ]]; then
            read -rp "Do you want to delete and recreate it? Type 'y' to continue: " user_input
            if [[ "$user_input" != "y" ]]; then
                log "Exiting script as IAM role already exists. No changes made."
                exit 0
            fi
        fi

        cleanup_iam_role
    fi

# Create IAM role with EKS trust policy
  log "Generating trust policy document for IAM role..."
  cat <<EOF > trust-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": { "Service": "ec2.amazonaws.com" },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF

  NODE_IAM_ROLE_ARN=$(aws iam create-role --role-name "$NODE_IAM_ROLE_NAME" \
    --assume-role-policy-document file://trust-policy.json \
    --query "Role.Arn" --output text) || error_exit "Failed to create IAM role."

  for policy in "${NODE_ROLE_IAM_POLICIES[@]}"; do
    log "Attaching policy $policy to $NODE_IAM_ROLE_NAME..."
    aws iam attach-role-policy --role-name "$NODE_IAM_ROLE_NAME" --policy-arn "$policy" || error_exit "Failed to attach policy $policy."
  done

}

# Function to fetch Kubernetes node details
get_k8s_node_subnet() {
    log "Randomly selecting a running node..."
    NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}') || error_exit "Failed to retrieve a node from the cluster."

    log "Fetching instance ID for node: $NODE_NAME..."
    INSTANCE_ID=$(aws ec2 describe-instances \
        --filters "Name=instance-id,Values=$NODE_NAME" \
        --query 'Reservations[].Instances[].InstanceId' \
        --output text) || error_exit "Failed to get instance ID."

    log "Fetching subnet ID for instance..."
    SUBNET=$(aws ec2 describe-instances \
        --instance-ids "$NODE_NAME" \
        --query 'Reservations[].Instances[].SubnetId' \
        --output text) || error_exit "Failed to get subnet ID."
}

# Function to create the GPU node group
create_gpu_nodegroup() {
    # Check if node group already exists
    if aws eks describe-nodegroup --cluster-name "$CLUSTER_NAME" --nodegroup-name "$GPU_NODEGROUP_NAME" &>/dev/null; then
      log "Managed node group $GPU_NODEGROUP_NAME already exists."
        read -rp "Do you want to delete and recreate it? Type 'y' to continue: " user_input
        if [[ "$user_input" == "y" ]]; then
            log "Deleting existing node group $GPU_NODEGROUP_NAME..."
            result=$(aws eks delete-nodegroup --cluster-name "$CLUSTER_NAME" --nodegroup-name "$GPU_NODEGROUP_NAME")
            log "Waiting for node group deletion to complete..."
            while true; do
                NODEGROUP_STATUS=$(aws eks describe-nodegroup --cluster-name "$CLUSTER_NAME" --nodegroup-name "$GPU_NODEGROUP_NAME" --query "nodegroup.status" --output text 2>/dev/null || echo "DELETED")
                if [[ "$NODEGROUP_STATUS" == "DELETED" ]]; then
                    log "Node group successfully deleted."
                    break
                fi
                sleep 30
            done
        else
            log "Exiting script as node group already exists. No changes made."
            exit 0
        fi
    fi

    log "Creating GPU node group: $GPU_NODEGROUP_NAME..."
    res=$(aws eks create-nodegroup \
        --cluster-name "$CLUSTER_NAME" \
        --subnet "$SUBNET" \
        --node-role "$NODE_IAM_ROLE_ARN" \
        --nodegroup-name "$GPU_NODEGROUP_NAME" \
        --instance-types "$INSTANCE_TYPE" \
        --disk-size "$DISK_SIZE" \
        --scaling-config "minSize=$MIN_SIZE,maxSize=$MAX_SIZE,desiredSize=$DESIRED_SIZE" \
        --ami-type "AL2_x86_64_GPU" \
        --taints '{"key": "nvidia.com/gpu" ,  "effect": "NO_SCHEDULE"}' \
        --output text) || error_exit "Failed to create GPU node group."

    log "Successfully initiated GPU node group creation."

    # Wait for node group to become ACTIVE
    log "Waiting for node group to reach 'ACTIVE' state..."
    while true; do
        NODEGROUP_STATUS=$(aws eks describe-nodegroup --cluster-name "$CLUSTER_NAME" --nodegroup-name "$GPU_NODEGROUP_NAME" --query "nodegroup.status" --output text)
        log "Current node group status: $NODEGROUP_STATUS"
        if [[ "$NODEGROUP_STATUS" == "ACTIVE" ]]; then
            log "Node group is now ACTIVE."
            break
        elif [[ "$NODEGROUP_STATUS" == "DELETING" ]]; then
            error_exit "Node group creation failed."
        elif [[ "$NODEGROUP_STATUS" == "CREATE_FAILED" ]]; then
            error_exit "Node group creation failed."
        fi
        sleep 30
    done

    log "Created GPU managed node group. Details:"
    log "subnet: $SUBNET"
    log "node group: $GPU_NODEGROUP_NAME"
    log "node IAM role: $NODE_IAM_ROLE_NAME"
    log "instance type: $INSTANCE_TYPE"
}

main() {
    
    AUTO_APPROVE=false
    for arg in "$@"; do
      case "$arg" in
          --auto-approve)
              AUTO_APPROVE=true
              ;;
          *)
              error_exit "Unknown argument: $arg"
              ;;
      esac
    done


    if [[ "$AUTO_APPROVE" == false ]]; then
        read -rp "This script will create an EKS managed node group with $INSTANCE_TYPE instances. Type 'y' to continue: " user_input
        if [[ "$user_input" != "y" ]]; then
            echo "Operation aborted by user."
            exit 0
        fi
    fi
    
    # Check if the EKS cluster exists
    if ! aws eks describe-cluster --name "$CLUSTER_NAME" &>/dev/null; then
      error_exit "EKS cluster $CLUSTER_NAME not found."
    fi

    # Check if the node group already exists
    if aws eks describe-nodegroup --cluster-name "$CLUSTER_NAME" --nodegroup-name "$GPU_NODEGROUP_NAME" --query "nodegroup.status" --output text &>/dev/null; then
      # Check if the node group's status is ACTIVE, DELETING, or CREATE_FAILED
      NODEGROUP_STATUS=$(aws eks describe-nodegroup --cluster-name "$CLUSTER_NAME" --nodegroup-name "$GPU_NODEGROUP_NAME" --query "nodegroup.status" --output text)
      if [[ "$NODEGROUP_STATUS" == "ACTIVE" ]]; then
        error_exit "Node group already exists. Please delete it before running this script by running the command: aws eks delete-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $GPU_NODEGROUP_NAME"
      elif [[ "$NODEGROUP_STATUS" == "DELETING" ]]; then
        error_exit "Node group is still deleting. Please wait for it to be deleted before running this script. To view nodegroup status, run \"aws eks describe-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $GPU_NODEGROUP_NAME --query nodegroup.status --output text\""
      elif [[ "$NODEGROUP_STATUS" == "CREATE_FAILED" ]]; then
        error_exit "Node is in CREATE_FAILED state. Please delete it before running this script by running the command: aws eks delete-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name $GPU_NODEGROUP_NAME"
      fi
    fi
    
    # Enable required cluster addons for managed node groups
    enable_cluster_addon "vpc-cni"
    enable_cluster_addon "kube-proxy"
    
    setup_iam_role
    get_k8s_node_subnet
    create_gpu_nodegroup

}

# Run the main function
main "$@"

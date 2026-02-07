#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-eks-dev}"
AWS_REGION="${AWS_REGION:-us-east-1}"
K8S_VERSION="${K8S_VERSION:-1.35}"
ALLOWED_AZS="${ALLOWED_AZS:-us-east-1a,us-east-1b}"

NODEGROUP_NAME="${NODEGROUP_NAME:-tools}"
NODE_INSTANCE_TYPE="${NODE_INSTANCE_TYPE:-t3.medium}"
NODE_MIN_SIZE="${NODE_MIN_SIZE:-2}"
NODE_MAX_SIZE="${NODE_MAX_SIZE:-2}"
NODE_DESIRED_SIZE="${NODE_DESIRED_SIZE:-2}"
NODE_DISK_SIZE="${NODE_DISK_SIZE:-20}"
NODE_CAPACITY_TYPE="${NODE_CAPACITY_TYPE:-ON_DEMAND}"
NODE_LABELS="${NODE_LABELS:-workload=tools}"
NODE_TAINTS="${NODE_TAINTS:-}"

CLUSTER_ROLE_NAME="${CLUSTER_ROLE_NAME:-eks-cluster-role}"
NODE_ROLE_NAME="${NODE_ROLE_NAME:-eks-node-role}"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: missing dependency: $1" >&2
    exit 1
  fi
}

require_cmd aws
require_cmd jq

export AWS_PAGER=""

echo "Using:"
echo "  CLUSTER_NAME=${CLUSTER_NAME}"
echo "  AWS_REGION=${AWS_REGION}"
echo "  K8S_VERSION=${K8S_VERSION}"
echo "  ALLOWED_AZS=${ALLOWED_AZS}"
echo "  NODEGROUP_NAME=${NODEGROUP_NAME}"
echo "  NODE_INSTANCE_TYPE=${NODE_INSTANCE_TYPE}"
echo "  NODE_MIN_SIZE=${NODE_MIN_SIZE}"
echo "  NODE_MAX_SIZE=${NODE_MAX_SIZE}"
echo "  NODE_DESIRED_SIZE=${NODE_DESIRED_SIZE}"
echo "  NODE_DISK_SIZE=${NODE_DISK_SIZE}"
echo "  NODE_CAPACITY_TYPE=${NODE_CAPACITY_TYPE}"
echo "  NODE_LABELS=${NODE_LABELS}"
echo "  NODE_TAINTS=${NODE_TAINTS}"

aws sts get-caller-identity >/dev/null

VPC_ID="$(aws ec2 describe-vpcs \
  --region "${AWS_REGION}" \
  --filters Name=isDefault,Values=true \
  --query 'Vpcs[0].VpcId' \
  --output text)"

if [[ -z "${VPC_ID}" || "${VPC_ID}" == "None" ]]; then
  echo "ERROR: default VPC not found in ${AWS_REGION}" >&2
  exit 1
fi

IFS=',' read -r -a AZ_LIST <<< "${ALLOWED_AZS}"
SUBNET_IDS=()
for az in "${AZ_LIST[@]}"; do
  subnet_id="$(aws ec2 describe-subnets \
    --region "${AWS_REGION}" \
    --filters Name=vpc-id,Values="${VPC_ID}" Name=availability-zone,Values="${az}" \
    --query 'Subnets[0].SubnetId' \
    --output text)"
  if [[ -n "${subnet_id}" && "${subnet_id}" != "None" ]]; then
    SUBNET_IDS+=("${subnet_id}")
  fi
done

if [[ "${#SUBNET_IDS[@]}" -lt 2 ]]; then
  echo "ERROR: need at least 2 subnets in allowed AZs. Found: ${#SUBNET_IDS[@]}" >&2
  exit 1
fi

echo "Default VPC: ${VPC_ID}"
echo "Subnets: ${SUBNET_IDS[*]}"

CLUSTER_ROLE_ARN="$(aws iam get-role --role-name "${CLUSTER_ROLE_NAME}" --query 'Role.Arn' --output text 2>/dev/null || true)"
if [[ -z "${CLUSTER_ROLE_ARN}" || "${CLUSTER_ROLE_ARN}" == "None" ]]; then
  echo "Creating IAM role for EKS control plane: ${CLUSTER_ROLE_NAME}"
  cat > /tmp/eks-cluster-trust.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "eks.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  CLUSTER_ROLE_ARN="$(aws iam create-role \
    --role-name "${CLUSTER_ROLE_NAME}" \
    --assume-role-policy-document file:///tmp/eks-cluster-trust.json \
    --query 'Role.Arn' \
    --output text)"
  aws iam attach-role-policy --role-name "${CLUSTER_ROLE_NAME}" --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
  aws iam attach-role-policy --role-name "${CLUSTER_ROLE_NAME}" --policy-arn arn:aws:iam::aws:policy/AmazonEKSVPCResourceController
fi

NODE_ROLE_ARN="$(aws iam get-role --role-name "${NODE_ROLE_NAME}" --query 'Role.Arn' --output text 2>/dev/null || true)"
if [[ -z "${NODE_ROLE_ARN}" || "${NODE_ROLE_ARN}" == "None" ]]; then
  echo "Creating IAM role for node group: ${NODE_ROLE_NAME}"
  cat > /tmp/eks-node-trust.json <<'EOF'
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
  NODE_ROLE_ARN="$(aws iam create-role \
    --role-name "${NODE_ROLE_NAME}" \
    --assume-role-policy-document file:///tmp/eks-node-trust.json \
    --query 'Role.Arn' \
    --output text)"
  aws iam attach-role-policy --role-name "${NODE_ROLE_NAME}" --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
  aws iam attach-role-policy --role-name "${NODE_ROLE_NAME}" --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
  aws iam attach-role-policy --role-name "${NODE_ROLE_NAME}" --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
  aws iam attach-role-policy --role-name "${NODE_ROLE_NAME}" --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
fi


echo "Creating EKS cluster (if not exists)..."
if ! aws eks describe-cluster --region "${AWS_REGION}" --name "${CLUSTER_NAME}" >/dev/null 2>&1; then
  aws eks create-cluster \
    --region "${AWS_REGION}" \
    --name "${CLUSTER_NAME}" \
    --kubernetes-version "${K8S_VERSION}" \
    --role-arn "${CLUSTER_ROLE_ARN}" \
    --resources-vpc-config subnetIds="$(IFS=,; echo "${SUBNET_IDS[*]}")",endpointPublicAccess=true
fi

aws eks wait cluster-active --region "${AWS_REGION}" --name "${CLUSTER_NAME}"


echo "Creating managed node group (if not exists)..."
if ! aws eks describe-nodegroup --region "${AWS_REGION}" --cluster-name "${CLUSTER_NAME}" --nodegroup-name "${NODEGROUP_NAME}" >/dev/null 2>&1; then
  aws eks create-nodegroup \
    --region "${AWS_REGION}" \
    --cluster-name "${CLUSTER_NAME}" \
    --nodegroup-name "${NODEGROUP_NAME}" \
    --subnets "${SUBNET_IDS[@]}" \
    --node-role "${NODE_ROLE_ARN}" \
    --instance-types "${NODE_INSTANCE_TYPE}" \
    --disk-size "${NODE_DISK_SIZE}" \
    --scaling-config minSize="${NODE_MIN_SIZE}",maxSize="${NODE_MAX_SIZE}",desiredSize="${NODE_DESIRED_SIZE}" \
    --labels "${NODE_LABELS}" \
    --capacity-type "${NODE_CAPACITY_TYPE}"
fi

aws eks wait nodegroup-active --region "${AWS_REGION}" --cluster-name "${CLUSTER_NAME}" --nodegroup-name "${NODEGROUP_NAME}"

echo "Updating kubeconfig..."
aws eks update-kubeconfig --region "${AWS_REGION}" --name "${CLUSTER_NAME}"

echo "Done."

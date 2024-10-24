#!/bin/bash

# Set the prefix for the tag value we are looking for
TAG_NAME_PREFIX="deepRacer-*"

# Set the AWS region (adjust if needed)
REGION="us-east-1"

# Function to terminate EC2 instances based on tag
terminate_ec2_instances() {
  echo "Searching for EC2 instances with tag Name starting with $TAG_NAME_PREFIX..."

  INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$TAG_NAME_PREFIX" \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text --region $REGION)

  if [ -n "$INSTANCE_IDS" ]; then
    echo "Terminating EC2 instances: $INSTANCE_IDS"
    aws ec2 terminate-instances --instance-ids $INSTANCE_IDS --region $REGION
    echo "EC2 instances terminated."
  else
    echo "No EC2 instances found with tag Name starting with $TAG_NAME_PREFIX."
  fi
}

# Function to delete S3 buckets based on tag
delete_s3_buckets() {
  echo "Searching for S3 buckets with tag Name starting with $TAG_NAME_PREFIX..."

  BUCKETS=$(aws s3api list-buckets --query "Buckets[].Name" --output text)

  for BUCKET in $BUCKETS; do
    TAGS=$(aws s3api get-bucket-tagging --bucket $BUCKET --query 'TagSet' --output text 2>/dev/null)
    if [[ $TAGS == *"Name"* && $TAGS == *"$TAG_NAME_PREFIX"* ]]; then
      echo "Deleting S3 bucket: $BUCKET"
      aws s3 rb s3://$BUCKET --force
    fi
  done
}

# Function to delete CloudFormation stacks based on tag
delete_cloudformation_stacks() {
  echo "Searching for CloudFormation stacks with tag Name starting with $TAG_NAME_PREFIX..."

  STACKS=$(aws cloudformation describe-stacks --query "Stacks[?Tags[?Key=='Name' && starts_with(Value, \`${TAG_NAME_PREFIX}\`)]].StackName" --output text --region $REGION)

  for STACK in $STACKS; do
    echo "Deleting CloudFormation stack: $STACK"
    aws cloudformation delete-stack --stack-name $STACK --region $REGION
    echo "CloudFormation stack $STACK deletion initiated."
  done

  if [ -z "$STACKS" ]; then
    echo "No CloudFormation stacks found with tag Name starting with $TAG_NAME_PREFIX."
  fi
}

# Main function to run the cleanup tasks
cleanup_resources() {
  echo "Starting cleanup of AWS resources with tag Name starting with $TAG_NAME_PREFIX..."

  terminate_ec2_instances
  delete_s3_buckets
  delete_cloudformation_stacks

  echo "Cleanup process completed."
}

# Run the cleanup
cleanup_resources

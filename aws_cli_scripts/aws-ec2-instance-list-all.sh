#!/bin/bash

echo "Fetching all EC2 instances in all regions..."

# Get all region names
regions=$(aws ec2 describe-regions --query "Regions[*].RegionName" --output text)

for region in $regions; do
  echo "🔍 Region: $region"
  
  aws ec2 describe-instances \
    --region "$region" \
    --query 'Reservations[*].Instances[*].{ID:InstanceId,Type:InstanceType,State:State.Name,Name:Tags[?Key==`Name`]|[0].Value}' \
    --output table
done

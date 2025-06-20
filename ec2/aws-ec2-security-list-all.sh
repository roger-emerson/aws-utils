#!/bin/bash

echo "Fetching all EC2 security groups in all regions..."

# Get all region names
regions=$(aws ec2 describe-regions --query "Regions[*].RegionName" --output text)

for region in $regions; do
  echo "🔍 Region: $region"

  aws ec2 describe-security-groups \
    --region "$region" \
    --query 'SecurityGroups[*].{GroupName:GroupName, GroupId:GroupId, Description:Description, VpcId:VpcId}' \
    --output table
done

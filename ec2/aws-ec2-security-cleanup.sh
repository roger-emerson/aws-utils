#!/bin/bash

echo "🚨 Deleting all non-default security groups in all AWS regions..."

regions=$(aws ec2 describe-regions --query "Regions[*].RegionName" --output text)

for region in $regions; do
  echo "🔍 Region: $region"

  # Get non-default security group IDs
  sg_ids=$(aws ec2 describe-security-groups \
    --region "$region" \
    --query "SecurityGroups[?GroupName!='default'].GroupId" \
    --output text)

  for sg_id in $sg_ids; do
    echo "🗑️  Attempting to delete $sg_id in $region..."
    aws ec2 delete-security-group --region "$region" --group-id "$sg_id" 2>/dev/null

    if [ $? -eq 0 ]; then
      echo "✅ Deleted $sg_id"
    else
      echo "⚠️ Could not delete $sg_id (probably in use)"
    fi
  done

  echo "----------------------------"
done

echo "🎉 Security group cleanup complete."
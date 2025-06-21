#!/bin/bash

# Get all regions
regions=$(aws ec2 describe-regions --query "Regions[*].RegionName" --output text)

for region in $regions; do
  echo "Cleaning EC2 resources in region: $region"

  # Terminate all EC2 instances
  instance_ids=$(aws ec2 describe-instances \
    --region $region \
    --query "Reservations[*].Instances[*].InstanceId" \
    --output text)

  if [ -n "$instance_ids" ]; then
    echo "Terminating instances in $region: $instance_ids"
    aws ec2 terminate-instances --region $region --instance-ids $instance_ids
  fi

  # Wait for instances to terminate
  for id in $instance_ids; do
    echo "Waiting for instance $id to terminate..."
    aws ec2 wait instance-terminated --region $region --instance-ids $id
  done

  # Delete unattached volumes
  volume_ids=$(aws ec2 describe-volumes \
    --region $region \
    --filters Name=status,Values=available \
    --query "Volumes[*].VolumeId" \
    --output text)

  for volume in $volume_ids; do
    echo "Deleting volume: $volume"
    aws ec2 delete-volume --region $region --volume-id $volume
  done

  # Delete non-default security groups
  sg_ids=$(aws ec2 describe-security-groups \
    --region $region \
    --query "SecurityGroups[?GroupName!='default'].GroupId" \
    --output text)

  for sg in $sg_ids; do
    echo "Deleting security group: $sg"
    aws ec2 delete-security-group --region $region --group-id $sg 2>/dev/null
  done

  echo "✅ Done with $region"
  echo "-----------------------------"
done

echo "🎉 All EC2-related resources cleared."
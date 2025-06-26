#!/bin/bash

echo "📋 Listing all managed prefix lists in all AWS regions..."

regions=$(aws ec2 describe-regions --query "Regions[*].RegionName" --output text)

for region in $regions; do
  echo "🔍 Region: $region"

  aws ec2 describe-managed-prefix-lists \
    --region "$region" \
    --query "PrefixLists[*].{ID:PrefixListId, Name:PrefixListName, Owner:OwnerId, MaxEntries:MaxEntries}" \
    --output table
done
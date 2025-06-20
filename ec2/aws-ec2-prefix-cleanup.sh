#!/bin/bash

echo "🚨 Deleting all user-managed prefix lists in all AWS regions..."

regions=$(aws ec2 describe-regions --query "Regions[*].RegionName" --output text)

for region in $regions; do
  echo "🔍 Region: $region"

  # Get only user-managed prefix list IDs
  plist_ids=$(aws ec2 describe-managed-prefix-lists \
    --region "$region" \
    --query "PrefixLists[?PrefixListArn.contains(@, 'prefix-list') && OwnerId=='$(aws sts get-caller-identity --query Account --output text)'].PrefixListId" \
    --output text)

  for plist_id in $plist_ids; do
    echo "🗑️  Deleting Prefix List: $plist_id in $region..."
    aws ec2 delete-managed-prefix-list \
      --region "$region" \
      --prefix-list-id "$plist_id" 2>/dev/null

    if [ $? -eq 0 ]; then
      echo "✅ Deleted $plist_id"
    else
      echo "⚠️ Could not delete $plist_id (maybe in use or protected)"
    fi
  done

  echo "----------------------------"
done

echo "🎉 Managed prefix list cleanup complete."
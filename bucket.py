import boto3
import sys

def delete_bucket(bucket_name):
    """Deletes all objects and the bucket itself."""
    s3 = boto3.resource('s3')
    bucket = s3.Bucket(bucket_name)

    # First, delete all objects in the bucket
    print(f"Deleting all objects from bucket: {bucket_name}")
    bucket.objects.all().delete()

    # Now, delete the bucket
    print(f"Deleting bucket: {bucket_name}")
    bucket.delete()

def get_buckets_with_tag(tag_key, tag_value):
    """Returns a list of bucket names that have the specified tag key and value."""
    s3_client = boto3.client('s3')
    response = s3_client.list_buckets()
    
    buckets_to_delete = []

    for bucket in response['Buckets']:
        bucket_name = bucket['Name']
        try:
            tags = s3_client.get_bucket_tagging(Bucket=bucket_name)
            for tag in tags['TagSet']:
                if tag['Key'] == tag_key and tag['Value'].startswith(tag_value):
                    buckets_to_delete.append(bucket_name)
        except s3_client.exceptions.NoSuchTagSet:
            # Ignore buckets that don't have tags
            continue
        except Exception as e:
            print(f"Error checking tags for bucket {bucket_name}: {e}")
            continue

    return buckets_to_delete

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python delete_s3_buckets_by_tag.py <tag-key> <tag-value>")
        sys.exit(1)

    tag_key = sys.argv[1]
    tag_value = sys.argv[2]

    print(f"Looking for buckets with tag {tag_key}={tag_value}")

    buckets_to_delete = get_buckets_with_tag(tag_key, tag_value)

    if not buckets_to_delete:
        print("No buckets found with the specified tag.")
    else:
        for bucket_name in buckets_to_delete:
            try:
                delete_bucket(bucket_name)
            except Exception as e:
                print(f"Failed to delete bucket {bucket_name}: {e}")

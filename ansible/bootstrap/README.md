# Infrastructure Bootstrap Scripts

## Step 1: Build Docker Images

1. Update configuration variables labeled with `TODO` in _build.conf_ file.
2. Optionally run `ansible/bin/install-git-hook.sh` to install GIT pre-commit hook to prevent commit of unencrypted configuration files.
3. Run `build` to build all Docker images. Add the `-f` parameter if you did not install GIT pre-commit hook. Optionally supply the `-p` parameter to push Docker images to registry.

## Step 2: Prepare AWS for Deployment

1. Create "_ansible" user in IAM with the following permissions:
```AmazonEC2FullAccess, AmazonS3FullAccess, AmazonRoute53FullAccess, ReadOnlyAccess```

2. Create "_ops" user in IAM with `AmazonS3FullAccess, AmazonRoute53FullAccess` permission.

3. Create "<prefix>-ops" bucket in S3 using `boto`, with "_ops" user account's access id and key:
```
from boto.s3.connection import S3Connection
conn = S3Connection('<aws_access_key_id>', '<aws_secret_access_key>')
from boto.s3.connection import Location
conn.create_bucket('<prefix>-ops, location=Location.USWest2)
```

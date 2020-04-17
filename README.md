# terraform-cassidynelemans.com

Terraform code to deploy the infrastructure needed to host https://www.cassidynelemans.com

Website repo is located here: https://github.com/nelemansc/cassidynelemans.com

Deploys the following:
- Bare domain S3 bucket
- www domain S3 bucket
- Cloudfront distribuction for TLS support
- Route53 records to resolve the bare and www to the Cloudfront distribution

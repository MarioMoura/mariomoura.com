---
title: "Super simple AWS static website using Terraform"
date: 2025-07-05T10:13:37-03:00
tags:
  - aws
  - terraform
  - s3
  - cloudfront
image: '/img/posts/aws-static-site.jpeg'
comments: true
params:
    dotfile: false
summary: "This article explains how to configure a simple and hands off static website on AWS."
---

# Short word on static websites

I'm not going to scratch the surface on the debate between static and dynamic sites.
They both are tools and have their respective use cases.

I will, however, assume here that you want (or need) to deploy some static code using the simplest
solution as possible.

**Note on Terraform**: The management of a Terraform stack is a bit out of scope for this article,
I will not comment on state management. It is totally possible to use template code as a *run-once*
solution.

# Requirements
1. AWS Account
2. Route53 Domain
3. Code to deploy
4. Terraform installed

Make sure you can run `aws sts get-caller-identity` successfully on you shell.

## Architecture
CDN included. Versioning on the bucket in case you mess up something.
```
+------+     +----------+     +---------+
|Client| ==> |Cloudfront| ==> |S3 Bucket|
+------+     +----------+     +---------+
```
## Cost
1. Domain annual cost.
2. S3 storage, generally pretty low, depends on the size of your site.
3. Traffic, Cloudfront is the cheapest way of getting data out of AWS.

# The code

Using two modules:
- [s3-static-websites](https://registry.terraform.io/modules/cn-terraform/s3-static-website/aws/latest)
- [syncdir](https://registry.terraform.io/modules/MarioMoura/syncdir/aws/latest)

Make sure to replace the `< >` fields with what suits you.

```terraform
provider "aws" {
  alias  = "global"
  # Has to be us-east-1
  region = "us-east-1"
}

provider "aws" {
  region = <YOUR_REGION>
}

data "aws_route53_zone" "dns_zone" {
  # Like: example.com
  name = <YOUR_DOMAIN>
}
module "s3-static-website" {
  source  = "cn-terraform/s3-static-website/aws"
  version = "1.0.10"
  providers = {
    aws.main         = aws
    aws.acm_provider = aws.global
  }

  # Like: blog.example.com
  name_prefix         = <YOUR_SUBDOMAIN>
  website_domain_name = <YOUR_SUBDOMAIN>


  create_route53_hosted_zone = false
  route53_hosted_zone_id     = data.aws_route53_zone.dns_zone.zone_id
}
module "sync-dir" {
  source                = "MarioMoura/syncdir/aws"
  version               = "~> 0.0"
  # The directory where the static code is
  directory             = <LOCAL_DIR>
  bucket                = module.s3-static-website.website_bucket_id
  cache_control_default = "max-age=3600"
  cache_control_by_extension = {
    html = "max-age=7200"
  }
}
```

The next few commands will differ depending on your setup, generally a `terraform init && terraform apply`
enough.

**Warning**: Notice that I left out the backend and provider version configuration. If you need guidance look
[here](https://developer.hashicorp.com/terraform/language/terraform).

Probably something like this:
```terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = <VERSION>
    }
  }
  backend "<TYPE>" {
    "<ARGUMENTS>"
  }
}
```

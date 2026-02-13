# terraform {
#   backend "s3" {
#     bucket = "terraform-state-bucket-alf"
#     key    = "static-web/terraform.tfstate"
#     region = "us-east-1"
#     encrypt = true
#     use_lockfile = true
#   }
# } 


terraform {
  backend "s3" {
    bucket         = "terraform-state-web-alf"
    key            = "static-site/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}


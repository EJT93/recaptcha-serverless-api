terraform {
  backend "s3" {
    bucket                = "gcs-wms-terraform-state"
    key                   = "recaptcha-severless-api.tfstate"
    workspace_key_prefix  = "serverless-api" 
    region                = "us-east-2"
    kms_key_id            = "alias/s3_terraform_key"
  }
}
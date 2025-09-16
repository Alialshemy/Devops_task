locals {
  service_names = {
    s3       = "com.amazonaws.${var.region}.s3"
    sqs      = "com.amazonaws.${var.region}.sqs"
    ecr_api  = "com.amazonaws.${var.region}.ecr.api"
    ecr_dkr  = "com.amazonaws.${var.region}.ecr.dkr"
  }
}

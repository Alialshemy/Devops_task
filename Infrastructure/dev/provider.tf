terraform {


  backend "s3" {
    bucket       = "ali-devopstask"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }

}

provider "aws" {
  region = var.region
}
terraform {
  backend "s3" {
    bucket = "myterraform6weekschallenge"
    key = "challenge-2/dev/terraform.tfstate"
    region = "eu-west-1"
    use_lockfile = true
    encrypt = true
  }
}
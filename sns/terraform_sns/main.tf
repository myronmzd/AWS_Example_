resource "random_string" "bucket_suffix1" {
  length  = 6
  special = false
  upper   = false
}
resource "random_string" "bucket_suffix2" {
  length  = 6
  special = false
  upper   = false
}


module "input" {
  source            = "./modules/input"
  input_bucket_name = "my-input-bucket-${random_string.bucket_suffix1.result}"
}

module "output" {
  source             = "./modules/output"
  output_bucket_name = "my-input-bucket-${random_string.bucket_suffix2.result}"
}

module "compute" {
  source            = "./modules/compute"
  input_bucket_id   = module.input.input_bucket_id
  input_bucket_arn  = module.input.input_bucket_arn
  output_bucket_id  = module.output.output_bucket_id
  output_bucket_arn = module.output.output_bucket_arn
  email_endpoint    = "myronmzd22@gmail.com"
}

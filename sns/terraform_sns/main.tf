module "input" {
  source             = "./modules/input"
  input_bucket_name  = "my-input-bucket"
}

module "output" {
  source             = "./modules/output"
  output_bucket_name = "my-output-bucket"
}

module "compute" {
  source            = "./modules/compute"
  input_bucket_id   = module.input.input_bucket_id
  input_bucket_arn  = module.input.input_bucket_arn
  output_bucket_id  = module.output.output_bucket_id
  output_bucket_arn = module.output.output_bucket_arn
}

# On génère une chaîne aléatoire pour garantir que les noms des buckets soient uniques mondialement
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# 1. Appel du module S3 pour créer le bucket source
module "s3_source" {
  source      = "./modules/s3"
  bucket_name = "${var.project_name}-source-${random_string.suffix.result}"
}

# 2. Appel du module S3 pour créer le bucket de destination
module "s3_dest" {
  source      = "./modules/s3"
  bucket_name = "${var.project_name}-dest-${random_string.suffix.result}"
}

# 3. Appel du module Lambda pour créer la fonction et ses permissions IAM
module "pdf_converter_lambda" {
  source            = "./modules/lambda"
  function_name     = "${var.project_name}-converter"
  source_bucket_arn = module.s3_source.bucket_arn
  dest_bucket_arn   = module.s3_dest.bucket_arn
  source_bucket_id  = module.s3_source.bucket_id
}

# 4. Configuration du déclencheur (Trigger) : Quand on dépose un fichier sur le S3 source, ça lance la Lambda
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = module.s3_source.bucket_id

  lambda_function {
    lambda_function_arn = module.pdf_converter_lambda.lambda_arn
    events              = ["s3:ObjectCreated:*"]
  }

  # On s'assure que Terraform a bien fini de créer les permissions Lambda avant d'activer le déclencheur
  depends_on = [module.pdf_converter_lambda]
}
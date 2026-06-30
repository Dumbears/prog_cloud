# 1. Création du rôle IAM pour la Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# 2. Création de la politique (policy) IAM pour lire/écrire sur S3 et faire des logs
resource "aws_iam_policy" "lambda_policy" {
  name = "${var.function_name}-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${var.source_bucket_arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "${var.dest_bucket_arn}/*"
      }
    ]
  })
}

# 3. Attacher la politique au rôle
resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# 4. Création d'une archive ZIP vide ou basique pour initialiser la Lambda
# (Ansible viendra mettre à jour le vrai code plus tard)
data "archive_file" "dummy_payload" {
  type        = "zip"
  output_path = "${path.module}/dummy_payload.zip"
  
  source {
    content  = "def lambda_handler(event, context):\n    pass"
    filename = "handler.py"
  }
}

# 5. Création de la fonction Lambda
resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.11" # Version demandée dans le sujet
  filename         = data.archive_file.dummy_payload.output_path
  source_code_hash = data.archive_file.dummy_payload.output_base64sha256
  timeout          = 30

  # On demande à Terraform d'ignorer les futures modifications du code source
  # Car c'est Ansible qui va s'en charger !
  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
    ]
  }
}

# 6. Autoriser le bucket S3 source à déclencher cette Lambda
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.source_bucket_arn
}
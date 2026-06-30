output "lambda_arn" {
  description = "L'ARN de la fonction Lambda"
  value       = aws_lambda_function.this.arn
}

output "lambda_function_name" {
  description = "Le nom de la fonction Lambda"
  value       = aws_lambda_function.this.function_name
}
variable "function_name" {
  description = "Nom de la fonction Lambda"
  type        = string
}

variable "source_bucket_arn" {
  description = "ARN du bucket source (pour lui donner le droit de lire)"
  type        = string
}

variable "dest_bucket_arn" {
  description = "ARN du bucket de destination (pour lui donner le droit d'écrire)"
  type        = string
}

variable "source_bucket_id" {
  description = "ID du bucket source (pour autoriser le déclenchement)"
  type        = string
}
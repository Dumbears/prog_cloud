variable "aws_region" {
  description = "Région AWS pour déployer l'infrastructure"
  type        = string
  default     = "eu-west-3" # Région Paris par défaut
}

variable "project_name" {
  description = "Nom du projet utilisé pour nommer les ressources"
  type        = string
  default     = "ynov-iac-2025"
}
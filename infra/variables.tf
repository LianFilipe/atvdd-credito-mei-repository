variable "aiven_api_token" {
  description = "Token de API da Aiven (definir via TF_VAR_aiven_api_token; nunca versionar)"
  type        = string
  sensitive   = true
}

variable "aiven_project" {
  description = "Nome do projeto na Aiven"
  type        = string
  default     = "ucsal-bigdata2"
}

variable "service_name" {
  description = "Nome do serviço PostgreSQL na Aiven"
  type        = string
  default     = "pg-1366b989"
}

variable "cloud_name" {
  description = "Provedor e região onde o serviço roda (DigitalOcean, Nova York)"
  type        = string
  default     = "do-nyc"
}

variable "plan" {
  description = "Plano do serviço (Free Tier)."
  type        = string
  default     = "free-1-1gb"
}

# Versões mínimas do Terraform e do provider da Aiven.
# O bloco "import" usado em main.tf exige Terraform >= 1.6.
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aiven = {
      source  = "aiven/aiven"
      version = ">= 4.0.0, < 5.0.0"
    }
  }
}

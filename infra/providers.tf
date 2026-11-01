# O token NÃO fica escrito aqui. Ele é lido da variável aiven_api_token,
# que deve vir da variável de ambiente TF_VAR_aiven_api_token
# (ou de um terraform.tfvars local, que está no .gitignore).
provider "aiven" {
  api_token = var.aiven_api_token
}

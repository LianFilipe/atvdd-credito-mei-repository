# Dados de conexão NÃO sensíveis. A senha não é exposta como output.
output "pg_host" {
  description = "Host do PostgreSQL"
  value       = aiven_pg.banco_credito_mei.service_host
}

output "pg_port" {
  description = "Porta do PostgreSQL"
  value       = aiven_pg.banco_credito_mei.service_port
}

output "pg_user" {
  description = "Usuário administrador"
  value       = aiven_pg.banco_credito_mei.service_username
}

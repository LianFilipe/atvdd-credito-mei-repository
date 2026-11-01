# ---------------------------------------------------------------------
# Banco PostgreSQL gerenciado na Aiven (Free Tier)
#
# O serviço foi criado inicialmente pelo console da Aiven. O bloco
# "import" abaixo associa esse serviço existente ao código, sem
# recriá-lo e sem apagar os dados já carregados.
# ---------------------------------------------------------------------

import {
  to = aiven_pg.banco_credito_mei
  id = "${var.aiven_project}/${var.service_name}"
}

resource "aiven_pg" "banco_credito_mei" {
  project      = var.aiven_project
  service_name = var.service_name
  cloud_name   = var.cloud_name
  plan         = var.plan

  # Proteção: impede que um "terraform destroy" acidental apague o banco.
  lifecycle {
    prevent_destroy = true
  }
}

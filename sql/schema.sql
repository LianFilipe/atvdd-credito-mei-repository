-- =====================================================================
-- schema.sql
-- Estrutura do banco: Crédito MEI por UF (BCB) x População (IBGE)
-- Banco: PostgreSQL 18 (Aiven) | Schema: public
-- Modelagem: esquema estrela (floco de neve)
--   dim_regiao  <-  dim_uf  <-  fato_credito_mei_anual
--   + view analítica vw_credito_mei_indicadores
--
-- Ordem de criação respeita as dependências (FKs):
--   1. dim_regiao  2. dim_uf  3. fato_credito_mei_anual  4. índice  5. view
-- O script é idempotente: pode ser executado mais de uma vez.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Dimensão Região (5 regiões do Brasil)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dim_regiao (
    id_regiao  smallint              NOT NULL,
    nome       character varying(20) NOT NULL,

    CONSTRAINT dim_regiao_pkey     PRIMARY KEY (id_regiao),
    CONSTRAINT dim_regiao_nome_key UNIQUE (nome)
);


-- ---------------------------------------------------------------------
-- 2. Dimensão UF (27 unidades federativas)
--    Chave = código IBGE da UF, o que permite cruzar com bases do IBGE
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS dim_uf (
    codigo_ibge  smallint              NOT NULL,
    sigla        character(2)          NOT NULL,
    nome         character varying(40) NOT NULL,
    id_regiao    smallint              NOT NULL,

    CONSTRAINT dim_uf_pkey      PRIMARY KEY (codigo_ibge),
    CONSTRAINT dim_uf_sigla_key UNIQUE (sigla),
    CONSTRAINT dim_uf_id_regiao_fkey
        FOREIGN KEY (id_regiao) REFERENCES dim_regiao (id_regiao)
        ON UPDATE CASCADE ON DELETE RESTRICT
);


-- ---------------------------------------------------------------------
-- 3. Fato: crédito MEI anual por UF
--    Granularidade: 1 linha por UF por ano (2020-2025 => 27 x 6 = 162)
--    Valores monetários em numeric(20,2) (decimal exato, sem erro de
--    arredondamento de ponto flutuante).
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fato_credito_mei_anual (
    codigo_uf                      smallint      NOT NULL,
    ano                            smallint      NOT NULL,
    data_base                      date          NOT NULL,
    tem_dado_bcb                   boolean       NOT NULL,
    numero_operacoes               bigint,
    numero_operacoes_indisponivel  boolean       NOT NULL,
    carteira_ativa                 numeric(20,2),
    carteira_inadimplencia         numeric(20,2),
    ativo_problematico             numeric(20,2),
    populacao_ibge                 bigint        NOT NULL,

    -- Chave composta: impede duplicidade de UF no mesmo ano
    CONSTRAINT fato_credito_mei_anual_pkey PRIMARY KEY (codigo_uf, ano),

    CONSTRAINT fato_credito_mei_anual_codigo_uf_fkey
        FOREIGN KEY (codigo_uf) REFERENCES dim_uf (codigo_ibge)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    -- Recorte temporal do projeto
    CONSTRAINT fato_credito_mei_anual_ano_check
        CHECK (ano >= 2020 AND ano <= 2025),

    -- Data-base padronizada: sempre 31/12 do ano de referência
    CONSTRAINT fato_credito_mei_anual_check
        CHECK (data_base = make_date(ano::integer, 12, 31)),

    -- Coerência da flag: se indisponível, a contagem deve ser nula
    CONSTRAINT fato_credito_mei_anual_check1
        CHECK (NOT numero_operacoes_indisponivel OR numero_operacoes IS NULL),

    -- Valores não podem ser negativos (nulos são permitidos)
    CONSTRAINT fato_credito_mei_anual_numero_operacoes_check
        CHECK (numero_operacoes IS NULL OR numero_operacoes >= 0),
    CONSTRAINT fato_credito_mei_anual_carteira_ativa_check
        CHECK (carteira_ativa IS NULL OR carteira_ativa >= 0),
    CONSTRAINT fato_credito_mei_anual_carteira_inadimplencia_check
        CHECK (carteira_inadimplencia IS NULL OR carteira_inadimplencia >= 0),
    CONSTRAINT fato_credito_mei_anual_ativo_problematico_check
        CHECK (ativo_problematico IS NULL OR ativo_problematico >= 0),

    -- População precisa ser positiva (usada como divisor na view)
    CONSTRAINT fato_credito_mei_anual_populacao_ibge_check
        CHECK (populacao_ibge > 0)
);


-- ---------------------------------------------------------------------
-- 4. Índice para consultas filtradas por ano
-- ---------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_fato_credito_mei_anual_ano
    ON fato_credito_mei_anual USING btree (ano);


-- ---------------------------------------------------------------------
-- 5. View analítica com indicadores calculados
--    - credito_por_habitante: carteira ativa / população
--    - taxa_inadimplencia_percentual: 100 * inadimplência / carteira ativa
--    NULLIF evita erro de divisão por zero.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_credito_mei_indicadores AS
SELECT
    f.codigo_uf,
    u.sigla  AS uf,
    u.nome   AS nome_uf,
    r.nome   AS regiao,
    f.ano,
    f.data_base,
    f.tem_dado_bcb,
    f.numero_operacoes,
    f.numero_operacoes_indisponivel,
    f.carteira_ativa,
    f.carteira_inadimplencia,
    f.ativo_problematico,
    f.populacao_ibge,
    round(f.carteira_ativa / NULLIF(f.populacao_ibge, 0)::numeric, 4)
        AS credito_por_habitante,
    round(100::numeric * f.carteira_inadimplencia / NULLIF(f.carteira_ativa, 0::numeric), 4)
        AS taxa_inadimplencia_percentual
FROM fato_credito_mei_anual f
JOIN dim_uf     u ON u.codigo_ibge = f.codigo_uf
JOIN dim_regiao r ON r.id_regiao   = u.id_regiao;

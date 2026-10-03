-- DDL do projeto DimDim (SQL Server / Azure SQL Database)
-- Tabela master: cliente  |  Tabela detail: transacao (FK para cliente)
-- O script e idempotente: so cria se a tabela ainda nao existir.

IF OBJECT_ID('dbo.cliente', 'U') IS NULL
CREATE TABLE dbo.cliente (
    id     BIGINT        IDENTITY(1,1) NOT NULL,
    nome   VARCHAR(100)  NOT NULL,
    email  VARCHAR(150)  NOT NULL,
    CONSTRAINT pk_cliente PRIMARY KEY (id),
    CONSTRAINT uq_cliente_email UNIQUE (email)
);

IF OBJECT_ID('dbo.transacao', 'U') IS NULL
CREATE TABLE dbo.transacao (
    id          BIGINT         IDENTITY(1,1) NOT NULL,
    descricao   VARCHAR(200)   NOT NULL,
    valor       DECIMAL(12,2)  NOT NULL,
    data_hora   DATETIME2      NOT NULL,
    cliente_id  BIGINT         NOT NULL,
    CONSTRAINT pk_transacao PRIMARY KEY (id),
    CONSTRAINT fk_transacao_cliente FOREIGN KEY (cliente_id) REFERENCES dbo.cliente (id)
);

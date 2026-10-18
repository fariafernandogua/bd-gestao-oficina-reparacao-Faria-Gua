CREATE DATABASE oficina_reparacoes
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE oficina_reparacoes;

-- ---------------------------------------------------------------------
-- 1. CRIAÇÃO DAS TABELAS (ordem: primeiro as tabelas referenciadas)
-- ---------------------------------------------------------------------

CREATE TABLE utilizadores (
  id_utilizador      INT AUTO_INCREMENT PRIMARY KEY,
  nome_utilizador    VARCHAR(50)  NOT NULL UNIQUE,
  email              VARCHAR(100) NOT NULL UNIQUE,
  palavra_passe_hash VARCHAR(255) NOT NULL,
  perfil             ENUM('administrador','tecnico','cliente') NOT NULL,
  ativo              TINYINT(1)   NOT NULL DEFAULT 1,
  data_criacao       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT ck_utilizadores_ativo CHECK (ativo IN (0,1))
) ENGINE=InnoDB;

CREATE TABLE clientes (
  id_cliente     INT AUTO_INCREMENT PRIMARY KEY,
  id_utilizador  INT NULL UNIQUE,
  nome           VARCHAR(100) NOT NULL,
  telefone       VARCHAR(20)  NOT NULL,
  email          VARCHAR(100) NULL UNIQUE,
  endereco       VARCHAR(150) NULL,
  data_registo   DATE NOT NULL DEFAULT (CURRENT_DATE),
  CONSTRAINT fk_clientes_utilizador FOREIGN KEY (id_utilizador)
    REFERENCES utilizadores (id_utilizador)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE tecnicos (
  id_tecnico     INT AUTO_INCREMENT PRIMARY KEY,
  id_utilizador  INT NOT NULL UNIQUE,
  nome           VARCHAR(100) NOT NULL,
  especialidade  VARCHAR(60)  NOT NULL,
  telefone       VARCHAR(20)  NOT NULL,
  CONSTRAINT fk_tecnicos_utilizador FOREIGN KEY (id_utilizador)
    REFERENCES utilizadores (id_utilizador)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE equipamentos (
  id_equipamento INT AUTO_INCREMENT PRIMARY KEY,
  id_cliente     INT NOT NULL,
  tipo           ENUM('Portátil','Computador de secretária','All-in-One',
                      'Monitor','Impressora','Servidor','Tablet') NOT NULL,
  marca          VARCHAR(40) NOT NULL,
  modelo         VARCHAR(60) NOT NULL,
  numero_serie   VARCHAR(40) NOT NULL UNIQUE,
  CONSTRAINT fk_equipamentos_cliente FOREIGN KEY (id_cliente)
    REFERENCES clientes (id_cliente)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE servicos (
  id_servico  INT AUTO_INCREMENT PRIMARY KEY,
  nome        VARCHAR(80)  NOT NULL UNIQUE,
  descricao   VARCHAR(200) NULL,
  preco_base  DECIMAL(10,2) NOT NULL,
  CONSTRAINT ck_servicos_preco CHECK (preco_base > 0)
) ENGINE=InnoDB;

CREATE TABLE pecas (
  id_peca         INT AUTO_INCREMENT PRIMARY KEY,
  nome            VARCHAR(80) NOT NULL UNIQUE,
  marca           VARCHAR(40) NOT NULL,
  preco_unitario  DECIMAL(10,2) NOT NULL,
  stock           INT NOT NULL DEFAULT 0,
  stock_minimo    INT NOT NULL DEFAULT 5,
  CONSTRAINT ck_pecas_preco  CHECK (preco_unitario > 0),
  CONSTRAINT ck_pecas_stock  CHECK (stock >= 0),
  CONSTRAINT ck_pecas_minimo CHECK (stock_minimo >= 0)
) ENGINE=InnoDB;

CREATE TABLE reparacoes (
  id_reparacao      INT AUTO_INCREMENT PRIMARY KEY,
  id_equipamento    INT NOT NULL,
  id_tecnico        INT NOT NULL,
  problema_relatado TEXT NOT NULL,
  diagnostico       TEXT NULL,
  estado            ENUM('Recebida','Em diagnóstico','Em reparação',
                         'Concluída','Entregue') NOT NULL DEFAULT 'Recebida',
  custo_estimado    DECIMAL(10,2) NOT NULL DEFAULT 0,
  data_entrada      DATE NOT NULL,
  data_prevista     DATE NOT NULL,
  data_conclusao    DATE NULL,
  CONSTRAINT fk_reparacoes_equipamento FOREIGN KEY (id_equipamento)
    REFERENCES equipamentos (id_equipamento)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_reparacoes_tecnico FOREIGN KEY (id_tecnico)
    REFERENCES tecnicos (id_tecnico)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_reparacoes_custo  CHECK (custo_estimado >= 0),
  CONSTRAINT ck_reparacoes_prevista CHECK (data_prevista >= data_entrada),
  CONSTRAINT ck_reparacoes_conclusao CHECK
    (data_conclusao IS NULL OR data_conclusao >= data_entrada)
) ENGINE=InnoDB;

-- Tabela de associação (muitos-para-muitos reparações <-> serviços)
CREATE TABLE servicos_reparacao (
  id_reparacao    INT NOT NULL,
  id_servico      INT NOT NULL,
  preco_aplicado  DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (id_reparacao, id_servico),
  CONSTRAINT fk_sr_reparacao FOREIGN KEY (id_reparacao)
    REFERENCES reparacoes (id_reparacao)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_sr_servico FOREIGN KEY (id_servico)
    REFERENCES servicos (id_servico)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_sr_preco CHECK (preco_aplicado >= 0)
) ENGINE=InnoDB;

-- Tabela de associação (muitos-para-muitos reparações <-> peças)
CREATE TABLE pecas_reparacao (
  id_reparacao    INT NOT NULL,
  id_peca         INT NOT NULL,
  quantidade      INT NOT NULL,
  preco_unitario  DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (id_reparacao, id_peca),
  CONSTRAINT fk_pr_reparacao FOREIGN KEY (id_reparacao)
    REFERENCES reparacoes (id_reparacao)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_pr_peca FOREIGN KEY (id_peca)
    REFERENCES pecas (id_peca)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_pr_quantidade CHECK (quantidade > 0),
  CONSTRAINT ck_pr_preco CHECK (preco_unitario > 0)
) ENGINE=InnoDB;

-- ENTIDADE FRACA: um pagamento só existe associado a uma reparação.
-- A chave primária é composta: (id_reparacao, num_pagamento), onde
-- num_pagamento é a chave parcial (1.º, 2.º pagamento... da reparação).
CREATE TABLE pagamentos (
  id_reparacao    INT NOT NULL,
  num_pagamento   INT NOT NULL,
  data_pagamento  DATE NOT NULL,
  valor           DECIMAL(10,2) NOT NULL,
  metodo          ENUM('Numerário','M-Pesa','e-Mola',
                       'Transferência bancária','Cartão') NOT NULL,
  PRIMARY KEY (id_reparacao, num_pagamento),
  CONSTRAINT fk_pagamentos_reparacao FOREIGN KEY (id_reparacao)
    REFERENCES reparacoes (id_reparacao)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT ck_pagamentos_valor CHECK (valor > 0),
  CONSTRAINT ck_pagamentos_num   CHECK (num_pagamento >= 1)
) ENGINE=InnoDB;

-- Índices adicionais para pesquisas frequentes
CREATE INDEX idx_reparacoes_estado   ON reparacoes (estado);
CREATE INDEX idx_reparacoes_tecnico  ON reparacoes (id_tecnico);
CREATE INDEX idx_equipamentos_cliente ON equipamentos (id_cliente);
CREATE INDEX idx_pagamentos_data     ON pagamentos (data_pagamento);
CREATE INDEX idx_pecas_stock         ON pecas (stock);

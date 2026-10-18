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

INSERT INTO utilizadores (id_utilizador, nome_utilizador, email, palavra_passe_hash, perfil, ativo, data_criacao) VALUES
(1, 'admin.geral', 'admin.geral@oficina.co.mz', SHA2('Demo@2026',256), 'administrador', 1, '2026-07-01 08:00:00'),
(2, 'admin.oficina', 'admin.oficina@oficina.co.mz', SHA2('Demo@2026',256), 'administrador', 1, '2026-07-01 08:05:00'),
(3, 'aderito.bande', 'aderito.bande@oficina.co.mz', SHA2('Demo@2026',256), 'tecnico', 1, '2026-07-02 09:00:00'),
(4, 'bernardo.cuamba', 'bernardo.cuamba@oficina.co.mz', SHA2('Demo@2026',256), 'tecnico', 1, '2026-07-02 09:01:00'),
(5, 'candida.mussa', 'candida.mussa@oficina.co.mz', SHA2('Demo@2026',256), 'tecnico', 1, '2026-07-02 09:02:00'),
(6, 'daniel.muchanga', 'daniel.muchanga@oficina.co.mz', SHA2('Demo@2026',256), 'tecnico', 1, '2026-07-02 09:03:00'),
(7, 'esperanca.langa', 'esperanca.langa@oficina.co.mz', SHA2('Demo@2026',256), 'tecnico', 1, '2026-07-02 09:04:00'),
(8, 'felisberto.nhampossa', 'felisberto.nhampossa@oficina.co.mz', SHA2('Demo@2026',256), 'tecnico', 1, '2026-07-02 09:05:00'),
(9, 'gaspar.uamusse', 'gaspar.uamusse@oficina.co.mz', SHA2('Demo@2026',256), 'tecnico', 1, '2026-07-02 09:06:00'),
(10, 'hortencia.mazive', 'hortencia.mazive@oficina.co.mz', SHA2('Demo@2026',256), 'tecnico', 1, '2026-07-02 09:07:00'),
(11, 'inacio.zimba', 'inacio.zimba@oficina.co.mz', SHA2('Demo@2026',256), 'tecnico', 1, '2026-07-02 09:08:00'),
(12, 'jacinta.mate', 'jacinta.mate@oficina.co.mz', SHA2('Demo@2026',256), 'tecnico', 1, '2026-07-02 09:09:00'),
(13, 'kelvin.nhanombe', 'kelvin.nhanombe@oficina.co.mz', SHA2('Demo@2026',256), 'tecnico', 1, '2026-07-02 09:10:00'),
(14, 'lurdes.chongo', 'lurdes.chongo@oficina.co.mz', SHA2('Demo@2026',256), 'tecnico', 1, '2026-07-02 09:11:00'),
(15, 'mario.mutisse', 'mario.mutisse@oficina.co.mz', SHA2('Demo@2026',256), 'tecnico', 1, '2026-07-02 09:12:00'),
(16, 'noemia.vilanculos', 'noemia.vilanculos@oficina.co.mz', SHA2('Demo@2026',256), 'tecnico', 1, '2026-07-02 09:13:00'),
(17, 'osvaldo.tchamo', 'osvaldo.tchamo@oficina.co.mz', SHA2('Demo@2026',256), 'tecnico', 1, '2026-07-02 09:14:00'),
(18, 'palmira.bambo', 'palmira.bambo@oficina.co.mz', SHA2('Demo@2026',256), 'tecnico', 1, '2026-07-02 09:15:00'),
(19, 'quirino.muianga', 'quirino.muianga@oficina.co.mz', SHA2('Demo@2026',256), 'tecnico', 1, '2026-07-02 09:16:00'),
(20, 'rosa.mavila', 'rosa.mavila@oficina.co.mz', SHA2('Demo@2026',256), 'tecnico', 1, '2026-07-02 09:17:00'),
(21, 'sergio.machava', 'sergio.machava@oficina.co.mz', SHA2('Demo@2026',256), 'tecnico', 1, '2026-07-02 09:18:00'),
(22, 'telma.fumo', 'telma.fumo@oficina.co.mz', SHA2('Demo@2026',256), 'tecnico', 1, '2026-07-02 09:19:00'),
(23, 'abdul.rashid.momade', 'abdulrashidmomade@gmail.com', SHA2('Demo@2026',256), 'cliente', 1, '2026-07-03 10:00:00'),
(24, 'beatriz.armando.chiziane', 'beatrizarmandochiziane@gmail.com', SHA2('Demo@2026',256), 'cliente', 1, '2026-07-04 10:00:00'),
(25, 'carlos.alberto.mucavele', 'carlosalbertomucavele@gmail.com', SHA2('Demo@2026',256), 'cliente', 1, '2026-07-05 10:00:00'),
(26, 'dulce.maria.nhantumbo', 'dulcemarianhantumbo@gmail.com', SHA2('Demo@2026',256), 'cliente', 1, '2026-07-06 10:00:00'),
(27, 'eduardo.samuel.macuacua', 'eduardosamuelmacuacua@gmail.com', SHA2('Demo@2026',256), 'cliente', 1, '2026-07-07 10:00:00'),
(28, 'fatima.issufo.bila', 'fatimaissufobila@gmail.com', SHA2('Demo@2026',256), 'cliente', 1, '2026-07-08 10:00:00'),
(29, 'gilberto.tomas.cossa', 'gilbertotomascossa@gmail.com', SHA2('Demo@2026',256), 'cliente', 1, '2026-07-09 10:00:00'),
(30, 'helena.jose.matsinhe', 'helenajosematsinhe@gmail.com', SHA2('Demo@2026',256), 'cliente', 1, '2026-07-10 10:00:00'),
(31, 'ismael.julio.tembe', 'ismaeljuliotembe@gmail.com', SHA2('Demo@2026',256), 'cliente', 1, '2026-07-11 10:00:00'),
(32, 'joana.paulo.mondlane', 'joanapaulomondlane@gmail.com', SHA2('Demo@2026',256), 'cliente', 1, '2026-07-12 10:00:00'),
(33, 'katia.domingos.sitoe', 'katiadomingossitoe@gmail.com', SHA2('Demo@2026',256), 'cliente', 1, '2026-07-13 10:00:00'),
(34, 'luis.fernando.chivambo', 'luisfernandochivambo@gmail.com', SHA2('Demo@2026',256), 'cliente', 1, '2026-07-14 10:00:00'),
(35, 'mariana.pedro.zandamela', 'marianapedrozandamela@gmail.com', SHA2('Demo@2026',256), 'cliente', 1, '2026-07-15 10:00:00'),
(36, 'narciso.augusto.maculuve', 'narcisoaugustomaculuve@gmail.com', SHA2('Demo@2026',256), 'cliente', 1, '2026-07-16 10:00:00'),
(37, 'olga.raimundo.cumbe', 'olgaraimundocumbe@gmail.com', SHA2('Demo@2026',256), 'cliente', 1, '2026-07-17 10:00:00'),
(38, 'paulo.jorge.mabunda', 'paulojorgemabunda@gmail.com', SHA2('Demo@2026',256), 'cliente', 1, '2026-07-18 10:00:00'),
(39, 'quiteria.amade.saide', 'quiteriaamadesaide@gmail.com', SHA2('Demo@2026',256), 'cliente', 1, '2026-07-19 10:00:00');

INSERT INTO clientes (id_cliente, id_utilizador, nome, telefone, email, endereco, data_registo) VALUES
(1, 23, 'Abdul Rashid Momade', '84 555 0100', 'abdulrashidmomade@gmail.com', 'Bairro Ponta-Gêa, Beira, Sofala', '2026-07-03'),
(2, 24, 'Beatriz Armando Chiziane', '84 555 0101', 'beatrizarmandochiziane@gmail.com', 'Bairro Macúti, Beira, Sofala', '2026-07-04'),
(3, 25, 'Carlos Alberto Mucavele', '84 555 0102', 'carlosalbertomucavele@gmail.com', 'Bairro Munhava, Beira, Sofala', '2026-07-05'),
(4, 26, 'Dulce Maria Nhantumbo', '84 555 0103', 'dulcemarianhantumbo@gmail.com', 'Bairro Matacuane, Beira, Sofala', '2026-07-06'),
(5, 27, 'Eduardo Samuel Macuácua', '84 555 0104', 'eduardosamuelmacuacua@gmail.com', 'Bairro Chaimite, Beira, Sofala', '2026-07-07'),
(6, 28, 'Fátima Issufo Bila', '84 555 0105', 'fatimaissufobila@gmail.com', 'Bairro Manga, Beira, Sofala', '2026-07-08'),
(7, 29, 'Gilberto Tomás Cossa', '84 555 0106', 'gilbertotomascossa@gmail.com', 'Bairro Esturro, Beira, Sofala', '2026-07-09'),
(8, 30, 'Helena José Matsinhe', '84 555 0107', 'helenajosematsinhe@gmail.com', 'Bairro Chipangara, Beira, Sofala', '2026-07-10'),
(9, 31, 'Ismael Júlio Tembe', '84 555 0108', 'ismaeljuliotembe@gmail.com', 'Bairro Vaz, Beira, Sofala', '2026-07-11'),
(10, 32, 'Joana Paulo Mondlane', '84 555 0109', 'joanapaulomondlane@gmail.com', 'Bairro Inhamízua, Beira, Sofala', '2026-07-12'),
(11, 33, 'Kátia Domingos Sitoe', '84 555 0110', 'katiadomingossitoe@gmail.com', 'Bairro Nhaconjo, Beira, Sofala', '2026-07-13'),
(12, 34, 'Luís Fernando Chivambo', '84 555 0111', 'luisfernandochivambo@gmail.com', 'Bairro Alto da Manga, Beira, Sofala', '2026-07-14'),
(13, 35, 'Mariana Pedro Zandamela', '84 555 0112', 'marianapedrozandamela@gmail.com', 'Bairro Ponta-Gêa, Beira, Sofala', '2026-07-15'),
(14, 36, 'Narciso Augusto Maculuve', '84 555 0113', 'narcisoaugustomaculuve@gmail.com', 'Bairro Macúti, Beira, Sofala', '2026-07-16'),
(15, 37, 'Olga Raimundo Cumbe', '84 555 0114', 'olgaraimundocumbe@gmail.com', 'Bairro Munhava, Beira, Sofala', '2026-07-17'),
(16, 38, 'Paulo Jorge Mabunda', '84 555 0115', 'paulojorgemabunda@gmail.com', 'Bairro Matacuane, Beira, Sofala', '2026-07-18'),
(17, 39, 'Quitéria Amade Saide', '84 555 0116', 'quiteriaamadesaide@gmail.com', 'Bairro Chaimite, Beira, Sofala', '2026-07-19'),
(18, NULL, 'Rui Manuel Guambe', '84 555 0117', 'ruimanuelguambe@gmail.com', 'Bairro Manga, Beira, Sofala', '2026-07-20'),
(19, NULL, 'Sónia Alberto Nhaca', '84 555 0118', 'soniaalbertonhaca@gmail.com', 'Bairro Esturro, Beira, Sofala', '2026-07-21'),
(20, NULL, 'Tiago Elias Mavie', '84 555 0119', 'tiagoeliasmavie@gmail.com', 'Bairro Chipangara, Beira, Sofala', '2026-07-22'),
(21, NULL, 'Úrsula Daniel Chaúque', '84 555 0120', 'ursuladanielchauque@gmail.com', 'Bairro Vaz, Beira, Sofala', '2026-07-03');

INSERT INTO tecnicos (id_tecnico, id_utilizador, nome, especialidade, telefone) VALUES
(1, 3, 'Adérito Bande', 'Hardware', '82 777 0200'),
(2, 4, 'Bernardo Cuamba', 'Software', '82 777 0201'),
(3, 5, 'Cândida Mussa', 'Portáteis', '82 777 0202'),
(4, 6, 'Daniel Muchanga', 'Redes', '82 777 0203'),
(5, 7, 'Esperança Langa', 'Impressoras', '82 777 0204'),
(6, 8, 'Felisberto Nhampossa', 'Electrónica', '82 777 0205'),
(7, 9, 'Gaspar Uamusse', 'Monitores', '82 777 0206'),
(8, 10, 'Hortência Mazive', 'Software', '82 777 0207'),
(9, 11, 'Inácio Zimba', 'Hardware', '82 777 0208'),
(10, 12, 'Jacinta Mate', 'Portáteis', '82 777 0209'),
(11, 13, 'Kelvin Nhanombe', 'Recuperação de dados', '82 777 0210'),
(12, 14, 'Lurdes Chongo', 'Impressoras', '82 777 0211'),
(13, 15, 'Mário Mutisse', 'Hardware', '82 777 0212'),
(14, 16, 'Noémia Vilanculos', 'Redes', '82 777 0213'),
(15, 17, 'Osvaldo Tchamo', 'Electrónica', '82 777 0214'),
(16, 18, 'Palmira Bambo', 'Software', '82 777 0215'),
(17, 19, 'Quirino Muianga', 'Monitores', '82 777 0216'),
(18, 20, 'Rosa Mavila', 'Portáteis', '82 777 0217'),
(19, 21, 'Sérgio Machava', 'Hardware', '82 777 0218'),
(20, 22, 'Telma Fumo', 'Recuperação de dados', '82 777 0219');

INSERT INTO equipamentos (id_equipamento, id_cliente, tipo, marca, modelo, numero_serie) VALUES
(1, 1, 'Portátil', 'HP', '15-dw3000', 'SN-HP15-0001'),
(2, 2, 'Portátil', 'Dell', 'Inspiron 3511', 'SN-DEL3511-0002'),
(3, 3, 'Computador de secretária', 'Lenovo', 'ThinkCentre M70', 'SN-LEN-M70-0003'),
(4, 4, 'Portátil', 'Acer', 'Aspire 5', 'SN-ACE-A5-0004'),
(5, 5, 'Impressora', 'Epson', 'L3150', 'SN-EPS-L3150-0005'),
(6, 6, 'Portátil', 'Asus', 'VivoBook 15', 'SN-ASU-VB15-0006'),
(7, 7, 'Monitor', 'Samsung', 'S24', 'SN-SAM-S24-0007'),
(8, 8, 'Computador de secretária', 'HP', 'ProDesk 400', 'SN-HP-PD400-0008'),
(9, 9, 'Portátil', 'Lenovo', 'IdeaPad 3', 'SN-LEN-IP3-0009'),
(10, 10, 'Tablet', 'Samsung', 'Galaxy Tab A8', 'SN-SAM-TABA8-0010'),
(11, 11, 'Portátil', 'Toshiba', 'Satellite C55', 'SN-TOS-C55-0011'),
(12, 12, 'Impressora', 'HP', 'LaserJet Pro M15w', 'SN-HP-M15W-0012'),
(13, 13, 'Computador de secretária', 'Dell', 'OptiPlex 3080', 'SN-DEL-OP3080-0013'),
(14, 14, 'Portátil', 'MSI', 'GF63', 'SN-MSI-GF63-0014'),
(15, 15, 'Servidor', 'Dell', 'PowerEdge T140', 'SN-DEL-T140-0015'),
(16, 16, 'Portátil', 'HP', '250 G8', 'SN-HP-250G8-0016'),
(17, 17, 'Monitor', 'LG', '24MK430H', 'SN-LG-24MK-0017'),
(18, 1, 'Portátil', 'Dell', 'Latitude 5410', 'SN-DEL-L5410-0018'),
(19, 3, 'All-in-One', 'HP', '24-df0000', 'SN-HP-AIO24-0019'),
(20, 9, 'Portátil', 'Acer', 'Nitro 5', 'SN-ACE-N5-0020');

INSERT INTO servicos (id_servico, nome, descricao, preco_base) VALUES
(1, 'Diagnóstico geral', 'Avaliação inicial do equipamento e identificação da avaria', 500.00),
(2, 'Formatação e instalação do Windows', 'Instalação limpa do sistema operativo e controladores', 1200.00),
(3, 'Remoção de vírus e malware', 'Limpeza de software malicioso e recuperação do sistema', 800.00),
(4, 'Limpeza interna e pasta térmica', 'Limpeza de pó e substituição da pasta térmica', 700.00),
(5, 'Substituição de disco rígido ou SSD', 'Mão de obra para trocar e clonar o disco', 600.00),
(6, 'Substituição de memória RAM', 'Mão de obra para trocar ou adicionar memória', 400.00),
(7, 'Substituição de ecrã', 'Mão de obra para trocar o ecrã ou painel', 1500.00),
(8, 'Substituição de teclado', 'Mão de obra para trocar o teclado', 600.00),
(9, 'Substituição de bateria', 'Mão de obra para trocar a bateria', 450.00),
(10, 'Substituição de fonte de alimentação', 'Mão de obra para trocar a fonte', 650.00),
(11, 'Reparação de placa-mãe', 'Reparação ao nível de componentes da placa-mãe', 3500.00),
(12, 'Recuperação de dados', 'Recuperação de ficheiros de discos avariados', 2500.00),
(13, 'Instalação de Microsoft Office', 'Instalação e configuração do pacote Office', 500.00),
(14, 'Configuração de rede e Wi-Fi', 'Configuração de ligações de rede e router', 600.00),
(15, 'Limpeza de cabeça de impressão', 'Desobstrução e limpeza da cabeça de impressão', 700.00),
(16, 'Substituição de ventoinha', 'Mão de obra para trocar a ventoinha', 550.00),
(17, 'Instalação de antivírus', 'Instalação e configuração de antivírus', 300.00),
(18, 'Substituição de dobradiças', 'Reparação das dobradiças do portátil', 800.00),
(19, 'Actualização de BIOS', 'Actualização do firmware da placa-mãe', 400.00),
(20, 'Substituição de cabo ou conector', 'Troca de cabos e conectores avariados', 350.00);

INSERT INTO pecas (id_peca, nome, marca, preco_unitario, stock, stock_minimo) VALUES
(1, 'Fonte ATX 500W', 'Corsair', 2800.00, 8, 3),
(2, 'Memória RAM DDR4 8GB', 'Kingston', 2400.00, 15, 5),
(3, 'Memória RAM DDR4 4GB', 'Kingston', 1500.00, 4, 5),
(4, 'SSD 240GB SATA', 'Kingston', 2500.00, 10, 4),
(5, 'SSD 480GB SATA', 'Crucial', 3800.00, 6, 4),
(6, 'Disco rígido 1TB 2.5 polegadas', 'Seagate', 3200.00, 3, 4),
(7, 'Bateria para portátil HP 15', 'HP', 3500.00, 5, 3),
(8, 'Teclado para portátil Dell Inspiron', 'Dell', 1800.00, 2, 3),
(9, 'Ecrã LCD 15.6 polegadas 30 pinos', 'LG', 6500.00, 4, 2),
(10, 'Ventoinha para portátil', 'Foxconn', 650.00, 12, 5),
(11, 'Pasta térmica 4g', 'Arctic', 350.00, 25, 10),
(12, 'Cabo HDMI 1,5m', 'Ugreen', 300.00, 18, 6),
(13, 'Cabo SATA', 'Ugreen', 150.00, 30, 10),
(14, 'Dobradiças para portátil Acer', 'Acer', 1200.00, 3, 2),
(15, 'Cartucho de tinta Epson preto', 'Epson', 650.00, 14, 6),
(16, 'Cabeça de impressão Epson L3150', 'Epson', 4800.00, 2, 2),
(17, 'Rolos de tracção para impressora HP', 'HP', 1800.00, 5, 2),
(18, 'Placa de rede PCI-E Gigabit', 'TP-Link', 900.00, 7, 3),
(19, 'Vidro táctil Samsung Tab A8', 'Samsung', 4200.00, 1, 2),
(20, 'Barra LED para monitor 24 polegadas', 'Samsung', 1600.00, 6, 3);

INSERT INTO reparacoes (id_reparacao, id_equipamento, id_tecnico, problema_relatado, diagnostico, estado, custo_estimado, data_entrada, data_prevista, data_conclusao) VALUES
(1, 1, 1, 'Não liga, sem sinal de energia', 'Fonte de alimentação avariada', 'Entregue', 3950.00, '2026-08-03', '2026-08-07', '2026-08-06'),
(2, 2, 2, 'Lentidão extrema e anúncios no ecrã', 'Malware e sistema degradado', 'Entregue', 4200.00, '2026-08-05', '2026-08-10', '2026-08-09'),
(3, 3, 3, 'Ecrã preto ao iniciar', 'Memória RAM defeituosa', 'Entregue', 3300.00, '2026-08-10', '2026-08-14', '2026-08-13'),
(4, 4, 4, 'Bateria não carrega', 'Bateria degradada', 'Entregue', 4450.00, '2026-08-12', '2026-08-18', '2026-08-17'),
(5, 5, 5, 'Impressão com riscas', 'Cabeça de impressão obstruída', 'Entregue', 5500.00, '2026-08-20', '2026-08-25', '2026-08-24'),
(6, 6, 6, 'Várias teclas deixaram de funcionar', 'Teclado danificado por líquido', 'Entregue', 2400.00, '2026-08-24', '2026-08-30', '2026-08-29'),
(7, 7, 7, 'Monitor liga mas sem imagem', 'Barra de retroiluminação avariada', 'Concluída', 3100.00, '2026-09-02', '2026-09-09', '2026-09-08'),
(8, 8, 8, 'Windows não arranca', 'Sistema operativo corrompido', 'Entregue', 1500.00, '2026-09-03', '2026-09-08', '2026-09-07'),
(9, 9, 9, 'Desliga sozinho por sobreaquecimento', 'Ventoinha com pó e pasta térmica seca', 'Entregue', 1700.00, '2026-09-07', '2026-09-12', '2026-09-11'),
(10, 10, 10, 'Vidro do ecrã partido', 'Vidro táctil partido', 'Concluída', 5700.00, '2026-09-10', '2026-09-20', '2026-09-18'),
(11, 11, 11, 'Disco faz ruídos e bloqueia', 'Disco rígido em fim de vida', 'Em reparação', 4300.00, '2026-10-09', '2026-10-20', NULL),
(12, 12, 12, 'Papel encrava constantemente', 'Rolos de tracção gastos', 'Em reparação', 2650.00, '2026-10-09', '2026-10-20', NULL),
(13, 13, 13, 'Reinicia sozinho sem aviso', 'Fonte de alimentação instável', 'Em reparação', 4300.00, '2026-10-10', '2026-10-21', NULL),
(14, 14, 14, 'Não reconhece o disco SSD', NULL, 'Em diagnóstico', 3500.00, '2026-10-13', '2026-10-22', NULL),
(15, 15, 15, 'Servidor sem acesso à rede', NULL, 'Em diagnóstico', 2500.00, '2026-10-14', '2026-10-23', NULL),
(16, 16, 16, 'Ecrã com linhas horizontais', NULL, 'Recebida', 8500.00, '2026-10-16', '2026-10-25', NULL),
(17, 17, 17, 'Monitor com imagem a cintilar', NULL, 'Recebida', 2500.00, '2026-10-16', '2026-10-24', NULL),
(18, 18, 18, 'Instalação de sistema e programas', 'Instalação limpa do Windows e do Office', 'Entregue', 1700.00, '2026-09-15', '2026-09-17', '2026-09-16'),
(19, 19, 19, 'Ventoinha ruidosa e lentidão', 'Pó acumulado e pouca memória RAM', 'Concluída', 4450.00, '2026-09-25', '2026-10-02', '2026-10-01'),
(20, 20, 20, 'Ecrã com pixéis mortos', 'Painel LCD com defeito', 'Em reparação', 8500.00, '2026-10-12', '2026-10-26', NULL),
(21, 1, 1, 'Dobradiça partida', 'Dobradiças partidas', 'Em reparação', 2000.00, '2026-10-11', '2026-10-19', NULL),
(22, 3, 3, 'Computador não lê o disco', 'Cabo SATA solto', 'Entregue', 500.00, '2026-09-28', '2026-09-30', '2026-09-30'),
(23, 5, 5, 'Impressora não reconhece a tinta', NULL, 'Em diagnóstico', 5800.00, '2026-10-15', '2026-10-24', NULL),
(24, 7, 7, 'Sem sinal de vídeo', 'Cabo HDMI danificado', 'Entregue', 650.00, '2026-10-01', '2026-10-03', '2026-10-02');

INSERT INTO servicos_reparacao (id_reparacao, id_servico, preco_aplicado) VALUES
(1, 1, 500.00),
(1, 10, 650.00),
(2, 3, 800.00),
(2, 17, 300.00),
(2, 5, 600.00),
(3, 1, 500.00),
(3, 6, 400.00),
(4, 1, 500.00),
(4, 9, 450.00),
(5, 15, 700.00),
(6, 8, 600.00),
(7, 7, 1500.00),
(8, 2, 1200.00),
(8, 17, 300.00),
(9, 4, 700.00),
(10, 7, 1500.00),
(11, 1, 500.00),
(11, 5, 600.00),
(12, 1, 500.00),
(12, 20, 350.00),
(13, 1, 500.00),
(13, 10, 650.00),
(14, 1, 500.00),
(15, 1, 500.00),
(15, 14, 600.00),
(16, 1, 500.00),
(17, 1, 500.00),
(18, 2, 1200.00),
(18, 13, 500.00),
(19, 4, 700.00),
(19, 6, 400.00),
(20, 1, 500.00),
(20, 7, 1500.00),
(21, 18, 800.00),
(22, 20, 350.00),
(23, 1, 500.00),
(24, 20, 350.00);

INSERT INTO pecas_reparacao (id_reparacao, id_peca, quantidade, preco_unitario) VALUES
(1, 1, 1, 2800.00),
(2, 4, 1, 2500.00),
(3, 2, 1, 2400.00),
(4, 7, 1, 3500.00),
(5, 16, 1, 4800.00),
(6, 8, 1, 1800.00),
(7, 20, 1, 1600.00),
(9, 10, 1, 650.00),
(9, 11, 1, 350.00),
(10, 19, 1, 4200.00),
(11, 6, 1, 3200.00),
(12, 17, 1, 1800.00),
(13, 1, 1, 2800.00),
(13, 11, 1, 350.00),
(15, 18, 1, 900.00),
(19, 3, 2, 1500.00),
(19, 11, 1, 350.00),
(20, 9, 1, 6500.00),
(21, 14, 1, 1200.00),
(22, 13, 1, 150.00),
(24, 12, 1, 300.00);

INSERT INTO pagamentos (id_reparacao, num_pagamento, data_pagamento, valor, metodo) VALUES
(1, 1, '2026-08-04', 1950.00, 'Numerário'),
(1, 2, '2026-08-06', 2000.00, 'M-Pesa'),
(2, 1, '2026-08-06', 2100.00, 'e-Mola'),
(2, 2, '2026-08-09', 2100.00, 'Transferência bancária'),
(3, 1, '2026-08-11', 1650.00, 'Cartão'),
(3, 2, '2026-08-13', 1650.00, 'Numerário'),
(4, 1, '2026-08-13', 2200.00, 'M-Pesa'),
(4, 2, '2026-08-17', 2250.00, 'e-Mola'),
(5, 1, '2026-08-24', 5500.00, 'Transferência bancária'),
(6, 1, '2026-08-29', 2400.00, 'Cartão'),
(7, 1, '2026-09-08', 1550.00, 'Numerário'),
(8, 1, '2026-09-04', 750.00, 'M-Pesa'),
(8, 2, '2026-09-07', 750.00, 'e-Mola'),
(9, 1, '2026-09-11', 1700.00, 'Transferência bancária'),
(10, 1, '2026-09-11', 2250.00, 'Cartão'),
(11, 1, '2026-10-10', 2150.00, 'Numerário'),
(13, 1, '2026-10-11', 2150.00, 'M-Pesa'),
(18, 1, '2026-09-16', 1700.00, 'e-Mola'),
(20, 1, '2026-10-13', 4250.00, 'Transferência bancária'),
(21, 1, '2026-10-12', 1000.00, 'Cartão'),
(22, 1, '2026-09-30', 500.00, 'Numerário'),
(24, 1, '2026-10-02', 650.00, 'M-Pesa');

-- ---------------------------------------------------------------------
-- 3. VERIFICAÇÃO: quantidade de registos por tabela (mínimo exigido: 20)
-- ---------------------------------------------------------------------
SELECT 'utilizadores' AS tabela, COUNT(*) AS registos FROM utilizadores
UNION ALL SELECT 'clientes', COUNT(*) FROM clientes
UNION ALL SELECT 'tecnicos', COUNT(*) FROM tecnicos
UNION ALL SELECT 'equipamentos', COUNT(*) FROM equipamentos
UNION ALL SELECT 'servicos', COUNT(*) FROM servicos
UNION ALL SELECT 'pecas', COUNT(*) FROM pecas
UNION ALL SELECT 'reparacoes', COUNT(*) FROM reparacoes
UNION ALL SELECT 'servicos_reparacao', COUNT(*) FROM servicos_reparacao
UNION ALL SELECT 'pecas_reparacao', COUNT(*) FROM pecas_reparacao
UNION ALL SELECT 'pagamentos', COUNT(*) FROM pagamentos;

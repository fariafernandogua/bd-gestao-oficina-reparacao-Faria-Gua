# Modelo relacional — Sistema de Gestão de Oficina de Reparação de Computadores

**Estudante:** Faria Fernando Gua · **UC:** Tecnologias de Bases de Dados · Universidade Licungo

Legenda: **PK** = chave primária (sublinhada no diagrama) · **FK** = chave estrangeira · `→` aponta para a tabela referenciada.

## 1. Esquema relacional

```
utilizadores (PK id_utilizador, nome_utilizador, email, palavra_passe_hash, perfil, ativo, data_criacao)

clientes (PK id_cliente, FK id_utilizador → utilizadores [opcional, único], nome, telefone, email, endereco, data_registo)

tecnicos (PK id_tecnico, FK id_utilizador → utilizadores [obrigatório, único], nome, especialidade, telefone)

equipamentos (PK id_equipamento, FK id_cliente → clientes, tipo, marca, modelo, numero_serie)

servicos (PK id_servico, nome, descricao, preco_base)

pecas (PK id_peca, nome, marca, preco_unitario, stock, stock_minimo)

reparacoes (PK id_reparacao, FK id_equipamento → equipamentos, FK id_tecnico → tecnicos,
            problema_relatado, diagnostico, estado, custo_estimado,
            data_entrada, data_prevista, data_conclusao)

servicos_reparacao (PK composta (id_reparacao, id_servico),
                    FK id_reparacao → reparacoes, FK id_servico → servicos, preco_aplicado)

pecas_reparacao (PK composta (id_reparacao, id_peca),
                 FK id_reparacao → reparacoes, FK id_peca → pecas, quantidade, preco_unitario)

pagamentos (PK composta (id_reparacao, num_pagamento),      -- ENTIDADE FRACA
            FK id_reparacao → reparacoes, data_pagamento, valor, metodo)
```

## 2. Relacionamentos, cardinalidade e participação

| Relacionamento | Entidades | Cardinalidade | Participação |
|---|---|---|---|
| tem conta | utilizadores – clientes | 1 : 1 | cliente: **parcial** (há clientes sem conta); utilizador: parcial |
| tem conta | utilizadores – tecnicos | 1 : 1 | técnico: **total** (todo o técnico tem conta); utilizador: parcial |
| possui | clientes – equipamentos | 1 : N | equipamento: **total**; cliente: parcial |
| é alvo de | equipamentos – reparacoes | 1 : N | reparação: **total**; equipamento: parcial |
| é responsável | tecnicos – reparacoes | 1 : N | reparação: **total**; técnico: parcial |
| inclui | reparacoes – servicos | M : N (tabela `servicos_reparacao`) | parcial nos dois lados |
| utiliza | reparacoes – pecas | M : N (tabela `pecas_reparacao`) | parcial nos dois lados |
| recebe (identificador) | reparacoes – pagamentos | 1 : N | pagamento: **total**; reparação: parcial |

**Entidade fraca:** `pagamentos`. Um pagamento não tem existência própria: só se identifica através da reparação a que pertence. A chave é composta por `id_reparacao` (herdada da entidade forte) e `num_pagamento` (chave parcial: 1.º, 2.º... pagamento dessa reparação).

## 3. Dicionário de dados (tipos e restrições)

### utilizadores
| Coluna | Tipo | Restrições |
|---|---|---|
| id_utilizador | INT | PK, AUTO_INCREMENT |
| nome_utilizador | VARCHAR(50) | NOT NULL, UNIQUE |
| email | VARCHAR(100) | NOT NULL, UNIQUE |
| palavra_passe_hash | VARCHAR(255) | NOT NULL |
| perfil | ENUM('administrador','tecnico','cliente') | NOT NULL |
| ativo | TINYINT(1) | NOT NULL, DEFAULT 1, CHECK (0 ou 1) |
| data_criacao | DATETIME | NOT NULL, DEFAULT CURRENT_TIMESTAMP |

### clientes
| Coluna | Tipo | Restrições |
|---|---|---|
| id_cliente | INT | PK, AUTO_INCREMENT |
| id_utilizador | INT | FK → utilizadores, UNIQUE, pode ser NULL |
| nome | VARCHAR(100) | NOT NULL |
| telefone | VARCHAR(20) | NOT NULL |
| email | VARCHAR(100) | UNIQUE, pode ser NULL |
| endereco | VARCHAR(150) | pode ser NULL |
| data_registo | DATE | NOT NULL, DEFAULT data actual |

### tecnicos
| Coluna | Tipo | Restrições |
|---|---|---|
| id_tecnico | INT | PK, AUTO_INCREMENT |
| id_utilizador | INT | FK → utilizadores, NOT NULL, UNIQUE |
| nome | VARCHAR(100) | NOT NULL |
| especialidade | VARCHAR(60) | NOT NULL |
| telefone | VARCHAR(20) | NOT NULL |

### equipamentos
| Coluna | Tipo | Restrições |
|---|---|---|
| id_equipamento | INT | PK, AUTO_INCREMENT |
| id_cliente | INT | FK → clientes, NOT NULL |
| tipo | ENUM('Portátil','Computador de secretária','All-in-One','Monitor','Impressora','Servidor','Tablet') | NOT NULL |
| marca | VARCHAR(40) | NOT NULL |
| modelo | VARCHAR(60) | NOT NULL |
| numero_serie | VARCHAR(40) | NOT NULL, UNIQUE |

### servicos
| Coluna | Tipo | Restrições |
|---|---|---|
| id_servico | INT | PK, AUTO_INCREMENT |
| nome | VARCHAR(80) | NOT NULL, UNIQUE |
| descricao | VARCHAR(200) | pode ser NULL |
| preco_base | DECIMAL(10,2) | NOT NULL, CHECK (> 0) |

### pecas
| Coluna | Tipo | Restrições |
|---|---|---|
| id_peca | INT | PK, AUTO_INCREMENT |
| nome | VARCHAR(80) | NOT NULL, UNIQUE |
| marca | VARCHAR(40) | NOT NULL |
| preco_unitario | DECIMAL(10,2) | NOT NULL, CHECK (> 0) |
| stock | INT | NOT NULL, DEFAULT 0, CHECK (>= 0) — o stock nunca é negativo |
| stock_minimo | INT | NOT NULL, DEFAULT 5, CHECK (>= 0) |

### reparacoes
| Coluna | Tipo | Restrições |
|---|---|---|
| id_reparacao | INT | PK, AUTO_INCREMENT |
| id_equipamento | INT | FK → equipamentos, NOT NULL |
| id_tecnico | INT | FK → tecnicos, NOT NULL |
| problema_relatado | TEXT | NOT NULL |
| diagnostico | TEXT | pode ser NULL (ainda não feito) |
| estado | ENUM('Recebida','Em diagnóstico','Em reparação','Concluída','Entregue') | NOT NULL, DEFAULT 'Recebida' |
| custo_estimado | DECIMAL(10,2) | NOT NULL, DEFAULT 0, CHECK (>= 0) |
| data_entrada | DATE | NOT NULL |
| data_prevista | DATE | NOT NULL, CHECK (>= data_entrada) |
| data_conclusao | DATE | pode ser NULL, CHECK (nula ou >= data_entrada) |

### servicos_reparacao
| Coluna | Tipo | Restrições |
|---|---|---|
| id_reparacao | INT | PK (parte), FK → reparacoes |
| id_servico | INT | PK (parte), FK → servicos |
| preco_aplicado | DECIMAL(10,2) | NOT NULL, CHECK (>= 0) |

### pecas_reparacao
| Coluna | Tipo | Restrições |
|---|---|---|
| id_reparacao | INT | PK (parte), FK → reparacoes |
| id_peca | INT | PK (parte), FK → pecas |
| quantidade | INT | NOT NULL, CHECK (> 0) |
| preco_unitario | DECIMAL(10,2) | NOT NULL, CHECK (> 0) — preço no momento do uso |

### pagamentos (entidade fraca)
| Coluna | Tipo | Restrições |
|---|---|---|
| id_reparacao | INT | PK (parte), FK → reparacoes |
| num_pagamento | INT | PK (parte, chave parcial), CHECK (>= 1) |
| data_pagamento | DATE | NOT NULL |
| valor | DECIMAL(10,2) | NOT NULL, CHECK (> 0) |
| metodo | ENUM('Numerário','M-Pesa','e-Mola','Transferência bancária','Cartão') | NOT NULL |

## 4. Regras de integridade das chaves estrangeiras

Todas as chaves estrangeiras usam `ON UPDATE CASCADE ON DELETE RESTRICT`: se o `id` mudar, a alteração propaga-se; não é possível eliminar um registo "pai" que ainda tenha registos "filhos" (por exemplo, um cliente com equipamentos).

## 5. Estados da reparação

| Estado | Significado |
|---|---|
| Recebida | O equipamento entrou na oficina e foi registado. Ainda não foi analisado. |
| Em diagnóstico | O técnico está a identificar a avaria. |
| Em reparação | O diagnóstico está feito e o trabalho está em curso. |
| Concluída | O trabalho terminou; o equipamento está pronto, mas ainda está na oficina. |
| Entregue | O cliente levou o equipamento. É o estado final. |

## 6. Decisões de modelação

1. O preço de cada serviço (`preco_aplicado`) e de cada peça (`preco_unitario` em `pecas_reparacao`) é copiado no momento do uso. Assim, uma alteração futura de preços não muda reparações antigas.
2. O stock guardado em `pecas` é o stock actual, já descontado das peças usadas.
3. O custo total de uma reparação não é guardado: calcula-se com soma de serviços + soma de peças. O mesmo para o valor por pagar (total − pagamentos). Isto evita redundância e dados contraditórios.
4. A palavra-passe de demonstração é guardada com SHA2 no script. No projecto de Programação Web usa-se `password_hash()` do PHP.

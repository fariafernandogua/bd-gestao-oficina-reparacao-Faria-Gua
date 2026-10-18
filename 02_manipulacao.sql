USE oficina_reparacoes;

-- =====================================================================
-- A. TRÊS CONSULTAS SELECT SIMPLES (com WHERE e ORDER BY)
-- =====================================================================

SELECT id_reparacao, id_equipamento, estado, data_entrada, data_prevista, custo_estimado
FROM reparacoes
WHERE estado IN ('Recebida', 'Em diagnóstico')
ORDER BY data_entrada ASC, id_reparacao ASC;

SELECT id_peca, nome, stock, stock_minimo
FROM pecas
WHERE stock <= stock_minimo
ORDER BY stock ASC, nome ASC;

SELECT id_reparacao, num_pagamento, data_pagamento, valor, metodo
FROM pagamentos
WHERE valor >= 2000 AND data_pagamento >= '2026-09-01'
ORDER BY valor DESC;

-- =====================================================================
-- B. DUAS CONSULTAS COM JOIN
-- =====================================================================

SELECT r.id_reparacao,
       c.nome       AS cliente,
       e.tipo, e.marca, e.modelo,
       t.nome       AS tecnico,
       r.estado,
       r.data_prevista
FROM reparacoes r
JOIN equipamentos e ON r.id_equipamento = e.id_equipamento
JOIN clientes     c ON e.id_cliente     = c.id_cliente
JOIN tecnicos     t ON r.id_tecnico     = t.id_tecnico
WHERE r.estado <> 'Entregue'
ORDER BY r.data_prevista ASC, r.id_reparacao ASC;

SELECT r.id_reparacao,
       e.marca, e.modelo,
       p.nome AS peca,
       pr.quantidade,
       pr.preco_unitario,
       pr.quantidade * pr.preco_unitario AS subtotal
FROM pecas_reparacao pr
JOIN pecas        p ON pr.id_peca      = p.id_peca
JOIN reparacoes   r ON pr.id_reparacao = r.id_reparacao
JOIN equipamentos e ON r.id_equipamento = e.id_equipamento
ORDER BY r.id_reparacao ASC, p.nome ASC;


SELECT x.id_reparacao, x.cliente, x.total_servicos, x.total_pecas, x.total_pago,
       (x.total_servicos + x.total_pecas - x.total_pago) AS valor_por_pagar
FROM (
  SELECT r.id_reparacao,
         c.nome AS cliente,
         COALESCE((SELECT SUM(sr.preco_aplicado) FROM servicos_reparacao sr
                   WHERE sr.id_reparacao = r.id_reparacao), 0) AS total_servicos,
         COALESCE((SELECT SUM(pr.quantidade * pr.preco_unitario) FROM pecas_reparacao pr
                   WHERE pr.id_reparacao = r.id_reparacao), 0) AS total_pecas,
         COALESCE((SELECT SUM(pg.valor) FROM pagamentos pg
                   WHERE pg.id_reparacao = r.id_reparacao), 0) AS total_pago
  FROM reparacoes r
  JOIN equipamentos e ON r.id_equipamento = e.id_equipamento
  JOIN clientes     c ON e.id_cliente     = c.id_cliente
) AS x
WHERE (x.total_servicos + x.total_pecas - x.total_pago) > 0
ORDER BY valor_por_pagar DESC;

-- =====================================================================
-- C. DUAS OPERAÇÕES UPDATE
-- =====================================================================

SELECT id_reparacao, estado FROM reparacoes WHERE id_reparacao = 16;   -- antes
UPDATE reparacoes
SET estado = 'Em diagnóstico'
WHERE id_reparacao = 16;
SELECT id_reparacao, estado FROM reparacoes WHERE id_reparacao = 16;   -- depois


SELECT id_peca, nome, stock, stock_minimo FROM pecas WHERE id_peca = 6;  -- antes
UPDATE pecas
SET stock = 10
WHERE id_peca = 6;
SELECT id_peca, nome, stock, stock_minimo FROM pecas WHERE id_peca = 6;  -- depois

-- =====================================================================
-- D. UMA OPERAÇÃO DELETE (respeitando as chaves estrangeiras)
-- =====================================================================

SELECT COUNT(*) AS equipamentos_do_cliente_21 FROM equipamentos WHERE id_cliente = 21;  -- tem de dar 0
DELETE FROM clientes
WHERE id_cliente = 21;
SELECT COUNT(*) AS clientes_com_id_21 FROM clientes WHERE id_cliente = 21;              -- deve dar 0

-- =====================================================================
-- E. TESTE DE INTEGRIDADE REFERENCIAL
-- =====================================================================

INSERT INTO equipamentos (id_cliente, tipo, marca, modelo, numero_serie)
VALUES (999, 'Portátil', 'HP', 'Teste Invalido', 'SN-TESTE-9999');

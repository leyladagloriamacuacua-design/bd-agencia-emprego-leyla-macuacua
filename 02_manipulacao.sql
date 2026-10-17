-- =====================================================================
-- Projecto de Base de Dados: Agência de Emprego (Elo Emprego)
-- Autor: <O SEU NOME COMPLETO>
-- Ficheiro 2/2: manipulação dos dados (SELECT, JOIN, UPDATE, DELETE, integridade)
-- Pré-requisito: ter executado 01_criacao_e_insercao.sql
-- Cada comando tem o "RESULTADO ESPERADO" escrito ANTES de ser executado.
-- =====================================================================

USE agencia_emprego;

-- =====================================================================
-- A) SELECT SIMPLES (3) - com WHERE e ORDER BY
-- =====================================================================

-- A1. Vagas abertas em Maputo, das mais bem pagas para as menos pagas.
-- RESULTADO ESPERADO: só vagas com localidade 'Maputo' e estado 'aberta',
--                     (10 linhas) ordenadas por salário decrescente: as duas primeiras pagam 30 000 MZN.
SELECT id_vaga, titulo, localidade, salario
FROM vaga
WHERE localidade = 'Maputo' AND estado = 'aberta'
ORDER BY salario DESC;

-- A2. Candidatos com licenciatura, por ordem alfabética.
-- RESULTADO ESPERADO: apenas candidatos com nivel_academico = 'Licenciatura', de A a Z pelo nome.
SELECT id_candidato, nome_completo, cidade, profissao
FROM candidato
WHERE nivel_academico = 'Licenciatura'
ORDER BY nome_completo ASC;

-- A3. Candidaturas ainda em análise, das mais antigas para as mais recentes.
-- RESULTADO ESPERADO: só candidaturas com estado 'em_analise', ordenadas pela data (mais antiga primeiro).
SELECT id_candidatura, id_candidato, id_vaga, data_candidatura
FROM candidatura
WHERE estado = 'em_analise'
ORDER BY data_candidatura ASC;

-- =====================================================================
-- B) SELECT COM JOIN (2)
-- =====================================================================

-- B1. Candidaturas com o nome do candidato, o título da vaga e a empresa (4 tabelas).
-- RESULTADO ESPERADO: uma linha por candidatura (32 linhas), mostrando em vez de IDs
--                     os nomes legíveis: candidato, vaga, empresa e estado.
SELECT ca.id_candidatura,
       c.nome_completo  AS candidato,
       v.titulo         AS vaga,
       e.nome           AS empresa,
       ca.estado
FROM candidatura ca
JOIN candidato c ON c.id_candidato = ca.id_candidato
JOIN vaga v      ON v.id_vaga      = ca.id_vaga
JOIN empresa e   ON e.id_empresa   = v.id_empresa
ORDER BY ca.id_candidatura;

-- B2. Entrevistas pendentes: quem, para que vaga, quando e qual o funcionário responsável.
-- RESULTADO ESPERADO: só entrevistas com resultado 'pendente' (8 linhas), da mais próxima
--                     para a mais distante, com o e-mail do funcionário que a conduz.
SELECT en.id_entrevista,
       c.nome_completo AS candidato,
       v.titulo        AS vaga,
       en.data_hora,
       en.local,
       u.email         AS funcionario
FROM entrevista en
JOIN candidatura ca ON ca.id_candidatura = en.id_candidatura
JOIN candidato c    ON c.id_candidato    = ca.id_candidato
JOIN vaga v         ON v.id_vaga         = ca.id_vaga
JOIN utilizador u   ON u.id_utilizador   = en.id_funcionario
WHERE en.resultado = 'pendente'
ORDER BY en.data_hora;

-- =====================================================================
-- C) UPDATE (3)
-- =====================================================================

-- C1. A candidatura 4 (submetida) passa a "em análise".
-- RESULTADO ESPERADO: 1 linha afetada; o estado da candidatura 4 passa de 'submetida' a 'em_analise'.
UPDATE candidatura SET estado = 'em_analise' WHERE id_candidatura = 4;
SELECT id_candidatura, estado FROM candidatura WHERE id_candidatura = 4;

-- C2. Aumento de 10 % no salário da vaga 8 (Motorista de Pesados: 21 000 -> 23 100 MZN).
-- RESULTADO ESPERADO: 1 linha afetada; o salário da vaga 8 passa a 23100.00.
UPDATE vaga SET salario = salario * 1.10 WHERE id_vaga = 8;
SELECT id_vaga, titulo, salario FROM vaga WHERE id_vaga = 8;

-- C3. O candidato 5 mudou de número de telefone.
-- RESULTADO ESPERADO: 1 linha afetada; o telefone do candidato 5 passa a '+258 84 555 0123'.
UPDATE candidato SET telefone = '+258 84 555 0123' WHERE id_candidato = 5;
SELECT id_candidato, nome_completo, telefone FROM candidato WHERE id_candidato = 5;

-- =====================================================================
-- D) DELETE (1) - respeitando as chaves estrangeiras
-- =====================================================================

-- D1. Eliminar a candidatura 25 (do candidato 11). Esta candidatura tem uma entrevista associada,
--     por isso é preciso apagar PRIMEIRO o registo "filho" (entrevista) e só depois o "pai"
--     (candidatura). Se tentássemos apagar a candidatura primeiro, o MySQL daria o erro 1451
--     (Cannot delete or update a parent row: a foreign key constraint fails).
-- RESULTADO ESPERADO: 1 linha apagada em entrevista e 1 linha apagada em candidatura;
--                     as duas consultas finais devolvem 0 linhas.
DELETE FROM entrevista  WHERE id_candidatura = 25;
DELETE FROM candidatura WHERE id_candidatura = 25;
SELECT * FROM entrevista  WHERE id_candidatura = 25;
SELECT * FROM candidatura WHERE id_candidatura = 25;

-- =====================================================================
-- E) TESTE DE INTEGRIDADE REFERENCIAL (1)
-- =====================================================================

-- E1. Inserir uma candidatura para a vaga 999, que não existe.
-- RESULTADO ESPERADO: o MySQL RECUSA o INSERT com o erro
--   ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails
--   (`agencia_emprego`.`candidatura`, CONSTRAINT `fk_candidatura_vaga`
--    FOREIGN KEY (`id_vaga`) REFERENCES `vaga` (`id_vaga`) ...)
-- EXPLICAÇÃO: a coluna id_vaga da candidatura é chave estrangeira de vaga(id_vaga).
--   Como não existe nenhuma vaga com id 999, a ligação seria inválida e o SGBD impede
--   o registo, garantindo que não há candidaturas "órfãs". (Este erro é esperado.)
INSERT INTO candidatura (id_candidato, id_vaga, data_candidatura, estado)
VALUES (1, 999, '2026-10-17', 'submetida');

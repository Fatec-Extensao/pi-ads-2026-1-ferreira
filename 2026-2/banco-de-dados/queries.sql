Aqui está o `queries.sql` corrigido, sem o `USE` duplicado e com os comentários ajustados. Mantive os INSERTs e as cinco consultas.

sql

```sql

USE gestao_pesquisas;

-- =====================================================================
--  1. DADOS INICIAIS
-- =====================================================================

-- Cadastro dos perfis de acesso

INSERT INTO perfis (nome, descricao) VALUES
    ('Administrador',
     'Cria e gerencia pesquisas, categorias, questionários, senhas, relatórios e usuários.'),

    ('Secretaria',
     'Aprova pesquisas antes da aplicação e analisa relatórios institucionais.'),

    ('Analista de Dados',
     'Analisa resultados, gera insights e exporta dados para uso externo.'),

    ('Suporte Técnico',
     'Mantém o sistema em operação e resolve erros e falhas.'),

    ('Auditor',
     'Audita os dados coletados e verifica segurança e conformidade com a LGPD.');


-- =====================================================================
--  2. PARTICIPAÇÃO POR CATEGORIA
--  Mostra quantas submissões cada categoria recebeu em cada pesquisa.
-- =====================================================================

SELECT
    p.id AS pesquisa_id,
    p.titulo AS pesquisa,
    cp.nome AS categoria,
    COUNT(s.id) AS total_submissoes
FROM pesquisas p
INNER JOIN categorias_participantes cp
    ON cp.pesquisa_id = p.id
LEFT JOIN submissoes s
    ON s.categoria_id = cp.id
GROUP BY
    p.id,
    p.titulo,
    cp.id,
    cp.nome
ORDER BY
    p.titulo,
    cp.nome;


-- =====================================================================
--  3. DISTRIBUIÇÃO DAS RESPOSTAS POR ALTERNATIVA
--  Mostra quantas vezes cada alternativa foi escolhida.
-- =====================================================================

SELECT
    p.titulo AS pesquisa,
    cp.nome AS categoria,
    q.texto_questao AS questao,
    a.texto_alternativa AS alternativa,
    COUNT(r.id) AS total_respostas
FROM respostas r
INNER JOIN questoes q
    ON q.id = r.questao_id
INNER JOIN alternativas a
    ON a.id = r.alternativa_id
INNER JOIN categorias_participantes cp
    ON cp.id = q.categoria_id
INNER JOIN pesquisas p
    ON p.id = cp.pesquisa_id
GROUP BY
    p.id,
    p.titulo,
    cp.id,
    cp.nome,
    q.id,
    q.texto_questao,
    a.id,
    a.texto_alternativa
ORDER BY
    p.titulo,
    q.texto_questao,
    total_respostas DESC;


-- =====================================================================
--  4. MÉDIA DE SATISFAÇÃO POR QUESTÃO E CATEGORIA
--  Calcula a média das respostas de questões do tipo ESCALA.
-- =====================================================================

SELECT
    p.titulo AS pesquisa,
    cp.nome AS categoria,
    q.texto_questao AS questao,
    COUNT(r.id) AS total_respostas,
    ROUND(AVG(r.valor_escala), 2) AS media_satisfacao
FROM respostas r
INNER JOIN questoes q
    ON q.id = r.questao_id
INNER JOIN categorias_participantes cp
    ON cp.id = q.categoria_id
INNER JOIN pesquisas p
    ON p.id = cp.pesquisa_id
WHERE
    q.tipo_questao = 'ESCALA'
    AND r.valor_escala IS NOT NULL
GROUP BY
    p.id,
    p.titulo,
    cp.id,
    cp.nome,
    q.id,
    q.texto_questao
ORDER BY
    p.titulo,
    cp.nome;


-- =====================================================================
--  5. SUBMISSÕES POR DIA
--  Mostra a quantidade de submissões recebidas em cada dia.
-- =====================================================================

SELECT
    p.titulo AS pesquisa,
    DATE(s.criado_em) AS data_submissao,
    COUNT(s.id) AS total_submissoes,
    COUNT(DISTINCT s.categoria_id) AS categorias_participantes
FROM submissoes s
INNER JOIN categorias_participantes cp
    ON cp.id = s.categoria_id
INNER JOIN pesquisas p
    ON p.id = cp.pesquisa_id
GROUP BY
    p.id,
    p.titulo,
    DATE(s.criado_em)
ORDER BY
    data_submissao;


-- =====================================================================
--  6. RESUMO GERAL POR PESQUISA
--  Apresenta indicadores gerais de cada pesquisa.
-- =====================================================================

SELECT
    p.id AS pesquisa_id,
    p.titulo AS pesquisa,
    p.status,
    COUNT(DISTINCT cp.id) AS total_categorias,
    COUNT(DISTINCT q.id) AS total_questoes,
    COUNT(DISTINCT s.id) AS total_submissoes,
    COUNT(DISTINCT r.id) AS total_respostas
FROM pesquisas p
LEFT JOIN categorias_participantes cp
    ON cp.pesquisa_id = p.id
LEFT JOIN questoes q
    ON q.categoria_id = cp.id
LEFT JOIN submissoes s
    ON s.categoria_id = cp.id
LEFT JOIN respostas r
    ON r.submissao_id = s.id
GROUP BY
    p.id,
    p.titulo,
    p.status
ORDER BY
    p.id;
```


USE gestao_pesquisas;

-- =====================================================================
--  8. DADOS INICIAIS
-- =====================================================================

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

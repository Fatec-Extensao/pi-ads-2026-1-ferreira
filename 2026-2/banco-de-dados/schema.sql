

CREATE DATABASE IF NOT EXISTS gestao_pesquisas
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE gestao_pesquisas;


DROP TABLE IF EXISTS chamados_historico;
DROP TABLE IF EXISTS chamados;
DROP TABLE IF EXISTS notificacoes;
DROP TABLE IF EXISTS logs_auditoria;
DROP TABLE IF EXISTS respostas;
DROP TABLE IF EXISTS submissoes;
DROP TABLE IF EXISTS tokens_anonimos;
DROP TABLE IF EXISTS lotes_senhas;
DROP TABLE IF EXISTS alternativas;
DROP TABLE IF EXISTS questoes;
DROP TABLE IF EXISTS categorias_participantes;
DROP TABLE IF EXISTS pesquisas;
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS perfis;

-- =====================================================================
--  1. USUÁRIOS E PERFIS
-- =====================================================================

CREATE TABLE perfis (
    id         INT          NOT NULL AUTO_INCREMENT,
    nome       VARCHAR(50)  NOT NULL,
    descricao  TEXT         NULL,
    CONSTRAINT pk_perfis PRIMARY KEY (id),
    CONSTRAINT uq_perfis_nome UNIQUE (nome)
) ENGINE = InnoDB;

CREATE TABLE usuarios (
    id          INT           NOT NULL AUTO_INCREMENT,
    nome        VARCHAR(100)  NOT NULL,
    email       VARCHAR(100)  NOT NULL,
    senha_hash  VARCHAR(255)  NOT NULL,              -- BCrypt/Argon2, nunca texto puro
    perfil_id   INT           NOT NULL,
    ativo       BOOLEAN       NOT NULL DEFAULT TRUE, -- FALSE = desativado (permissões revogadas)
    criado_em   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_usuarios PRIMARY KEY (id),
    CONSTRAINT uq_usuarios_email UNIQUE (email),
    CONSTRAINT fk_usuarios_perfil FOREIGN KEY (perfil_id) REFERENCES perfis (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB;

-- =====================================================================
--  2. PESQUISAS, CATEGORIAS E QUESTIONÁRIO
-- =====================================================================

CREATE TABLE pesquisas (
    id                 INT           NOT NULL AUTO_INCREMENT,
    titulo             VARCHAR(100)  NOT NULL,
    descricao          TEXT          NULL,
    data_inicio        DATETIME      NOT NULL,
    data_fim           DATETIME      NOT NULL,
    status             VARCHAR(20)   NOT NULL DEFAULT 'RASCUNHO',
    criado_por         INT           NOT NULL,
    aprovado_por       INT           NULL,         -- preenchido pela Secretaria
    aprovado_em        DATETIME      NULL,
    motivo_reprovacao  TEXT          NULL,
    criado_em          TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_pesquisas PRIMARY KEY (id),
    CONSTRAINT fk_pesquisas_criado_por FOREIGN KEY (criado_por) REFERENCES usuarios (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_pesquisas_aprovado_por FOREIGN KEY (aprovado_por) REFERENCES usuarios (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_pesquisas_titulo CHECK (CHAR_LENGTH(titulo) BETWEEN 5 AND 100),
    CONSTRAINT ck_pesquisas_periodo CHECK (data_fim > data_inicio),
    CONSTRAINT ck_pesquisas_status CHECK (status IN
        ('RASCUNHO', 'EM_ANALISE', 'APROVADA', 'REPROVADA', 'ATIVA', 'ENCERRADA'))
) ENGINE = InnoDB;

CREATE INDEX idx_pesquisas_status  ON pesquisas (status);
CREATE INDEX idx_pesquisas_periodo ON pesquisas (data_inicio, data_fim);

CREATE TABLE categorias_participantes (
    id           INT          NOT NULL AUTO_INCREMENT,
    pesquisa_id  INT          NOT NULL,
    nome         VARCHAR(50)  NOT NULL,
    CONSTRAINT pk_categorias PRIMARY KEY (id),
    CONSTRAINT uq_categorias_pesquisa_nome UNIQUE (pesquisa_id, nome),  -- nome único na pesquisa
    CONSTRAINT fk_categorias_pesquisa FOREIGN KEY (pesquisa_id) REFERENCES pesquisas (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB;

CREATE TABLE questoes (
    id             INT          NOT NULL AUTO_INCREMENT,
    categoria_id   INT          NOT NULL,
    texto_questao  TEXT         NOT NULL,
    tipo_questao   VARCHAR(30)  NOT NULL,
    obrigatoria    BOOLEAN      NOT NULL DEFAULT FALSE,
    ordem          INT          NOT NULL DEFAULT 1,
    CONSTRAINT pk_questoes PRIMARY KEY (id),
    CONSTRAINT fk_questoes_categoria FOREIGN KEY (categoria_id) REFERENCES categorias_participantes (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_questoes_tipo CHECK (tipo_questao IN
        ('MULTIPLA_UNICA', 'MULTIPLA_VARIAS', 'ESCALA', 'ABERTA')),
    CONSTRAINT ck_questoes_ordem CHECK (ordem >= 1)
) ENGINE = InnoDB;

CREATE TABLE alternativas (
    id                 INT      NOT NULL AUTO_INCREMENT,
    questao_id         INT      NOT NULL,
    texto_alternativa  TEXT     NOT NULL,
    ordem              INT      NOT NULL DEFAULT 1,
    CONSTRAINT pk_alternativas PRIMARY KEY (id),
    CONSTRAINT uq_alternativas_id_questao UNIQUE (id, questao_id),  -- permite a FK composta de respostas
    CONSTRAINT fk_alternativas_questao FOREIGN KEY (questao_id) REFERENCES questoes (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_alternativas_ordem CHECK (ordem >= 1)
) ENGINE = InnoDB;

-- =====================================================================
--  3. SENHAS ANÔNIMAS (lotes e tokens)
-- =====================================================================

CREATE TABLE lotes_senhas (
    id            INT        NOT NULL AUTO_INCREMENT,
    categoria_id  INT        NOT NULL,
    quantidade    INT        NOT NULL,
    criado_em     TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_lotes_senhas PRIMARY KEY (id),
    CONSTRAINT fk_lotes_categoria FOREIGN KEY (categoria_id) REFERENCES categorias_participantes (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_lotes_quantidade CHECK (quantidade > 0)
) ENGINE = InnoDB;

CREATE TABLE tokens_anonimos (
    id            INT         NOT NULL AUTO_INCREMENT,
    lote_id       INT         NOT NULL,
    token_hash    VARCHAR(64) NOT NULL,   -- SHA-256 em hexadecimal; a senha em texto nunca é gravada
    utilizado_em  DATE        NULL,       -- NULL = disponível; guarda só a data (sem hora) por causa do anonimato
    CONSTRAINT pk_tokens PRIMARY KEY (id),
    CONSTRAINT uq_tokens_hash UNIQUE (token_hash),
    CONSTRAINT fk_tokens_lote FOREIGN KEY (lote_id) REFERENCES lotes_senhas (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB;

-- =====================================================================
--  4. RESPOSTAS (sem nenhuma ligação com tokens_anonimos: preserva o anonimato)
-- =====================================================================

CREATE TABLE submissoes (
    id            INT       NOT NULL AUTO_INCREMENT,
    categoria_id  INT       NOT NULL,
    criado_em     DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_submissoes PRIMARY KEY (id),
    CONSTRAINT fk_submissoes_categoria FOREIGN KEY (categoria_id) REFERENCES categorias_participantes (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB;

CREATE INDEX idx_submissoes_criado_em ON submissoes (criado_em);

CREATE TABLE respostas (
    id              INT   NOT NULL AUTO_INCREMENT,
    submissao_id    INT   NOT NULL,
    questao_id      INT   NOT NULL,
    alternativa_id  INT   NULL,       -- só em questões de múltipla escolha
    valor_escala    INT   NULL,       -- só em questões de escala (1 a 5)
    resposta_texto  TEXT  NULL,       -- só em questões abertas
    CONSTRAINT pk_respostas PRIMARY KEY (id),
    CONSTRAINT fk_respostas_submissao FOREIGN KEY (submissao_id) REFERENCES submissoes (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_respostas_questao FOREIGN KEY (questao_id) REFERENCES questoes (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    -- FK composta: a alternativa escolhida precisa pertencer à questão respondida.
    -- Quando alternativa_id é NULL (escala/aberta), a verificação é ignorada.
    CONSTRAINT fk_respostas_alternativa FOREIGN KEY (alternativa_id, questao_id)
        REFERENCES alternativas (id, questao_id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_respostas_escala CHECK (valor_escala IS NULL OR valor_escala BETWEEN 1 AND 5)
) ENGINE = InnoDB;

-- =====================================================================
--  5. AUDITORIA E NOTIFICAÇÕES
-- =====================================================================

CREATE TABLE logs_auditoria (
    id              BIGINT        NOT NULL AUTO_INCREMENT,
    usuario_id      INT           NULL,          -- NULL = ação do sistema
    acao            VARCHAR(100)  NOT NULL,
    tabela_afetada  VARCHAR(50)   NULL,
    registro_id     BIGINT        NULL,
    descricao       TEXT          NULL,
    endereco_ip     VARCHAR(45)   NULL,          -- apenas de usuários internos, nunca de participantes
    criado_em       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_logs PRIMARY KEY (id),
    CONSTRAINT fk_logs_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB;

CREATE INDEX idx_logs_criado_em ON logs_auditoria (criado_em);

CREATE TABLE notificacoes (
    id          INT           NOT NULL AUTO_INCREMENT,
    usuario_id  INT           NOT NULL,          -- destinatário
    mensagem    VARCHAR(255)  NOT NULL,
    lida        BOOLEAN       NOT NULL DEFAULT FALSE,
    criado_em   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_notificacoes PRIMARY KEY (id),
    CONSTRAINT fk_notificacoes_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB;

-- =====================================================================
--  6. SUPORTE TÉCNICO (chamados)
-- =====================================================================

CREATE TABLE chamados (
    id          INT           NOT NULL AUTO_INCREMENT,
    aberto_por  INT           NOT NULL,
    titulo      VARCHAR(100)  NOT NULL,
    descricao   TEXT          NULL,
    severidade  VARCHAR(20)   NOT NULL,
    status      VARCHAR(20)   NOT NULL DEFAULT 'ABERTO',
    aberto_em   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fechado_em  DATETIME      NULL,
    CONSTRAINT pk_chamados PRIMARY KEY (id),
    CONSTRAINT fk_chamados_aberto_por FOREIGN KEY (aberto_por) REFERENCES usuarios (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_chamados_severidade CHECK (severidade IN ('CRITICA', 'MEDIA', 'BAIXA')),
    CONSTRAINT ck_chamados_status CHECK (status IN ('ABERTO', 'FECHADO'))
) ENGINE = InnoDB;

CREATE TABLE chamados_historico (
    id          INT        NOT NULL AUTO_INCREMENT,
    chamado_id  INT        NOT NULL,
    usuario_id  INT        NOT NULL,
    acao        TEXT       NOT NULL,
    criado_em   TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_chamados_historico PRIMARY KEY (id),
    CONSTRAINT fk_historico_chamado FOREIGN KEY (chamado_id) REFERENCES chamados (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_historico_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB;

-- =====================================================================
--  7. REGRAS DE NEGÓCIO NO BANCO (triggers)
-- =====================================================================
DELIMITER $$

-- Logs imutáveis: não podem ser alterados nem excluídos (RNF29)
CREATE TRIGGER trg_logs_bloqueia_update BEFORE UPDATE ON logs_auditoria
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Logs de auditoria são imutáveis.';
END$$

CREATE TRIGGER trg_logs_bloqueia_delete BEFORE DELETE ON logs_auditoria
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Logs de auditoria são imutáveis.';
END$$

-- Cada senha permite uma única resposta: depois de utilizada, não muda mais (RF09)
CREATE TRIGGER trg_tokens_uma_utilizacao BEFORE UPDATE ON tokens_anonimos
FOR EACH ROW
BEGIN
    IF OLD.utilizado_em IS NOT NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Esta senha já foi utilizada.';
    END IF;
    IF NEW.token_hash <> OLD.token_hash OR NEW.lote_id <> OLD.lote_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hash e lote da senha não podem ser alterados.';
    END IF;
END$$

-- A questão respondida deve ser da mesma categoria da submissão
CREATE TRIGGER trg_respostas_mesma_categoria BEFORE INSERT ON respostas
FOR EACH ROW
BEGIN
    IF (SELECT categoria_id FROM questoes    WHERE id = NEW.questao_id)
    <> (SELECT categoria_id FROM submissoes WHERE id = NEW.submissao_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A questão não pertence à categoria da submissão.';
    END IF;
END$$

DELIMITER ;




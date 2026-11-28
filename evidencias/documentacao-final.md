# Documentação Final — Sistema Web para Gestão de Pesquisas por Questionários

> **Instituição:** Fatec Lins — Curso Superior de Tecnologia em Análise e Desenvolvimento de Sistemas (ADS)  
> **Disciplina:** Projeto Integrador · 2026  
> **Equipe:** Anderson Clayton Pereira de Assis · Eduardo Matias Ferreira · Lucas Augusto Vieira Tridapali · Vitor Hugo Dias Mantovani · Neandro Bueno Vieira

---

## 1. Visão Geral do Projeto

O **Sistema Web para Gestão de Pesquisas por Questionários** é uma plataforma institucional desenvolvida para **criar, aprovar, aplicar e analisar pesquisas internas com garantia estrutural de anonimato** (conformidade com a LGPD — Lei nº 13.709/2018).

### Problema e Solução
* **Problema:** Pesquisas institucionais tradicionais enfrentam baixa adesão por receio de identificação do respondente, além de processos manuais descentralizados e dificuldade na consolidação comparativa entre diferentes públicos.
* **Solução:** Aplicação web responsiva (*mobile-first* para respondentes) baseada em **senhas anônimas de uso único** geradas por categoria de participante, dissociadas fisicamente das respostas submetidas, com fluxo formal de aprovação institucional e painéis estatísticos agregados.

---

## 2. Atores e Perfis de Acesso

O sistema opera com **6 perfis distintos**, regidos pelo princípio do menor privilégio (RBAC) e validação de permissões tanto no frontend quanto no backend (`RNF36`–`RNF40`):

| Perfil / Ator | Tipo de Acesso | Responsabilidades Principais |
| :--- | :--- | :--- |
| **Administrador** | Autenticado (Login) | Cadastra pesquisas, categorias e questionários; envia pesquisas para análise; gera e exporta lotes de senhas anônimas; monitora participação em tempo real e gerencia usuários internos. |
| **Participante** | Público (Senha anônima) | Não possui cadastro. Acessa o questionário da sua categoria via senha única de 8 caracteres, salva rascunho localmente no navegador e submete respostas de forma 100% anônima. |
| **Secretaria** | Autenticado (Login) | Revisa o conteúdo das pesquisas em análise, aprova ou reprova (com justificativa obrigatória de no mínimo 10 caracteres) e analisa relatórios institucionais consolidados. |
| **Analista de Dados** | Autenticado (Somente leitura) | Realiza cruzamentos avançados por pergunta, categoria e período, gera insights e exporta bases anonimizadas em CSV e XLSX. |
| **Suporte Técnico** | Autenticado (Operacional) | Monitora a disponibilidade de APIs, banco e servidores (atualização a cada 30s) e gerencia chamados técnicos com controle de SLA (4h crítico / 24h médio). |
| **Auditor** | Autenticado (Somente leitura) | Inspeciona a trilha de auditoria imutável (`logs_auditoria`) e emite relatórios de conformidade técnica e legal (LGPD). |

---

## 3. Ciclo de Vida da Pesquisa (Máquina de Estados)

Toda pesquisa segue um fluxo controlado de estados validado pela camada de aplicação e por restrições `CHECK` no banco de dados:

```text
[ RASCUNHO ] ──(Enviar p/ análise)──► [ EM_ANALISE ]
                                           │
                     ┌─────────────────────┴─────────────────────┐
                     ▼ (Aprovar)                                 ▼ (Reprovar c/ motivo)
               [ APROVADA ]                                [ REPROVADA ] ──(Editar)──► [ RASCUNHO ]
                     │
        (Início do período + Lotes)
                     ▼
                [ ATIVA ] ──(Fim do período)──► [ ENCERRADA ]
```

---

## 4. Arquitetura Técnica e Banco de Dados

### 4.1 Modelo Físico (`MySQL 8.0.16+` / `MariaDB 10.5+`)
O banco de dados é composto por **14 tabelas relacionais**, todas protegidas por `ON DELETE RESTRICT ON UPDATE RESTRICT` para impedir exclusão acidental de registros históricos:

* **Gestão de Usuários:** `perfis`, `usuarios`
* **Estrutura de Pesquisas:** `pesquisas`, `categorias_participantes`, `questoes`, `alternativas`
* **Controle de Acesso Anônimo:** `lotes_senhas`, `tokens_anonimos`
* **Coleta de Dados:** `submissoes`, `respostas`
* **Governança, Auditoria e Suporte:** `logs_auditoria`, `notificacoes`, `chamados`, `chamados_historico`

### 4.2 Integridade Automatizada no SGBD
* **Chave Estrangeira Composta:** `respostas(alternativa_id, questao_id)` referencia `alternativas(id, questao_id)`, garantindo no banco que uma alternativa pertence obrigatoriamente à questão respondida.
* **Triggers Ativas:**
  1. `trg_logs_bloqueia_update`: Impede alteração em registros de auditoria (`RNF29`).
  2. `trg_logs_bloqueia_delete`: Impede exclusão de registros de auditoria (`RNF29`).
  3. `trg_tokens_uma_utilizacao`: Bloqueia reuso de senha anônima e alteração de hash/lote (`RF09`).
  4. `trg_respostas_mesma_categoria`: Valida que a questão respondida pertence à mesma categoria da submissão.

---

## 5. Compliance, Segurança da Informação e LGPD

O projeto incorpora controles de **Privacy by Design** e mitigação de riscos alinhados ao **OWASP Top 10** e à **Lei nº 13.709/2018 (LGPD)**:

* **Anonimato Estrutural (`RNF10`–`RNF15`):** Não existe chave estrangeira ou relação entre `tokens_anonimos` e `submissoes`/`respostas`. Além disso, `tokens_anonimos.utilizado_em` grava apenas a data (`DATE`), inviabilizando o pareamento temporal com `submissoes.criado_em` (`DATETIME`).
* **Zero Rastreamento do Respondente:** Nenhuma resposta armazena IP, cookies ou identificadores pessoais. O controle de tentativas inválidas (máximo 3 em 15 minutos, `RNF43`) ocorre exclusivamente em memória (cache).
* **K-Anonimato e TCLE:** Relatórios e cruzamentos exigem tamanho mínimo de grupo (5 respondentes) para evitar re-identificação indireta, e o participante aceita o Termo de Consentimento Livre e Esclarecido (TCLE) antes de iniciar.
* **Criptografia:** Senhas anônimas armazenadas exclusivamente via hash `SHA-256` (texto puro disponível apenas no download único da geração do lote); senhas de usuários internos protegidas com `BCrypt` ou `Argon2`.
* **Gestão de Riscos:** Matriz completa com **27 riscos mapeados** (`R01`–`R27`), plano de ação priorizado em 4 fases e política formal de retenção e expurgo de dados.

---

## 6. Mapa de Artefatos do Repositório

| Módulo / Pasta | Artefato | Descrição |
| :--- | :--- | :--- |
| **`2026-2/engenharia-software/`** | `requisitos.md` | 21 Requisitos Funcionais, 44 Não Funcionais, 17 Casos de Uso e Matriz de Rastreabilidade. |
| **`2026-2/engenharia-software/`** | `especificacao-diagrama-de-classes.md` | Especificação das 21 classes, 2 serviços, 3 enumerações e mapeamento classe → tabela. |
| **`2026-2/engenharia-software/`** | `especificacao-diagramas-de-sequencia.md` | Fluxos de interação detalhados para todos os 17 casos de uso. |
| **`2026-2/desenvolvimento-web/`** | `wireframes-projeto.md` e `wireframes/` | 18 telas prototipadas cobrindo todos os perfis de usuário. |
| **`2026-2/banco-de-dados/`** | `mer.md` & `script_banco_gestao_pesquisas.sql` | Diagrama ER, dicionário de dados, restrições `CHECK`/`UNIQUE` e 4 *triggers*. |
| **`2026-2/seguranca/`** | `analise-de-riscos.md` | Identificação, matriz P×I, controles OWASP e plano de mitigação de 27 riscos. |
| **`2026-2/seguranca/`** | `lgpd-e-anonimato.md` | Enquadramento legal, *k-anonimato*, política de retenção e modelo de TCLE. |
| **`evidencias/`** | `apresentacao.html` | Apresentação visual interativa da solução. |
| **`evidencias/`** | `validacao-do-projeto.md` | Relatório de validação cruzada e termo de aprovação da equipe. |

---

## 7. Como Implantar o Banco de Dados

1. Certifique-se de utilizar **MySQL 8.0.16+** ou **MariaDB 10.5+** (necessário para suporte completo às restrições `CHECK`).
2. Execute o arquivo `script_banco_gestao_pesquisas.sql` localizado em `2026-2/banco-de-dados/`.
3. Verifique a criação das 14 tabelas, dos perfis iniciais na tabela `perfis` e das 4 *triggers* ativas no schema.

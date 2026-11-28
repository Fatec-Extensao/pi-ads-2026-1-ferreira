# Documentação Final — Sistema Web para Gestão de Pesquisas por Questionários

> **Instituição:** Fatec Lins — Prof. Antonio Seabra  
> **Curso:** Tecnologia em Análise e Desenvolvimento de Sistemas (ADS)  
> **Disciplina:** Projeto Integrador I · 2026  
> **Equipe:** Anderson Clayton Pereira de Assis · Eduardo Matias Ferreira · Lucas Augusto Vieira Tridapali · Vitor Hugo Dias Mantovani · Neandro Bueno Vieira

---

## 1. Visão Geral do Projeto

### 1.1 Contextualização e Problema
Instituições de ensino e organizações enfrentam desafios recorrentes ao conduzir pesquisas internas de avaliação e clima: formulários genéricos sem segmentação por público, risco de respostas duplicadas por um mesmo indivíduo e, sobretudo, a desconfiança dos respondentes quanto ao sigilo de suas respostas.

### 1.2 Solução Proposta
O **Sistema Web para Gestão de Pesquisas por Questionários** resolve esse cenário por meio de uma plataforma institucional que separa rigorosamente a **gestão administrativa** da **coleta anônima de respostas**:

* **Anonimato garantido por arquitetura:** O participante não possui cadastro nem login. O acesso ocorre exclusivamente por uma **senha de uso único (token)** vinculada apenas à categoria do público (ex.: Alunos, Professores, Colaboradores).
* **Governança e fluxo de aprovação:** Pesquisas passam por revisão formal da Secretaria antes de serem liberadas para geração de senhas e coleta.
* **Análise agregada e conformidade (LGPD):** Relatórios e dashboards exibem apenas dados consolidados (percentuais e totais), com trilha de auditoria imutável para operações administrativas.

---

## 2. Perfis de Acesso (Atores)

O sistema contempla **6 perfis**, sendo 5 usuários internos autenticados (com controle baseado em perfil/RBAC) e 1 ator externo anônimo:

| Perfil | Tipo de Acesso | Responsabilidades Principais |
| :--- | :--- | :--- |
| **Administrador** | Login interno | Cadastra pesquisas, categorias e questionários; envia para análise; gera lotes de senhas anônimas; acompanha dashboard e gerencia usuários. |
| **Participante** | Senha anônima (8 caracteres) | Acessa o questionário da sua categoria e envia respostas de forma única e não rastreável. |
| **Secretaria** | Login interno | Revisa pesquisas em análise, aprova ou reprova (com justificativa obrigatória) e consulta relatórios institucionais. |
| **Analista de Dados** | Login interno (leitura) | Aplica filtros avançados, cruza resultados por categoria/pergunta e exporta bases anonimizadas (`CSV` e `XLSX`). |
| **Suporte Técnico** | Login interno | Monitora a disponibilidade dos serviços (API, banco, servidor) e gerencia chamados técnicos dentro do SLA. |
| **Auditor** | Login interno (leitura) | Audita logs imutáveis do sistema e emite relatórios de conformidade técnica e adequação à LGPD. |

---

## 3. Ciclo de Vida da Pesquisa

Toda pesquisa segue uma máquina de estados controlada por regras de negócio no banco de dados e na aplicação:

```text
[RASCUNHO] ──(Enviar p/ análise)──> [EM_ANALISE] ──(Secretaria aprova)──> [APROVADA] ──(Início vigência)──> [ATIVA] ──(Fim vigência)──> [ENCERRADA]
                                         │
                                  (Secretaria reprova
                                   com justificativa)
                                         ▼
                                    [REPROVADA] ──(Ajustes pelo Admin)──> [RASCUNHO]
```

1. **Rascunho:** Administrador cria a pesquisa, define período, cadastra categorias e monta os questionários.
2. **Em análise:** Envio bloqueado caso não exista ao menos uma categoria com questionário cadastrado. Secretaria é notificada.
3. **Aprovada / Reprovada:** A Secretaria valida o conteúdo. A aprovação libera a geração de lotes de senhas; a reprovação exige justificativa (mínimo 10 caracteres).
4. **Ativa:** Pesquisa vigente dentro do intervalo `data_inicio` e `data_fim`, aceitando respostas via tokens válidos.
5. **Encerrada:** Período finalizado; tokens não utilizados expiram automaticamente e os resultados ficam disponíveis para análise.

---

## 4. Arquitetura Técnica e Pilares de Segurança

### 4.1 Banco de Dados (Modelo Físico)
Projetado para **MySQL 8.0.16+ / MariaDB 10.5+**, composto por **14 tabelas**, restrições de integridade (`PK`, `FK` com `ON DELETE RESTRICT`, `UNIQUE`, `CHECK`) e **4 triggers** nativas:

* **Dissociação entre token e resposta:** Não há chave estrangeira ligando `tokens_anonimos` a `submissoes` ou `respostas`.
* **Granularidade temporal reduzida:** `tokens_anonimos.utilizado_em` armazena apenas `DATE` (sem hora/minuto/segundo), impedindo correlação temporal com `submissoes.criado_em`.
* **Integridade referencial composta:** `respostas` utiliza FK composta `(alternativa_id, questao_id)` para garantir que a alternativa escolhida pertença à questão respondida.
* **Triggers ativas no SGBD:**
  * `trg_logs_bloqueia_update` e `trg_logs_bloqueia_delete`: asseguram imutabilidade (WORM) em `logs_auditoria`.
  * `trg_tokens_uma_utilizacao`: impede reutilização de senha ou alteração do hash/lote após o uso.
  * `trg_respostas_mesma_categoria`: garante no banco que a questão respondida pertence à categoria da submissão.

### 4.2 Segurança da Informação e LGPD
* **Criptografia e Hash:** Senhas anônimas são exportadas uma única vez no momento da geração do lote e armazenadas apenas como **SHA-256**. Senhas de usuários internos utilizam **BCrypt** ou **Argon2**.
* **Privacidade na coleta:** Nenhum IP, cookie de sessão ou dado pessoal é gravado nas respostas. O limite de tentativas inválidas (3 tentativas em 15 minutos) é controlado em memória.
* **Rascunho local:** O progresso do participante é salvo apenas no navegador (`localStorage`), sem tráfego parcial no banco até o envio definitivo.

---

## 5. Organização do Repositório e Mapa de Artefatos

A documentação e os códigos do projeto estão organizados em quatro frentes principais:

```text
├── engenharia-software/
│   ├── requisitos-e-casos-de-uso.md       # 6 atores, 21 RFs, 44 RNFs, 17 UCs e Matriz de Rastreabilidade
│   ├── especificacao-classes.md           # 21 classes, 2 serviços, 3 enumerações e mapeamento ORM
│   ├── especificacao-sequencia.md         # 17 diagramas de sequência detalhados
│   ├── wireframes.md                      # 18 telas prototipadas cobrindo todos os perfis
│   ├── validacao-do-projeto.md            # Relatório de validação cruzada e rastreabilidade
│   └── modelagem-uml/                     # Arquivos fontes e imagens (.png) dos diagramas
│
├── banco-de-dados/
│   ├── mer-modelo-fisico.md               # Diagrama Mermaid (notação IE), dicionário de dados e triggers
│   └── script_banco_gestao_pesquisas.sql  # DDL completo, constraints, índices e triggers
│
├── seguranca/
│   └── analise-de-riscos.md               # Matriz de probabilidade x impacto (27 riscos) e mitigações
│
└── desenvolvimento-web/
    └── ...                                # Código-fonte da aplicação web
```

---

## 6. Guia Rápido de Implantação do Banco de Dados

Para instanciar a estrutura de dados em ambiente local ou de homologação:

1. Certifique-se de utilizar **MariaDB 10.5+** ou **MySQL 8.0.16+** (necessário para suporte pleno às restrições `CHECK`).
2. Crie o banco de dados com codificação UTF-8 completa:
   ```sql
   CREATE DATABASE gestao_pesquisas
     CHARACTER SET utf8mb4
     COLLATE utf8mb4_unicode_ci;
   USE gestao_pesquisas;
   ```
3. Execute o script físico localizado em `banco-de-dados/script_banco_gestao_pesquisas.sql` para criar as **14 tabelas**, **4 índices** e **4 triggers**.
4. Realize a carga inicial dos 5 perfis base na tabela `perfis` (`Administrador`, `Secretaria`, `Analista de Dados`, `Suporte Técnico`, `Auditor`) e do usuário administrador inicial.

---

## 7. Resumo dos Indicadores do Projeto

* **21 Requisitos Funcionais** (`RF01`–`RF21`) e **44 Requisitos Não Funcionais** (`RNF01`–`RNF44`) rastreados.
* **17 Casos de Uso** acompanhados de **17 Diagramas de Atividades** e **17 Diagramas de Sequência**.
* **18 Wireframes** cobrindo 100% da jornada dos 6 atores.
* **27 Riscos de Segurança** mapeados e mitigados conforme diretrizes da LGPD.

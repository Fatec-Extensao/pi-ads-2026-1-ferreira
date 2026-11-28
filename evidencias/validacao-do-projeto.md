# Validação do Projeto — Sistema Web para Gestão de Pesquisas por Questionários

> **Instituição:** Fatec Lins — Curso Superior de Tecnologia em Análise e Desenvolvimento de Sistemas (ADS)  
> **Disciplina:** Projeto Integrador · 2026  
> **Equipe:** Anderson Clayton Pereira de Assis · Eduardo Matias Ferreira · Lucas Augusto Vieira Tridapali · Vitor Hugo Dias Mantovani · Neandro Bueno Vieira  
> **Versão do Documento:** 1.1 · Status: **Validado para Entrega**

---

## 1. Objetivo da Validação

Este documento registra a verificação cruzada e a validação técnica entre todos os artefatos produzidos para o **Sistema Web para Gestão de Pesquisas por Questionários**. O objetivo é comprovar a coerência arquitetural, a rastreabilidade integral dos requisitos e a conformidade com as regras de negócio, segurança e privacidade (LGPD) entre:

1. **Engenharia de Software:** Requisitos Funcionais (RF), Requisitos Não Funcionais (RNF), Casos de Uso (UC), Matriz de Rastreabilidade, Diagrama de Classes e Diagramas de Sequência.
2. **Banco de Dados:** Modelo Entidade-Relacionamento (MER), Modelo Físico e Script SQL (`MySQL 8.0.16+` / `MariaDB 10.5+`).
3. **Compliance e Segurança da Informação:** Análise de Riscos (`analise-de-riscos.md`) e Diretrizes de Conformidade LGPD e Anonimato (`lgpd-e-anonimato.md`).
4. **Design e Prototipação (UI/UX):** Wireframes funcionais de fluxo (`wireframes-projeto.md`).

---

## 2. Resumo Quantitativo dos Artefatos Validados

| Camada / Disciplina | Artefato | Quantidade | Status |
| :--- | :--- | :---: | :---: |
| **Levantamento** | Atores / Perfis do Sistema | 6 | ✔ Validado |
| **Levantamento** | Requisitos Funcionais (`RF01`–`RF21`) | 21 | ✔ Validado |
| **Levantamento** | Requisitos Não Funcionais (`RNF01`–`RNF44`) | 44 | ✔ Validado |
| **Modelagem UML** | Casos de Uso (`UC-ADM`, `PAR`, `SEC`, `ANA`, `SUP`, `AUD`) | 17 | ✔ Validado |
| **Modelagem UML** | Diagramas de Sequência | 17 | ✔ Validado |
| **Modelagem UML** | Diagrama de Classes + Serviços + Enumerações | 21 classes · 2 serviços · 3 enums | ✔ Validado |
| **Banco de Dados** | Entidades / Tabelas Físicas | 14 | ✔ Validado |
| **Banco de Dados** | Triggers de Integridade e Imutabilidade | 4 | ✔ Validado |
| **Segurança e LGPD** | Riscos Mapeados e Mitigados (`R01`–`R27`) | 27 | ✔ Validado |
| **Prototipação** | Telas de Wireframes | 18 | ✔ Validado |

---

## 3. Validação de Cobertura e Rastreabilidade

### 3.1 Requisitos Funcionais × Casos de Uso × Banco de Dados × Wireframes

Todos os 21 requisitos funcionais possuem cobertura ponta a ponta, desde a interface (wireframe) até a persistência ou consulta no banco de dados:

| ID | Requisito Funcional | Caso(s) de Uso | Wireframe(s) | Tabela(s) / Serviço(s) | Status |
| :--- | :--- | :--- | :--- | :--- | :---: |
| **RF01** | Cadastrar pesquisas e gerenciar ciclo de status | `UC-ADM-01` | Página 11 | `pesquisas` | ✔ |
| **RF02** | Cadastrar categorias de participantes | `UC-ADM-02` | Página 10 | `categorias_participantes` | ✔ |
| **RF03** | Criar questionários por categoria | `UC-ADM-03` | Página 12 | `questoes` | ✔ |
| **RF04** | Cadastrar perguntas e alternativas (4 tipos) | `UC-ADM-03` | Página 12 | `questoes`, `alternativas` | ✔ |
| **RF05** | Gerar senhas anônimas por lote e categoria | `UC-ADM-04` | Página 15 | `lotes_senhas`, `tokens_anonimos` | ✔ |
| **RF06** | Exportar senhas no ato (apenas hash armazenado) | `UC-ADM-04` | Página 15 | `LoteSenha` (CSV/PDF) | ✔ |
| **RF07** | Aplicar questionários via senha anônima | `UC-PAR-01` | Página 05 | `tokens_anonimos`, `pesquisas` | ✔ |
| **RF08** | Gravar respostas em submissão sem vínculo com token | `UC-PAR-02` | Página 18 | `submissoes`, `respostas` | ✔ |
| **RF09** | Impedir reutilização de senhas anônimas | `UC-PAR-01`, `UC-PAR-02` | Páginas 05, 18 | `tokens_anonimos` (`trg_tokens_uma_utilizacao`) | ✔ |
| **RF10** | Monitorar participação em tempo real (dashboard) | `UC-ADM-07` | Página 04 | `DashboardService` | ✔ |
| **RF11** | Gerar relatórios estatísticos e comparativos | `UC-ADM-05`, `UC-SEC-02`, `UC-ANA-01` | Páginas 06, 07, 14 | `RelatorioService` | ✔ |
| **RF12** | Exportar resultados agregados (PDF, CSV, XLSX) | `UC-ADM-05`, `UC-SEC-02`, `UC-ANA-02` | Páginas 06, 13, 14 | `RelatorioService` | ✔ |
| **RF13** | Aprovar ou reprovar pesquisas com justificativa | `UC-SEC-01` | Página 08 | `pesquisas`, `notificacoes` | ✔ |
| **RF14** | Autenticar usuários internos e controlar perfis | `UC-ADM-01/06`, `SEC-01`, `ANA-01`, `SUP-02`, `AUD-02` | Páginas 03, 04 | `usuarios`, `perfis` | ✔ |
| **RF15** | Registrar trilha de auditoria imutável | `UC-ADM-01/06`, `UC-ANA-02`, `UC-AUD-01` | Página 09 | `logs_auditoria` | ✔ |
| **RF16** | Monitorar serviços e emitir alertas automáticos | `UC-SUP-01` | Página 16 | `logs_auditoria`, `notificacoes` | ✔ |
| **RF17** | Gerenciar chamados técnicos com SLA e histórico | `UC-SUP-02` | Página 17 | `chamados`, `chamados_historico` | ✔ |
| **RF18** | Gerar relatório de conformidade e LGPD | `UC-AUD-02` | Página 09 | `Auditor`, `logs_auditoria` | ✔ |
| **RF19** | Salvar rascunho localmente no navegador (`localStorage`) | `UC-PAR-02` | Página 18 | Armazenamento local (Client-side) | ✔ |
| **RF20** | Cadastrar, desativar e atribuir perfil a usuários | `UC-ADM-06` | Página 04 | `usuarios`, `perfis` | ✔ |
| **RF21** | Enviar pesquisa para análise e notificar Secretaria | `UC-ADM-01` | Página 11 | `pesquisas`, `notificacoes` | ✔ |

---

## 4. Validação Arquitetural, Segurança e LGPD

### 4.1 Garantia Estrutural de Anonimato (`RNF10`–`RNF15` · Art. 12 LGPD)
* **Dissociação física no banco:** Validado no MER, no Script SQL e em `lgpd-e-anonimato.md` que **não existe chave estrangeira ou qualquer relação** entre `tokens_anonimos` e `submissoes` / `respostas`.
* **Granularidade temporal reduzida:** O campo `tokens_anonimos.utilizado_em` utiliza o tipo `DATE` (apenas data, sem hora/minuto/segundo), impossibilitando o cruzamento temporal com `submissoes.criado_em` (`DATETIME`).
* **Ausência de metadados rastreáveis e *k-anonimato*:** Respostas são gravadas sem IP, cookies ou identificadores pessoais (`RNF11`, `RNF12`). O controle de força bruta (3 tentativas em 15 minutos, `RNF43`) ocorre exclusivamente em memória (cache), e relatórios aplicam tamanho mínimo de grupo (mínimo de 5 respondentes) para evitar re-identificação por inferência (`R09`).
* **Transparência e retenção:** Modelo de Aviso de Privacidade/TCLE validado antes do início do questionário e ciclos de retenção/expurgo definidos por tabela (Art. 15 e 16 da LGPD).

### 4.2 Integridade Garantida pelo Banco de Dados (`RNF24`, `RNF29`)
* **Restrições Referenciais:** Todas as chaves estrangeiras utilizam `ON DELETE RESTRICT ON UPDATE RESTRICT`, impedindo exclusão acidental de pesquisas, questões ou históricos em uso.
* **Chave Estrangeira Composta:** A tabela `respostas` referencia `alternativas(id, questao_id)`, garantindo no próprio SGBD que uma alternativa escolhida pertence obrigatoriamente à questão respondida.
* **Triggers Ativas:**
  * `trg_logs_bloqueia_update` e `trg_logs_bloqueia_delete`: garantem o padrão WORM (*Write Once, Read Many*) em `logs_auditoria` (mitigando `R21`).
  * `trg_tokens_uma_utilizacao`: impede reuso de senha e alteração retroativa de `token_hash` ou `lote_id` (mitigando `R13` e `R14`).
  * `trg_respostas_mesma_categoria`: valida no `BEFORE INSERT` que a questão respondida pertence à mesma categoria da submissão (mitigando `R18` e `R22`).

### 4.3 Análise de Riscos e Controles de Acesso (`RNF32`–`RNF44`)
* **Cobertura OWASP Top 10 e ISO/IEC 27005:** Todos os 27 riscos mapeados em `analise-de-riscos.md` (2 críticos iniciais, 16 altos, 8 moderados e 1 baixo) possuem plano de mitigação rastreado aos requisitos e controles do banco/aplicação.
* **Criptografia:** Senhas anônimas armazenadas exclusivamente como hash `SHA-256` (`VARCHAR(64)`); credenciais de usuários internos protegidas via `BCrypt` ou `Argon2` (`VARCHAR(255)`), com revogação imediata de acesso via `usuarios.ativo = FALSE` e plano de ação priorizado para MFA (`R19`), escape contra XSS (`R02`) e consultas parametrizadas (`R01`).

---

## 5. Registro de Alinhamento Entre Diagramas e Banco

| # | Escopo | Divergência Identificada | Resolução / Diretriz Adotada |
| :---: | :--- | :--- | :--- |
| **01** | `UC-PAR-02` (Sequência) | Criação do objeto `Submissao` antes de `validarObrigatorias()`. | Instanciar e persistir `Submissao` somente **dentro da transação atômica**, após validação bem-sucedida. |
| **02** | `Chamado` (Classes × Banco) | Banco possui `status`, `aberto_em`, `fechado_em` e `aberto_por`; classe omitia `existeDuplicado()`, `abrir()` e `fechar()`. | Sincronizar atributos e métodos na classe `Chamado` conforme o modelo físico e `seq-sup-02`. |
| **03** | `TokenAnonimo` (Classes × Banco) | Atributo `utilizadoEm` tipado como `LocalDateTime` na classe, mas `DATE` no banco. | Ajustar tipo na classe para `LocalDate`, preservando o requisito de anonimato (`RNF10`). |
| **04** | `RelatorioService` (Classes) | Assinatura `compararCategoria(p)` vs `compararCategorias(p)` na sequência, e visibilidade privada (`-`) em `porPergunta`. | Padronizar para `+ compararCategorias(p : Pesquisa)` e `+ porPergunta(p : Pesquisa)`. |
| **05** | Granularidade Temporal (`LGPD`) | Alinhamento da descrição de `submissoes.criado_em` (`DATETIME`) frente a `tokens_anonimos.utilizado_em` (`DATE`). | Documentado em `lgpd-e-anonimato.md` que o descasamento já impede correlação direta, com truncamento opcional na aplicação. |
| **06** | Notificações de Grupo | Tabela `notificacoes` aponta para um `usuario_id` individual, enquanto fluxos citam "Secretaria" ou "Plantão". | A camada de aplicação itera sobre os usuários ativos do perfil alvo e gera uma notificação individual por destinatário. |

---

## 6. Critérios de Aceitação Global (Checklist Final)

- [x] **Coerência de Modelo:** Todas as 14 tabelas do MER correspondem diretamente às entidades persistentes do Diagrama de Classes.
- [x] **Rastreabilidade Completa:** Nenhum caso de uso órfão; todos os 21 RFs estão mapeados na Matriz de Rastreabilidade.
- [x] **Segurança e LGPD:** Impossibilidade técnica de vincular um participante às suas respostas validada no banco, em `analise-de-riscos.md` e em `lgpd-e-anonimato.md`.
- [x] **Atomicidade:** Geração de lotes/tokens (`UC-ADM-04`) e envio de respostas/baixa de token (`UC-PAR-02`) projetados em transações atômicas.
- [x] **Auditoria:** Operações críticas de escrita e exportação registradas em `logs_auditoria` com proteção contra `UPDATE` e `DELETE`.

---

## 7. Termo de Validação da Equipe

Os integrantes abaixo atestam que os artefatos de Engenharia de Software, Banco de Dados, Prototipação e Segurança foram revisados em conjunto e encontram-se íntegros e prontos para a etapa de implementação e apresentação do **Projeto Integrador (Fatec Lins · 2026)**:

| Integrante | Papel / Contribuição Validada | Status |
| :--- | :--- | :---: |
| **Anderson Clayton Pereira de Assis** | Engenharia de Requisitos, Modelagem UML e Arquitetura | ✔ Aprovado |
| **Eduardo Matias Ferreira** | Banco de Dados (MER, Modelo Físico, SQL e Triggers) | ✔ Aprovado |
| **Lucas Augusto Vieira Tridapali** | Diagramas de Sequência, Classes e Regras de Negócio | ✔ Aprovado |
| **Vitor Hugo Dias Mantovani** | Segurança da Informação, LGPD e Análise de Riscos | ✔ Aprovado |
| **Neandro Bueno Vieira** | Prototipação (Wireframes), UI/UX e Rastreabilidade | ✔ Aprovado |
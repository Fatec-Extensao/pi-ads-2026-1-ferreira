# Conformidade com a LGPD e Garantia de Anonimato — Sistema Web para Gestão de Pesquisas por Questionários

> Projeto Integrador · ADS · Fatec Lins · 2026
> Versão 1.0 · novembro/2026

---

## Sumário

1. [Objetivo e escopo](#1-objetivo-e-escopo)
2. [Enquadramento legal (LGPD)](#2-enquadramento-legal-lgpd)
3. [Garantia técnica do anonimato e prevenção de coleta de PII](#3-garantia-técnica-do-anonimato-e-prevenção-de-coleta-de-pii)
4. [Mapeamento de dados por ator do sistema](#4-mapeamento-de-dados-por-ator-do-sistema)
5. [Política de retenção e exclusão de dados](#5-política-de-retenção-e-exclusão-de-dados)
6. [Modelo de Aviso de Privacidade e Termo de Consentimento (TCLE)](#6-modelo-de-aviso-de-privacidade-e-termo-de-consentimento-tcle)
7. [Direitos dos titulares e resposta a incidentes](#7-direitos-dos-titulares-e-resposta-a-incidentes)
8. [Referências](#8-referências)

---

## 1. Objetivo e escopo

Este documento estabelece as diretrizes técnicas, arquiteturais e operacionais para assegurar a conformidade do **Sistema Web para Gestão de Pesquisas por Questionários** com a **Lei Geral de Proteção de Dados Pessoais (Lei nº 13.709/2018 — LGPD)**.

O documento cobre:
- os mecanismos de **Privacy by Design** que impedem a coleta e o rastreamento de Dados Pessoais Identificáveis (PII) dos respondentes;
- a **política de retenção, arquivamento e eliminação segura** dos dados armazenados no banco de dados (`script_banco_gestao_pesquisas.sql`);
- o **modelo oficial de Aviso de Privacidade / Termo de Consentimento Livre e Esclarecido (TCLE)** exibido antes do preenchimento do questionário (UC-PAR-01 / UC-PAR-02).

---

## 2. Enquadramento legal (LGPD)

A arquitetura do sistema foi projetada para atender aos princípios do **Art. 6º** e às disposições sobre **dados anonimizados (Art. 12)** da Lei nº 13.709/2018:

| Princípio / Dispositivo | Aplicação no Sistema |
|---|---|
| **Anonimização (Art. 5º, XI e Art. 12)** | Dados anonimizados não são considerados dados pessoais pela LGPD, desde que o processo não possa ser revertido por meios razoáveis. O sistema desvincula totalmente a senha de acesso (`tokens_anonimos`) das respostas enviadas (`submissoes`). |
| **Finalidade e Adequação (Art. 6º, I e II)** | A coleta destina-se exclusivamente à avaliação institucional e à geração de indicadores estatísticos agregados, sem uso secundário ou comercial. |
| **Necessidade / Minimização (Art. 6º, III)** | Nenhum dado cadastral (nome, CPF, e-mail, RA ou matrícula) é solicitado ao participante (RNF11). |
| **Segurança e Prevenção (Art. 6º, VII e VIII)** | Uso de criptografia em trânsito (HTTPS/TLS), armazenamento apenas de hashes (`token_hash` e `senha_hash`), controle de acesso por perfil (RBAC) e logs imutáveis (RNF23, RNF29, RNF33). |
| **Transparência (Art. 6º, VI)** | Exibição obrigatória do Aviso de Privacidade/TCLE antes do início do questionário, informando objetivos, anonimato e prazo de guarda. |

---

## 3. Garantia técnica do anonimato e prevenção de coleta de PII

Para garantir que o sistema não colete Dados Pessoais Identificáveis (PII) dos participantes nem permita a re-identificação indireta (atendendo aos requisitos **RNF10 a RNF15** e mitigando o risco **R09**), são aplicados os seguintes controles:

### 3.1 Desvinculação arquitetural no banco de dados
- **Ausência de chave estrangeira:** Não existe qualquer relacionamento (`FOREIGN KEY`) ou coluna de ligação entre a tabela `tokens_anonimos` (que valida o acesso em UC-PAR-01) e as tabelas `submissoes` e `respostas` (gravadas em UC-PAR-02).
- **Lote sem destinatário nominal:** Na geração de senhas (UC-ADM-04 / `lotes_senhas`), o sistema gera códigos aleatórios vinculados apenas a uma `categoria_id` (ex.: *Docentes*, *Discentes*, *Técnico-Administrativos*), sem associar cada senha a um indivíduo específico.
- **Armazenamento irreversível da senha:** Apenas o resumo criptográfico (`token_hash`) é gravado no banco (RNF33). A senha em texto claro é exportada uma única vez no momento da geração e não permanece no servidor (RF06 / RNF32).

### 3.2 Supressão de metadados e rastreadores
- **Bloqueio de registro de IP e *User-Agent*:** A aplicação não coleta, não processa e não armazena endereço IP, geolocalização, impressão digital de navegador (*fingerprinting*) ou cookies de rastreamento nas rotas públicas de acesso e resposta (RNF12).
- **Logs do servidor web:** Nas rotas `/acessar-pesquisa` e `/responder-questionario`, o servidor HTTP/proxy reverso deve omitir ou anonimizar o endereço IP nos logs de acesso.
- **Descasamento da granularidade temporal:** A coluna `tokens_anonimos.utilizado_em` armazena exclusivamente a **data** (`DATE`), sem hora, minuto ou segundo, impossibilitando o cruzamento temporal direto com `submissoes.criado_em` (`DATETIME`). Como evolução opcional na camada de aplicação, recomenda-se truncar ou arredondar o timestamp de submissão para janelas de turno/dia.
- **Rascunho exclusivamente local:** O salvamento automático de rascunho durante o preenchimento (RF19) utiliza apenas o armazenamento local do navegador do participante (`localStorage` / `sessionStorage`), sem tráfego de dados parciais para o servidor.

### 3.3 Proteção contra re-identificação nos relatórios e respostas abertas
- **Tamanho mínimo de amostra (*k-anonimato*):** Os painéis de resultados (UC-ADM-05 e UC-ANA-01) e exportações (UC-ANA-02 / RNF14) bloqueiam a exibição de filtros ou cruzamentos cujos grupos possuam **menos de 5 respondentes**, evitando que respostas de categorias reduzidas sejam atribuídas a um indivíduo.
- **Prevenção de PII em questões abertas (`resposta_texto`):**
  - Antes de campos de texto livre, a interface exibe um alerta claro orientando o respondente a não inserir nomes, e-mails, telefones, matrículas ou relatos que identifiquem pessoas.
  - A aplicação executa verificação automatizada por expressões regulares (*Regex*) no momento do envio para alertar ou mascarar padrões evidentes de CPF, e-mail e telefone antes da persistência.

---

## 4. Mapeamento de dados por ator do sistema

| Ator / Categoria | Dados coletados | Contém PII? | Base legal (LGPD) | Finalidade |
|---|---|---|---|---|
| **Participante (Respondente)** | Senha anônima (validada via `token_hash`), respostas fechadas/escala e respostas abertas (`resposta_texto`). | **Não** (dado anonimizado — Art. 12) | Não aplicável (dado anonimizado) / Consentimento informado no TCLE | Coleta de percepção institucional e geração de estatísticas agregadas. |
| **Usuários Internos** *(Administrador, Secretaria, Analista, Auditor, Suporte)* | Nome completo, e-mail institucional, perfil de acesso e `senha_hash` (tabela `usuarios`). | **Sim** (dados cadastrais funcionais) | Execução de contrato / Legítimo interesse / Obrigação regulatória (Art. 7º, II, V e IX) | Autenticação, controle de permissões (RBAC) e responsabilização administrativa. |
| **Trilha de Auditoria (`logs_auditoria`)** | Identificador do usuário interno (`usuario_id`), ação executada, tabela afetada, data/hora e IP interno. *(Não registra ações de participantes).* | **Sim** (vinculado apenas a usuários internos) | Cumprimento de obrigação legal / Prevenção à fraude (Art. 7º, II e IX) | Rastreabilidade, auditoria de conformidade (UC-AUD-01/02) e integridade operacional (RNF29). |

---

## 5. Política de retenção e exclusão de dados

Em cumprimento ao **Art. 15 e Art. 16 da LGPD** (término do tratamento e eliminação dos dados), os registros do sistema seguem ciclos de vida definidos:

| Categoria de Dado / Tabela | Prazo de Retenção | Método de Exclusão / Destinação Final | Responsável |
|---|---|---|---|
| **Senhas anônimas (`tokens_anonimos` e `lotes_senhas`)** | **30 dias** após o encerramento da pesquisa (`data_fim`). | Exclusão definitiva (expurgo) dos registros de `tokens_anonimos` não utilizados e destruição dos hashes após a conciliação final. | Administrador / Rotina automatizada |
| **Respostas abertas brutas (`respostas.resposta_texto`)** | **12 meses** após a aprovação do relatório institucional final (UC-SEC-02). | Sanitização/anonimização definitiva ou exclusão dos textos brutos após a consolidação dos insights (UC-ANA-02), mantendo apenas os indicadores estatísticos agregados. | Administrador / Auditor (verificação) |
| **Respostas estruturadas e indicadores agregados (`submissoes`, `respostas` fechadas/escala)** | **5 anos** para fins de série histórica e avaliação institucional. | Mantidos de forma puramente estatística e anonimizada; após 5 anos, arquivamento histórico ou descarte seguro. | Secretaria / Administrador |
| **Rascunho local do formulário (navegador)** | Até o envio do questionário ou fechamento da aba/limpeza do navegador. | Remoção automática via script (`localStorage.removeItem`) imediatamente após a confirmação de envio em UC-PAR-02. | Aplicação Front-End |
| **Contas de usuários internos (`usuarios`)** | Enquanto durar o vínculo funcional do servidor/colaborador. | Desativação imediata (`ativo = FALSE` em UC-ADM-06 / RNF42) no desligamento, preservando o ID apenas para integridade histórica dos logs. | Administrador |
| **Logs de auditoria (`logs_auditoria`)** | **5 anos** (conforme requisito RNF29). | Armazenamento imutável (*append-only*, protegido por *triggers* de bloqueio de `UPDATE`/`DELETE`); expurgo seguro após o prazo legal. | Suporte Técnico / Auditor |
| **Backups do banco de dados** | Ciclos rotativos de **30 dias** (diários) e **12 meses** (mensais). | Sobrescrita criptografada e destruição segura das mídias/snapshots expirados (RNF19 / RNF20). | Suporte Técnico |

---

## 6. Modelo de Aviso de Privacidade e Termo de Consentimento (TCLE)

O texto abaixo deve ser apresentado ao respondente na tela inicial da pesquisa (após a validação da senha em `acessar-pesquisa.html` e antes da exibição das perguntas em `responder-questionario.html`), exigindo a marcação da caixa de aceite para habilitar o início do questionário:

---

> ### Aviso de Privacidade e Termo de Consentimento Livre e Esclarecido (TCLE)
>
> **Título da Pesquisa:** `[Nome da Pesquisa Institucional]`  
> **Instituição Responsável:** `[Nome da Instituição / Fatec Lins]`  
> **Contato do Encarregado de Dados (DPO):** `[dpo@instituicao.edu.br]`
>
> **1. Objetivo da Pesquisa**  
> Você está sendo convidado(a) a participar desta pesquisa institucional, cujo objetivo é coletar percepções e sugestões para a melhoria contínua dos serviços, processos e ambiente acadêmico/organizacional.
>
> **2. Garantia Total de Anonimato (LGPD)**  
> Sua participação é **100% anônima**. Em conformidade com a Lei Geral de Proteção de Dados (Lei nº 13.709/2018):
> - **Nenhum dado pessoal é coletado:** não solicitamos seu nome, CPF, e-mail, número de matrícula ou telefone.
> - **Sem rastreamento técnico:** o sistema não registra seu endereço IP, localização ou identificadores do seu dispositivo.
> - **Desvinculação da senha:** a senha utilizada para acessar esta tela serve apenas para validar que você pertence à categoria convidada e impedir respostas duplicadas. No momento em que você envia o questionário, a senha é invalidada e **não existe qualquer vínculo técnico** entre ela e as respostas gravadas no banco de dados.
>
> **3. Cuidados nas Questões Abertas**  
> Nos campos de resposta livre, **não escreva seu nome, documentos ou informações que possam identificar você ou terceiros**.
>
> **4. Voluntariedade e Uso dos Dados**  
> Sua participação é voluntária. Você pode interromper o preenchimento a qualquer momento antes de clicar em *"Enviar Respostas"* sem qualquer prejuízo (nenhum dado é enviado ao servidor antes da submissão final). Os resultados serão divulgados exclusivamente em formato estatístico consolidado, respeitando um número mínimo de respondentes por grupo para evitar qualquer identificação indireta.
>
> **5. Retenção e Segurança**  
> As respostas anonimizadas ficarão armazenadas em ambiente protegido com criptografia pelo período necessário à consolidação dos relatórios institucionais (até 12 meses para textos abertos e até 5 anos para séries históricas estatísticas), sendo descartadas ao término desse prazo.
>
> ---
> - [ ] **Declaro que li e compreendi as informações acima, estou ciente da garantia de anonimato e concordo em participar voluntariamente desta pesquisa.**
>
> `[ Botão: Iniciar Questionário ]`

---

## 7. Direitos dos titulares e resposta a incidentes

- **Exercício de direitos (Art. 18 da LGPD):**
  - *Participantes:* Como os dados são anonimizados na origem (Art. 12), não é possível identificar, alterar ou excluir uma resposta individual após o envio, fato informado previamente no TCLE. Dúvidas ou solicitações sobre o tratamento institucional podem ser encaminhadas ao Encarregado (DPO).
  - *Usuários internos:* Podem solicitar confirmação de tratamento, acesso e correção de seus dados cadastrais junto ao Administrador ou ao DPO.
- **Verificação periódica:** O perfil **Auditor** (UC-AUD-01 e UC-AUD-02 / RF18) emite relatórios periódicos de conformidade para atestar a ausência de vínculos entre tokens e submissões, o cumprimento do tamanho mínimo de amostra e a integridade dos logs.
- **Resposta a incidentes:** Em caso de suspeita de vazamento ou acesso não autorizado, o Suporte Técnico e o Administrador devem isolar o componente afetado, preservar os logs de auditoria e notificar o Encarregado (DPO) para avaliação e eventual comunicação à Autoridade Nacional de Proteção de Dados (ANPD), conforme o Art. 48 da LGPD.

---

## 8. Referências

- **BRASIL.** Lei nº 13.709, de 14 de agosto de 2018 — *Lei Geral de Proteção de Dados Pessoais (LGPD)*.
- **ANPD.** *Guia Orientativo para Definições dos Agentes de Tratamento de Dados Pessoais e do Encarregado*.
- **ISO/IEC 27701** — *Gestão da Privacidade da Informação* (extensão da ISO/IEC 27001 e 27002).
- **OWASP Top 10 Privacy Risks** — boas práticas de minimização e proteção de dados em aplicações web.
- Artefatos do projeto: *Requisitos e Casos de Uso* (`RF01–RF21`, `RNF01–RNF44`), `script_banco_gestao_pesquisas.sql` e `analise-de-riscos.md`.
conformidade-lgpd.md
Exibindo conformidade-lgpd.md…
# Análise de Riscos — Sistema Web para Gestão de Pesquisas por Questionários

> Projeto Integrador · ADS · Fatec Lins · 2026
> Versão 1.1 · novembro/2026

---

## Sumário

1. [Objetivo e escopo](#1-objetivo-e-escopo)
2. [Metodologia](#2-metodologia)
3. [Ativos e fronteiras de confiança](#3-ativos-e-fronteiras-de-confiança)
4. [Registro de riscos](#4-registro-de-riscos)
5. [Matriz de risco (probabilidade × impacto)](#5-matriz-de-risco-probabilidade--impacto)
6. [Riscos e medidas de mitigação](#6-riscos-e-medidas-de-mitigação)
7. [Controles já presentes no modelo e no script SQL](#7-controles-já-presentes-no-modelo-e-no-script-sql)
8. [Plano de ação priorizado](#8-plano-de-ação-priorizado)
9. [Monitoramento e revisão](#9-monitoramento-e-revisão)
10. [Premissas, limitações e referências](#10-premissas-limitações-e-referências)

---

## 1. Objetivo e escopo

Este documento identifica os riscos de segurança do sistema, classifica cada um por **probabilidade** e **impacto** (matriz de risco) e define as **medidas de mitigação**.

A análise foi feita sobre os artefatos de projeto:

- requisitos funcionais e não funcionais (RF01–RF21 e RNF01–RNF44);
- os 17 casos de uso e seus diagramas de sequência;
- o diagrama de classes, o MER e o modelo físico;
- o script SQL (`script_banco_gestao_pesquisas.sql`).

O foco é o que mais importa para este sistema: o **anonimato dos participantes**, a **integridade dos resultados** e o **controle de acesso** das contas internas.

**Fora do escopo:** análise de código-fonte (o sistema ainda não foi implementado), testes de invasão e segurança física do ambiente de hospedagem.

---

## 2. Metodologia

O nível de cada risco é calculado por **Probabilidade (P) × Impacto (I)**, em escalas de 1 a 5.

### 2.1 Escala de probabilidade

| P | Nível | Critério |
|:-:|---|---|
| 1 | Muito baixa | Exige condições muito improváveis ou acesso privilegiado já comprometido. |
| 2 | Baixa | Possível, mas exige esforço, conhecimento ou combinação de falhas. |
| 3 | Média | Pode ocorrer durante a vida do sistema; ataque conhecido e acessível. |
| 4 | Alta | Provável: superfície muito exposta ou ataque comum e automatizável. |
| 5 | Muito alta | Praticamente certo de ocorrer sem controles. |

### 2.2 Escala de impacto

| I | Nível | Critério |
|:-:|---|---|
| 1 | Insignificante | Desconforto sem efeito sobre dados ou resultados. |
| 2 | Menor | Retrabalho ou perda isolada, sem efeito sobre a pesquisa. |
| 3 | Moderado | Compromete uma pesquisa ou parte dos resultados; recuperável. |
| 4 | Alto | Compromete várias pesquisas, a confiança dos participantes ou a operação por dias. |
| 5 | Crítico | Quebra do anonimato, vazamento em massa, perda irrecuperável de dados ou descumprimento grave da LGPD. |

### 2.3 Níveis de risco

| Pontuação (P × I) | Nível | Tratamento esperado |
|:-:|---|---|
| 1 a 4 | 🟢 **Baixo** | Aceitar e monitorar. |
| 5 a 9 | 🟡 **Moderado** | Mitigar no ciclo normal de desenvolvimento. |
| 10 a 15 | 🟠 **Alto** | Mitigar com prioridade; tratar antes da homologação. |
| 16 a 25 | 🔴 **Crítico** | Tratar imediatamente; não liberar o sistema sem mitigação. |

### 2.4 Estratégias de tratamento

**Mitigar** (reduzir probabilidade ou impacto), **Aceitar** (risco residual tolerável), **Transferir** (ex.: serviço gerenciado/seguro) e **Evitar** (eliminar a causa). O **risco residual** é a estimativa após aplicar as medidas.

---

## 3. Ativos e fronteiras de confiança

### 3.1 Ativos a proteger

| Ativo | Por que importa |
|---|---|
| Anonimato dos respondentes | É a promessa central do sistema (RNF10 a RNF15) e requisito da LGPD. |
| Respostas e resultados | Base das decisões institucionais; precisam ser confidenciais e íntegras. |
| Senhas anônimas (tokens e lotes) | Controlam quem pode responder; cada uma vale uma única resposta. |
| Contas de usuários internos | O Administrador controla pesquisas, senhas e usuários; a Secretaria aprova. |
| Trilha de auditoria (`logs_auditoria`) | Prova de quem fez o quê; precisa ser imutável. |
| Disponibilidade do sistema | A pesquisa tem prazo (`data_inicio` e `data_fim`); indisponibilidade invalida a coleta. |

### 3.2 Fronteiras de confiança

```text
 Internet ──► [ Participante anônimo ]   (sem conta; só senha; público e mais exposto)
 Internet ──► [ Usuários internos ]      (login: Administrador, Secretaria, Analista, Suporte, Auditor)
                      │
              Aplicação web (backend)  ──►  Banco de dados  ──►  Backups
                      │
               Exportações (CSV/PDF/XLSX) ──► ambientes externos (Excel, Power BI)
```

As entradas mais expostas são a **tela de senha** (UC-PAR-01), o **formulário de respostas** (UC-PAR-02, inclusive texto livre), o **login** dos usuários internos e as **exportações** (UC-ADM-04 e UC-ANA-02).

---

## 4. Registro de riscos

**Legenda de nível:** 🟢 Baixo · 🟡 Moderado · 🟠 Alto · 🔴 Crítico. **Residual** = P × I estimado após as mitigações da seção 6.

| ID | Risco | Categoria | P | I | P×I | Nível | Residual |
|---|---|---|:-:|:-:|:-:|:-:|:-:|
| R01 | Injeção de SQL | Ataque à aplicação | 3 | 5 | 15 | 🟠 Alto | 5 🟡 |
| R02 | XSS armazenado (respostas e textos exibidos a usuários internos) | Ataque à aplicação | 4 | 4 | 16 | 🔴 Crítico | 8 🟡 |
| R03 | Quebra de controle de acesso / escalonamento de privilégios | Ataque à aplicação | 3 | 5 | 15 | 🟠 Alto | 5 🟡 |
| R04 | Sequestro de sessão e CSRF em funções administrativas | Ataque à aplicação | 3 | 4 | 12 | 🟠 Alto | 8 🟡 |
| R05 | Injeção de fórmulas em CSV/Excel nas exportações | Ataque à aplicação | 3 | 3 | 9 | 🟡 Moderado | 3 🟢 |
| R06 | Dependências vulneráveis e configuração insegura | Ataque à aplicação | 3 | 4 | 12 | 🟠 Alto | 8 🟡 |
| R07 | Vazamento de segredos (credenciais, chaves, `.env` no Git) | Ataque à aplicação | 3 | 5 | 15 | 🟠 Alto | 5 🟡 |
| R08 | Interceptação de dados em trânsito (sem HTTPS/TLS) | Ataque à aplicação | 2 | 5 | 10 | 🟠 Alto | 5 🟡 |
| R09 | Quebra do anonimato por correlação e amostra pequena | Anonimato | 3 | 5 | 15 | 🟠 Alto | 8 🟡 |
| R10 | Vazamento de respostas (banco, backups, exportações) | Confidencialidade | 3 | 5 | 15 | 🟠 Alto | 5 🟡 |
| R11 | Descumprimento da LGPD | Conformidade | 3 | 4 | 12 | 🟠 Alto | 6 🟡 |
| R12 | Acesso privilegiado indevido (DBA, suporte, infraestrutura) | Confidencialidade | 2 | 5 | 10 | 🟠 Alto | 5 🟡 |
| R13 | Reuso de senha por requisições simultâneas (condição de corrida) | Fraude de preenchimento | 3 | 4 | 12 | 🟠 Alto | 4 🟢 |
| R14 | Compartilhamento ou venda de senhas | Fraude de preenchimento | 4 | 3 | 12 | 🟠 Alto | 6 🟡 |
| R15 | Vazamento do arquivo de lote de senhas | Fraude de preenchimento | 3 | 4 | 12 | 🟠 Alto | 6 🟡 |
| R16 | Força bruta e adivinhação de senhas anônimas | Fraude de preenchimento | 2 | 4 | 8 | 🟡 Moderado | 4 🟢 |
| R17 | Hash fraco das senhas anônimas (SHA-256 sem segredo, 8 caracteres) | Fraude de preenchimento | 2 | 4 | 8 | 🟡 Moderado | 3 🟢 |
| R18 | Submissão inválida que burla a validação do navegador | Integridade | 3 | 3 | 9 | 🟡 Moderado | 3 🟢 |
| R19 | Comprometimento de credenciais de usuários internos | Contas e privilégios | 4 | 5 | 20 | 🔴 Crítico | 10 🟠 |
| R20 | Fraude interna na aprovação ou na alteração de pesquisas | Contas e privilégios | 2 | 4 | 8 | 🟡 Moderado | 4 🟢 |
| R21 | Adulteração ou apagamento de logs de auditoria | Contas e privilégios | 2 | 4 | 8 | 🟡 Moderado | 4 🟢 |
| R22 | Manipulação direta dos resultados no banco | Integridade | 2 | 5 | 10 | 🟠 Alto | 5 🟡 |
| R23 | Negação de serviço (DoS/DDoS) e picos de acesso | Disponibilidade | 3 | 4 | 12 | 🟠 Alto | 6 🟡 |
| R24 | Perda de dados (falha, ransomware, exclusão acidental) | Disponibilidade | 2 | 5 | 10 | 🟠 Alto | 5 🟡 |
| R25 | Operação em várias etapas interrompida (sem transação) | Integridade | 3 | 3 | 9 | 🟡 Moderado | 3 🟢 |
| R26 | Pesquisa aplicada fora das regras (sem aprovação ou fora do período) | Integridade | 2 | 3 | 6 | 🟡 Moderado | 3 🟢 |
| R27 | Perda do rascunho salvo no navegador do participante | Usabilidade | 3 | 1 | 3 | 🟢 Baixo | 3 🟢 |

**Resumo:** 2 riscos críticos (R02 e R19), 16 altos, 8 moderados e 1 baixo.
Após as mitigações, o único risco que permanece alto é o **R19** (credenciais de usuários internos), porque depende também do comportamento das pessoas; ele exige monitoramento contínuo.

---

## 5. Matriz de risco (probabilidade × impacto)

Cada célula mostra a cor do nível (P × I) e os riscos que caem nela. As linhas vão da probabilidade mais alta (5) para a mais baixa (1).

| Probabilidade \ Impacto | 1 Insignificante | 2 Menor | 3 Moderado | 4 Alto | 5 Crítico |
|---|:-:|:-:|:-:|:-:|:-:|
| **5 Muito alta** | 🟡 | 🟠 | 🟠 | 🔴 | 🔴 |
| **4 Alta** | 🟢 | 🟡 | 🟠 **R14** | 🔴 **R02** | 🔴 **R19** |
| **3 Média** | 🟢 **R27** | 🟡 | 🟡 **R05 R18 R25** | 🟠 **R04 R06 R11 R13 R15 R23** | 🟠 **R01 R03 R07 R09 R10** |
| **2 Baixa** | 🟢 | 🟢 | 🟡 **R26** | 🟡 **R16 R17 R20 R21** | 🟠 **R08 R12 R22 R24** |
| **1 Muito baixa** | 🟢 | 🟢 | 🟢 | 🟢 | 🟡 |

Matriz após as mitigações (risco residual):

| Probabilidade \ Impacto | 1 Insignificante | 2 Menor | 3 Moderado | 4 Alto | 5 Crítico |
|---|:-:|:-:|:-:|:-:|:-:|
| **5 Muito alta** | 🟡 | 🟠 | 🟠 | 🔴 | 🔴 |
| **4 Alta** | 🟢 | 🟡 | 🟠 | 🔴 | 🔴 |
| **3 Média** | 🟢 **R27** | 🟡 **R14 R15** | 🟡 | 🟡 | 🟠 |
| **2 Baixa** | 🟢 | 🟢 | 🟡 **R11 R23** | 🟡 **R02 R04 R06 R09** | 🟠 **R19** |
| **1 Muito baixa** | 🟢 | 🟢 | 🟢 **R05 R17 R18 R25 R26** | 🟢 **R13 R16 R20 R21** | 🟡 **R01 R03 R07 R08 R10 R12 R22 R24** |

---

## 6. Riscos e medidas de mitigação

Cada risco indica o cenário no sistema, as medidas (preventivas, detectivas e corretivas), o que o projeto **já prevê** e o tratamento. As siglas RF, RNF, UC e os nomes de tabela referem-se aos documentos do projeto.

### 6.1 Ataques à aplicação

#### R01 — Injeção de SQL

- **Nível:** P3 × I5 = **15 🟠 Alto** · residual 1 × 5 = 5 🟡 · OWASP A03:2021
- **Cenário:** um atacante envia comandos SQL pelo campo de senha (UC-PAR-01), pelo login, pelos filtros de relatório (pesquisa, período, categoria e pergunta nos UC-ADM-05 e UC-ANA-01) ou por qualquer campo de busca. O resultado seria ler ou alterar respostas, hashes e usuários.
- **Mitigação:**
  - Usar **somente consultas parametrizadas** (PDO/Eloquent, JPA ou equivalente); nunca concatenar texto em SQL.
  - Validar entrada por tipo, tamanho e lista de valores permitidos (filtros de período, categoria e pergunta).
  - Conta do banco da aplicação com **privilégio mínimo**: sem `DROP`, `ALTER`, `TRUNCATE`, `GRANT`; sem `UPDATE` e `DELETE` em `respostas`, `submissoes` e `logs_auditoria`.
  - Mensagens de erro genéricas ao usuário (sem expor SQL nem estrutura do banco).
  - Análise estática de código (SAST) e testes dinâmicos (DAST, como o OWASP ZAP) no pipeline; testes automatizados com payloads de injeção.
- **Já previsto no projeto:** RNF27 (validação de entrada) e RNF38 (acesso ao banco protegido).
- **Tratamento:** Mitigar · **Responsável:** Desenvolvimento

#### R02 — XSS armazenado

- **Nível:** P4 × I4 = **16 🔴 Crítico** · residual 2 × 4 = 8 🟡 · OWASP A03:2021
- **Cenário:** o participante anônimo escreve um script em uma resposta aberta (`resposta_texto`). O texto é gravado e executado quando um Administrador, Secretaria ou Analista abre o relatório, o que permite roubar a sessão de uma conta com privilégio. O mesmo vale para título e descrição de pesquisas, texto de questões e alternativas.
- **Mitigação:**
  - **Codificar a saída** (escape) em todas as telas; nunca renderizar HTML vindo de respostas.
  - Cabeçalho **Content-Security-Policy** restritivo (sem scripts inline) e `X-Content-Type-Options: nosniff`.
  - Cookies de sessão com `HttpOnly`, `Secure` e `SameSite`.
  - Limitar o tamanho de `resposta_texto` (ex.: 2.000 caracteres) e rejeitar caracteres de controle.
  - Em bibliotecas de gráficos, usar apenas modos que tratam o texto como texto.
- **Já previsto no projeto:** RNF27 (XSS).
- **Tratamento:** Mitigar · **Responsável:** Desenvolvimento

#### R03 — Quebra de controle de acesso

- **Nível:** P3 × I5 = **15 🟠 Alto** · residual 1 × 5 = 5 🟡 · OWASP A01:2021
- **Cenário:** um Analista (somente leitura) chama uma função administrativa pela URL; um usuário altera um identificador (`/pesquisas/12`) para ver dados de outra pesquisa; a validação existe só na tela e não no servidor.
- **Mitigação:**
  - Validar **permissões no backend em toda requisição** (negar por padrão), usando `Usuario.temPermissao()` e `Perfil.getPermissoes()`.
  - Verificar a **propriedade** do recurso (pesquisa, categoria, lote) antes de ler ou alterar.
  - Matriz de permissões por perfil e **testes automatizados de autorização** por perfil.
  - Participante acessa só o questionário da categoria da sua senha (RNF44).
  - Registrar tentativas de acesso negado no log de auditoria.
- **Já previsto no projeto:** RNF36 a RNF40 (autorização, menor privilégio, validação no frontend e no backend).
- **Tratamento:** Mitigar · **Responsável:** Desenvolvimento

#### R04 — Sequestro de sessão e CSRF

- **Nível:** P3 × I4 = **12 🟠 Alto** · residual 2 × 4 = 8 🟡 · OWASP A01 e A07:2021
- **Cenário:** um site malicioso faz o navegador de um Administrador logado enviar uma ação (aprovar pesquisa, gerar lote, desativar usuário); ou uma sessão é roubada e reutilizada.
- **Mitigação:**
  - **Token anti-CSRF** em todos os formulários e requisições que alteram dados; `SameSite=Lax` ou `Strict`.
  - Sessão com expiração por inatividade (UC-ADM-01, fluxo FA3) e renovação do identificador após o login.
  - **Reautenticação** para operações críticas (gerar lote, desativar usuário, aprovar ou reprovar).
  - Bloquear acessos simultâneos indevidos com a mesma conta (RNF41).
- **Tratamento:** Mitigar · **Responsável:** Desenvolvimento

#### R05 — Injeção de fórmulas em CSV/Excel

- **Nível:** P3 × I3 = **9 🟡 Moderado** · residual 1 × 3 = 3 🟢
- **Cenário:** uma resposta aberta começa com `=`, `+`, `-` ou `@` (ex.: `=HYPERLINK(...)`). Quando o Analista exporta (UC-ANA-02, RF12) e abre no Excel ou no Power BI, a fórmula é executada.
- **Mitigação:** ao exportar, prefixar com apóstrofo (`'`) os textos que começam por esses caracteres; preferir XLSX com células tipadas como texto; manter a anonimização obrigatória (RNF14) e o registro da exportação no log.
- **Tratamento:** Mitigar · **Responsável:** Desenvolvimento

#### R06 — Dependências vulneráveis e configuração insegura

- **Nível:** P3 × I4 = **12 🟠 Alto** · residual 2 × 4 = 8 🟡 · OWASP A05 e A06:2021
- **Cenário:** uso de versões antigas do framework (Laravel, Node.js, Spring Boot) ou de bibliotecas com falhas conhecidas; modo de depuração ativo em produção; portas do banco expostas; imagens Docker desatualizadas.
- **Mitigação:**
  - Verificação automática de dependências (`composer audit`, `npm audit`, Dependabot) e atualização regular.
  - Desativar depuração e páginas de erro detalhadas em produção.
  - **Hardening**: serviços mínimos, banco acessível só pela aplicação, cabeçalhos de segurança, imagens mínimas e sem usuário root.
  - Separar ambientes (desenvolvimento, homologação e produção) com credenciais diferentes.
- **Tratamento:** Mitigar · **Responsável:** Desenvolvimento e Suporte Técnico

#### R07 — Vazamento de segredos

- **Nível:** P3 × I5 = **15 🟠 Alto** · residual 1 × 5 = 5 🟡 · OWASP A05:2021
- **Cenário:** senha do banco, chave de HMAC ou chave AES enviadas por engano ao GitHub (arquivo `.env`, configuração, `docker-compose`); o repositório é compartilhado entre vários alunos.
- **Mitigação:**
  - Segredos só em **variáveis de ambiente** ou cofre; `.env` no `.gitignore`; arquivo `.env.example` sem valores reais.
  - Ativar *secret scanning* do GitHub ou o `gitleaks` no pipeline.
  - Se um segredo vazar: **rotacionar imediatamente** e limpar o histórico do Git.
  - Credenciais diferentes por ambiente e com privilégio mínimo.
- **Tratamento:** Mitigar · **Responsável:** Desenvolvimento

#### R08 — Interceptação de dados em trânsito

- **Nível:** P2 × I5 = **10 🟠 Alto** · residual 1 × 5 = 5 🟡 · OWASP A02:2021
- **Cenário:** acesso por HTTP (rede pública ou da instituição) expõe respostas, senhas anônimas e cookies de sessão.
- **Mitigação:** HTTPS/TLS 1.2 ou superior em **todas** as páginas, redirecionamento de HTTP para HTTPS e **HSTS**; cookies `Secure`; TLS também entre a aplicação e o banco.
- **Já previsto no projeto:** RNF23 (HTTPS/TLS).
- **Tratamento:** Mitigar · **Responsável:** Suporte Técnico

### 6.2 Anonimato e confidencialidade

#### R09 — Quebra do anonimato por correlação e amostra pequena

- **Nível:** P3 × I5 = **15 🟠 Alto** · residual 2 × 4 = 8 🟡
- **Cenário:** mesmo sem ligação entre resposta e senha, um atacante ou analista pode **re-identificar** pessoas por inferência:
  - uma categoria pequena (ex.: 3 professores) ou um cruzamento de perguntas (UC-ANA-01) cria grupos tão pequenos que a resposta fica evidente;
  - o horário de `submissoes.criado_em` (`DATETIME`) combinado com o **log de acesso do servidor web** (IP + horário) liga uma submissão a um endereço;
  - respostas abertas trazem nome, CPF ou e-mail digitados pelo participante;
  - identificadores sequenciais (`AUTO_INCREMENT`) preservam a ordem em que as pessoas responderam.
- **Mitigação:**
  - **Tamanho mínimo de grupo** em relatórios e cruzamentos (ex.: não exibir resultados de grupos com menos de 5 submissões).
  - **Descasamento temporal:** manter `tokens_anonimos.utilizado_em` apenas com **data** (`DATE`, sem hora), e na camada de aplicação truncar ou arredondar o timestamp de `submissoes.criado_em` (`DATETIME`) para janelas de turno/dia.
  - Não registrar IP, cookies ou identificadores de participantes (RNF12), **inclusive nos logs do servidor web e do proxy** nas rotas de resposta; quando inevitável, anonimizar o IP e manter retenção curta.
  - Aviso na tela de resposta aberta: "não informe dados pessoais"; detecção simples de padrões (CPF, e-mail) para alertar ou mascarar.
  - Avaliar identificadores não sequenciais (UUID) em `submissoes` e `respostas`.
  - Manter a regra de **não haver associação** entre `submissoes` e `tokens_anonimos` (já no modelo).
- **Já previsto no projeto:** RNF10 a RNF15; `utilizado_em` só com data (`DATE`); nenhuma chave entre submissão e senha.
- **Tratamento:** Mitigar · **Responsável:** Desenvolvimento e Auditor (verificação)

#### R10 — Vazamento de respostas

- **Nível:** P3 × I5 = **15 🟠 Alto** · residual 1 × 5 = 5 🟡 · OWASP A02:2021
- **Cenário:** cópia indevida do banco, de um backup, de um dump em máquina de desenvolvimento ou de uma exportação CSV/PDF/XLSX enviada por e-mail ou guardada em pasta aberta.
- **Mitigação:**
  - Banco **sem porta exposta** à internet; acesso só pelo servidor da aplicação.
  - **Backups criptografados** e com acesso restrito; criptografia em repouso (AES-256) para dados sensíveis.
  - Exportações **anonimizadas** (RNF14), com link de download temporário e registro de quem exportou e quando (UC-ANA-02).
  - Nunca usar dados reais em desenvolvimento ou testes (usar dados fictícios).
  - Revisão periódica de quem tem acesso a relatórios e exportações.
- **Já previsto no projeto:** RNF13, RNF14, RNF32 a RNF35.
- **Tratamento:** Mitigar · **Responsável:** Desenvolvimento e Suporte Técnico

#### R11 — Descumprimento da LGPD

- **Nível:** P3 × I4 = **12 🟠 Alto** · residual 2 × 3 = 6 🟡
- **Cenário:** coleta além do necessário (IP de participantes), dados pessoais em respostas abertas, retenção sem prazo definido, falta de aviso de privacidade ou de encarregado (DPO) identificado.
- **Mitigação:**
  - **Minimização**: coletar só o necessário; nenhum dado pessoal do participante (RNF11).
  - Aviso de privacidade antes da pesquisa, informando finalidade, anonimato e tempo de guarda.
  - **Política de retenção** e descarte de respostas, tokens, logs e backups.
  - Relatório de conformidade periódico pelo Auditor (UC-AUD-02) e identificação do encarregado.
  - Procedimento de resposta a incidentes (comunicação à ANPD e aos titulares, quando aplicável).
- **Já previsto no projeto:** RNF11, RNF12, RF18 (relatório de conformidade).
- **Tratamento:** Mitigar · **Responsável:** Equipe do projeto e Auditor

#### R12 — Acesso privilegiado indevido

- **Nível:** P2 × I5 = **10 🟠 Alto** · residual 1 × 5 = 5 🟡
- **Cenário:** um administrador de banco, o Suporte Técnico ou alguém da infraestrutura lê ou copia respostas, ou altera dados, por curiosidade ou má-fé.
- **Mitigação:**
  - Contas **nominais** (sem usuário compartilhado) e **MFA** para acesso à infraestrutura e ao banco.
  - Separar funções: o Suporte Técnico trabalha por chamados (UC-SUP-02) e **não** tem acesso a respostas; usar dados mascarados para reproduzir erros.
  - Registrar o acesso direto ao banco (auditoria do SGBD) e revisar periodicamente.
  - Acesso de emergência com aprovação e registro.
- **Já previsto no projeto:** RNF35, RNF37 e RNF40 (privilégio mínimo; acesso por perfil e por operação).
- **Tratamento:** Mitigar · **Responsável:** Suporte Técnico e Auditor

### 6.3 Fraude de preenchimento

#### R13 — Reuso de senha por requisições simultâneas

- **Nível:** P3 × I4 = **12 🟠 Alto** · residual 1 × 4 = 4 🟢 · OWASP A04:2021
- **Cenário:** duas requisições com a **mesma senha** chegam quase ao mesmo tempo. Ambas leem "senha disponível" (`estaUtilizado()`) antes de qualquer uma marcá-la como utilizada, e as duas gravam respostas.
- **Mitigação:**
  - **Transação única** para criar a submissão, gravar as respostas e marcar a senha como utilizada (RNF25).
  - Reservar a senha de forma atômica antes de gravar: `UPDATE tokens_anonimos SET utilizado_em = CURDATE() WHERE token_hash = ? AND utilizado_em IS NULL` e prosseguir só se **uma linha** foi afetada (ou `SELECT ... FOR UPDATE`).
  - Teste de concorrência (ex.: k6 ou JMeter) com a mesma senha.
- **Já previsto no projeto:** a *trigger* `trg_tokens_uma_utilizacao` do script SQL impede uma segunda utilização do mesmo token; os diagramas de sequência de UC-PAR-02 mostram a gravação na mesma transação.
- **Tratamento:** Mitigar · **Responsável:** Desenvolvimento

#### R14 — Compartilhamento ou venda de senhas

- **Nível:** P4 × I3 = **12 🟠 Alto** · residual 3 × 2 = 6 🟡
- **Cenário:** um participante repassa a senha a quem não pertence à categoria, ou alguém vende ou publica senhas do lote. Como o sistema é anônimo, não há como saber quem usou cada senha.
- **Mitigação:**
  - Distribuição **controlada** (entrega individual, envelope ou canal institucional) e lote **do tamanho do público** esperado.
  - Senhas válidas somente no período da pesquisa (UC-PAR-01).
  - **Monitorar** picos anormais de respostas em curto intervalo e a divergência entre o esperado por categoria e o recebido.
  - CAPTCHA no envio para dificultar o uso automatizado.
  - Possibilidade de **invalidar um lote** suspeito.
- **Risco aceito em parte:** o anonimato e a prevenção desse risco são objetivos opostos; o que resta é monitorado, não eliminado.
- **Tratamento:** Mitigar e aceitar o residual · **Responsável:** Administrador

#### R15 — Vazamento do arquivo de lote de senhas

- **Nível:** P3 × I4 = **12 🟠 Alto** · residual 3 × 2 = 6 🟡
- **Cenário:** o CSV ou PDF com as senhas em texto puro (única vez em que existem, UC-ADM-04) é salvo em local aberto, enviado por e-mail ou fica no computador do Administrador.
- **Mitigação:**
  - Gerar e entregar o arquivo **uma única vez** na hora do download; **não** guardar o arquivo no servidor.
  - Orientar o Administrador a guardar em local protegido e a apagar após a distribuição.
  - Registrar a geração do lote (`lotes_senhas`) para auditoria e permitir invalidar o lote em caso de vazamento.
  - Entregar o lote por canal seguro (HTTPS; link de uso único com expiração).
- **Já previsto no projeto:** RF06 (exportar apenas no momento da geração) e RNF32 (senha em texto só na exportação).
- **Tratamento:** Mitigar · **Responsável:** Administrador

#### R16 — Força bruta e adivinhação de senhas anônimas

- **Nível:** P2 × I4 = **8 🟡 Moderado** · residual 1 × 4 = 4 🟢 · OWASP A07:2021
- **Cenário:** um robô testa combinações na tela de acesso. O espaço de 8 caracteres alfanuméricos é grande (62⁸ ≈ 2,2 × 10¹⁴), mas ataques distribuídos (muitos IPs) escapam de um limite por IP. As mensagens diferentes ("não encontrada" e "já utilizada") também confirmam que uma senha existe.
- **Mitigação:**
  - Manter o limite de **3 tentativas em 15 minutos** (RNF43), em memória, e acrescentar **limite global** por pesquisa e **CAPTCHA** após falhas.
  - Gerar as senhas com gerador criptograficamente seguro (CSPRNG).
  - Avaliar uma única mensagem de erro para senha inexistente ou usada.
  - Alertar sobre picos de tentativas inválidas.
- **Já previsto no projeto:** RNF43, RNF21 (*rate limiting*).
- **Tratamento:** Mitigar · **Responsável:** Desenvolvimento

#### R17 — Hash fraco das senhas anônimas

- **Nível:** P2 × I4 = **8 🟡 Moderado** · residual 1 × 3 = 3 🟢 · OWASP A02:2021
- **Cenário:** se o banco vazar, os hashes SHA-256 **sem segredo** de senhas de **8 caracteres** podem ser recuperados por força bruta offline: o espaço (≈ 2,2 × 10¹⁴) é percorrido em poucas horas com GPUs. O atacante obtém senhas ainda **não utilizadas** e pode preencher a pesquisa em massa.
- **Mitigação:**
  - Trocar SHA-256 puro por **HMAC-SHA-256 com chave secreta** guardada fora do banco, ou
  - Aumentar o comprimento (12 caracteres ou mais), o que torna a busca offline inviável (ordem de milhares de anos).
  - Expirar os tokens ao fim da pesquisa e, passada a retenção, apagar os hashes.
- **Já previsto no projeto:** RNF33 (SHA-256 para senhas anônimas, conforme os casos de uso).
- **Observação:** é uma decisão de projeto a revisar com o professor, pois os casos de uso (UC-ADM-04) citam SHA-256 e 8 caracteres.
- **Tratamento:** Mitigar · **Responsável:** Desenvolvimento

#### R18 — Submissão inválida que burla a validação do navegador

- **Nível:** P3 × I3 = **9 🟡 Moderado** · residual 1 × 3 = 3 🟢 · OWASP A04:2021
- **Cenário:** o atacante altera a requisição para enviar uma alternativa de outra questão, uma questão de outra categoria, um valor de escala fora de 1 a 5, um texto gigante ou deixar de responder obrigatórias.
- **Mitigação:**
  - **Revalidar tudo no servidor**: obrigatoriedade, tipo de resposta compatível com o tipo da questão, tamanho do texto e categoria da senha.
  - Manter as regras no banco como segunda barreira.
- **Já previsto no projeto:** o script SQL tem **chave estrangeira composta** (a alternativa precisa pertencer à questão), `CHECK` de escala de 1 a 5 e a *trigger* `trg_respostas_mesma_categoria`; RNF26 e RNF39.
- **Tratamento:** Mitigar · **Responsável:** Desenvolvimento

### 6.4 Contas internas e privilégios

#### R19 — Comprometimento de credenciais de usuários internos

- **Nível:** P4 × I5 = **20 🔴 Crítico** · residual 2 × 5 = 10 🟠 · OWASP A07:2021
- **Cenário:** phishing, senha fraca ou reutilizada, ou força bruta de login. Uma conta de Administrador permite criar usuários, gerar senhas, alterar pesquisas e exportar dados; a de Secretaria aprova pesquisas.
- **Mitigação:**
  - **Autenticação multifator (MFA)** para Administrador, Secretaria e Auditor; no mínimo para o Administrador.
  - Senhas de usuário com **BCrypt ou Argon2** (nunca SHA simples), política de senha forte (12 caracteres ou mais) e verificação contra senhas vazadas conhecidas.
  - Bloqueio temporário após tentativas inválidas de login, com alerta ao titular.
  - Sessões curtas e reautenticação em operações críticas (ver R04).
  - Desativar de imediato contas de quem saiu (`usuarios.ativo = FALSE`, UC-ADM-06; RNF42) e **revisão periódica de acessos** pelo Auditor.
  - Limitar o número de contas Administrador; treinamento contra phishing.
- **Já previsto no projeto:** RNF33 (BCrypt/Argon2 sugerido), RNF42, RNF41; `senha_hash` em `usuarios`; campo `ativo`.
- **Risco residual alto:** depende de pessoas; exige monitoramento (seção 9).
- **Tratamento:** Mitigar · **Responsável:** Desenvolvimento, Administrador e Auditor

#### R20 — Fraude interna na aprovação ou na alteração de pesquisas

- **Nível:** P2 × I4 = **8 🟡 Moderado** · residual 1 × 4 = 4 🟢 · OWASP A04:2021
- **Cenário:** o próprio criador da pesquisa a aprova; alguém altera perguntas ou período **depois** da aprovação; ou pesquisa é marcada como "Aprovada" sem revisão da Secretaria.
- **Mitigação:**
  - **Separação de funções**: `aprovado_por` diferente de `criado_por`, garantido por *trigger* ou validação (a aprovação só por usuário com perfil Secretaria).
  - **Travar a edição** de pesquisa, categorias e questionário após "Aprovada" ou "Ativa"; para alterar, voltar a "Rascunho" e repetir a aprovação.
  - Máquina de estados no backend (Rascunho → Em análise → Aprovada ou Reprovada → Ativa → Encerrada) e notificação do Administrador a cada decisão.
  - Registrar quem aprovou e quando (`aprovado_por`, `aprovado_em`) e revisão pelo Auditor.
- **Já previsto no projeto:** RF13, RF21, UC-SEC-01, `CHECK` de valores de `status`.
- **Tratamento:** Mitigar · **Responsável:** Desenvolvimento

#### R21 — Adulteração ou apagamento de logs de auditoria

- **Nível:** P2 × I4 = **8 🟡 Moderado** · residual 1 × 4 = 4 🟢 · OWASP A09:2021
- **Cenário:** quem tem acesso ao banco tenta esconder suas ações. As *triggers* do script bloqueiam `UPDATE` e `DELETE`, mas **`TRUNCATE TABLE`, `DROP TRIGGER` e `DROP TABLE` não são bloqueados por elas**.
- **Mitigação:**
  - A conta da aplicação **sem** os privilégios `TRUNCATE`, `DROP`, `ALTER` e `TRIGGER`.
  - Enviar os logs também para **armazenamento externo imutável** (WORM) ou sistema de logs centralizado; retenção mínima de 5 anos (RNF29).
  - Verificação periódica de integridade (ex.: encadeamento por hash dos registros ou conferência com a cópia externa).
  - Alertar quando uma operação bloqueada pela *trigger* for tentada.
- **Já previsto no projeto:** RNF29 e as *triggers* `trg_logs_bloqueia_update` e `trg_logs_bloqueia_delete`.
- **Tratamento:** Mitigar · **Responsável:** Suporte Técnico e Auditor

#### R22 — Manipulação direta dos resultados no banco

- **Nível:** P2 × I5 = **10 🟠 Alto** · residual 1 × 5 = 5 🟡 · OWASP A08:2021
- **Cenário:** alguém com acesso ao banco insere respostas falsas ou altera respostas existentes. Como as respostas **não** têm autor (anonimato), isso é difícil de provar depois.
- **Mitigação:**
  - Conta da aplicação com apenas `INSERT` e `SELECT` em `respostas` e `submissoes` (sem `UPDATE` e `DELETE`).
  - **Conciliação periódica**: para cada categoria, o número de tokens utilizados deve ser compatível com o número de submissões; divergências geram alerta. Funciona sem ligar a resposta ao participante.
  - Auditoria do SGBD para acessos diretos e *dumps* de verificação por lote.
- **Já previsto no projeto:** `ON DELETE RESTRICT` em todas as chaves estrangeiras; separação entre `submissoes` e `tokens_anonimos`.
- **Tratamento:** Mitigar · **Responsável:** Suporte Técnico e Auditor

### 6.5 Disponibilidade e integridade operacional

#### R23 — Negação de serviço e picos de acesso

- **Nível:** P3 × I4 = **12 🟠 Alto** · residual 2 × 3 = 6 🟡
- **Cenário:** ataque de volume ou simplesmente muitos participantes respondendo no último dia derrubam o sistema dentro do prazo da pesquisa (`data_fim`).
- **Mitigação:**
  - Limite de requisições (*rate limiting*) no proxy e na aplicação; **WAF** ou CDN contra DDoS.
  - Teste de carga antes de cada pesquisa grande e dimensionamento para o pico.
  - Pool de conexões, índices nas consultas frequentes (já criados no script) e cache de páginas estáticas.
  - Monitoramento com alerta em menos de 5 minutos (UC-SUP-01) e plano para **prorrogar o prazo** se houver indisponibilidade.
- **Já previsto no projeto:** RNF05, RNF16 a RNF18, RNF21.
- **Tratamento:** Mitigar · **Responsável:** Suporte Técnico

#### R24 — Perda de dados

- **Nível:** P2 × I5 = **10 🟠 Alto** · residual 1 × 5 = 5 🟡
- **Cenário:** falha de disco, exclusão acidental, ataque de *ransomware* ou erro em uma atualização apagam respostas ou o banco inteiro.
- **Mitigação:**
  - **Backups automáticos** (regra 3-2-1: 3 cópias, 2 mídias, 1 fora do local), criptografados e **com teste de restauração periódico**.
  - Definir RPO e RTO; plano de recuperação de desastres e redundância.
  - Contas sem privilégio de apagar em massa; `ON DELETE RESTRICT` (já no script).
  - Atualizações do banco com migração versionada e *rollback*.
- **Já previsto no projeto:** RNF19 e RNF20.
- **Tratamento:** Mitigar · **Responsável:** Suporte Técnico

#### R25 — Operação em várias etapas interrompida

- **Nível:** P3 × I3 = **9 🟡 Moderado** · residual 1 × 3 = 3 🟢 · OWASP A04:2021
- **Cenário:** a queda ocorre entre os passos de uma operação (por exemplo, o lote é criado sem seus tokens, ou a senha é marcada como utilizada sem que a submissão seja gravada), deixando dados inconsistentes ou o participante sem poder responder.
- **Mitigação:** **transações** para gravar submissão, respostas e uso da senha (RNF25); gerar lote e tokens na mesma transação; rotina de **conciliação** de inconsistências; mensagem de erro clara com nova tentativa. O rascunho no navegador (RF19) evita que o participante perca o que escreveu.
- **Já previsto no projeto:** RNF25, RF19, fluxo alternativo de falha de conexão em UC-PAR-02.
- **Tratamento:** Mitigar · **Responsável:** Desenvolvimento

#### R26 — Pesquisa aplicada fora das regras

- **Nível:** P2 × I3 = **6 🟡 Moderado** · residual 1 × 3 = 3 🟢
- **Cenário:** senhas geradas para pesquisa não aprovada, ou questionário exibido fora do período ou com a pesquisa encerrada.
- **Mitigação:** gerar lote **somente** para pesquisa "Aprovada" (UC-ADM-04); exibir o questionário apenas se `status = ATIVA` e `Pesquisa.estaVigente()` (UC-PAR-01); rotina agendada para mudar o status de acordo com `data_inicio` e `data_fim`; testes das regras de estado.
- **Já previsto no projeto:** `CHECK` de `status` e de período (`data_fim > data_inicio`) no script SQL; fluxo FA4 do UC-PAR-01.
- **Tratamento:** Mitigar · **Responsável:** Desenvolvimento

### 6.6 Usabilidade

#### R27 — Perda do rascunho salvo no navegador

- **Nível:** P3 × I1 = **3 🟢 Baixo** · residual 3 × 1 = 3 🟢
- **Cenário:** o rascunho fica só no navegador (RF19, por decisão de anonimato). Se o participante limpar os dados ou trocar de aparelho, perde o que respondeu.
- **Mitigação:** salvar a cada pergunta; avisar na tela que o rascunho fica neste aparelho; mensagem clara em caso de falha de envio ("Respostas salvas localmente").
- **Tratamento:** **Aceitar** (guardar o rascunho no servidor exigiria ligá-lo a um identificador e enfraqueceria o anonimato) · **Responsável:** Desenvolvimento

---

## 7. Controles já presentes no modelo e no script SQL

O banco já implementa parte das mitigações. Esta tabela mostra o que existe no script (`script_banco_gestao_pesquisas.sql`) e os riscos que cada controle reduz.

| Controle no banco | Onde | Riscos |
|---|---|---|
| `senha_hash` e `token_hash` (só hash; senha em texto nunca gravada) | `usuarios`, `tokens_anonimos` | R10, R17, R19 |
| `UNIQUE` em `usuarios.email` e `tokens_anonimos.token_hash` | índices únicos | R13, R14, R18 |
| `utilizado_em` apenas com **data** (`DATE`) | `tokens_anonimos` | R09 |
| Nenhuma chave entre `submissoes` e `tokens_anonimos` | modelo | R09, R10, R22 |
| *Trigger* de uma única utilização da senha | `trg_tokens_uma_utilizacao` | R13, R14 |
| *Triggers* de logs imutáveis (sem `UPDATE` e `DELETE`) | `trg_logs_bloqueia_update`, `trg_logs_bloqueia_delete` | R21 |
| *Trigger* que exige questão e submissão na mesma categoria | `trg_respostas_mesma_categoria` | R18, R22 |
| Chave estrangeira **composta** (alternativa pertence à questão) | `respostas` | R18, R22 |
| `CHECK` de `status`, `tipo_questao`, `severidade`, período, `quantidade` e escala (1 a 5) | várias tabelas | R18, R20, R26 |
| `ON DELETE RESTRICT` e `ON UPDATE RESTRICT` em todas as chaves estrangeiras | todas | R22, R24 |
| `ativo` em usuários (desativação sem apagar histórico) | `usuarios` | R19 |
| Quem aprovou e quando (`aprovado_por`, `aprovado_em`, `motivo_reprovacao`) | `pesquisas` | R20 |
| Registro de lotes e de chamados com histórico | `lotes_senhas`, `chamados_historico` | R15, R21 |
| Índices em período, status e datas | `pesquisas`, `submissoes`, `logs_auditoria` | R23 |

**Limites dos controles do banco** (precisam de reforço na aplicação ou na infraestrutura):

- `TRUNCATE`, `DROP` e `ALTER` **contornam** as *triggers*; exigem privilégios restritos (R21).
- Regras como "pesquisa só vai para análise com ao menos uma categoria com questionário" e "criador diferente do aprovador" ficam na aplicação ou em novas *triggers* (R20).
- O banco não impede o compartilhamento de senhas (R14) nem a correlação por horário (R09).

---

## 8. Plano de ação priorizado

| Prioridade | Quando | Riscos | Ações principais |
|:-:|---|---|---|
| **1** | Antes de qualquer homologação | R19, R02, R01, R03, R07 | MFA e BCrypt/Argon2 no login; escape de saída e CSP; consultas parametrizadas e conta do banco com privilégio mínimo; testes de autorização por perfil; segredos fora do Git. |
| **2** | Antes da primeira pesquisa real | R13, R09, R10, R17, R08, R04 | Transação e reserva atômica da senha; tamanho mínimo de grupo nos relatórios e descasamento temporal; backups e dados criptografados; HMAC ou senha mais longa; HTTPS com HSTS; CSRF e reautenticação em operações críticas. |
| **3** | Durante a fase de implantação | R06, R11, R12, R14, R15, R22, R23, R24 | Verificação de dependências e hardening; aviso de privacidade e política de retenção; contas nominais no banco; controle de distribuição e invalidação de lote; conciliação tokens × submissões; teste de carga; teste de restauração de backup. |
| **4** | Rotina contínua | R05, R16, R18, R20, R21, R25, R26, R27 | Neutralizar fórmulas em CSV; CAPTCHA e limite global; revalidação no servidor; separação de funções e trava após aprovação; logs externos imutáveis; conciliação de inconsistências; regras de estado; aceitar R27. |

Os itens da prioridade 1 também são **requisitos de aceite**: o sistema não deve ser liberado com algum deles em aberto.

---

## 9. Monitoramento e revisão

### 9.1 Indicadores de risco (alertas)

| Indicador | Risco | Frequência |
|---|---|---|
| Tentativas de senha inválida por hora (total e por IP) | R14, R16 | Contínua |
| Divergência entre tokens utilizados e submissões, por categoria | R13, R14, R22, R25 | Diária |
| Respostas por minuto acima do padrão | R14, R23 | Contínua |
| Falhas de login e logins fora do padrão de usuários internos | R19 | Contínua |
| Tentativas de `UPDATE` ou `DELETE` bloqueadas em `logs_auditoria` | R21 | Contínua |
| Exportações realizadas e por quem (log de UC-ANA-02) | R05, R10 | Semanal |
| Vulnerabilidades abertas em dependências | R06 | A cada *build* e semanal |
| Resultado do teste de restauração de backup | R24 | Mensal |
| Grupos de relatório abaixo do tamanho mínimo bloqueados | R09 | Mensal |

### 9.2 Revisão da análise

- **Quando:** a cada entrega relevante, a cada mudança no modelo de dados ou nos fluxos de resposta, após qualquer incidente e, no mínimo, a cada semestre.
- **Quem:** a equipe do projeto, com validação do **Auditor** (UC-AUD-02), que compara o relatório de conformidade com este registro.
- **Como:** reavaliar P e I de cada risco com as medidas já implementadas, atualizar o risco residual e registrar novos riscos.

---

## 10. Premissas, limitações e referências

### 10.1 Premissas e limitações

- A análise é **qualitativa**, baseada em documentos de projeto; as probabilidades são estimativas e devem ser revistas com o sistema implementado.
- Considera-se que a aplicação seguirá os requisitos RNF (HTTPS, validação, hash, transações). Onde um controle depende de decisão ainda aberta, isso foi indicado no risco.
- Não foram feitos testes de invasão, revisão de código nem análise do ambiente de hospedagem.
- O banco usado como referência é MySQL (testado também em MariaDB); controles específicos podem variar em outro SGBD.

### 10.2 Referências

- **OWASP Top 10:2021** — categorias A01 a A10 (citadas por risco).
- **OWASP Application Security Verification Standard (ASVS)** — requisitos de verificação por área.
- **OWASP Cheat Sheet Series** — SQL Injection Prevention, XSS Prevention, CSRF Prevention, Password Storage e Session Management.
- **Lei Geral de Proteção de Dados (Lei nº 13.709/2018)** — princípios de finalidade, necessidade e segurança (art. 6º e art. 46).
- **ISO/IEC 27005** — gestão de riscos de segurança da informação (escala qualitativa de probabilidade e impacto).
- Documentos do projeto: `requisitos.md` (RF, RNF e UC), diagramas de classes e de sequência, MER, modelo físico e `script_banco_gestao_pesquisas.sql`.
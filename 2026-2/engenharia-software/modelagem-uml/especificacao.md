# Fluxos Principais e Alternativos

Este documento descreve os fluxos de uso do Sistema Web para Gestão de Pesquisas por Questionários, organizados por caso de uso. Cada caso de uso apresenta o **fluxo principal** (caminho feliz) e os **fluxos alternativos** (exceções, validações e desvios).

---

## UC01 — Cadastrar Pesquisa

**Ator principal:** Administrador

### Fluxo Principal
1. O Administrador acessa o módulo de cadastro de pesquisas.
2. O sistema exibe o formulário de nova pesquisa.
3. O Administrador informa título, descrição e período de aplicação (data início e fim).
4. O Administrador define o status inicial da pesquisa (ativa/inativa).
5. O sistema valida os dados informados.
6. O sistema registra a pesquisa no banco de dados.
7. O sistema exibe mensagem de confirmação de cadastro.

### Fluxos Alternativos
- **A1 — Dados obrigatórios não preenchidos:** no passo 5, o sistema identifica campos obrigatórios em branco, exibe mensagem de erro e retorna ao formulário para correção.
- **A2 — Período inválido:** no passo 5, caso a data de término seja anterior à data de início, o sistema rejeita o cadastro e solicita correção do período.
- **A3 — Cancelamento:** em qualquer etapa, o Administrador pode cancelar o cadastro; o sistema descarta os dados informados e retorna à listagem de pesquisas.

---

## UC02 — Cadastrar Categorias de Participantes

**Ator principal:** Administrador

### Fluxo Principal
1. O Administrador seleciona uma pesquisa previamente cadastrada.
2. O sistema exibe a área de gerenciamento de categorias da pesquisa.
3. O Administrador cadastra uma ou mais categorias (ex.: Alunos, Professores, Colaboradores).
4. O sistema associa as categorias à pesquisa selecionada.
5. O sistema confirma o cadastro das categorias.

### Fluxos Alternativos
- **A1 — Categoria duplicada:** no passo 4, se a categoria já existir para a pesquisa, o sistema exibe aviso e impede duplicidade.
- **A2 — Exclusão de categoria em uso:** caso o Administrador tente excluir uma categoria que já possui questionário ou senhas vinculadas, o sistema impede a exclusão e informa o motivo.

---

## UC03 — Criar Questionário por Categoria

**Ator principal:** Administrador

### Fluxo Principal
1. O Administrador seleciona a pesquisa e a categoria de participantes.
2. O sistema exibe a área de criação de questionário para a categoria.
3. O Administrador cadastra as questões, definindo o tipo (múltipla escolha única, múltipla escolha múltipla, escala ou resposta aberta).
4. O Administrador cadastra as alternativas de resposta, quando aplicável.
5. O sistema associa as questões e alternativas à categoria selecionada.
6. O sistema salva o questionário.

### Fluxos Alternativos
- **A1 — Questão sem alternativas obrigatórias:** no passo 4, se o tipo de questão exigir alternativas (múltipla escolha ou escala) e nenhuma for informada, o sistema impede o salvamento e solicita o preenchimento.
- **A2 — Edição de questionário já aplicado:** caso a pesquisa já esteja ativa e possua respostas registradas, o sistema alerta sobre o impacto da alteração antes de permitir a edição.

---

## UC04 — Gerar Senhas Anônimas

**Ator principal:** Administrador

### Fluxo Principal
1. O Administrador seleciona a pesquisa e a categoria de participantes.
2. O Administrador informa a quantidade de senhas a serem geradas (lote).
3. O sistema gera senhas aleatórias, sem vínculo com identidade do respondente.
4. O sistema associa cada senha à categoria selecionada e as marca como "não utilizadas".
5. O sistema armazena as senhas de forma criptografada no banco de dados.
6. O sistema disponibiliza a opção de exportação (PDF ou CSV).

### Fluxos Alternativos
- **A1 — Exportação do lote:** após o passo 6, o Administrador pode exportar as senhas geradas em PDF ou CSV para distribuição aos participantes.
- **A2 — Quantidade inválida:** no passo 2, se a quantidade informada for zero ou negativa, o sistema exibe erro e solicita novo valor.
- **A3 — Pesquisa inativa:** caso a pesquisa esteja com status "inativa", o sistema impede a geração de novas senhas até que a pesquisa seja ativada.

---

## UC05 — Aplicar Questionário via Senha (Coleta de Dados)

**Ator principal:** Participante

### Fluxo Principal
1. O Participante acessa o sistema.
2. O Participante digita a senha anônima recebida.
3. O sistema valida a senha e identifica a categoria correspondente.
4. O sistema exibe o questionário vinculado à categoria.
5. O Participante responde às questões obrigatórias e opcionais.
6. O Participante confirma o envio das respostas.
7. O sistema grava as respostas no banco de dados.
8. O sistema marca a senha como "utilizada".
9. O sistema exibe mensagem de agradecimento/confirmação de envio.

### Fluxos Alternativos
- **A1 — Senha inválida:** no passo 3, se a senha não existir, o sistema exibe mensagem de erro e solicita nova tentativa.
- **A2 — Senha já utilizada:** no passo 3, se a senha já tiver sido usada, o sistema bloqueia o acesso e informa que a resposta já foi registrada.
- **A3 — Respostas obrigatórias não preenchidas:** no passo 6, o sistema identifica campos obrigatórios não respondidos, exibe alerta e impede o envio até a correção.
- **A4 — Pesquisa fora do período de aplicação:** no passo 3, se a data atual estiver fora do período definido para a pesquisa, o sistema informa que a pesquisa está encerrada ou ainda não iniciada.
- **A5 — Interrupção do preenchimento:** caso o Participante abandone o preenchimento sem enviar, a senha permanece como "não utilizada" e nenhuma resposta é gravada.

---

## UC06 — Aprovar Pesquisa

**Ator principal:** Secretaria

### Fluxo Principal
1. A Secretaria acessa a lista de pesquisas pendentes de aprovação.
2. A Secretaria seleciona uma pesquisa para análise.
3. O sistema exibe os detalhes da pesquisa (título, período, categorias e questionários).
4. A Secretaria aprova a pesquisa.
5. O sistema altera o status da pesquisa para "ativa", liberando-a para aplicação.

### Fluxos Alternativos
- **A1 — Reprovação da pesquisa:** no passo 4, a Secretaria pode reprovar a pesquisa, informando justificativa; o sistema mantém o status como "inativa" e notifica o Administrador.
- **A2 — Solicitação de ajustes:** a Secretaria pode devolver a pesquisa ao Administrador solicitando alterações antes de nova submissão para aprovação.

---

## UC07 — Monitorar Participação (Dashboard)

**Ator principal:** Administrador (também acessível à Secretaria e ao Analista de Dados)

### Fluxo Principal
1. O usuário acessa o Dashboard de gestão.
2. O sistema exibe os indicadores: total de senhas geradas, total de respostas recebidas, taxa de participação e participação por categoria.
3. O usuário pode filtrar os indicadores por pesquisa ou por categoria.
4. O sistema atualiza os indicadores em tempo real conforme novas respostas são registradas.

### Fluxos Alternativos
- **A1 — Nenhuma resposta registrada:** no passo 2, se a pesquisa ainda não recebeu respostas, o sistema exibe indicadores zerados com mensagem informativa.
- **A2 — Falha na atualização em tempo real:** caso ocorra indisponibilidade momentânea, o sistema exibe o último dado consolidado disponível e sinaliza que a atualização está pendente.

---

## UC08 — Gerar Relatórios Estatísticos

**Ator principal:** Analista de Dados (também acessível ao Administrador e à Secretaria)

### Fluxo Principal
1. O usuário acessa o módulo de relatórios.
2. O usuário seleciona a pesquisa e o tipo de relatório (por pergunta, por categoria ou comparativo entre categorias).
3. O sistema processa os dados e exibe os resultados em tela, com gráficos.
4. O usuário opta por exportar o relatório em PDF ou CSV.
5. O sistema gera o arquivo solicitado e disponibiliza para download.

### Fluxos Alternativos
- **A1 — Dados insuficientes para o relatório:** no passo 3, se não houver respostas suficientes para gerar o relatório, o sistema informa a limitação e sugere aguardar mais participações.
- **A2 — Falha na exportação:** no passo 5, se ocorrer erro na geração do arquivo, o sistema exibe mensagem de erro e permite nova tentativa.

---

## UC09 — Auditar Dados e Segurança

**Ator principal:** Auditor

### Fluxo Principal
1. O Auditor acessa o módulo de auditoria.
2. O sistema exibe os registros de acesso, geração de senhas e respostas armazenadas.
3. O Auditor verifica a integridade e a rastreabilidade dos dados.
4. O Auditor confirma a conformidade com as normas de segurança e anonimato.
5. O sistema registra o parecer de auditoria.

### Fluxos Alternativos
- **A1 — Inconsistência identificada:** no passo 3, se o Auditor identificar alguma inconsistência (ex.: possibilidade de rastreamento do respondente), o sistema registra a ocorrência e notifica o Administrador e o Suporte Técnico.
- **A2 — Auditoria parcial:** o Auditor pode restringir a verificação a uma pesquisa ou período específico, gerando um parecer segmentado.

---

## UC10 — Manutenção e Suporte Técnico

**Ator principal:** Suporte Técnico

### Fluxo Principal
1. O Suporte Técnico identifica ou é notificado sobre uma falha no sistema.
2. O Suporte Técnico acessa os registros/logs do sistema para diagnóstico.
3. O Suporte Técnico realiza a correção necessária.
4. O sistema retorna à operação normal.
5. O Suporte Técnico registra a ocorrência e a solução aplicada.

### Fluxos Alternativos
- **A1 — Falha crítica com indisponibilidade:** no passo 1, se a falha impedir o acesso dos Participantes, o sistema deve preservar as senhas ainda não utilizadas e os dados já gravados até a normalização.
- **A2 — Necessidade de escalonamento:** caso a correção exija intervenção além do escopo do Suporte Técnico, o chamado é escalonado para a equipe de desenvolvimento.

---

## Resumo de Rastreabilidade (Casos de Uso x Requisitos Funcionais)

| Caso de Uso | Requisitos Funcionais relacionados |
|-------------|-------------------------------------|
| UC01 — Cadastrar Pesquisa | RF01 |
| UC02 — Cadastrar Categorias de Participantes | RF02 |
| UC03 — Criar Questionário por Categoria | RF03, RF04 |
| UC04 — Gerar Senhas Anônimas | RF05, RF06 |
| UC05 — Aplicar Questionário via Senha | RF07, RF08, RF09 |
| UC06 — Aprovar Pesquisa | — (regra de negócio institucional) |
| UC07 — Monitorar Participação (Dashboard) | RF10 |
| UC08 — Gerar Relatórios Estatísticos | RF11, RF12 |
| UC09 — Auditar Dados e Segurança | RNF02, RNF05 |
| UC10 — Manutenção e Suporte Técnico | RNF03, RNF04 |
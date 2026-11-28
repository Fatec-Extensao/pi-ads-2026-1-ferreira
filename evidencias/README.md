# Sistema Web para Gestão de Pesquisas por Questionários

> **Instituição:** Fatec Lins — Curso Superior de Tecnologia em Análise e Desenvolvimento de Sistemas (ADS)  
> **Disciplina:** Projeto Integrador · 2026  
> **Equipe:** Anderson Clayton Pereira de Assis · Eduardo Matias Ferreira · Lucas Augusto Vieira Tridapali · Vitor Hugo Dias Mantovani · Neandro Bueno Vieira

---

## Sobre o Projeto

Sistema web institucional desenvolvido para **criar, aprovar, aplicar e analisar pesquisas por questionários com garantia estrutural de anonimato** (conformidade com a LGPD).

* **Acesso por senha anônima de uso único:** cada participante responde sem vínculo com nome, CPF, e-mail ou endereço IP.
* **Segmentação por categoria:** questionários específicos para alunos, professores e colaboradores dentro de uma mesma pesquisa.
* **Governança e rastreabilidade:** fluxo formal de aprovação pela Secretaria, trilha de auditoria imutável (WORM) e relatórios estatísticos agregados com exportação em PDF, CSV e XLSX.

---

## Pasta `evidencias/`

A pasta **`evidencias/`** centraliza os materiais de encerramento, apresentação e comprovação técnica do Projeto Integrador:

| Arquivo | Descrição |
| :--- | :--- |
| **[`apresentacao.html`](apresentacao.html)** | Apresentação visual em formato de slides contendo o problema, a solução proposta, o ciclo de vida da pesquisa, os números da modelagem, os mecanismos de segurança e a organização das entregas. |
| **[`documentacao-final.md`](documentacao-final.md)** | Documento mestre do projeto que consolida a visão arquitetural, os 6 perfis de acesso, a máquina de estados da pesquisa, os pilares de banco de dados/LGPD e o guia de execução. |
| **[`validacao-do-projeto.md`](validacao-do-projeto.md)** | Documento de verificação técnica e rastreabilidade ponta a ponta entre os 21 Requisitos Funcionais, 44 Não Funcionais, 17 Casos de Uso, 18 Wireframes, Diagramas UML e as 14 tabelas do banco de dados, incluindo o termo de aprovação da equipe. |

---

## Módulos Principais do Repositório

* **[`engenharia-software/`](../2026-2/engenharia-software/)**: Levantamento de requisitos (`RF01`–`RF21` e `RNF01`–`RNF44`), especificações dos 17 casos de uso, matriz de rastreabilidade, diagrama de classes e diagramas de sequência.
* **[`banco-de-dados/`](../2026-2/banco-de-dados/)**: Modelo Entidade-Relacionamento (MER), documentação das 14 tabelas, restrições (`CHECK`, `UNIQUE`, chaves estrangeiras compostas) e o script SQL com as 4 *triggers* de integridade e imutabilidade.
* **[`seguranca/`](../2026-2/seguranca/)**: Matriz de análise de riscos (27 riscos mapeados com probabilidade, impacto e mitigação) e diretrizes de conformidade com a LGPD e anonimato.
* **[`desenvolvimento-web/`](../2026-2/desenvolvimento-web/)**: Implementação da aplicação web (frontend e backend) e os 18 wireframes prototipados.

---

## Como Visualizar a Apresentação

1. Abra o arquivo [`apresentacao.html`](apresentacao.html) diretamente em qualquer navegador moderno (Chrome, Edge, Firefox ou Safari).
2. Utilize as setas do teclado ou os controles da tela para navegar entre os slides.

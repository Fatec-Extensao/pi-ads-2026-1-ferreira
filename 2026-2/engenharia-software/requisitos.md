# Sistema Web para Gestão de Pesquisas por Questionários

## Requisitos Funcionais

Os requisitos funcionais descrevem o que o sistema deve fazer — as funcionalidades que deverão ser implementadas para atender às necessidades dos usuários.

| ID | Descrição |
|----|-----------|
| RF01 | Cadastrar pesquisas |
| RF02 | Cadastrar categorias de participantes |
| RF03 | Criar questionários por categoria |
| RF04 | Cadastrar perguntas e alternativas de resposta |
| RF05 | Gerar senhas anônimas por lote e por categoria |
| RF06 | Exportar senhas geradas (PDF ou CSV) |
| RF07 | Aplicar questionários via senha anônima |
| RF08 | Registrar respostas no banco de dados |
| RF09 | Impedir reutilização de senhas |
| RF10 | Monitorar participação em tempo real (dashboard) |
| RF11 | Gerar relatórios estatísticos por pergunta, categoria e comparativos |
| RF12 | Exportar resultados em PDF e CSV |

## Requisitos Não Funcionais

Os requisitos não funcionais definem as qualidades e restrições do sistema, como desempenho, segurança, usabilidade e portabilidade.

| ID | Categoria | Descrição |
|----|-----------|-----------|
| RNF01 | Usabilidade | Interface web amigável e layout responsivo, acessível em dispositivos móveis e desktops. |
| RNF02 | Segurança | Senhas criptografadas no banco, validação de acesso e proteção contra múltiplas respostas. |
| RNF03 | Performance | O sistema deve suportar múltiplos acessos simultâneos sem degradação de desempenho. |
| RNF04 | Portabilidade | Funcionamento em navegadores modernos (Chrome, Firefox, Edge, Safari). |
| RNF05 | Anonimato | Nenhuma resposta deve poder ser rastreada ao respondente individualmente. |

## Atores

Os atores representam os perfis de usuários que interagem com o sistema.

| Ator | Descrição |
|------|-----------|
| Administrador | Responsável por criar e gerenciar pesquisas, categorias, questionários, senhas e relatórios. Tem acesso total ao sistema. |
| Participante | Usuário que recebe uma senha anônima e responde ao questionário correspondente à sua categoria. Não possui conta no sistema. |
| Secretaria | Responsável por aprovar pesquisas antes de sua aplicação e analisar relatórios para subsidiar decisões institucionais. |
| Analista de Dados | Responsável por analisar os resultados das pesquisas, gerar insights e exportar dados para uso externo. |
| Suporte Técnico | Responsável pela manutenção do sistema, resolução de erros e garantia de continuidade operacional. |
| Auditor | Responsável por auditar os dados coletados, verificar a segurança do sistema e garantir conformidade com normas. |

## User Stories

As User Stories descrevem as funcionalidades do sistema do ponto de vista do usuário, no formato: **Ator — Ação — Resultado esperado**.

| Ator | Ação do Usuário | Resultado Esperado |
|------|------------------|---------------------|
| Administrador | Cadastrar uma nova pesquisa | O sistema registra a pesquisa com título, descrição, período e status. |
| Administrador | Cadastrar categorias de participantes | O sistema associa as categorias (ex: Alunos, Professores) à pesquisa. |
| Administrador | Criar questionário por categoria | O sistema vincula as perguntas à categoria selecionada. |
| Administrador | Gerar lote de senhas anônimas por categoria | O sistema gera senhas aleatórias associadas à categoria, sem identificar o respondente. |
| Administrador | Gerar relatório de resultados | O sistema exibe gráficos e permite exportação em PDF ou CSV. |
| Participante | Acessar a pesquisa com a senha recebida | O sistema identifica a categoria do participante e exibe o questionário correspondente. |
| Participante | Responder o questionário | O sistema valida as respostas obrigatórias e grava as respostas no banco de dados. |
| Secretaria | Aprovar pesquisas antes da aplicação | O sistema libera a pesquisa para aplicação após aprovação. |
| Secretaria | Analisar relatórios institucionais | O sistema fornece dados consolidados para apoio à tomada de decisão. |
| Analista de Dados | Analisar resultados detalhados | O sistema exibe gráficos detalhados por categoria e pergunta. |
| Analista de Dados | Gerar insights e exportar dados | O sistema permite exportação dos dados para análises externas. |
| Suporte Técnico | Manter o sistema em operação | O sistema continua funcionando corretamente após manutenção. |
| Suporte Técnico | Resolver erros e falhas | As falhas são corrigidas e o sistema retorna à normalidade. |
| Auditor | Auditar os dados coletados | O sistema garante integridade e rastreabilidade dos dados. |
| Auditor | Verificar segurança e conformidade | A conformidade com normas de segurança é validada. |

---

## Referências

* [Diagramas de casos de uso RF01 a RF12](modelagem-uml/casos-de-uso.md)
* [Fluxos principais e alternativos RF01 a RF12](modelagem-uml/especificacao.md)
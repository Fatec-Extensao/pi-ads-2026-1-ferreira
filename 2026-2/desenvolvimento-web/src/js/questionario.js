document.addEventListener("DOMContentLoaded", () => {
  const form = document.querySelector("form");
  if (!form) return;

  // Seleciona cada bloco de questão (ajuste o seletor se suas questões usarem outra tag/classe, como .questao ou section)
  const questoes = Array.from(form.querySelectorAll("fieldset, .questao"));
  if (questoes.length === 0) return;

  let indiceAtual = 0;

  // Cria e insere a barra de progresso e os botões de navegação dinamicamente
  const barraProgresso = document.createElement("p");
  barraProgresso.id = "progresso-questionario";
  barraProgresso.setAttribute("aria-live", "polite");
  form.insertBefore(barraProgresso, questoes[0]);

  const containerNavegacao = document.createElement("div");
  containerNavegacao.className = "navegacao-questoes";

  const btnAnterior = document.createElement("button");
  btnAnterior.type = "button";
  btnAnterior.textContent = "Anterior";
  btnAnterior.className = "btn-secundario";

  const btnProximo = document.createElement("button");
  btnProximo.type = "button";
  btnProximo.textContent = "Próxima";
  btnProximo.className = "btn-primario";

  // Localiza o botão original de envio do formulário
  const btnEnviar = form.querySelector('button[type="submit"], input[type="submit"]');

  containerNavegacao.appendChild(btnAnterior);
  containerNavegacao.appendChild(btnProximo);
  if (btnEnviar) {
    containerNavegacao.appendChild(btnEnviar);
  }
  form.appendChild(containerNavegacao);

  // Atualiza qual questão está visível e o estado dos botões
  function atualizarExibicao() {
    questoes.forEach((questao, index) => {
      questao.style.display = index === indiceAtual ? "block" : "none";
    });

    barraProgresso.textContent = `Questão ${indiceAtual + 1} de ${questoes.length}`;
    btnAnterior.style.display = indiceAtual > 0 ? "inline-block" : "none";

    const ehUltima = indiceAtual === questoes.length - 1;
    btnProximo.style.display = ehUltima ? "none" : "inline-block";
    if (btnEnviar) {
      btnEnviar.style.display = ehUltima ? "inline-block" : "none";
    }
  }

  // Valida os campos obrigatórios (required) dentro de um bloco específico
  function validarBloco(container) {
    limparErros(container);
    let valido = true;

    const obrigatorios = container.querySelectorAll("[required]");
    const gruposRadioValidados = new Set();

    obrigatorios.forEach((campo) => {
      if (campo.type === "radio" || campo.type === "checkbox") {
        if (gruposRadioValidados.has(campo.name)) return;
        gruposRadioValidados.add(campo.name);

        const algumMarcado = container.querySelector(
          `input[name="${campo.name}"]:checked`
        );
        if (!algumMarcado) {
          valido = false;
          exibirErro(container, "Por favor, selecione uma opção obrigatória.");
        }
      } else if (!campo.value.trim()) {
        valido = false;
        campo.classList.add("campo-invalido");
        exibirErro(campo.parentElement, "Este campo é obrigatório.");
      }
    });

    return valido;
  }

  function exibirErro(elementoPai, mensagem) {
    // Evita duplicar mensagens de erro no mesmo bloco
    if (elementoPai.querySelector(".mensagem-erro")) return;

    const erro = document.createElement("span");
    erro.className = "mensagem-erro";
    erro.setAttribute("role", "alert");
    erro.textContent = mensagem;
    elementoPai.appendChild(erro);
  }

  function limparErros(container) {
    container.querySelectorAll(".mensagem-erro").forEach((el) => el.remove());
    container
      .querySelectorAll(".campo-invalido")
      .forEach((el) => el.classList.remove("campo-invalido"));
  }

  // Eventos de navegação
  btnProximo.addEventListener("click", () => {
    if (validarBloco(questoes[indiceAtual])) {
      indiceAtual++;
      atualizarExibicao();
    }
  });

  btnAnterior.addEventListener("click", () => {
    limparErros(questoes[indiceAtual]);
    if (indiceAtual > 0) {
      indiceAtual--;
      atualizarExibicao();
    }
  });

  // Validação final antes do envio do formulário
  form.addEventListener("submit", (event) => {
    let formularioValido = true;

    questoes.forEach((questao, index) => {
      if (!validarBloco(questao)) {
        if (formularioValido) {
          // Volta automaticamente para a primeira questão com erro
          indiceAtual = index;
          atualizarExibicao();
        }
        formularioValido = false;
      }
    });

    if (!formularioValido) {
      event.preventDefault();
    }
  });

  // Inicializa na primeira questão
  atualizarExibicao();
});

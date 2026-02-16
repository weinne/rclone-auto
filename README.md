# ☁️ RClone Auto

> **O Gerenciador Definitivo para Rclone no Linux.**
> Gerencie montagens e sincronizações de nuvem com uma interface TUI moderna, bonita e inteligente.

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square)
![Interface](https://img.shields.io/badge/Interface-Gum_(Charm)-ff69b4?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-Linux-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

**RClone Auto** é um script Bash avançado que automatiza a configuração, montagem e sincronização de remotos do **Rclone**. Ele remove a complexidade da linha de comando, oferecendo uma experiência visual rica (mouse, filtros, cores) e garantindo persistência via `systemd`.

---

## ✨ Funcionalidades Principais

* **🎨 Interface Moderna (Gum):** Menus navegáveis, filtros de pesquisa, spinners de carregamento e confirmações visuais.
* **🚀 Auto-Instalação Inteligente:** Detecta e baixa automaticamente as dependências (`rclone` e `gum`) se não estiverem instaladas.
* **📦 Modo Portátil/Offline:** Suporte a binários embutidos no repositório para rodar sem internet ou instalação prévia.
* **⚡ Modos Duplos:**
    * **Mount:** Transforma a nuvem em um disco virtual (acesso imediato, sem ocupar espaço).
    * **Sync:** Cria uma cópia offline real com sincronização bidirecional automática (a cada 15 min).
* **🧠 Menu Contextual:** Gerencie conexões de forma intuitiva: clique na conexão -> escolha a ação (Parar, Abrir Pasta, Renomear, Excluir).
* **🏷️ Padronização:** Enforce nomes organizados (ex: `drive-trabalho`, `s3-backup`) com lista dinâmica de provedores.
* **🛠️ Ferramentas de Sistema:** Criação automática de atalhos no Menu/Área de Trabalho, correção de ícones e auto-update.

---

## 📦 Instalação

Você não precisa instalar nada antes. O script cuida de tudo.

### Método Rápido (Online)

```bash
# 1. Baixe o script
wget [https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/main/rclone-auto.sh](https://raw.githubusercontent.com/SEU_USUARIO/SEU_REPO/main/rclone-auto.sh)

# 2. Dê permissão de execução
chmod +x rclone-auto.sh

# 3. Execute
./rclone-auto.sh

### Método Portátil (Offline / Bundle)

Para criar um pacote que funciona em máquinas sem internet ou sem permissão de root:

1. Baixe o binário do `gum` compatível com a arquitetura alvo.
2. Coloque na mesma pasta do script (ou numa subpasta `bin/`).
3. O script detectará o arquivo local e pulará o download.

---

## 🎮 Como Usar

Basta rodar o script. Se você estiver em um ambiente gráfico (Desktop), ele abrirá automaticamente o seu terminal favorito.

```bash
rclone-auto

```

### O Menu Principal

1. **🚀 Nova Conexão:**
* Lista dinamicamente os provedores suportados pelo seu Rclone.
* Guia você pela autenticação no navegador.
* Pergunta se deseja **Montar** ou **Sincronizar**.
* Cria o serviço Systemd e inicia imediatamente.


2. **📂 Gerenciar Conexões:**
* Mostra uma lista colorida com status real (🟢 Montado, 🔵 Sync, ⚪ Parado).
* Clique em uma conexão para ver opções específicas (Parar, Abrir, Ativar, Renomear).


3. **🛠️ Ferramentas:**
* Recriar atalhos na Área de Trabalho.
* Corrigir ícones das pastas.
* Atualizar binários do Rclone e Gum para a última versão.



---

## 🔧 Estrutura Técnica

* **Persistência:** Utiliza unidades `systemd` de usuário (`rclone-mount-*.service` e `rclone-sync-*.timer`). Não requer `sudo` para rodar.
* **Diretórios:**
* Binários: `~/.local/bin/`
* Configurações: `~/.config/rclone/`
* Montagens: `~/Nuvem/`


* **Ícones:** Aplica metadados `.directory` para integração visual com Dolphin/Nautilus (ícone de nuvem na pasta raiz).

---

## 📋 Requisitos

* **Sistema Operacional:** Linux (Ubuntu, Debian, Fedora, Arch, etc).
* **Dependências de Sistema:** `curl`, `fuse3` (geralmente pré-instalado, mas necessário para montagem).
* **Dependências Automáticas:** O script baixa `rclone` e `gum` (Go) automaticamente se não encontrar.

---

## 🤝 Contribuindo

Pull requests são bem-vindos!

1. Faça um Fork do projeto.
2. Crie sua Feature Branch (`git checkout -b feature/NovaFeature`).
3. Commit suas mudanças (`git commit -m 'Adiciona NovaFeature'`).
4. Push para a Branch (`git push origin feature/NovaFeature`).
5. Abra um Pull Request.


## 👏 Créditos e Dependências

Este projeto é um "wrapper" de automação que se apoia em ferramentas open-source incríveis. Todo o crédito aos criadores originais pelas tecnologias subjacentes:

* **[Gum](https://github.com/charmbracelet/gum):** Desenvolvido pela [Charm](https://charm.sh/). Usado para criar a interface TUI moderna, interativa e bonita. Distribuído sob a licença MIT.
* **[Rclone](https://rclone.org/):** Desenvolvido por Nick Craig-Wood e contribuidores. É o motor robusto que realiza as conexões e sincronizações com a nuvem. Distribuído sob a licença MIT.

> **Nota sobre Distribuição:**
> Para facilitar a experiência do usuário ("battery-included"), este repositório pode conter ou baixar automaticamente binários dessas ferramentas. Todos os direitos de propriedade intelectual pertencem aos seus respectivos autores.

---

## 📜 Licença

Este projeto (o script `rclone-auto`) é distribuído sob a licença **MIT**.

Você é livre para usar, modificar e distribuir, desde que mantenha os créditos.

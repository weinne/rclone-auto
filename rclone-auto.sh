#!/bin/bash

# ==========================================
# RClone Auto v16.0 (System Installer)
# Autor: Weinne
# Feature: Auto-instalação no PATH, comando global e --help
# ==========================================

# --- Configurações ---
APP_NAME="rclone-auto"
PRETTY_NAME="RClone Auto"
ICON_URL="https://rclone.org/img/rclone-120x120.png"

# Diretórios do Sistema (User Space)
USER_BIN_DIR="$HOME/.local/bin"
SYSTEMD_DIR="$HOME/.config/systemd/user"
SHORTCUT_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons"

# Caminho atual deste arquivo
CURRENT_PATH=$(readlink -f "$0")

# Garante estrutura
mkdir -p "$USER_BIN_DIR" "$SYSTEMD_DIR" "$HOME/Nuvem" "$SHORTCUT_DIR" "$ICON_DIR"
export PATH="$USER_BIN_DIR:$PATH"

# Rclone Binário
if [ -f "$USER_BIN_DIR/rclone" ]; then
    RCLONE_BIN="$USER_BIN_DIR/rclone"
else
    RCLONE_BIN=$(which rclone 2>/dev/null || echo "$USER_BIN_DIR/rclone")
fi

# Ícone Local
LOCAL_ICON_PATH="$ICON_DIR/rclone-auto.png"

# --- 1. Menu de Ajuda (--help) ---
show_help() {
    echo -e "\033[1;34m$PRETTY_NAME v16.0\033[0m"
    echo "Gerenciador de automação para Rclone (Google Drive, OneDrive, S3, etc)."
    echo ""
    echo -e "\033[1mUSO:\033[0m"
    echo "  rclone-auto [OPÇÕES]"
    echo ""
    echo -e "\033[1mOPÇÕES:\033[0m"
    echo "  --gui       Força a interface gráfica (Zenity)."
    echo "  --tui       Força a interface de texto (Whiptail/Terminal)."
    echo "  --help      Mostra esta mensagem de ajuda."
    echo ""
    echo -e "\033[1mINSTALAÇÃO:\033[0m"
    echo "  Ao executar este script pela primeira vez, ele se instala automaticamente"
    echo "  em '~/.local/bin/rclone-auto' e cria um atalho no menu de aplicativos."
    echo ""
    exit 0
}

# --- 2. Processamento de Argumentos ---
FORCE_MODE=""
case "$1" in
    --gui) FORCE_MODE="GUI"; shift ;;
    --tui) FORCE_MODE="TUI"; shift ;;
    --help|-h) show_help ;;
esac

# --- 3. Lógica de Auto-Instalação (O Pulo do Gato) ---
install_system() {
    TARGET_BIN="$USER_BIN_DIR/$APP_NAME"

    # 3.1 Instala o binário (se copia para .local/bin)
    # Só copia se o script atual NÃO for o instalado, ou se o instalado for mais antigo/diferente
    if [ "$CURRENT_PATH" != "$TARGET_BIN" ]; then
        cp "$CURRENT_PATH" "$TARGET_BIN"
        chmod +x "$TARGET_BIN"
        # Atualiza a variável para apontar para o instalado
        FINAL_EXEC_PATH="$TARGET_BIN"
    else
        FINAL_EXEC_PATH="$CURRENT_PATH"
    fi

    # 3.2 Garante o Ícone
    if [ ! -s "$LOCAL_ICON_PATH" ]; then
        curl -s -L "$ICON_URL" -o "$LOCAL_ICON_PATH"
    fi
    if [ -s "$LOCAL_ICON_PATH" ]; then CURRENT_ICON="$LOCAL_ICON_PATH"; else CURRENT_ICON="folder-cloud"; fi

    # 3.3 Garante o Atalho .desktop (Sempre recria apontando para o binário instalado)
    DESKTOP_FILE="$SHORTCUT_DIR/$APP_NAME.desktop"

    # Conteúdo do atalho
    cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Name=$PRETTY_NAME
Comment=Gerenciador de Nuvens e Montagem Automática
Exec="$FINAL_EXEC_PATH" --gui
Icon=$CURRENT_ICON
Terminal=false
Type=Application
Categories=Utility;Network;FileTools;
StartupWMClass=$APP_NAME
StartupNotify=true
Actions=Configure;

[Desktop Action Configure]
Name=Configurar Nuvens
Exec="$FINAL_EXEC_PATH" --tui
EOF
    chmod +x "$DESKTOP_FILE"
    update-desktop-database "$SHORTCUT_DIR" 2>/dev/null
}

# --- 4. Wrappers Visuais e Funções ---

detect_mode() {
    if [ "$FORCE_MODE" = "GUI" ] && command -v zenity &> /dev/null; then MODE="GUI"; return;
    elif [ "$FORCE_MODE" = "TUI" ]; then MODE="TUI"; return; fi
    if [ ! -t 0 ] && [ -n "$DISPLAY" ] && command -v zenity &> /dev/null; then MODE="GUI"; else MODE="TUI"; fi
}

get_zen_opts() { ZEN_ARGS=(--width=500 --height=430 --title="$PRETTY_NAME"); }

notify_user() { if [ "$MODE" = "GUI" ]; then notify-send -i "$CURRENT_ICON" "$1" "$2" 2>/dev/null; fi; }

ui_msg() {
    if [ "$MODE" = "GUI" ]; then get_zen_opts; zenity --info --text="<span size='large'>$1</span>\n\n$2" "${ZEN_ARGS[@]}" --width=400 --height=200
    else whiptail --title "$PRETTY_NAME" --msgbox "$1\n$2" 10 60; fi
}

ui_confirm() {
    if [ "$MODE" = "GUI" ]; then get_zen_opts; zenity --question --text="<span size='large'>$1</span>" "${ZEN_ARGS[@]}" --width=400 --height=200
    else whiptail --title "$PRETTY_NAME" --yesno "$1" 10 60; fi
}

ui_input() {
    TITLE="$1"; DEFAULT="$2"
    if [ "$MODE" = "GUI" ]; then get_zen_opts; zenity --entry --text="$TITLE" --entry-text="$DEFAULT" "${ZEN_ARGS[@]}" --width=400 --height=200
    else whiptail --title "$PRETTY_NAME" --inputbox "$TITLE" 10 60 "$DEFAULT" 3>&1 1>&2 2>&3; fi
}

ui_input_folder() {
    DEFAULT="$1"
    if [ "$MODE" = "GUI" ]; then get_zen_opts; zenity --file-selection --directory --filename="$DEFAULT/" --title="Selecione a pasta" "${ZEN_ARGS[@]}"
    else whiptail --title "Localização" --inputbox "Caminho da pasta:" 10 60 "$DEFAULT" 3>&1 1>&2 2>&3; fi
}

ui_dashboard() {
    ACTIVE_COUNT=$(systemctl --user list-unit-files | grep "rclone-mount-" | grep "enabled" | wc -l)
    TEXT="Bem-vindo ao <b>$PRETTY_NAME</b>.\nVocê tem <b>$ACTIVE_COUNT</b> conexões ativas."
    if [ "$MODE" = "GUI" ]; then get_zen_opts; zenity --list --column="ID" --column="Ação" --column="Descrição" --hide-column=1 --text="$TEXT" "${ZEN_ARGS[@]}" --hide-header \
        "1" "☁️  Conectar Nuvem" "Adicionar Google Drive, OneDrive..." \
        "2" "⚙️  Gerenciar Ativas" "Parar ou remover montagens" \
        "3" "🔧  Configuração Avançada" "Terminal do Rclone (Modo Texto)" \
        "4" "🚪  Sair" "Fechar o aplicativo"
    else whiptail --title "$PRETTY_NAME" --menu "Menu Principal" 20 70 10 "1" "Nova Conexão" "2" "Gerenciar" "3" "Config Avançada" "4" "Sair" 3>&1 1>&2 2>&3; fi
}

ui_select_list() {
    TITLE="$1"; shift;
    if [ "$MODE" = "GUI" ]; then get_zen_opts; ZEN_LIST_ARGS=(); while [ "$#" -gt 0 ]; do ZEN_LIST_ARGS+=("FALSE" "$1" "$2"); shift 2; done
        zenity --list --radiolist --column="" --column="ID" --column="Opção" --hide-column=2 --text="$TITLE" "${ZEN_ARGS[@]}" "${ZEN_LIST_ARGS[@]}"
    else whiptail --title "$PRETTY_NAME" --menu "$TITLE" 20 70 10 "$@" 3>&1 1>&2 2>&3; fi
}

check_deps() {
    if ! command -v fusermount &> /dev/null && ! command -v fusermount3 &> /dev/null; then ui_msg "Erro" "FUSE não encontrado.\nRode: sudo apt install fuse3"; exit 1; fi
    if ! command -v "$RCLONE_BIN" &> /dev/null; then
        if ui_confirm "Rclone ausente" "Baixar versão oficial agora?"; then
             if [ "$MODE" = "GUI" ]; then (echo "10"; curl -L https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rclone.zip; echo "100") | zenity --progress --pulsate --text="Baixando..." --auto-close; else curl -L https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rclone.zip; fi
             unzip -o /tmp/rclone.zip -d /tmp/inst > /dev/null
             mv /tmp/inst/rclone-*-linux-amd64/rclone "$USER_BIN_DIR/"; chmod +x "$USER_BIN_DIR/rclone"
             rm -rf /tmp/inst /tmp/rclone.zip
             RCLONE_BIN="$USER_BIN_DIR/rclone"
        else exit 1; fi
    fi
}

# --- 5. Funções de Negócio ---

do_wizard() {
    PROVIDER=$(ui_select_list "Qual serviço conectar?" "drive" "Google Drive" "onedrive" "Microsoft OneDrive" "dropbox" "Dropbox" "s3" "Amazon S3" "mega" "Mega" "pcloud" "pCloud") || return
    NAME=$(ui_input "Nome da conexão (sem espaços):" "MeuDrive") || return
    NAME=$(echo "$NAME" | tr -cd '[:alnum:]_-')
    if [ -z "$NAME" ]; then return; fi
    if "$RCLONE_BIN" listremotes | grep -q "^${NAME}:"; then ui_msg "Erro" "Nome '$NAME' já existe."; return; fi

    ui_msg "Autorização" "Seu navegador será aberto.\nFaça login e autorize o acesso."

    if [ "$MODE" = "GUI" ]; then
        TERM_FOUND=0
        for term in konsole gnome-terminal xfce4-terminal x-terminal-emulator; do if command -v $term &> /dev/null; then $term -e "$RCLONE_BIN config create '$NAME' '$PROVIDER'"; TERM_FOUND=1; break; fi; done
        if [ $TERM_FOUND -eq 0 ]; then "$RCLONE_BIN" config create "$NAME" "$PROVIDER" & fi
    else "$RCLONE_BIN" config create "$NAME" "$PROVIDER"; fi

    if [ "$MODE" = "GUI" ]; then (echo "50"; sleep 3; echo "# Aguardando..."; sleep 3; echo "100") | zenity --progress --pulsate --text="Aguardando autorização..." --auto-close --no-cancel; else sleep 5; fi

    if "$RCLONE_BIN" listremotes | grep -q "^${NAME}:"; then
        if ui_confirm "Sucesso!" "Conexão criada! Montar agora?"; then do_mount "$NAME"; fi
    else ui_msg "Aviso" "Não consegui verificar a conexão."; fi
}

do_mount() {
    REMOTE="$1"
    if [ -z "$REMOTE" ]; then
        REMOTES=$("$RCLONE_BIN" listremotes); if [ -z "$REMOTES" ]; then ui_msg "Aviso" "Nenhuma conta configurada."; return; fi
        MENU_ITEMS=(); while read -r line; do clean="${line%:}"; MENU_ITEMS+=("$clean" "Nuvem"); done <<< "$REMOTES"
        REMOTE=$(ui_select_list "Qual serviço montar?" "${MENU_ITEMS[@]}") || return
    fi
    MOUNT_POINT=$(ui_input_folder "$HOME/Nuvem/$REMOTE") || return
    mkdir -p "$MOUNT_POINT"
    if [ "$(ls -A "$MOUNT_POINT")" ]; then ui_msg "Erro" "A pasta deve estar vazia."; return; fi

    SERVICE_NAME="rclone-mount-${REMOTE}"; SERVICE_FILE="$SYSTEMD_DIR/${SERVICE_NAME}.service"; REAL_RCLONE=$(readlink -f "$RCLONE_BIN")
    cat <<EOF > "$SERVICE_FILE"
[Unit]
Description=Mount $REMOTE via Rclone Auto
After=network-online.target
[Service]
Type=notify
ExecStart=$REAL_RCLONE mount ${REMOTE}: "$MOUNT_POINT" --vfs-cache-mode full --no-modtime --vfs-read-chunk-size 32M --vfs-read-chunk-size-limit off
ExecStop=/bin/fusermount -u "$MOUNT_POINT"
Restart=on-failure
RestartSec=10
[Install]
WantedBy=default.target
EOF
    systemctl --user daemon-reload; systemctl --user enable --now "${SERVICE_NAME}.service"
    if [ "$MODE" = "GUI" ]; then (echo "100") | zenity --progress --pulsate --text="Conectando..." --auto-close --no-cancel; fi
    if systemctl --user is-active --quiet "${SERVICE_NAME}.service"; then notify_user "Sucesso" "$REMOTE montado!"; ui_msg "Conectado!" "Local: <tt>$MOUNT_POINT</tt>"; else ui_msg "Erro" "Falha ao iniciar serviço."; fi
}

do_manage() {
    LIST=$(systemctl --user list-unit-files | grep "rclone-mount-" | awk '{print $1}')
    MENU_OPTS=(); if [ -n "$LIST" ]; then for s in $LIST; do PRETTY=$(echo "$s" | sed 's/rclone-mount-//;s/.service//'); MENU_OPTS+=("$s" "🔴 Desconectar: $PRETTY"); done; fi
    ALL_REMOTES=$("$RCLONE_BIN" listremotes); while read -r line; do clean="${line%:}"; if ! echo "$LIST" | grep -q "rclone-mount-${clean}"; then MENU_OPTS+=("MOUNT:$clean" "🟢 Montar: $clean"); fi; done <<< "$ALL_REMOTES"
    if [ ${#MENU_OPTS[@]} -eq 0 ]; then ui_msg "Info" "Nenhuma conexão configurada."; return; fi
    SELECTION=$(ui_select_list "Gerenciar Conexões" "${MENU_OPTS[@]}") || return
    if [[ "$SELECTION" == MOUNT:* ]]; then do_mount "${SELECTION#MOUNT:}"; else
        if ui_confirm "Confirmação" "Remover serviço?"; then systemctl --user stop "$SELECTION"; systemctl --user disable "$SELECTION"; rm "$SYSTEMD_DIR/$SELECTION"; systemctl --user daemon-reload; notify_user "Desconectado" "Serviço removido."; fi
    fi
}

do_advanced() {
    if [ "$MODE" = "GUI" ]; then
        for term in konsole gnome-terminal xfce4-terminal x-terminal-emulator; do if command -v $term &> /dev/null; then $term -e "$RCLONE_BIN config"; return; fi; done
        ui_msg "Erro" "Terminal não encontrado. Rode 'rclone config'."
    else "$RCLONE_BIN" config; fi
}

# --- Execução ---
detect_mode
install_system # Instala binário global e atalho
check_deps

while true; do
    ACTION=$(ui_dashboard); if [ $? -ne 0 ]; then exit 0; fi
    case $ACTION in
        1) do_wizard ;;
        2) do_manage ;;
        3) do_advanced ;;
        4|"") exit 0 ;;
    esac
done

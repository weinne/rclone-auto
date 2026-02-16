#!/bin/bash

# ==========================================
# RClone Auto v12.0 (Wizard Edition)
# Autor: Weinne
# Feature: Assistente guiado para criar conexões (Google/OneDrive)
# ==========================================

# --- Configurações ---
APP_NAME="rclone-auto"
PRETTY_NAME="RClone Auto"
ICON_URL="https://rclone.org/img/rclone-120x120.png"

# Diretórios
USER_BIN_DIR="$HOME/.local/bin"
SYSTEMD_DIR="$HOME/.config/systemd/user"
SHORTCUT_DIR="$HOME/.local/share/applications"
ICON_DIR="$HOME/.local/share/icons"
SCRIPT_PATH=$(readlink -f "$0")

# Garante estrutura
mkdir -p "$USER_BIN_DIR" "$SYSTEMD_DIR" "$HOME/Nuvem" "$SHORTCUT_DIR" "$ICON_DIR"
export PATH="$USER_BIN_DIR:$PATH"

# Rclone Binário
if [ -f "$USER_BIN_DIR/rclone" ]; then
    RCLONE_BIN="$USER_BIN_DIR/rclone"
else
    RCLONE_BIN=$(which rclone 2>/dev/null || echo "$USER_BIN_DIR/rclone")
fi

# Caminho do Ícone Local
LOCAL_ICON_PATH="$ICON_DIR/rclone-auto.png"

# --- 1. Flags ---
FORCE_MODE=""
case "$1" in
    --gui) FORCE_MODE="GUI"; shift ;;
    --tui) FORCE_MODE="TUI"; shift ;;
esac

# --- 2. Ícone ---
ensure_icon() {
    if [ ! -s "$LOCAL_ICON_PATH" ]; then curl -s -L "$ICON_URL" -o "$LOCAL_ICON_PATH"; fi
    if [ -s "$LOCAL_ICON_PATH" ]; then CURRENT_ICON="$LOCAL_ICON_PATH"; else CURRENT_ICON="folder-cloud"; fi
}

# --- 3. Auto-Instalação ---
install_shortcut() {
    DESKTOP_FILE="$SHORTCUT_DIR/rclone-auto.desktop"
    if [ ! -f "$DESKTOP_FILE" ] || ! grep -q "$SCRIPT_PATH" "$DESKTOP_FILE"; then
        cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Name=$PRETTY_NAME
Comment=Gerenciador Automático de Nuvens
Exec="$SCRIPT_PATH" --gui
Icon=$CURRENT_ICON
Terminal=false
Type=Application
Categories=Utility;System;Network;FileTools;
StartupWMClass=$APP_NAME
StartupNotify=true
EOF
        chmod +x "$DESKTOP_FILE"
        update-desktop-database "$SHORTCUT_DIR" 2>/dev/null
    fi
}

# --- 4. Detecção ---
detect_mode() {
    if [ "$FORCE_MODE" = "GUI" ] && command -v zenity &> /dev/null; then MODE="GUI"; return;
    elif [ "$FORCE_MODE" = "TUI" ]; then MODE="TUI"; return; fi
    if [ ! -t 0 ] && [ -n "$DISPLAY" ] && command -v zenity &> /dev/null; then MODE="GUI"; else MODE="TUI"; fi
}

# --- 5. Wrappers Visuais ---
get_zen_opts() {
    ZEN_ARGS=(--width=500 --height=430 --title="$PRETTY_NAME")
}

notify_user() {
    if [ "$MODE" = "GUI" ]; then notify-send -i "$CURRENT_ICON" "$1" "$2" 2>/dev/null; fi
}

ui_msg() {
    if [ "$MODE" = "GUI" ]; then get_zen_opts; zenity --info --text="<span size='large' weight='bold'>$1</span>\n\n$2" "${ZEN_ARGS[@]}" --width=400 --height=200
    else whiptail --title "$PRETTY_NAME" --msgbox "$1\n$2" 10 60; fi
}

ui_confirm() {
    if [ "$MODE" = "GUI" ]; then get_zen_opts; zenity --question --text="<span size='large'>$1</span>" "${ZEN_ARGS[@]}" --width=400 --height=200
    else whiptail --title "$PRETTY_NAME" --yesno "$1" 10 60; fi
}

ui_input() {
    TITLE="$1"; DEFAULT="$2"
    if [ "$MODE" = "GUI" ]; then get_zen_opts; zenity --entry --title="$PRETTY_NAME" --text="$TITLE" --entry-text="$DEFAULT" "${ZEN_ARGS[@]}" --width=400 --height=200
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
        "1" "☁️  Conectar Nuvem" "Criar nova conexão (Google, OneDrive...)" \
        "2" "⚙️  Gerenciar Montagens" "Ativar, desativar ou remover drives" \
        "3" "🔧  Configuração Avançada" "Menu completo do Rclone (Terminal)" \
        "4" "🚪  Sair" "Fechar o aplicativo"
    else whiptail --title "$PRETTY_NAME" --menu "Menu Principal" 20 70 10 "1" "Conectar Nuvem" "2" "Gerenciar Montagens" "3" "Config Avançada" "4" "Sair" 3>&1 1>&2 2>&3; fi
}

ui_select_list() {
    TITLE="$1"; shift;
    if [ "$MODE" = "GUI" ]; then get_zen_opts; ZEN_LIST_ARGS=(); while [ "$#" -gt 0 ]; do ZEN_LIST_ARGS+=("FALSE" "$1" "$2"); shift 2; done
        zenity --list --radiolist --column="" --column="ID" --column="Opção" --hide-column=2 --text="$TITLE" "${ZEN_ARGS[@]}" "${ZEN_LIST_ARGS[@]}"
    else whiptail --title "$PRETTY_NAME" --menu "$TITLE" 20 70 10 "$@" 3>&1 1>&2 2>&3; fi
}

# --- 6. Verificações ---
check_deps() {
    if ! command -v fusermount &> /dev/null && ! command -v fusermount3 &> /dev/null; then ui_msg "Erro" "FUSE não encontrado.\nRode: sudo apt install fuse3"; exit 1; fi
    if ! command -v "$RCLONE_BIN" &> /dev/null; then
        if ui_confirm "Rclone ausente" "Baixar versão oficial agora?"; then
             curl -L https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rclone.zip
             unzip -o /tmp/rclone.zip -d /tmp/inst > /dev/null
             mv /tmp/inst/rclone-*-linux-amd64/rclone "$USER_BIN_DIR/"; chmod +x "$USER_BIN_DIR/rclone"
             RCLONE_BIN="$USER_BIN_DIR/rclone"
        else exit 1; fi
    fi
}

# --- 7. Lógica Principal ---

# O NOVO ASSISTENTE (WIZARD)
do_wizard() {
    # Passo 1: Escolher o provedor (Curadoria dos mais usados)
    PROVIDER=$(ui_select_list "Qual serviço você quer conectar?" \
        "drive" "Google Drive" \
        "onedrive" "Microsoft OneDrive" \
        "dropbox" "Dropbox" \
        "s3" "Amazon S3 / Compatíveis" \
        "mega" "Mega" \
        "pcloud" "pCloud") || return

    # Passo 2: Dar um nome
    NAME=$(ui_input "Dê um nome para esta conexão (sem espaços):" "MeuDrive") || return
    # Sanitize name (remove espaços e caracteres estranhos)
    NAME=$(echo "$NAME" | tr -cd '[:alnum:]_-')

    if [ -z "$NAME" ]; then ui_msg "Erro" "O nome não pode ser vazio."; return; fi

    # Verifica se já existe
    if "$RCLONE_BIN" listremotes | grep -q "^${NAME}:"; then
        ui_msg "Erro" "Já existe uma conexão com o nome '$NAME'."; return
    fi

    # Passo 3: Executar a mágica (rclone config create)
    ui_msg "Atenção" "Seu navegador irá abrir para autorizar o acesso.\n\nPor favor, faça login na sua conta e autorize o Rclone."

    # Abre terminal para mostrar o link caso o navegador falhe
    if [ "$MODE" = "GUI" ]; then
        # Tenta abrir um terminal para rodar o comando interativo
        TERM_CMD=""
        for term in konsole gnome-terminal xfce4-terminal x-terminal-emulator; do
            if command -v $term &> /dev/null; then TERM_CMD=$term; break; fi
        done

        if [ -n "$TERM_CMD" ]; then
            $TERM_CMD -e "$RCLONE_BIN config create '$NAME' '$PROVIDER'"
        else
            # Fallback: roda em background e torce pro xdg-open funcionar
            "$RCLONE_BIN" config create "$NAME" "$PROVIDER" &
        fi
    else
        "$RCLONE_BIN" config create "$NAME" "$PROVIDER"
    fi

    # Pequena pausa para garantir que o config salvou
    sleep 2

    # Verifica se criou
    if "$RCLONE_BIN" listremotes | grep -q "^${NAME}:"; then
        if ui_confirm "Sucesso!" "A conexão '$NAME' foi criada!\nDeseja montá-la como um disco agora?"; then
            do_mount_remote "$NAME"
        fi
    else
        ui_msg "Aviso" "Não foi possível verificar se a conexão foi criada.\nTente novamente ou use a Configuração Avançada."
    fi
}

do_mount_remote() {
    REMOTE="$1"
    # Se não passou argumento, pede para escolher
    if [ -z "$REMOTE" ]; then
        REMOTES=$("$RCLONE_BIN" listremotes)
        if [ -z "$REMOTES" ]; then ui_msg "Aviso" "Nenhuma conta configurada."; return; fi
        MENU_ITEMS=(); while read -r line; do clean="${line%:}"; MENU_ITEMS+=("$clean" "Nuvem"); done <<< "$REMOTES"
        REMOTE=$(ui_select_list "Qual serviço montar?" "${MENU_ITEMS[@]}") || return
    fi

    MOUNT_POINT=$(ui_input_folder "$HOME/Nuvem/$REMOTE") || return
    mkdir -p "$MOUNT_POINT"

    if [ "$(ls -A "$MOUNT_POINT")" ]; then ui_msg "Erro" "A pasta escolhida deve estar vazia."; return; fi

    SERVICE_NAME="rclone-mount-${REMOTE}"
    SERVICE_FILE="$SYSTEMD_DIR/${SERVICE_NAME}.service"
    REAL_RCLONE=$(readlink -f "$RCLONE_BIN")

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

    systemctl --user daemon-reload
    systemctl --user enable --now "${SERVICE_NAME}.service"

    if [ "$MODE" = "GUI" ]; then (echo "100") | zenity --progress --title="Montando" --text="Conectando..." --auto-close --pulsate --no-cancel "${ZEN_ARGS[@]}"; fi

    if systemctl --user is-active --quiet "${SERVICE_NAME}.service"; then
        notify_user "Sucesso" "$REMOTE conectado!"
        ui_msg "Conectado!" "Local: <tt>$MOUNT_POINT</tt>"
    else ui_msg "Erro" "Falha ao iniciar serviço."; fi
}

do_manage() {
    LIST=$(systemctl --user list-unit-files | grep "rclone-mount-" | awk '{print $1}')
    if [ -z "$LIST" ]; then ui_msg "Info" "Nenhuma montagem ativa."; return; fi
    MENU_ITEMS=(); for s in $LIST; do PRETTY=$(echo "$s" | sed 's/rclone-mount-//;s/.service//'); MENU_ITEMS+=("$s" "Nuvem: $PRETTY"); done
    DEL=$(ui_select_list "Selecione para DESCONECTAR:" "${MENU_ITEMS[@]}") || return
    if ui_confirm "Confirmação" "Remover <b>$DEL</b>?"; then
        systemctl --user stop "$DEL"; systemctl --user disable "$DEL"; rm "$SYSTEMD_DIR/$DEL"; systemctl --user daemon-reload
        notify_user "Desconectado" "Serviço removido."
    fi
}

do_advanced_config() {
    if [ "$MODE" = "GUI" ]; then
        for term in konsole gnome-terminal xfce4-terminal x-terminal-emulator; do
            if command -v $term &> /dev/null; then $term -e "$RCLONE_BIN config"; return; fi
        done
        ui_msg "Erro" "Terminal não encontrado. Rode manualmente."
    else "$RCLONE_BIN" config; fi
}

# --- Execução ---
detect_mode; ensure_icon; install_shortcut; check_deps

while true; do
    ACTION=$(ui_dashboard); if [ $? -ne 0 ]; then exit 0; fi
    case $ACTION in
        1) do_wizard ;;          # O Novo Assistente
        2) do_manage ;;          # Gerenciar montagens (stop/start)
        3) do_advanced_config ;; # O velho "rclone config"
        4|"") exit 0 ;;
    esac
done

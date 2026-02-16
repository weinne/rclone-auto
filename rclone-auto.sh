#!/bin/bash

# ==========================================
# RClone Auto v11.0 (Compatibility Fix)
# Autor: Weinne
# Fix: Remove flags do Zenity que causam erro em algumas distros
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

# --- 1. Processamento de Argumentos (Flags) ---
FORCE_MODE=""
case "$1" in
    --gui)
        FORCE_MODE="GUI"
        shift # Remove o argumento para não processar depois
        ;;
    --tui)
        FORCE_MODE="TUI"
        shift
        ;;
esac

# --- 2. Lógica de Ícone Inteligente ---
ensure_icon() {
    if [ ! -s "$LOCAL_ICON_PATH" ]; then
        curl -s -L "$ICON_URL" -o "$LOCAL_ICON_PATH"
    fi
    if [ -s "$LOCAL_ICON_PATH" ]; then
        CURRENT_ICON="$LOCAL_ICON_PATH"
    else
        CURRENT_ICON="folder-cloud"
    fi
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

# --- 4. Detecção de Interface ---
detect_mode() {
    # 1. Se o usuário forçou via flag
    if [ "$FORCE_MODE" = "GUI" ] && command -v zenity &> /dev/null; then
        MODE="GUI"
        return
    elif [ "$FORCE_MODE" = "TUI" ]; then
        MODE="TUI"
        return
    fi

    # 2. Detecção Automática
    if [ ! -t 0 ] && [ -n "$DISPLAY" ] && command -v zenity &> /dev/null; then
        MODE="GUI"
    else
        MODE="TUI"
    fi
}

# --- 5. Wrappers Visuais (Simplificados) ---
get_zen_opts() {
    # Removemos --window-icon e --class para evitar erros de compatibilidade
    ZEN_ARGS=(
        --width=500
        --height=430
        --title="$PRETTY_NAME"
    )
}

notify_user() {
    if [ "$MODE" = "GUI" ]; then
        notify-send -i "$CURRENT_ICON" "$1" "$2" 2>/dev/null
    fi
}

ui_msg() {
    if [ "$MODE" = "GUI" ]; then
        get_zen_opts
        zenity --info --text="<span size='large' weight='bold'>$1</span>\n\n$2" "${ZEN_ARGS[@]}" --width=400 --height=200
    else
        whiptail --title "$PRETTY_NAME" --msgbox "$1\n$2" 10 60
    fi
}

ui_confirm() {
    if [ "$MODE" = "GUI" ]; then
        get_zen_opts
        zenity --question --text="<span size='large'>$1</span>" "${ZEN_ARGS[@]}" --width=400 --height=200
    else
        whiptail --title "$PRETTY_NAME" --yesno "$1" 10 60
    fi
}

ui_input_folder() {
    DEFAULT="$1"
    if [ "$MODE" = "GUI" ]; then
        get_zen_opts
        zenity --file-selection --directory --filename="$DEFAULT/" --title="Selecione a pasta" "${ZEN_ARGS[@]}"
    else
        whiptail --title "Localização" --inputbox "Caminho da pasta:" 10 60 "$DEFAULT" 3>&1 1>&2 2>&3
    fi
}

ui_dashboard() {
    ACTIVE_COUNT=$(systemctl --user list-unit-files | grep "rclone-mount-" | grep "enabled" | wc -l)
    TEXT="Bem-vindo ao <b>$PRETTY_NAME</b>.\nVocê tem <b>$ACTIVE_COUNT</b> conexões ativas."

    if [ "$MODE" = "GUI" ]; then
        get_zen_opts
        zenity --list \
            --column="ID" --column="Ação" --column="Descrição" \
            --hide-column=1 \
            --text="$TEXT" \
            "${ZEN_ARGS[@]}" \
            --hide-header \
            "1" "☁️  Nova Conexão" "Montar Google Drive, OneDrive, S3..." \
            "2" "⚙️  Gerenciar Ativas" "Parar ou remover montagens" \
            "3" "🔧  Configurações" "Adicionar/Editar contas no Rclone" \
            "4" "🚪  Sair" "Fechar o aplicativo"
    else
        whiptail --title "$PRETTY_NAME" --menu "Menu Principal" 20 70 10 \
        "1" "Nova Conexão" \
        "2" "Gerenciar Ativas" \
        "3" "Configurar Rclone" \
        "4" "Sair" 3>&1 1>&2 2>&3
    fi
}

ui_select_remote() {
    TITLE="$1"
    shift
    if [ "$MODE" = "GUI" ]; then
        get_zen_opts
        ZEN_LIST_ARGS=()
        while [ "$#" -gt 0 ]; do
            ZEN_LIST_ARGS+=("FALSE" "$1" "$2")
            shift 2
        done
        zenity --list --radiolist \
            --column="" --column="ID" --column="Nuvem" \
            --hide-column=2 \
            --text="$TITLE" \
            "${ZEN_ARGS[@]}" \
            "${ZEN_LIST_ARGS[@]}"
    else
        whiptail --title "$PRETTY_NAME" --menu "$TITLE" 20 70 10 "$@" 3>&1 1>&2 2>&3
    fi
}

# --- 6. Verificações ---
check_deps() {
    if ! command -v fusermount &> /dev/null && ! command -v fusermount3 &> /dev/null; then
        ui_msg "Erro Crítico" "FUSE não encontrado.\nRode: sudo apt install fuse3"
        exit 1
    fi
    if ! command -v "$RCLONE_BIN" &> /dev/null; then
        if ui_confirm "Rclone ausente" "Deseja baixar e instalar agora?"; then
             if [ "$MODE" = "GUI" ]; then
                get_zen_opts
                (
                    echo "10"; echo "# Baixando..."; curl -L https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rclone.zip
                    echo "50"; echo "# Extraindo..."; unzip -o /tmp/rclone.zip -d /tmp/inst > /dev/null
                    echo "80"; echo "# Instalando..."; mv /tmp/inst/rclone-*-linux-amd64/rclone "$USER_BIN_DIR/"
                    chmod +x "$USER_BIN_DIR/rclone"
                    rm -rf /tmp/inst /tmp/rclone.zip
                    echo "100"; echo "# Concluído!"
                ) | zenity --progress --title="Instalação" --auto-close "${ZEN_ARGS[@]}"
             else
                curl -L https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rclone.zip
                unzip -o /tmp/rclone.zip -d /tmp/inst > /dev/null
                mv /tmp/inst/rclone-*-linux-amd64/rclone "$USER_BIN_DIR/"
                chmod +x "$USER_BIN_DIR/rclone"
             fi
             RCLONE_BIN="$USER_BIN_DIR/rclone"
        else
             exit 1
        fi
    fi
}

# --- 7. Funções Principais ---

do_create_mount() {
    REMOTES=$("$RCLONE_BIN" listremotes)
    if [ -z "$REMOTES" ]; then
        ui_msg "Aviso" "Nenhuma conta configurada. Vamos configurar agora."
        do_config
        return
    fi

    MENU_ITEMS=()
    while read -r line; do
        clean="${line%:}"
        MENU_ITEMS+=("$clean" "Armazenamento Remoto")
    done <<< "$REMOTES"

    REMOTE=$(ui_select_remote "Qual serviço você deseja montar?" "${MENU_ITEMS[@]}") || return
    MOUNT_POINT=$(ui_input_folder "$HOME/Nuvem/$REMOTE") || return

    mkdir -p "$MOUNT_POINT"
    if [ "$(ls -A "$MOUNT_POINT")" ]; then
        ui_msg "Erro" "A pasta escolhida <b>não está vazia</b>."
        return
    fi

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

    if [ "$MODE" = "GUI" ]; then
        get_zen_opts
        (echo "50"; sleep 1; echo "100") | zenity --progress --title="Conectando..." --text="Montando $REMOTE..." --auto-close --pulsate --no-cancel "${ZEN_ARGS[@]}"
    fi

    if systemctl --user is-active --quiet "${SERVICE_NAME}.service"; then
        notify_user "Sucesso" "$REMOTE conectado!"
        ui_msg "Conectado!" "Local: <tt>$MOUNT_POINT</tt>"
    else
        ui_msg "Erro" "Falha ao iniciar o serviço."
    fi
}

do_remove_mount() {
    LIST=$(systemctl --user list-unit-files | grep "rclone-mount-" | awk '{print $1}')
    if [ -z "$LIST" ]; then ui_msg "Informação" "Nenhuma montagem ativa."; return; fi

    MENU_ITEMS=()
    for s in $LIST; do
        PRETTY_NAME=$(echo "$s" | sed 's/rclone-mount-//;s/.service//')
        MENU_ITEMS+=("$s" "Nuvem: $PRETTY_NAME")
    done

    DEL=$(ui_select_remote "Selecione para <b>DESCONECTAR</b>:" "${MENU_ITEMS[@]}") || return

    if ui_confirm "Confirmação" "Desconectar <b>$DEL</b>?"; then
        systemctl --user stop "$DEL"
        systemctl --user disable "$DEL"
        rm "$SYSTEMD_DIR/$DEL"
        systemctl --user daemon-reload
        notify_user "Desconectado" "Serviço removido."
    fi
}

do_config() {
    if [ "$MODE" = "GUI" ]; then
        for term in konsole gnome-terminal xfce4-terminal x-terminal-emulator; do
            if command -v $term &> /dev/null; then
                $term -e "$RCLONE_BIN config"
                return
            fi
        done
        ui_msg "Erro" "Nenhum terminal encontrado.\nRode 'rclone config' manualmente."
    else
        "$RCLONE_BIN" config
    fi
}

# --- Execução Principal ---
detect_mode
ensure_icon
install_shortcut # Atualiza o atalho para usar --gui
check_deps

while true; do
    ACTION=$(ui_dashboard)
    EXIT_STATUS=$?

    if [ $EXIT_STATUS -ne 0 ]; then exit 0; fi

    case $ACTION in
        1) do_create_mount ;;
        2) do_remove_mount ;;
        3) do_config ;;
        4|"") exit 0 ;;
    esac
done

#!/bin/bash

# ==========================================
# RClone Auto v30.0 (Self-Update & Parent Icon)
# Autor: Weinne
# Feature: Atualização automática do binário e Ícone na pasta raiz
# ==========================================

# --- Configurações ---
APP_NAME="rclone-auto"
PRETTY_NAME="RClone Auto"
SYSTEM_ICON="folder-remote"

# Diretórios
USER_BIN_DIR="$HOME/.local/bin"
SYSTEMD_DIR="$HOME/.config/systemd/user"
SHORTCUT_DIR="$HOME/.local/share/applications"
DESKTOP_DIR=$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")
CLOUD_DIR="$HOME/Nuvem"

# Caminhos
CURRENT_PATH=$(readlink -f "$0")
TARGET_BIN="$USER_BIN_DIR/$APP_NAME"

mkdir -p "$USER_BIN_DIR" "$SYSTEMD_DIR" "$CLOUD_DIR" "$SHORTCUT_DIR"
export PATH="$USER_BIN_DIR:$PATH"

# Define binário
RCLONE_BIN=""

# --- i18n ---
declare -A TXT
TXT[WELCOME_TITLE]="Welcome to"
TXT[WELCOME_MSG]="Active Connections:"
TXT[BTN_NEW]="New Connection"
TXT[DESC_NEW]="Add Google Drive, OneDrive, S3..."
TXT[BTN_MANAGE]="Manage Drives"
TXT[DESC_MANAGE]="Mount, unmount or remove drives"
TXT[BTN_TOOLS]="Tools & Shortcuts"
TXT[DESC_TOOLS]="Standardize names, icons, shortcuts"
TXT[BTN_ADV]="Advanced Config"
TXT[DESC_ADV]="Open Rclone terminal wizard"
TXT[BTN_EXIT]="Exit"
TXT[DESC_EXIT]="Close application"
TXT[ERR_FUSE]="FUSE not found.\nPlease run: sudo apt install fuse3"
TXT[ASK_INSTALL_TITLE]="Rclone Missing"
TXT[ASK_INSTALL_MSG]="How do you want to install Rclone?"
TXT[INST_PORTABLE]="Portable (Recommended)"
TXT[INST_PORTABLE_DESC]="Download official binary to user folder. No root required."
TXT[INST_SYSTEM]="System Package"
TXT[INST_SYSTEM_DESC]="Install via package manager (needs sudo)."
TXT[DL_PROG]="Downloading Rclone..."
TXT[WIZ_PROV]="Select Provider"
TXT[WIZ_NAME]="Identifier (suffix):"
TXT[WIZ_NAME_DEF]="personal"
TXT[WIZ_PREVIEW]="Final Name will be:"
TXT[ERR_NAME_EXIST]="Name already exists."
TXT[AUTH_TITLE]="Authorization"
TXT[AUTH_MSG]="Your browser will open.\nPlease login and authorize access."
TXT[WAIT_AUTH]="Waiting for authorization..."
TXT[SUCCESS_NEW]="Connection created!"
TXT[MODE_TITLE]="Select Mode"
TXT[MODE_MSG]="How do you want to use this connection?"
TXT[MODE_MOUNT]="Mount (Virtual Drive)"
TXT[MODE_MOUNT_DESC]="Files stay in cloud. Saves disk space."
TXT[MODE_SYNC]="Sync (Offline Copy)"
TXT[MODE_SYNC_DESC]="Real copy on disk. Available offline. Syncs every 15m."
TXT[SEL_FOLDER]="Select Local Folder"
TXT[ERR_EMPTY]="Folder must be empty."
TXT[CONN_PROG]="Configuring..."
TXT[SUCCESS_MOUNT]="Mounted successfully!"
TXT[SUCCESS_SYNC]="Sync scheduled (every 15 min)!"
TXT[ERR_SERVICE]="Failed to start service."
TXT[MANAGE_TITLE]="Manage Connections"
TXT[ACT_UNMOUNT]="Disconnect"
TXT[ACT_MOUNT]="Mount/Start"
TXT[CONFIRM_REM]="Disconnect and remove service?"
TXT[REMOVED]="Service removed."
TXT[ERR_TERM]="Terminal not found."
TXT[NO_CONFIG]="No accounts configured."
TXT[TOOLS_TITLE]="Tools"
TXT[TOOL_DESKTOP]="Create Desktop Shortcuts"
TXT[TOOL_FIX]="Fix/Reapply Folder Icons"
TXT[TOOL_RENAME]="Standardize/Rename Connection"
TXT[MSG_DESKTOP]="Shortcuts created on Desktop!"
TXT[MSG_FIX]="Folder icons reapplied!"
TXT[REN_TITLE]="Standardize Connection"
TXT[REN_NEW_NAME]="Enter new suffix:"
TXT[REN_SUCCESS]="Renamed successfully!"
TXT[REN_WARN]="Note: Active mounts were stopped. Please mount again."

if [[ "$LANG" == pt* ]]; then
    TXT[WELCOME_TITLE]="Bem-vindo ao"
    TXT[WELCOME_MSG]="Conexões Ativas:"
    TXT[BTN_NEW]="Nova Conexão"
    TXT[DESC_NEW]="Adicionar Google Drive, OneDrive, S3..."
    TXT[BTN_MANAGE]="Gerenciar"
    TXT[DESC_MANAGE]="Ativar, desativar ou remover drives"
    TXT[BTN_TOOLS]="Ferramentas & Atalhos"
    TXT[DESC_TOOLS]="Padronizar nomes, ícones, atalhos"
    TXT[BTN_ADV]="Avançado"
    TXT[DESC_ADV]="Terminal do Rclone"
    TXT[BTN_EXIT]="Sair"
    TXT[DESC_EXIT]="Fechar o aplicativo"
    TXT[ERR_FUSE]="FUSE não encontrado.\nRode: sudo apt install fuse3"
    TXT[ASK_INSTALL_TITLE]="Instalação do Rclone"
    TXT[ASK_INSTALL_MSG]="Como deseja instalar o Rclone?"
    TXT[INST_PORTABLE]="Portátil (Recomendado)"
    TXT[INST_PORTABLE_DESC]="Baixa versão oficial na pasta do usuário. Sem root."
    TXT[INST_SYSTEM]="Gerenciador de Pacotes"
    TXT[INST_SYSTEM_DESC]="Instala via sistema (apt/dnf). Requer senha/root."
    TXT[DL_PROG]="Baixando Rclone..."
    TXT[WIZ_PROV]="Qual serviço conectar?"
    TXT[WIZ_NAME]="Identificador (sufixo):"
    TXT[WIZ_NAME_DEF]="pessoal"
    TXT[WIZ_PREVIEW]="Nome final será:"
    TXT[ERR_NAME_EXIST]="Este nome já existe."
    TXT[AUTH_TITLE]="Autorização"
    TXT[AUTH_MSG]="Seu navegador será aberto.\nFaça login e autorize o acesso."
    TXT[WAIT_AUTH]="Aguardando autorização..."
    TXT[SUCCESS_NEW]="Conexão criada!"
    TXT[MODE_TITLE]="Escolha o Modo"
    TXT[MODE_MSG]="Como deseja usar esta nuvem?"
    TXT[MODE_MOUNT]="Montar (Disco Virtual)"
    TXT[MODE_MOUNT_DESC]="Arquivos ficam na nuvem. Economiza espaço."
    TXT[MODE_SYNC]="Sincronizar (Cópia Offline)"
    TXT[MODE_SYNC_DESC]="Cópia real no disco. Funciona offline. Sincroniza a cada 15m."
    TXT[SEL_FOLDER]="Selecione a Pasta Local"
    TXT[ERR_EMPTY]="A pasta deve estar vazia."
    TXT[CONN_PROG]="Configurando..."
    TXT[SUCCESS_MOUNT]="Montado com sucesso!"
    TXT[SUCCESS_SYNC]="Sincronização agendada (a cada 15 min)!"
    TXT[ERR_SERVICE]="Falha ao iniciar serviço."
    TXT[MANAGE_TITLE]="Gerenciar Conexões"
    TXT[ACT_UNMOUNT]="Desconectar"
    TXT[ACT_MOUNT]="Ativar"
    TXT[CONFIRM_REM]="Desconectar e remover serviço?"
    TXT[REMOVED]="Serviço removido."
    TXT[ERR_TERM]="Terminal não encontrado."
    TXT[NO_CONFIG]="Nenhuma conta configurada."
    TXT[TOOLS_TITLE]="Ferramentas"
    TXT[TOOL_DESKTOP]="Criar Atalhos na Área de Trabalho"
    TXT[TOOL_FIX]="Reparar Ícones das Pastas"
    TXT[TOOL_RENAME]="Padronizar/Renomear Conexão"
    TXT[MSG_DESKTOP]="Atalhos criados na Área de Trabalho!"
    TXT[MSG_FIX]="Ícones das pastas reaplicados!"
    TXT[REN_TITLE]="Padronizar Conexão"
    TXT[REN_NEW_NAME]="Digite o novo sufixo:"
    TXT[REN_SUCCESS]="Renomeado com sucesso!"
    TXT[REN_WARN]="Nota: Montagens ativas foram paradas. Monte novamente."
fi

# --- Install & Update Self ---
install_system() {
    # 1. Copia/Atualiza o binário
    # Se o script que está rodando ($CURRENT_PATH) não é o mesmo que está instalado ($TARGET_BIN),
    # significa que é uma versão nova ou rodando de outro lugar. Copiamos por cima.
    if [ "$CURRENT_PATH" != "$TARGET_BIN" ]; then
        cp -f "$CURRENT_PATH" "$TARGET_BIN"
        chmod +x "$TARGET_BIN"
        FINAL_EXEC_PATH="$TARGET_BIN"
    else
        FINAL_EXEC_PATH="$CURRENT_PATH"
    fi

    # 2. Cria/Atualiza Atalho
    DESKTOP_FILE="$SHORTCUT_DIR/$APP_NAME.desktop"
    cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Name=$PRETTY_NAME
Comment=${TXT[BTN_NEW]}
Exec="$FINAL_EXEC_PATH" --gui
Icon=$SYSTEM_ICON
Terminal=false
Type=Application
Categories=Utility;Network;System;
StartupWMClass=$APP_NAME
StartupNotify=true
Actions=Configure;
[Desktop Action Configure]
Name=${TXT[BTN_ADV]}
Exec="$FINAL_EXEC_PATH" --tui
EOF
    chmod +x "$DESKTOP_FILE"

    # 3. Força atualização do cache do menu
    if command -v update-desktop-database &> /dev/null; then update-desktop-database "$SHORTCUT_DIR" 2>/dev/null; fi
    if command -v kbuildsycoca6 &> /dev/null; then kbuildsycoca6 --noincremental &> /dev/null; fi
    touch "$SHORTCUT_DIR"
}

# --- Parent Icon Setup ---
set_parent_icon() {
    # Define o ícone da pasta raiz "Nuvem"
    if [ -d "$CLOUD_DIR" ]; then
        echo -e "[Desktop Entry]\nIcon=$SYSTEM_ICON\nType=Directory" > "$CLOUD_DIR/.directory" 2>/dev/null
    fi
}

# --- Wrappers ---
FORCE_MODE=""; case "$1" in --gui) FORCE_MODE="GUI"; shift ;; --tui) FORCE_MODE="TUI"; shift ;; esac
detect_mode() {
    if [ "$FORCE_MODE" = "GUI" ] && command -v zenity &> /dev/null; then MODE="GUI"; return;
    elif [ "$FORCE_MODE" = "TUI" ]; then MODE="TUI"; return; fi
    if [ ! -t 0 ] && [ -n "$DISPLAY" ] && command -v zenity &> /dev/null; then MODE="GUI"; else MODE="TUI"; fi
}
get_zen_opts() { ZEN_ARGS=(--width=500 --height=400 --title="$PRETTY_NAME"); }
notify_user() { if [ "$MODE" = "GUI" ]; then notify-send -i "$SYSTEM_ICON" "$1" "$2" 2>/dev/null; fi; }
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
    if [ "$MODE" = "GUI" ]; then get_zen_opts; zenity --file-selection --directory --filename="$DEFAULT/" --title="${TXT[SEL_FOLDER]}" "${ZEN_ARGS[@]}"
    else whiptail --title "${TXT[SEL_FOLDER]}" --inputbox "Path:" 10 60 "$DEFAULT" 3>&1 1>&2 2>&3; fi
}
ui_select_list() {
    TITLE="$1"; shift;
    if [ "$MODE" = "GUI" ]; then get_zen_opts; ZEN_LIST_ARGS=(); while [ "$#" -gt 0 ]; do ZEN_LIST_ARGS+=("FALSE" "$1" "$2"); shift 2; done
        zenity --list --radiolist --column="" --column="ID" --column="Option" --hide-column=2 --text="$TITLE" "${ZEN_ARGS[@]}" "${ZEN_LIST_ARGS[@]}"
    else whiptail --title "$PRETTY_NAME" --menu "$TITLE" 20 70 10 "$@" 3>&1 1>&2 2>&3; fi
}
ui_dashboard() {
    ACTIVE_COUNT=$(systemctl --user list-unit-files | grep "rclone-" | grep "enabled" | wc -l)
    TEXT="${TXT[WELCOME_TITLE]} <b>$PRETTY_NAME</b>.\n${TXT[WELCOME_MSG]} <b>$ACTIVE_COUNT</b>"
    if [ "$MODE" = "GUI" ]; then get_zen_opts; zenity --list --column="ID" --column="Ação" --column="Descrição" --hide-column=1 --text="$TEXT" "${ZEN_ARGS[@]}" --hide-header \
        "1" "☁️  ${TXT[BTN_NEW]}" "${TXT[DESC_NEW]}" \
        "2" "⚙️  ${TXT[BTN_MANAGE]}" "${TXT[DESC_MANAGE]}" \
        "3" "🛠️  ${TXT[BTN_TOOLS]}" "${TXT[DESC_TOOLS]}" \
        "4" "🔧  ${TXT[BTN_ADV]}" "${TXT[DESC_ADV]}" \
        "5" "🚪  ${TXT[BTN_EXIT]}" "${TXT[DESC_EXIT]}"
    else whiptail --title "$PRETTY_NAME" --menu "Menu" 20 70 10 "1" "${TXT[BTN_NEW]}" "2" "${TXT[BTN_MANAGE]}" "3" "${TXT[BTN_TOOLS]}" "4" "${TXT[BTN_ADV]}" "5" "${TXT[BTN_EXIT]}" 3>&1 1>&2 2>&3; fi
}

# --- CHECK & INSTALL RCLONE ---
check_deps() {
    if ! command -v fusermount &> /dev/null && ! command -v fusermount3 &> /dev/null; then ui_msg "Error" "${TXT[ERR_FUSE]}"; exit 1; fi
    if [ -f "$USER_BIN_DIR/rclone" ]; then RCLONE_BIN="$USER_BIN_DIR/rclone"; elif command -v rclone &> /dev/null; then RCLONE_BIN=$(command -v rclone); fi

    if [ -z "$RCLONE_BIN" ]; then
        PKG_MGR=""; INSTALL_CMD=""
        if command -v apt &> /dev/null; then PKG_MGR="apt (Debian/Ubuntu)"; INSTALL_CMD="apt install -y rclone";
        elif command -v dnf &> /dev/null; then PKG_MGR="dnf (Fedora)"; INSTALL_CMD="dnf install -y rclone";
        elif command -v pacman &> /dev/null; then PKG_MGR="pacman (Arch)"; INSTALL_CMD="pacman -S --noconfirm rclone";
        elif command -v zypper &> /dev/null; then PKG_MGR="zypper (OpenSUSE)"; INSTALL_CMD="zypper install -y rclone"; fi

        METHOD=$(ui_select_list "${TXT[ASK_INSTALL_TITLE]}\n${TXT[ASK_INSTALL_MSG]}" "PORTABLE" "${TXT[INST_PORTABLE]} - ${TXT[INST_PORTABLE_DESC]}" "SYSTEM" "${TXT[INST_SYSTEM]} - ${TXT[INST_SYSTEM_DESC]} [$PKG_MGR]")

        if [ "$METHOD" == "SYSTEM" ] && [ -n "$INSTALL_CMD" ]; then
            if [ "$MODE" = "GUI" ] && command -v pkexec &> /dev/null; then pkexec bash -c "$INSTALL_CMD"; elif [ "$MODE" = "GUI" ]; then x-terminal-emulator -e "sudo $INSTALL_CMD"; else sudo $INSTALL_CMD; fi
            RCLONE_BIN=$(command -v rclone)
        elif [ "$METHOD" == "PORTABLE" ] || [ -z "$METHOD" ]; then
             if [ "$MODE" = "GUI" ]; then (echo "10"; curl -L https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rclone.zip; echo "100") | zenity --progress --pulsate --text="${TXT[DL_PROG]}" --auto-close; else curl -L https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rclone.zip; fi
             unzip -o /tmp/rclone.zip -d /tmp/inst > /dev/null; mv /tmp/inst/rclone-*-linux-amd64/rclone "$USER_BIN_DIR/"; chmod +x "$USER_BIN_DIR/rclone"; rm -rf /tmp/inst /tmp/rclone.zip; RCLONE_BIN="$USER_BIN_DIR/rclone"
        else exit 1; fi
    fi
}

# --- ICONS ---
get_safe_icon() { echo "$SYSTEM_ICON"; }

create_desktop_shortcut() {
    REMOTE="$1"; MOUNT_POINT="$2"; ICON=$(get_safe_icon)
    SHORTCUT_FILE="$DESKTOP_DIR/$REMOTE.desktop"
    cat <<EOF > "$SHORTCUT_FILE"
[Desktop Entry]
Name=$REMOTE
Comment=Nuvem $REMOTE
Exec=xdg-open "$MOUNT_POINT"
Icon=$ICON
Terminal=false
Type=Application
Categories=Network;
EOF
    chmod +x "$SHORTCUT_FILE"
}

# --- SETUP FUNCTIONS ---
setup_sync_timer() {
    REMOTE="$1"; LOCAL_PATH="$2"; SERVICE_NAME="rclone-sync-${REMOTE}"; REAL_RCLONE=$(readlink -f "$RCLONE_BIN")
    cat <<EOF > "$SYSTEMD_DIR/${SERVICE_NAME}.service"
[Unit]
Description=Sync $REMOTE to Local (Bisync)
After=network-online.target
[Service]
Type=oneshot
ExecStart=$REAL_RCLONE bisync "${REMOTE}:" "${LOCAL_PATH}" --create-empty-src-dirs --compare size,modtime,checksum --slow-hash-sync-only --resync --verbose
EOF
    cat <<EOF > "$SYSTEMD_DIR/${SERVICE_NAME}.timer"
[Unit]
Description=Timer for $REMOTE sync
[Timer]
OnBootSec=5min
OnUnitActiveSec=15min
[Install]
WantedBy=timers.target
EOF
    systemctl --user daemon-reload; systemctl --user enable --now "${SERVICE_NAME}.timer"
    if [ "$MODE" = "GUI" ]; then (echo "50"; systemctl --user start "${SERVICE_NAME}.service"; echo "100") | zenity --progress --pulsate --text="Syncing..." --auto-close --no-cancel; else systemctl --user start "${SERVICE_NAME}.service"; fi
    notify_user "Sync" "${TXT[SUCCESS_SYNC]}"; ui_msg "Success" "${TXT[SUCCESS_SYNC]}\nFolder: $LOCAL_PATH"
}

setup_mount_service() {
    REMOTE="$1"; MOUNT_POINT="$2"; SERVICE_NAME="rclone-mount-${REMOTE}"; REAL_RCLONE=$(readlink -f "$RCLONE_BIN")
    cat <<EOF > "$SYSTEMD_DIR/${SERVICE_NAME}.service"
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
    if [ "$MODE" = "GUI" ]; then (echo "100") | zenity --progress --pulsate --text="${TXT[CONN_PROG]}" --auto-close --no-cancel; fi
    if systemctl --user is-active --quiet "${SERVICE_NAME}.service"; then
        notify_user "Success" "$REMOTE mounted!"; ui_msg "${TXT[SUCCESS_MOUNT]}" "Path: <tt>$MOUNT_POINT</tt>"
    else ui_msg "Error" "${TXT[ERR_SERVICE]}"; fi
}

# --- TOOL: RENAME/STANDARDIZE ---
do_rename() {
    ALL_REMOTES=$("$RCLONE_BIN" listremotes 2>/dev/null)
    if [ -z "$ALL_REMOTES" ]; then ui_msg "Info" "${TXT[NO_CONFIG]}"; return; fi

    MENU_OPTS=()
    for line in $ALL_REMOTES; do
        clean="${line%:}"
        if [ -n "$clean" ]; then MENU_OPTS+=("$clean" "$clean"); fi
    done

    OLD_NAME=$(ui_select_list "${TXT[REN_TITLE]}" "${MENU_OPTS[@]}") || return

    TYPE=$("$RCLONE_BIN" config show "$OLD_NAME" | grep "type =" | head -n1 | cut -d= -f2 | tr -d ' ')
    if [ -z "$TYPE" ]; then TYPE="cloud"; fi

    SUFFIX=$(ui_input "${TXT[REN_NEW_NAME]} [${TYPE}-???]" "renomeado") || return
    SUFFIX=$(echo "$SUFFIX" | tr -cd '[:alnum:]_-')
    if [ -z "$SUFFIX" ]; then return; fi

    NEW_NAME="${TYPE}-${SUFFIX}"
    if [ "$NEW_NAME" == "$OLD_NAME" ]; then return; fi

    if ! ui_confirm "Confirm" "${TXT[WIZ_PREVIEW]} <b>$NEW_NAME</b>\n\nProceed?"; then return; fi

    CONFIG_FILE=$("$RCLONE_BIN" config file | grep ".conf" | tail -n1)

    systemctl --user stop "rclone-mount-${OLD_NAME}.service" 2>/dev/null
    systemctl --user disable "rclone-mount-${OLD_NAME}.service" 2>/dev/null
    rm "$SYSTEMD_DIR/rclone-mount-${OLD_NAME}.service" 2>/dev/null
    systemctl --user stop "rclone-sync-${OLD_NAME}.timer" 2>/dev/null
    systemctl --user stop "rclone-sync-${OLD_NAME}.service" 2>/dev/null
    systemctl --user disable "rclone-sync-${OLD_NAME}.timer" 2>/dev/null
    rm "$SYSTEMD_DIR/rclone-sync-${OLD_NAME}.timer" "$SYSTEMD_DIR/rclone-sync-${OLD_NAME}.service" 2>/dev/null

    systemctl --user daemon-reload
    sed -i "s/^\[$OLD_NAME\]$/\[$NEW_NAME\]/" "$CONFIG_FILE"

    if [ -d "$CLOUD_DIR/$OLD_NAME" ]; then mv "$CLOUD_DIR/$OLD_NAME" "$CLOUD_DIR/$NEW_NAME"; fi
    rm "$DESKTOP_DIR/$OLD_NAME.desktop" 2>/dev/null

    if [ -d "$CLOUD_DIR/$NEW_NAME" ]; then
        create_desktop_shortcut "$NEW_NAME" "$CLOUD_DIR/$NEW_NAME"
    fi
    ui_msg "Success" "${TXT[REN_SUCCESS]}\n${TXT[REN_WARN]}"
}

do_tools() {
    TOOL=$(ui_select_list "${TXT[TOOLS_TITLE]}" "RENAME" "${TXT[TOOL_RENAME]}" "DESKTOP" "${TXT[TOOL_DESKTOP]}" "FIX" "${TXT[TOOL_FIX]}") || return

    if [ "$TOOL" == "RENAME" ]; then do_rename; return; fi

    LIST=$(systemctl --user list-unit-files | grep "rclone-mount-" | grep "enabled" | awk '{print $1}')
    if [ -z "$LIST" ]; then ui_msg "Info" "${TXT[NO_CONFIG]}"; return; fi

    if [ "$TOOL" == "DESKTOP" ]; then
        for s in $LIST; do NAME=$(echo "$s" | sed 's/rclone-mount-//;s/.service//'); MOUNT_POINT=$(grep "ExecStart=" "$SYSTEMD_DIR/$s" | cut -d'"' -f2); if [ -n "$MOUNT_POINT" ]; then create_desktop_shortcut "$NAME" "$MOUNT_POINT"; fi; done
        notify_user "Desktop" "${TXT[MSG_DESKTOP]}"
    elif [ "$TOOL" == "FIX" ]; then
        # Agora a função FIX apenas re-aplica o ícone pai, pois não aplicamos mais dentro das pastas
        set_parent_icon
        notify_user "Icons" "${TXT[MSG_FIX]}"
    fi
}

do_wizard() {
    PROVIDER=$(ui_select_list "${TXT[WIZ_PROV]}" "drive" "Google Drive" "onedrive" "Microsoft OneDrive" "dropbox" "Dropbox" "s3" "Amazon S3" "mega" "Mega" "pcloud" "pCloud") || return
    SUFFIX=$(ui_input "${TXT[WIZ_NAME]} [${PROVIDER}-???]" "${TXT[WIZ_NAME_DEF]}") || return
    SUFFIX=$(echo "$SUFFIX" | tr -cd '[:alnum:]_-')
    if [ -z "$SUFFIX" ]; then return; fi

    NAME="${PROVIDER}-${SUFFIX}"
    if ! ui_confirm "Confirm" "${TXT[WIZ_PREVIEW]} <b>$NAME</b>\n\nProceed?"; then return; fi

    if "$RCLONE_BIN" listremotes | grep -q "^${NAME}:"; then ui_msg "Error" "${TXT[ERR_NAME_EXIST]}"; return; fi

    ui_msg "${TXT[AUTH_TITLE]}" "${TXT[AUTH_MSG]}"
    if [ "$MODE" = "GUI" ]; then
        TERM_FOUND=0; for term in konsole gnome-terminal xfce4-terminal x-terminal-emulator; do if command -v $term &> /dev/null; then $term -e "$RCLONE_BIN config create '$NAME' '$PROVIDER'"; TERM_FOUND=1; break; fi; done
        if [ $TERM_FOUND -eq 0 ]; then "$RCLONE_BIN" config create "$NAME" "$PROVIDER" & fi
    else "$RCLONE_BIN" config create "$NAME" "$PROVIDER"; fi

    if [ "$MODE" = "GUI" ]; then (echo "50"; sleep 3; echo "# ..."; sleep 3; echo "100") | zenity --progress --pulsate --text="${TXT[WAIT_AUTH]}" --auto-close --no-cancel; else sleep 5; fi

    if "$RCLONE_BIN" listremotes | grep -q "^${NAME}:"; then
        ui_msg "Success" "${TXT[SUCCESS_NEW]}"
        OP_MODE=$(ui_select_list "${TXT[MODE_TITLE]}\n${TXT[MODE_MSG]}" "MOUNT" "${TXT[MODE_MOUNT]} - ${TXT[MODE_MOUNT_DESC]}" "SYNC" "${TXT[MODE_SYNC]} - ${TXT[MODE_SYNC_DESC]}") || return
        LOCAL_FOLDER=$(ui_input_folder "$CLOUD_DIR/$NAME") || return
        mkdir -p "$LOCAL_FOLDER"
        if [ "$(ls -A "$LOCAL_FOLDER")" ]; then ui_msg "Error" "${TXT[ERR_EMPTY]}"; return; fi
        if [ "$OP_MODE" == "MOUNT" ]; then setup_mount_service "$NAME" "$LOCAL_FOLDER"; elif [ "$OP_MODE" == "SYNC" ]; then setup_sync_timer "$NAME" "$LOCAL_FOLDER"; fi
    else ui_msg "Error" "${TXT[ERR_VERIFY]}"; fi
}

do_manage() {
    LIST_M=$(systemctl --user list-unit-files | grep "rclone-mount-" | awk '{print $1}')
    LIST_S=$(systemctl --user list-unit-files | grep "rclone-sync-" | awk '{print $1}')
    MENU_OPTS=()
    if [ -n "$LIST_M" ]; then for s in $LIST_M; do PRETTY=$(echo "$s" | sed 's/rclone-mount-//;s/.service//'); MENU_OPTS+=("$s" "🔴 ${TXT[ACT_UNMOUNT]} (Mount): $PRETTY"); done; fi
    if [ -n "$LIST_S" ]; then for s in $LIST_S; do PRETTY=$(echo "$s" | sed 's/rclone-sync-//;s/.timer//'); MENU_OPTS+=("$s" "🔴 ${TXT[ACT_UNMOUNT]} (Sync): $PRETTY"); done; fi
    ALL_REMOTES=$("$RCLONE_BIN" listremotes)
    while read -r line; do clean="${line%:}"; if ! echo "$LIST_M $LIST_S" | grep -q "rclone-.*-${clean}"; then MENU_OPTS+=("ACTIVATE:$clean" "🟢 ${TXT[ACT_MOUNT]}: $clean"); fi; done <<< "$ALL_REMOTES"
    if [ ${#MENU_OPTS[@]} -eq 0 ]; then ui_msg "Info" "${TXT[NO_CONFIG]}"; return; fi
    SELECTION=$(ui_select_list "${TXT[MANAGE_TITLE]}" "${MENU_OPTS[@]}") || return
    if [[ "$SELECTION" == ACTIVATE:* ]]; then
        REMOTE=${SELECTION#ACTIVATE:}
        OP_MODE=$(ui_select_list "${TXT[MODE_TITLE]}" "MOUNT" "${TXT[MODE_MOUNT]}" "SYNC" "${TXT[MODE_SYNC]}") || return
        LOCAL_FOLDER=$(ui_input_folder "$CLOUD_DIR/$REMOTE") || return
        mkdir -p "$LOCAL_FOLDER"
        if [ "$OP_MODE" == "MOUNT" ]; then setup_mount_service "$REMOTE" "$LOCAL_FOLDER"; elif [ "$OP_MODE" == "SYNC" ]; then setup_sync_timer "$REMOTE" "$LOCAL_FOLDER"; fi
    else
        if ui_confirm "Confirm" "${TXT[CONFIRM_REM]}"; then
            if [[ "$SELECTION" == *.timer ]]; then BASE_NAME=${SELECTION%.timer}; systemctl --user stop "$SELECTION" "$BASE_NAME.service"; systemctl --user disable "$SELECTION"; rm "$SYSTEMD_DIR/$SELECTION" "$SYSTEMD_DIR/$BASE_NAME.service"; else systemctl --user stop "$SELECTION"; systemctl --user disable "$SELECTION"; rm "$SYSTEMD_DIR/$SELECTION"; fi
            systemctl --user daemon-reload; notify_user "Info" "${TXT[REMOVED]}"
        fi
    fi
}

do_advanced() {
    if [ "$MODE" = "GUI" ]; then
        for term in konsole gnome-terminal xfce4-terminal x-terminal-emulator; do if command -v $term &> /dev/null; then $term -e "$RCLONE_BIN config"; return; fi; done
        ui_msg "Error" "${TXT[ERR_TERM]}"
    else "$RCLONE_BIN" config; fi
}

# --- Run ---
detect_mode; install_system; set_parent_icon; check_deps
while true; do
    ACTION=$(ui_dashboard); if [ $? -ne 0 ]; then exit 0; fi
    case $ACTION in 1) do_wizard ;; 2) do_manage ;; 3) do_tools ;; 4) do_advanced ;; 5|"") exit 0 ;; esac
done

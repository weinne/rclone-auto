#!/bin/bash

# ==========================================
# RClone Auto v19.0 (Global Edition)
# Autor: Weinne
# Feature: Internacionalização (i18n) PT/EN automática
# ==========================================

# --- Configurações ---
APP_NAME="rclone-auto"
PRETTY_NAME="RClone Auto"
SYSTEM_ICON="folder-cloud"

# Diretórios
USER_BIN_DIR="$HOME/.local/bin"
SYSTEMD_DIR="$HOME/.config/systemd/user"
SHORTCUT_DIR="$HOME/.local/share/applications"

# Caminhos
CURRENT_PATH=$(readlink -f "$0")
TARGET_BIN="$USER_BIN_DIR/$APP_NAME"

mkdir -p "$USER_BIN_DIR" "$SYSTEMD_DIR" "$HOME/Nuvem" "$SHORTCUT_DIR"
export PATH="$USER_BIN_DIR:$PATH"

# Rclone Binário
if [ -f "$USER_BIN_DIR/rclone" ]; then RCLONE_BIN="$USER_BIN_DIR/rclone"
else RCLONE_BIN=$(which rclone 2>/dev/null || echo "$USER_BIN_DIR/rclone"); fi

# --- 1. Sistema de Internacionalização (i18n) ---
declare -A TXT

# Define Inglês como padrão (Default)
TXT[WELCOME_TITLE]="Welcome to"
TXT[WELCOME_MSG]="Active Connections:"
TXT[BTN_NEW]="New Connection"
TXT[DESC_NEW]="Add Google Drive, OneDrive, S3..."
TXT[BTN_MANAGE]="Manage Drives"
TXT[DESC_MANAGE]="Mount, unmount or remove drives"
TXT[BTN_ADV]="Advanced Config"
TXT[DESC_ADV]="Open Rclone terminal wizard"
TXT[BTN_EXIT]="Exit"
TXT[DESC_EXIT]="Close application"
TXT[ERR_FUSE]="FUSE not found.\nPlease run: sudo apt install fuse3"
TXT[ASK_DL_RCLONE]="Rclone not found. Download official version now?"
TXT[DL_PROG]="Downloading Rclone..."
TXT[WIZ_PROV]="Select Provider"
TXT[WIZ_NAME]="Connection Name (no spaces):"
TXT[WIZ_NAME_DEF]="MyDrive"
TXT[ERR_NAME_EXIST]="Name already exists."
TXT[AUTH_TITLE]="Authorization"
TXT[AUTH_MSG]="Your browser will open.\nPlease login and authorize access."
TXT[WAIT_AUTH]="Waiting for authorization..."
TXT[SUCCESS_NEW]="Connection created! Mount it now?"
TXT[ERR_VERIFY]="Could not verify connection."
TXT[SEL_MOUNT]="Select service to mount:"
TXT[SEL_FOLDER]="Select mount folder"
TXT[ERR_EMPTY]="Folder must be empty."
TXT[CONN_PROG]="Connecting..."
TXT[SUCCESS_MOUNT]="Mounted successfully!"
TXT[ERR_SERVICE]="Failed to start service."
TXT[MANAGE_TITLE]="Manage Connections"
TXT[ACT_UNMOUNT]="Disconnect"
TXT[ACT_MOUNT]="Mount"
TXT[CONFIRM_REM]="Disconnect and remove service?"
TXT[REMOVED]="Service removed."
TXT[ERR_TERM]="Terminal not found. Run 'rclone config' manually."
TXT[NO_CONFIG]="No accounts configured."

# Sobrescreve se for Português
if [[ "$LANG" == pt* ]]; then
    TXT[WELCOME_TITLE]="Bem-vindo ao"
    TXT[WELCOME_MSG]="Conexões Ativas:"
    TXT[BTN_NEW]="Nova Conexão"
    TXT[DESC_NEW]="Adicionar Google Drive, OneDrive, S3..."
    TXT[BTN_MANAGE]="Gerenciar"
    TXT[DESC_MANAGE]="Ativar, desativar ou remover drives"
    TXT[BTN_ADV]="Avançado"
    TXT[DESC_ADV]="Terminal do Rclone"
    TXT[BTN_EXIT]="Sair"
    TXT[DESC_EXIT]="Fechar o aplicativo"
    TXT[ERR_FUSE]="FUSE não encontrado.\nRode: sudo apt install fuse3"
    TXT[ASK_DL_RCLONE]="Rclone ausente. Baixar versão oficial agora?"
    TXT[DL_PROG]="Baixando Rclone..."
    TXT[WIZ_PROV]="Qual serviço conectar?"
    TXT[WIZ_NAME]="Nome da conexão (sem espaços):"
    TXT[WIZ_NAME_DEF]="MeuDrive"
    TXT[ERR_NAME_EXIST]="Este nome já existe."
    TXT[AUTH_TITLE]="Autorização"
    TXT[AUTH_MSG]="Seu navegador será aberto.\nFaça login e autorize o acesso."
    TXT[WAIT_AUTH]="Aguardando autorização..."
    TXT[SUCCESS_NEW]="Conexão criada! Montar agora?"
    TXT[ERR_VERIFY]="Não consegui verificar a conexão."
    TXT[SEL_MOUNT]="Qual serviço montar?"
    TXT[SEL_FOLDER]="Selecione a pasta"
    TXT[ERR_EMPTY]="A pasta deve estar vazia."
    TXT[CONN_PROG]="Conectando..."
    TXT[SUCCESS_MOUNT]="Montado com sucesso!"
    TXT[ERR_SERVICE]="Falha ao iniciar serviço."
    TXT[MANAGE_TITLE]="Gerenciar Conexões"
    TXT[ACT_UNMOUNT]="Desconectar"
    TXT[ACT_MOUNT]="Montar"
    TXT[CONFIRM_REM]="Desconectar e remover serviço?"
    TXT[REMOVED]="Serviço removido."
    TXT[ERR_TERM]="Terminal não encontrado. Rode 'rclone config'."
    TXT[NO_CONFIG]="Nenhuma conta configurada."
fi

# --- 2. Instalação e Menu ---
install_system() {
    if [ "$CURRENT_PATH" != "$TARGET_BIN" ]; then
        cp "$CURRENT_PATH" "$TARGET_BIN"; chmod +x "$TARGET_BIN"; FINAL_EXEC_PATH="$TARGET_BIN"
    else FINAL_EXEC_PATH="$CURRENT_PATH"; fi

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
    if command -v update-desktop-database &> /dev/null; then update-desktop-database "$SHORTCUT_DIR" 2>/dev/null; fi
    if command -v kbuildsycoca6 &> /dev/null; then kbuildsycoca6 --noincremental &> /dev/null; fi
    touch "$SHORTCUT_DIR"
}

# --- 3. Wrappers Visuais ---
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
    ACTIVE_COUNT=$(systemctl --user list-unit-files | grep "rclone-mount-" | grep "enabled" | wc -l)
    TEXT="${TXT[WELCOME_TITLE]} <b>$PRETTY_NAME</b>.\n${TXT[WELCOME_MSG]} <b>$ACTIVE_COUNT</b>"
    if [ "$MODE" = "GUI" ]; then get_zen_opts; zenity --list --column="ID" --column="Ação" --column="Descrição" --hide-column=1 --text="$TEXT" "${ZEN_ARGS[@]}" --hide-header \
        "1" "☁️  ${TXT[BTN_NEW]}" "${TXT[DESC_NEW]}" \
        "2" "⚙️  ${TXT[BTN_MANAGE]}" "${TXT[DESC_MANAGE]}" \
        "3" "🔧  ${TXT[BTN_ADV]}" "${TXT[DESC_ADV]}" \
        "4" "🚪  ${TXT[BTN_EXIT]}" "${TXT[DESC_EXIT]}"
    else whiptail --title "$PRETTY_NAME" --menu "Menu" 20 70 10 "1" "${TXT[BTN_NEW]}" "2" "${TXT[BTN_MANAGE]}" "3" "${TXT[BTN_ADV]}" "4" "${TXT[BTN_EXIT]}" 3>&1 1>&2 2>&3; fi
}

check_deps() {
    if ! command -v fusermount &> /dev/null && ! command -v fusermount3 &> /dev/null; then ui_msg "Error" "${TXT[ERR_FUSE]}"; exit 1; fi
    if ! command -v "$RCLONE_BIN" &> /dev/null; then
        if ui_confirm "Rclone" "${TXT[ASK_DL_RCLONE]}"; then
             if [ "$MODE" = "GUI" ]; then (echo "10"; curl -L https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rclone.zip; echo "100") | zenity --progress --pulsate --text="${TXT[DL_PROG]}" --auto-close; else curl -L https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rclone.zip; fi
             unzip -o /tmp/rclone.zip -d /tmp/inst > /dev/null; mv /tmp/inst/rclone-*-linux-amd64/rclone "$USER_BIN_DIR/"; chmod +x "$USER_BIN_DIR/rclone"; rm -rf /tmp/inst /tmp/rclone.zip; RCLONE_BIN="$USER_BIN_DIR/rclone"
        else exit 1; fi
    fi
}

# --- 4. Funções Principais ---
do_wizard() {
    PROVIDER=$(ui_select_list "${TXT[WIZ_PROV]}" "drive" "Google Drive" "onedrive" "Microsoft OneDrive" "dropbox" "Dropbox" "s3" "Amazon S3" "mega" "Mega" "pcloud" "pCloud") || return
    NAME=$(ui_input "${TXT[WIZ_NAME]}" "${TXT[WIZ_NAME_DEF]}") || return
    NAME=$(echo "$NAME" | tr -cd '[:alnum:]_-')
    if [ -z "$NAME" ]; then return; fi
    if "$RCLONE_BIN" listremotes | grep -q "^${NAME}:"; then ui_msg "Error" "${TXT[ERR_NAME_EXIST]}"; return; fi

    ui_msg "${TXT[AUTH_TITLE]}" "${TXT[AUTH_MSG]}"
    if [ "$MODE" = "GUI" ]; then
        TERM_FOUND=0; for term in konsole gnome-terminal xfce4-terminal x-terminal-emulator; do if command -v $term &> /dev/null; then $term -e "$RCLONE_BIN config create '$NAME' '$PROVIDER'"; TERM_FOUND=1; break; fi; done
        if [ $TERM_FOUND -eq 0 ]; then "$RCLONE_BIN" config create "$NAME" "$PROVIDER" & fi
    else "$RCLONE_BIN" config create "$NAME" "$PROVIDER"; fi

    if [ "$MODE" = "GUI" ]; then (echo "50"; sleep 3; echo "# ..."; sleep 3; echo "100") | zenity --progress --pulsate --text="${TXT[WAIT_AUTH]}" --auto-close --no-cancel; else sleep 5; fi

    if "$RCLONE_BIN" listremotes | grep -q "^${NAME}:"; then
        if ui_confirm "Success" "${TXT[SUCCESS_NEW]}"; then do_mount "$NAME"; fi
    else ui_msg "Error" "${TXT[ERR_VERIFY]}"; fi
}

do_mount() {
    REMOTE="$1"
    if [ -z "$REMOTE" ]; then
        REMOTES=$("$RCLONE_BIN" listremotes); if [ -z "$REMOTES" ]; then ui_msg "Info" "${TXT[NO_CONFIG]}"; return; fi
        MENU_ITEMS=(); while read -r line; do clean="${line%:}"; MENU_ITEMS+=("$clean" "Cloud"); done <<< "$REMOTES"
        REMOTE=$(ui_select_list "${TXT[SEL_MOUNT]}" "${MENU_ITEMS[@]}") || return
    fi
    MOUNT_POINT=$(ui_input_folder "$HOME/Nuvem/$REMOTE") || return
    mkdir -p "$MOUNT_POINT"
    if [ "$(ls -A "$MOUNT_POINT")" ]; then ui_msg "Error" "${TXT[ERR_EMPTY]}"; return; fi

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
    if [ "$MODE" = "GUI" ]; then (echo "100") | zenity --progress --pulsate --text="${TXT[CONN_PROG]}" --auto-close --no-cancel; fi
    if systemctl --user is-active --quiet "${SERVICE_NAME}.service"; then notify_user "Success" "$REMOTE mounted!"; ui_msg "${TXT[SUCCESS_MOUNT]}" "Path: <tt>$MOUNT_POINT</tt>"; else ui_msg "Error" "${TXT[ERR_SERVICE]}"; fi
}

do_manage() {
    LIST=$(systemctl --user list-unit-files | grep "rclone-mount-" | awk '{print $1}')
    MENU_OPTS=(); if [ -n "$LIST" ]; then for s in $LIST; do PRETTY=$(echo "$s" | sed 's/rclone-mount-//;s/.service//'); MENU_OPTS+=("$s" "🔴 ${TXT[ACT_UNMOUNT]}: $PRETTY"); done; fi
    ALL_REMOTES=$("$RCLONE_BIN" listremotes); while read -r line; do clean="${line%:}"; if ! echo "$LIST" | grep -q "rclone-mount-${clean}"; then MENU_OPTS+=("MOUNT:$clean" "🟢 ${TXT[ACT_MOUNT]}: $clean"); fi; done <<< "$ALL_REMOTES"
    if [ ${#MENU_OPTS[@]} -eq 0 ]; then ui_msg "Info" "${TXT[NO_CONFIG]}"; return; fi
    SELECTION=$(ui_select_list "${TXT[MANAGE_TITLE]}" "${MENU_OPTS[@]}") || return
    if [[ "$SELECTION" == MOUNT:* ]]; then do_mount "${SELECTION#MOUNT:}"; else
        if ui_confirm "Confirm" "${TXT[CONFIRM_REM]}"; then systemctl --user stop "$SELECTION"; systemctl --user disable "$SELECTION"; rm "$SYSTEMD_DIR/$SELECTION"; systemctl --user daemon-reload; notify_user "Info" "${TXT[REMOVED]}"; fi
    fi
}

do_advanced() {
    if [ "$MODE" = "GUI" ]; then
        for term in konsole gnome-terminal xfce4-terminal x-terminal-emulator; do if command -v $term &> /dev/null; then $term -e "$RCLONE_BIN config"; return; fi; done
        ui_msg "Error" "${TXT[ERR_TERM]}"
    else "$RCLONE_BIN" config; fi
}

# --- Run ---
detect_mode; install_system; check_deps
while true; do
    ACTION=$(ui_dashboard); if [ $? -ne 0 ]; then exit 0; fi
    case $ACTION in 1) do_wizard ;; 2) do_manage ;; 3) do_advanced ;; 4|"") exit 0 ;; esac
done

#!/bin/bash

# ==========================================
# RClone Auto v31.0 (CLI/TUI Ultimate)
# Autor: Weinne
# Feature: Interface TUI pura, Auto-Launch de Terminal e Comandos via flag (--)
# ==========================================

# --- Configurações ---
APP_NAME="rclone-auto"
PRETTY_NAME="RClone Auto"
SYSTEM_ICON="folder-remote"

# Diretórios
USER_BIN_DIR="$HOME/.local/bin"
SYSTEMD_DIR="$HOME/.config/systemd/user"
SHORTCUT_DIR="$HOME/.local/share/applications"
CLOUD_DIR="$HOME/Nuvem"

# Caminhos
CURRENT_PATH=$(readlink -f "$0")
TARGET_BIN="$USER_BIN_DIR/$APP_NAME"

mkdir -p "$USER_BIN_DIR" "$SYSTEMD_DIR" "$CLOUD_DIR" "$SHORTCUT_DIR"
export PATH="$USER_BIN_DIR:$PATH"

# Binário Rclone (será detectado)
RCLONE_BIN=""

# --- 1. Terminal Auto-Launcher ---
# Se não estiver rodando em um terminal (ex: clicou no menu), abre um emulador.
ensure_terminal() {
    if [ ! -t 0 ]; then
        # Lista de preferência de terminais
        for term in konsole gnome-terminal xfce4-terminal terminator xterm; do
            if command -v $term &> /dev/null; then
                # Executa o próprio script dentro do terminal encontrado
                $term -e "$CURRENT_PATH"
                exit 0
            fi
        done
        # Se não achar terminal nenhum (muito raro)
        notify-send "Erro" "Nenhum terminal encontrado para abrir o Rclone Auto."
        exit 1
    fi
}

# --- 2. Funções TUI (Whiptail) ---
# Wrappers simples para manter o código limpo

ui_msg() {
    whiptail --title "$PRETTY_NAME" --msgbox "$1\n\n$2" 12 70
}

ui_yesno() {
    whiptail --title "$PRETTY_NAME" --yesno "$1" 10 60
}

ui_input() {
    # $1 = Titulo, $2 = Valor Padrão
    whiptail --title "$PRETTY_NAME" --inputbox "$1" 10 60 "$2" 3>&1 1>&2 2>&3
}

ui_menu() {
    # $1 = Titulo, $2... = Opções
    TITLE="$1"; shift
    whiptail --title "$PRETTY_NAME" --menu "$TITLE" 20 70 10 "$@" 3>&1 1>&2 2>&3
}

# --- 3. Instalação e Atualização ---
install_system() {
    if [ "$CURRENT_PATH" != "$TARGET_BIN" ]; then
        cp -f "$CURRENT_PATH" "$TARGET_BIN"
        chmod +x "$TARGET_BIN"
    fi

    DESKTOP_FILE="$SHORTCUT_DIR/$APP_NAME.desktop"
    cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Name=$PRETTY_NAME
Comment=Gerenciador de Nuvens (TUI)
Exec="$TARGET_BIN"
Icon=$SYSTEM_ICON
Terminal=true
Type=Application
Categories=Utility;Network;System;
StartupWMClass=$APP_NAME
EOF
    chmod +x "$DESKTOP_FILE"

    if command -v update-desktop-database &> /dev/null; then update-desktop-database "$SHORTCUT_DIR" 2>/dev/null; fi
    touch "$SHORTCUT_DIR"

    # Ícone Pai
    if [ -d "$CLOUD_DIR" ]; then echo -e "[Desktop Entry]\nIcon=$SYSTEM_ICON\nType=Directory" > "$CLOUD_DIR/.directory" 2>/dev/null; fi
}

# --- 4. Checagem de Dependências ---
check_deps() {
    if ! command -v fusermount &> /dev/null && ! command -v fusermount3 &> /dev/null; then
        echo "Erro: FUSE ausente. Instale 'fuse3'."
        exit 1
    fi

    if [ -f "$USER_BIN_DIR/rclone" ]; then RCLONE_BIN="$USER_BIN_DIR/rclone"; elif command -v rclone &> /dev/null; then RCLONE_BIN=$(command -v rclone); fi

    if [ -z "$RCLONE_BIN" ]; then
        if ui_yesno "Rclone não encontrado.\nDeseja baixar a versão portátil oficial agora?"; then
             curl -L https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rclone.zip
             unzip -o /tmp/rclone.zip -d /tmp/inst > /dev/null
             mv /tmp/inst/rclone-*-linux-amd64/rclone "$USER_BIN_DIR/"; chmod +x "$USER_BIN_DIR/rclone"; rm -rf /tmp/inst /tmp/rclone.zip
             RCLONE_BIN="$USER_BIN_DIR/rclone"
             ui_msg "Sucesso" "Rclone instalado em $USER_BIN_DIR"
        else
            echo "Rclone necessário. Saindo."
            exit 1
        fi
    fi
}

# --- 5. Funções Core (Lógica) ---

setup_sync_timer() {
    REMOTE="$1"; LOCAL_PATH="$2"; SERVICE_NAME="rclone-sync-${REMOTE}"; REAL_RCLONE=$(readlink -f "$RCLONE_BIN")
    cat <<EOF > "$SYSTEMD_DIR/${SERVICE_NAME}.service"
[Unit]
Description=Sync $REMOTE (Bisync)
After=network-online.target
[Service]
Type=oneshot
ExecStart=$REAL_RCLONE bisync "${REMOTE}:" "${LOCAL_PATH}" --create-empty-src-dirs --compare size,modtime,checksum --slow-hash-sync-only --resync --verbose
EOF
    cat <<EOF > "$SYSTEMD_DIR/${SERVICE_NAME}.timer"
[Unit]
Description=Timer 15min $REMOTE
[Timer]
OnBootSec=5min
OnUnitActiveSec=15min
[Install]
WantedBy=timers.target
EOF
    systemctl --user daemon-reload; systemctl --user enable --now "${SERVICE_NAME}.timer"
    systemctl --user start "${SERVICE_NAME}.service"
    echo "Sync agendado para $REMOTE em $LOCAL_PATH"
}

setup_mount_service() {
    REMOTE="$1"; MOUNT_POINT="$2"; SERVICE_NAME="rclone-mount-${REMOTE}"; REAL_RCLONE=$(readlink -f "$RCLONE_BIN")
    cat <<EOF > "$SYSTEMD_DIR/${SERVICE_NAME}.service"
[Unit]
Description=Mount $REMOTE
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
    # Aplica ícone pai (segurança)
    if [ -d "$CLOUD_DIR" ]; then echo -e "[Desktop Entry]\nIcon=$SYSTEM_ICON\nType=Directory" > "$CLOUD_DIR/.directory" 2>/dev/null; fi
    echo "Montagem iniciada: $REMOTE -> $MOUNT_POINT"
}

stop_service() {
    NAME="$1"
    # Tenta parar mount e sync
    systemctl --user stop "rclone-mount-${NAME}.service" 2>/dev/null
    systemctl --user disable "rclone-mount-${NAME}.service" 2>/dev/null
    rm "$SYSTEMD_DIR/rclone-mount-${NAME}.service" 2>/dev/null

    systemctl --user stop "rclone-sync-${NAME}.timer" 2>/dev/null
    systemctl --user stop "rclone-sync-${NAME}.service" 2>/dev/null
    systemctl --user disable "rclone-sync-${NAME}.timer" 2>/dev/null
    rm "$SYSTEMD_DIR/rclone-sync-${NAME}.timer" "$SYSTEMD_DIR/rclone-sync-${NAME}.service" 2>/dev/null

    systemctl --user daemon-reload
    echo "Serviços parados para: $NAME"
}

# --- 6. Menus TUI ---

do_wizard() {
    PROVIDER=$(ui_menu "Selecione o Provedor" "drive" "Google Drive" "onedrive" "Microsoft OneDrive" "dropbox" "Dropbox" "s3" "Amazon S3" "mega" "Mega" "pcloud" "pCloud") || return
    SUFFIX=$(ui_input "Sufixo do nome [${PROVIDER}-???]" "pessoal") || return
    SUFFIX=$(echo "$SUFFIX" | tr -cd '[:alnum:]_-')
    [ -z "$SUFFIX" ] && return

    NAME="${PROVIDER}-${SUFFIX}"
    if "$RCLONE_BIN" listremotes | grep -q "^${NAME}:"; then ui_msg "Erro" "Nome $NAME já existe."; return; fi

    ui_msg "Autorização" "O navegador será aberto para login em: $PROVIDER"
    "$RCLONE_BIN" config create "$NAME" "$PROVIDER"

    if "$RCLONE_BIN" listremotes | grep -q "^${NAME}:"; then
        MODE=$(ui_menu "Como deseja utilizar?" "MOUNT" "Disco Virtual (Mount)" "SYNC" "Cópia Offline (Sync 15min)") || return

        # Local padrão
        LOCAL="$CLOUD_DIR/$NAME"
        if ui_yesno "Usar pasta padrão?\n$LOCAL"; then
            mkdir -p "$LOCAL"
        else
            LOCAL=$(ui_input "Caminho completo da pasta:" "$LOCAL")
            mkdir -p "$LOCAL"
        fi

        if [ "$MODE" == "MOUNT" ]; then setup_mount_service "$NAME" "$LOCAL"; else setup_sync_timer "$NAME" "$LOCAL"; fi
        ui_msg "Sucesso" "Configuração concluída!"
    else
        ui_msg "Erro" "Falha ao criar conexão."
    fi
}

do_manage() {
    # Lista de ativos
    LIST_RAW=$(systemctl --user list-unit-files | grep -E "rclone-(mount|sync)-" | grep "enabled" | awk '{print $1}')

    # Lista de Remotes do Rclone
    REMOTES_RAW=$("$RCLONE_BIN" listremotes 2>/dev/null)

    MENU_ITENS=()

    # Adiciona remotes disponíveis para ativar
    for r in $REMOTES_RAW; do
        clean="${r%:}"
        if ! echo "$LIST_RAW" | grep -q "$clean"; then
            MENU_ITENS+=("START:$clean" "🟢 Ativar: $clean")
        fi
    done

    # Adiciona serviços ativos para parar
    for s in $LIST_RAW; do
        clean=$(echo "$s" | sed -E 's/rclone-(mount|sync)-//;s/\.(service|timer)//')
        type="Mount"
        [[ "$s" == *"sync"* ]] && type="Sync"
        # Evita duplicatas visuais se tiver timer e service
        if [[ ! "${MENU_ITENS[*]}" =~ "STOP:$clean" ]]; then
            MENU_ITENS+=("STOP:$clean" "🔴 Parar ($type): $clean")
        fi
    done

    if [ ${#MENU_ITENS[@]} -eq 0 ]; then ui_msg "Info" "Nada para gerenciar."; return; fi

    SEL=$(ui_menu "Gerenciar Conexões" "${MENU_ITENS[@]}") || return

    if [[ "$SEL" == START:* ]]; then
        NAME=${SEL#START:}
        MODE=$(ui_menu "Modo" "MOUNT" "Mount" "SYNC" "Sync") || return
        mkdir -p "$CLOUD_DIR/$NAME"
        if [ "$MODE" == "MOUNT" ]; then setup_mount_service "$NAME" "$CLOUD_DIR/$NAME"; else setup_sync_timer "$NAME" "$CLOUD_DIR/$NAME"; fi
        ui_msg "OK" "Iniciado."
    elif [[ "$SEL" == STOP:* ]]; then
        NAME=${SEL#STOP:}
        stop_service "$NAME"
        ui_msg "OK" "Parado e removido do boot."
    fi
}

do_rename() {
    # Pega lista limpa
    REMOTES=$("$RCLONE_BIN" listremotes 2>/dev/null)
    [ -z "$REMOTES" ] && return

    MENU=()
    for r in $REMOTES; do clean="${r%:}"; MENU+=("$clean" "$clean"); done

    OLD=$(ui_menu "Renomear/Padronizar" "${MENU[@]}") || return

    TYPE=$("$RCLONE_BIN" config show "$OLD" | grep "type =" | head -n1 | cut -d= -f2 | tr -d ' ')
    [ -z "$TYPE" ] && TYPE="cloud"

    SUF=$(ui_input "Novo Sufixo [${TYPE}-???]" "novo") || return
    NEW="${TYPE}-${SUF}"

    if [ "$NEW" == "$OLD" ]; then return; fi

    stop_service "$OLD"

    CONF=$("$RCLONE_BIN" config file | grep ".conf" | tail -n1)
    sed -i "s/^\[$OLD\]$/\[$NEW\]/" "$CONF"

    if [ -d "$CLOUD_DIR/$OLD" ]; then mv "$CLOUD_DIR/$OLD" "$CLOUD_DIR/$NEW"; fi

    ui_msg "Sucesso" "Renomeado para $NEW.\nVá em Gerenciar para ativar novamente."
}


# --- 7. Argumentos CLI (Ações Diretas) ---
show_help() {
    echo "Uso: rclone-auto [OPÇÃO]"
    echo ""
    echo "  (sem args)      Abre o menu interativo (TUI)"
    echo "  --list          Lista conexões ativas e disponíveis"
    echo "  --stop <nome>   Para a montagem/sync de uma conexão"
    echo "  --mount <nome>  Monta uma conexão existente (pasta padrão)"
    echo "  --sync <nome>   Agenda sync para uma conexão (pasta padrão)"
    echo "  --install       Força a (re)instalação do script/atalhos"
    echo "  --help          Mostra esta ajuda"
    exit 0
}

if [ "$#" -gt 0 ]; then
    # Estamos no modo CLI
    check_deps # Garante que rclone existe

    case "$1" in
        --list)
            echo "--- Ativos (Systemd) ---"
            systemctl --user list-unit-files | grep -E "rclone-(mount|sync)-" | grep "enabled"
            echo ""
            echo "--- Disponíveis (Rclone) ---"
            "$RCLONE_BIN" listremotes
            ;;
        --stop)
            if [ -z "$2" ]; then echo "Informe o nome. Ex: --stop drive-pessoal"; exit 1; fi
            stop_service "$2"
            ;;
        --mount)
            if [ -z "$2" ]; then echo "Informe o nome."; exit 1; fi
            mkdir -p "$CLOUD_DIR/$2"
            setup_mount_service "$2" "$CLOUD_DIR/$2"
            ;;
        --sync)
            if [ -z "$2" ]; then echo "Informe o nome."; exit 1; fi
            mkdir -p "$CLOUD_DIR/$2"
            setup_sync_timer "$2" "$CLOUD_DIR/$2"
            ;;
        --install)
            install_system
            echo "Instalação forçada concluída."
            ;;
        --help|-h)
            show_help
            ;;
        *)
            echo "Opção inválida: $1"
            show_help
            ;;
    esac
    exit 0
fi

# --- 8. Loop Principal (Modo Interativo) ---

# Se chegou aqui, não tem argumentos.
ensure_terminal # Garante que está no Konsole/Terminal
install_system  # Auto-update silencioso
check_deps      # Garante dependencias

while true; do
    # Dashboard simples no titulo do menu
    ACTIVES=$(systemctl --user list-unit-files | grep -E "rclone-(mount|sync)-" | grep "enabled" | wc -l)

    CHOICE=$(whiptail --title "$PRETTY_NAME" --menu "Ativos: $ACTIVES" 20 70 10 \
        "1" "Nova Conexão (Wizard)" \
        "2" "Gerenciar (Ativar/Parar)" \
        "3" "Renomear/Padronizar" \
        "4" "Console Rclone (Avançado)" \
        "0" "Sair" 3>&1 1>&2 2>&3)

    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then exit 0; fi

    case "$CHOICE" in
        1) do_wizard ;;
        2) do_manage ;;
        3) do_rename ;;
        4) "$RCLONE_BIN" config ;;
        0) clear; exit 0 ;;
    esac
done

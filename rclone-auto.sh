#!/bin/bash

# ==========================================
# RClone Auto v42.0 (The Real Fix)
# Autor: Weinne
# Feature: Correção na detecção de provedores usando 'rclone help backends'
# ==========================================

# --- Configurações Visuais (Gum Theme) ---
export GUM_CHOOSE_CURSOR="👉 "
export GUM_CHOOSE_CURSOR_FOREGROUND="#00FFFF" # Cyan
export GUM_CHOOSE_ITEM_FOREGROUND="#FFFFFF"   # Branco
export GUM_CHOOSE_SELECTED_FOREGROUND="#00FFFF" # Cyan
export GUM_CONFIRM_SELECTED_BACKGROUND="#008080" # Teal

# Diretórios
APP_NAME="rclone-auto"
USER_BIN_DIR="$HOME/.local/bin"
SYSTEMD_DIR="$HOME/.config/systemd/user"
SHORTCUT_DIR="$HOME/.local/share/applications"
CLOUD_DIR="$HOME/Nuvem"
SYSTEM_ICON="folder-remote"

CURRENT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$CURRENT_PATH")
TARGET_BIN="$USER_BIN_DIR/$APP_NAME"

mkdir -p "$USER_BIN_DIR" "$SYSTEMD_DIR" "$CLOUD_DIR" "$SHORTCUT_DIR"
export PATH="$USER_BIN_DIR:$PATH"

# Binários
RCLONE_BIN=""
GUM_BIN=""

# --- 1. Inicialização ---

ensure_terminal() {
    if [ ! -t 0 ]; then
        for term in konsole gnome-terminal xfce4-terminal terminator xterm; do
            if command -v $term &> /dev/null; then $term -e "$CURRENT_PATH"; exit 0; fi
        done
        exit 1
    fi
}

check_deps() {
    # FUSE
    if ! command -v fusermount &> /dev/null && ! command -v fusermount3 &> /dev/null; then
        echo "❌ Erro: FUSE ausente. Instale 'fuse3'."
        read -p "Enter..."
        exit 1
    fi

    # RCLONE
    if [ -f "$USER_BIN_DIR/rclone" ]; then RCLONE_BIN="$USER_BIN_DIR/rclone"; elif command -v rclone &> /dev/null; then RCLONE_BIN=$(command -v rclone); fi
    if [ -z "$RCLONE_BIN" ]; then
        echo "⬇️  Baixando Rclone..."
        curl -L https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rclone.zip
        unzip -o /tmp/rclone.zip -d /tmp/inst > /dev/null
        mv /tmp/inst/rclone-*-linux-amd64/rclone "$USER_BIN_DIR/"
        chmod +x "$USER_BIN_DIR/rclone"
        rm -rf /tmp/inst /tmp/rclone.zip
        RCLONE_BIN="$USER_BIN_DIR/rclone"
    fi

    # GUM
    if [ -f "$SCRIPT_DIR/gum" ] && [ -x "$SCRIPT_DIR/gum" ]; then GUM_BIN="$SCRIPT_DIR/gum"
    elif [ -f "$USER_BIN_DIR/gum" ]; then GUM_BIN="$USER_BIN_DIR/gum"
    elif command -v gum &> /dev/null; then GUM_BIN=$(command -v gum); fi

    if [ -z "$GUM_BIN" ]; then
        echo "🌐 Baixando interface Gum..."
        ARCH=$(uname -m); case $ARCH in x86_64) GUM_ARCH="x86_64";; aarch64|arm64) GUM_ARCH="arm64";; *) echo "Arch $ARCH não suportada."; exit 1;; esac
        VERSION="0.14.5"
        curl -L -o /tmp/gum.tar.gz "https://github.com/charmbracelet/gum/releases/download/v${VERSION}/gum_${VERSION}_Linux_${GUM_ARCH}.tar.gz"
        tar -xzf /tmp/gum.tar.gz -C /tmp/
        mv $(find /tmp -name gum -type f -executable | head -n 1) "$USER_BIN_DIR/"
        chmod +x "$USER_BIN_DIR/gum"
        GUM_BIN="$USER_BIN_DIR/gum"
        rm -rf /tmp/gum*
    fi
}

install_system() {
    if [ "$CURRENT_PATH" != "$TARGET_BIN" ]; then cp -f "$CURRENT_PATH" "$TARGET_BIN"; chmod +x "$TARGET_BIN"; fi
    if [ "$GUM_BIN" == "$SCRIPT_DIR/gum" ] && [ ! -f "$USER_BIN_DIR/gum" ]; then cp "$SCRIPT_DIR/gum" "$USER_BIN_DIR/"; chmod +x "$USER_BIN_DIR/gum"; fi

    DESKTOP_FILE="$SHORTCUT_DIR/$APP_NAME.desktop"
    echo -e "[Desktop Entry]\nName=RClone Auto\nComment=Gerenciador de Nuvens\nExec=\"$TARGET_BIN\"\nIcon=$SYSTEM_ICON\nTerminal=true\nType=Application\nCategories=Utility;Network;" > "$DESKTOP_FILE"
    chmod +x "$DESKTOP_FILE"
    if command -v update-desktop-database &> /dev/null; then update-desktop-database "$SHORTCUT_DIR" 2>/dev/null; fi
    if [ -d "$CLOUD_DIR" ]; then echo -e "[Desktop Entry]\nIcon=$SYSTEM_ICON\nType=Directory" > "$CLOUD_DIR/.directory" 2>/dev/null; fi
}

# --- 2. Wrappers Visuais ---

ui_header() {
    clear
    $GUM_BIN style --foreground 212 --border-foreground 212 --border double --align center --width 50 --margin "1 2" --padding "0 2" "☁️  RClone Auto"
}

ui_success() { $GUM_BIN style --foreground 46 "✅ $1"; sleep 1.5; }
ui_error() { $GUM_BIN style --foreground 196 "❌ $1"; $GUM_BIN confirm "Ok" --affirmative "Entendi" --negative ""; }

# --- 3. Lógica de Serviços ---

setup_sync() {
    REMOTE="$1"; LOCAL="$CLOUD_DIR/$REMOTE"
    mkdir -p "$LOCAL"
    cat <<EOF > "$SYSTEMD_DIR/rclone-sync-${REMOTE}.service"
[Unit]
Description=Sync $REMOTE
[Service]
Type=oneshot
ExecStart=$(readlink -f "$RCLONE_BIN") bisync "${REMOTE}:" "${LOCAL}" --create-empty-src-dirs --compare size,modtime,checksum --slow-hash-sync-only --resync --verbose
EOF
    cat <<EOF > "$SYSTEMD_DIR/rclone-sync-${REMOTE}.timer"
[Unit]
Description=Timer 15m $REMOTE
[Timer]
OnBootSec=5min
OnUnitActiveSec=15min
[Install]
WantedBy=timers.target
EOF
    $GUM_BIN spin --spinner dot --title "Agendando..." -- sleep 1
    systemctl --user daemon-reload; systemctl --user enable --now "rclone-sync-${REMOTE}.timer"
    $GUM_BIN spin --title "Sincronizando..." -- systemctl --user start "rclone-sync-${REMOTE}.service"
    ui_success "Sync ativo: $LOCAL"
}

setup_mount() {
    REMOTE="$1"; LOCAL="$CLOUD_DIR/$REMOTE"
    mkdir -p "$LOCAL"
    cat <<EOF > "$SYSTEMD_DIR/rclone-mount-${REMOTE}.service"
[Unit]
Description=Mount $REMOTE
[Service]
Type=notify
ExecStart=$(readlink -f "$RCLONE_BIN") mount ${REMOTE}: "${LOCAL}" --vfs-cache-mode full --no-modtime
ExecStop=/bin/fusermount -u "${LOCAL}"
Restart=on-failure
[Install]
WantedBy=default.target
EOF
    $GUM_BIN spin --spinner dot --title "Montando..." -- sleep 1
    systemctl --user daemon-reload; systemctl --user enable --now "rclone-mount-${REMOTE}.service"
    if systemctl --user is-active --quiet "rclone-mount-${REMOTE}.service"; then
        if [ -d "$CLOUD_DIR" ]; then echo -e "[Desktop Entry]\nIcon=$SYSTEM_ICON\nType=Directory" > "$CLOUD_DIR/.directory" 2>/dev/null; fi
        ui_success "Montado: $LOCAL"
    else
        ui_error "Erro ao montar."
    fi
}

stop_all() {
    NAME="$1"
    $GUM_BIN spin --title "Parando..." -- sleep 1
    systemctl --user stop "rclone-mount-${NAME}.service" "rclone-sync-${NAME}.timer" "rclone-sync-${NAME}.service" 2>/dev/null
    systemctl --user disable "rclone-mount-${NAME}.service" "rclone-sync-${NAME}.timer" 2>/dev/null
    rm "$SYSTEMD_DIR/rclone-mount-${NAME}.service" "$SYSTEMD_DIR/rclone-sync-${NAME}.timer" "$SYSTEMD_DIR/rclone-sync-${NAME}.service" 2>/dev/null
    systemctl --user daemon-reload
    ui_success "Parado."
}

# --- 4. Ferramentas Globais ---

update_binaries() {
    echo "⬇️  Atualizando Rclone..."
    curl -L https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rclone.zip
    unzip -o /tmp/rclone.zip -d /tmp/inst > /dev/null
    mv /tmp/inst/rclone-*-linux-amd64/rclone "$USER_BIN_DIR/"
    chmod +x "$USER_BIN_DIR/rclone"

    echo "⬇️  Atualizando Gum..."
    ARCH=$(uname -m); case $ARCH in x86_64) GUM_ARCH="x86_64";; aarch64|arm64) GUM_ARCH="arm64";; esac
    curl -L -o /tmp/gum.tar.gz "https://github.com/charmbracelet/gum/releases/download/v0.14.5/gum_0.14.5_Linux_${GUM_ARCH}.tar.gz"
    tar -xzf /tmp/gum.tar.gz -C /tmp/
    mv $(find /tmp -name gum -type f -executable | head -n 1) "$USER_BIN_DIR/"
    chmod +x "$USER_BIN_DIR/gum"

    ui_success "Binários atualizados!"
}

create_shortcuts() {
    $GUM_BIN spin --title "Criando atalhos..." -- sleep 1
    LIST=$(systemctl --user list-unit-files | grep "rclone-mount-" | grep "enabled" | awk '{print $1}')
    for s in $LIST; do
        NAME=$(echo "$s" | sed 's/rclone-mount-//;s/.service//')
        MOUNT_POINT="$CLOUD_DIR/$NAME"
        SHORTCUT="$HOME/Desktop/$NAME.desktop"
        echo -e "[Desktop Entry]\nName=$NAME\nExec=xdg-open \"$MOUNT_POINT\"\nIcon=$SYSTEM_ICON\nType=Application" > "$SHORTCUT"
        chmod +x "$SHORTCUT"
    done
    ui_success "Atalhos criados na Área de Trabalho!"
}

fix_icons() {
    $GUM_BIN spin --title "Aplicando ícones..." -- sleep 1
    if [ -d "$CLOUD_DIR" ]; then echo -e "[Desktop Entry]\nIcon=$SYSTEM_ICON\nType=Directory" > "$CLOUD_DIR/.directory" 2>/dev/null; fi
    ui_success "Ícones reaplicados!"
}

do_global_tools() {
    CHOICE=$(echo -e "🖥️  Criar Atalhos no Desktop\n🎨 Corrigir Ícones\n⬇️  Atualizar Binários (Rclone/Gum)\n♻️  Reinstalar Script\n🔙 Voltar" | $GUM_BIN choose --header "Ferramentas")

    case "$CHOICE" in
        "🖥️"*) create_shortcuts ;;
        "🎨"*) fix_icons ;;
        "⬇️"*) update_binaries ;;
        "♻️"*) install_system; ui_success "Reinstalado!" ;;
    esac
}

# --- 5. Menus ---

do_wizard() {
    # CORREÇÃO: Usamos 'rclone help backends' em vez de 'providers'
    # O awk pula a primeira linha (header) e formata "drive Google Drive" -> "drive (Google Drive)"
    PROVIDERS=$($GUM_BIN spin --title "Carregando serviços..." -- "$RCLONE_BIN" help backends 2>/dev/null | tail -n +2 | awk '{printf "%s (%s)\n", $1, substr($0, index($0,$2))}')

    # Fallback se a lista vier vazia (Rclone muito antigo ou erro de parsing)
    if [ -z "$PROVIDERS" ]; then
        PROVIDERS=$(echo -e "drive (Google Drive)\nonedrive (Microsoft)\ndropbox (Dropbox)\ns3 (Amazon/Minio)\nmega (Mega)\npcloud (pCloud)\nwebdav (WebDAV)\nftp (FTP)\nsftp (SSH/SFTP)")
    fi

    # Filtro Dinâmico
    SEL=$(echo "$PROVIDERS" | $GUM_BIN choose --header "1. Selecione o Provedor (Digite para buscar)" --height 15)
    [ -z "$SEL" ] && return

    # Limpa cores e pega apenas o ID (primeira palavra)
    PROVIDER=$(echo "$SEL" | awk '{print $1}' | sed 's/\x1b\[[0-9;]*m//g')

    echo "📝 Sufixo (Ex: pessoal, trabalho)"
    SUFFIX=$($GUM_BIN input --placeholder "pessoal" | tr -cd '[:alnum:]_-')
    [ -z "$SUFFIX" ] && return

    NAME="${PROVIDER}-${SUFFIX}"
    if "$RCLONE_BIN" listremotes | grep -q "^${NAME}:"; then ui_error "Já existe."; return; fi

    echo -e "🔑 Logar em \033[1;34m$PROVIDER\033[0m..."
    $GUM_BIN confirm "Abrir navegador?" && "$RCLONE_BIN" config create "$NAME" "$PROVIDER"

    if "$RCLONE_BIN" listremotes | grep -q "^${NAME}:"; then
        ACTION=$(echo -e "MOUNT (Disco Virtual)\nSYNC (Backup 15min)" | $GUM_BIN choose --header "2. Modo de uso")
        if [[ "$ACTION" == MOUNT* ]]; then setup_mount "$NAME"; else setup_sync "$NAME"; fi
    else
        ui_error "Falha na criação. Tente 'Atualizar Binários' nas ferramentas."
    fi
}

do_manage() {
    REMOTES=$("$RCLONE_BIN" listremotes 2>/dev/null)
    if [ -z "$REMOTES" ]; then ui_error "Nenhuma conexão criada."; return; fi

    MENU_ITENS=""
    for r in $REMOTES; do
        clean="${r%:}"
        STATUS="⚪"; TYPE="Parado"
        if systemctl --user is-active --quiet "rclone-mount-${clean}.service"; then STATUS="🟢"; TYPE="Montado";
        elif systemctl --user is-active --quiet "rclone-sync-${clean}.timer"; then STATUS="🔵"; TYPE="Sync"; fi

        LINE=$(printf "%s  %-20s  (%s)" "$STATUS" "$clean" "$TYPE")
        MENU_ITENS+="${LINE}\n"
    done
    MENU_ITENS+="🔙 Voltar"

    CHOICE=$(echo -e "$MENU_ITENS" | $GUM_BIN choose --header "Gerenciar Conexões" --height 15)

    if [[ "$CHOICE" == *"Voltar"* ]] || [ -z "$CHOICE" ]; then return; fi
    NAME=$(echo "$CHOICE" | awk '{print $2}')

    if [[ "$CHOICE" == *"Montado"* ]] || [[ "$CHOICE" == *"Sync"* ]]; then
        ACTION=$(echo -e "📂 Abrir Pasta\n🔴 Parar/Desativar\n🔙 Voltar" | $GUM_BIN choose --header "Ações para $NAME")
        case "$ACTION" in
            "📂 Abrir"*) xdg-open "$CLOUD_DIR/$NAME" ;;
            "🔴 Parar"*) if $GUM_BIN confirm "Parar $NAME?"; then stop_all "$NAME"; fi ;;
        esac
    else
        ACTION=$(echo -e "🟢 Ativar (Mount)\n🔵 Ativar (Sync)\n✏️  Renomear\n🗑️  Excluir\n🔙 Voltar" | $GUM_BIN choose --header "Ações para $NAME")
        case "$ACTION" in
            "🟢 Ativar"*) setup_mount "$NAME" ;;
            "🔵 Ativar"*) setup_sync "$NAME" ;;
            "🗑️  Excluir"*)
                if $GUM_BIN confirm "Excluir $NAME permanentemente?"; then stop_all "$NAME"; "$RCLONE_BIN" config delete "$NAME"; ui_success "Removido."; fi ;;
            "✏️  Renomear"*)
                echo "📝 Novo sufixo para $NAME:"
                NEW_SUF=$($GUM_BIN input | tr -cd '[:alnum:]_-')
                if [ -n "$NEW_SUF" ]; then
                    TYPE=$(echo "$NAME" | cut -d- -f1); NEW_NAME="${TYPE}-${NEW_SUF}"; stop_all "$NAME"
                    CONF=$("$RCLONE_BIN" config file | grep ".conf" | tail -n1)
                    sed -i "s/^\[$NAME\]$/\[$NEW_NAME\]/" "$CONF"
                    if [ -d "$CLOUD_DIR/$NAME" ]; then mv "$CLOUD_DIR/$NAME" "$CLOUD_DIR/$NEW_NAME"; fi
                    ui_success "Renomeado para $NEW_NAME"
                fi ;;
        esac
    fi
}

# --- 6. Loop Principal ---

ensure_terminal
check_deps; install_system

while true; do
    ui_header
    ACTIVE=$(systemctl --user list-unit-files | grep -E "rclone-(mount|sync)-" | grep "enabled" | wc -l)
    echo -e "   Conexões Ativas: \033[1;32m$ACTIVE\033[0m"
    echo ""

    CHOICE=$(echo -e "🚀 Nova Conexão\n📂 Gerenciar Conexões\n🛠️  Ferramentas do Sistema\n🔧 Avançado (Rclone Config)\n🚪 Sair" | $GUM_BIN choose --header "Menu Principal")

    case "$CHOICE" in
        "🚀 Nova"*) do_wizard ;;
        "📂 Gerenciar"*) do_manage ;;
        "🛠️  Ferramentas"*) do_global_tools ;;
        "🔧 Avançado"*) "$RCLONE_BIN" config ;;
        "🚪 Sair") clear; exit 0 ;;
    esac
done

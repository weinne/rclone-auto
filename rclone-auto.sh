#!/bin/bash

# ==========================================
# RClone Auto v48.0 (Navigation Fix)
# Autor: Weinne
# Feature: Botões de "Voltar" adicionados ao Wizard e melhoria no fluxo de cancelamento.
# ==========================================

# --- Configurações de Tema ---
export GUM_CHOOSE_CURSOR="👉 "
export GUM_CHOOSE_CURSOR_FOREGROUND="#00FFFF"
export GUM_CHOOSE_ITEM_FOREGROUND="#E0E0E0"
export GUM_CHOOSE_SELECTED_FOREGROUND="#00FFFF"
export GUM_INPUT_CURSOR_FOREGROUND="#FF00FF"
export GUM_CONFIRM_SELECTED_BACKGROUND="#6A0DAD"

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

bootstrap_gum() {
    if [ -f "$SCRIPT_DIR/gum" ] && [ -x "$SCRIPT_DIR/gum" ]; then GUM_BIN="$SCRIPT_DIR/gum"
    elif [ -f "$USER_BIN_DIR/gum" ]; then GUM_BIN="$USER_BIN_DIR/gum"
    elif command -v gum &> /dev/null; then GUM_BIN=$(command -v gum); fi

    if [ -z "$GUM_BIN" ]; then
        echo "⬇️  Instalando interface gráfica (Gum)..."
        rm -rf /tmp/gum*
        ARCH=$(uname -m); case $ARCH in x86_64) GUM_ARCH="x86_64";; aarch64|arm64) GUM_ARCH="arm64";; esac
        curl -L -o /tmp/gum.tar.gz "https://github.com/charmbracelet/gum/releases/download/v0.14.5/gum_0.14.5_Linux_${GUM_ARCH}.tar.gz"
        tar -xzf /tmp/gum.tar.gz -C /tmp/
        mv $(find /tmp -name gum -type f -executable | head -n 1) "$USER_BIN_DIR/"
        chmod +x "$USER_BIN_DIR/gum"
        GUM_BIN="$USER_BIN_DIR/gum"
        echo "✅ Interface instalada!"
    fi
}

check_deps_splash() {
    bootstrap_gum

    clear
    echo ""
    $GUM_BIN style --foreground 212 --border double --border-foreground 212 --padding "1 2" --align center "RCLONE AUTO v48" "System Initialization"
    echo ""

    check_step() {
        if $1; then
            $GUM_BIN style --foreground 46 "✓ $2.......... [OK]"
        else
            $GUM_BIN style --foreground 196 "✗ $2.......... [FAIL]"
            return 1
        fi
    }

    if command -v fusermount3 &> /dev/null; then
        check_step "true" "FUSE3 Filesystem"
    else
        check_step "false" "FUSE3 Filesystem"
        echo "⚠️  Erro Crítico: Instale o fuse3 (sudo apt install fuse3)"
        read -p "Enter para sair..."
        exit 1
    fi
    sleep 0.1

    if [ -f "$USER_BIN_DIR/rclone" ]; then RCLONE_BIN="$USER_BIN_DIR/rclone"; elif command -v rclone &> /dev/null; then RCLONE_BIN=$(command -v rclone); fi

    if [ -z "$RCLONE_BIN" ]; then
        $GUM_BIN spin --title "Baixando Rclone Core..." -- curl -L https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rclone.zip
        unzip -q -o /tmp/rclone.zip -d /tmp/inst
        mv /tmp/inst/rclone-*-linux-amd64/rclone "$USER_BIN_DIR/"
        chmod +x "$USER_BIN_DIR/rclone"
        RCLONE_BIN="$USER_BIN_DIR/rclone"
    fi
    check_step "true" "Rclone Core"
    sleep 0.1

    check_step "true" "Graphic UI (Gum)"
    sleep 0.5
}

install_system() {
    if [ -f "$CURRENT_PATH" ] && [ "$CURRENT_PATH" != "$TARGET_BIN" ]; then cp -f "$CURRENT_PATH" "$TARGET_BIN"; chmod +x "$TARGET_BIN"; fi
    if [ "$GUM_BIN" == "$SCRIPT_DIR/gum" ] && [ ! -f "$USER_BIN_DIR/gum" ]; then cp "$SCRIPT_DIR/gum" "$USER_BIN_DIR/"; chmod +x "$USER_BIN_DIR/gum"; fi

    DESKTOP_FILE="$SHORTCUT_DIR/$APP_NAME.desktop"
    echo -e "[Desktop Entry]\nName=RClone Auto\nComment=Gerenciador de Nuvens\nExec=\"$TARGET_BIN\"\nIcon=$SYSTEM_ICON\nTerminal=true\nType=Application\nCategories=Utility;Network;" > "$DESKTOP_FILE"
    chmod +x "$DESKTOP_FILE"
    if command -v update-desktop-database &> /dev/null; then update-desktop-database "$SHORTCUT_DIR" 2>/dev/null; fi
    if [ -d "$CLOUD_DIR" ]; then echo -e "[Desktop Entry]\nIcon=$SYSTEM_ICON\nType=Directory" > "$CLOUD_DIR/.directory" 2>/dev/null; fi
}

# --- 2. Interface Helper ---

ui_header() {
    clear
    $GUM_BIN style --foreground 212 --border-foreground 212 --border double --align center --width 50 --margin "1 2" --padding "0 2" "☁️  RClone Auto"
}

ui_talk() {
    echo ""
    $GUM_BIN style --foreground 255 --padding "0 1" "🤖 Assistente:"
    $GUM_BIN style --foreground 212 --padding "0 2" "$1"
    echo ""
}

ui_success() { $GUM_BIN style --foreground 46 "✅ $1"; sleep 1.5; }
ui_error() { $GUM_BIN style --foreground 196 "❌ $1"; $GUM_BIN confirm "Ok" --affirmative "Entendi" --negative ""; }

# --- 3. Lógica Core ---

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
    $GUM_BIN spin --spinner dot --title "Configurando timer..." -- sleep 1
    systemctl --user daemon-reload; systemctl --user enable --now "rclone-sync-${REMOTE}.timer"
    $GUM_BIN spin --title "Sincronizando arquivos..." -- systemctl --user start "rclone-sync-${REMOTE}.service"
    ui_success "Pronto! A pasta $REMOTE está sincronizada."
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
    $GUM_BIN spin --spinner dot --title "Montando disco..." -- sleep 1
    systemctl --user daemon-reload; systemctl --user enable --now "rclone-mount-${REMOTE}.service"
    if systemctl --user is-active --quiet "rclone-mount-${REMOTE}.service"; then
        if [ -d "$CLOUD_DIR" ]; then echo -e "[Desktop Entry]\nIcon=$SYSTEM_ICON\nType=Directory" > "$CLOUD_DIR/.directory" 2>/dev/null; fi
        ui_success "Conectado! Acesso disponível na pasta Nuvem."
    else
        ui_error "Houve um erro ao montar o disco."
    fi
}

stop_all() {
    NAME="$1"
    $GUM_BIN spin --title "Desconectando..." -- sleep 1
    systemctl --user stop "rclone-mount-${NAME}.service" "rclone-sync-${NAME}.timer" "rclone-sync-${NAME}.service" 2>/dev/null
    systemctl --user disable "rclone-mount-${NAME}.service" "rclone-sync-${NAME}.timer" 2>/dev/null
    rm "$SYSTEMD_DIR/rclone-mount-${NAME}.service" "$SYSTEMD_DIR/rclone-sync-${NAME}.timer" "$SYSTEMD_DIR/rclone-sync-${NAME}.service" 2>/dev/null
    systemctl --user daemon-reload
    ui_success "Serviço parado."
}

# --- 4. Ferramentas Globais ---

update_binaries() {
    $GUM_BIN spin --title "Atualizando Rclone..." -- curl -L https://downloads.rclone.org/rclone-current-linux-amd64.zip -o /tmp/rclone.zip
    unzip -q -o /tmp/rclone.zip -d /tmp/inst
    mv /tmp/inst/rclone-*-linux-amd64/rclone "$USER_BIN_DIR/"
    chmod +x "$USER_BIN_DIR/rclone"
    ui_success "Sistema atualizado!"
}

create_shortcuts() {
    $GUM_BIN spin --title "Gerando ícones..." -- sleep 1
    LIST=$(systemctl --user list-unit-files | grep "rclone-mount-" | grep "enabled" | awk '{print $1}')
    for s in $LIST; do
        NAME=$(echo "$s" | sed 's/rclone-mount-//;s/.service//')
        MOUNT_POINT="$CLOUD_DIR/$NAME"
        SHORTCUT="$HOME/Desktop/$NAME.desktop"
        echo -e "[Desktop Entry]\nName=$NAME\nExec=xdg-open \"$MOUNT_POINT\"\nIcon=$SYSTEM_ICON\nType=Application" > "$SHORTCUT"
        chmod +x "$SHORTCUT"
    done
    ui_success "Atalhos criados no Desktop!"
}

fix_icons() {
    if [ -d "$CLOUD_DIR" ]; then echo -e "[Desktop Entry]\nIcon=$SYSTEM_ICON\nType=Directory" > "$CLOUD_DIR/.directory" 2>/dev/null; fi
    ui_success "Ícones corrigidos."
}

do_global_tools() {
    ui_talk "Aqui estão algumas ferramentas para manter tudo em ordem."
    CHOICE=$(echo -e "🖥️  Criar Atalhos no Desktop\n🎨 Corrigir Ícones\n⬇️  Atualizar Tudo\n♻️  Reinstalar Script\n🔙 Voltar" | $GUM_BIN choose --header "Ferramentas")

    case "$CHOICE" in
        "🖥️"*) create_shortcuts ;;
        "🎨"*) fix_icons ;;
        "⬇️"*) update_binaries ;;
        "♻️"*) install_system; ui_success "Script reinstalado com sucesso." ;;
    esac
}

# --- 5. O Mago (Wizard) ---

do_wizard() {
    ui_talk "Olá! Vamos conectar uma nova nuvem ao seu sistema. Qual serviço você gostaria de adicionar?"

    POPULAR="drive (Google Drive)
onedrive (Microsoft OneDrive)
dropbox (Dropbox)
box (Box)
pcloud (pCloud)
s3 (S3 / AWS / Minio)
webdav (WebDAV)
smb (Windows Share / SMB)
sftp (SSH / SFTP)
--------------------------------
ALL (Outros / Listar Todos)
🔙 Voltar"

    SEL=$(echo "$POPULAR" | $GUM_BIN choose --height 15)

    # 1. Verifica Voltar/Cancelar
    if [[ "$SEL" == *"Voltar"* ]] || [ -z "$SEL" ]; then return; fi

    # 2. Ignora separador
    if [[ "$SEL" == *"---"* ]]; then return; fi

    # 3. Busca Global
    if [[ "$SEL" == "ALL"* ]]; then
        ui_talk "Buscando lista completa de drivers..."
        FULL_LIST=$("$RCLONE_BIN" help backends 2>/dev/null | tail -n +2 | awk '{printf "%s (%s)\n", $1, substr($0, index($0,$2))}')
        # Adiciona Voltar na busca global
        FULL_LIST="${FULL_LIST}
🔙 Voltar"

        SEL=$(echo "$FULL_LIST" | $GUM_BIN choose --header "Busca Global" --height 15)
        if [[ "$SEL" == *"Voltar"* ]] || [ -z "$SEL" ]; then return; fi
    fi

    PROVIDER=$(echo "$SEL" | awk '{print $1}' | sed 's/\x1b\[[0-9;]*m//g')

    ui_talk "Ótima escolha ($PROVIDER). Como devemos chamar essa conexão? (Dica: use nomes curtos como 'pessoal' ou 'trabalho')."

    SUFFIX=$($GUM_BIN input --placeholder "ex: pessoal" | tr -cd '[:alnum:]_-')
    if [ -z "$SUFFIX" ]; then ui_talk "Operação cancelada."; return; fi

    NAME="${PROVIDER}-${SUFFIX}"
    if "$RCLONE_BIN" listremotes | grep -q "^${NAME}:"; then ui_error "Esse nome ($NAME) já está em uso."; return; fi

    ui_talk "Certo. Vou abrir seu navegador para você fazer o login no $PROVIDER. Preparado?"
    if $GUM_BIN confirm "Sim, abrir navegador" --negative "Cancelar"; then
        "$RCLONE_BIN" config create "$NAME" "$PROVIDER"
    else
        ui_talk "Operação cancelada."
        return
    fi

    if "$RCLONE_BIN" listremotes | grep -q "^${NAME}:"; then
        ui_talk "Sucesso! Agora, como você quer usar essa nuvem?"
        ACTION=$(echo -e "MOUNT (Disco Virtual - Economiza espaço)\nSYNC (Backup Offline - Cópia segura)" | $GUM_BIN choose)

        if [[ "$ACTION" == MOUNT* ]]; then
            setup_mount "$NAME"
        else
            setup_sync "$NAME"
        fi
    else
        ui_error "Não consegui confirmar a criação. Tente novamente."
    fi
}

do_manage() {
    REMOTES=$("$RCLONE_BIN" listremotes 2>/dev/null)
    if [ -z "$REMOTES" ]; then ui_talk "Você ainda não tem nenhuma conexão configurada."; return; fi

    MENU_ITENS=""
    for r in $REMOTES; do
        clean="${r%:}"
        STATUS="⚪"; TYPE="Inativo"
        if systemctl --user is-active --quiet "rclone-mount-${clean}.service"; then STATUS="🟢"; TYPE="Montado";
        elif systemctl --user is-active --quiet "rclone-sync-${clean}.timer"; then STATUS="🔵"; TYPE="Sync"; fi

        LINE=$(printf "%s  %-20s  (%s)" "$STATUS" "$clean" "$TYPE")
        MENU_ITENS+="${LINE}\n"
    done
    MENU_ITENS+="🔙 Voltar"

    ui_talk "Aqui estão suas conexões. Selecione uma para ver opções."
    CHOICE=$(echo -e "$MENU_ITENS" | $GUM_BIN choose --height 10)

    if [[ "$CHOICE" == *"Voltar"* ]] || [ -z "$CHOICE" ]; then return; fi
    NAME=$(echo "$CHOICE" | awk '{print $2}')

    if [[ "$CHOICE" == *"Montado"* ]] || [[ "$CHOICE" == *"Sync"* ]]; then
        ACTION=$(echo -e "📂 Abrir Pasta\n🔴 Desconectar\n🔙 Voltar" | $GUM_BIN choose --header "Opções para $NAME")
        case "$ACTION" in
            "📂 Abrir"*) xdg-open "$CLOUD_DIR/$NAME" ;;
            "🔴 Desconectar"*) if $GUM_BIN confirm "Tem certeza que deseja parar $NAME?"; then stop_all "$NAME"; fi ;;
        esac
    else
        ACTION=$(echo -e "🟢 Ativar (Mount)\n🔵 Ativar (Sync)\n✏️  Renomear\n🗑️  Excluir\n🔙 Voltar" | $GUM_BIN choose --header "Opções para $NAME")
        case "$ACTION" in
            "🟢 Ativar"*) setup_mount "$NAME" ;;
            "🔵 Ativar"*) setup_sync "$NAME" ;;
            "🗑️  Excluir"*)
                if $GUM_BIN confirm "Excluir configurações de $NAME permanentemente?"; then
                    stop_all "$NAME"; "$RCLONE_BIN" config delete "$NAME"; ui_success "Removido.";
                fi ;;
            "✏️  Renomear"*)
                ui_talk "Qual será o novo sufixo para $NAME?"
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
check_deps_splash
install_system

while true; do
    ui_header
    ACTIVE=$(systemctl --user list-unit-files | grep -E "rclone-(mount|sync)-" | grep "enabled" | wc -l)

    echo -e "   Conexões Ativas: \033[1;32m$ACTIVE\033[0m"
    echo ""

    CHOICE=$(echo -e "🚀 Nova Conexão\n📂 Gerenciar Conexões\n🛠️  Ferramentas\n🔧 Configuração Avançada\n🚪 Sair" | $GUM_BIN choose)

    case "$CHOICE" in
        "🚀 Nova"*) do_wizard ;;
        "📂 Gerenciar"*) do_manage ;;
        "🛠️  Ferramentas"*) do_global_tools ;;
        "🔧 Configuração"*) "$RCLONE_BIN" config ;;
        "🚪 Sair") clear; exit 0 ;;
    esac
done

#!/bin/bash

# PDF Tools GUI - Instalador Automático
# Versão: 2.3 - CORREÇÃO TOTAL
# Autor: Sistema
# Descrição: Instala interface gráfica Tcl/Tk para ferramentas PDF

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Configurações
SCRIPT_DIR="$HOME/.local/share/pdf-tools"  # Diretório dos scripts
BIN_DIR="$HOME/.local/bin"                  # Diretório dos binários
CONFIG_DIR="$HOME/.config/pdf-tools"        # Diretório de configuração
BIN_LINK="$BIN_DIR/pdf-tools"               # Comando CLI
GUI_BIN_LINK="$BIN_DIR/pdf-tools-gui"       # Comando GUI
MENU_DIR="$HOME/.local/share/applications"  # Atalhos de menu
ICON_DIR="$HOME/.local/share/icons"         # Ícones

# ========== FUNÇÕES BÁSICAS ==========

# Banner
show_banner() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                                                        ║${NC}"
    echo -e "${BLUE}║   📄 PDF Tools GUI - Instalador Automático v2.3       ║${NC}"
    echo -e "${BLUE}║                                                        ║${NC}"
    echo -e "${BLUE}║   🔹 CLI + TUI + GUI (Tcl/Tk)                          ║${NC}"
    echo -e "${BLUE}║   🔹 Seleção interativa de idiomas                     ║${NC}"
    echo -e "${BLUE}║   🔹 Correção automática de PATH                       ║${NC}"
    echo -e "${BLUE}║   🔹 Wrappers funcionais                               ║${NC}"
    echo -e "${BLUE}║                                                        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Verificar sistema
check_system() {
    echo -e "${CYAN}🔍 Verificando sistema...${NC}"
    
    if [ -f /etc/fedora-release ]; then
        OS="fedora"
        PKG_MANAGER="dnf"
        echo -e "${GREEN}✅ Fedora detectado${NC}"
    elif [ -f /etc/debian_version ]; then
        OS="debian"
        PKG_MANAGER="apt"
        echo -e "${GREEN}✅ Debian/Ubuntu detectado${NC}"
    elif [ -f /etc/arch-release ]; then
        OS="arch"
        PKG_MANAGER="pacman"
        echo -e "${GREEN}✅ Arch Linux detectado${NC}"
    else
        echo -e "${RED}❌ Sistema não suportado${NC}"
        exit 1
    fi
}

# ========== CONFIGURAÇÃO DE PATH ==========

# Garantir que diretórios existem
ensure_directories() {
    echo -e "\n${CYAN}📁 Criando diretórios necessários...${NC}"
    
    mkdir -p "$BIN_DIR"
    mkdir -p "$SCRIPT_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$SCRIPT_DIR/modules"
    mkdir -p "$CONFIG_DIR/presets"
    mkdir -p "$SCRIPT_DIR/logs"
    mkdir -p "$SCRIPT_DIR/workspace"
    mkdir -p "$ICON_DIR"
    mkdir -p "$MENU_DIR"
    
    echo -e "${GREEN}✅ Diretórios criados${NC}"
}

# Garantir que ~/.local/bin está no PATH
ensure_path() {
    echo -e "\n${CYAN}🔧 Verificando PATH...${NC}"
    
    local path_updated=0
    
    # Verificar se o diretório existe
    if [ ! -d "$BIN_DIR" ]; then
        mkdir -p "$BIN_DIR"
    fi
    
    # Verificar se já está no PATH
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        echo -e "${YELLOW}⚠️  $BIN_DIR não está no PATH${NC}"
        
        # Adicionar ao .bashrc
        if [ -f "$HOME/.bashrc" ]; then
            # Verificar se já não foi adicionado antes
            if ! grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" "$HOME/.bashrc"; then
                echo '' >> "$HOME/.bashrc"
                echo '# Adicionar ~/.local/bin ao PATH para PDF Tools' >> "$HOME/.bashrc"
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
                echo -e "${GREEN}✅ Adicionado ao ~/.bashrc${NC}"
                path_updated=1
            else
                echo -e "${GREEN}✅ ~/.bashrc já configurado${NC}"
            fi
        fi
        
        # Adicionar ao .zshrc se existir
        if [ -f "$HOME/.zshrc" ]; then
            if ! grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" "$HOME/.zshrc"; then
                echo '' >> "$HOME/.zshrc"
                echo '# Adicionar ~/.local/bin ao PATH para PDF Tools' >> "$HOME/.zshrc"
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
                echo -e "${GREEN}✅ Adicionado ao ~/.zshrc${NC}"
                path_updated=1
            fi
        fi
        
        # Adicionar ao PATH atual
        export PATH="$BIN_DIR:$PATH"
        echo -e "${GREEN}✅ PATH atualizado para esta sessão${NC}"
        
        if [ $path_updated -eq 1 ]; then
            echo -e "${YELLOW}ℹ️  Para usar permanentemente, execute: source ~/.bashrc${NC}"
        fi
    else
        echo -e "${GREEN}✅ $BIN_DIR já está no PATH${NC}"
    fi
}

# ========== SELEÇÃO DE IDIOMAS ==========

# Selecionar idiomas para instalar
select_languages() {
    echo -e "\n${CYAN}🌐 Seleção de Idiomas para OCR${NC}"
    echo -e "${YELLOW}Escolha os idiomas que deseja instalar:${NC}\n"
    
    # Opções de idiomas
    echo "1) 🇧🇷 Português (por) - [recomendado]"
    echo "2) 🇺🇸 Inglês (eng) - [recomendado]"
    echo "3) 🇪🇸 Espanhol (spa)"
    echo "4) 🇫🇷 Francês (fra)"
    echo "5) 🇩🇪 Alemão (deu)"
    echo "6) 🇮🇹 Italiano (ita)"
    echo "7) 🇷🇺 Russo (rus)"
    echo "8) 🇸🇦 Árabe (ara)"
    echo "9) 🇨🇳 Chinês (chi_sim)"
    echo "10) 🇯🇵 Japonês (jpn)"
    echo ""
    echo "Digite os números separados por espaço (ex: 1 2 3):"
    read -p "> " lang_numbers
    
    SELECTED_LANGS=""
    for num in $lang_numbers; do
        case $num in
            1) SELECTED_LANGS="$SELECTED_LANGS por" ;;
            2) SELECTED_LANGS="$SELECTED_LANGS eng" ;;
            3) SELECTED_LANGS="$SELECTED_LANGS spa" ;;
            4) SELECTED_LANGS="$SELECTED_LANGS fra" ;;
            5) SELECTED_LANGS="$SELECTED_LANGS deu" ;;
            6) SELECTED_LANGS="$SELECTED_LANGS ita" ;;
            7) SELECTED_LANGS="$SELECTED_LANGS rus" ;;
            8) SELECTED_LANGS="$SELECTED_LANGS ara" ;;
            9) SELECTED_LANGS="$SELECTED_LANGS chi_sim" ;;
            10) SELECTED_LANGS="$SELECTED_LANGS jpn" ;;
        esac
    done
    
    # Garantir que pelo menos português e inglês estejam selecionados
    if [[ ! "$SELECTED_LANGS" =~ "por" ]]; then
        SELECTED_LANGS="por $SELECTED_LANGS"
        echo -e "${YELLOW}⚠️  Adicionando Português (obrigatório)${NC}"
    fi
    if [[ ! "$SELECTED_LANGS" =~ "eng" ]]; then
        SELECTED_LANGS="eng $SELECTED_LANGS"
        echo -e "${YELLOW}⚠️  Adicionando Inglês (obrigatório)${NC}"
    fi
    
    echo -e "${GREEN}✅ Idiomas selecionados:${NC} $SELECTED_LANGS"
    
    # Perguntar idioma padrão
    echo ""
    echo -e "${CYAN}Idioma padrão para OCR:${NC}"
    echo "1) 🇧🇷 Português"
    echo "2) 🇺🇸 Inglês"
    echo "3) 🇪🇸 Espanhol"
    echo "4) Outro"
    read -p "Escolha [1]: " default_lang_choice
    
    case $default_lang_choice in
        2) DEFAULT_LANG="eng" ;;
        3) DEFAULT_LANG="spa" ;;
        4) read -p "Digite o código do idioma: " DEFAULT_LANG ;;
        *) DEFAULT_LANG="por" ;;
    esac
    
    echo -e "${GREEN}✅ Idioma padrão: $DEFAULT_LANG${NC}"
}

# ========== INSTALAÇÃO DE DEPENDÊNCIAS ==========

# Instalar dependências do sistema
install_system_deps() {
    echo -e "\n${CYAN}📦 Instalando dependências do sistema...${NC}"
    
    # Pacotes base
    case $PKG_MANAGER in
        dnf)
            sudo dnf install -y \
                ocrmypdf \
                tesseract \
                poppler-utils \
                libreoffice \
                pandoc \
                ImageMagick \
                ghostscript \
                wkhtmltopdf \
                python3-pip \
                python3-devel \
                git \
                wget \
                dialog \
                fzf \
                parallel \
                unpaper \
                qpdf \
                pdfgrep \
                tcl \
                tk \
                tcllib \
                tkimg \
                perl-File-Slurp \
                perl-IPC-Run
            
            # Instalar idiomas
            for lang in $SELECTED_LANGS; do
                case $lang in
                    por) sudo dnf install -y tesseract-langpack-por ;;
                    eng) sudo dnf install -y tesseract-langpack-eng ;;
                    spa) sudo dnf install -y tesseract-langpack-spa ;;
                    fra) sudo dnf install -y tesseract-langpack-fra ;;
                    deu) sudo dnf install -y tesseract-langpack-deu ;;
                    ita) sudo dnf install -y tesseract-langpack-ita ;;
                    rus) sudo dnf install -y tesseract-langpack-rus ;;
                    ara) sudo dnf install -y tesseract-langpack-ara ;;
                    chi_sim) sudo dnf install -y tesseract-langpack-chi-sim ;;
                    jpn) sudo dnf install -y tesseract-langpack-jpn ;;
                esac
            done
            ;;
            
        apt)
            sudo apt update
            sudo apt install -y \
                ocrmypdf \
                tesseract-ocr \
                poppler-utils \
                libreoffice \
                pandoc \
                imagemagick \
                ghostscript \
                wkhtmltopdf \
                python3-pip \
                python3-dev \
                git \
                wget \
                dialog \
                fzf \
                parallel \
                unpaper \
                qpdf \
                pdfgrep \
                tcl \
                tk \
                tcllib \
                tk8.6 \
                libtk-img \
                libfile-slurp-perl \
                libipc-run-perl
            
            # Instalar idiomas
            for lang in $SELECTED_LANGS; do
                case $lang in
                    por) sudo apt install -y tesseract-ocr-por ;;
                    eng) sudo apt install -y tesseract-ocr-eng ;;
                    spa) sudo apt install -y tesseract-ocr-spa ;;
                    fra) sudo apt install -y tesseract-ocr-fra ;;
                    deu) sudo apt install -y tesseract-ocr-deu ;;
                    ita) sudo apt install -y tesseract-ocr-ita ;;
                    rus) sudo apt install -y tesseract-ocr-rus ;;
                    ara) sudo apt install -y tesseract-ocr-ara ;;
                    chi_sim) sudo apt install -y tesseract-ocr-chi-sim ;;
                    jpn) sudo apt install -y tesseract-ocr-jpn ;;
                esac
            done
            ;;
            
        pacman)
            sudo pacman -S --noconfirm \
                ocrmypdf \
                tesseract \
                poppler \
                libreoffice-fresh \
                pandoc \
                imagemagick \
                ghostscript \
                wkhtmltopdf \
                python-pip \
                git \
                wget \
                dialog \
                fzf \
                parallel \
                unpaper \
                qpdf \
                pdfgrep \
                tcl \
                tk \
                tcllib \
                tkimg \
                perl-file-slurp \
                perl-ipc-run
            
            # Instalar idiomas
            for lang in $SELECTED_LANGS; do
                case $lang in
                    por) sudo pacman -S --noconfirm tesseract-data-por ;;
                    eng) sudo pacman -S --noconfirm tesseract-data-eng ;;
                    spa) sudo pacman -S --noconfirm tesseract-data-spa ;;
                    fra) sudo pacman -S --noconfirm tesseract-data-fra ;;
                    deu) sudo pacman -S --noconfirm tesseract-data-deu ;;
                    ita) sudo pacman -S --noconfirm tesseract-data-ita ;;
                    rus) sudo pacman -S --noconfirm tesseract-data-rus ;;
                    ara) sudo pacman -S --noconfirm tesseract-data-ara ;;
                    chi_sim) sudo pacman -S --noconfirm tesseract-data-chi-sim ;;
                    jpn) sudo pacman -S --noconfirm tesseract-data-jpn ;;
                esac
            done
            ;;
    esac
    
    echo -e "${GREEN}✅ Dependências do sistema instaladas${NC}"
}

# Instalar ferramentas Python
install_python_tools() {
    echo -e "\n${CYAN}🐍 Instalando ferramentas Python...${NC}"
    
    pip3 install --user --upgrade pip
    pip3 install --user \
        commonforms \
        pdf2image \
        pytesseract \
        pillow \
        numpy \
        tabula-py \
        camelot-py[cv] \
        pdfplumber \
        PyPDF2 \
        reportlab
    
    echo -e "${GREEN}✅ Ferramentas Python instaladas${NC}"
}

# ========== CRIAÇÃO DOS WRAPPERS ==========

# Criar wrapper para CLI
create_cli_wrapper() {
    cat > "$BIN_LINK" << EOF
#!/bin/bash
# Wrapper para PDF Tools CLI
# Gerado pelo instalador em $(date)

SCRIPT_DIR="$SCRIPT_DIR"

if [ ! -f "\$SCRIPT_DIR/pdf-tools-tui.sh" ]; then
    echo -e "${RED}❌ Erro: Script CLI não encontrado em \$SCRIPT_DIR/pdf-tools-tui.sh${NC}"
    exit 1
fi

exec "\$SCRIPT_DIR/pdf-tools-tui.sh" "\$@"
EOF
    chmod +x "$BIN_LINK"
    echo -e "${GREEN}✅ Wrapper CLI criado: $BIN_LINK${NC}"
}

# Criar wrapper para GUI
create_gui_wrapper() {
    cat > "$GUI_BIN_LINK" << 'EOF'
#!/bin/bash
# Wrapper para PDF Tools GUI
# Gerado pelo instalador

SCRIPT_DIR="$HOME/.local/share/pdf-tools"

# Cores (para mensagens de erro)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verificar se wish está disponível
if ! command -v wish &> /dev/null; then
    echo -e "${RED}❌ Erro: Tcl/Tk (wish) não está instalado.${NC}"
    echo -e "${YELLOW}Execute o instalador novamente ou instale com:${NC}"
    echo "  sudo dnf install tcl tk      # Fedora"
    echo "  sudo apt install tcl tk      # Debian/Ubuntu"
    exit 1
fi

# Verificar se o script GUI existe
if [ ! -f "$SCRIPT_DIR/pdf-tools-gui.tcl" ]; then
    echo -e "${RED}❌ Erro: Script GUI não encontrado em $SCRIPT_DIR/pdf-tools-gui.tcl${NC}"
    exit 1
fi

# Executar GUI
cd "$SCRIPT_DIR" || exit 1
exec wish "$SCRIPT_DIR/pdf-tools-gui.tcl" "$@"
EOF
    chmod +x "$GUI_BIN_LINK"
    echo -e "${GREEN}✅ Wrapper GUI criado: $GUI_BIN_LINK${NC}"
}

# ========== INSTALAÇÃO DOS SCRIPTS ==========

# Instalar script GUI
install_gui_script() {
    echo -e "\n${CYAN}📝 Instalando script GUI...${NC}"
    
    # Verificar se o arquivo existe no diretório atual
    if [ -f "pdf-tools-gui.tcl" ]; then
        cp "pdf-tools-gui.tcl" "$SCRIPT_DIR/"
        echo -e "${GREEN}✅ Script GUI copiado do diretório atual${NC}"
    else
        echo -e "${YELLOW}⚠️  pdf-tools-gui.tcl não encontrado no diretório atual${NC}"
        echo -e "${CYAN}Deseja fazer download do script? (s/N): ${NC}"
        read -p "> " download_choice
        
        if [[ "$download_choice" =~ ^[Ss]$ ]]; then
            echo -e "${YELLOW}Baixando script GUI...${NC}"
            # Tentar baixar de uma URL (substitua pela URL real se disponível)
            curl -s -o "$SCRIPT_DIR/pdf-tools-gui.tcl" "https://raw.githubusercontent.com/seu-repo/pdf-tools/main/pdf-tools-gui.tcl" 2>/dev/null || {
                echo -e "${RED}❌ Falha no download. Criando script básico...${NC}"
                create_basic_gui_script
            }
        else
            echo -e "${RED}❌ Script GUI necessário para instalação${NC}"
            exit 1
        fi
    fi
    
    # Verificar se o script foi instalado
    if [ -f "$SCRIPT_DIR/pdf-tools-gui.tcl" ]; then
        chmod +x "$SCRIPT_DIR/pdf-tools-gui.tcl"
        echo -e "${GREEN}✅ Script GUI instalado em: $SCRIPT_DIR/pdf-tools-gui.tcl${NC}"
    else
        echo -e "${RED}❌ Falha na instalação do script GUI${NC}"
        exit 1
    fi
}

# Criar script GUI básico (fallback)
create_basic_gui_script() {
    cat > "$SCRIPT_DIR/pdf-tools-gui.tcl" << 'EOF'
#!/usr/bin/wish
# PDF Tools GUI - Versão Básica
package require Tk
wm title . "PDF Tools GUI"
wm geometry . 800x600
label .title -text "PDF Tools GUI" -font {Helvetica 24 bold}
pack .title -pady 20
label .msg -text "Interface gráfica em desenvolvimento" -font {Helvetica 12}
pack .msg -pady 10
button .exit -text "Sair" -command exit -padx 20 -pady 5
pack .exit -pady 20
EOF
    echo -e "${YELLOW}⚠️  Script GUI básico criado${NC}"
}

# Instalar script CLI
install_cli_script() {
    echo -e "\n${CYAN}📝 Instalando script CLI...${NC}"
    
    # Criar script CLI básico
    cat > "$SCRIPT_DIR/pdf-tools-tui.sh" << 'EOF'
#!/bin/bash
# PDF Tools CLI - Interface de Texto
echo "📄 PDF Tools CLI"
echo "================"
echo ""
echo "Comandos disponíveis:"
echo "  pdf-tools-gui    - Interface gráfica"
echo "  pdf-tools        - Esta ajuda"
echo ""
echo "Para usar a interface gráfica, execute: pdf-tools-gui"
echo ""
read -p "Pressione ENTER para continuar"
EOF
    chmod +x "$SCRIPT_DIR/pdf-tools-tui.sh"
    echo -e "${GREEN}✅ Script CLI instalado em: $SCRIPT_DIR/pdf-tools-tui.sh${NC}"
}

# Criar arquivo de configuração
create_config_file() {
    cat > "$CONFIG_DIR/settings.conf" << EOF
# PDF Tools GUI - Configurações
# Gerado pelo instalador em $(date)

# 🌐 Idiomas
LANGUAGE="$DEFAULT_LANG"
AVAILABLE_LANGUAGES="$SELECTED_LANGS"

# 📁 Diretórios
WORKSPACE_DIR="\$HOME/Documents/PDF_Tools"
DEFAULT_OUTPUT_DIR="\$WORKSPACE_DIR/output"
SCRIPT_DIR="$SCRIPT_DIR"
CONFIG_DIR="$CONFIG_DIR"

# ⚙️ Configurações gerais
LOG_LEVEL="INFO"
AUTO_CLEAN_TEMP="true"
MAX_PARALLEL_JOBS="2"
GUI_FONT_SIZE="10"
GUI_THEME="light"
EOF
    echo -e "${GREEN}✅ Configuração salva em: $CONFIG_DIR/settings.conf${NC}"
}

# ========== ATALHOS DE MENU ==========

# Criar atalhos no menu
create_desktop_entries() {
    echo -e "\n${CYAN}🖥️  Criando atalhos no menu...${NC}"
    
    # Atalho para CLI
    cat > "$MENU_DIR/pdf-tools-cli.desktop" << EOF
[Desktop Entry]
Name=PDF Tools CLI
Comment=Ferramentas de PDF - Interface de Texto
Exec=$BIN_LINK
Terminal=true
Type=Application
Icon=utilities-terminal
Categories=Office;Utility;
Keywords=pdf;ocr;converter;
EOF
    
    # Atalho para GUI
    cat > "$MENU_DIR/pdf-tools-gui.desktop" << EOF
[Desktop Entry]
Name=PDF Tools GUI
Comment=Ferramentas de PDF - Interface Gráfica
Exec=$GUI_BIN_LINK
Terminal=false
Type=Application
Icon=accessories-text-editor
Categories=Office;Utility;Graphics;
Keywords=pdf;ocr;converter;gui;
EOF
    
    # Ícone
    cat > "$ICON_DIR/pdf-tools.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <rect width="64" height="64" fill="#4CAF50" rx="8"/>
  <text x="12" y="44" font-family="Arial" font-size="32" fill="white" font-weight="bold">PDF</text>
  <circle cx="48" cy="20" r="8" fill="white" fill-opacity="0.3"/>
</svg>
EOF
    
    # Atualizar cache
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$MENU_DIR" 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅ Atalhos criados em: $MENU_DIR${NC}"
}

# ========== VERIFICAÇÕES ==========

# Verificar Tcl/Tk
check_tcltk() {
    echo -e "\n${CYAN}🔍 Verificando Tcl/Tk...${NC}"
    
    if command -v wish &> /dev/null; then
        local version=$(echo 'puts [info patchlevel]; exit' | wish 2>/dev/null)
        echo -e "${GREEN}✅ Tcl/Tk $version encontrado${NC}"
        return 0
    else
        echo -e "${RED}❌ Tcl/Tk não encontrado${NC}"
        return 1
    fi
}

# Verificar idiomas instalados
check_languages() {
    echo -e "\n${CYAN}🔍 Verificando idiomas instalados...${NC}"
    
    if command -v tesseract &> /dev/null; then
        INSTALLED_LANGS=$(tesseract --list-langs 2>/dev/null | tail -n +2)
        if [ -n "$INSTALLED_LANGS" ]; then
            echo -e "${GREEN}Idiomas Tesseract instalados:${NC}"
            for lang in $INSTALLED_LANGS; do
                case $lang in
                    por) echo "  🇧🇷 Português" ;;
                    eng) echo "  🇺🇸 Inglês" ;;
                    spa) echo "  🇪🇸 Espanhol" ;;
                    fra) echo "  🇫🇷 Francês" ;;
                    deu) echo "  🇩🇪 Alemão" ;;
                    ita) echo "  🇮🇹 Italiano" ;;
                    rus) echo "  🇷🇺 Russo" ;;
                    ara) echo "  🇸🇦 Árabe" ;;
                    chi_sim) echo "  🇨🇳 Chinês" ;;
                    jpn) echo "  🇯🇵 Japonês" ;;
                    *) echo "  📌 $lang" ;;
                esac
            done
        else
            echo -e "${YELLOW}⚠️  Nenhum idioma Tesseract encontrado${NC}"
        fi
    else
        echo -e "${RED}❌ Tesseract não encontrado${NC}"
    fi
}

# Verificar instalação completa
verify_installation() {
    echo -e "\n${CYAN}🔍 Verificando instalação completa...${NC}"
    
    local errors=0
    
    # Verificar wrappers
    if [ -f "$BIN_LINK" ] && [ -x "$BIN_LINK" ]; then
        echo -e "  ${GREEN}✅ CLI wrapper: $BIN_LINK${NC}"
    else
        echo -e "  ${RED}❌ CLI wrapper não encontrado${NC}"
        errors=$((errors+1))
    fi
    
    if [ -f "$GUI_BIN_LINK" ] && [ -x "$GUI_BIN_LINK" ]; then
        echo -e "  ${GREEN}✅ GUI wrapper: $GUI_BIN_LINK${NC}"
    else
        echo -e "  ${RED}❌ GUI wrapper não encontrado${NC}"
        errors=$((errors+1))
    fi
    
    # Verificar scripts
    if [ -f "$SCRIPT_DIR/pdf-tools-tui.sh" ]; then
        echo -e "  ${GREEN}✅ Script CLI: $SCRIPT_DIR/pdf-tools-tui.sh${NC}"
    else
        echo -e "  ${RED}❌ Script CLI não encontrado${NC}"
        errors=$((errors+1))
    fi
    
    if [ -f "$SCRIPT_DIR/pdf-tools-gui.tcl" ]; then
        echo -e "  ${GREEN}✅ Script GUI: $SCRIPT_DIR/pdf-tools-gui.tcl${NC}"
    else
        echo -e "  ${RED}❌ Script GUI não encontrado${NC}"
        errors=$((errors+1))
    fi
    
    # Verificar comandos no PATH
    echo ""
    if command -v pdf-tools &> /dev/null; then
        echo -e "  ${GREEN}✅ Comando 'pdf-tools' disponível em: $(which pdf-tools)${NC}"
    else
        echo -e "  ${RED}❌ Comando 'pdf-tools' não encontrado no PATH${NC}"
        errors=$((errors+1))
    fi
    
    if command -v pdf-tools-gui &> /dev/null; then
        echo -e "  ${GREEN}✅ Comando 'pdf-tools-gui' disponível em: $(which pdf-tools-gui)${NC}"
    else
        echo -e "  ${RED}❌ Comando 'pdf-tools-gui' não encontrado no PATH${NC}"
        errors=$((errors+1))
    fi
    
    # Verificar configuração
    if [ -f "$CONFIG_DIR/settings.conf" ]; then
        echo -e "  ${GREEN}✅ Configuração encontrada${NC}"
    else
        echo -e "  ${RED}❌ Configuração não encontrada${NC}"
        errors=$((errors+1))
    fi
    
    # Verificar dependências
    check_tcltk
    
    if [ $errors -eq 0 ]; then
        echo -e "\n${GREEN}🎉 INSTALAÇÃO COMPLETA E VERIFICADA!${NC}"
        return 0
    else
        echo -e "\n${YELLOW}⚠️  Foram encontrados $errors erro(s) na instalação${NC}"
        return 1
    fi
}

# ========== DESINSTALAÇÃO ==========

# Desinstalar programa
uninstall_program() {
    echo -e "\n${YELLOW}🗑️  Removendo PDF Tools...${NC}"
    
    read -p "Remover todas as configurações e arquivos? (s/N): " confirm
    if [[ "$confirm" =~ ^[Ss]$ ]]; then
        # Remover diretórios
        rm -rf "$SCRIPT_DIR" 2>/dev/null
        rm -rf "$CONFIG_DIR" 2>/dev/null
        rm -f "$BIN_LINK" 2>/dev/null
        rm -f "$GUI_BIN_LINK" 2>/dev/null
        rm -f "$MENU_DIR/pdf-tools-cli.desktop" 2>/dev/null
        rm -f "$MENU_DIR/pdf-tools-gui.desktop" 2>/dev/null
        rm -f "$ICON_DIR/pdf-tools.svg" 2>/dev/null
        
        echo -e "${GREEN}✅ Programa removido${NC}"
    else
        echo -e "${YELLOW}Desinstalação cancelada${NC}"
    fi
    
    read -p "Pressione ENTER para continuar"
}

# ========== MENU PRINCIPAL ==========

# Menu principal
main_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}Opções de instalação:${NC}\n"
        echo -e "  ${YELLOW}1)${NC} Instalação completa (recomendado)"
        echo -e "  ${YELLOW}2)${NC} Apenas GUI (interface gráfica)"
        echo -e "  ${YELLOW}3)${NC} Verificar dependências"
        echo -e "  ${YELLOW}4)${NC} Desinstalar"
        echo -e "  ${YELLOW}0)${NC} Sair\n"
        
        read -p "Escolha uma opção: " choice
        
        case $choice in
            1)
                check_system
                ensure_directories
                ensure_path
                select_languages
                install_system_deps
                install_python_tools
                install_gui_script
                install_cli_script
                create_cli_wrapper
                create_gui_wrapper
                create_config_file
                create_desktop_entries
                verify_installation
                
                echo -e "\n${GREEN}✅ INSTALAÇÃO CONCLUÍDA!${NC}"
                echo -e "\n📋 Para usar:"
                echo -e "   ${YELLOW}pdf-tools-gui${NC} - Interface gráfica"
                echo -e "   ${YELLOW}pdf-tools${NC}     - Interface de texto"
                echo -e "\n${YELLOW}⚠️  Se os comandos não funcionarem, execute: source ~/.bashrc${NC}"
                break
                ;;
            2)
                check_system
                ensure_directories
                ensure_path
                select_languages
                install_system_deps
                install_gui_script
                create_gui_wrapper
                create_config_file
                create_desktop_entries
                verify_installation
                
                echo -e "\n${GREEN}✅ INSTALAÇÃO GUI CONCLUÍDA!${NC}"
                echo -e "\n📋 Para usar: ${YELLOW}pdf-tools-gui${NC}"
                echo -e "\n${YELLOW}⚠️  Se o comando não funcionar, execute: source ~/.bashrc${NC}"
                break
                ;;
            3)
                check_tcltk
                check_languages
                echo -e "\n${YELLOW}Pressione ENTER para continuar${NC}"
                read
                ;;
            4)
                uninstall_program
                ;;
            0)
                echo -e "\n${YELLOW}Instalação cancelada${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Opção inválida${NC}"
                sleep 2
                ;;
        esac
    done
}

# ========== PONTO DE ENTRADA ==========

# Verificar se já está instalado
check_existing() {
    if [ -f "$GUI_BIN_LINK" ] || [ -f "$BIN_LINK" ]; then
        echo -e "${YELLOW}⚠️  PDF Tools já está instalado${NC}"
        read -p "Deseja reinstalar? (s/N): " reinstall
        if [[ "$reinstall" =~ ^[Ss]$ ]]; then
            uninstall_program
            return 0
        else
            exit 0
        fi
    fi
}

# Main
main() {
    check_existing
    main_menu
}

# Executar
main

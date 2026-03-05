#!/bin/bash

# PDF Tools TUI - Interface de Texto para Ferramentas de PDF
# Versão: 2.2 - INTEGRAÇÃO MODULAR
# Autor: Sistema
# Descrição: Interface unificada para OCR, formulários, conversões e utilitários

# ========== CONFIGURAÇÕES INICIAIS ==========

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/pdf-tools"
WORKSPACE_DIR="$HOME/Documents/PDF_Tools"
LOG_FILE="$CONFIG_DIR/logs/operations.log"
CURRENT_FILE=""
SELECTED_FILE=""

# Criar diretórios necessários
mkdir -p "$CONFIG_DIR"/{logs,presets,cache,temp}
mkdir -p "$WORKSPACE_DIR"/{output,temp}

# Carregar módulos
for _mod in common ocr convert forms batch utils; do
    _mod_file="$SCRIPT_DIR/modules/${_mod}.sh"
    if [[ -f "$_mod_file" ]]; then
        source "$_mod_file"
    else
        echo "AVISO: módulo não encontrado: $_mod_file" >&2
    fi
done
unset _mod _mod_file

# ========== FUNÇÕES DE AJUDA ==========

show_help() {
    cat << EOF
PDF Tools TUI - Interface de Texto para Ferramentas de PDF

USO:
    pdf-tools [opções] [arquivo.pdf]

OPÇÕES:
    -h, --help      Mostra esta ajuda
    -v, --version   Mostra a versão
    -f, --file      Especifica um arquivo PDF para processar
    -o, --ocr       Aplica OCR no arquivo especificado
    -t, --txt       Extrai texto para TXT
    -i, --info      Mostra informações do PDF

EXEMPLOS:
    pdf-tools                    Inicia a interface interativa
    pdf-tools documento.pdf       Abre a interface com o arquivo selecionado
    pdf-tools --ocr arquivo.pdf   Aplica OCR diretamente
    pdf-tools --info arquivo.pdf  Mostra informações do PDF

EOF
}

show_version() {
    echo "PDF Tools TUI versão 2.2"
    echo "Interface de texto para ferramentas de PDF"
    exit 0
}

process_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                ;;
            -f|--file)
                SELECTED_FILE="$2"
                shift 2
                ;;
            -o|--ocr)
                if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
                    SELECTED_FILE="$2"
                    ocr_basic_direct "$SELECTED_FILE"
                    exit $?
                else
                    echo -e "${RED}Erro: Nenhum arquivo especificado para OCR${NC}"
                    exit 1
                fi
                ;;
            -t|--txt)
                if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
                    SELECTED_FILE="$2"
                    extract_text_direct "$SELECTED_FILE"
                    exit $?
                else
                    echo -e "${RED}Erro: Nenhum arquivo especificado para extração${NC}"
                    exit 1
                fi
                ;;
            -i|--info)
                if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
                    SELECTED_FILE="$2"
                    pdf_info_direct "$SELECTED_FILE"
                    exit $?
                else
                    echo -e "${RED}Erro: Nenhum arquivo especificado${NC}"
                    exit 1
                fi
                ;;
            *.pdf)
                SELECTED_FILE="$1"
                shift
                ;;
            *)
                echo -e "${RED}Opção desconhecida: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
}

# ========== FUNÇÕES COMPARTILHADAS ==========
# Estas definições sobrescrevem as versões dos módulos com implementações aprimoradas.

show_banner() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║              📄 PDF Tools TUI v2.2                    ║${NC}"
    echo -e "${BLUE}╠════════════════════════════════════════════════════════╣${NC}"
    if [ -n "$SELECTED_FILE" ] && [ -f "$SELECTED_FILE" ]; then
        echo -e "${BLUE}║${NC}  Arquivo: ${CYAN}$(basename "$SELECTED_FILE")${NC}"
    else
        echo -e "${BLUE}║${NC}  Workspace: ${CYAN}$WORKSPACE_DIR${NC}"
    fi
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Versão aprimorada: garante que o diretório de log existe antes de escrever
log_operation() {
    local operation=$1
    local input=$2
    local output=$3
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    mkdir -p "$(dirname "$LOG_FILE")"
    echo "[$timestamp] $operation | $input → $output" >> "$LOG_FILE"
}

# Versão aprimorada: lembra arquivo selecionado na sessão e usa menu numerado
select_pdf_file() {
    if [ -n "$SELECTED_FILE" ] && [ -f "$SELECTED_FILE" ]; then
        echo -e "${GREEN}📄 Arquivo atual: $SELECTED_FILE${NC}"
        read -p "Usar este arquivo? (s/N): " use_current
        if [[ "$use_current" =~ ^[Ss]$ ]]; then
            return 0
        fi
    fi

    local files=()
    for f in *.pdf; do
        [ -f "$f" ] && files+=("$f")
    done

    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${RED}❌ Nenhum arquivo PDF encontrado no diretório atual${NC}"
        echo -e "${YELLOW}Diretório atual: $(pwd)${NC}"
        return 1
    fi

    if [ ${#files[@]} -eq 1 ]; then
        SELECTED_FILE="${files[0]}"
        echo -e "${GREEN}📄 Arquivo selecionado: $SELECTED_FILE${NC}"
        return 0
    fi

    echo -e "${CYAN}📄 Arquivos PDF disponíveis:${NC}"
    local i=1
    for file in "${files[@]}"; do
        echo "  $i) $file"
        ((i++))
    done
    echo "  0) Cancelar"
    echo ""

    read -p "Escolha um arquivo (número): " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -gt 0 ] && [ "$choice" -le ${#files[@]} ]; then
        SELECTED_FILE="${files[$((choice-1))]}"
        echo -e "${GREEN}📄 Selecionado: $SELECTED_FILE${NC}"
        return 0
    else
        echo -e "${YELLOW}Operação cancelada${NC}"
        return 1
    fi
}

# Versão aprimorada: guard para total=0
show_progress() {
    local current=$1
    local total=$2
    local width=50
    [ "$total" -eq 0 ] && return
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))

    printf "\r["
    printf "%${completed}s" | tr ' ' '='
    printf "%${remaining}s" | tr ' ' ' '
    printf "] %d%%" "$percentage"
}

# ========== FUNÇÕES DIRETAS (LINHA DE COMANDO) ==========

ocr_basic_direct() {
    local file=$1
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ Arquivo não encontrado: $file${NC}"
        return 1
    fi

    local output="${file%.*}_ocr.pdf"
    echo -e "${YELLOW}Aplicando OCR em: $file${NC}"

    if command -v ocrmypdf &> /dev/null; then
        ocrmypdf --language por "$file" "$output"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ OCR concluído: $output${NC}"
            return 0
        else
            echo -e "${RED}❌ Erro no OCR${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ ocrmypdf não encontrado${NC}"
        return 1
    fi
}

extract_text_direct() {
    local file=$1
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ Arquivo não encontrado: $file${NC}"
        return 1
    fi

    local output="${file%.*}.txt"
    echo -e "${YELLOW}Extraindo texto de: $file${NC}"

    if command -v pdftotext &> /dev/null; then
        pdftotext -layout "$file" "$output"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Texto extraído: $output${NC}"
            return 0
        else
            echo -e "${RED}❌ Erro na extração${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ pdftotext não encontrado${NC}"
        return 1
    fi
}

pdf_info_direct() {
    local file=$1
    if [ ! -f "$file" ]; then
        echo -e "${RED}❌ Arquivo não encontrado: $file${NC}"
        return 1
    fi

    echo -e "${CYAN}════════════════════════ INFORMAÇÕES DO PDF ════════════════════════${NC}"
    echo ""

    if command -v pdfinfo &> /dev/null; then
        pdfinfo "$file" 2>/dev/null
    else
        ls -lh "$file"
    fi

    return 0
}

# ========== MENU PRINCIPAL ==========

main_menu() {
    while true; do
        show_banner
        echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║                    MENU PRINCIPAL                      ║${NC}"
        echo -e "${BLUE}╠════════════════════════════════════════════════════════╣${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}1)${NC} 📋 OCR e Reconhecimento de Texto"
        echo -e "${BLUE}║${NC}  ${YELLOW}2)${NC} 🔍 Formulários e Campos"
        echo -e "${BLUE}║${NC}  ${YELLOW}3)${NC} 🔄 Conversões de PDF"
        echo -e "${BLUE}║${NC}  ${YELLOW}4)${NC} 🔧 Utilitários"
        echo -e "${BLUE}║${NC}  ${YELLOW}5)${NC} 📦 Processamento em Lote"
        echo -e "${BLUE}║${NC}  ${YELLOW}6)${NC} ⚙️  Configurações"
        echo -e "${BLUE}║${NC}  ${YELLOW}0)${NC} Sair"
        echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
        echo ""
        read -p "Escolha uma opção: " choice

        case $choice in
            1) ocr_menu ;;
            2) forms_menu ;;
            3) convert_menu ;;
            4) utils_menu ;;
            5) batch_menu ;;
            6) config_menu ;;
            0)
                echo -e "\n${GREEN}Até logo! 👋${NC}"
                exit 0
                ;;
            *) echo -e "${RED}Opção inválida${NC}"; sleep 2 ;;
        esac
    done
}

# ========== CONFIGURAÇÕES ==========

config_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                    ⚙️  Configurações                    ║${NC}"
        echo -e "${CYAN}╠════════════════════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║${NC}  ${YELLOW}1)${NC} Diretório de trabalho: $WORKSPACE_DIR"
        echo -e "${CYAN}║${NC}  ${YELLOW}2)${NC} Verificar dependências"
        echo -e "${CYAN}║${NC}  ${YELLOW}3)${NC} Sobre"
        echo -e "${CYAN}║${NC}  ${YELLOW}0)${NC} Voltar"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
        echo ""
        read -p "Escolha uma opção: " opt

        case $opt in
            1)
                read -p "Novo diretório de trabalho: " new_dir
                mkdir -p "$new_dir"
                WORKSPACE_DIR="$new_dir"
                echo -e "${GREEN}✅ Diretório alterado${NC}"
                sleep 2
                ;;
            2)
                echo -e "\n${CYAN}Verificando dependências...${NC}"
                for cmd in ocrmypdf tesseract pandoc convert pdfinfo pdftotext gs commonforms pdfcpu wish; do
                    if command -v $cmd &>/dev/null; then
                        echo -e "  ${GREEN}✅ $cmd${NC}"
                    else
                        echo -e "  ${RED}❌ $cmd${NC}"
                    fi
                done
                read -p "Pressione ENTER para continuar"
                ;;
            3)
                echo -e "\n${CYAN}PDF Tools TUI v2.2${NC}"
                echo "Interface de texto para ferramentas de PDF"
                echo "Autor: Sistema"
                echo ""
                read -p "Pressione ENTER para continuar"
                ;;
            0)
                return
                ;;
        esac
    done
}

# ========== INICIALIZAÇÃO ==========

if [ $# -gt 0 ]; then
    process_args "$@"
fi

main_menu

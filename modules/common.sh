#!/bin/bash

# Funções compartilhadas entre todos os módulos

# Selecionar arquivo PDF interativamente
select_pdf_file() {
    local files=(*.pdf)
    
    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${RED}❌ Nenhum arquivo PDF encontrado no diretório atual${NC}"
        return 1
    fi
    
    if [ ${#files[@]} -eq 1 ]; then
        SELECTED_FILE="${files[0]}"
        echo -e "${GREEN}📄 Arquivo selecionado: $SELECTED_FILE${NC}"
        return 0
    fi
    
    echo -e "${CYAN}📄 Arquivos PDF disponíveis:${NC}"
    select file in "${files[@]}" "Cancelar"; do
        if [ "$file" = "Cancelar" ]; then
            return 1
        fi
        if [ -n "$file" ]; then
            SELECTED_FILE="$file"
            echo -e "${GREEN}📄 Selecionado: $SELECTED_FILE${NC}"
            return 0
        else
            echo -e "${RED}Opção inválida${NC}"
        fi
    done
}

# Log de operações
log_operation() {
    local operation=$1
    local input=$2
    local output=$3
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] $operation | $input → $output" >> "$LOG_FILE"
}

# Verificar dependência
check_dependency() {
    local cmd=$1
    local package=${2:-$1}
    
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${YELLOW}⚠️  $cmd não encontrado${NC}"
        read -p "Instalar $package? (s/N): " install
        if [[ "$install" =~ ^[Ss]$ ]]; then
            case $PKG_MANAGER in
                dnf) sudo dnf install -y "$package" ;;
                apt) sudo apt install -y "$package" ;;
                pacman) sudo pacman -S --noconfirm "$package" ;;
            esac
        fi
    fi
}

# Progress bar
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

# Limpar caracteres especiais
sanitize_filename() {
    echo "$1" | sed 's/[^a-zA-Z0-9._-]/_/g'
}

# Mostrar erro e sair
show_error() {
    echo -e "${RED}❌ Erro: $1${NC}" >&2
    return 1
}

# Verificar se arquivo existe e não está vazio
validate_pdf() {
    local file=$1
    
    if [ ! -f "$file" ]; then
        show_error "Arquivo não encontrado: $file"
        return 1
    fi
    
    if [ ! -s "$file" ]; then
        show_error "Arquivo vazio: $file"
        return 1
    fi
    
    # Verificar se é PDF válido
    if ! pdfinfo "$file" &>/dev/null; then
        show_error "Arquivo não é um PDF válido: $file"
        return 1
    fi
    
    return 0
}

# Criar diretório de saída se não existir
ensure_output_dir() {
    local dir=$1
    
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi
}

# Obter nome base do arquivo sem extensão
get_basename() {
    local file=$1
    basename "$file" .pdf
}

# Abrir arquivo com aplicativo padrão
open_with_default() {
    local file=$1
    
    if command -v xdg-open &>/dev/null; then
        xdg-open "$file"
    elif command -v open &>/dev/null; then
        open "$file"
    else
        echo -e "${YELLOW}Não foi possível abrir o arquivo automaticamente${NC}"
    fi
}

# Menu de confirmação
confirm_action() {
    local message=${1:-"Confirmar?"}
    
    read -p "$message (s/N): " confirm
    [[ "$confirm" =~ ^[Ss]$ ]]
}

# Obter tamanho do arquivo formatado
get_file_size() {
    local file=$1
    du -h "$file" | cut -f1
}

# Extrair texto do PDF (função auxiliar do módulo — não colide com a versão inline)
extract_text_common() {
    local file=$1
    local output=$2

    pdftotext "$file" "$output" 2>/dev/null
}

# Contar palavras no PDF
count_words() {
    local file=$1
    local temp_txt="/tmp/pdf_word_count.txt"
    
    pdftotext "$file" "$temp_txt" 2>/dev/null
    local words=$(wc -w < "$temp_txt" 2>/dev/null)
    rm -f "$temp_txt"
    
    echo "${words:-0}"
}

# Menu rápido com fzf (se disponível)
fzf_menu() {
    local prompt=$1
    shift
    local options=("$@")
    
    if command -v fzf &>/dev/null; then
        printf "%s\n" "${options[@]}" | fzf --prompt="$prompt > "
    else
        select opt in "${options[@]}"; do
            echo "$opt"
            break
        done
    fi
}

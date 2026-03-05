#!/bin/bash

# Módulo de Processamento em Lote

batch_menu() {
    while true; do
        clear
        echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║              📦 Processamento em Lote                  ║${NC}"
        echo -e "${BLUE}╠════════════════════════════════════════════════════════╣${NC}"
        echo -e "${BLUE}║${NC}  ${YELLOW}1)${NC} Aplicar OCR em múltiplos PDFs"
        echo -e "${BLUE}║${NC}  ${YELLOW}2)${NC} Converter PDFs para TXT"
        echo -e "${BLUE}║${NC}  ${YELLOW}3)${NC} Converter PDFs para DOCX"
        echo -e "${BLUE}║${NC}  ${YELLOW}4)${NC} Extrair imagens de PDFs"
        echo -e "${BLUE}║${NC}  ${YELLOW}5)${NC} Comprimir múltiplos PDFs"
        echo -e "${BLUE}║${NC}  ${YELLOW}6)${NC} Renomear arquivos em lote"
        echo -e "${BLUE}║${NC}  ${YELLOW}7)${NC} Processar com script personalizado"
        echo -e "${BLUE}║${NC}  ${YELLOW}8)${NC} Salvar configuração de lote"
        echo -e "${BLUE}║${NC}  ${YELLOW}0)${NC} Voltar"
        echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
        echo ""
        read -p "Escolha uma opção: " opt
        
        case $opt in
            1) batch_ocr ;;
            2) batch_to_txt ;;
            3) batch_to_docx ;;
            4) batch_extract_images ;;
            5) batch_compress ;;
            6) batch_rename ;;
            7) batch_custom ;;
            8) batch_save_config ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida${NC}"; sleep 2 ;;
        esac
    done
}

batch_ocr() {
    echo -e "\n${CYAN}📁 Diretório atual: $(pwd)${NC}"
    
    local pattern="*.pdf"
    read -p "Padrão de arquivos [*.pdf]: " input_pattern
    pattern=${input_pattern:-$pattern}
    
    local files=($pattern)
    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${RED}Nenhum arquivo encontrado${NC}"
        read -p "Pressione ENTER para continuar"
        return
    fi
    
    echo -e "\n${YELLOW}Arquivos encontrados (${#files[@]}):${NC}"
    for f in "${files[@]}"; do
        echo "  - $f"
    done
    
    echo -e "\n${CYAN}Opções de OCR:${NC}"
    echo "1) Básico (rápido)"
    echo "2) Com melhoria (recomendado)"
    echo "3) Forçado (sobrescrever texto)"
    read -p "Escolha [2]: " ocr_type
    ocr_type=${ocr_type:-2}
    
    local ocr_opts="--language por"
    case $ocr_type in
        1) ocr_opts="$ocr_opts" ;;
        2) ocr_opts="$ocr_opts --deskew --clean" ;;
        3) ocr_opts="$ocr_opts --force-ocr --deskew --clean" ;;
    esac
    
    local output_dir="ocr_output_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$output_dir"
    
    local total=${#files[@]}
    local current=0
    local success=0
    local failed=0
    
    echo -e "\n${YELLOW}Processando...${NC}\n"
    
    for file in "${files[@]}"; do
        current=$((current + 1))
        echo -ne "${CYAN}[$current/$total]${NC} Processando: $file ... "
        
        local output="$output_dir/${file%.*}_ocr.pdf"
        
        if ! command -v ocrmypdf &>/dev/null; then
            echo -e "${RED}❌ ocrmypdf não encontrado. Execute o instalador.${NC}"
            read -p "Pressione ENTER para continuar"
            return
        fi

        if ocrmypdf $ocr_opts "$file" "$output" &>/dev/null; then
            echo -e "${GREEN}✅${NC}"
            success=$((success + 1))
        else
            echo -e "${RED}❌${NC}"
            failed=$((failed + 1))
        fi
    done
    
    echo -e "\n${GREEN}✅ Processamento concluído!${NC}"
    echo -e "${CYAN}📊 Resumo:${NC}"
    echo "  Total: $total"
    echo "  ✅ Sucesso: $success"
    echo "  ❌ Falhas: $failed"
    echo "  📁 Arquivos salvos em: $output_dir"
    
    read -p "Pressione ENTER para continuar"
}

batch_to_txt() {
    batch_convert_function "TXT" "pdftotext" "txt"
}

batch_to_docx() {
    batch_convert_function "DOCX" "pandoc" "docx"
}

batch_convert_function() {
    local format=$1
    local converter=$2
    local extension=$3
    
    echo -e "\n${CYAN}📁 Diretório atual: $(pwd)${NC}"
    
    local files=(*.pdf)
    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${RED}Nenhum PDF encontrado${NC}"
        read -p "Pressione ENTER para continuar"
        return
    fi
    
    echo "Convertendo ${#files[@]} PDFs para $format"
    read -p "Confirmar? (s/N): " confirm
    
    if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
        return
    fi
    
    local output_dir="convert_${format}_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$output_dir"
    
    local total=${#files[@]}
    local current=0
    
    for file in "${files[@]}"; do
        current=$((current + 1))
        echo -ne "${CYAN}[$current/$total]${NC} Convertendo: $file ... "
        
        local output="$output_dir/${file%.*}.$extension"
        
        local ok=false
        case $converter in
            "pdftotext")
                pdftotext "$file" "$output" &>/dev/null && ok=true ;;
            "pandoc")
                pandoc "$file" -o "$output" &>/dev/null && ok=true ;;
            *)
                echo -e "${RED}❌ Conversor desconhecido: $converter${NC}"
                break
                ;;
        esac

        $ok && echo -e "${GREEN}✅${NC}" || echo -e "${RED}❌${NC}"
    done
    
    echo -e "\n${GREEN}✅ Conversões salvas em: $output_dir${NC}"
    read -p "Pressione ENTER para continuar"
}

batch_extract_images() {
    echo -e "\n${CYAN}📁 Diretório atual: $(pwd)${NC}"
    
    local files=(*.pdf)
    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${RED}Nenhum PDF encontrado${NC}"
        return
    fi
    
    local output_dir="imagens_extraidas_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$output_dir"
    
    local total=${#files[@]}
    local current=0
    
    for file in "${files[@]}"; do
        current=$((current + 1))
        echo -e "${CYAN}[$current/$total]${NC} Extraindo imagens de: $file"
        
        local file_base="$output_dir/${file%.*}"
        pdfimages -all "$file" "$file_base" 2>/dev/null
        
        local img_count=$(ls "$file_base"* 2>/dev/null | wc -l)
        echo "  → $img_count imagens extraídas"
    done
    
    echo -e "\n${GREEN}✅ Imagens salvas em: $output_dir${NC}"
    read -p "Pressione ENTER para continuar"
}

batch_compress() {
    echo -e "\n${CYAN}📁 Comprimir múltiplos PDFs${NC}"
    
    local files=(*.pdf)
    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${RED}Nenhum PDF encontrado${NC}"
        return
    fi
    
    echo "Nível de compressão:"
    echo "1) Baixa (qualidade alta)"
    echo "2) Média (recomendado)"
    echo "3) Alta (arquivo pequeno)"
    read -p "Escolha [2]: " level
    level=${level:-2}
    
    local quality
    case $level in
        1) quality="/printer" ;;
        2) quality="/ebook" ;;
        3) quality="/screen" ;;
    esac
    
    local output_dir="comprimidos_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$output_dir"
    
    local total=${#files[@]}
    local current=0
    
    echo ""
    for file in "${files[@]}"; do
        current=$((current + 1))
        echo -ne "${CYAN}[$current/$total]${NC} Comprimindo: $file ... "
        
        local output="$output_dir/${file}"
        local original_size
        original_size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo 0)
        
        gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=$quality \
           -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$output" "$file" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            local new_size
            new_size=$(stat -c%s "$output" 2>/dev/null || stat -f%z "$output" 2>/dev/null || echo 0)
            if [ "$original_size" -gt 0 ]; then
                local reduction=$((100 - (new_size * 100 / original_size)))
                echo -e "${GREEN}✅ ${reduction}% menor${NC}"
            else
                echo -e "${GREEN}✅${NC}"
            fi
        else
            echo -e "${RED}❌${NC}"
        fi
    done
    
    echo -e "\n${GREEN}✅ Arquivos comprimidos em: $output_dir${NC}"
    read -p "Pressione ENTER para continuar"
}

batch_rename() {
    echo -e "\n${CYAN}📁 Renomear arquivos em lote${NC}"
    
    local files=(*.pdf)
    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${RED}Nenhum PDF encontrado${NC}"
        return
    fi
    
    echo "Padrões de renomeação:"
    echo "1) Adicionar prefixo"
    echo "2) Adicionar sufixo"
    echo "3) Substituir texto"
    echo "4) Numerar sequencialmente"
    echo "5) Usar data atual"
    read -p "Escolha: " rename_type
    
    case $rename_type in
        1)
            read -p "Prefixo: " prefix
            for file in "${files[@]}"; do
                mv -v "$file" "${prefix}${file}"
            done
            ;;
        2)
            read -p "Sufixo: " sufix
            for file in "${files[@]}"; do
                mv -v "$file" "${file%.*}${sufix}.pdf"
            done
            ;;
        3)
            read -p "Texto a substituir: " old
            read -p "Novo texto: " new
            for file in "${files[@]}"; do
                mv -v "$file" "${file//$old/$new}"
            done
            ;;
        4)
            local num=1
            for file in "${files[@]}"; do
                mv -v "$file" "$(printf "documento_%03d.pdf" $num)"
                num=$((num + 1))
            done
            ;;
        5)
            local date_str=$(date +%Y%m%d)
            for file in "${files[@]}"; do
                mv -v "$file" "${date_str}_${file}"
            done
            ;;
    esac
    
    echo -e "${GREEN}✅ Renomeação concluída${NC}"
    read -p "Pressione ENTER para continuar"
}

batch_custom() {
    echo -e "\n${CYAN}🔧 Processamento personalizado${NC}"
    echo "Digite o comando para cada arquivo (use {} para o arquivo):"
    echo "Exemplo: ocrmypdf --language por {} {}.ocr.pdf"
    echo ""
    read -p "Comando: " cmd_template
    
    if [ -z "$cmd_template" ]; then
        echo -e "${RED}Comando vazio${NC}"
        return
    fi
    
    local files=(*.pdf)
    local total=${#files[@]}
    local current=0
    
    for file in "${files[@]}"; do
        current=$((current + 1))
        echo -e "${CYAN}[$current/$total]${NC} Processando: $file"
        
        local cmd="${cmd_template//\{\}/\"${file//\"/\\\"}\"}"
        bash -c "$cmd"
    done
    
    echo -e "${GREEN}✅ Processamento concluído${NC}"
    read -p "Pressione ENTER para continuar"
}

batch_save_config() {
    echo -e "\n${CYAN}💾 Salvar configuração de lote${NC}"
    read -p "Nome da configuração: " config_name
    
    if [ -z "$config_name" ]; then
        echo -e "${RED}Nome inválido${NC}"
        return
    fi
    
    local config_file="$CONFIG_DIR/batch_${config_name}.conf"
    
    cat > "$config_file" << EOF
# Configuração de lote: $config_name
# Criado em: $(date)

# Diretório de origem
SOURCE_DIR="$(pwd)"

# Comando a ser executado
COMMAND=""

# Opções
RECURSIVE=false
OUTPUT_DIR=""
EOF
    
    echo -e "${GREEN}✅ Configuração salva em: $config_file${NC}"
    echo "Edite o arquivo para adicionar o comando desejado."
    
    read -p "Pressione ENTER para continuar"
}

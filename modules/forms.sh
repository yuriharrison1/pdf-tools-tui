#!/bin/bash

# Módulo de Formulários - CommonForms
# Gerencia detecção e criação de campos em PDF

forms_menu() {
    while true; do
        clear
        echo -e "${PURPLE}╔════════════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║              🔍 Formulários e Campos                   ║${NC}"
        echo -e "${PURPLE}╠════════════════════════════════════════════════════════╣${NC}"
        echo -e "${PURPLE}║${NC}  ${YELLOW}1)${NC} Detectar campos automaticamente"
        echo -e "${PURPLE}║${NC}  ${YELLOW}2)${NC} Detectar com assinaturas"
        echo -e "${PURPLE}║${NC}  ${YELLOW}3)${NC} Modo rápido (teste)"
        echo -e "${PURPLE}║${NC}  ${YELLOW}4)${NC} Extrair campos para arquivo"
        echo -e "${PURPLE}║${NC}  ${YELLOW}5)${NC} Preencher formulário via JSON"
        echo -e "${PURPLE}║${NC}  ${YELLOW}6)${NC} Listar campos existentes"
        echo -e "${PURPLE}║${NC}  ${YELLOW}7)${NC} Remover campos (limpar formulário)"
        echo -e "${PURPLE}║${NC}  ${YELLOW}8)${NC} Converter para PDF/A (arquivamento)"
        echo -e "${PURPLE}║${NC}  ${YELLOW}0)${NC} Voltar"
        echo -e "${PURPLE}╚════════════════════════════════════════════════════════╝${NC}"
        echo ""
        read -p "Escolha uma opção: " opt
        
        case $opt in
            1) forms_detect ;;
            2) forms_detect_signature ;;
            3) forms_fast ;;
            4) forms_extract_json ;;
            5) forms_fill_json ;;
            6) forms_list_fields ;;
            7) forms_remove_fields ;;
            8) forms_to_pdfa ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida${NC}"; sleep 2 ;;
        esac
    done
}

forms_detect() {
    select_pdf_file || return
    
    local output_name="${SELECTED_FILE%.*}_com_campos.pdf"
    read -p "Nome do arquivo de saída [$output_name]: " output
    output=${output:-$output_name}
    
    echo -e "${YELLOW}Detectando campos no documento...${NC}"
    commonforms "$SELECTED_FILE" "$output"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Campos detectados e salvos em: $output${NC}"
        log_operation "Detecção de campos" "$SELECTED_FILE" "$output"
        
        # Mostrar estatísticas
        forms_list_fields "$output" --quiet
    else
        echo -e "${RED}❌ Erro na detecção de campos${NC}"
    fi
    
    read -p "Pressione ENTER para continuar"
}

forms_detect_signature() {
    select_pdf_file || return
    
    local output_name="${SELECTED_FILE%.*}_com_assinaturas.pdf"
    read -p "Nome do arquivo de saída [$output_name]: " output
    output=${output:-$output_name}
    
    echo -e "${YELLOW}Detectando campos e áreas de assinatura...${NC}"
    commonforms --use-signature-fields "$SELECTED_FILE" "$output"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Campos e assinaturas detectados${NC}"
    else
        echo -e "${RED}❌ Erro na detecção${NC}"
    fi
    
    read -p "Pressione ENTER para continuar"
}

forms_fast() {
    select_pdf_file || return
    
    local output_name="${SELECTED_FILE%.*}_rapido.pdf"
    read -p "Nome do arquivo de saída [$output_name]: " output
    output=${output:-$output_name}
    
    echo -e "${YELLOW}Modo rápido (para testes)...${NC}"
    commonforms --fast "$SELECTED_FILE" "$output"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Processamento rápido concluído${NC}"
    else
        echo -e "${RED}❌ Erro${NC}"
    fi
    
    read -p "Pressione ENTER para continuar"
}

forms_extract_json() {
    select_pdf_file || return

    local out_name="${SELECTED_FILE%.*}_campos.txt"
    read -p "Nome do arquivo de saída [$out_name]: " out_file
    out_file=${out_file:-$out_name}

    echo -e "${YELLOW}Extraindo campos...${NC}"

    # pdfcpu form list retorna texto formatado, não JSON
    if command -v pdfcpu &> /dev/null; then
        pdfcpu form list "$SELECTED_FILE" > "$out_file" 2>/dev/null
        echo -e "${GREEN}✅ Campos extraídos para: $out_file${NC}"
    else
        echo -e "${RED}❌ pdfcpu não instalado. Use o instalador.${NC}"
    fi

    read -p "Pressione ENTER para continuar"
}

forms_fill_json() {
    select_pdf_file || return
    
    echo -e "${CYAN}Arquivos JSON disponíveis:${NC}"
    select json in *.json; do
        if [ -n "$json" ]; then
            break
        fi
    done
    
    local output_name="${SELECTED_FILE%.*}_preenchido.pdf"
    read -p "Nome do arquivo de saída [$output_name]: " output
    output=${output:-$output_name}
    
    if command -v pdfcpu &> /dev/null; then
        pdfcpu form fill -f "$json" "$SELECTED_FILE" "$output"
        echo -e "${GREEN}✅ Formulário preenchido: $output${NC}"
    else
        echo -e "${RED}❌ pdfcpu não instalado${NC}"
    fi
    
    read -p "Pressione ENTER para continuar"
}

forms_list_fields() {
    local file=${1:-$(select_pdf_file_interactive)}
    [ -z "$file" ] && return
    
    local quiet=${2:-false}
    
    echo -e "${CYAN}📋 Campos encontrados no formulário:${NC}"
    echo ""
    
    if command -v pdfcpu &> /dev/null; then
        pdfcpu form list "$file" 2>/dev/null || echo "Nenhum campo detectado"
    else
        # Fallback: usar pdftk se disponível
        pdftk "$file" dump_data_fields 2>/dev/null | grep -E "FieldType|FieldName" || \
        echo "Nenhum campo detectado ou ferramenta não disponível"
    fi
    
    if [ "$quiet" = false ]; then
        read -p "Pressione ENTER para continuar"
    fi
}

forms_remove_fields() {
    select_pdf_file || return
    
    local output_name="${SELECTED_FILE%.*}_sem_campos.pdf"
    read -p "Nome do arquivo de saída [$output_name]: " output
    output=${output:-$output_name}
    
    echo -e "${YELLOW}Removendo campos do formulário...${NC}"
    
    # Usar ghostscript para achatar formulários
    gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite \
       -sOutputFile="$output" "$SELECTED_FILE"
    
    echo -e "${GREEN}✅ Campos removidos (formulário achatado)${NC}"
    read -p "Pressione ENTER para continuar"
}

forms_to_pdfa() {
    select_pdf_file || return
    
    local output_name="${SELECTED_FILE%.*}_pdfa.pdf"
    read -p "Nome do arquivo de saída [$output_name]: " output
    output=${output:-$output_name}
    
    echo -e "${YELLOW}Convertendo para PDF/A (formato de arquivamento)...${NC}"
    
    gs -dPDFA -dBATCH -dNOPAUSE -dNOOUTERSAVE -dUseCIEColor \
       -sProcessColorModel=DeviceRGB -sDEVICE=pdfwrite \
       -sOutputFile="$output" "$SELECTED_FILE"
    
    echo -e "${GREEN}✅ PDF/A gerado: $output${NC}"
    read -p "Pressione ENTER para continuar"
}

select_pdf_file_interactive() {
    local files=(*.pdf)
    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${RED}Nenhum PDF encontrado${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Selecione um arquivo PDF:${NC}"
    select file in "${files[@]}"; do
        if [ -n "$file" ]; then
            echo "$file"
            return 0
        fi
    done
}

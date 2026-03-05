#!/bin/bash

# Módulo de Utilitários

utils_menu() {
    while true; do
        show_banner
        echo -e "${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║              🔧 Utilitários                            ║${NC}"
        echo -e "${YELLOW}╠════════════════════════════════════════════════════════╣${NC}"
        echo -e "${YELLOW}║${NC}  ${YELLOW}1)${NC} 📊 Informações do PDF"
        echo -e "${YELLOW}║${NC}  ${YELLOW}2)${NC} 🔍 Buscar texto em PDFs"
        echo -e "${YELLOW}║${NC}  ${YELLOW}3)${NC} 🖼️  Extrair imagens"
        echo -e "${YELLOW}║${NC}  ${YELLOW}4)${NC} 🔄 Reparar PDF corrompido"
        echo -e "${YELLOW}║${NC}  ${YELLOW}5)${NC} 📋 Histórico de operações"
        echo -e "${YELLOW}║${NC}  ${YELLOW}6)${NC} 🧹 Limpar temporários"
        echo -e "${YELLOW}║${NC}  ${YELLOW}0)${NC} Voltar"
        echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
        echo ""
        read -p "Escolha uma opção: " opt

        case $opt in
            1) pdf_info ;;
            2) pdf_search ;;
            3) extract_images ;;
            4) repair_pdf ;;
            5) show_history ;;
            6) clean_temp ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida${NC}"; sleep 2 ;;
        esac
    done
}

pdf_info() {
    select_pdf_file || return

    clear
    echo -e "${CYAN}════════════════════════ INFORMAÇÕES DO PDF ════════════════════════${NC}"
    echo ""

    if command -v pdfinfo &> /dev/null; then
        pdfinfo "$SELECTED_FILE" 2>/dev/null || {
            echo -e "${RED}Erro ao ler informações do PDF${NC}"
            read -p "Pressione ENTER para continuar"
            return
        }
    else
        echo -e "${RED}pdfinfo não encontrado${NC}"
        ls -lh "$SELECTED_FILE"
    fi

    echo ""
    read -p "Pressione ENTER para continuar"
}

pdf_search() {
    read -p "Termo de busca: " search_term

    if [ -z "$search_term" ]; then
        echo -e "${RED}Termo não informado${NC}"
        read -p "Pressione ENTER para continuar"
        return
    fi

    read -p "Diretório para busca [.]: " search_dir
    search_dir=${search_dir:-.}

    echo -e "\n${CYAN}Buscando '$search_term' em $search_dir...${NC}\n"

    if command -v pdfgrep &> /dev/null; then
        pdfgrep -r -n -i "$search_term" "$search_dir"/*.pdf 2>/dev/null || \
            echo "Nenhuma ocorrência encontrada"
    else
        echo -e "${YELLOW}pdfgrep não instalado. Usando método lento...${NC}"
        local found=0
        for pdf in "$search_dir"/*.pdf; do
            [ -f "$pdf" ] || continue
            if pdftotext "$pdf" - 2>/dev/null | grep -i -q "$search_term"; then
                echo "✅ Encontrado em: $(basename "$pdf")"
                found=$((found + 1))
            fi
        done
        [ $found -eq 0 ] && echo "Nenhuma ocorrência encontrada"
    fi

    echo ""
    read -p "Pressione ENTER para continuar"
}

extract_images() {
    select_pdf_file || return

    local output_dir="${SELECTED_FILE%.*}_imagens"
    mkdir -p "$output_dir"

    echo -e "${YELLOW}Extraindo imagens...${NC}"

    if command -v pdfimages &> /dev/null; then
        pdfimages -all "$SELECTED_FILE" "$output_dir/imagem"

        local count
        count=$(ls -1 "$output_dir" 2>/dev/null | wc -l)

        if [ "$count" -gt 0 ]; then
            echo -e "${GREEN}✅ $count imagens extraídas para: $output_dir${NC}"
            log_operation "Extrair imagens" "$SELECTED_FILE" "$output_dir"
        else
            echo -e "${YELLOW}Nenhuma imagem encontrada${NC}"
            rmdir "$output_dir"
        fi
    else
        echo -e "${RED}❌ pdfimages não encontrado${NC}"
    fi

    read -p "Pressione ENTER para continuar"
}

repair_pdf() {
    select_pdf_file || return

    local output_name="${SELECTED_FILE%.*}_reparado.pdf"
    read -p "Nome do arquivo de saída [$output_name]: " output
    output=${output:-$output_name}

    echo -e "${YELLOW}Tentando reparar PDF...${NC}"

    if command -v gs &> /dev/null; then
        gs -o "$output" -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress \
           -dCompatibilityLevel=1.4 "$SELECTED_FILE" 2>/dev/null

        if [ $? -eq 0 ] && [ -s "$output" ]; then
            echo -e "${GREEN}✅ PDF reparado: $output${NC}"
            log_operation "Reparar PDF" "$SELECTED_FILE" "$output"
        else
            echo -e "${RED}❌ Não foi possível reparar${NC}"
        fi
    else
        echo -e "${RED}❌ gs (Ghostscript) não encontrado${NC}"
    fi

    read -p "Pressione ENTER para continuar"
}

show_history() {
    clear
    echo -e "${CYAN}════════════════════════ HISTÓRICO DE OPERAÇÕES ════════════════════════${NC}"
    echo ""

    if [ -f "$LOG_FILE" ]; then
        tail -20 "$LOG_FILE" | nl
    else
        echo "Nenhuma operação registrada ainda."
    fi

    echo ""
    read -p "Pressione ENTER para continuar"
}

clean_temp() {
    echo -e "${YELLOW}Limpando arquivos temporários...${NC}"

    rm -rf "$WORKSPACE_DIR/temp"/* 2>/dev/null
    rm -f /tmp/pdf_*.txt 2>/dev/null
    rm -f /tmp/pdf_tools_*.sh 2>/dev/null

    echo -e "${GREEN}✅ Arquivos temporários removidos${NC}"
    read -p "Pressione ENTER para continuar"
}

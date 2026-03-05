#!/bin/bash

# Módulo de OCR - Versão Completa
# Gerencia todas as operações de reconhecimento de texto

ocr_menu() {
    while true; do
        clear
        echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              📋 OCR e Reconhecimento de Texto          ║${NC}"
        echo -e "${CYAN}╠════════════════════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║${NC}  Arquivo atual: ${YELLOW}$CURRENT_FILE${NC}"
        echo -e "${CYAN}╠════════════════════════════════════════════════════════╣${NC}"
        echo -e "${CYAN}║${NC}  ${YELLOW}1)${NC} Aplicar OCR básico"
        echo -e "${CYAN}║${NC}  ${YELLOW}2)${NC} OCR com melhoria de qualidade"
        echo -e "${CYAN}║${NC}  ${YELLOW}3)${NC} OCR forçado (sobrescrever texto existente)"
        echo -e "${CYAN}║${NC}  ${YELLOW}4)${NC} OCR em lote (múltiplos arquivos)"
        echo -e "${CYAN}║${NC}  ${YELLOW}5)${NC} Extrair texto para TXT"
        echo -e "${CYAN}║${NC}  ${YELLOW}6)${NC} Extrair texto com formatação"
        echo -e "${CYAN}║${NC}  ${YELLOW}7)${NC} Verificar se PDF tem texto"
        echo -e "${CYAN}║${NC}  ${YELLOW}8)${NC} Configurar idiomas do OCR"
        echo -e "${CYAN}║${NC}  ${YELLOW}9)${NC} Visualizar texto extraído"
        echo -e "${CYAN}║${NC}  ${YELLOW}0)${NC} Voltar"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
        echo ""
        read -p "Escolha uma opção: " opt
        
        case $opt in
            1) ocr_basic ;;
            2) ocr_advanced ;;
            3) ocr_force ;;
            4) ocr_batch ;;
            5) extract_text_simple ;;
            6) extract_text_formatted ;;
            7) check_text ;;
            8) ocr_languages ;;
            9) view_extracted_text ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida${NC}"; sleep 2 ;;
        esac
    done
}

ocr_basic() {
    select_pdf_file || return

    if ! command -v ocrmypdf &>/dev/null; then
        echo -e "${RED}❌ ocrmypdf não encontrado. Execute o instalador.${NC}"
        read -p "Pressione ENTER para continuar"
        return
    fi

    local output_name="${SELECTED_FILE%.*}_ocr.pdf"
    read -p "Nome do arquivo de saída [$output_name]: " output
    output=${output:-$output_name}

    echo -e "\n${CYAN}📥 Idioma padrão: português${NC}"
    echo -e "${YELLOW}Processando OCR básico...${NC}"

    ocrmypdf --language por "$SELECTED_FILE" "$output"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ OCR concluído: $output${NC}"
        log_operation "OCR básico" "$SELECTED_FILE" "$output"
    else
        echo -e "${RED}❌ Erro no OCR${NC}"
    fi
    
    read -p "Pressione ENTER para continuar"
}

ocr_advanced() {
    select_pdf_file || return

    if ! command -v ocrmypdf &>/dev/null; then
        echo -e "${RED}❌ ocrmypdf não encontrado. Execute o instalador.${NC}"
        read -p "Pressione ENTER para continuar"
        return
    fi

    local output_name="${SELECTED_FILE%.*}_ocr_melhorado.pdf"
    read -p "Nome do arquivo de saída [$output_name]: " output
    output=${output:-$output_name}
    
    echo -e "\n${CYAN}⚙️  Opções avançadas disponíveis:${NC}"
    echo "1) Padrão (deskew + clean)"
    echo "2) Alta qualidade (lento)"
    echo "3) Para arquivos escaneados"
    echo "4) Personalizado"
    read -p "Escolha o perfil [1]: " profile
    profile=${profile:-1}
    
    local options=(--language por)
    case $profile in
        1) options+=(--deskew --clean) ;;
        2) options+=(--deskew --clean --oversample 600 --remove-background) ;;
        3) options+=(--deskew --clean --remove-background --threshold) ;;
        4)
            read -p "Opções adicionais (ex: --deskew --clean): " custom
            read -ra extra <<< "$custom"
            options+=("${extra[@]}")
            ;;
    esac

    echo -e "${YELLOW}Processando OCR avançado...${NC}"
    ocrmypdf "${options[@]}" "$SELECTED_FILE" "$output"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ OCR avançado concluído: $output${NC}"
        log_operation "OCR avançado" "$SELECTED_FILE" "$output"
    else
        echo -e "${RED}❌ Erro no OCR${NC}"
    fi
    
    read -p "Pressione ENTER para continuar"
}

ocr_force() {
    select_pdf_file || return

    if ! command -v ocrmypdf &>/dev/null; then
        echo -e "${RED}❌ ocrmypdf não encontrado. Execute o instalador.${NC}"
        read -p "Pressione ENTER para continuar"
        return
    fi

    local output_name="${SELECTED_FILE%.*}_ocr_forcado.pdf"
    read -p "Nome do arquivo de saída [$output_name]: " output
    output=${output:-$output_name}
    
    echo -e "${YELLOW}Forçando OCR mesmo com texto existente...${NC}"
    ocrmypdf --force-ocr --language por "$SELECTED_FILE" "$output"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ OCR forçado concluído${NC}"
    else
        echo -e "${RED}❌ Erro no OCR${NC}"
    fi
    
    read -p "Pressione ENTER para continuar"
}

ocr_batch() {
    echo -e "\n${CYAN}📁 Diretório atual: $(pwd)${NC}"

    if ! command -v ocrmypdf &>/dev/null; then
        echo -e "${RED}❌ ocrmypdf não encontrado. Execute o instalador.${NC}"
        read -p "Pressione ENTER para continuar"
        return
    fi

    local pattern="*.pdf"
    read -p "Padrão de arquivos [*.pdf]: " input_pattern
    pattern=${input_pattern:-$pattern}
    
    local files=($pattern)
    if [ ${#files[@]} -eq 0 ]; then
        echo -e "${RED}Nenhum arquivo encontrado${NC}"
        read -p "Pressione ENTER para continuar"
        return
    fi
    
    echo -e "\n${YELLOW}Arquivos encontrados:${NC}"
    for f in "${files[@]}"; do
        echo "  - $f"
    done
    
    read -p "Processar todos? (s/N): " confirm
    if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
        return
    fi
    
    local output_dir="ocr_batch_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$output_dir"
    
    local count=0
    local total=${#files[@]}
    
    for file in "${files[@]}"; do
        count=$((count + 1))
        echo -e "\n${CYAN}[$count/$total] Processando: $file${NC}"
        
        local output="$output_dir/${file%.*}_ocr.pdf"
        ocrmypdf --language por "$file" "$output"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}  ✅ OK${NC}"
        else
            echo -e "${RED}  ❌ Erro${NC}"
        fi
    done
    
    echo -e "\n${GREEN}✅ Processamento em lote concluído! Arquivos salvos em: $output_dir${NC}"
    read -p "Pressione ENTER para continuar"
}

extract_text_simple() {
    select_pdf_file || return
    
    local output_name="${SELECTED_FILE%.*}.txt"
    read -p "Nome do arquivo TXT [$output_name]: " output
    output=${output:-$output_name}
    
    echo -e "${YELLOW}Extraindo texto...${NC}"
    pdftotext "$SELECTED_FILE" "$output"
    
    if [ $? -eq 0 ]; then
        local lines=$(wc -l < "$output")
        local words=$(wc -w < "$output")
        echo -e "${GREEN}✅ Texto extraído: $output${NC}"
        echo -e "${CYAN}📊 Linhas: $lines | Palavras: $words${NC}"
        
        read -p "Visualizar texto? (s/N): " view
        if [[ "$view" =~ ^[Ss]$ ]]; then
            less "$output"
        fi
    else
        echo -e "${RED}❌ Erro na extração${NC}"
    fi
    
    read -p "Pressione ENTER para continuar"
}

extract_text_formatted() {
    select_pdf_file || return
    
    local output_name="${SELECTED_FILE%.*}_formatado.txt"
    read -p "Nome do arquivo [$output_name]: " output
    output=${output:-$output_name}
    
    echo -e "${CYAN}Opções de formatação:${NC}"
    echo "1) Preservar layout (colunas, tabelas)"
    echo "2) Layout simples (fluxo contínuo)"
    echo "3) Com quebras de página"
    echo "4) Raw (sem formatação)"
    read -p "Escolha [1]: " fmt
    fmt=${fmt:-1}
    
    local options=""
    case $fmt in
        1) options="-layout" ;;
        2) options="" ;;
        3) options="-layout -nopgbrk" ;;
        4) options="-raw" ;;
    esac
    
    pdftotext $options "$SELECTED_FILE" "$output"
    
    echo -e "${GREEN}✅ Texto extraído com formatação${NC}"
    read -p "Pressione ENTER para continuar"
}

check_text() {
    select_pdf_file || return
    
    echo -e "${CYAN}Verificando camada de texto...${NC}"
    
    # Extrair primeiras linhas para teste
    local temp_txt="/tmp/pdf_text_check.txt"
    pdftotext "$SELECTED_FILE" "$temp_txt" 2>/dev/null
    
    if [ -s "$temp_txt" ]; then
        local lines=$(wc -l < "$temp_txt")
        local words=$(wc -w < "$temp_txt")
        
        if [ $words -gt 10 ]; then
            echo -e "${GREEN}✅ PDF possui camada de texto${NC}"
            echo -e "${CYAN}📊 Amostra:${NC}"
            head -5 "$temp_txt"
            echo -e "${CYAN}...${NC}"
            echo -e "${CYAN}Total: $lines linhas, $words palavras${NC}"
        else
            echo -e "${YELLOW}⚠️  PDF tem muito pouco texto (pode ser apenas OCR antigo ou imagem)${NC}"
        fi
    else
        echo -e "${RED}❌ PDF não possui camada de texto detectável${NC}"
        echo -e "${YELLOW}Recomendação: Aplicar OCR básico${NC}"
    fi
    
    rm -f "$temp_txt"
    read -p "Pressione ENTER para continuar"
}

ocr_languages() {
    while true; do
        clear
        echo -e "${CYAN}🌐 Configuração de Idiomas do OCR${NC}\n"
        echo "Idiomas disponíveis:"
        echo ""
        
        # Verificar idiomas instalados
        local langs=$(tesseract --list-langs 2>/dev/null | tail -n +2)
        
        local i=1
        declare -A lang_options
        for lang in $langs; do
            case $lang in
                por) echo "  $i) 🇧🇷 Português [INSTALADO]" ;;
                eng) echo "  $i) 🇺🇸 Inglês [INSTALADO]" ;;
                spa) echo "  $i) 🇪🇸 Espanhol [INSTALADO]" ;;
                fra) echo "  $i) 🇫🇷 Francês [INSTALADO]" ;;
                deu) echo "  $i) 🇩🇪 Alemão [INSTALADO]" ;;
                ita) echo "  $i) 🇮🇹 Italiano [INSTALADO]" ;;
                *) echo "  $i) $lang [INSTALADO]" ;;
            esac
            lang_options[$i]=$lang
            i=$((i+1))
        done
        
        echo ""
        echo "  i) Instalar novo idioma"
        echo "  v) Voltar"
        echo ""
        
        read -p "Escolha idioma padrão [por]: " choice
        
        case $choice in
            [0-9]*)
                if [ -n "${lang_options[$choice]}" ]; then
                    local selected="${lang_options[$choice]}"
                    sed -i "s/^LANGUAGE=.*/LANGUAGE=$selected/" "$CONFIG_DIR/settings.conf"
                    echo -e "${GREEN}✅ Idioma padrão alterado para: $selected${NC}"
                fi
                ;;
            i|I)
                install_ocr_language
                ;;
            v|V)
                return
                ;;
            *)
                echo -e "${YELLOW}Mantendo idioma atual${NC}"
                return
                ;;
        esac
    done
}

install_ocr_language() {
    echo -e "\n${CYAN}📥 Instalar novo idioma Tesseract${NC}"
    read -p "Código do idioma (ex: rus, ara, chi_sim): " lang_code
    
    if [ -n "$lang_code" ]; then
        echo -e "${YELLOW}Instalando $lang_code...${NC}"
        
        case $PKG_MANAGER in
            dnf)
                sudo dnf install -y "tesseract-langpack-$lang_code" 2>/dev/null
                ;;
            apt)
                sudo apt install -y "tesseract-ocr-$lang_code" 2>/dev/null
                ;;
            pacman)
                sudo pacman -S --noconfirm "tesseract-data-$lang_code" 2>/dev/null
                ;;
        esac
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Idioma instalado!${NC}"
        else
            echo -e "${RED}❌ Falha na instalação. Verifique o código do idioma.${NC}"
        fi
    fi
    
    read -p "Pressione ENTER para continuar"
}

view_extracted_text() {
    select_pdf_file || return
    
    echo -e "${CYAN}🔍 Extraindo texto para visualização...${NC}"
    
    local temp_view="/tmp/pdf_text_view.txt"
    pdftotext -layout "$SELECTED_FILE" "$temp_view"
    
    if [ -s "$temp_view" ]; then
        clear
        echo -e "${BLUE}════════════════════════ TEXT EXTRAÍDO ════════════════════════${NC}"
        cat "$temp_view"
        echo -e "${BLUE}════════════════════════ FIM DO TEXTO ═════════════════════════${NC}"
    else
        echo -e "${RED}Nenhum texto encontrado${NC}"
    fi
    
    rm -f "$temp_view"
    read -p "Pressione ENTER para continuar"
}

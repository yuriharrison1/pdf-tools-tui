#!/bin/bash

# Módulo de Conversões - Suporte a múltiplos formatos
# Gerencia conversões entre PDF e outros formatos

convert_menu() {
    while true; do
        clear
        echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║              🔄 Conversões de PDF                      ║${NC}"
        echo -e "${GREEN}╠════════════════════════════════════════════════════════╣${NC}"
        echo -e "${GREEN}║${NC}  📤 CONVERTER PDF PARA:"
        echo -e "${GREEN}║${NC}  ${YELLOW}1)${NC} 📝 TXT - Texto puro"
        echo -e "${GREEN}║${NC}  ${YELLOW}2)${NC} 📘 DOCX - Microsoft Word"
        echo -e "${GREEN}║${NC}  ${YELLOW}3)${NC} 📗 ODT - LibreOffice"
        echo -e "${GREEN}║${NC}  ${YELLOW}4)${NC} 🌐 HTML - Página web"
        echo -e "${GREEN}║${NC}  ${YELLOW}5)${NC} 📊 CSV/Excel - Tabelas"
        echo -e "${GREEN}║${NC}  ${YELLOW}6)${NC} 🖼️  Imagens (PNG/JPEG)"
        echo -e "${GREEN}║${NC}  ${YELLOW}7)${NC} 📑 PDF/A - Arquivamento"
        echo -e "${GREEN}║${NC}  ${YELLOW}8)${NC} 📱 EPUB - E-book"
        echo -e "${GREEN}║${NC}  ${YELLOW}9)${NC} 📄 Markdown"
        echo -e "${GREEN}║${NC}  ──────────────────────────────────────────────"
        echo -e "${GREEN}║${NC}  📥 CONVERTER PARA PDF:"
        echo -e "${GREEN}║${NC}  ${YELLOW}10)${NC} 🖼️  Imagens → PDF"
        echo -e "${GREEN}║${NC}  ${YELLOW}11)${NC} 📝 Texto → PDF"
        echo -e "${GREEN}║${NC}  ${YELLOW}12)${NC} 📘 DOCX → PDF"
        echo -e "${GREEN}║${NC}  ${YELLOW}13)${NC} 🌐 HTML → PDF"
        echo -e "${GREEN}║${NC}  ${YELLOW}14)${NC} 📊 CSV → PDF (tabela)"
        echo -e "${GREEN}║${NC}  ${YELLOW}15)${NC} 📑 Múltiplos PDFs → Um PDF"
        echo -e "${GREEN}║${NC}  ──────────────────────────────────────────────"
        echo -e "${GREEN}║${NC}  ${YELLOW}16)${NC} 🔧 Conversões avançadas"
        echo -e "${GREEN}║${NC}  ${YELLOW}0)${NC} Voltar"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
        echo ""
        read -p "Escolha uma opção: " opt
        
        case $opt in
            1) convert_pdf_to_txt ;;
            2) convert_pdf_to_docx ;;
            3) convert_pdf_to_odt ;;
            4) convert_pdf_to_html ;;
            5) convert_pdf_to_csv ;;
            6) convert_pdf_to_images ;;
            7) convert_to_pdfa ;;
            8) convert_pdf_to_epub ;;
            9) convert_pdf_to_md ;;
            10) convert_images_to_pdf ;;
            11) convert_text_to_pdf ;;
            12) convert_docx_to_pdf ;;
            13) convert_html_to_pdf ;;
            14) convert_csv_to_pdf ;;
            15) merge_pdfs ;;
            16) convert_advanced ;;
            0) return ;;
            *) echo -e "${RED}Opção inválida${NC}"; sleep 2 ;;
        esac
    done
}

convert_pdf_to_txt() {
    select_pdf_file || return
    
    local output_name="${SELECTED_FILE%.*}.txt"
    read -p "Nome do arquivo TXT [$output_name]: " output
    output=${output:-$output_name}
    
    echo -e "${CYAN}Opções de extração:${NC}"
    echo "1) Texto simples"
    echo "2) Preservar layout"
    echo "3) Modo raw (sem formatação)"
    read -p "Escolha [1]: " mode
    mode=${mode:-1}
    
    local options=()
    case $mode in
        2) options+=(-layout) ;;
        3) options+=(-raw) ;;
    esac

    pdftotext "${options[@]}" "$SELECTED_FILE" "$output"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Convertido: $output${NC}"
        wc -l "$output"
    else
        echo -e "${RED}❌ Erro na conversão${NC}"
    fi
    
    read -p "Pressione ENTER para continuar"
}

convert_pdf_to_docx() {
    select_pdf_file || return
    
    local output_name="${SELECTED_FILE%.*}.docx"
    read -p "Nome do arquivo DOCX [$output_name]: " output
    output=${output:-$output_name}
    
    echo -e "${YELLOW}Convertendo PDF para DOCX...${NC}"
    
    # Tentar com pandoc primeiro
    if command -v pandoc &> /dev/null; then
        pandoc "$SELECTED_FILE" -o "$output"
    # Fallback para libreoffice
    elif command -v libreoffice &> /dev/null; then
        libreoffice --headless --convert-to docx "$SELECTED_FILE" --outdir "$(dirname "$output")"
    else
        echo -e "${RED}❌ Nenhum conversor disponível (pandoc ou libreoffice)${NC}"
        read -p "Pressione ENTER para continuar"
        return
    fi
    
    if [ -f "$output" ]; then
        echo -e "${GREEN}✅ Convertido: $output${NC}"
    else
        echo -e "${RED}❌ Erro na conversão${NC}"
    fi
    
    read -p "Pressione ENTER para continuar"
}

convert_pdf_to_odt() {
    select_pdf_file || return

    if ! command -v libreoffice &>/dev/null; then
        echo -e "${RED}❌ libreoffice não encontrado.${NC}"
        read -p "Pressione ENTER para continuar"
        return
    fi

    local output_name="${SELECTED_FILE%.*}.odt"
    read -p "Nome do arquivo ODT [$output_name]: " output
    output=${output:-$output_name}

    local out_dir
    out_dir="$(dirname "$output")"
    [ -z "$out_dir" ] && out_dir="."

    libreoffice --headless --convert-to odt "$SELECTED_FILE" --outdir "$out_dir" 2>/dev/null
    local lo_generated="$out_dir/$(basename "${SELECTED_FILE%.*}").odt"
    [ -f "$lo_generated" ] && [ "$lo_generated" != "$output" ] && mv "$lo_generated" "$output"

    if [ -f "$output" ]; then
        echo -e "${GREEN}✅ Convertido: $output${NC}"
        log_operation "PDF→ODT" "$SELECTED_FILE" "$output"
    else
        echo -e "${RED}❌ Erro na conversão${NC}"
    fi

    read -p "Pressione ENTER para continuar"
}

convert_pdf_to_html() {
    select_pdf_file || return
    
    local output_name="${SELECTED_FILE%.*}.html"
    read -p "Nome do arquivo HTML [$output_name]: " output
    output=${output:-$output_name}
    
    echo -e "${CYAN}Opções:${NC}"
    echo "1) HTML simples (pdftohtml)"
    echo "2) HTML com imagens (pdf2htmlEX)"
    echo "3) HTML complexo (pandoc)"
    read -p "Escolha [1]: " mode
    mode=${mode:-1}
    
    case $mode in
        1)
            pdftohtml "$SELECTED_FILE" "$output"
            ;;
        2)
            if command -v pdf2htmlEX &> /dev/null; then
                pdf2htmlEX "$SELECTED_FILE" "$output"
            else
                echo -e "${RED}❌ pdf2htmlEX não instalado${NC}"
                read -p "Pressione ENTER para continuar"
                return
            fi
            ;;
        3)
            pandoc "$SELECTED_FILE" -o "$output"
            ;;
    esac

    if [ -f "$output" ]; then
        echo -e "${GREEN}✅ HTML gerado: $output${NC}"
        log_operation "PDF→HTML" "$SELECTED_FILE" "$output"
    else
        echo -e "${RED}❌ Erro na conversão para HTML${NC}"
    fi

    read -p "Pressione ENTER para continuar"
}

convert_pdf_to_csv() {
    select_pdf_file || return
    
    local output_name="${SELECTED_FILE%.*}.csv"
    read -p "Nome do arquivo CSV [$output_name]: " output
    output=${output:-$output_name}
    
    echo -e "${YELLOW}Extraindo tabelas para CSV...${NC}"
    
    # Tentar tabula primeiro
    if command -v tabula &> /dev/null; then
        tabula -o "$output" "$SELECTED_FILE"
    elif python3 -c "import tabula" 2>/dev/null; then
        python3 -c "
import tabula
tabula.convert_into('$SELECTED_FILE', '$output', output_format='csv', pages='all')
"
    else
        echo -e "${RED}❌ tabula-py não instalado${NC}"
        echo "Instale com: pip install tabula-py"
    fi
    
    if [ -f "$output" ]; then
        echo -e "${GREEN}✅ CSV gerado: $output${NC}"
    fi
    
    read -p "Pressione ENTER para continuar"
}

convert_pdf_to_images() {
    select_pdf_file || return
    
    local base_name="${SELECTED_FILE%.*}"
    local output_prefix="$base_name"
    read -p "Prefixo das imagens [$base_name]: " prefix
    prefix=${prefix:-$base_name}
    
    echo -e "${CYAN}Formato:${NC}"
    echo "1) PNG"
    echo "2) JPEG"
    echo "3) TIFF"
    read -p "Escolha [1]: " fmt
    fmt=${fmt:-1}
    
    case $fmt in
        1) format="png"; pdftoppm -png "$SELECTED_FILE" "$prefix" ;;
        2) format="jpg"; pdftoppm -jpeg "$SELECTED_FILE" "$prefix" ;;
        3) format="tiff"; pdfimages -tiff "$SELECTED_FILE" "$prefix" ;;
    esac
    
    echo -e "${GREEN}✅ Imagens geradas com prefixo: $prefix${NC}"
    ls -lh "$prefix"*."$format" 2>/dev/null || ls -lh "$prefix"* 2>/dev/null
    
    read -p "Pressione ENTER para continuar"
}

convert_images_to_pdf() {
    # Coletar imagens disponíveis sem redirecionamento no select (sintaxe inválida)
    local all_images=()
    for ext in jpg jpeg png tiff bmp; do
        for f in *.$ext; do
            [ -f "$f" ] && all_images+=("$f")
        done
    done

    if [ ${#all_images[@]} -eq 0 ]; then
        echo -e "${RED}Nenhuma imagem encontrada (jpg, png, tiff, bmp)${NC}"
        read -p "Pressione ENTER para continuar"
        return
    fi

    echo -e "${CYAN}🖼️  Selecione as imagens (escolha '-- Pronto --' para encerrar):${NC}"
    local images=()
    select img in "${all_images[@]}" "-- Pronto --"; do
        if [ "$img" = "-- Pronto --" ] || [ -z "$img" ]; then
            break
        fi
        images+=("$img")
        echo "Adicionado: $img"
    done

    if [ ${#images[@]} -eq 0 ]; then
        echo -e "${RED}Nenhuma imagem selecionada${NC}"
        read -p "Pressione ENTER para continuar"
        return
    fi

    read -p "Nome do PDF de saída [imagens.pdf]: " output
    output=${output:-imagens.pdf}

    # Detectar ImageMagick v7+ (magick) ou v6 (convert)
    local im_cmd=""
    if command -v magick &>/dev/null; then
        im_cmd="magick"
    elif command -v convert &>/dev/null; then
        im_cmd="convert"
    fi

    if [ -n "$im_cmd" ]; then
        $im_cmd "${images[@]}" "$output"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ PDF criado: $output${NC}"
        else
            echo -e "${RED}❌ Erro na criação${NC}"
        fi
    else
        echo -e "${RED}❌ ImageMagick não encontrado (instale imagemagick)${NC}"
    fi

    read -p "Pressione ENTER para continuar"
}

convert_text_to_pdf() {
    echo -e "${CYAN}📝 Arquivos de texto disponíveis:${NC}"
    select txt in *.txt; do
        if [ -n "$txt" ]; then
            break
        fi
    done
    
    local output_name="${txt%.*}.pdf"
    read -p "Nome do PDF de saída [$output_name]: " output
    output=${output:-$output_name}
    
    # Usar pandoc ou enscript
    if command -v pandoc &> /dev/null; then
        pandoc "$txt" -o "$output"
    else
        enscript -B "$txt" -o - | ps2pdf - "$output"
    fi
    
    echo -e "${GREEN}✅ PDF gerado: $output${NC}"
    read -p "Pressione ENTER para continuar"
}

convert_docx_to_pdf() {
    echo -e "${CYAN}📘 Arquivos DOCX disponíveis:${NC}"

    local docxs=()
    for f in *.docx; do [ -f "$f" ] && docxs+=("$f"); done

    if [ ${#docxs[@]} -eq 0 ]; then
        echo -e "${RED}Nenhum arquivo DOCX encontrado${NC}"
        read -p "Pressione ENTER para continuar"
        return
    fi

    local i=1
    for docx in "${docxs[@]}"; do echo "  $i) $docx"; ((i++)); done
    echo ""

    read -p "Escolha o número: " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le ${#docxs[@]} ]; then
        local docx_file="${docxs[$((choice-1))]}"
        local output_name="${docx_file%.*}.pdf"

        read -p "Nome do PDF de saída [$output_name]: " output
        output=${output:-$output_name}

        echo -e "${YELLOW}Convertendo DOCX para PDF...${NC}"

        if command -v libreoffice &> /dev/null; then
            local out_dir
            out_dir="$(dirname "$output")"
            [ -z "$out_dir" ] && out_dir="."
            libreoffice --headless --convert-to pdf "$docx_file" --outdir "$out_dir" 2>/dev/null
            local lo_generated="$out_dir/$(basename "${docx_file%.*}").pdf"
            [ -f "$lo_generated" ] && [ "$lo_generated" != "$output" ] && mv "$lo_generated" "$output"
            if [ -f "$output" ]; then
                echo -e "${GREEN}✅ PDF gerado: $output${NC}"
                log_operation "DOCX→PDF" "$docx_file" "$output"
            else
                echo -e "${RED}❌ Erro na conversão${NC}"
            fi
        elif command -v pandoc &> /dev/null; then
            pandoc "$docx_file" -o "$output"
            echo -e "${GREEN}✅ PDF gerado: $output${NC}"
        else
            echo -e "${RED}❌ Nenhum conversor disponível (libreoffice ou pandoc)${NC}"
        fi
    fi

    read -p "Pressione ENTER para continuar"
}

convert_html_to_pdf() {
    read -p "URL do HTML ou caminho do arquivo: " source
    
    local output_name="pagina.pdf"
    read -p "Nome do PDF de saída [$output_name]: " output
    output=${output:-$output_name}
    
    if [[ "$source" =~ ^https?:// ]]; then
        wkhtmltopdf "$source" "$output"
    else
        pandoc "$source" -o "$output"
    fi
    
    echo -e "${GREEN}✅ PDF gerado: $output${NC}"
    read -p "Pressione ENTER para continuar"
}

convert_csv_to_pdf() {
    echo -e "${CYAN}📊 Arquivos CSV disponíveis:${NC}"
    select csv in *.csv; do
        if [ -n "$csv" ]; then
            break
        fi
    done
    
    local output_name="${csv%.*}.pdf"
    read -p "Nome do PDF de saída [$output_name]: " output
    output=${output:-$output_name}
    
    # Criar HTML temporário com tabela
    local temp_html="/tmp/csv_table.html"
    echo "<html><body><table border='1'>" > "$temp_html"
    
    # Converter CSV para HTML (simples)
    while IFS=',' read -r line; do
        echo "<tr>" >> "$temp_html"
        echo "$line" | sed 's/,/<\/td><td>/g' | sed 's/^/<td>/' | sed 's/$/<\/td>/' >> "$temp_html"
        echo "</tr>" >> "$temp_html"
    done < "$csv"
    
    echo "</table></body></html>" >> "$temp_html"
    
    # Converter HTML para PDF
    wkhtmltopdf "$temp_html" "$output"
    
    rm -f "$temp_html"
    
    echo -e "${GREEN}✅ PDF gerado: $output${NC}"
    read -p "Pressione ENTER para continuar"
}

merge_pdfs() {
    echo -e "${CYAN}📑 PDFs disponíveis para mesclar:${NC}"

    local pdfs=()
    for f in *.pdf; do [ -f "$f" ] && pdfs+=("$f"); done

    if [ ${#pdfs[@]} -lt 2 ]; then
        echo -e "${RED}Precisa de pelo menos 2 PDFs para mesclar${NC}"
        read -p "Pressione ENTER para continuar"
        return
    fi

    local i=1
    for pdf in "${pdfs[@]}"; do echo "  $i) $pdf"; ((i++)); done
    echo ""

    read -p "Números dos PDFs para mesclar (ex: 1 2 3): " pdf_nums

    local selected=()
    for num in $pdf_nums; do
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#pdfs[@]} ]; then
            selected+=("${pdfs[$((num-1))]}")
        fi
    done

    if [ ${#selected[@]} -lt 2 ]; then
        echo -e "${RED}Selecione pelo menos 2 PDFs válidos${NC}"
        read -p "Pressione ENTER para continuar"
        return
    fi

    read -p "Nome do PDF mesclado [merged.pdf]: " output
    output=${output:-merged.pdf}

    echo -e "${YELLOW}Mesclando PDFs...${NC}"

    if command -v gs &> /dev/null; then
        gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile="$output" "${selected[@]}"
        echo -e "${GREEN}✅ PDFs mesclados: $output${NC}"
        log_operation "Mesclar PDFs" "${selected[*]}" "$output"
    elif command -v pdfunite &> /dev/null; then
        pdfunite "${selected[@]}" "$output"
        echo -e "${GREEN}✅ PDFs mesclados: $output${NC}"
    else
        echo -e "${RED}❌ Nenhuma ferramenta disponível (gs ou pdfunite)${NC}"
    fi

    read -p "Pressione ENTER para continuar"
}

convert_advanced() {
    echo -e "\n${CYAN}🔧 Conversões avançadas${NC}"
    echo "1) PDF para PDF/A (arquivamento)"
    echo "2) PDF para PDF pesquisável (imagem + texto)"
    echo "3) Extrair páginas"
    echo "4) Rotacionar páginas"
    echo "5) Adicionar senha"
    echo "6) Remover senha"
    echo "7) Comprimir PDF"
    echo "0) Voltar"
    
    read -p "Escolha: " adv
    
    case $adv in
        1) convert_to_pdfa ;;
        2) ocr_basic ;;  # Reutiliza função do módulo OCR
        3) extract_pages ;;
        4) rotate_pdf ;;
        5) encrypt_pdf ;;
        6) decrypt_pdf ;;
        7) compress_pdf ;;
        0) return ;;
    esac
}

extract_pages() {
    select_pdf_file || return
    
    local output_name="${SELECTED_FILE%.*}_paginas.pdf"
    read -p "Intervalo de páginas (ex: 1-5, 7, 9-12): " pages
    read -p "Nome do arquivo de saída [$output_name]: " output
    output=${output:-$output_name}
    
    pdftk "$SELECTED_FILE" cat $pages output "$output"
    
    echo -e "${GREEN}✅ Páginas extraídas: $output${NC}"
    read -p "Pressione ENTER para continuar"
}

rotate_pdf() {
    select_pdf_file || return
    
    echo -e "${CYAN}Opções de rotação:${NC}"
    echo "1) 90° horário"
    echo "2) 90° anti-horário"
    echo "3) 180°"
    read -p "Escolha: " rot
    
    local direction
    case $rot in
        1) direction="1-endeast" ;;
        2) direction="1-endwest" ;;
        3) direction="1-endsouth" ;;
        *) echo "Opção inválida"; return ;;
    esac
    
    local output_name="${SELECTED_FILE%.*}_rotacionado.pdf"
    read -p "Nome do arquivo de saída [$output_name]: " output
    output=${output:-$output_name}
    
    pdftk "$SELECTED_FILE" cat $direction output "$output"
    
    echo -e "${GREEN}✅ PDF rotacionado: $output${NC}"
    read -p "Pressione ENTER para continuar"
}

encrypt_pdf() {
    select_pdf_file || return
    
    local output_name="${SELECTED_FILE%.*}_protegido.pdf"
    read -p "Nome do arquivo de saída [$output_name]: " output
    output=${output:-$output_name}
    
    read -sp "Senha: " password
    echo ""
    read -sp "Confirme a senha: " password2
    echo ""
    
    if [ "$password" != "$password2" ]; then
        echo -e "${RED}Senhas não conferem${NC}"
        read -p "Pressione ENTER para continuar"
        return
    fi
    
    pdftk "$SELECTED_FILE" output "$output" user_pw "$password"
    
    echo -e "${GREEN}✅ PDF protegido: $output${NC}"
    read -p "Pressione ENTER para continuar"
}

decrypt_pdf() {
    select_pdf_file || return
    
    local output_name="${SELECTED_FILE%.*}_sem_senha.pdf"
    read -p "Nome do arquivo de saída [$output_name]: " output
    output=${output:-$output_name}
    
    read -sp "Senha: " password
    echo ""
    
    pdftk "$SELECTED_FILE" input_pw "$password" output "$output"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ PDF descriptografado: $output${NC}"
    else
        echo -e "${RED}❌ Senha incorreta${NC}"
    fi
    
    read -p "Pressione ENTER para continuar"
}

compress_pdf() {
    select_pdf_file || return
    
    local output_name="${SELECTED_FILE%.*}_comprimido.pdf"
    read -p "Nome do arquivo de saída [$output_name]: " output
    output=${output:-$output_name}
    
    echo -e "${CYAN}Nível de compressão:${NC}"
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
    
    if command -v gs &> /dev/null; then
        local original_size
        original_size=$(du -h "$SELECTED_FILE" | cut -f1)

        gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 "-dPDFSETTINGS=$quality" \
           -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$output" "$SELECTED_FILE" 2>/dev/null

        if [ $? -eq 0 ] && [ -f "$output" ]; then
            local new_size
            new_size=$(du -h "$output" | cut -f1)
            echo -e "${GREEN}✅ PDF comprimido: $output${NC}"
            echo -e "${CYAN}📊 Tamanho original: $original_size → Novo: $new_size${NC}"
        else
            echo -e "${RED}❌ Erro na compressão${NC}"
        fi
    else
        echo -e "${RED}❌ gs (Ghostscript) não encontrado${NC}"
    fi

    read -p "Pressione ENTER para continuar"
}

convert_to_pdfa() {
    select_pdf_file || return
    
    local output_name="${SELECTED_FILE%.*}_pdfa.pdf"
    read -p "Nome do arquivo de saída [$output_name]: " output
    output=${output:-$output_name}
    
    gs -dPDFA -dBATCH -dNOPAUSE -dNOOUTERSAVE -dUseCIEColor \
       -sProcessColorModel=DeviceRGB -sDEVICE=pdfwrite \
       -sOutputFile="$output" "$SELECTED_FILE"
    
    echo -e "${GREEN}✅ PDF/A gerado: $output${NC}"
    read -p "Pressione ENTER para continuar"
}

convert_pdf_to_epub() {
    select_pdf_file || return
    
    local output_name="${SELECTED_FILE%.*}.epub"
    read -p "Nome do arquivo EPUB [$output_name]: " output
    output=${output:-$output_name}
    
    pandoc "$SELECTED_FILE" -o "$output"
    
    echo -e "${GREEN}✅ EPUB gerado: $output${NC}"
    read -p "Pressione ENTER para continuar"
}

convert_pdf_to_md() {
    select_pdf_file || return
    
    local output_name="${SELECTED_FILE%.*}.md"
    read -p "Nome do arquivo Markdown [$output_name]: " output
    output=${output:-$output_name}
    
    pandoc "$SELECTED_FILE" -t markdown -o "$output"
    
    echo -e "${GREEN}✅ Markdown gerado: $output${NC}"
    read -p "Pressione ENTER para continuar"
}

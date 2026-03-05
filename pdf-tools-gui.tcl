#!/usr/bin/wish

# PDF Tools GUI - Interface Gráfica para Ferramentas de PDF
# Desenvolvido em Tcl/Tk puro
# Versão: 1.1

# Configurações iniciais
package require Tk
wm title . "PDF Tools GUI v1.1"
wm geometry . 900x700
wm resizable . 1 1

# Cores e estilos
set bg_color "#f0f0f0"
set fg_color "#333333"
set accent_color "#4CAF50"
set error_color "#f44336"
set warning_color "#ff9800"

# Configurar cores de fundo
. configure -bg $bg_color

# Variáveis globais
set current_file ""
set operation_running 0
set progress_value 0
set log_messages ""
set selected_files [list]
set output_format "pdf"
set ocr_language "por"
set opt_deskew 1
set opt_clean 1
set opt_force_ocr 0
set opt_remove_background 0
set convert_type "pdf_to_txt"
set quality_var "medium"
set preserve_layout 1
set form_action "detect"
set utils_action "info"

# Frame principal
frame .main -bg $bg_color
pack .main -fill both -expand 1 -padx 10 -pady 10

# ========== CABEÇALHO ==========
frame .header -bg $accent_color -height 60
pack .header -fill x -side top

label .header.title -text "📄 PDF Tools GUI" \
    -font {Helvetica 24 bold} \
    -fg white -bg $accent_color
pack .header.title -pady 10

# ========== ÁREA DE ARQUIVOS ==========
labelframe .files -text "📁 Arquivos" \
    -bg $bg_color -fg $fg_color \
    -font {Helvetica 12 bold} -padx 10 -pady 10
pack .files -fill x -pady 10

frame .files.buttons
pack .files.buttons -fill x

button .files.buttons.select -text "Selecionar PDF" \
    -command select_files \
    -bg $accent_color -fg white \
    -font {Helvetica 10} -padx 15 -pady 5
pack .files.buttons.select -side left -padx 5

button .files.buttons.clear -text "Limpar Seleção" \
    -command clear_files \
    -bg $warning_color -fg white \
    -font {Helvetica 10} -padx 15 -pady 5
pack .files.buttons.clear -side left -padx 5

label .files.count -text "Nenhum arquivo selecionado" \
    -bg $bg_color -fg $fg_color
pack .files.count -side left -padx 20

# Lista de arquivos selecionados
listbox .files.list -height 5 \
    -bg white -fg $fg_color \
    -selectmode extended \
    -font {Courier 10}
pack .files.list -fill x -pady 5

# ========== ABAS DE OPERAÇÕES ==========
set nb [ttk::notebook .notebook]
pack $nb -fill both -expand 1 -pady 10

# Aba OCR
set ocr_tab [frame $nb.ocr -bg $bg_color]
$nb add $ocr_tab -text "📋 OCR"

# Aba Conversões
set convert_tab [frame $nb.convert -bg $bg_color]
$nb add $convert_tab -text "🔄 Conversões"

# Aba Formulários
set forms_tab [frame $nb.forms -bg $bg_color]
$nb add $forms_tab -text "🔍 Formulários"

# Aba Utilitários
set utils_tab [frame $nb.utils -bg $bg_color]
$nb add $utils_tab -text "🔧 Utilitários"

# ========== ABA OCR ==========
frame $ocr_tab.controls -bg $bg_color
pack $ocr_tab.controls -fill both -expand 1 -padx 10 -pady 10

# Opções de OCR
labelframe $ocr_tab.controls.options -text "Opções de OCR" \
    -bg $bg_color -fg $fg_color
pack $ocr_tab.controls.options -fill x -pady 5

# Idioma
frame $ocr_tab.controls.options.lang
pack $ocr_tab.controls.options.lang -fill x -pady 5

label $ocr_tab.controls.options.lang.label -text "Idioma:" \
    -bg $bg_color -fg $fg_color
pack $ocr_tab.controls.options.lang.label -side left -padx 5

ttk::combobox $ocr_tab.controls.options.lang.combo \
    -textvariable ocr_language \
    -values {"por" "eng" "spa" "fra" "deu"} \
    -state readonly
pack $ocr_tab.controls.options.lang.combo -side left -padx 5

# Checkbuttons para opções
checkbutton $ocr_tab.controls.options.deskew \
    -text "Corrigir inclinação (deskew)" \
    -variable opt_deskew \
    -bg $bg_color -fg $fg_color \
    -activebackground $bg_color
pack $ocr_tab.controls.options.deskew -anchor w -pady 2

checkbutton $ocr_tab.controls.options.clean \
    -text "Limpar ruídos (clean)" \
    -variable opt_clean \
    -bg $bg_color -fg $fg_color \
    -activebackground $bg_color
pack $ocr_tab.controls.options.clean -anchor w -pady 2

checkbutton $ocr_tab.controls.options.force \
    -text "Forçar OCR (sobrescrever texto)" \
    -variable opt_force_ocr \
    -bg $bg_color -fg $fg_color \
    -activebackground $bg_color
pack $ocr_tab.controls.options.force -anchor w -pady 2

checkbutton $ocr_tab.controls.options.remove_bg \
    -text "Remover fundo" \
    -variable opt_remove_background \
    -bg $bg_color -fg $fg_color \
    -activebackground $bg_color
pack $ocr_tab.controls.options.remove_bg -anchor w -pady 2

# Botões de ação
frame $ocr_tab.controls.buttons -bg $bg_color
pack $ocr_tab.controls.buttons -fill x -pady 10

button $ocr_tab.controls.buttons.apply -text "Aplicar OCR" \
    -command {start_operation "ocr"} \
    -bg $accent_color -fg white \
    -font {Helvetica 12} -padx 20 -pady 8
pack $ocr_tab.controls.buttons.apply -side left -padx 5

button $ocr_tab.controls.buttons.preview -text "Pré-visualizar" \
    -command preview_ocr \
    -bg $warning_color -fg white \
    -font {Helvetica 10} -padx 15 -pady 5
pack $ocr_tab.controls.buttons.preview -side left -padx 5

# ========== ABA CONVERSÕES ==========
frame $convert_tab.controls -bg $bg_color
pack $convert_tab.controls -fill both -expand 1 -padx 10 -pady 10

# Tipo de conversão
labelframe $convert_tab.controls.type -text "Tipo de Conversão" \
    -bg $bg_color -fg $fg_color
pack $convert_tab.controls.type -fill x -pady 5

radiobutton $convert_tab.controls.type.pdf_txt \
    -text "PDF → TXT" \
    -variable convert_type \
    -value "pdf_to_txt" \
    -bg $bg_color -fg $fg_color
pack $convert_tab.controls.type.pdf_txt -anchor w -pady 2

radiobutton $convert_tab.controls.type.pdf_docx \
    -text "PDF → DOCX" \
    -variable convert_type \
    -value "pdf_to_docx" \
    -bg $bg_color -fg $fg_color
pack $convert_tab.controls.type.pdf_docx -anchor w -pady 2

radiobutton $convert_tab.controls.type.pdf_images \
    -text "PDF → Imagens" \
    -variable convert_type \
    -value "pdf_to_images" \
    -bg $bg_color -fg $fg_color
pack $convert_tab.controls.type.pdf_images -anchor w -pady 2

radiobutton $convert_tab.controls.type.images_pdf \
    -text "Imagens → PDF" \
    -variable convert_type \
    -value "images_to_pdf" \
    -bg $bg_color -fg $fg_color
pack $convert_tab.controls.type.images_pdf -anchor w -pady 2

# Opções de conversão
labelframe $convert_tab.controls.options -text "Opções" \
    -bg $bg_color -fg $fg_color
pack $convert_tab.controls.options -fill x -pady 5

frame $convert_tab.controls.options.quality
pack $convert_tab.controls.options.quality -fill x -pady 2

label $convert_tab.controls.options.quality.label \
    -text "Qualidade:" -bg $bg_color -fg $fg_color
pack $convert_tab.controls.options.quality.label -side left -padx 5

ttk::combobox $convert_tab.controls.options.quality.combo \
    -textvariable quality_var \
    -values {"low" "medium" "high"} \
    -state readonly
pack $convert_tab.controls.options.quality.combo -side left -padx 5

checkbutton $convert_tab.controls.options.preserve_layout \
    -text "Preservar layout" \
    -variable preserve_layout \
    -bg $bg_color -fg $fg_color
pack $convert_tab.controls.options.preserve_layout -anchor w -pady 2

button $convert_tab.controls.apply -text "Converter" \
    -command {start_operation "convert"} \
    -bg $accent_color -fg white \
    -font {Helvetica 12} -padx 20 -pady 8
pack $convert_tab.controls.apply -pady 10

# ========== ABA FORMULÁRIOS ==========
frame $forms_tab.controls -bg $bg_color
pack $forms_tab.controls -fill both -expand 1 -padx 10 -pady 10

radiobutton $forms_tab.controls.detect \
    -text "Detectar campos automaticamente" \
    -variable form_action -value "detect" \
    -bg $bg_color -fg $fg_color
pack $forms_tab.controls.detect -anchor w -pady 5

radiobutton $forms_tab.controls.signature \
    -text "Detectar campos + assinaturas" \
    -variable form_action -value "signature" \
    -bg $bg_color -fg $fg_color
pack $forms_tab.controls.signature -anchor w -pady 5

radiobutton $forms_tab.controls.extract \
    -text "Extrair campos para JSON" \
    -variable form_action -value "extract" \
    -bg $bg_color -fg $fg_color
pack $forms_tab.controls.extract -anchor w -pady 5

button $forms_tab.controls.apply -text "Processar Formulário" \
    -command {start_operation "forms"} \
    -bg $accent_color -fg white \
    -font {Helvetica 12} -padx 20 -pady 8
pack $forms_tab.controls.apply -pady 10

# ========== ABA UTILITÁRIOS ==========
frame $utils_tab.controls -bg $bg_color
pack $utils_tab.controls -fill both -expand 1 -padx 10 -pady 10

radiobutton $utils_tab.controls.info \
    -text "Informações do PDF" \
    -variable utils_action -value "info" \
    -bg $bg_color -fg $fg_color
pack $utils_tab.controls.info -anchor w -pady 5

radiobutton $utils_tab.controls.merge \
    -text "Mesclar PDFs" \
    -variable utils_action -value "merge" \
    -bg $bg_color -fg $fg_color
pack $utils_tab.controls.merge -anchor w -pady 5

radiobutton $utils_tab.controls.compress \
    -text "Comprimir PDF" \
    -variable utils_action -value "compress" \
    -bg $bg_color -fg $fg_color
pack $utils_tab.controls.compress -anchor w -pady 5

radiobutton $utils_tab.controls.extract_images \
    -text "Extrair imagens" \
    -variable utils_action -value "extract_images" \
    -bg $bg_color -fg $fg_color
pack $utils_tab.controls.extract_images -anchor w -pady 5

button $utils_tab.controls.apply -text "Executar" \
    -command {start_operation "utils"} \
    -bg $accent_color -fg white \
    -font {Helvetica 12} -padx 20 -pady 8
pack $utils_tab.controls.apply -pady 10

# ========== BARRA DE PROGRESSO ==========
labelframe .progress -text "📊 Progresso" \
    -bg $bg_color -fg $fg_color
pack .progress -fill x -pady 10

# CORREÇÃO: Usar ttk::progressbar em vez de progressbar
ttk::progressbar .progress.bar \
    -variable progress_value \
    -maximum 100 \
    -length 800
pack .progress.bar -padx 10 -pady 5

label .progress.status -text "Aguardando operação..." \
    -bg $bg_color -fg $fg_color
pack .progress.status -pady 5

# ========== ÁREA DE LOG ==========
labelframe .log -text "📝 Log de Operações" \
    -bg $bg_color -fg $fg_color
pack .log -fill both -expand 1 -pady 10

# Frame para log com scrollbar
frame .log.frame -bg $bg_color
pack .log.frame -fill both -expand 1 -padx 5 -pady 5

text .log.frame.text -height 8 \
    -bg white -fg $fg_color \
    -font {Courier 9} \
    -wrap word \
    -yscrollcommand {.log.frame.scroll set}
scrollbar .log.frame.scroll -command {.log.frame.text yview}

pack .log.frame.scroll -side right -fill y
pack .log.frame.text -side left -fill both -expand 1

# ========== RODAPÉ ==========
frame .footer -bg $bg_color
pack .footer -fill x -pady 5

button .footer.exit -text "Sair" \
    -command confirm_exit \
    -bg $error_color -fg white \
    -font {Helvetica 10} -padx 20 -pady 5
pack .footer.exit -side right -padx 5

label .footer.version -text "v1.1 | Tcl/Tk GUI" \
    -bg $bg_color -fg gray
pack .footer.version -side left -padx 5

# ========== FUNÇÕES ==========

# Selecionar arquivos
proc select_files {} {
    global selected_files
    
    set types {
        {"PDF Files" {.pdf}} 
        {"All Files" *}
    }
    
    set files [tk_getOpenFile -filetypes $types -multiple 1 \
        -title "Selecionar arquivos PDF"]
    
    if {$files ne ""} {
        set selected_files $files
        .files.list delete 0 end
        foreach file $files {
            .files.list insert end [file tail $file]
        }
        set count [llength $files]
        .files.count configure -text "$count arquivo(s) selecionado(s)"
        log_message "✅ Selecionados: $count arquivo(s)"
    }
}

# Limpar seleção
proc clear_files {} {
    global selected_files
    set selected_files [list]
    .files.list delete 0 end
    .files.count configure -text "Nenhum arquivo selecionado"
    log_message "📋 Seleção limpa"
}

# Iniciar operação
proc start_operation {operation} {
    global selected_files operation_running

    if {$operation_running} {
        log_message "⚠️ Operação já em andamento"
        return
    }

    if {[llength $selected_files] == 0} {
        log_message "❌ Nenhum arquivo selecionado"
        return
    }

    # Construir comando baseado na operação
    set cmd ""
    switch -- $operation {
        "ocr"     { set cmd [build_ocr_command] }
        "convert" { set cmd [build_convert_command] }
        "forms"   { set cmd [build_forms_command] }
        "utils"   { set cmd [build_utils_command] }
    }

    if {$cmd eq ""} {
        log_message "❌ Operação desconhecida: $operation"
        return
    }

    log_message "🔧 Comando: $cmd"
    execute_operation $cmd $operation
}

# Construir comando OCR
proc build_ocr_command {} {
    global selected_files ocr_language opt_deskew opt_clean opt_force_ocr opt_remove_background
    
    set file [lindex $selected_files 0]
    set output "[file rootname $file]_ocr.pdf"
    
    set cmd "ocrmypdf --language $ocr_language"
    
    if {$opt_deskew} { append cmd " --deskew" }
    if {$opt_clean} { append cmd " --clean" }
    if {$opt_force_ocr} { append cmd " --force-ocr" }
    if {$opt_remove_background} { append cmd " --remove-background" }
    
    append cmd " \"$file\" \"$output\""
    
    return $cmd
}

# Construir comando de conversão
proc build_convert_command {} {
    global selected_files convert_type quality_var preserve_layout
    
    set file [lindex $selected_files 0]
    
    switch -- $convert_type {
        "pdf_to_txt" {
            set output "[file rootname $file].txt"
            set cmd "pdftotext"
            if {$preserve_layout} { append cmd " -layout" }
            append cmd " \"$file\" \"$output\""
        }
        "pdf_to_docx" {
            set output "[file rootname $file].docx"
            set cmd "pandoc \"$file\" -o \"$output\""
        }
        "pdf_to_images" {
            set output "[file rootname $file]"
            set cmd "pdftoppm -png \"$file\" \"$output\""
        }
        "images_to_pdf" {
            set output "imagens_convertidas.pdf"
            set files_str ""
            foreach f $selected_files { append files_str " \"$f\"" }
            set im_bin [expr {[catch {exec which magick}] == 0 ? "magick" : "convert"}]
            set cmd "${im_bin}${files_str} \"$output\""
        }
    }
    
    return $cmd
}

# Construir comando de formulários
proc build_forms_command {} {
    global selected_files form_action
    
    set file [lindex $selected_files 0]
    
    switch -- $form_action {
        "detect" {
            set output "[file rootname $file]_com_campos.pdf"
            set cmd "commonforms \"$file\" \"$output\""
        }
        "signature" {
            set output "[file rootname $file]_assinaturas.pdf"
            set cmd "commonforms --use-signature-fields \"$file\" \"$output\""
        }
        "extract" {
            set output "[file rootname $file].json"
            set cmd "pdfcpu form list \"$file\" > \"$output\" 2>/dev/null"
        }
    }
    
    return $cmd
}

# Construir comando de utilitários
proc build_utils_command {} {
    global selected_files utils_action
    
    set file [lindex $selected_files 0]
    
    switch -- $utils_action {
        "info" {
            set cmd "pdfinfo \"$file\""
        }
        "merge" {
            set files_str ""
            foreach f $selected_files {
                append files_str " \"[string map {\" \\\"} $f]\""
            }
            set output "merged.pdf"
            set cmd "gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=\"$output\"$files_str"
        }
        "compress" {
            set output "[file rootname $file]_comprimido.pdf"
            set cmd "gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dQUIET -dBATCH -sOutputFile=\"$output\" \"$file\""
        }
        "extract_images" {
            set output "[file rootname $file]"
            set cmd "pdfimages -all \"$file\" \"$output\""
        }
    }
    
    return $cmd
}

# Executar operação real de forma assíncrona via pipe
proc execute_operation {cmd operation} {
    global operation_running progress_value

    set operation_running 1
    set progress_value 0
    .progress.status configure -text "Executando: $operation..."

    # Escreve o comando em script temporário para suportar pipes e redirecionamentos
    set tmpscript "/tmp/pdf_tools_[pid].sh"
    set fh [open $tmpscript w]
    puts $fh "#!/bin/sh"
    puts $fh $cmd
    close $fh

    if {[catch {set fid [open "|sh $tmpscript 2>&1" r]} err]} {
        catch {file delete -force $tmpscript}
        log_message "❌ Erro ao iniciar: $err"
        set operation_running 0
        .progress.status configure -text "Erro ao iniciar operação"
        return
    }

    fconfigure $fid -blocking 0 -buffering line
    fileevent $fid readable [list on_cmd_output $fid $operation $tmpscript]
    progress_tick
}

# Leitura assíncrona da saída do comando em execução
proc on_cmd_output {fid operation tmpscript} {
    global operation_running progress_value

    if {[eof $fid]} {
        set exit_err [catch {close $fid} close_msg]
        catch {file delete -force $tmpscript}
        set operation_running 0
        set progress_value 100

        if {$exit_err && [string match "*child process exited abnormally*" $close_msg]} {
            .progress.status configure -text "❌ Erro na operação"
            log_message "❌ '$operation' falhou"
        } else {
            .progress.status configure -text "✅ Concluído!"
            log_message "✅ '$operation' concluída com sucesso!"
        }

        after 3000 [list .progress.status configure -text "Aguardando operação..."]
        after 3500 {set ::progress_value 0}
        return
    }

    if {[gets $fid line] >= 0 && $line ne ""} {
        log_message $line
    }
}

# Anima a barra de progresso enquanto a operação roda
proc progress_tick {} {
    global operation_running progress_value
    if {$operation_running && $progress_value < 88} {
        incr progress_value 2
        after 300 progress_tick
    }
}

# Log de mensagens
proc log_message {message} {
    set timestamp [clock format [clock seconds] -format "%H:%M:%S"]
    .log.frame.text insert end "$timestamp - $message\n"
    .log.frame.text see end
    update
}

# Preview OCR
proc preview_ocr {} {
    global selected_files
    
    if {[llength $selected_files] == 0} {
        log_message "❌ Selecione um arquivo para pré-visualizar"
        return
    }
    
    set file [lindex $selected_files 0]
    log_message "🔍 Pré-visualizando: [file tail $file]"
    
    # Criar janela de preview
    set preview .preview
    catch {destroy $preview}
    toplevel $preview
    wm title $preview "Pré-visualização - [file tail $file]"
    wm geometry $preview 600x400
    
    text $preview.text -wrap word -font {Courier 10} \
        -yscrollcommand "$preview.scroll set"
    scrollbar $preview.scroll -command "$preview.text yview"
    
    pack $preview.scroll -side right -fill y
    pack $preview.text -side left -fill both -expand 1 -padx 10 -pady 10
    
    # Tentar extrair texto real
    set temp_file "/tmp/pdf_preview_[pid].txt"
    catch {exec pdftotext -layout "$file" "$temp_file"} result
    
    if {[file exists $temp_file]} {
        set fid [open $temp_file r]
        set content [read $fid]
        close $fid
        file delete $temp_file
        
        $preview.text insert end $content
    } else {
        $preview.text insert end "Não foi possível extrair texto do PDF.\n"
        $preview.text insert end "O arquivo pode ser escaneado ou não ter camada de texto.\n\n"
        $preview.text insert end "Recomendação: Use a função OCR primeiro."
    }
}

# Confirmação antes de sair
proc confirm_exit {} {
    global operation_running
    if {$operation_running} {
        set resp [tk_messageBox -type yesno -icon warning \
            -title "Operação em andamento" \
            -message "Uma operação está em andamento. Deseja sair mesmo assim?"]
        if {$resp ne "yes"} { return }
    } else {
        set resp [tk_messageBox -type yesno -icon question \
            -title "Sair" -message "Deseja sair do PDF Tools?"]
        if {$resp ne "yes"} { return }
    }
    exit
}

# Atalhos de teclado
bind . <Control-q> confirm_exit
bind . <Escape>    confirm_exit
bind . <F1> {log_message "ℹ️ Ajuda: Selecione arquivos e escolha uma operação"}

# Inicialização
log_message "🚀 PDF Tools GUI iniciado"
log_message "ℹ️ Selecione arquivos e escolha uma operação"
log_message "ℹ️ Pressione F1 para ajuda"

# Centralizar janela
update
set x [expr {([winfo screenwidth .] - [winfo width .]) / 2}]
set y [expr {([winfo screenheight .] - [winfo height .]) / 2}]
wm geometry . +$x+$y

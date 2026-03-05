# PDF Tools TUI — Rastreamento de Desenvolvimento

> Criado em: 2026-03-05
> Última atualização: 2026-03-05 (revisão completa do código v2.1)

---

## Visão Geral do Projeto

| Arquivo | Linhas | Papel |
|---|---|---|
| `pdf-tools-tui.sh` | ~260 | TUI principal — init, shared overrides, CLI direto, menus (v2.2) |
| `pdf-tools-gui.tcl` | 671 | GUI em Tcl/Tk puro (v1.1) |
| `install.sh` | 828 | Instalador multi-distro |
| `modules/common.sh` | ~190 | Utilitários compartilhados (select_pdf_file, log, progress, etc.) |
| `modules/ocr.sh` | ~380 | OCR completo (9 funções) |
| `modules/forms.sh` | ~220 | Formulários (8 funções) |
| `modules/convert.sh` | ~620 | Conversões (16 opções no menu, 15+ funções) |
| `modules/batch.sh` | ~380 | Processamento em lote (8 funções) |
| `modules/utils.sh` | ~130 | Utilitários PDF + histórico + limpeza (7 funções) |
| `config/` | — | Configurações, presets, logs, cache |

### Arquitetura Atual (v2.2 — modular)

```
pdf-tools-tui.sh (v2.2)
  ├── Variáveis globais (RED, GREEN, ..., SCRIPT_DIR, CONFIG_DIR, ...)
  ├── Carrega módulos em ordem: common → ocr → convert → forms → batch → utils
  ├── Sobrescreve com versões aprimoradas: show_banner, log_operation,
  │   select_pdf_file (com memoria de sessão), show_progress (guard zero)
  ├── Funções CLI diretas: ocr_basic_direct / extract_text_direct / pdf_info_direct
  └── main_menu / config_menu / process_args

modules/common.sh    → select_pdf_file, log_operation, show_progress, validate_pdf, ...
modules/ocr.sh       → ocr_menu, ocr_basic/advanced/force/batch, check_text, languages, ...
modules/forms.sh     → forms_menu, detect/signature/fast/extract/fill/list/remove/pdfa
modules/convert.sh   → convert_menu (16 opções), pdf↔txt/docx/odt/html/csv/images/epub/md, merge, compress, ...
modules/batch.sh     → batch_menu, ocr/txt/docx/images/compress/rename/custom/config em lote
modules/utils.sh     → utils_menu, pdf_info/search/extract_images/repair, show_history, clean_temp

pdf-tools-gui.tcl (v1.1)
  ├── UI Tcl/Tk com abas: OCR / Conversões / Formulários / Utilitários
  ├── Executa comandos reais via pipe assincrono (execute_operation / on_cmd_output)
  ├── preview_ocr — extrai texto real via pdftotext
  └── confirm_exit — com guard para operação em andamento
```

---

## Bugs Encontrados

### Legenda de status
- `ABERTO` — ainda presente no código atual
- `CORRIGIDO` — corrigido na versão 2.1 do TUI / 1.1 da GUI
- `RESIDUAL` — corrigido inline mas ainda presente no módulo (código morto)

---

### Criticos (quebram funcionalidade)

#### BUG-01 — `batch_menu` ausente no script principal
**Arquivo:** `pdf-tools-tui.sh`
**Status:** `CORRIGIDO` — `batch_menu` e todas as sub-funções de lote foram adicionadas inline a partir da linha 1279.

---

#### BUG-02 — `confirm_exit` não definida na GUI
**Arquivo:** `pdf-tools-gui.tcl:342`
**Status:** `CORRIGIDO` — proc `confirm_exit` definida em `pdf-tools-gui.tcl:641`.

---

#### BUG-03 — `preview_ocr` incompleta na GUI
**Arquivo:** `pdf-tools-gui.tcl`
**Status:** `CORRIGIDO` — proc `preview_ocr` completa com toplevel, text widget, scrollbar e extração real via `pdftotext`.

---

#### BUG-04 — Arquivo `&1` estranho na raiz do projeto
**Descrição:** Arquivo criado acidentalmente por redirecionamento mal formado (`2>&1` sem pipe). Continha mensagem de erro do ocrmypdf.
**Status:** `CORRIGIDO` — arquivo removido.

---

#### BUG-05 — `config_menu` verificava binário inexistente (`ghostscript`)
**Arquivo:** `pdf-tools-tui.sh:1668`
**Descrição:** O laço de verificação de dependências testava `command -v ghostscript`, mas o binário chama-se `gs`.
**Status:** `CORRIGIDO` — linha 1668 agora lista `gs` corretamente.

---

### Medios (comportamento incorreto)

#### BUG-06 — Divisão por zero em `show_progress` no módulo comum
**Arquivo:** `modules/common.sh:68`
**Descrição:** `$((current * 100 / total))` sem guard para `total=0`.
**Status:** `CORRIGIDO` — guard `[ "$total" -eq 0 ] && return` adicionado em `modules/common.sh` e já existia no inline.

---

#### BUG-07 — `batch_convert_function` — falso sucesso quando conversor desconhecido
**Arquivo:** `modules/batch.sh:148-161`
**Descrição:** Se `$converter` não bater em nenhum `case`, `$?` seria 0 e o script reportaria sucesso.
**Status:** `CORRIGIDO` — `modules/batch.sh` atualizado com `local ok=false` e `*) break` no case. Inline já estava correto.

---

#### BUG-08 — `forms_extract_json` salva texto como JSON
**Arquivo:** `pdf-tools-tui.sh` (funcao forms_extract_json)
**Descrição:** `pdfcpu form list` retorna texto formatado, **não JSON**. O arquivo de saída tem extensão `.json` mas conteúdo é texto plano.
**Status:** `CORRIGIDO` — `modules/forms.sh` usa extensão `.txt` e rótulo do menu atualizado. TUI inline já estava correto.

---

#### BUG-09 — `convert_docx_to_pdf` — nome do arquivo de saída errado com LibreOffice
**Arquivo:** `pdf-tools-tui.sh` (funcao convert_docx_to_pdf)
**Descrição:** `libreoffice --convert-to pdf` gera o arquivo com o nome-base do fonte (`.pdf`) no diretório especificado, ignorando o nome customizado do usuário. O echo de confirmacao reporta o nome errado.
**Status:** `ABERTO` — após a conversão, localizar o arquivo gerado e renomeá-lo para o nome desejado.

---

#### BUG-10 — GUI `build_utils_command` — paths sem aspas na mesclagem
**Arquivo:** `pdf-tools-gui.tcl:506`
**Descrição:** `set files [join $selected_files " "]` junta caminhos com espaço simples, sem aspas. Arquivos com espaço no nome quebram o comando `gs` de mesclagem.
**Status:** `CORRIGIDO` — `pdf-tools-gui.tcl`: `build_utils_command` agora itera com `foreach` e aplica `string map` para escapar aspas em cada path antes de adicionar ao comando `gs`.

---

#### BUG-11 — `batch_compress` — divisão por zero em módulo
**Arquivo:** `modules/batch.sh:240`
**Descrição:** `$((100 - (new_size * 100 / original_size)))` quando `original_size=0`.
**Status:** `CORRIGIDO` — `modules/batch.sh`: `original_size` com fallback `echo 0` e guard `[ "$original_size" -gt 0 ]` antes da divisão. Inline já estava correto.

---

#### BUG-12 — `batch_ocr` em `modules/batch.sh` não verifica `ocrmypdf`
**Arquivo:** `modules/batch.sh:88`
**Descrição:** Chama `ocrmypdf` diretamente sem `command -v`, dando mensagem de erro pouco informativa.
**Status:** `CORRIGIDO` — `modules/batch.sh`: `batch_ocr` verifica `command -v ocrmypdf` antes de processar.

---

### Baixos (qualidade de codigo / confusao)

#### BUG-13 — Conflito de nome: `extract_text` em dois lugares
**Arquivo:** `modules/common.sh:155` e `pdf-tools-tui.sh`
**Descrição:** Mesma assinatura, comportamentos diferentes. O módulo é sobrescrito pelo inline.
**Status:** `CORRIGIDO` — `modules/common.sh`: função renomeada para `extract_text_common` para evitar colisão com a versão inline.

---

#### BUG-14 — Módulos são código morto (exceto estrutura de batch)
**Arquivo:** `modules/ocr.sh`, `modules/forms.sh`, `modules/convert.sh`, `modules/common.sh`
**Descrição:** Todas as funções são sobrescritas pelas versões inline. Os módulos são carregados desnecessariamente.
**Status:** `CORRIGIDO` — Integração modular completa (v2.2): TUI reescrito com ~260 linhas, módulos são a fonte de verdade, `modules/utils.sh` criado, `modules/convert.sh` melhorado. Ver seção "Integração Modular" abaixo.

---

#### BUG-15 — `ocr_advanced` em módulo usa `$options` sem aspas (arg splitting)
**Arquivo:** `modules/ocr.sh:93`
**Descrição:** `ocrmypdf $options "$SELECTED_FILE"` — string concatenada em vez de array.
**Status:** `CORRIGIDO` — `modules/ocr.sh`: `ocr_advanced` migrado para array `options=()`; `"${options[@]}"` na chamada do `ocrmypdf`.

---

#### BUG-16 — `clean_temp` não limpava scripts temporários da GUI
**Arquivo:** `pdf-tools-tui.sh` (funcao clean_temp)
**Descrição:** Não removia os scripts `/tmp/pdf_tools_*.sh` gerados pela GUI Tcl.
**Status:** `CORRIGIDO` — `pdf-tools-tui.sh:1271` agora remove `/tmp/pdf_tools_*.sh`.

---

#### BUG-17 — `ocr_batch` em módulo usa `SELECTED_FILE` vazio para diretório de saída
**Arquivo:** `modules/ocr.sh:148`
**Descrição:** `local output_dir="${SELECTED_FILE%.*}_ocr_batch"` — se chamado sem arquivo selecionado, cria diretório `_ocr_batch`.
**Status:** `CORRIGIDO` — `modules/ocr.sh`: `ocr_batch` usa `ocr_batch_$(date +%Y%m%d_%H%M%S)` como diretório de saída.

---

## Sugestoes de Melhoria

| # | Sugestao | Prioridade |
|---|---|---|
| S-01 | Corrigir BUG-08: mudar extensao de `.json` para `.txt` ou usar ferramenta que emita JSON | Alta |
| S-02 | Corrigir BUG-09: pos-processar nome do arquivo gerado pelo LibreOffice | Alta |
| S-03 | Corrigir BUG-10 na GUI: escapar paths na mesclagem de PDFs | Alta |
| S-04 | Remover `modules/ocr.sh`, `modules/forms.sh`, `modules/convert.sh`, `modules/common.sh` (codigo morto) | Media |
| S-05 | Adicionar validacao de PDF (`pdfinfo`) antes de qualquer operacao destructiva | Media |
| S-06 | Adicionar suporte a configuracao persistente (carregar `config/settings.conf` e honrar LANGUAGE=) | Media |
| S-07 | GUI: escapar paths em todos os `build_*_command` (nao so na mesclagem) | Media |
| S-08 | GUI: adicionar suporte a arrastar-e-soltar arquivos | Baixa |
| S-09 | `ocr_languages` lê idioma padrão de `settings.conf`, mas o TUI principal ignora essa config | Baixa |

---

## Log de Atividades

| Data | Acao | Responsavel |
|---|---|---|
| 2026-03-05 | Leitura completa do projeto, mapeamento de bugs e criacao do track.md | Claude |
| 2026-03-05 | Revisao completa do codigo v2.1/v1.1: reconfirmacao e atualizacao de status de todos os bugs | Claude |
| 2026-03-05 | Correcao de todos os bugs ativos e residuais nos modulos e na GUI | Claude |
| 2026-03-05 | Integração modular v2.2: TUI reescrito (~260 linhas), utils.sh criado, convert.sh melhorado | Claude |
| 2026-03-05 | Testes manuais pelo usuário — 10 novos bugs documentados (BUG-18 a BUG-27) | Yuri + Claude |

### Correcoes aplicadas nesta sessao

| Bug | Arquivo(s) alterado(s) | O que foi feito |
|---|---|---|
| BUG-06 | `modules/common.sh:68` | Adicionado guard `[ "$total" -eq 0 ] && return` em `show_progress` |
| BUG-07 | `modules/batch.sh:148` | `batch_convert_function` usa `local ok=false` + `*) break` no case |
| BUG-08 | `modules/forms.sh:101,16` | `forms_extract_json` usa extensao `.txt`; menu atualizado |
| BUG-10 | `pdf-tools-gui.tcl:506` | `build_utils_command` merge: cada path agora entre aspas com escaping |
| BUG-11 | `modules/batch.sh:233` | `batch_compress` guarda `original_size` com fallback `echo 0`; guard antes da divisao |
| BUG-12 | `modules/batch.sh:88` | `batch_ocr` agora verifica `command -v ocrmypdf` antes de processar |
| BUG-13 | `modules/common.sh:155` | `extract_text` renomeada para `extract_text_common` para evitar colisao |
| BUG-15 | `modules/ocr.sh:81` | `ocr_advanced` migrado de string para array `options=()`; `"${options[@]}"` |
| BUG-17 | `modules/ocr.sh:148` | `ocr_batch` usa `ocr_batch_$(date +%Y%m%d_%H%M%S)` como `output_dir` |

---

## Status Geral

- Criticos: **5 corrigidos** — 0 abertos
- Medios: **7 corrigidos** — 0 abertos
- Baixos: **5 corrigidos** — 1 aberto (BUG-14: modulos sao codigo morto — decisao arquitetural pendente)
- **Total de bugs resolvidos (ciclo anterior): 17 de 17**
- **Novos bugs descobertos em teste (pós v2.2): 10 abertos** (BUG-18 a BUG-27)
  - Críticos: 3 (BUG-18, BUG-19, BUG-20)
  - Médios: 5 (BUG-21 a BUG-25)
  - Baixos: 2 (BUG-26, BUG-27)

---

## Bugs Descobertos em Teste (pós v2.2)

> Reportados pelo usuário em: 2026-03-05 — testes manuais na GUI e TUI

---

### Criticos

#### BUG-18 — GUI forms detect usa `commonforms` sem `--fast` → demora muito
**Arquivo:** `pdf-tools-gui.tcl` → `build_forms_command`
**Descrição:** A ação "Detectar campos automaticamente" chama `commonforms "$file" "$output"` sem a flag `--fast`. Sem ela, `commonforms` faz análise completa (ML), que pode ser muito lenta. O TUI tem `forms_fast` com `--fast` como opção separada, mas a GUI não expõe isso. Usuário relatou demora excessiva — normalmente é rápido.
**Causa provável:** Falta da flag `--fast` ou `commonforms` não instalado (neste caso o processo fica pendente sem feedback claro).
**Acao de correcao:** Adicionar checkbox "Detecção rápida (`--fast`)" na aba Formulários da GUI; marcar por padrão. Verificar `command -v commonforms` antes de chamar.
**Status:** `ABERTO`

---

#### BUG-19 — GUI utils/info não salva arquivo — só exibe no log
**Arquivo:** `pdf-tools-gui.tcl` → `build_utils_command` → case `info`
**Descrição:** `pdfinfo "$file"` imprime na saída padrão, que vai para o log da GUI. Nenhum arquivo é gerado. Todos os processos devem gerar arquivo de saída.
**Acao de correcao:** Trocar comando para `pdfinfo "$file" > "[file rootname $file]_info.txt"` para salvar o resultado em arquivo.
**Status:** `ABERTO`

---

#### BUG-20 — GUI forms/extract ainda usa extensão `.json`
**Arquivo:** `pdf-tools-gui.tcl` → `build_forms_command` → case `extract`
**Descrição:** O BUG-08 foi corrigido no TUI e em `modules/forms.sh`, mas a GUI ainda usa `[file rootname $file].json`. A saída do `pdfcpu form list` é texto formatado, não JSON.
**Acao de correcao:** Mudar extensão para `.txt` no `build_forms_command`.
**Status:** `ABERTO`

---

### Medios

#### BUG-21 — TUI `forms_detect`, `forms_detect_signature`, `forms_fast` sem check de `commonforms`
**Arquivo:** `modules/forms.sh:48,71,90`
**Descrição:** As três funções chamam `commonforms` diretamente sem `command -v commonforms`. Se não instalado, o erro é genérico e confuso.
**Acao de correcao:** Adicionar guard `command -v commonforms || { echo "❌ commonforms não encontrado"; return 1; }` no topo de cada função.
**Status:** `ABERTO`

---

#### BUG-22 — TUI `forms_remove_fields` e `forms_to_pdfa` sem verificação de erro (falso sucesso)
**Arquivo:** `modules/forms.sh:177,193`
**Descrição:** Ambas as funções chamam `gs` e imprimem "✅" incondicionalmente, sem verificar `$?` ou se o arquivo foi gerado. Se `gs` falhar, o usuário vê sucesso falso e nenhum arquivo é criado.
**Acao de correcao:** Adicionar `if [ $? -eq 0 ] && [ -f "$output" ]; then ... else echo ❌; fi`.
**Status:** `ABERTO`

---

#### BUG-23 — TUI `ocr_basic`, `ocr_advanced`, `ocr_force` sem `command -v ocrmypdf`
**Arquivo:** `modules/ocr.sh:54,94,114`
**Descrição:** O modo interativo chama `ocrmypdf` diretamente sem checar se está instalado. As funções `_direct` têm o guard, mas o menu interativo não.
**Acao de correcao:** Adicionar `command -v ocrmypdf &>/dev/null || { echo "❌ ocrmypdf não encontrado"; ...; return; }` no início de cada função.
**Status:** `ABERTO`

---

#### BUG-24 — TUI `convert_pdf_to_odt` — BUG-09 não corrigido (nome LibreOffice ignorado)
**Arquivo:** `modules/convert.sh:129`
**Descrição:** `libreoffice --convert-to odt` ignora o nome de destino e gera `basename.odt` no diretório de saída. Não foi aplicado o mesmo padrão `mv` que foi feito em `convert_docx_to_pdf`.
**Acao de correcao:** Capturar o arquivo gerado pelo LibreOffice e renomear com `mv` para o nome desejado, igual ao padrão aplicado em `convert_docx_to_pdf`.
**Status:** `ABERTO`

---

#### BUG-25 — TUI `convert_pdf_to_html` sem verificação de arquivo gerado
**Arquivo:** `modules/convert.sh:154-169`
**Descrição:** Modos 1 (`pdftohtml`) e 3 (`pandoc`) não verificam `$?` nem `[ -f "$output" ]`. Só o modo 2 faz check de `command -v`. Se a conversão falhar silenciosamente, não há feedback de erro.
**Acao de correcao:** Após cada conversão, verificar `[ -f "$output" ]` e exibir erro se não gerou arquivo.
**Status:** `ABERTO`

---

### Baixos

#### BUG-26 — TUI `forms_list_fields` — parâmetro quiet com semântica confusa
**Arquivo:** `modules/forms.sh:149,162`
**Descrição:** A função recebe `--quiet` como `$2` mas compara `"$quiet" = false`. Funciona por acidente (`"--quiet" != "false"` evita o prompt), mas a lógica está invertida e difícil de manter.
**Acao de correcao:** Mudar para `[[ "$2" == "--quiet" ]] && local quiet=true || local quiet=false` e comparar `$quiet = true`.
**Status:** `ABERTO`

---

#### BUG-27 — TUI `forms_fill_json` — sem validação do JSON antes de chamar pdfcpu
**Arquivo:** `modules/forms.sh:125-142`
**Descrição:** Usa `select json in *.json` sem verificar se há arquivos `.json` no diretório. Se não houver, o `select` trava esperando entrada que nunca será válida.
**Acao de correcao:** Checar `ls *.json 2>/dev/null` antes do `select`; exibir erro e retornar se não houver arquivos.
**Status:** `ABERTO`

---

## Integração Modular (v2.2)

### O que mudou

| Item | Antes (v2.1) | Depois (v2.2) |
|---|---|---|
| `pdf-tools-tui.sh` | ~1690 linhas (tudo inline) | ~260 linhas (só init + overrides + menus) |
| Módulos | carregados mas sobrescritos | **fonte de verdade** — usados diretamente |
| `modules/utils.sh` | não existia | criado com 7 funções |
| `modules/convert.sh` | 16 opções mas com bugs | bugs corrigidos (convert_docx_to_pdf, merge_pdfs, compress_pdf, convert_pdf_to_txt) |

### Ordem de carregamento dos módulos
```
common → ocr → convert → forms → batch → utils
```
O TUI redefine depois do source loop (overrides aprimorados):
- `show_banner` — exibe versão e arquivo atual
- `log_operation` — garante criação do diretório de log
- `select_pdf_file` — menu numerado + memória de sessão
- `show_progress` — guard para total=0

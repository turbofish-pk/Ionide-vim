" Vim autoload functions
if exists('g:loaded_autoload_fsharp')
    finish
endif
let g:loaded_autoload_fsharp = 1

" basic setups

function! s:get_newline()
    if has('win32') || &fileformat ==# 'dos'
        return "\r\n"
    else
        return "\n"
    endif
endfunction
let s:newline = s:get_newline()

" FSAC payload interfaces

function! s:TextDocumentIdentifier(path)
    return { 'Uri': luaeval('vim.uri_from_fname(_A)', fnamemodify(a:path, ':p')) }
endfunction

function! s:Position(line, character)
    return { 'Line': a:line, 'Character': a:character }
endfunction

function! s:TextDocumentPositionParams(documentUri, line, character)
    return { 'TextDocument': s:TextDocumentIdentifier(a:documentUri), 'Position': s:Position(a:line, a:character) }
endfunction

function! s:WorkspaceLoadParams(files)
    let prm = []
    for file in a:files
        call add(prm, s:TextDocumentIdentifier(file))
    endfor
    return { 'TextDocuments': prm }
endfunction

" LSP functions

function! s:call(method, params, cont)
    let key = fsharp#register_callback(a:cont)
    call luaeval('require("ionide").call(_A[1], _A[2], _A[3])', [a:method, a:params, key])
endfunction

function! s:notify(method, params)
    " done
    "call luaeval('require("ionide").notify(_A[1], _A[2])', [a:method, a:params])
    call v:lua.require('fsharp_vim').notify(a:method, a:params)
endfunction

function! s:signature(filePath, line, character, cont)
    return s:call('fsharp/signature', s:TextDocumentPositionParams(a:filePath, a:line, a:character), a:cont)
endfunction
function! s:workspaceLoad(files, cont)
    return s:call('fsharp/workspaceLoad', s:WorkspaceLoadParams(a:files), a:cont)
endfunction
function! s:f1Help(filePath, line, character, cont)
    return s:call('fsharp/f1Help', s:TextDocumentPositionParams(a:filePath, a:line, a:character), a:cont)
endfunction
function! fsharp#documentation(filePath, line, character, cont)
    return s:call('fsharp/documentation', s:TextDocumentPositionParams(a:filePath, a:line, a:character), a:cont)
endfunction


" FSAC configuration

" FSharpConfigDto from https://github.com/fsharp/FsAutoComplete/blob/master/src/FsAutoComplete/LspHelpers.fs
"
" * The following options seems not working with workspace/didChangeConfiguration
"   since the initialization has already completed?
"     'AutomaticWorkspaceInit',
"     'WorkspaceModePeekDeepLevel',
"
" * Changes made to linter/unused analyzer settings seems not reflected after sending them to FSAC?
"
let s:config_keys_camel =
            \ [
            \     {'key': 'AutomaticWorkspaceInit', 'default': 1},
            \     {'key': 'WorkspaceModePeekDeepLevel', 'default': 2},
            \     {'key': 'ExcludeProjectDirectories', 'default': []},
            \     {'key': 'keywordsAutocomplete', 'default': 1},
            \     {'key': 'ExternalAutocomplete', 'default': 0},
            \     {'key': 'FullNameExternalAutocomplete', 'default': 0},
            \     {'key': 'Linter', 'default': 1},
            \     {'key': 'LinterConfig'},
            \     {'key': 'IndentationSize', 'default': 4},
            \     {'key': 'UnionCaseStubGeneration', 'default': 1},
            \     {'key': 'UnionCaseStubGenerationBody'},
            \     {'key': 'RecordStubGeneration', 'default': 1},
            \     {'key': 'RecordStubGenerationBody'},
            \     {'key': 'InterfaceStubGeneration', 'default': 1},
            \     {'key': 'InterfaceStubGenerationObjectIdentifier', 'default': 'this'},
            \     {'key': 'InterfaceStubGenerationMethodBody'},
            \     {'key': 'AddPrivateAccessModifier', 'default': 0},
            \     {'key': 'UnusedOpensAnalyzer', 'default': 1},
            \     {'key': 'UnusedOpensAnalyzerExclusions', 'default': []},
            \     {'key': 'UnusedDeclarationsAnalyzer', 'default': 1},
            \     {'key': 'UnusedDeclarationsAnalyzerExclusions', 'default': []},
            \     {'key': 'SimplifyNameAnalyzer', 'default': 0},
            \     {'key': 'SimplifyNameAnalyzerExclusions', 'default': []},
            \     {'key': 'UnnecessaryParenthesesAnalyzer', 'default': 0},
            \     {'key': 'UnnecessaryParenthesesAnalyzerExclusions', 'default': []},
            \     {'key': 'ResolveNamespaces', 'default': 1},
            \     {'key': 'EnableReferenceCodeLens', 'default': 1},
            \     {'key': 'EnableAnalyzers', 'default': 0},
            \     {'key': 'AnalyzersPath'},
            \     {'key': 'ExcludeAnalyzers'},
            \     {'key': 'IncludeAnalyzers'},
            \     {'key': 'DisableInMemoryProjectReferences', 'default': 0},
            \     {'key': 'LineLens', 'default': {'enabled': 'never', 'prefix': ''}},
            \     {'key': 'UseSdkScripts', 'default': 1},
            \     {'key': 'dotNetRoot'},
            \     {'key': 'fsiExtraParameters'},
            \     {'key': 'fsiExtraInteractiveParameters', 'default': ['--readline-']},
            \     {'key': 'fsiExtraSharedParameters', 'default': []},
            \     {'key': 'fsiCompilerToolLocations', 'default': []},
            \     {'key': 'TooltipMode', 'default': 'full'},
            \     {'key': 'GenerateBinlog', 'default': 0},
            \     {'key': 'AbstractClassStubGeneration', 'default': 1},
            \     {'key': 'AbstractClassStubGenerationObjectIdentifier', 'default': 'this'},
            \     {'key': 'AbstractClassStubGenerationMethodBody', 'default': 'failwith "Not Implemented"'},
            "\    {'key': 'CodeLenses', TODO},
            "\    {'key': 'PipelineHints', TODO}
            "\    {'key': 'InlayHints', TODO}
            "\    {'key': 'Fsac', TODO}
            "\    {'key': 'Notifications', TODO}
            "\    {'key': 'Debug', TODO}
            \ ]
let s:config_keys = []
let s:config_is_loaded = v:false

function! s:toSnakeCase(str)
    let sn = substitute(a:str, '\(\<\u\l\+\|\l\+\)\(\u\)', '\l\1_\l\2', 'g')
    if sn ==# a:str | return tolower(a:str) | endif
    return sn
endfunction

function! s:buildConfigKeys()
    if empty(s:config_keys)
        for key_camel in s:config_keys_camel
            let key = {}
            let key.snake = s:toSnakeCase(key_camel.key)
            let key.camel = key_camel.key
            if has_key(key_camel, 'default')
                let key.default = key_camel.default
            endif
            call add(s:config_keys, key)
        endfor
    endif
endfunction

function! fsharp#getServerConfig()
    let fsharp = {}
    call s:buildConfigKeys()
    for key in s:config_keys
        if exists('g:fsharp#' . key.snake)
            let fsharp[key.camel] = g:fsharp#{key.snake}
        elseif exists('g:fsharp#' . key.camel)
            let fsharp[key.camel] = g:fsharp#{key.camel}
        elseif has_key(key, 'default') && g:fsharp#use_recommended_server_config
            let g:fsharp#{key.snake} = key.default
            let fsharp[key.camel] = key.default
        endif
    endfor
    return fsharp
endfunction

function! fsharp#updateServerConfig()
    let fsharp = fsharp#getServerConfig()
    let settings = {'settings': {'FSharp': fsharp}}
    call s:notify('workspace/didChangeConfiguration', settings)
endfunction

function! fsharp#loadConfig()
    if s:config_is_loaded
        return
    endif

    if !exists('g:fsharp#fsautocomplete_command')
        let g:fsharp#fsautocomplete_command = ['fsautocomplete']
    endif
    if !exists('g:fsharp#use_recommended_server_config')
        let g:fsharp#use_recommended_server_config = 1
    endif
    call fsharp#getServerConfig()
    if !exists('g:fsharp#automatic_workspace_init')
        let g:fsharp#automatic_workspace_init = 1
    endif
    if !exists('g:fsharp#automatic_reload_workspace')
        let g:fsharp#automatic_reload_workspace = 1
    endif
    if !exists('g:fsharp#show_signature_on_cursor_move')
        let g:fsharp#show_signature_on_cursor_move = 0
    endif
    if !exists('g:fsharp#fsi_command')
        let g:fsharp#fsi_command = "dotnet fsi"
    endif
    if !exists('g:fsharp#fsi_keymap')
        let g:fsharp#fsi_keymap = "vscode"
    endif
    if !exists('g:fsharp#fsi_window_command')
        let g:fsharp#fsi_window_command = "botright 10new"
    endif
    if !exists('g:fsharp#fsi_focus_on_send')
        let g:fsharp#fsi_focus_on_send = 0
    endif
    if !exists('g:fsharp#fsi_trim_indentation')
        let g:fsharp#fsi_trim_indentation = 1
    endif

    " backend configuration
    if !exists('g:fsharp#lsp_auto_setup')
        let g:fsharp#lsp_auto_setup = 1
    endif
    if !exists('g:fsharp#lsp_codelens')
        let g:fsharp#lsp_codelens = 1
    endif

    " FSI keymaps
    if g:fsharp#fsi_keymap ==# "vscode"
        let g:fsharp#fsi_keymap_send   = "<M-cr>"
        let g:fsharp#fsi_keymap_toggle = "<M-@>"
    elseif g:fsharp#fsi_keymap ==# "vim-fsharp"
        let g:fsharp#fsi_keymap_send   = "<leader>i"
        let g:fsharp#fsi_keymap_toggle = "<leader>e"
    elseif g:fsharp#fsi_keymap ==# "custom"
        let g:fsharp#fsi_keymap = "none"
        if !exists('g:fsharp#fsi_keymap_send')
            echoerr "g:fsharp#fsi_keymap_send is not set"
        elseif !exists('g:fsharp#fsi_keymap_toggle')
            echoerr "g:fsharp#fsi_keymap_toggle is not set"
        else
            let g:fsharp#fsi_keymap = "custom"
        endif
    endif

    let s:config_is_loaded = v:true
endfunction


" handlers for notifications

let s:handlers = { 'fsharp/notifyWorkspace': 'fsharp#handle_notifyWorkspace', }

function! s:registerAutocmds()
    if g:fsharp#lsp_codelens
        augroup FSharp_AutoRefreshCodeLens
            autocmd!
            autocmd CursorHold,InsertLeave <buffer> lua vim.lsp.codelens.refresh()
        augroup END
    endif
    augroup FSharp_OnCursorMove
        autocmd!
        autocmd CursorMoved *.fs,*.fsi,*.fsx  call fsharp#OnCursorMove()
    augroup END
endfunction

function! fsharp#initialize()
    echom '[FSAC] Initialized'
    call fsharp#updateServerConfig()
    call s:registerAutocmds()
endfunction


" nvim-lsp specific functions

" handlers are picked up by ionide.setup()
function! fsharp#get_handlers()
    return s:handlers
endfunction

let s:callback_id = 0
let s:callbacks = {}

function! fsharp#register_callback(fn)
    if type(a:fn) != v:t_func
        return -1
    endif
    let s:callback_id += 1
    let key = string(s:callback_id)
    let s:callbacks[key] = a:fn
    return key
endfunction

function! fsharp#resolve_callback(key, arg)
    if has_key(s:callbacks, a:key)
        let Callback = s:callbacks[a:key]
        call Callback(a:arg)
        call remove(s:callbacks, a:key)
    endif
endfunction


" .NET/F# specific operations

let s:workspace = []

function! fsharp#getLoadedProjects()
    return copy(s:workspace)
endfunction

function! fsharp#handle_notifyWorkspace(payload) abort
    let content = json_decode(a:payload.content)
    if content.Kind ==# 'projectLoading'
        echom "[FSAC] Loading" content.Data.Project
        let s:workspace = uniq(sort(add(s:workspace, content.Data.Project)))
    elseif content.Kind ==# 'workspaceLoad' && content.Data.Status ==# 'finished'
        echom printf("[FSAC] Workspace loaded (%d project(s))", len(s:workspace))
        call fsharp#updateServerConfig()
    endif
endfunction


function! s:load(arg)
    call s:workspaceLoad(a:arg, v:null)
endfunction

function! fsharp#loadProject(...)
    let prjs = []
    for proj in a:000
        call add(prjs, fnamemodify(proj, ':p'))
    endfor
    call s:load(prjs)
endfunction

function! fsharp#showLoadedProjects()
    for proj in s:workspace
        echo "-" proj
    endfor
endfunction

function! fsharp#reloadProjects()
    if !empty(s:workspace)
        call s:workspaceLoad(s:workspace, v:null)
    else
        echom "[FSAC] Workspace is empty"
    endif
endfunction

function! fsharp#OnFSProjSave()
    if &ft ==# "fsharp_project" && g:fsharp#automatic_reload_workspace
        call fsharp#reloadProjects()
    endif
endfunction

function! fsharp#showSignature()
    function! s:callback_showSignature(result)
        if exists('a:result.result.content')
            let content = json_decode(a:result.result.content)
            if exists('content.Data')
                echo substitute(content.Data, '\n\+$', ' ', 'g')
            endif
        endif
    endfunction
    call s:signature(expand('%:p'), line('.') - 1, col('.') - 1, function("s:callback_showSignature"))
endfunction

function! fsharp#OnCursorMove()
    if g:fsharp#show_signature_on_cursor_move
        call fsharp#showSignature()
    endif
endfunction

function! fsharp#showF1Help()
    function! s:callback_showF1Help(result)
        if exists('a:result.result.content')
            let content = json_decode(a:result.result.content)
            if exists('content.Data')
                let url = 'https://docs.microsoft.com/en-us/dotnet/api/' . substitute(content.Data, '#ctor', '-ctor', 'g')
                echo url
            endif
        endif
    endfunction
    call s:f1Help(expand('%:p'), line('.') - 1, col('.') - 1, function("s:callback_showF1Help"))
endfunction

function! s:hover()
    "done
    call v:lua.require('fsharp_vim').hover()
endfunction

function! fsharp#showTooltip()
    function! s:callback_showTooltip(result)
        if exists('a:result.result.content')
            let content = json_decode(a:result.result.content)
            if exists('content.Data')
                call s:hover()
            endif
        endif
    endfunction
    " show hover only if signature exists for the current position
    call s:signature(expand('%:p'), line('.') - 1, col('.') - 1, function("s:callback_showTooltip"))
endfunction


" FSI integration

let s:fsi_buffer = -1
let s:fsi_job    = -1
let s:fsi_width  = 0
let s:fsi_height = 0

function! s:get_fsi_command()
    let cmd = g:fsharp#fsi_command
    for prm in g:fsharp#fsi_extra_interactive_parameters
        let cmd = cmd . " " . prm
    endfor
    for prm in g:fsharp#fsi_extra_shared_parameters
        let cmd = cmd . " " . prm
    endfor
    return cmd
endfunction

function! fsharp#openFsi(returnFocus)
    if bufwinid(s:fsi_buffer) <= 0
        let fsi_command = s:get_fsi_command()
        let current_win = win_getid()

        execute g:fsharp#fsi_window_command
        if s:fsi_width  > 0 | execute 'vertical resize' s:fsi_width | endif
        if s:fsi_height > 0 | execute 'resize' s:fsi_height | endif

        if s:fsi_buffer >= 0 && bufexists(s:fsi_buffer) && s:fsi_job > 0 && jobwait([s:fsi_job], 0)[0] == -1
            execute 'buffer' s:fsi_buffer
            " go to the last line of the file
            normal! G
            if a:returnFocus
                call win_gotoid(current_win)
            endif
        else
            let s:fsi_job = termopen(fsi_command)
            if s:fsi_job > 0
                let s:fsi_buffer = bufnr("%")
            else
                close
                echom "[FSAC] Failed to open FSI."
                return -1
            endif
        endif

        setlocal bufhidden=hide
        " go to the last line of the file
        normal! G

        if a:returnFocus
            call win_gotoid(current_win)
        endif
        return s:fsi_buffer
    endif
    return s:fsi_buffer
endfunction

function! fsharp#toggleFsi()
    let fsiWindowId = bufwinid(s:fsi_buffer)
    if fsiWindowId > 0
        let current_win = win_getid()
        call win_gotoid(fsiWindowId)
        let s:fsi_width = winwidth('%')
        let s:fsi_height = winheight('%')
        close
        call win_gotoid(current_win)
    else
        call fsharp#openFsi(0)
    endif
endfunction

function! fsharp#quitFsi()
    if s:fsi_buffer >= 0 && bufexists(s:fsi_buffer)
        let winid = bufwinid(s:fsi_buffer)
        "if winid > 0 | execute "close " . winid | endif
        if winid > 0
            let current_win = win_getid()
            call win_gotoid(winid)
            close
            call win_gotoid(current_win)
        endif
        call jobstop(s:fsi_job)
        let s:fsi_buffer = -1
        let s:fsi_job = -1
    endif
endfunction

function! fsharp#resetFsi()
    call fsharp#quitFsi()
    return fsharp#openFsi(1)
endfunction

function! fsharp#sendFsi(text)
    if fsharp#openFsi(!g:fsharp#fsi_focus_on_send) > 0
        " Neovim
        let l:current_dir = expand('%:p:h')
        " Ensure directory exists before trying to cd into it
        if !empty(l:current_dir) && isdirectory(l:current_dir)
            let l:cd_command = printf('#cd @"%s"', l:current_dir)
            let l:full_text = l:cd_command . s:newline . a:text
        else
            let l:full_text = a:text " Don't send #cd if directory is invalid/empty
        endif
        "call chansend(s:fsi_job, l:full_text . s:newline . ";;". s:newline)
        if s:fsi_job > 0 && jobwait([s:fsi_job], 0)[0] == -1
            call chansend(s:fsi_job, l:full_text . s:newline . ';;' . s:newline)
        else
            echom '[FSAC] FSI is not running.'
            return -1
        endif
    endif
endfunction

function! s:trim_common_leading_spaces(lines)
    let min_indent = 1000
    for line in a:lines
        if empty(line) | continue | endif
        let indent = match(line, '\S')
        if indent == -1 | continue | endif
        if min_indent == 1000 || indent < min_indent
            let min_indent = indent
        endif
    endfor

    if min_indent > 0
        let trimmed_lines = []
        for line in a:lines
            call add(trimmed_lines, strpart(line, min_indent))
        endfor
        return trimmed_lines
    else
        return a:lines
    endif
endfunction

" https://stackoverflow.com/a/6271254
function! s:get_visual_selection()
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if empty(lines)
        return []
    endif
    let lines[-1] = lines[-1][: column_end - (&selection ==# 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
    return lines
endfunction

function! s:get_complete_buffer()
    return join(getline(1, '$'), s:newline)
endfunction

function! fsharp#sendSelectionToFsi() range
    let lines = s:get_visual_selection()
    if empty(lines)
        return
    endif
    execute 'normal! ' . len(lines) . 'j'
    if g:fsharp#fsi_trim_indentation == 1
        let trimmed_lines = s:trim_common_leading_spaces(lines)
    else
        let trimmed_lines = lines
    endif
    let text = join(trimmed_lines, s:newline)
    return fsharp#sendFsi(text)
endfunction

function! fsharp#sendLineToFsi()
    let lines = [getline('.')]
    if g:fsharp#fsi_trim_indentation == 1
        let trimmed_lines = s:trim_common_leading_spaces(lines)
    else
        let trimmed_lines = lines
    endif
    let text = trimmed_lines[0]
    execute 'normal! j'
    return fsharp#sendFsi(text)
endfunction

function! fsharp#sendAllToFsi()
    let text = s:get_complete_buffer()
    return fsharp#sendFsi(text)
endfunction

" vim: sw=4 et sts=4

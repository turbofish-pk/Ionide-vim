" Vim filetype plugin

if exists('b:did_fsharp_ftplugin')
    finish
endif
let b:did_fsharp_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

" enable syntax based folding
setl fdm=syntax

" comment settings
setl formatoptions=croql
setl commentstring=(*%s*)
setl comments=s0:*\ -,m0:*\ \ ,ex0:*),s1:(*,mb:*,ex:*),:\/\/\/,:\/\/

" make ftplugin undo-able
let b:undo_ftplugin = 'setl fo< cms< com< fdm<'

"lua ionide = require("ionide")

" load configurations
call fsharp#loadConfig()

" F# specific bindings
com! -buffer FSharpReloadWorkspace call fsharp#reloadProjects()
com! -buffer FSharpShowLoadedProjects call fsharp#showLoadedProjects()
com! -buffer -nargs=* -complete=file FSharpLoadProject call fsharp#loadProject(<f-args>)
com! -buffer FSharpUpdateServerConfig call fsharp#updateServerConfig()
com! -buffer -nargs=1 FsiEval call fsharp#sendFsi(<f-args>)
com! -buffer FsiEvalBuffer call fsharp#sendAllToFsi()
com! -buffer FsiReset call fsharp#resetFsi()
com! -buffer FsiShow call fsharp#toggleFsi()

if g:fsharp#fsi_keymap != "none"
    execute "vnoremap <silent>" g:fsharp#fsi_keymap_send ":call fsharp#sendSelectionToFsi()<cr><esc>"
    execute "nnoremap <silent>" g:fsharp#fsi_keymap_send ":call fsharp#sendLineToFsi()<cr>"
    execute "nnoremap <silent>" g:fsharp#fsi_keymap_toggle ":call fsharp#toggleFsi()<cr>"
    execute "tnoremap <silent>" g:fsharp#fsi_keymap_toggle "<C-\\><C-n>:call fsharp#toggleFsi()<cr>"
endif

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: sw=4 et sts=4

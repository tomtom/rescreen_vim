" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @GIT:         http://github.com/tomtom/rescreen_vim
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    21
" GetLatestVimScripts: 0 0 :AutoInstall: rescreen.vim

if &cp || exists("loaded_rescreen")
    finish
endif
let loaded_rescreen = 1

let s:save_cpo = &cpo
set cpo&vim


" :display: :Rescreen[!] [OPTIONS] [REPLTYPE] [CMD]
" Prepare a session using REPLTYPE for the current buffer. If no 
" REPLTYPE is given, use the default repl (see |g:rescreen#repltype_map|).
" This command can also be used to switch between REPLs.
"
" Send CMD to the repl. CMD is also used to define the session name.
"
" With a optional bang (!), start the session immediatly.
"
" Arguments can also be passed as OPTIONS:
"   -[no-]default ... The current buffer's default repl
"   -[no-]wait    ... Wait for the user to press ENTER when done
"   -repltype=REPLTYPE
"   -mode=MODE
command! -bang -nargs=* Rescreen let b:rescreen = rescreen#Init(!empty('<bang>'), rescreen#Args2Dict([<f-args>]))


augroup ReScreen
    autocmd!
augroup END


let &cpo = s:save_cpo
unlet s:save_cpo

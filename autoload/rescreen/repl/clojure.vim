" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    25


let s:prototype = {} "{{{2


function! s:prototype.ExitRepl() dict "{{{3
    if empty(get(self, 'lein_project', ''))
        call self.rescreen.EvaluateInSession('(System/exit 0)', '')
    else
        call self.rescreen.EvaluateInSession('(quit)', '')
    endif
    sleep 1
endf


" Set the repl to "lein repl" if the current buffer seems to be part of 
" a lein project, i.e. if there is a project.clj around. Otherwise 
" clojure is used.
"
" The working directory has to be set properly -- either by means of 
" 'autochdir' or by |:chdir|.
function! rescreen#repl#clojure#Extend(dict) "{{{3
    let a:dict.repl_handler = s:prototype
    let a:dict.repl_handler.lein_project = findfile('project.clj', '.;')
    " TLogVAR a:dict.lein_project
    if !empty(a:dict.repl_handler.lein_project)
        let a:dict.repldir = fnamemodify(a:dict.repl_handler.lein_project, ':p:h')
        let a:dict.repl = 'lein repl'
    endif
endf


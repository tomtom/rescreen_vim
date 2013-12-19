" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    16


" Set the repl to "lein repl" if the current buffer seems to be part of 
" a lein project, i.e. if there is a project.clj around. Otherwise 
" clojure is used.
"
" The working directory has to be set properly -- either by means of 
" 'autochdir' or by |:chdir|.
function! rescreen#repl#clojure#Extend(dict) "{{{3
    let lein_project = findfile('project.clj', '.;')
    " TLogVAR lein_project
    if !empty(lein_project)
        let a:dict.repldir = fnamemodify(lein_project, ':p:h')
        let a:dict.repl = 'lein repl'
    endif
endf


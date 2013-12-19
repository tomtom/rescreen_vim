" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    10


function! rescreen#repl#clojure#Extend(dict) "{{{3
    let lein = findfile('project.clj', '.;')
    " TLogVAR lein
    if !empty(lein)
        let a:dict.repldir = fnamemodify(lein, ':p:h')
        let a:dict.repl = 'lein repl'
    endif
endf


" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Revision:    849


let s:windows = has('win16') || has('win32') || has('win64') || has('win95')


if !exists('g:rescreen#mapleader')
    " Map leader used in |g:rescreen#maps|.
    let g:rescreen#mapleader = '<localleader>e'   "{{{2
endif


if !exists('g:rescreen#maps')
    " Key maps.
    " :read: let g:rescreen#maps = {...}   "{{{2
    let g:rescreen#maps = {
                \ 'send': '<c-cr>',
                \ 'op': g:rescreen#mapleader,
                \ }
endif


if !exists('g:rescreen#encoding')
    " If non-empty, use |iconv()| to recode input.
    let g:rescreen#encoding = ''   "{{{2
endif


if !exists('g:rescreen#cmd')
    " The name of the screen executable.
    " If the variable is user-defined, trust its value.
    let g:rescreen#cmd = executable('screen') ? 'screen' : ''  "{{{2
    if empty(g:rescreen#cmd)
        throw "rescreen: screen is not executable (see g:rescreen#cmd):" g:rescreen#cmd
    endif
endif


if !exists('g:rescreen#repltype_map')
    " A map REPLTYPE => REPL. The key "*" defines the default/fallback REPL.
    " REPLTYPE defaults to 'filetype'.
    " :read: let g:rescreen#repltype_map = {...}   "{{{2
    let g:rescreen#repltype_map = {
                \ '*': 'bash',
                \ 'clojure': 'clojure',
                \ 'python': 'python',
                \ 'ruby': 'irb',
                \ 'scala': 'scala',
                \ 'sh': 'bash',
                \ 'r': s:windows ? 'R --ess' : 'R',
                \ 'tcl': 'tclsh',
                \ }
endif


if !exists('g:rescreen#session_name_expr')
    " A vim expression that is |eval()|uated to get the session name.
    let g:rescreen#session_name_expr = '"rescreen_'. v:servername .'_". self.repl'   "{{{2
endif


if !exists('g:rescreen#shell')
    " The shell and terminal used to run |g:rescreen#cmd|.
    " If GUI is running, also start a terminal.
    "
    " Default values with GUI running:
    "     Windows :: mintty
    "     Linux :: gnome-terminal
    let g:rescreen#shell =  ''   "{{{2
    if has('gui_running')
        if s:windows
            if executable('mintty')
                let g:rescreen#shell = ' start "" mintty.exe %s'
            elseif executable('powershell')
                let g:rescreen#shell = ' start "" powershell.exe -Command %s'
            else
                let g:rescreen#shell = ' start "" cmd.exe /C %s'
            endif
        elseif executable('gnome-terminal')
            let g:rescreen#shell = 'gnome-terminal -x %s &'
        endif
    endif
endif


if !exists('g:rescreen#init_wait')
    " How long to wait after starting the terminal.
    let g:rescreen#init_wait = 1   "{{{2
endif


if !exists('g:rescreen#wait')
    " How long to wait after executing a command.
    let g:rescreen#wait = '500m'   "{{{2
endif


if !exists('g:rescreen#clear')
    " If true, always clear the screen before evaluating some input.
    let g:rescreen#clear = 0   "{{{2
endif


if !exists('g:rescreen#sep')
    " Number of empty lines to separate commands.
    let g:rescreen#sep = 0   "{{{2
endif


if !exists('g:rescreen#send_after')
    " A key sequence sent to the terminal via screen's stuff command 
    " after evaluating input.
    let g:rescreen#send_after = '\15\15'   "{{{2
endif


if !exists('g:rescreen#timeout')
    " Timeout when waiting for a command to finish to retrieve 
    " its output.
    let g:rescreen#timeout = 5   "{{{2
endif


if !exists('g:rescreen#maxsize')
    let g:rescreen#maxsize = 2048   "{{{2
endif


" For use as an operator. See 'opfunc'.
function! rescreen#Operator(type, ...) range "{{{3
    " TLogVAR a:type, a:000
    let sel_save = &selection
    let &selection = "inclusive"
    let reg_save = @@
    try
        if a:0
            let text = s:GetSelection("o")
        elseif a:type == 'line'
            let text = s:GetSelection("o", "'[", "']", 'lines')
        elseif a:type == 'block'
            let text = s:GetSelection("o", "'[", "']", 'block')
        else
            let text = s:GetSelection("o", "'[", "']")
        endif
        " TLogVAR text
        call rescreen#Send(text)
    finally
        let &selection = sel_save
        let @@ = reg_save
    endtry
endf


" :display: s:GetSelection(mode, ?mbeg="'<", ?mend="'>", ?opmode='selection')
" mode can be one of: selection, lines, block
function! s:GetSelection(mode, ...) range "{{{3
    if a:0 >= 2
        let mbeg = a:1
        let mend = a:2
    else
        let mbeg = "'<"
        let mend = "'>"
    endif
    let opmode = a:0 >= 3 ? a:3 : 'selection'
    let l0   = line(mbeg)
    let l1   = line(mend)
    let text = getline(l0, l1)
    let c0   = col(mbeg)
    let c1   = col(mend)
    " TLogVAR mbeg, mend, opmode, l0, l1, c0, c1
    " TLogVAR text[-1]
    " TLogVAR len(text[-1])
    if opmode == 'block'
        let clen = c1 - c0
        call map(text, 'strpart(v:val, c0, clen)')
    elseif opmode == 'selection'
        if c1 > 1
            let text[-1] = strpart(text[-1], 0, c1 - (a:mode == 'o' || c1 > len(text[-1]) ? 0 : 1))
        endif
        if c0 > 1
            let text[0] = strpart(text[0], c0 - 1)
        endif
    endif
    return text
endf


let s:tempfile = ''


let s:prototype = {
            \ 'convert_path': has('win32unix') ? 'cygpath -m %s' : '',
            \ 'initial_screen_args': '',
            \ 'quitter': '',
            \ 'repltype': '',
            \ 'WrapResultPrinter': '',
            \ 'WrapResultWriter': '',
            \ }


function! s:prototype.InitBuffer() dict "{{{3
    if !exists('b:rescreens')
        let b:rescreens = {}
    endif
    if empty(self.repltype)
        let self.repltype = empty(&l:filetype) ? '*' : &l:filetype
    endif
    if has_key(b:rescreens, self.repltype)
        return b:rescreens[self.repltype]
    else
        let self.repl = get(g:rescreen#repltype_map, self.repltype, g:rescreen#repltype_map['*'])
        let session_name = eval(g:rescreen#session_name_expr)
        let self.session_name = substitute(session_name, '\W', '_', 'g')
        command! -bar -buffer -bang Requit if empty('<bang>') | call rescreen#Exit() | else | call rescreen#ExitAll() | endif
        command! -buffer -nargs=1 Resend call rescreen#Send([<q-args>])
        let map_send = get(g:rescreen#maps, 'send', '')
        if !empty(map_send)
            exec 'nnoremap <buffer>' map_send ':call rescreen#Send(getline("."))<cr>'
            exec 'inoremap <buffer>' map_send '<c-\><c-o>:call rescreen#Send(getline("."))<cr>'
            exec 'xnoremap <buffer>' map_send ':call rescreen#Send(<SID>GetSelection("v"))<cr>'
        endif
        let map_op = get(g:rescreen#maps, 'op', '')
        if !empty(map_op)
            exec 'nnoremap <buffer> '. map_op .' :set opfunc=rescreen#Operator<cr>g@'
            exec 'xnoremap <buffer> '. map_op .' :call rescreen#Send(<SID>GetSelection("v"))<cr>'
        endif
        " TLogVAR self.repltype
        let b:rescreens[self.repltype] = self
        return self
    endif
endf


function! s:prototype.ExitRepl() dict "{{{3
    let rv = 0
    if self.SessionExists(0, '.')
        if !empty(self.quitter)
            call self.EvaluateInSession(self.quitter, '')
        endif
        call self.RunScreen('-X eval "msgwait 5" "msgminwait 1"')
        call self.RunScreen('-X kill')
        let rv = 1
        " if !s:reuse
        "     call self.RunScreen('-wipe '. self.session_name)
        " endif
        if !empty(s:tempfile) && filereadable(s:tempfile)
            call delete(s:tempfile)
        endif
        call remove(b:rescreens, self.repltype)
    endif
    return rv
endf


" input  ... a list of lines for input
" mode  ... r ... read the result
"           x ... evaluate as is
function! s:prototype.EvaluateInSession(input, mode) dict "{{{3
    " TLogVAR a:input, a:mode
    call self.EnsureSessionExists()
    if empty(s:tempfile)
        let s:tempfile = substitute(tempname(), '\\', '/', 'g')
    endif
    let input = repeat([''], g:rescreen#sep) + self.PrepareInput(a:input, a:mode)
    " TLogVAR input
    let cmd0 = '-X eval '
                \ . ' "msgminwait 0"'
                \ . ' "msgwait 0"'
                \ . (g:rescreen#clear ? ' "at '. self.session_name .' clear"' : '')
                \ . printf(' "bufferfile ''%s''"', s:tempfile)
                \ . ' readbuf'
                \ . ' "at '. self.session_name .' paste ."'
    " \ . ' "at '. self.session_name .' redisplay"'
    " TLogVAR cmd0
    let parts = []
    let part = []
    let part_size = 0
    for line in input
        let llen = strlen(line)
        if part_size + llen > g:rescreen#maxsize
            call add(parts, part)
            let part = []
            let part_size = 0
        endif
        call add(part, line)
        let part_size += llen
    endfor
    call add(parts, part)
    " echo "DBG Rescreen: Sending input ... Please wait"
    let result = []
    for part in parts
        " TLogVAR part
        call writefile(part, s:tempfile)
        let ftime = getftime(s:tempfile)
        let fsize = getfsize(s:tempfile)
        if a:mode == 'r'
            let cmd = cmd0
        else
            let cmd = cmd0 . printf(' "register a rescreen%s"', fsize == 4 ? '_' : '')
                        \ . ' "paste a ."'
                        \ . ' writebuf'
        endif
        " TLogVAR cmd
        call self.RunScreen(cmd)
        for i in range(g:rescreen#timeout * 5)
            sleep 200m
            " echom "DBG Evaluate" filereadable(s:tempfile) ftime getftime(s:tempfile) fsize getfsize(s:tempfile)
            " echom "DBG Evaluate" string(input) string(readfile(s:tempfile))
            if fsize != getfsize(s:tempfile) || ftime != getftime(s:tempfile)
                        \ || (a:mode == 'r' && i % 5 == 0 && readfile(s:tempfile) != input)
                if a:mode == 'r'
                    let result += readfile(s:tempfile)
                    " TLogVAR 1, len(result)
                    break
                else
                    break
                endif
            endif
        endfor
    endfor
    if !empty(g:rescreen#send_after)
        " TLogVAR g:rescreen#send_after
        call self.RunScreen('-X "stuff '. escape(g:rescreen#send_after, '"') .'"')
    endif
    " redraw
    " echo
    " TLogVAR result
    return join(result, "\n")
endf


function! s:prototype.Filename(filename) dict "{{{3
    if empty(self.convert_path)
        return a:filename
    else
        let cmd = printf(self.convert_path, shellescape(a:filename))
        let filename = system(cmd)
        " TLogVAR cmd, filename
        return filename
    endif
endf


function! s:prototype.GetScreenCmd(type, screen_args) dict "{{{3
    " TLogVAR a:initial, a:screen_args
    let eval = '-X eval'
    let shell = 0
    if a:type =~ '^i\%[nitial]$'
        if has("gui_running") || !empty(g:rescreen#shell)
            let shell = 1
            let cmd = [
                        \ g:rescreen#cmd,
                        \ self.GetSessionParams(),
                        \ '-t '. self.session_name
                        \ ]
            " if !s:reuse
            "     call add(cmd, '-d -R')
            " endif
            " call add(cmd, '-X partial on')
        elseif $TERM =~ '^screen'
            let cmd = [g:rescreen#cmd,
                        \ self.GetSessionParams(),
                        \ eval,
                        \ '"title vim"',
                        \ '"screen -t '. self.session_name .'" "at '. self.session_name .' split" focus "select '. self.session_name .'"',
                        \ 'focus "select vim"'
                        \ ]
        else
            throw 'Rescreen: You have to run vim within screen or set g:rescreen#shell'
        endif
        let initial_screen_args = get(self, 'initial_screen_args', '')
        if !empty(initial_screen_args)
            if type(initial_screen_args) == e
                let cmd += initial_screen_args
            else
                call add(cmd, initial_screen_args)
            endif
        endif
    else
        let cmd = [
                    \ g:rescreen#cmd,
                    \ self.GetSessionParams(),
                    \ ]
    endif
    if !empty(a:screen_args)
        let eval_arg = a:screen_args =~ '\V\^'. eval .'\>'
        " TLogVAR eval_arg, eval, a:screen_args
        if a:screen_args[0:0] == '-'
            call add(cmd, a:screen_args)
        else
            call add(cmd, eval)
            call add(cmd, '"at '. self.session_name .' '. escape(a:screen_args, '''"\') .'"')
        endif
    endif
    let cmdline = join(cmd)
    if shell
        let cmdline = printf(g:rescreen#shell, cmdline)
    endif
    " TLogVAR cmdline
    return cmdline
endf


function! s:prototype.GetSessionParams() dict "{{{3
    return has('gui_running') ? ('-D -R -S '. self.session_name) : ''
endf


function! s:prototype.SessionExists(...) dict "{{{3
    let sessions = call(self.GetSessions, a:000, self)
    return !empty(sessions)
endf


function! s:prototype.GetSessions(use_cached, ...) dict "{{{3
    if !exists('s:sessions_list') || !a:use_cached
        let s:sessions_list = split(system(g:rescreen#cmd .' -list'), '\n')
    endif
    let sessions = copy(s:sessions_list)
    if a:0 == 0
        let filters = '.'
    else
        let filters = a:000
    endif
    for filter in filters
        if filter == "."
            let filter = self.session_name
        endif
        let sessions = filter(sessions, 'v:val =~ filter')
    endfor
    return sessions
endf


function! s:prototype.EnsureSessionExists(...) dict "{{{3
    let rv = 0
    let ok = self.SessionExists(0, '.')
    if !ok
        let repl = a:0 >= 1 ? a:1 : self.repl
        " TLogVAR repl
        call self.StartSession()
        if !empty(repl)
            call self.EvaluateInSession(repl, 'x')
        endif
        let rv = 1
    endif
    return rv
endf


function! s:prototype.StartSession() dict "{{{3
    let cmd = self.GetScreenCmd('init', '')
    " TLogVAR cmd
    if !empty(cmd)
        exec 'silent! !'. cmd
        if has("gui_running")
            if !empty(g:rescreen#shell)
                exec 'sleep' g:rescreen#init_wait
            endif
        else
            redraw!
        endif
    endif
    call self.RunScreen('-wipe')
endf


function! s:prototype.RunScreen(screen_args) dict "{{{3
    " TLogVAR a:screen_args
    let cmd = self.GetScreenCmd('', a:screen_args)
    " TLogVAR cmd
    if has("win32unix")
        exec 'silent! !'. cmd
        let rv = ''
    else
        let rv = system(cmd)
    endif
    " exec 'sleep' g:rescreen#wait
    " TLogVAR rv
    return rv
endf


function! s:prototype.PrepareInput(input, mode) dict "{{{3
    if type(a:input) == 3
        let input = a:input
    else
        let input = split(a:input, '\n')
    endif
    if has('+iconv') && !empty(g:rescreen#encoding) && &l:encoding != g:rescreen#encoding
        try
            call map(input, 
                        \ printf('iconv(v:val, %s, %s)',
                        \     string(&l:encoding),
                        \     string(g:rescreen#encoding)))
        catch
            echoerr "Rescreen: Error when encoding input: Check the value of g:rescreen#encoding:" v:errormsg
        endtry
    endif
    if a:mode == 'p'
        if !empty(self.WrapResultPrinter)
            let input = self.WrapResultPrinter(input)
        else
            throw 'rescreen: No support for printing results'
        endif
    elseif a:mode == 'r'
        if !empty(self.WrapResultWriter)
            let xtempfile = self.Filename(s:tempfile)
            let input = self.WrapResultWriter(input, xtempfile)
        else
            throw 'rescreen: No support for returning results'
        endif
    endif
    " TLogVAR input
    return input
endf


" Turn positional arguments into a dictionary. The arguments are:
"   0. repltype
function! rescreen#Args2Dict(args) "{{{3
    let argd = {}
    if !empty(a:args)
        let argn = ['repltype']
        for i in range(0, len(argn) - 1)
            let name = argn[i]
            let val = a:args[i]
            let argd[name] = val
        endfor
    endif
    return argd
endf


function! rescreen#Init(...) "{{{3
    let argd = a:0 >= 1 ? a:1 : {}
    " TLogVAR argd
    if !exists('b:rescreen') || (has_key(argd, 'repltype') && argd.repltype != b:rescreen.repltype)
        let rescreen = copy(s:prototype)
        let rescreen = extend(rescreen, argd)
        let b:rescreen = rescreen.InitBuffer()
    endif
    return b:rescreen
endf


function! rescreen#Exit() "{{{3
    if !exists('b:rescreen')
        return
    endif
    call b:rescreen.ExitRepl()
    unlet! b:rescreen
endf


function! rescreen#ExitAll() "{{{3
    if exists('b:rescreens')
        for [repltype, rescreen] in items(b:rescreens)
            call rescreen.ExitRepl()
        endfor
        unlet! b:rescreen b:rescreens
    endif
endf


" :display: rescreen#Send(lines, ?repltype = '*')
" Send lines to a REPL.
function! rescreen#Send(lines, ...) "{{{3
    let rescreen = call(function('rescreen#Init'), [rescreen#Args2Dict(a:000)])
    call rescreen.EvaluateInSession(a:lines, '')
endf


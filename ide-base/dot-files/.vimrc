""""""" VimRC configuration file based on Walt Woods' stuff """""""
" To use everything, you must:
" A. Copy this file as ~/.vimrc
" B. Install Vundle, which manages vim plugins, with the following command:
"
"    $ git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
"
" C. Open vim, and run :PluginInstall, wait for it to finish
" D. cd to ~/.vim/bundle/YouCompleteMe, and run ./install.sh
" E. Enjoy a good-looking, smooth-running VIM environment
"
" Ctags steps:
" 1. Edit ~/.ctags to include:
"         --extra=+f
"         --recurse=yes
"         --tag-relative=yes
"
" Use 't' to focus/blur the tagbar.  'enter' will show all references to a
" tag, and ctrl+t will bring you back before going to the reference.
"
" Use e.g. --exclude=*/.git/* to exclude unwanted listings.
"
" If your ~/.ctags file has custom languages, create a ~/.ctags.vimrc file next
" to it with contents like let g:tagbar_type_<lang> = ... (see tagbar
" documentation).
"
" ctags integration assumes section spacing (for e.g. LaTeX) is accomplished
" with dots and spaces (e.g., ".. Subsubsection") to the left.  Ctags
" integration for tab-completion also allows identifiers to be part of the tag
" (e.g., ".. <<sec:sub>>Subsubsection").
"
" Additionally, note that this file has been configured for heavy ctags
" integration; for instance, ctrl+p, if it finds a "tags" file, will use ctags
" to generate the list of files to search.  This was chosen instead of git
" deliberately, as it works with SVN as well, and can include auto-generated
" files that should not be in source control.


" TODO: Make plugin, use/recommend universal-ctags

if v:version < 705
    echom "Some features broken with vim version < 7.5"
endif

"""""""" Utility functions; next section is Plugin Management """"""""
func! s:GetScriptNumber(script_name)
    " https://stackoverflow.com/a/24027507/160205
    " Return the <SNR> of a script.
    "
    " Args:
    "   script_name : (str) The name of a sourced script.
    "
    " Return:
    "   (int) The <SNR> of the script; if the script isn't found, -1.

    redir => scriptnames
    silent! scriptnames
    redir END

    for script in split(l:scriptnames, "\n")
        if l:script =~ a:script_name
            return str2nr(split(l:script, ":")[0])
        endif
    endfor

    return -1
endfunc


func! s:PreviewNavigate(fpath, lineno, linepattern)
    " Tagbar is great, but the preview isn't.

    " Specifically, it is broken with some e.g. LaTeX bindings (pattern
    " doesn't match, should fall back to line numbers, doesn't).

    " Store current / previous window, preserve those
    let l:bufcur = win_getid()
    wincmd p
    let l:bufprev = win_getid()

	silent execute g:tagbar_previewwin_pos . ' pedit ' . fnameescape(a:fpath)

    let pid = 0
    for win in range(1, winnr('$'))
        if getwinvar(win, '&previewwindow')
            let pid = win
            break
        endif
    endfor
    execute pid . ' wincmd w'

    " Go to our reference
    echom a:lineno . '|$psearch! /' . a:linepattern . '/'
    silent! execute a:lineno . '|$psearch! /' . a:linepattern . '/'
    normal! zv
    normal! zz
    if g:tagbar_vertical != 0
        silent execute 'vertical resize ' . g:tagbar_width
    endif

    " Go back to previous window, then original window
    call win_gotoid(l:bufprev)
    call win_gotoid(l:bufcur)
endfunc


func! s:WinByBufname(bufname)
    " Utility function to get window index by name (must be unique match)
    " Thanks https://www.reddit.com/r/vim/comments/3aldvk/switch_to_a_split_depending_on_its_name/csdv7k8/
    let l:bufmap = map(range(1, winnr('$')), '[bufname(winbufnr(v:val)), v:val]')
    let l:thewindow = filter(l:bufmap, 'v:val[0] =~ a:bufname')
    if len(l:thewindow) > 0
        let l:thewindow = l:thewindow[0][1]
    else
        let l:thewindow = 0
    endif
    " use ":thewindow wincmd w" to go to the window
    return l:thewindow
endfunc

""""""" Plugin Management stuff """""""
set nocompatible
filetype off

let vimfolder = resolve($MYVIMRC) == resolve($HOME . '/.vimrc') ? $HOME . '/.vim' : fnamemodify($MYVIMRC, ':h')

exec  'set rtp+=' . vimfolder . '/bundle/Vundle.vim'
call vundle#begin(vimfolder . '/bundle')

Plugin 'gmarik/Vundle.vim'

Plugin 'wwoods/hexmode'
func! s:WWhexgoto(a, indexed)
    " Goto 1-based line, optionally with hex offset
    if a:a =~ "^0x"
        let a = str2nr(a:a[2:], 16)
    elseif a:a =~ "h$"
        let a = str2nr(a:a[:-1], 16)
    else
        let a = str2nr(a:a, 10)
    endif

    " Convert to 0-index
    let a = a - str2nr(a:indexed)

    " Each line starts with 8-byte address, followed by ": ", followed by
    " 8 tuples of type "xxxx ".
    " This means 16 bytes per line, and chars start at 52
    let boff = a % 16
    let bline = a / 16
    let b = bline * 68 + 52 + boff
    exec 'goto ' . b
    echom a . " -> " . b
endfunc
command -nargs=1 Hexgoto call s:WWhexgoto(<args>, 0)
command -nargs=1 Hexgoto1 call s:WWhexgoto(<args>, 1)

" Custom plugins AND configuration...

"""" EasyMotion - Allows <leader><leader>(b|e) to jump to (b)eginning or (end)
" of words.
Plugin 'easymotion/vim-easymotion'

"""" Ctrl-P - Fuzzy file search
Plugin 'kien/ctrlp.vim'
let g:ctrlp_root_markers = ['tags']
let g:ctrlp_user_command = ['tags', 'grep -P "F(\$|\t)" %s/tags | cut -f2 | sort -u', 'find %s -type f']

"""" :DirDiff -- diff two directories
Plugin 'will133/vim-dirdiff'

"""" Allows colorization
Plugin 'chrisbra/Colorizer'

"""" Json5
Plugin 'GutenYe/json5.vim'

"""" Mundo, for viewing undo tree per :MundoToggle
Plugin 'simnalamburt/vim-mundo'

"""" git integration (see g?)
Plugin 'tpope/vim-fugitive'
"Plugin 'junegunn/gv.vim'  Retired in favor of custom plugin... need to clean
"everything up though.

" Hack Gstatus command to bind d to Gvdiff only
func! s:WWgstatus()
    let l:vdiff = maparg('dv')
    let l:base = ""
    let l:base = l:base . ":nunmap <buffer> dv\<cr>"
    let l:base = l:base . ":nunmap <buffer> dp\<cr>"
    let l:base = l:base . ":nunmap <buffer> ds\<cr>"
    let l:base = l:base . ":nunmap <buffer> dh\<cr>"
    let l:base = l:base . ":nunmap <buffer> dd\<cr>"
    nnoremap <buffer> d :call <SID>WWgstatus_diffFile()<cr>
    "let l:base = l:base . ":nnoremap <buffer> d " . l:vdiff . ":execute 'normal! ' . g:WWgdiff()<cr>\<cr>"
    ". s:WWgdiff()
    "echo(substitute(l:base, "\<cr>", ' CR ', 'g'))
    return l:base
endfunc
func! s:WWgstatus_diffFile()
    let l:fugitive_scr = s:GetScriptNumber('fugitive.vim')
    execute 'let [filename, status] = <SNR>' . l:fugitive_scr . '_stage_info(line("."))'
    if empty(l:filename)
        return
    endif
    let l:staged = v:false
    if l:status == 'staged'
        let l:staged = v:true
    endif
    call s:WWgdiff_file(l:filename, 'HEAD', '', l:staged, v:false, v:false)
endfunc
func! g:WWgdiff()
    return s:WWgdiff()
endfunc
func! s:WWgdiff()
    " Executed after Gvdiff; current selection is main window, but without
    " other operations, it will change once vim-fugitive is done on the next
    " tick.
    " h - left, l - right
    let l:win = winnr()
    let l:diff2 = s:WinByBufname('.git//0/')
    if l:diff2
        " 2-way diff
        execute l:diff2 . " wincmd w"
        set ro
        set nomodifiable
        nnoremap <buffer> q :q<cr>
        execute l:win . " wincmd w"
    else
        " 3-way diff... expect //2 and //3
        echo 'TODO 3-way MERGE'
        sleep 5000ms
    endif
endfunc
nnoremap g? :echo "
            \vim-fugitive key bindings:\n
            \gs - :Gstatus (has its own g? screen; '-' to add/reset staging;\n
            \        however, 'd' has been rebound to an improved Gvdiff, as below)\n
            \gb - :Git blame\n
            \gd - git diff working tree against HEAD.\n
            \gl - git log help.\n
            \gla - git log all.\n
            \glf - git log current file.\n
            \"<cr>
nnoremap <silent> gb :Git blame<cr>
nnoremap <silent> gd :call <SID>WWgdiff_file('', 'HEAD', '', v:false, v:false, v:false)<cr>
nmap <silent> gl g?
nnoremap <silent> gla :call <SID>WWglog('--all')<cr>
nnoremap <silent> glf :call <SID>WWglog('')<cr>
nnoremap <silent> gs :Gstatus<cr>:execute "normal! " . <SID>WWgstatus()<cr>

func! s:WWglog(all)
    " Function for displaying and navigating the git log
    if empty(a:all)
        let l:file = expand('%:p')
        let l:fileshort = expand('%:p:.')
        let l:all = ''
    else
        let l:file = ''
        let l:fileshort = ''
        let l:all = '--all'
    endif

    tabnew
    setlocal buftype=nofile bufhidden=wipe noswapfile
    let b:logAll = a:all
    let l:cmd = 'git log --graph ' . l:all . ' --abbrev-commit --decorate --format=format:"%h - (%as) %s - %an%d" -- ' . l:file
    execute 'read !' . escape(l:cmd, '%')
    execute '0'
    normal! dd
    " Move tags to same indentation but start of line
    silent! execute '%s/\v([\/\\| \t]*(\*[\/\\| \t]*[0-9a-f]+ - )?)(.*)(\([^)]*\))$/\=substitute(submatch(1), ".", " ", "g") . submatch(4) . "\r" . submatch(1) . submatch(3)/g'
    setlocal nomodifiable nowrap cursorline
    execute '0'
    silent! execute 'file ' . escape('//git/log' . (empty(l:file) ? '' : ' ' . l:fileshort), ' ')

    " Syntax setup
    setf wwglog
    syn clear
    syn match wwglogBranches /\v[\/\\| \t]*(\*[\/\\| \t]*|\s*$)/ nextgroup=wwglogSha
    syn match wwglogSha /\v[0-9a-f]+/ contained nextgroup=wwglogHyphen
    syn match wwglogHyphen / - / contained nextgroup=wwglogDate
    syn match wwglogDate /\v\([^)]+\)/ contained
    syn match wwglogTags /\v\([^)]+\)$/

    hi def link wwglogBranches Number
    hi def link wwglogSha Identifier
    hi def link wwglogDate Type
    hi def link wwglogTags Statement

    " Bind the keys for viewing the log
    nnoremap <silent> <buffer> g? :echo "
            \git graph bindings (no 'g' prefix needed):\n
            \g? - This help\n
            \d - Diff working tree against given commit\n
            \b - Diff working tree against given commit, ignoring whitespace (-b)\n
            \w - Diff working tree against given commit, diff by word rather than line (--word-diff)\n
            \r - Rebase HEAD off the selected commit\n
            \Left arrow or h - Skip left 80 chars\n
            \Right arrow or l - Skip right 80 chars\n
            \Return - View commit\n
            \q - Quit\n
            \"<cr>
    nnoremap <silent> <buffer> q :q!<cr>
    nnoremap <silent> <buffer> <cr> :call <SID>WWglog_viewCommit('', b:file)<cr>
    nnoremap <silent> <buffer> <space> :call <SID>WWglog_viewCommit('', b:file)<cr>
    let b:file = l:file
    nnoremap <silent> <buffer> d :call <SID>WWglog_viewCommit('diff', b:file)<cr>
    nnoremap <silent> <buffer> b :call <SID>WWglog_viewCommit('diffb', b:file)<cr>
    nnoremap <silent> <buffer> w :call <SID>WWglog_viewCommit('diffw', b:file)<cr>
    nnoremap <silent> <buffer> r :call <SID>WWglog_rebaseCommit()<cr>
    nnoremap <silent> <buffer> <left> 80h
    nnoremap <silent> <buffer> h 80h
    nnoremap <silent> <buffer> <right> 80l
    nnoremap <silent> <buffer> l 80l
endfunc
func! s:WWglog_getCommit()
    " Gets commit hash for current log line
    let l:line = getline('.')
    let l:commit = matchlist(l:line, '\v[|\\/ \t]*\*[|\\/ \t]*(\[[0-9;]*m)?([0-9a-f]+)')
    if empty(l:commit)
        return ''
    endif
    let l:commit = l:commit[2]
    return l:commit
endfunc
func! s:WWglog_refresh()
    " Refreshes the graph view
    let l:all = b:logAll
    normal q
    call s:WWglog(l:all)
endfunc
func! s:WWglog_rebaseCommit()
    let l:commit = s:WWglog_getCommit()
    if empty(l:commit)
        return
    endif
    silent! execute '!git rebase -i ' . l:commit
    call s:WWglog_refresh()
endfunc
func! s:WWgdiff_quit(forced)
    " Called when a new buffer is entered or q is pressed
    let l:pastwin = g:WWgdiff_winPast
    let l:mainwin = g:WWgdiff_winMain
    let l:nextwin = g:WWgdiff_winNext
    let l:curwin = win_getid()

    if winbufnr(l:mainwin) != -1
        call win_gotoid(l:mainwin)
        if &modified
            if a:forced
                " We are going to quit anyway, nothing can be done
            else
                echom "Cannot quit; unsaved changes!"
                call win_gotoid(l:mainwin)
                return
            endif
        endif
    endif

    " Definitly going to close diff, proceed
    augroup WWgdiff_quit
        autocmd!
    augroup END

    let winsToClose = [l:pastwin, l:nextwin]
    if g:WWgdiff_winCloseMain
        call add(winsToClose, l:mainwin)
    else
        call win_gotoid(l:mainwin)
        " Unmap keys
        nunmap <buffer> q
        nunmap <buffer> g?
        nunmap <buffer> g<
        nunmap <buffer> g>
    endif
    for win in winsToClose
        if winbufnr(win) == -1
            continue
        endif

        call win_gotoid(win)
        silent! execute 'q'
    endfor

    unlet g:WWgdiff_winMain
    unlet g:WWgdiff_winPast
    unlet g:WWgdiff_winNext

    diffoff!
endfunc
func! s:WWgdiff_quitMaybe()
    " Called when window changed
    let l:pastwin = g:WWgdiff_winPast
    let l:mainwin = g:WWgdiff_winMain
    let l:nextwin = g:WWgdiff_winNext
    let l:curwin = win_getid()

    let l:exited = winbufnr(l:mainwin) == -1
                \ || winbufnr(l:pastwin) == -1
                \ || winbufnr(l:nextwin) == -1

    if l:curwin != l:pastwin
                \ && l:curwin != l:mainwin
                \ && l:curwin != l:nextwin
                \ || l:exited

        " Make sure the main window still exists; otherwise it's forced
        call s:WWgdiff_quit(l:exited)
    endif
endfunc
func! s:WWgdiff_file(file, commitLeft, commitRight, staged, notThreeWay, noWhitespace)
    " Parameters:
    " file - File to open, or empty for current window.
    " commitLeft - Left-side commit.
    " commitRight - Right-side commit, or empty for duplicate of file view.
    " staged - v:true if --cached should be specified.
    " noWhitespace - v:true to diff with -b enabled.
    if exists('g:WWgdiff_winMain')
        " Close another diff
        call s:WWgdiff_quit(v:true)
    endif

    let l:file = a:file
    let l:filerel = a:file
    let l:gitdir = fnamemodify(FugitiveExtractGitDir('.'), ':h')
    if !empty(l:file)
        " Open out working version as a split
        let l:file = fnamemodify(l:gitdir . '/' . a:file, ':p:.')
        if a:notThreeWay
            new
            silent! execute 'file ' . escape(l:file, ' ')
            filetype detect
        else
            silent! execute 'split ' . l:file
        endif
        let g:WWgdiff_winCloseMain = v:true
    else
        "File already open
        let l:file = expand('%:p')
        let l:filerel = l:file[strlen(fnamemodify(l:gitdir, ':p')):]
        let l:file = fnamemodify(l:file, ':.')
        let g:WWgdiff_winCloseMain = v:false
    endif

    let l:filetype = &filetype
    let l:splitter = &splitright
    let l:mainwin = win_getid()

    if !a:notThreeWay
        " New pane for next version, turn diffing on in main pane
        diffthis

        set splitright
        vertical new
    else
        " Use main pane for next version
    endif
    " Diff against the current version, frozen
    setlocal buftype=nofile bufhidden=wipe noswapfile
    execute 'setlocal filetype=' . l:filetype
    if a:noWhitespace
        setlocal diffopt+=iwhite
    else
        setlocal diffopt-=iwhite
    endif
    let l:nextwin = win_getid()
    if empty(a:commitRight)
        call win_gotoid(l:mainwin)
        execute '%y'
        call win_gotoid(l:nextwin)
        normal! p
    else
        let l:cmd = 'git show ' . a:commitRight . ':' . l:filerel
        silent! execute 'read !' . escape(l:cmd, '%')
    endif
    execute '0'
    normal! dd
    setlocal nomodifiable
    diffthis

    " Diff against the version before the commit
    call win_gotoid(l:mainwin)
    set nosplitright
    vertical new
    setlocal buftype=nofile bufhidden=wipe noswapfile
    execute 'setlocal filetype=' . l:filetype
    let l:cmd = 'git show ' . a:commitLeft . ':' . l:filerel
    silent! execute 'read !' . escape(l:cmd, '%')
    execute '0'
    normal! dd
    setlocal nomodifiable
    diffthis
    let l:pastwin = win_getid()

    let &splitright = l:splitter

    " Store window ID, go back to main file
    call win_gotoid(l:mainwin)
    let g:WWgdiff_winPast = l:pastwin
    let g:WWgdiff_winMain = l:mainwin
    let g:WWgdiff_winNext = l:nextwin

    " Main buffer key presses
    nnoremap <silent> <buffer> q :call <SID>WWgdiff_quit(v:false)<cr>
    if a:notThreeWay
        nnoremap <silent> <buffer> g? :echo "
                \g? - This help.\n
                \q - Quit diff.\n
                \"<cr>
    else
        nnoremap <silent> <buffer> g? :echo "
                \g? - This help.\n
                \g< - Take left block.\n
                \g> - Take right block.\n
                \q - Quit diff.\n
                \"<cr>
        nnoremap <silent> <buffer> g< :execute 'diffget ' . winbufnr(g:WWgdiff_winPast)<cr>:diffupdate<cr>
        nnoremap <silent> <buffer> g> :execute 'diffget ' . winbufnr(g:WWgdiff_winNext)<cr>:diffupdate<cr>
    endif

    " Side buffer key presses
    call win_gotoid(l:pastwin)
    nnoremap <silent> <buffer> q :call <SID>WWgdiff_quit(v:false)<cr>
    call win_gotoid(l:nextwin)
    nnoremap <silent> <buffer> q :call <SID>WWgdiff_quit(v:false)<cr>

    " Return to main buffer
    call win_gotoid(l:mainwin)
    " Whenever the main buffer exits, quit them all.
    augroup WWgdiff_quit
        autocmd!
        autocmd WinEnter * call s:WWgdiff_quitMaybe()
        autocmd BufWritePost,FileWritePost <buffer> diffupdate
    augroup END

endfunc
func! s:WWglog_viewCommit(mode, file)
    " Function for viewing a given commit diff
    " Parameters:
    " mode - '' or 'diff'.  'diff' means against working tree.  'diffb' for
    "     diff against working tree but with -b enabled to hide whitespace
    "     changes.  'diffw' means diff against working tree with
    "     --word-diff=color.  Requires VIM version 8 or later.
    " file - '' or file path.  '' means all files.
    let l:commit = s:WWglog_getCommit()
    if empty(l:commit)
        return
    endif

    if !empty(a:mode) && !empty(a:file)
        call s:WWgdiff_file(a:file, l:commit, '', v:false, v:false, v:false)
        return
    endif

    let l:use_color = v:false
    let l:mode = a:mode
    let l:errormsg = ''
    if v:version < 800 && l:mode == 'diffw'
        let l:mode = 'diff'
        let l:errormsg = l:errormsg .  "--word-diff requires VIM version 8 or higher.  "
    endif

    if empty(l:mode)
        let l:title = '//git/show'
        let l:cmd = 'git show ' . l:commit . ' -- ' . a:file
    elseif l:mode == 'diff'
        let l:title = '//git/diff'
        let l:cmd = 'git diff --no-color ' . l:commit . ' -- ' . a:file
    elseif l:mode == 'diffb'
        let l:title = '//git/diff'
        let l:cmd = 'git diff -b --no-color ' . l:commit . ' -- ' . a:file
    elseif l:mode == 'diffw'
        let l:title = '//git/diff'
        let l:cmd = 'git diff --word-diff=color --word-diff-regex="[a-zA-Z0-9_]+|." ' . l:commit . ' -- ' . a:file
        let l:use_color = v:true
    else
        echom "ERROR: " . l:mode
        return
    endif

    new
    silent! execute 'file ' . escape(l:title . ' ' . l:commit, ' ')
    setlocal buftype=nofile bufhidden=wipe noswapfile
    silent! execute 'read !' . escape(l:cmd, '%')
    silent! execute '%s/diff --git .*/\0 {{{{{{1/g'

    execute '0'
    normal! dd

    " Syntax setup
    setf diff
    if l:use_color
        ColorHighlight!
        " Color highlighting can be lost when switching away; curiously,
        " re-upping it before leaving fixes the problem.
        autocmd BufLeave <buffer> :ColorHighlight!
        setlocal wrap
    else
        " For full-line diffs, wrap is not necessary
        setlocal nowrap
    endif
    "syn clear
    "syn match wwglogDiffAdded /\v^\+.*/
    "syn match wwglogDiffRemoved /\v^-.*/

    "hi def link wwglogDiffAdded Identifier
    "hi def link wwglogDiffRemoved Special

    " Fold configuration
    setlocal foldmethod=marker foldmarker={{{{{{,}}}}}}

    " Bind keys
    nnoremap <silent> <buffer> ? :echo "
            \? - This help\n
            \Enter or space - Expand / collapse diff segment\n
            \d - Diff a closed fold\n
            \q - Close the log view\n
            \"<cr>
    nnoremap <silent> <buffer> <cr> za
    nnoremap <silent> <buffer> <space> za
    execute 'nnoremap <silent> <buffer> d :call <SID>WWglog_viewCommit_diffFold("' . l:commit . '", "' . a:mode . '")<cr>'
    nnoremap <silent> <buffer> q :q!<cr>

    " Cleanup
    setlocal nomodifiable

    if !empty(l:errormsg)
        redraw | echom l:errormsg
    endif
endfunc
func! s:WWglog_viewCommit_diffFold(commit, mode)
    let line = getline('.')
    let m = matchlist(line, '\vdiff --git a/(.*[^\\]) b/')
    if empty(m)
        return
    endif

    let fname = m[1]
    if empty(a:mode)
        " Commit only
        call s:WWgdiff_file(fname, a:commit . '~1', a:commit, v:false, v:true, v:false)
    elseif a:mode == 'diffb'
        call s:WWgdiff_file(fname, a:commit, '', v:false, v:false, v:true)
    else
        " Diff from working tree
        call s:WWgdiff_file(fname, a:commit, '', v:false, v:false, v:false)
    endif
endfunc



"""" Autocomplete for python and others (IMPORTANT: To use,
" Core Python language autocomplete support
Plugin 'davidhalter/jedi-vim'

" Python code folding
"Plugin 'tmhedberg/SimpylFold'
" Remove extraneous whitespace when edit mode is exited
Plugin 'thirtythreeforty/lessspace.vim'
" The plugin "lessspace" by default does its magic on InsertLeave.
" Unfortunately, in combination with vim-tmux-focus-events, the <C-o> method
" of leaving insert mode is triggered when switching between panes, which
" causes InsertLeave, which isn't what we want.  So, re-work the bindings
" to get around this.
func! s:lessspace_fix(...)
    if !exists('g:loaded_lessspace_plugin')
        call timer_start(10, function('<SID>lessspace_fix'))
        return
    endif
    augroup LessSpace
        autocmd! InsertEnter
        autocmd! InsertLeave
        nnoremap <silent> a a<C-o>:call lessspace#OnInsertEnter()<CR>
        nnoremap <silent> ea ea<C-o>:call lessspace#OnInsertEnter()<CR>
        nnoremap <silent> A A<C-o>:call lessspace#OnInsertEnter()<CR>
        nnoremap <silent> i i<C-o>:call lessspace#OnInsertEnter()<CR>
        nnoremap <silent> I I<C-o>:call lessspace#OnInsertEnter()<CR>
        nnoremap <silent> o o<C-o>:call lessspace#OnInsertEnter()<CR>
        nnoremap <silent> O O<C-o>:call lessspace#OnInsertEnter()<CR>
        nnoremap <silent> s s<C-o>:call lessspace#OnInsertEnter()<CR>
        nnoremap <silent> S S<C-o>:call lessspace#OnInsertEnter()<CR>
        xnoremap <silent> I I<C-o>:call lessspace#OnInsertEnter()<CR><C-o>gvI
        " Added <C-e> to cancel any autocomplete
        inoremap <expr> <Esc> <SID>lessspace_esc_check()
    augroup END
endfunc
func! s:lessspace_esc_check()
    " Run <C-e> if pop up menu (PUM) is active; if it is, then <C-o> does not
    " have the same meaning until after <C-e>r
    let l:cmd = "\<C-o>:call lessspace#OnInsertExit()\<CR>\<Esc>"
    if complete_info().mode != ""
        let l:cmd = "\<C-e>" . l:cmd
    endif
    return l:cmd
endfunc
call s:lessspace_fix()

" General completer
" YouCompleteMe is awful to setup, and heavy handed. VimCompletesMe was great,
" but is unsupported as of early 2023. So, vim-mucomplete
" cd ~/.vim/bundle/YouCompleteMe and run ./install.sh)
"Plugin 'Valloric/YouCompleteMe'
"Plugin 'ajh17/VimCompletesMe'
Plugin 'lifepillar/vim-mucomplete'
set completeopt+=menuone
autocmd FileType *
            \ if &omnifunc == "" |
            \     let b:vcm_tab_complete='user' |
            \     setlocal completefunc=g:WWComplete_local |
            \ endif
func! g:WWComplete_local(findstart, base)
    if a:findstart == 1
        try
            if exists('b:WWComplete_pattern')
                throw 'escape_to_WWComplete'
            endif

            " Defer to language-aware when possible and not user-specified
            let l:sc_col = syntaxcomplete#Complete(1, '')
            return l:sc_col
        catch
            " Use word before cursor
            let l:searchpat = exists('b:WWComplete_pattern')
                    \ ? b:WWComplete_pattern
                    \ : '\k*'
            let l:searchpat = l:searchpat . '\V\%#'
            let l:start = searchpos(l:searchpat, 'bn', line('.'))[1]
            if l:start == 0
                let l:start = col('.')
            endif
            return l:start - 1
        endtry
    endif

    let l:results = []
    if !exists('b:WWComplete_pattern')
        try
            let l:sc_results = syntaxcomplete#Complete(0, a:base)
            let l:results = extend(l:results, l:sc_results)
        catch
        endtry
    endif

    " Add our results... case sensitive first
    let l:counted = {}
    let l:seen = {}
    let l:tags1 = taglist(a:base)
    let l:tags2 = taglist('\c' . a:base)
    if type(tags1) == 0 | let tags1 = [] | endif
    if type(tags2) == 0 | let tags2 = [] | endif
    let l:tags = extend(tags1, tags2)
    for l:tag in l:tags
        " Strip leading .'s and spaces
        let name = substitute(tag.name, '\v^[ .]+', '', 'g')

        " Filter out reference, if applicable
        let to_insert = name
        let to_insert_match = matchstr(name, '\v\<\<\zs[^>]*\ze\>\>')
        if !empty(to_insert_match)
            let to_insert = to_insert_match
        endif

        let record = get(l:seen, to_insert, 0)
        if type(record) == 0
            " New entry
            let record = {
                    \ 'word': to_insert,
                    \ 'abbr': name,
                    \ 'menu': {},
                    \ 'empty': 1
                    \ }
            let l:seen = extend(l:seen, {to_insert: record})
            let l:results = add(l:results, record)
        else
            " Extend entry; use longest matching name
            if len(name) > len(record.abbr)
                let record.abbr = name
            endif
        endif

        let uid = to_insert . '__' . tag.filename . '__' . tag.line
        if !has_key(l:counted, uid)
            let l:counted[uid] = 1
            let record.menu[tag.filename] = get(record.menu, tag.filename, 0)+1
        endif
    endfor

    " Process each unique results
    for l:result in values(seen)
        let menu = result.menu
        let mitems = items(menu)
        let mitems = sort(map(copy(mitems), '[v:val[1], v:val[0]]'))
        let result.menu = mitems[len(mitems)-1][1]
        if len(mitems) > 1
            let result.menu = result.menu . ' +' . (len(mitems)-1)
        endif
        let sum = 0
        for fmap in mitems
            let sum = sum + fmap[0]
        endfor
        let result.menu = result.menu . ' (' . sum . ')'
    endfor

    return l:results
endfunc

"""" ctags support (needs e.g. brew install ctags)
set tags=./tags;/
Plugin 'craigemery/vim-autotag'
Plugin 'majutsushi/tagbar'
"Plugin 'file:///u/wwoods/dev/vim-tagbar-revealmd'
Plugin 'wwoods/vim-tagbar-revealmd'

let g:tagbar_ctags_bin='ctags'
let g:tagbar_silent=1

func! s:WWTagbarOpen()
    " Called when <cr> pressed in the tagbar
    let l:tag = getline('.')
    if l:tag[0] == ' '
        wincmd p
        execute 'tjump ' . strpart(l:tag, 4)
    else
        normal o
    endif
endfunc
func! s:WWTagbar_preview()
    echom strpart(b:WWTagbar_oldpreview, 1, len(b:WWTagbar_oldpreview)-1-4)
    execute strpart(b:WWTagbar_oldpreview, 1, len(b:WWTagbar_oldpreview)-1-4)
    call getchar()
    pclose
endfunc
func! s:WWTagbarToggle()
    " Called to toggle the tagbar intelligently, and alter its functionality
    let l:cur = winnr()
    let l:tag = s:WinByBufname('Tagbar')

    if l:tag && l:cur != l:tag
        " Go to Tagbar after saving current
        if &modified
            write
        endif
        execute l:tag . ' wincmd w'
        return
    elseif l:tag
        " Go to previous
        wincmd p
        return
    endif

    " If we get here, it means open tagbar (but don't focus yet)
    if &modified
        write
    endif
    TagbarOpen
    if !s:WinByBufname('Tagbar')
        " Failed to open tagbar!
        return
    endif
    if !exists('b:WWTagbar_initialized')
        let b:WWTagbar_initialized=1

        let l:tag = s:WinByBufname('Tagbar')

        execute l:tag . ' wincmd w'
        let b:WWTagbar_tagscr = s:GetScriptNumber('tagbar/autoload/tagbar.vim')
        " Key bindings
        "nunmap <buffer> P
        "
        func! s:GetTagInfo()
            " Function to reach into tagbar's internals to get the tag info
            " for the current line.
            let pos = getpos('.')
            "echom string(pos)
            execute 'let l:taginfo = <SNR>' . b:WWTagbar_tagscr . '_GetTagInfo(pos[1], 1)'
            return l:taginfo
        endfunc
        func! s:PreviewTag(continued)
            " Function responsible for showing preview window AND moving the
            " previewed item.
            let l:taginfo = s:GetTagInfo()

            " Want to preview current line... is there anything?
            if !empty(l:taginfo)
                if has_key(l:taginfo, 'pattern')
                    call s:PreviewNavigate(l:taginfo.fileinfo.fpath,
                            \ l:taginfo.fields.line,
                            \ l:taginfo.pattern)
                endif
            endif

            " Regardless, highlight current line, and wait for input.
            normal! V
            redraw
            let l:char = getchar()
            normal! V
            if l:char == 32
                pclose
            elseif l:char == "\<down>" || nr2char(l:char) == "j"
                normal! j
                call s:PreviewTag(1)
            elseif l:char == "\<up>" || nr2char(l:char) == "k"
                normal! k
                call s:PreviewTag(1)
            elseif l:char == "\<left>" || nr2char(l:char) == "h"
                normal zc
                call s:PreviewTag(1)
            elseif l:char == "\<right>" || nr2char(l:char) == "l"
                normal zo
                call s:PreviewTag(1)
            elseif l:char == 13
                call s:GotoTag(l:taginfo)
            else
                pclose
            endif
        endfunc
        func! s:GotoTag(...)
            " Function to go to the specified tag or the tag for the current
            " line.  Corresponds to <CR> press.
            if a:0 >= 1
                let l:taginfo = a:1
            else
                let l:taginfo = s:GetTagInfo()
            endif

            pclose
            wincmd p
            execute l:taginfo.fields.line
            normal! zv
            normal! zz
        endfunc

        " Space - preview hacked to close on move
        nnoremap <buffer> <silent> <space> :<c-u>call <SID>PreviewTag(0)<cr>
        " Return - navigate to, with support for multiple
        nnoremap <buffer> <silent> <cr> :<c-u>call <SID>GotoTag()<cr>
        " Left/right should collapse/expand folds
        nmap <buffer> <silent> <left> zc
        nmap <buffer> <silent> <right> zo
        " TODO - WWTagbarOpen()<cr>.  Need some way to cross-reference between
        " files
        " / - Search tags with ctrl+P
        nnoremap <buffer> <silent> / :<c-u>wincmd p<cr>:CtrlPTag<cr>
    endif
    execute l:cur . ' wincmd w'
endfunc
nnoremap <silent> t :call <SID>WWTagbarToggle()<cr>
" Tagbar, while great, needs g:tagbar_type_<lang> defined on occasion...
exec 'source ' . fnamemodify($MYVIMRC, ':h') . '/.ctags.vimrc'

"""" Let FocusGained and FocusLost work when inside of tmux.
Plugin 'tmux-plugins/vim-tmux-focus-events'

"""" Screen splitter.  Use tmux instead!
"Plugin 'ervandew/screen'

"""" LaTeX editing
"LaTeX-Box works poorly in my experience.
" ctags with a few custom rules is better
"Plugin 'LaTeX-Box-Team/LaTeX-Box'

"However, spelling doesn't work in macros with builtin tex syntax.  Therefore,
"use the more modern "vimtex" as a compromise.

" Disable vimtex key mappings.  Otherwise, pressing e.g. '`' will wait for
" more input, which is annoying when quoting something.  Plus, all of the
" imaps don't really add any value...
let g:vimtex_mappings_enabled=0
let g:vimtex_imaps_enabled=0
"Plugin 'lervag/vimtex'

"""" Status bar mods
Plugin 'bling/vim-airline'
Plugin 'airblade/vim-gitgutter'

"""" Typescript formatting
Plugin 'leafgarland/typescript-vim'

"""" Dotfile viewing
Plugin 'wannesm/wmgraphviz.vim'


"""" Python typechecking
" BROKEN Plugin 'integralist/vim-mypy'
Plugin 'dense-analysis/ale'


" After all plugins...
call vundle#end()
filetype plugin indent on

""""""" General coding stuff """""""
" Highlight 81st column (touching this is too wide)
set colorcolumn=81
" Always show status bar
set laststatus=2
" Let plugins show effects after 500ms, not 4s
set updatetime=500
" Disable mouse click to go to position.  Unfortunately also disables resizing
" splits... as such, use ":set mouse=a (click) :set mouse-=a" to workaround.
set mouse-=a
if len($TMUX) > 0
    set ttymouse=xterm2
endif
" Let vim-gitgutter do its thing
let g:gitgutter_max_signs=10000
" Default indentation
set shiftwidth=4 tabstop=4 softtabstop=4 expandtab autoindent

" vim-conflicted version marker
set statusline+=%{ConflictedVersion()}

" Airline plugin can be quite slow with extensions, so turn those off.
let g:airline_extensions=[]
let g:airline_highlighting_cache=1

" Fix clipboard when no native support exists
if !has('clipboard')
    echoe 'VIM will not have clipboard access; see https://vi.stackexchange.com/a/96.  On e.g. Ubuntu, install vim-gnome to fix this.'
else
    " Set up clipboard to interface with OS by default.
    set clipboard=unnamedplus
endif

" Set terminal key timeout to be quite small, to prevent unnecessary delays in
" input sequences.
set ttimeoutlen=5

" Allow reloading a file that's not changed in vim but has been changed
" elsewhere.
set autoread
" Check if file changed on focus / buffer change.
autocmd FocusGained,BufEnter * :silent! checktime

autocmd FileType gitcommit setlocal spell

""""""" Python stuff """""""
syntax enable
set number showmatch
let python_highlight_all = 1
" See https://stackoverflow.com/a/37889460/160205.
" Basically, colon is a bit broken, so remove it.
autocmd FileType python setlocal indentkeys-=<:>
autocmd FileType python setlocal indentkeys-=:
" As of late 2021, new vim versions ship with a broken (in my opinion) python
" indenter, that unnecessarily aligns to parens. Fix that.
exec 'source ' . fnamemodify(resolve($MYVIMRC), ':h') . '/.vimrc.indent_python'
autocmd FileType python setlocal indentexpr=g:IndentPythonGetIndent(v:lnum)


""""""" ReStructuredText stuff """""""
autocmd FileType rst setlocal shiftwidth=2 tabstop=2 softtabstop=2


""""""" Typescript stuff """""""
autocmd BufNewFile,BufRead *.pug set filetype=pug
autocmd BufNewFile,BufRead *.vue set filetype=vue
autocmd BufNewFile,BufRead *.json5 set filetype=json5
autocmd FileType css,html,json,json5,scss,typescript,javascript,pug,vue,yaml setlocal shiftwidth=2 tabstop=2 softtabstop=2



""""""" Latex stuff """""""
autocmd FileType tex setlocal shiftwidth=2 tabstop=2 softtabstop=2
autocmd FileType tex setlocal spell
" LaTeX-Box indentation does not work well in practice
let g:tex_flavor = 'latex'


""""""" General appearance stuff """""""
colorscheme elflord
set hlsearch
set incsearch
set splitbelow


""""""" Basic VIM settings """""""
set nobackup
set noswapfile


""""""" Keybindings """""""
" Set up leaders
let mapleader=","
let maplocalleader="\\"

" Rewire the autocomplete popupmenu so that it won't do anything unless tab is
" pressed
"""""
"autocmd! BufNewFile,BufReadPre,FilterReadPre,FileReadPre *
"autocmd BufNewFile,BufReadPre,FilterReadPre,FileReadPre * let b:pum_arrows_disabled=1
"autocmd! CompleteDone *
"autocmd CompleteDone * call PumArrowsDisabledSet()
"func! PumArrowsDisabledSet()
"    if b:pum_arrows_disabled==0
"        " Was in menu, make sure preview is closed
"        execute "pclose"
"    endif
"    let b:pum_arrows_disabled=1
"endfunc
"func! PumArrowsDisabledUnset(key)
"    let b:pum_arrows_disabled=0
"    return a:key
"endfunc
"func! PumArrowsReturn()
"    "Used because if the menu isn't selected, it takes two returns to close
"    "and go down a line, but if it is selected, it only takes one.
"    "
"    "We insert an extra letter on the new line to save the tab indentation
"    "through the :pclose operation.
"    let l:pum = b:pum_arrows_disabled
"    return "\<Return>" . (l:pum==1 ? "\<Return>" : "") . "j\<C-O>:pclose\<Return>\<Backspace>"
"endfunc
"inoremap <expr> <Tab> pumvisible() ? PumArrowsDisabledUnset("\<C-N>") : "\<Tab>"
"inoremap <expr> <S-Tab> pumvisible() ? PumArrowsDisabledUnset("\<C-P>") : "\<S-Tab>"
"inoremap <expr> <Down> pumvisible() ? (b:pum_arrows_disabled==1 ? "\<C-Y>\<Down>" : "\<C-N>") : "\<Down>"
"inoremap <expr> <Up> pumvisible() ? (b:pum_arrows_disabled==1 ? "\<C-Y>\<Up>" : "\<C-P>") : "\<Up>"
"inoremap <expr> <Return> pumvisible() ? PumArrowsReturn() : "\<Return>"
"
"" Fix pageup / pagedown
"inoremap <expr> <PageUp> pumvisible() ? "\<C-Y>\<PageUp>" : "\<PageUp>"
"inoremap <expr> <PageDown> pumvisible() ? "\<C-Y>\<PageDown>" : "\<PageDown>"
"
"" Disable YouCompleteMe's next/previous completion since we implement that
"" better
"let g:ycm_key_list_previous_completion=[]
"let g:ycm_key_list_select_completion=[]

" Mac OS X option-left / right
noremap â b
noremap æ e
inoremap â <C-o>b
inoremap æ <C-o>e<right>
" Note - this required binding in preferences (Cmd-,) option+backspace to
" escape+z.
" Why this one is complicated - <C-o> at end of line moves cursor by one
" character, which means a trailing character could be left.
inoremap <expr> ú col('.')>1 ? 'T<Left><C-o>"_db<Delete>' : '<Backspace>T<Left><c-o>"_db<Delete>'
" Requires binding option+forward delete to escape
inoremap ø <C-o>"_dw

" Linux / windows ctrl+backspace ctrl+delete
" Note that ctrl+backspace doesn't work in Linux :(
" Note that <C-w> doesn't work here, as it would stop at insert boundary:
" https://github.com/vim/vim/issues/964 .  Instead, rely on 'db', using <C-o>
" to access it.
set backspace=indent,eol,start
imap <C-backspace> <C-\>
inoremap <C-\> <C-\><C-o>"_db
imap <C-delete> <C-o>"_dw
" For terminals which emit <C-delete> as follows
imap <C-[>[3;5~ <C-o>"_dw

" Arrow keys up/down move visually up and down rather than by whole lines.  In
" other words, wrapped lines will take longer to scroll through, but better
" control in long bodies of text.
" NOTE - Disabled since <leader><leader>w|e|b works well with easymotion
"noremap <up> gk
"noremap <down> gj

" Build commands - run make with (ctrl-b)
"nnoremap <C-b> :w<cr>:new<bar>r !make<cr>:setlocal buftype=nofile<cr>:setlocal bufhidden=hide<cr>:setlocal noswapfile<cr>
"imap <C-b> <Esc><C-b>


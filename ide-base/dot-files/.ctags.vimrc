let g:tagbar_type_tex = {
        \ 'ctagstype': 'latex',
        \ 'kinds': [ 'p:parts', 'c:chapters', 's:sections', 'g:graphics:1:0', 'l:labels:1:0', 'r:refs:0:0' ],
        \ 'sort': 0,
        \ 'replace': 1
        \}
let g:tagbar_type_bib = {
        \ 'ctagstype': 'bibtex',
        \ 'kinds': [ 'r:refs' ]
        \}
let g:tagbar_type_typescript = {
        \ 'ctagstype': 'typescript',
        \ 'kinds': ['c:classes', 'n:modules', 'f:functions', 'v:variables', 'm:members', 'i:interfaces', 't:types', 'e:enums', 'I:imports', 'T:tests' ],
        \ 'sort': 0
        \}
autocmd FileType tex let b:WWComplete_pattern = '\v(\k+:)?\k*'


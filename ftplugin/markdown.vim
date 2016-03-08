


function!ConvertMarkdownToJekyll()
    " **************************************************************
    " Configurable settings

    " Pandoc command for converting the markdown file to a flavor compatible
    " with github/jekyll.
    let JEKYLL_MARKDOWN_COMMAND = 'pandoc -S -f markdown_github+footnotes+pandoc_title_block+yaml_metadata_block -t markdown_github+footnotes+fenced_code_blocks+backtick_code_blocks-hard_line_breaks+yaml_metadata_block  --atx-headers -s '
    " Hacks needed since Pandoc wasn't enough to make a clean Jekyll ready 
    " markdown file.
    " 1) replace curly/typographic single and double quotes with plain ones
    " 2) strip the space between in bold text (**bold text: **) which is
    " required by pandoc
    " 3) add jekyll front matter to the markdown file
    "let JEKYLL_POSTPROC_COMMAND = " sed -i -e 's/’\\|‘/\\x27/g ; s/“\\|”/\\x22/g'  -e  's|\\*\\*\\(.*\\): \\*\\*|\\*\\*\\1:\\*\\*|g'  -e  '1s|^|---\\nlayout: post\\ntitle:  \\\"TITLE\\\"\\ndate:   2020-01-01 01:02:03\\ncategories: blog\\ntags:       writing\\n\\n---\\n\\n\\n|' "
    " 3) and 4) tweak the yaml frontmatter for jekyll
    "let JEKYLL_POSTPROC_COMMAND = " sed -i -e 's/’\\|‘/\\x27/g ; s/“\\|”/\\x22/g'      -e '1,10{s|\\.\\.\\.|---|g;}'  "
    " -e  '1s|---|---\\nlayout:  post|' -e '1,10{s|\\.\\.\\.|categories: blog\\ntags:       writing\\n---|g; }'      " this works, but YAGNI since yaml is preserved, so you can keep it in original .md
    " Escape liquid template tags,
    " http://stackoverflow.com/questions/3426182/how-to-escape-liquid-template-tags
    "let JEKYLL_ESCAPE_TAGS = " sed -i 's|{{|{\\% raw \\%}{{|g ; s|}}|}}{\\% endraw \\%}|g' "
    " NOTE: we actually have to use sed here, because we can't open it in a
    " buffer whose filetype maches the function being executed.

    "let VIMMARKDOWN_AND_PANDOC_FIX = " sed -i -e '1,20{s|\\.\\.\\.|---|g;}'  "

    " End of configurable settings
    " **************************************************************

    " search for a yaml frontmatter date tag
    let matched = ''
    let lines = getline(1, 10)
    for line in lines
        "for line in readfile(b:url, '', 8)
        if line =~ '^date: '
            "echom line
            let matched = matchstr(line, '[0-9\-]\+')
        endif
    endfor

    silent update
    let input_name = expand('%:p')
    " use date tag to determine jekyll post filename
    if len(matched) > 0
        let this_file = expand('%:t:r')
        let this_file = substitute(this_file, '_', '-', 'g')   " not mandatory
        let output_name = expand('%:p:h') . '/' . matched . '-' . this_file . '.markdown'
        " output document will be saved in the _posts folder
        " NOTE: this would break links to other markdown files, which are in the _drafts folder
        let drafts_dir = '/_drafts/'
        let posts_dir = '/_posts/'
        if expand('%:p') =~ drafts_dir . expand('%:t:r')
            let posts_output_name = substitute(output_name, drafts_dir, posts_dir, 'g')
        endif
    else
        let output_name = expand('%:p:h') . '/' . expand('%:t:r') . '.markdown'
    endif


    if input_name == output_name
        echoerr 'Unable to create jekyll compatible file. Can only create from .md to .markdown and your input filename is already .markdown!'
        return
    endif

    " Some Markdown implementations, especially the Python one,
    " work best with UTF-8. If our buffer is not in UTF-8, convert
    " it before running Markdown, then convert it back.
    let original_encoding = &fileencoding
    let original_bomb = &bomb
    if original_encoding != 'utf-8' || original_bomb == 1
        set nobomb
        set fileencoding=utf-8
        silent update
    endif

    let md_command = '!' . JEKYLL_MARKDOWN_COMMAND . ' "' . expand('%:p') . '" -o "' . output_name . '"'
    "echom md_command
    silent exec md_command
    "let md_command = '!'  . JEKYLL_POSTPROC_COMMAND . ' "' . output_name . '"'
    ""echom md_command
    "silent exec md_command
    "let md_command = '!'  . JEKYLL_ESCAPE_TAGS . ' "' . output_name . '"'
    ""echom md_command
    "silent exec md_command
    "let md_command = '!'  . VIMMARKDOWN_AND_PANDOC_FIX . ' "' . output_name . '"'
    ""echom md_command
    "silent exec md_command

    " If we changed the encoding, change it back.
    if original_encoding != 'utf-8' || original_bomb == 1
        if original_bomb == 1
            set bomb
        endif
        silent exec 'set fileencoding=' . original_encoding
        silent update
    endif

    redraw!


    echo 'Jekyll compatible markdown file created: ' . output_name
    "silent exec ':tabedit ' . output_name                  " doesn't work, explained here: http://stackoverflow.com/questions/22633115/why-do-i-get-e127-from-this-vimscript

    " save names that will be used in post processing step
    let g:vim_pajemas_drafts_file = output_name
    let g:vim_pajemas_posts_file = posts_output_name

endfunction




function!MyLoggerInit(log_file)
    echom 'Initializing log file: ' . a:log_file
    silent execute "! echo '' > " . a:log_file
endfunction

function!MyLogger(log_file, line_num, ...)
    let text = '(' . string(a:line_num) . ') =    '
    let i = 0
    while (i < len(a:000))
        let text = text . string(a:000[i]) . '    |'
        let i = i+1
    endwhile
    echom text
    silent execute '! echo "' . text . '" >> ' . a:log_file
    redraw!
endfunction





function!JekyllFilePostProc()
    let log_file = 'log.txt'
    "call MyLoggerInit(log_file)
    " jekyll compatibility
    if expand('%:e') != 'markdown'
        echoerr 'Fixing of local links is only supported for Jekyll markdown files.'
        return
    endif

    " vim-markdown Foldexpr_markdown can get really slow at times (~ 15 seconds for 750 lines doc)
    " https://github.com/plasticboy/vim-markdown/issues/162
    " The only way to work around this is to disable folding before working on
    " the document (ie, all those getline and setline) and then enable it again.
    let orgfoldexpr=&foldexpr
    setlocal foldexpr=0


    " convert .md links to proper jekyll links that use date in URL
    let b:user_view = winsaveview()
    normal gg
    let expr_big = '\[[^\]]*\]([^)]*)' " this expr finds valid links, but is incomplete
    let expr_start = '\['
    let expr_middle = '\]('
    let expr_end = ')'
    let flags = 'W'
    let b:lnum = 1
    while b:lnum > 0
        let [b:lnum, b:cnum] = searchpos(expr_big, flags)
        "echom 'found link at line ' . string(b:lnum)
        "call MyLogger(log_file, b:lnum, getline(b:lnum))
        let [b:lnum, b:cnum] = searchpairpos(expr_start, expr_middle, expr_end, flags)
        normal l
        let b:link_col_start = b:cnum + 1
        let [b:lnum, b:cnum] = searchpairpos('(', '', ')', flags)
        let b:link_col_end = b:cnum - 2
        if b:lnum > 0
            let b:lineraw = getline(b:lnum)
            "let b:tmp = string(b:lnum) . ' ' . string(b:cnum) . ' ' . b:lineraw
            "let b:tmp = string(b:lnum) . ': ' . string(b:link_col_start) . '-' . string(b:link_col_end)
            "echom b:lineraw . ' => ' . string(b:link_col_start) . '-' . string(b:link_col_end)
            let b:url = b:lineraw[b:link_col_start : b:link_col_end]
            "echom b:url
            let pos_ext = match(b:url, '\.\(markdown\|mdown\|mkdn\|mdwn\|md\)$')
            if pos_ext < 0
                continue
            endif
            " open url file and search for the date yaml tag
            let matched = ''
            let b:abs_url = expand('%:p:h') . '/' . b:url
            if filereadable(b:abs_url)
                for line in readfile(b:abs_url, '', 10)
                    if line =~ '^date: '
                        "echo line
                        let matched = matchstr(line, '[0-9\-]\+')
                    endif
                endfor
            endif
            " construct new url based on the markdown filename
            if len(matched) > 0
                "let matched = substitute(matched, '-', '/', 'g')
                "let new_url = matched . '/' . b:url[: pos_ext - 1]
                let tmp = substitute(b:url, '_', '-', 'g')
                let new_url = '{% post_url ' . matched . '-' . tmp[: pos_ext - 1] . ' %}'
            else
                let new_url = b:url
            endif
            "echom new_url
            " replace old url with new one
            let head = b:lineraw[: b:link_col_start - 1]
            let tail = b:lineraw[b:link_col_start : -1]
            let tail = substitute(tail, b:url, new_url, '')
            "echom head . tail
            call setline('.', head . tail)
        endif
    endwhile

    " implement workaround to jekyll 3 bug on naked links which basically means
    " converting this:  <https://github.com/alexconst>
    " into:             [https://github.com/alexconst](https://github.com/alexconst)
    if g:vim_pajemas_kramdown == 1
        normal gg
        let expr_big = '^<[a-z]\+://[^>]\+>\(  \)\?$' " this expr finds naked links
        let flags = 'W'
        let b:lnum = 1
        while b:lnum > 0
            let [b:lnum, b:cnum] = searchpos(expr_big, flags)
            "echom 'found link at line ' . string(b:lnum)
            "call MyLogger(log_file, b:lnum, getline(b:lnum))
            let b:lineraw = getline(b:lnum)
            let b:newline = substitute(b:lineraw,   '^<\(.*\)>\(.*\)$',   '[\1](\1)\2', 'g')
            call setline(b:lnum, b:newline)
        endwhile
    endif 

    " fix pandoc quote character and escape jekyll liquid tags
    let b:lnum = 1
    while(b:lnum <= line('$'))
        "echom line
        let line = getline(b:lnum)
        let line = substitute(line, '’\|‘', "'", 'g')
        let line = substitute(line, '“\|”', '"', 'g')
        let line = substitute(line, '{{', '{\% raw \%}{{', 'g')
        let line = substitute(line, '}}', '}}{\% endraw \%}', 'g')
        call setline(b:lnum, line)
        let b:lnum = b:lnum + 1
    endwhile
    " read yaml frontmatter
    let yaml_status = 0
    let b:lnum = 0
    let yaml = {}
    while (b:lnum <= line('$'))
        let b:lnum = b:lnum + 1
        let line = getline(b:lnum)
        if line =~ '^---$' && yaml_status != 1
            let yaml_status = 1
            continue
        endif
        if yaml_status == 1
            if line =~ '^---$\|^\.\.\.$'
                break
            endif
            let head = substitute(line, '\([a-zA-Z]\+\):\s*.*', '\1', 'g')
            let tail = substitute(line, '[a-zA-Z]\+\(:\s*.*\)', '\1', 'g')
            let yaml[head] = tail
        endif
    endwhile
    "echom string(yaml)
    " fix pandoc yaml frontmatter element sorting
    let order = ['layout', 'title', 'date', 'categories', 'tags']
    let b:lnum = 2
    while (len(order) > 0)
        let key = remove(order, 0)
        if has_key(yaml, key)
            let val = remove(yaml, key)
            let newline = key . val
            call setline(b:lnum, newline)
            let b:lnum = b:lnum + 1
        endif 
    endwhile
    while (len(yaml) > 0)
        let key = keys(yaml)[0]
        let val = remove(yaml, key)
        let newline = key . val
        call setline(b:lnum, newline)
        let b:lnum = b:lnum + 1
    endwhile
    if getline(b:lnum) == '...'
        call setline(b:lnum, '---')
        " append toc tag if kramdown is being used
        if g:vim_pajemas_kramdown_toc == 1
            let tmp = ""
            call append(b:lnum, [tmp])
            let tmp = "{% include toc.md %}"
            call append(b:lnum+1, [tmp])
        endif
    endif

    " save document
    update
    " restore original fold expression
    setlocal foldexpr=eval(orgfoldexpr)
    " restore cursor and window position
    call winrestview(b:user_view)
    " reload the document (for proper folding)
    "bufdo e!  " does not work here because of 'Cannot redefine function X: It is in use' error
    " redraw screen just in case
    redraw!
endfunction





" \[[^\]]*\]([^)]*) " initial regex to find markdown links, but it's broken
" another thing that could have helped (but is no longer required) is the
" % key to move to matching braces http://vim.wikia.com/wiki/Moving_to_matching_braces


"function!PandocBoldPre()
"    silent exec '%s/^\*\*\(.*\):\*\*\s*$/\*\*\1: \*\*/ge'
"    update
"    call ProcessMarkdownToHtml()
"endfunction
"
"function!PandocBoldPost()
"    silent exec '%s/^\*\*\(.*\): \*\*\s*$/\*\*\1:\*\*/ge'
"    update
"endfunction

function!ProcessMarkdownToHtmlWithBoldFix()
    silent exec "normal! mP"
    silent exec '%s/^\*\*\(.*\):\*\*\s*$/\*\*\1: \*\*/ge'
    update
    call ProcessMarkdownToHtml()
    silent exec '%s/^\*\*\(.*\): \*\*\s*$/\*\*\1:\*\*/ge'
    update
    redraw!
    silent exec "normal! 'P"
endfunction


function!ProcessMarkdownToHtml()
    " **************************************************************
    " Configurable settings

    "let MARKDOWN_COMMAND = 'markdown'
    "let MARKDOWN_COMMAND = 'pandoc -S -f markdown_github+footnotes -t html5 --section-divs --html-q-tags -s --toc --toc-depth=6 --number-sections -H /opt/share/doc/github-pandoc_html.css'
    let MARKDOWN_COMMAND = 'pandoc -S -f markdown_github+footnotes+pandoc_title_block+yaml_metadata_block+tex_math_dollars -t html5 --section-divs --html-q-tags -s --toc --toc-depth=6 --number-sections -c /opt/share/doc/normalize.css -c /opt/share/doc/pandoc-github.css --latexmathml=/opt/share/doc/LaTeXMathMLPandoc.js'
    " --latexmathml=/opt/share/doc/LaTeXMathMLPandoc.js
    " --mathjax
    " use -autolink_bare_uris on the input format to fix the bold-text-to-links

    " delete these 2 lines???
    "let JEKYLL_MARKDOWN_COMMAND = 'pandoc -S -f markdown_github+footnotes+pandoc_title_block -t markdown_github+fenced_code_blocks+backtick_code_blocks-hard_line_breaks  --atx-headers '
    "let JEKYLL_POSTPROC_COMMAND = " sed -i -e 's/’\|‘/\x27/g ; s/“\|”/\x22/g'  -e  's#\*\*\(.*\): \*\*#\*\*\1:\*\*#g'  -e  '1s#^#---\nlayout: post\ntitle:  \"TITLE\"\ndate:   2020-01-01 01:02:03\ncategories: blog\ntags:       writing\n---\n\n\n#'"     " note: this one is certainly broken since wildcards are not being properly escaped

    " End of configurable settings
    " **************************************************************

    silent update
    "let output_name = tempname() . '.html'
    let input_name = expand('%:p')
    let output_name = expand('%:r') . '.html'

    " Some Markdown implementations, especially the Python one,
    " work best with UTF-8. If our buffer is not in UTF-8, convert
    " it before running Markdown, then convert it back.
    let original_encoding = &fileencoding
    let original_bomb = &bomb
    if original_encoding != 'utf-8' || original_bomb == 1
        set nobomb
        set fileencoding=utf-8
        silent update
    endif

    "" Write the HTML header. Do a CSS reset, followed by setting up
    "" some basic styles from YUI, so the output looks nice.
    "let file_header = ['<html>', '<head>',
    "    \ '<meta http-equiv="Content-Type" content="text/html; charset=utf-8">',
    "    \ '<title>Markdown Preview</title>',
    "    \ '<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/3.3.0/build/cssreset/reset-min.css">',
    "    \ '<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/3.3.0/build/cssbase/base-min.css">',
    "    \ '<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/3.3.0/build/cssfonts/fonts-min.css">',
    "    \ '<style>body{padding:20px;}div#container{background-color:#F2F2F2;padding:0 20px;margin:0px;border:solid #D0D0D0 1px;}</style>',
    "    \ '</head>', '<body>', '<div id="container">']
    "call writefile(file_header, output_name)


    "let md_command = '!' . MARKDOWN_COMMAND . ' "' . expand('%:p') . '" >> "' .
    "    \ output_name . '"'
    let md_command = '!' . MARKDOWN_COMMAND . ' "' . expand('%:p') . '" -o "' . output_name . '"'
    silent exec md_command
    "let md_command = '!'  . FIX_PANDOC . ' "' . output_name . '"'


    "if has('win32')
    "    let footer_name = tempname()
    "    call writefile(['</div></body></html>'], footer_name)
    "    silent exec '!type "' . footer_name . '" >> "' . output_name . '"'
    "    exec delete(footer_name)
    "else
    "    silent exec '!echo "</div></body></html>" >> "' .
    "        \ output_name . '"'
    "endif

    " If we changed the encoding, change it back.
    if original_encoding != 'utf-8' || original_bomb == 1
        if original_bomb == 1
            set bomb
        endif
        silent exec 'set fileencoding=' . original_encoding
        silent update
    endif

endfunction



function!PreviewMarkdownInBrowser()
    " **************************************************************
    " Configurable settings

    "if has('win32')
    "    " note important extra pair of double-quotes
    "    let BROWSER_COMMAND = 'cmd.exe /c start ""'
    "else
        "let BROWSER_COMMAND = '/usr/bin/chromium --temp-profile --incognito --bwsi --disable-sync-preferences --disable-extensions --disable-plugins --disk-cache-dir=/dev/shm '
    "endif
    let BROWSER_COMMAND = '/opt/bin/firefox'

    " End of configurable settings
    " **************************************************************

    " jekyll compatibility
    if expand('%:e') == 'markdown'
        echoerr 'No preview for jekyll .markdown files. Only .md files.'
        return
    endif

    let output_name = expand('%:r') . '.html'
    "call ProcessMarkdownToHtml()

    silent exec '!' . BROWSER_COMMAND . ' "' . output_name . '"'

    "exec input('Press ENTER to continue...')
    "echo
    "exec delete(output_name)
    redraw!
endfunction




function!Main()
    call ConvertMarkdownToJekyll()
    execute 'tabe ' . g:vim_pajemas_drafts_file
    "JekyllFilePostProc()
    "normal :exec 'edit' <CR>
endfunction





let g:vim_pajemas_kramdown=1
let g:vim_pajemas_kramdown_toc=1

" for jekyll compatibility reasons we only create html files for .md files
"autocmd BufWriteCmd *.md :echom 'u wut m8'
"autocmd BufWriteCmd *.md :call ProcessMarkdownToHtml()
"autocmd BufWritePre *.md :call PandocBoldPre()
"autocmd BufWritePost *.md :call PandocBoldPost()

" convert to html
map <leader>h :call ProcessMarkdownToHtmlWithBoldFix()<CR>
" to preview the file in the browser
map <leader>p :call PreviewMarkdownInBrowser()<CR>
" to convert the file to jekyll-compatible markdown and open it in a new tab
"map <leader>j :call ConvertMarkdownToJekyll()<CR> :exec 'tabe ' . g:vim_pajemas_drafts_file <CR>  :call JekyllFilePostProc()<CR> :exec 'edit' <CR> 
map <leader>j 
\<CR> :call ConvertMarkdownToJekyll() <CR>
\<CR> :exec 'tabe ' . g:vim_pajemas_drafts_file <CR>
\<CR> :call JekyllFilePostProc() <CR>
\<CR> :call rename(g:vim_pajemas_drafts_file, g:vim_pajemas_posts_file) <CR>
\<CR> :exec 'edit ' . g:vim_pajemas_posts_file <CR>

"map <leader>j :call Main()<CR>

"map <leader>f :call JekyllFilePostProc()<CR>

" NOTE: very weird bug were new tabe won't open if the cursor is at the last
" line of the line when <leader>j is pressed



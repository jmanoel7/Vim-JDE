if exists('g:vjde_iab_loaded') || &cp || !has('ruby') "{{{1
	finish
endif
let g:vjde_iab_loaded = 1

let s:templates = []
let s:add_lines = []

let g:iab_previewer = VjdePreviewWindow_New()
let g:iab_previewer.name='iab_previewer'
let g:iab_previewer.onSelect='VjdePreviewIabSelect'
let g:iab_previewer.previewLinesFun=''

ruby $vjde_iab_manager = Vjde::VjdeTemplateManager.new
func! s:VjdeIabbrAdd(name,desc) "{{{2
	call add(s:templates,{'name':a:name,'desc':a:desc})
endf
func! s:VjdeIabbrInit() "{{{2
	ruby $vjde_iab_manager.add_file(VIM::evaluate('g:vjde_install_path')+"/vjde/tlds/iab.vjde")
	ruby $vjde_iab_manager.add_file(VIM::evaluate('expand("~/.vim/vjde/iab.vjde")'))
	if !empty(s:templates)
		call remove(s:templates,0,-1)
	endif
ruby<<EOF
$vjde_iab_manager.indexs.each_with_index { |ti,i|
	VIM::command('call s:VjdeIabbrAdd("'+ti.name+'","'+ti.desc+'")')
}
EOF
endf
func! s:VjdeInitPreview(base) "{{{2
	call g:iab_previewer.Clear()
	call g:iab_previewer.Add('abbr:'.a:base)
	if strlen(a:base)<=0
		for item in s:templates
			call g:iab_previewer.Add('abbr '.item.name.';'.item.desc)
		endfor
	else
		for item in filter(copy(s:templates),'v:val.name =~ "^'.a:base.'"')
			call g:iab_previewer.Add('abbr '.item.name.';'.item.desc)
		endfor
	endif
endf
let s:paras = {}
func! VjdePreviewIab(paras,...) "{{{2
	let base = '' 
	if a:0>1
		let base = a:1
	else
		let base = expand('<cword>')
	endif
	call s:VjdeInitPreview(base)
	let s:paras = a:paras
	call g:iab_previewer.Preview(0)
endf
func! VjdePreviewIabSelect(word)
	if strlen(a:word)>=0
		let s:added_lines = []
ruby<<EOF
    tn = VIM::evaluate("a:word")
    tplt = $vjde_iab_manager.getTemplate(tn)
    if tplt != nil
	tplt.each_para { |p|
		if "1"==VIM::evaluate('has_key(s:paras,"'+p.name+'")')
			tplt.set_para(p.name,VIM::evaluate('s:paras["'+p.name+'"]'))
		else
		str=VIM::evaluate('inputdialog(\''+p.desc.gsub(/'/,"''")+' : \',"")')
		tplt.set_para(p.name,str)
		end
	}
	
    tplt.each_line { |l|
    	l.gsub!(/'/,"''")
	l.chomp!
    	VIM::command("call add(s:added_lines,'"+l+"')")
    }
    end
EOF
	if len(s:added_lines) <= 0 
		return 
	endif
		call setline(line('.'),s:added_lines[0])
	if len(s:added_lines)>1	
		call append(line('.'),s:added_lines[1:-1])
	endif
		"exec 'normal '.len(s:added_lines).'k'
		exec 'normal '.len(s:added_lines).'=='
		let lnr = line('.')
		let idx = -1
		for item in s:added_lines
			let idx +=1
			let idx1 = stridx(item,'|')
			if ( idx1 > -1)
				call setline(lnr+idx,substitute(getline(lnr+idx),'|','',''))
				call cursor(lnr+idx,0)
				exec 'normal '.idx1.'l'
				break
			endif
		endfor
	endif
endf

call s:VjdeIabbrInit()
au BufNewFile,BufRead,BufEnter *.java imap <buffer> <C-j> <esc>:call VjdePreviewIab({})<cr>i
au BufNewFile,BufRead,BufEnter *.jsp imap <buffer> <C-j> <esc>:call VjdePreviewIab({})<cr>i

"vim:fdm=marker:ff=unix
"

" =============================================================================
" Filename: autoload/calendar/view/help.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/03/29 06:33:09.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! calendar#view#help#new(source) abort
  return s:constructor.new(a:source)
endfunction

let s:self = {}

let s:self._select_line = 0
let s:self._select_title = 1
let s:self._contents_cache = {}

function! s:self.split_message(message) dict abort
  let messages = split(a:message, "\n")
  let frame = calendar#setting#frame()
  let width = calendar#string#strdisplaywidth(frame.vertical)
  let w = self.sizex() - 4 - width * 2
  let msg = []
  for message in messages
    while len(message)
      let oneline = calendar#string#strwidthpart(message, w)
      let message = message[len(oneline):]
      if oneline =~# '[a-zA-Z]$' && message =~# '^[a-z.,]'
        let wordleader = matchstr(oneline, '\<[a-zA-Z]\+$')
        if len(wordleader) < len(oneline) / 5
          let oneline = oneline[:-len(wordleader) - 1]
          let message = wordleader . message
        endif
      endif
      let message = message[len(matchstr(message, '^ *')):]
      call add(msg, oneline)
    endwhile
  endfor
  return msg
endfunction

function! s:self.get_raw_contents() dict abort
  let key = self.sizex() . '-' . self.sizey() . '-' . calendar#setting#get('locale')
  if has_key(self._contents_cache, key)
    return self._contents_cache[key]
  endif
  let s = []
  let help_message = calendar#message#get('help')
  let title = get(help_message, 'title', 'calendar.vim')
  let message_top = self.split_message(get(help_message, 'message', ''))
  let message_credit = self.split_message(get(help_message, 'credit', ''))
  let title_mapping = get(help_message, 'Mapping', 'Mapping')
  let title_credit = get(help_message, 'Credit', 'Credit')
  let nms = self.get_mapping('n')
  for m in nms
    call filter(m.mappings, 'has_key(help_message, v:val.name)')
    if len(m.mappings)
      cal add(s, '  ' . get(help_message, m.title, m.title))
      for mapping in m.mappings
        cal add(s, '    ' . mapping.key . ' : ' . get(help_message, mapping.name, mapping.name))
      endfor
    endif
  endfor
  let self._contents_cache[key] =
        \ [{ 'title': title, 'items': map(message_top, "{ 'title': v:val }") },
        \ { 'title': title_mapping, 'items': map(s, "{ 'title': v:val }")},
        \ { 'title': title_credit, 'items': map(message_credit, "{ 'title': v:val }")}]
  return self._contents_cache[key]
endfunction

let s:nmapping_order =
      \ [ { 'title': 'View'
      \   , 'mappings': [ 'view_left', 'view_right' ] }
      \ , { 'title': 'Event window / Task window'
      \   , 'mappings': [ 'event', 'task', 'delete', 'delete_line', 'clear', 'undo', 'undo_line'] }
      \ , { 'title': 'Utility'
      \   , 'mappings': [ 'today', 'help', 'exit' ] } ]

function! s:self.get_mapping(mode) dict abort
  redir => redir
  exec 'silent! ' . a:mode . 'map <buffer>'
  redir END
  let buffermapping = filter(split(copy(redir), '\n'), 'v:val =~# "\\s@\\S\\+$"')
  let mapping = map(filter(copy(buffermapping), 'v:val =~# "@<Plug>(calendar_[^)]\\+)$"'), 'substitute(v:val, "\\(@<Plug>(calendar_\\|^n\s*\\|)$\\)", "", "g")')
  let _mapping_alias = filter(copy(buffermapping), 'v:val !~# "<Plug>(calendar_[^)]\\+)$"')
  let mapping_alias = map(map(_mapping_alias, 'substitute(v:val, "\\(@<Plug>(calendar_\\|^n\s*\\|)$\\)", "", "g")'), 'substitute(v:val, "@\\(\\S\\+\\)$", "\\1", "")')
  let map_dict = {}
  let map_dict_rev = {}
  let map_dict_alias = {}
  for n in mapping
    try
      let [key, name] = split(n, '\s\+')
      let map_dict[key] = name
      if has_key(map_dict_rev, name)
        call add(map_dict_rev[name], key)
      else
        let map_dict_rev[name] = [key]
      endif
    catch
    endtry
  endfor
  for n in mapping_alias
    try
      let [key, name] = split(n, '\s\+')
      if key =~# '^\(O[A-D]\|g\(.\|<\S\+>\)\|.*Wheel.*\)$'
        continue
      endif
      let map_dict_alias[key] = name
    catch
    endtry
  endfor
  for [key, name] in items(map_dict_alias)
    if has_key(map_dict, name)
      call add(map_dict_rev[map_dict[name]], key)
    endif
  endfor
  for [key, value] in items(map_dict_rev)
    let new_value = []
    for v in value
      if index(new_value, v) == -1 &&
            \ (v ==# tolower(v) && v != '/' || len(v) > 1
            \ || index(value, tolower(v)) == -1)
        call add(new_value, v)
      else
      endif
    endfor
    let map_dict_rev[key] = sort(new_value, 's:compare')
  endfor
  let keylist = []
  let mapping_order = get(s:, a:mode . 'mapping_order', [])
  for i in range(len(mapping_order))
    let title = mapping_order[i].title
    call add(keylist, { 'title': title, 'mappings': [] })
    for name in mapping_order[i].mappings
      if has_key(map_dict_rev, name)
        let keystr = join(map_dict_rev[name], ' / ')
        call add(keylist[i].mappings, { 'name': name, 'key': keystr })
      endif
    endfor
  endfor
  return keylist
endfunction

function! s:compare(a, b) abort
  return len(a:a) == 1 ? -1 : len(a:b) == 1 ? 1 :
        \ len(a:a) == len(a:b) ? (a:a =~ '^[a-z]\+$' ? -1 : 1) :
        \ a:a !~# '\S-' ? -1 : a:b !~# '\S-' ? 1 : len(a:a) > len(a:b) ? 1 : -1
endfunction

let s:constructor = calendar#constructor#view_textbox#new(s:self)

let &cpo = s:save_cpo
unlet s:save_cpo

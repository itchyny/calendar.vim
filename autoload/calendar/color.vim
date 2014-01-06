" =============================================================================
" Filename: autoload/calendar/color.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/01/07 05:35:18.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" Color utility

let s:is_gui = has('gui_running')
let s:is_cterm = !s:is_gui
let s:is_win32cui = (has('win32') || has('win64')) && !has('gui_running')
let s:term = has('gui_running') ? 'gui' : 'cterm'
let s:is_dark = &background ==# 'dark'

function! calendar#color#new_syntax(id, fg, bg)
  if has_key(b:, 'calendar')
    if !has_key(b:, 'calendar_syntaxnames')
      let b:calendar_syntaxnames = []
    endif
    let syntaxnames = b:calendar_syntaxnames
  else
    let syntaxnames = []
  endif
  let name = substitute(a:id, '[^a-zA-Z0-9]', '', 'g')
  if len(name) && len(a:fg) && len(a:bg)
    let flg = 0
    if &bg ==# 'dark' && a:fg ==# '#000000' || &bg ==# 'light' && a:fg ==# '#ffffff'
      let flg = 1
      let [fg, bg] = [a:bg, '']
    else
      let [fg, bg] = [a:fg, a:bg]
    endif
    let cuifg = calendar#color#convert(fg)
    let cuibg = calendar#color#convert(bg)
    if cuifg >= 0
      if index(syntaxnames, name) < 0
        call add(syntaxnames, name)
      endif
      if cuibg >= 0
        exec 'highlight Calendar' . name . ' ctermfg=' . cuifg . ' ctermbg=' . cuibg . ' guifg=' . fg . ' guibg=' . bg
      else
        exec 'highlight Calendar' . name . ' ctermfg=' . cuifg . ' guifg=' . fg
      endif
      let select_bg = s:select_color()
      if type(select_bg) == type('') || select_bg >= 0
        let nameselect = name . 'Select'
        if index(syntaxnames, nameselect) < 0
          call add(syntaxnames, nameselect)
        endif
        if s:is_gui
          exec 'highlight Calendar' . nameselect . ' guifg=' . fg . ' guibg=' . (flg ? select_bg : bg)
        else
          exec 'highlight Calendar' . nameselect . ' ctermfg=' . cuifg . ' ctermbg=' . (flg ? select_bg : cuibg)
        endif
      endif
    endif
    return name
  endif
  return ''
endfunction

function! calendar#color#convert(rgb)
  let rgb = map(matchlist(a:rgb, '#\(..\)\(..\)\(..\)')[1:3], '0 + ("0x".v:val)')
  if len(rgb) == 0
    return -1
  endif
  if rgb[0] == 0xc0 && rgb[1] == 0xc0 && rgb[2] == 0xc0
    return 7
  elseif rgb[0] == 0x80 && rgb[1] == 0x80 && rgb[2] == 0x80
    return 8
  elseif s:is_win32cui 
    if rgb[0] > 127 && rgb[1] > 127 && rgb[2] > 127
      let min = 0
      for r in rgb
        let min = min([min, r])
      endfor
      let rgb[index(rgb, min)] -= 127
    endif
    let newrgb = [rgb[0] > 0xa0 ? 4 : 0, rgb[1] > 0xa0 ? 2 : 0, rgb[2] > 0xa0 ? 1 : 0]
    return newrgb[0] + newrgb[1] + newrgb[2] + (rgb[0] > 196 || rgb[1] > 196 || rgb[2] > 196) * 8
  elseif (rgb[0] == 0x80 || rgb[0] == 0x00) && (rgb[1] == 0x80 || rgb[1] == 0x00) && (rgb[2] == 0x80 || rgb[2] == 0x00)
    return (rgb[0] / 0x80) + (rgb[1] / 0x80) * 2 + (rgb[1] / 0x80) * 4
  elseif abs(rgb[0]-rgb[1]) < 3 && abs(rgb[1]-rgb[2]) < 3 && abs(rgb[2]-rgb[0]) < 3
    return s:black((rgb[0] + rgb[1] + rgb[2]) / 3)
  else
    return 16 + ((s:nr(rgb[0]) * 6) + s:nr(rgb[1])) * 6 + s:nr(rgb[2])
  endif
endfunction

function! s:black(x)
  if a:x < 0x04
    return 16
  elseif a:x > 0xf4
    return 231
  elseif index([0x00, 0x5f, 0x87, 0xaf, 0xdf, 0xff], a:x) >= 0
    let l = a:x / 0x30
    return ((l * 6) + l) * 6 + l + 16
  else
    return 232 + (a:x < 8 ? 0 : a:x < 0x60 ? (a:x-8)/10 : a:x < 0x76 ? (a:x-0x60)/6+9 : (a:x-8)/10)
  endif
endfunction

function! s:nr(x)
  return a:x < 0x2f ? 0 : a:x < 0x73 ? 1 : a:x < 0x9b ? 2 : a:x < 0xc7 ? 3 : a:x < 0xef ? 4 : 5
endfunction

function! calendar#color#gui_color()
  if has_key(s:, '_gui_color') | return s:_gui_color | endif
  let s:_gui_color = {
        \ 'black'          : '#000000',
        \ 'white'          : '#ffffff',
        \
        \ 'darkestgreen'   : '#005f00',
        \ 'darkgreen'      : '#008700',
        \ 'mediumgreen'    : '#5faf00',
        \ 'brightgreen'    : '#afdf00',
        \
        \ 'darkestcyan'    : '#005f5f',
        \ 'mediumcyan'     : '#87dfff',
        \
        \ 'darkestblue'    : '#005f87',
        \ 'darkblue'       : '#0087af',
        \
        \ 'darkestred'     : '#5f0000',
        \ 'darkred'        : '#870000',
        \ 'mediumred'      : '#af0000',
        \ 'brightred'      : '#df0000',
        \ 'brightestred'   : '#ff0000',
        \
        \ 'darkestpurple'  : '#5f00af',
        \ 'mediumpurple'   : '#875fdf',
        \ 'brightpurple'   : '#dfdfff',
        \
        \ 'brightorange'   : '#ff8700',
        \ 'brightestorange': '#ffaf00',
        \
        \ 'gray0'          : '#121212',
        \ 'gray1'          : '#262626',
        \ 'gray2'          : '#303030',
        \ 'gray3'          : '#4e4e4e',
        \ 'gray4'          : '#585858',
        \ 'gray5'          : '#606060',
        \ 'gray6'          : '#808080',
        \ 'gray7'          : '#8a8a8a',
        \ 'gray8'          : '#9e9e9e',
        \ 'gray9'          : '#bcbcbc',
        \ 'gray10'         : '#d0d0d0',
        \
        \ 'yellow'         : '#b58900',
        \ 'orange'         : '#cb4b16',
        \ 'red'            : '#dc322f',
        \ 'magenta'        : '#d33682',
        \ 'violet'         : '#6c71c4',
        \ 'blue'           : '#268bd2',
        \ 'cyan'           : '#2aa198',
        \ 'green'          : '#859900',
        \ }
  return s:_gui_color
endfunction

function! calendar#color#to_256color(nr, fg)
  if a:nr == 0 || a:nr == 16
    return 232
  elseif a:nr == 15 || a:nr == 231
    return 255
  elseif a:nr < 16
    if a:fg
      return calendar#color#is_dark() ? 255 : 232
    else
      return calendar#color#is_dark() ? 232 : 255
    endif
  else
    return a:nr
  endif
endfunction

function! calendar#color#fg_color(syntax_name)
  let color = synIDattr(synIDtrans(hlID(a:syntax_name)), 'fg', s:term)
  return s:is_gui ? color : calendar#color#to_256color(color + 0, 1)
endfunction

function! calendar#color#bg_color(syntax_name)
  let color = synIDattr(synIDtrans(hlID(a:syntax_name)), 'bg', s:term)
  return s:is_gui ? color : calendar#color#to_256color(color + 0, 0)
endfunction

function! calendar#color#is_dark()
  return &background ==# 'dark'
endfunction

function! calendar#color#normal_fg_color()
  if s:is_win32cui
    if calendar#color#is_dark()
      return 15
    else
      return 0
    endif
  endif
  let fg_color = calendar#color#fg_color('Normal')
  if s:is_cterm && type(fg_color) == type(0) && fg_color < 0
    if calendar#color#is_dark()
      return 255
    else
      return 232
    endif
  endif
  return fg_color
endfunction

function! calendar#color#normal_bg_color()
  if s:is_win32cui
    if calendar#color#is_dark()
      return 0
    else
      return 15
    endif
  endif
  let bg_color = calendar#color#bg_color('Normal')
  if s:is_cterm && type(bg_color) == type(0) && bg_color < 0
    if calendar#color#is_dark()
      return 232
    else
      return 255
    endif
  endif
  return bg_color
endfunction

function! calendar#color#comment_fg_color()
  if s:is_win32cui
    return 7
  endif
  let fg_color = calendar#color#fg_color('Comment')
  if s:is_cterm && type(fg_color) == type(0) && fg_color < 0
    if calendar#color#is_dark()
      return 244
    else
      return 243
    endif
  endif
  return fg_color
endfunction

function! calendar#color#comment_bg_color()
  if s:is_win32cui
    if calendar#color#is_dark()
      return 0
    else
      return 15
    endif
  endif
  let bg_color = calendar#color#bg_color('Comment')
  if s:is_cterm && type(bg_color) == type(0) && bg_color < 0
    if calendar#color#is_dark()
      return 232
    else
      return 255
    endif
  endif
  return bg_color
endfunction

function! calendar#color#nr_rgb(nr)
  let x = a:nr * 1
  if x < 8
    let [b, rg] = [x / 4, x % 4]
    let [g, r] = [rg / 2, rg % 2]
    return [r * 3, g * 3, b * 3]
  elseif x == 8
    return [4, 4, 4]
  elseif x < 16
    let y = x - 8
    let [b, rg] = [y / 4, y % 4]
    let [g, r] = [rg / 2, rg % 2]
    return [r * 5, g * 5, b * 5]
  elseif x < 232
    let y = x - 16
    let [rg, b] = [y / 6, y % 6]
    let [r, g] = [rg / 6, rg % 6]
    return [r, g, b]
  else
    let k = (x - 232) * 5 / 23
    return [k, k, k]
  endif
endfunction

if s:is_win32cui

  function! calendar#color#gen_color(fg, bg, weightfg, weightbg)
    return a:weightfg > a:weightbg ? a:fg : a:bg
  endfunction

elseif s:is_cterm

  function! calendar#color#gen_color(fg, bg, weightfg, weightbg)
    let fg = a:fg < 0 ? (s:is_dark ?  255 : 232) : a:fg
    let bg = a:bg < 0 ? (s:is_dark ?  232 : 255) : a:bg
    let fg_rgb = calendar#color#nr_rgb(fg)
    let bg_rgb = calendar#color#nr_rgb(bg)
    if fg > 231 && bg > 231
      let color = (fg * a:weightfg + bg * a:weightbg) / (a:weightfg + a:weightbg)
    elseif fg < 16 || bg < 16
      let color = a:weightfg > a:weightbg ? fg : bg
    else
      let color_rgb = map([0, 1, 2], '(fg_rgb[v:val] * a:weightfg + bg_rgb[v:val] * a:weightbg) / (a:weightfg + a:weightbg)')
      let color = ((color_rgb[0] * 6 + color_rgb[1]) * 6 + color_rgb[2]) + 16
    endif
    return color
  endfunction

  function! calendar#color#select_rgb(color, rgb, weight)
    let c = calendar#color#nr_rgb(a:color < 0 ? (s:is_dark ? 255 : 232) : a:color)
    let cc = max([(c[0] + c[1] + c[2]) / 3, 5])
    let colors = [cc / a:weight, cc / a:weight, cc / a:weight]
    let colors[a:rgb] = cc
    let color = ((colors[0] * 6 + colors[1]) * 6 + colors[2]) + 16
    return color
  endfunction

else

  function! calendar#color#gen_color(fg, bg, weightfg, weightbg)
    let fg_rgb = map(matchlist(a:fg[0] == '#' ? a:fg : get(calendar#color#gui_color(), a:fg, ''), '#\(..\)\(..\)\(..\)')[1:3], '("0x".v:val) + 0')
    let bg_rgb = map(matchlist(a:bg[0] == '#' ? a:bg : get(calendar#color#gui_color(), a:bg, ''), '#\(..\)\(..\)\(..\)')[1:3], '("0x".v:val) + 0')
    if len(fg_rgb) != 3 | let fg_rgb = s:is_dark ?  [0xe4, 0xe4, 0xe4] : [0x12, 0x12, 0x12] | endif
    if len(bg_rgb) != 3 | let bg_rgb = s:is_dark ? [0x12, 0x12, 0x12] : [0xe4, 0xe4, 0xe4] | endif
    let color_rgb = map(map([0, 1, 2], '(fg_rgb[v:val] * a:weightfg + bg_rgb[v:val] * a:weightbg) / (a:weightfg + a:weightbg)'), 'v:val < 0 ? 0 : v:val > 0xff ? 0xff : v:val')
    let color = printf('0x%02x%02x%02x', color_rgb[0], color_rgb[1], color_rgb[2]) + 0
    if color < 0 || 0xffffff < color | let color = s:is_dark ? 0x3a3a3a : 0xbcbcbc | endif
    return printf('#%06x', color)
  endfunction

  function! calendar#color#select_rgb(color, rgb)
    let c = map(matchlist(a:color[0] == '#' ? a:color : get(calendar#color#gui_color(), a:color, ''), '#\(..\)\(..\)\(..\)')[1:3], '("0x".v:val) + 0')
    if len(c) != 3 | let c = s:is_dark ? [0xe4, 0xe4, 0xe4] : [0x12, 0x12, 0x12] | endif
    let cc = max([(c[0] + c[1] + c[2]) / 3, 0x6f])
    let color = printf('0x%02x%02x%02x', a:rgb % 2 ? cc : cc / 9, (a:rgb / 2) % 2 ? cc : cc / 9, (a:rgb / 4) % 2 ? cc : cc / 9) + 0
    if color < 0 || 0xffffff < color | let color = s:is_dark ? 0x3a3a3a : 0xbcbcbc | endif
    return printf('#%06x', color)
  endfunction

endif

function! calendar#color#colors()
  return [
        \ '#16a765',
        \ '#4986e7',
        \ '#fad165',
        \ '#b99aff',
        \ '#f83a22',
        \ '#9fe1e7',
        \ '#ffad46',
        \ '#9a9cff',
        \ '#f691b2',
        \ '#9fe1e7',
        \ '#92e1c0',
        \ '#ac725e',
        \ '#ff7537',
        \ '#b3dc6c',
        \ '#9fc6e7',
        \ '#fbe983',
        \ '#d06b64',
        \ ]
endfunction

function! calendar#color#syntax(name, fg, bg, attr)
  let term = len(a:attr) ? ' term=' . a:attr . ' cterm=' . a:attr . ' gui=' . a:attr : ''
  if s:is_gui
    let fg = len(a:fg) ? ' guifg=' . a:fg : ''
    let bg = len(a:bg) ? ' guibg=' . a:bg : ''
  else
    let fg = len(a:fg) ? ' ctermfg=' . a:fg : ''
    let bg = len(a:bg) ? ' ctermbg=' . a:bg : ''
  endif
  exec 'highlight Calendar' . a:name . term . fg . bg
endfunction

function! s:select_color()
  let fg_color = calendar#color#normal_fg_color()
  let bg_color = calendar#color#normal_bg_color()
  let select_color = calendar#color#gen_color(fg_color, bg_color, 1, 4)
  if s:is_win32cui
    let select_color = s:is_dark ? 8 : 7
  endif
  return select_color
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" =============================================================================
" Filename: autoload/calendar/string.vim
" Author: itchyny
" License: MIT License
" Last Change: 2014/01/04 18:56:30.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

" String manipulations.
" All the functions were imported from vital.vim.

let s:c = calendar#countcache#new('string.vim')

fu! calendar#string#truncate(s, w)
  retu s:C(a:s, a:w)
endf

fu! calendar#string#truncate_reverse(s, w)
  retu s:U(a:s, a:w)
endf

if exists('*strdisplaywidth')
  fu! calendar#string#strdisplaywidth(s)
    retu strdisplaywidth(a:s)
  endf
el
  fu! calendar#string#strdisplaywidth(s)
    retu s:S(a:s)
  endf
en

fu! calendar#string#strwidthpart(s, w)
  retu s:T(a:s, a:w)
endf

fu! calendar#string#strwidthpart_reverse(s, w)
  retu s:R(a:s, a:w)
endf

" The following codes were imported from vital.vim.
" https://github.com/vim-jp/vital.vim (Public Domain)
" Some functions are improved using binary search.

let s:r = '^[\x20-\x7e]*$'
" fu! s:truncate(s, w)
fu! s:C(s, w)
  if a:w <= 0 | retu '' | en
  let k = a:w . 'C' . a:s
  if s:c.has_key(k) | retu s:c.get(k) | en
  if a:s =~# s:r
    let r = len(a:s) < a:w ? printf('%-'.a:w.'s', a:s) : strpart(a:s, 0, a:w)
    retu s:c.save(k, r)
  en
  let r = a:s
  let w = s:S(a:s)
  if w > a:w
    let r = s:T(r, a:w)
    let w = s:S(r)
  en
  if w < a:w
    let r .= repeat(' ', a:w - w)
  en
  retu s:c.save(k, r)
endf

" fu! s:truncate_reverse(s, w)
fu! s:U(s, w)
  let k = a:w . 'U' . a:s
  if a:w == 0 | retu '' | en
  if s:c.has_key(k) | retu s:c.get(k) | en
  if a:s =~# s:r
    let r = len(a:s) < a:w ? printf('%-'.a:w.'s', a:s) : strpart(a:s, len(a:s) - a:w)
    retu s:c.save(k, r)
  en
  let r = a:s
  let w = s:S(a:s)
  if w > a:w
    let r = s:R(r, a:w)
    let w = s:S(r)
  en
  if w < a:w
    let r = repeat(' ', a:w - w) . r
  en
  retu s:c.save(k, r)
endf

" fu! s:truncate_smart(s, m, f, p)
fu! s:M(s, m, f, p)
  let w = s:S(a:s)
  if w <= a:m
    let r = a:s
  el
    let h = a:m - s:S(a:p) - a:f
    let r = s:T(a:s, h) . a:p . s:R(a:s, a:f)
  en
  retu s:C(r, a:m)
endf

" fu! s:strwidthpart(s, w)
fu! s:T(s, w)
  let k = a:w . 'T' . a:s
  if s:c.has_key(k) | retu s:c.get(k) | en
  let t = split(a:s, '\zs')
  let w = s:S(a:s)
  let l = len(t)
  let i = l / 2
  let r = l - 1
  wh w > a:w && i > 0
    let l = max([r - i + 1, 0])
    let n = s:S(join(t[(l):(r)], ''))
    if w - n >= a:w || i <= 1
      let w -= n
      let r = l - 1
    en
    if i > 1 | let i = i / 2 | en
  endw
  let r = join(l ? t[:l - 1] : [], '')
  retu s:c.save(k, r)
endf

" fu! s:strwidthpart_reverse(s, w)
fu! s:R(s, w)
  if a:w <= 0
    retu ''
  en
  let t = split(a:s, '\zs')
  let w = s:S(a:s)
  let s = len(t)
  let i = s / 2
  let l = 0
  let r = -1
  wh w > a:w && i > 0
    let r = min([l + i, s]) - 1
    let n = s:S(join(t[(l):(r)], ''))
    if w - n >= a:w || i <= 1
      let w -= n
      let l = r + 1
    en
    if i > 1 | let i = i / 2 | en
  endw
  retu join(r < s ? t[(r + 1):] : [], '')
endf

if exists('*strdisplaywidth')

  " fu! s:strdisplaywidth(s)
  fu! s:S(s)
    retu strdisplaywidth(a:s)
  endf

el

  let s:c1 = {}
  " fu! s:strdisplaywidth(s)
  fu! s:S(s)
    if !len(a:s) | retu 0 | en
    if has_key(s:c1, a:s) | retu s:c1[a:s] | en
    if a:s =~# '^[\x00-\x7f]*$'
      let r = 2 * len(a:s) - len(substitute(a:s, '[\x00-\x08\x0b-\x1f\x7f]', '', 'g'))
      let s:c1[a:s] = r
      retu r
    end
    let f = '^\(.\)'
    let s = a:s
    let w = 0
    wh 1
      let u = char2nr(substitute(s, f, '\1', ''))
      if u == 0
        break
      en
      let w += s:H(u)
      let s = substitute(s, f, '', '')
    endw
    let s:c1[a:s] = w
    retu w
  endf

  let s:c2 = {}
  " fu! s:_wcwidth(u)
  fu! s:H(u)
    if has_key(s:c2, a:u) | retu s:c2[a:u] | en
    let u = a:u
    if u > 0x7f && u <= 0xff
      let r = 4
    en
    if u <= 0x08 || 0x0b <= u && u <= 0x1f || u == 0x7f
      let r = 2
    en
    if (u >= 0x1100
          \  && (u <= 0x115f
          \  || u == 0x2329
          \  || u == 0x232a
          \  || (u >= 0x2190 && u <= 0x2194)
          \  || (u >= 0x2500 && u <= 0x2573)
          \  || (u >= 0x2580 && u <= 0x25ff)
          \  || (u >= 0x2e80 && u <= 0xa4cf && u != 0x303f)
          \  || (u >= 0xac00 && u <= 0xd7a3)
          \  || (u >= 0xf900 && u <= 0xfaff)
          \  || (u >= 0xfe30 && u <= 0xfe6f)
          \  || (u >= 0xff00 && u <= 0xff60)
          \  || (u >= 0xffe0 && u <= 0xffe6)
          \  || (u >= 0x20000 && u <= 0x2fffd)
          \  || (u >= 0x30000 && u <= 0x3fffd)
          \  ))
      let r = 2
    el
      let r = 1
    en
    let s:c2[u] = r
    retu r
  endf

en

let &cpo = s:save_cpo
unlet s:save_cpo

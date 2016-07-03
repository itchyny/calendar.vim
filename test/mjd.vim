let s:suite = themis#suite('mjd')
let s:assert = themis#helper('assert')

function! s:suite.mjd()
  call s:assert.equals(calendar#mjd#new(0).mjd, 0)
  call s:assert.equals(calendar#mjd#new(10).mjd, 10)
  call s:assert.equals(calendar#mjd#new(20).mjd, 20)
endfunction

function! s:suite.add()
  let x = calendar#mjd#new(10)
  call s:assert.equals(x.add(10).mjd, 20)
  call s:assert.equals(x.mjd, 10)
  call s:assert.equals(calendar#mjd#new(10).add(5).add(10).add(5).mjd, 30)
endfunction

function! s:suite.sub()
  call s:assert.equals(calendar#mjd#new(10).sub(calendar#mjd#new(10)), 0)
  call s:assert.equals(calendar#mjd#new(10).sub(calendar#mjd#new(20)), -10)
  call s:assert.equals(calendar#mjd#new(20).sub(calendar#mjd#new(10)), 10)
endfunction

function! s:suite.eq()
  call s:assert.equals(calendar#mjd#new(10).eq(calendar#mjd#new(10)), 1)
  call s:assert.equals(calendar#mjd#new(10).eq(calendar#mjd#new(20)), 0)
  call s:assert.equals(calendar#mjd#new(20).eq(calendar#mjd#new(10)), 0)
endfunction

function! s:suite.is_after()
  call s:assert.equals(calendar#mjd#new(10).is_after(calendar#mjd#new(10)), 0)
  call s:assert.equals(calendar#mjd#new(10).is_after(calendar#mjd#new(20)), 0)
  call s:assert.equals(calendar#mjd#new(20).is_after(calendar#mjd#new(10)), 1)
endfunction

function! s:suite.is_after_or_eq()
  call s:assert.equals(calendar#mjd#new(10).is_after_or_eq(calendar#mjd#new(10)), 1)
  call s:assert.equals(calendar#mjd#new(10).is_after_or_eq(calendar#mjd#new(20)), 0)
  call s:assert.equals(calendar#mjd#new(20).is_after_or_eq(calendar#mjd#new(10)), 1)
endfunction

function! s:suite.is_before()
  call s:assert.equals(calendar#mjd#new(10).is_before(calendar#mjd#new(10)), 0)
  call s:assert.equals(calendar#mjd#new(10).is_before(calendar#mjd#new(20)), 1)
  call s:assert.equals(calendar#mjd#new(20).is_before(calendar#mjd#new(10)), 0)
endfunction

function! s:suite.is_before_or_eq()
  call s:assert.equals(calendar#mjd#new(10).is_before_or_eq(calendar#mjd#new(10)), 1)
  call s:assert.equals(calendar#mjd#new(10).is_before_or_eq(calendar#mjd#new(20)), 1)
  call s:assert.equals(calendar#mjd#new(20).is_before_or_eq(calendar#mjd#new(10)), 0)
endfunction

function! s:suite.is_sunday()
  call s:assert.equals(calendar#mjd#new(51544).is_sunday(), 0)
  call s:assert.equals(calendar#mjd#new(55197).is_sunday(), 0)
  call s:assert.equals(calendar#mjd#new(57023).is_sunday(), 0)
  call s:assert.equals(calendar#mjd#new(58849).is_sunday(), 0)
  call s:assert.equals(calendar#mjd#new(60676).is_sunday(), 0)
  call s:assert.equals(calendar#mjd#new(62502).is_sunday(), 0)
  call s:assert.equals(calendar#mjd#new(64328).is_sunday(), 0)
  call s:assert.equals(calendar#mjd#new(66154).is_sunday(), 1)
  call s:assert.equals(calendar#mjd#new(-277168).is_sunday(), 1)
endfunction

function! s:suite.is_monday()
  call s:assert.equals(calendar#mjd#new(51544).is_monday(), 0)
  call s:assert.equals(calendar#mjd#new(55197).is_monday(), 0)
  call s:assert.equals(calendar#mjd#new(57023).is_monday(), 0)
  call s:assert.equals(calendar#mjd#new(58849).is_monday(), 0)
  call s:assert.equals(calendar#mjd#new(60676).is_monday(), 0)
  call s:assert.equals(calendar#mjd#new(62502).is_monday(), 0)
  call s:assert.equals(calendar#mjd#new(64328).is_monday(), 1)
  call s:assert.equals(calendar#mjd#new(66154).is_monday(), 0)
  call s:assert.equals(calendar#mjd#new(-313693).is_monday(), 1)
endfunction

function! s:suite.is_tuesday()
  call s:assert.equals(calendar#mjd#new(51544).is_tuesday(), 0)
  call s:assert.equals(calendar#mjd#new(55197).is_tuesday(), 0)
  call s:assert.equals(calendar#mjd#new(57023).is_tuesday(), 0)
  call s:assert.equals(calendar#mjd#new(58849).is_tuesday(), 0)
  call s:assert.equals(calendar#mjd#new(60676).is_tuesday(), 0)
  call s:assert.equals(calendar#mjd#new(62502).is_tuesday(), 1)
  call s:assert.equals(calendar#mjd#new(64328).is_tuesday(), 0)
  call s:assert.equals(calendar#mjd#new(66154).is_tuesday(), 0)
  call s:assert.equals(calendar#mjd#new(-350218).is_tuesday(), 1)
endfunction

function! s:suite.is_wednesday()
  call s:assert.equals(calendar#mjd#new(51544).is_wednesday(), 0)
  call s:assert.equals(calendar#mjd#new(55197).is_wednesday(), 0)
  call s:assert.equals(calendar#mjd#new(57023).is_wednesday(), 0)
  call s:assert.equals(calendar#mjd#new(58849).is_wednesday(), 1)
  call s:assert.equals(calendar#mjd#new(60676).is_wednesday(), 1)
  call s:assert.equals(calendar#mjd#new(62502).is_wednesday(), 0)
  call s:assert.equals(calendar#mjd#new(64328).is_wednesday(), 0)
  call s:assert.equals(calendar#mjd#new(66154).is_wednesday(), 0)
  call s:assert.equals(calendar#mjd#new(-131068).is_wednesday(), 1)
endfunction

function! s:suite.is_thursday()
  call s:assert.equals(calendar#mjd#new(51544).is_thursday(), 0)
  call s:assert.equals(calendar#mjd#new(55197).is_thursday(), 0)
  call s:assert.equals(calendar#mjd#new(57023).is_thursday(), 1)
  call s:assert.equals(calendar#mjd#new(58849).is_thursday(), 0)
  call s:assert.equals(calendar#mjd#new(60676).is_thursday(), 0)
  call s:assert.equals(calendar#mjd#new(62502).is_thursday(), 0)
  call s:assert.equals(calendar#mjd#new(64328).is_thursday(), 0)
  call s:assert.equals(calendar#mjd#new(66154).is_thursday(), 0)
  call s:assert.equals(calendar#mjd#new(-167593).is_thursday(), 1)
endfunction

function! s:suite.is_friday()
  call s:assert.equals(calendar#mjd#new(51544).is_friday(), 0)
  call s:assert.equals(calendar#mjd#new(55197).is_friday(), 1)
  call s:assert.equals(calendar#mjd#new(57023).is_friday(), 0)
  call s:assert.equals(calendar#mjd#new(58849).is_friday(), 0)
  call s:assert.equals(calendar#mjd#new(60676).is_friday(), 0)
  call s:assert.equals(calendar#mjd#new(62502).is_friday(), 0)
  call s:assert.equals(calendar#mjd#new(64328).is_friday(), 0)
  call s:assert.equals(calendar#mjd#new(66154).is_friday(), 0)
  call s:assert.equals(calendar#mjd#new(-204118).is_friday(), 1)
endfunction

function! s:suite.is_saturday()
  call s:assert.equals(calendar#mjd#new(51544).is_saturday(), 1)
  call s:assert.equals(calendar#mjd#new(55197).is_saturday(), 0)
  call s:assert.equals(calendar#mjd#new(57023).is_saturday(), 0)
  call s:assert.equals(calendar#mjd#new(58849).is_saturday(), 0)
  call s:assert.equals(calendar#mjd#new(60676).is_saturday(), 0)
  call s:assert.equals(calendar#mjd#new(62502).is_saturday(), 0)
  call s:assert.equals(calendar#mjd#new(64328).is_saturday(), 0)
  call s:assert.equals(calendar#mjd#new(66154).is_saturday(), 0)
  call s:assert.equals(calendar#mjd#new(-240643).is_saturday(), 1)
endfunction

let s:suite = themis#suite('day')
let s:assert = themis#helper('assert')

function! s:suite.gregorian()
  let tests = [
        \ [[2000, 1, 1], 51544, 6],
        \ [[2020, 12, 31], 59214, 4],
        \ [[2023, 1, 1], 59945, 0],
        \ [[1858, 11, 17], 0, 3],
        \ [[1600, 1, 1], -94553, 6],
        \ [[1582, 10, 15], -100840, 5],
        \ [[1580, 1, 1], -101858, 2],
        \ ]
  for [ymd, mjd, week] in tests
    let day = calendar#day#gregorian#new(ymd[0], ymd[1], ymd[2])
    call s:assert.equals(day.is_valid(), 1)
    call s:assert.equals(day.get_ymd(), ymd)
    call s:assert.equals(day.get_year(), ymd[0])
    call s:assert.equals(day.get_month(), ymd[1])
    call s:assert.equals(day.get_day(), ymd[2])
    call s:assert.equals(day.mjd, mjd)
    call s:assert.equals(day.week(), week)
    call s:assert.equals(day.year().get_year(), ymd[0])
    call s:assert.equals(day.month().get_year(), ymd[0])
    call s:assert.equals(day.month().get_month(), ymd[1])
    call s:assert.equals(day.is_gregorian(), 1)
  endfor
endfunction

function! s:suite.julian()
  let tests = [
        \ [[2000, 1, 1], 51557, 5],
        \ [[2020, 12, 31], 59227, 3],
        \ [[2023, 1, 1], 59958, 6],
        \ [[1858, 11, 17], 12, 1],
        \ [[1600, 1, 1], -94543, 2],
        \ [[1582, 10, 4], -100841, 4],
        \ [[1580, 1, 1], -101848, 5],
        \ ]
  for [ymd, mjd, week] in tests
    let day = calendar#day#julian#new(ymd[0], ymd[1], ymd[2])
    call s:assert.equals(day.is_valid(), 1)
    call s:assert.equals(day.get_ymd(), ymd)
    call s:assert.equals(day.get_year(), ymd[0])
    call s:assert.equals(day.get_month(), ymd[1])
    call s:assert.equals(day.get_day(), ymd[2])
    call s:assert.equals(day.mjd, mjd)
    call s:assert.equals(day.week(), week)
    call s:assert.equals(day.year().get_year(), ymd[0])
    call s:assert.equals(day.month().get_year(), ymd[0])
    call s:assert.equals(day.month().get_month(), ymd[1])
    call s:assert.equals(day.is_gregorian(), 0)
  endfor
endfunction

function! s:suite.default()
  let tests = [
        \ [[2000, 1, 1], 51544, 6, 1],
        \ [[2020, 12, 31], 59214, 4, 1],
        \ [[2023, 1, 1], 59945, 0, 1],
        \ [[1858, 11, 17], 0, 3, 1],
        \ [[1600, 1, 1], -94553, 6, 1],
        \ [[1582, 10, 15], -100840, 5, 1],
        \ [[1582, 10, 4], -100841, 4, 0],
        \ [[1580, 1, 1], -101848, 5, 0],
        \ ]
  for [ymd, mjd, week, is_gregorian] in tests
    let day = calendar#day#default#new(ymd[0], ymd[1], ymd[2])
    call s:assert.equals(day.is_valid(), 1)
    call s:assert.equals(day.get_ymd(), ymd)
    call s:assert.equals(day.get_year(), ymd[0])
    call s:assert.equals(day.get_month(), ymd[1])
    call s:assert.equals(day.get_day(), ymd[2])
    call s:assert.equals(day.mjd, mjd)
    call s:assert.equals(day.week(), week)
    call s:assert.equals(day.year().get_year(), ymd[0])
    call s:assert.equals(day.month().get_year(), ymd[0])
    call s:assert.equals(day.month().get_month(), ymd[1])
    call s:assert.equals(day.is_gregorian(), is_gregorian)
  endfor
endfunction

function! s:suite.british()
  let tests = [
        \ [[2000, 1, 1], 51544, 6, 1],
        \ [[2020, 12, 31], 59214, 4, 1],
        \ [[2023, 1, 1], 59945, 0, 1],
        \ [[1858, 11, 17], 0, 3, 1],
        \ [[1752, 9, 14], -38779, 4, 1],
        \ [[1752, 9, 2], -38780, 3, 0],
        \ [[1600, 1, 1], -94543, 2, 0],
        \ [[1582, 10, 15], -100830, 1, 0],
        \ [[1582, 10, 4], -100841, 4, 0],
        \ [[1580, 1, 1], -101848, 5, 0],
        \ ]
  for [ymd, mjd, week, is_gregorian] in tests
    let day = calendar#day#british#new(ymd[0], ymd[1], ymd[2])
    call s:assert.equals(day.is_valid(), 1)
    call s:assert.equals(day.get_ymd(), ymd)
    call s:assert.equals(day.get_year(), ymd[0])
    call s:assert.equals(day.get_month(), ymd[1])
    call s:assert.equals(day.get_day(), ymd[2])
    call s:assert.equals(day.mjd, mjd)
    call s:assert.equals(day.week(), week)
    call s:assert.equals(day.year().get_year(), ymd[0])
    call s:assert.equals(day.month().get_year(), ymd[0])
    call s:assert.equals(day.month().get_month(), ymd[1])
    call s:assert.equals(day.is_gregorian(), is_gregorian)
  endfor
endfunction

function! s:suite.add_sub()
  let tests = [
        \ [[2000, 1, 1], 1000, [2002, 9, 27]],
        \ [[2020, 12, 31], -10000, [1993, 8, 15]],
        \ [[1600, 1, 1], 1000000, [4337, 11, 28]],
        \ [[1582, 10, 15], -1, [1582, 10, 4]],
        \ [[1582, 10, 4], 1, [1582, 10, 15]],
        \ [[1, 1, 1], 1000000, [2738, 11, 27]],
        \ ]
  for [ymd, diff, new_ymd] in tests
    let day = calendar#day#new(ymd[0], ymd[1], ymd[2])
    call s:assert.equals(day.add(diff).get_ymd(), new_ymd)
    call s:assert.equals(day.sub(calendar#day#new(new_ymd[0], new_ymd[1], new_ymd[2])), -diff)
    call s:assert.equals(calendar#day#new(new_ymd[0], new_ymd[1], new_ymd[2]).sub(day), diff)
  endfor
endfunction

function! s:suite.join_date()
  let tests = [
        \ [[2022, 10, 11], 'big', '/', '2022/10/11', '10/11'],
        \ [[2022, 10, 11], 'little', '/', '11/10/2022', '11/10'],
        \ [[2022, 10, 11], 'middle', '/', '10/11/2022', '10/11'],
        \ [[2022, 10, 11], 'big', '-', '2022-10-11', '10-11'],
        \ [[2022, 10, 11], 'little', '-', '11-10-2022', '11-10'],
        \ [[2022, 10, 11], 'middle', '-', '10-11-2022', '10-11'],
        \ ]
  for [ymd, endian, separator, expected_ymd, expected_md] in tests
    let message = printf('ymd:%s, endian:%s, separator:%s', ymd, endian, separator)
    let day = calendar#day#new(ymd[0], ymd[1], ymd[2])
    let g:calendar_date_endian = endian
    let g:calendar_date_separator = separator
    let g:calendar_date_month_name = 0
    call s:assert.equals(calendar#day#join_date(day.get_ymd()), expected_ymd, message)
    call s:assert.equals(calendar#day#join_date(day.get_ymd()[1:]), expected_md, message)
  endfor
endfunction

function! s:suite.join_date_range()
  let g:calendar_date_endian = 'big'
  let g:calendar_date_separator = '-'
  let g:calendar_date_month_name = 0
  let tests = [
        \ [[2022, 10, 11], [2022, 10, 11], '10-11'],
        \ [[2022, 10, 11], [2022, 10, 12], '10-11 - 10-12'],
        \ [[2022, 10, 11], [2022, 10, 10], '10-10 - 10-11'],
        \ [[2022, 10, 11], [2022, 10, 9], '10-9 - 10-11'],
        \ [[2022, 10, 11], [2022, 11, 12], '10-11 - 11-12'],
        \ [[2022, 10, 11], [2022, 10, 1], '10-1 - 10-11'],
        \ [[2022, 10, 11], [2022, 9, 30], '9-30 - 10-11'],
        \ [[2022, 10, 11], [2023, 10, 11], '2022-10-11 - 2023-10-11'],
        \ [[2022, 10, 11], [2021, 10, 11], '2021-10-11 - 2022-10-11'],
        \ ]
  for [x, y, expected] in tests
    let message = printf('x:%s, y:%s', x, y)
    let day_x = calendar#day#new(x[0], x[1], x[2])
    let day_y = calendar#day#new(y[0], y[1], y[2])
    call s:assert.equals(calendar#day#join_date_range(day_x, day_y), expected, message)
  endfor
endfunction

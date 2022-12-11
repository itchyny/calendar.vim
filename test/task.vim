let s:suite = themis#suite('task')
let s:assert = themis#helper('assert')

function! s:suite.before_each()
  let b:calendar = {'day': {-> {'get_ymd': {-> [2023, 3, 2]}}}}
endfunction

function! s:suite.parse_title()
  let tests = [
        \ ['hello', '', 'hello', ''],
        \ ['2022-10-5 hello', 'big', 'hello', '2022-10-05T00:00:00Z'],
        \ ['2022/10/5 hello', 'big', 'hello', '2022-10-05T00:00:00Z'],
        \ ['2022-10/5 hello', 'big', 'hello', '2022-10-05T00:00:00Z'],
        \ ['2022/5-10 hello', 'big', 'hello', '2022-05-10T00:00:00Z'],
        \ ["2022/10/5 \t \t hello", 'big', 'hello', '2022-10-05T00:00:00Z'],
        \ ['2-5-2022 hello', 'little', 'hello', '2022-05-02T00:00:00Z'],
        \ ['2/5/2022 hello', 'little', 'hello', '2022-05-02T00:00:00Z'],
        \ ['2-5-2022 hello', 'middle', 'hello', '2022-02-05T00:00:00Z'],
        \ ['2/5/2022 hello', 'middle', 'hello', '2022-02-05T00:00:00Z'],
        \ ['1/5 hello', 'big', 'hello', '2024-01-05T00:00:00Z'],
        \ ['2/5 hello', 'big', 'hello', '2024-02-05T00:00:00Z'],
        \ ['3/5 hello', 'big', 'hello', '2023-03-05T00:00:00Z'],
        \ ['4/5 hello', 'big', 'hello', '2023-04-05T00:00:00Z'],
        \ ['2/5 hello', 'little', 'hello', '2023-05-02T00:00:00Z'],
        \ ['2/5 hello', 'middle', 'hello', '2024-02-05T00:00:00Z'],
        \ ]
  for [src, endian; expected] in tests
    let message = printf('src: %s, endian: %s', src, endian)
    let g:calendar_date_endian = endian
    call s:assert.equals(calendar#view#task#parse_title(src), expected, message)
  endfor
endfunction

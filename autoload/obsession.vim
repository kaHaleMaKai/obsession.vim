if exists('g:obsession_loaded')
  finish
endif
let g:obsession_loaded = v:true


if exists('$XDG_CACHE_DIR')
  let cache_dir = $XDG_CACHE_DIR
else
  let cache_dir = path#join($HOME, '.cache')
endif

let s:default_session_dir = path#join(cache_dir, 'vim', 'obsession.vim')
let s:session_dir = get(g:, 'session_dir', s:default_session_dir)
let s:work_dir = getcwd()


fun! s:get_num_buffers() abort "{{{
  return len(getbufinfo({'buflisted':1}))
endfun "}}}


fun! obsession#get_work_dir() abort "{{{
  return s:work_dir
endfun "}}}


fun! obsession#get_session_dir() abort "{{{
  return s:session_dir
endfun "}}}


fun! obsession#get_dir_hash(dir) abort "{{{
  return split(systemlist(['md5sum'], a:dir)[0])[0]
endfun "}}}


fun! obsession#get_session_file(dir) abort "{{{
  let dir_hash = obsession#get_dir_hash(a:dir)
  return path#join(s:session_dir, dir_hash)
endfun "}}}


fun! obsession#save_session_by_dir(dir, ...) abort "{{{
  if obsession#is_empty_view()
    return
  endif
  let session_file = obsession#get_session_file(a:dir)
  if !filewritable(s:session_dir)
    call mkdir(s:session_dir, 'p')
  endif
  exe printf('mksession! %s', session_file)
  let original_content = readfile(session_file)
  if has_key(get(a:000, 0, {}), 'content_filter_fn')
    let content = a:1.content_filter_fn(original_content)
  else
    let content = original_content
  endif
  call writefile(content, session_file)
endfun "}}}


fun! obsession#restore_session_by_dir_if_exists(dir) abort "{{{
  let session_file = obsession#get_session_file(a:dir)
  if filewritable(session_file)
    exe printf('source %s', session_file)
  endif
endfun "}}}


fun! obsession#ack(dir) abort "{{{
  let session_file = obsession#get_session_file(a:dir)
  call inputsave()
  let ack = input('Restore session? [Yn] ')
  call inputrestore()
  return empty(ack) || tolower(ack) == 'y'
endfun "}}}


fun! obsession#remove_session_file(dir) abort "{{{
  let session_file = obsession#get_session_file(a:dir)
  if !filewritable(session_file)
    return
  endif
  call delete(session_file)
endfun "}}}


fun! obsession#exists(dir) abort "{{{
  return filewritable(obsession#get_session_file(a:dir)) == 1
endfun "}}}


fun! obsession#is_git_related() abort "{{{
 let filename = expand('%:p:h:t')
 return filename == '.git' && s:get_num_buffers() == 1
endfun "}}}


fun! obsession#is_empty_view() abort "{{{
  return empty(expand('%')) && s:get_num_buffers() == 1
endfun "}}}


fun! obsession#is_allowed(dir) abort "{{{
  return get(g:, 'obsession_auto_save', v:true)
        \ || obsession#exists(a:dir)
endfun "}}}

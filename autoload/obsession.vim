if exists('g:obsession_loaded')
  finish
endif
let g:obsession_loaded = v:true


if exists('$XDG_CACHE_DIR')
  let cache_dir = $XDG_CACHE_DIR
else
  let cache_dir = path#join($HOME, '.cache')
endif

let s:default_obsession_dir = path#join(cache_dir, 'vim', 'obsession.vim')
let s:obsession_base_dir = get(g:, 'obsession_dir', s:default_obsession_dir)
let s:session_dir = path#join(s:obsession_base_dir, 'sessions')
let s:undo_dir = path#join(s:obsession_base_dir, 'undo')
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


fun! obsession#get_hash(dir) abort "{{{
  return split(systemlist(['md5sum'], a:dir)[0])[0]
endfun "}}}


fun! obsession#get_session_file(dir) abort "{{{
  let dir_hash = obsession#get_hash(a:dir)
  return path#join(s:session_dir, dir_hash)
endfun "}}}


fun! obsession#save_session_by_dir(dir, ...) abort "{{{
  if obsession#is_empty_view()
    return
  endif
  let session_file = obsession#get_session_file(a:dir)
  if !filewritable(s:session_dir)
    call mkdir(s:session_dir, 'p', 0700)
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
 let dir = expand('%:p')
 return dir =~# '/\.git\(/\|$\)' && s:get_num_buffers() == 1
endfun "}}}


fun! obsession#is_empty_view() abort "{{{
  return empty(expand('%')) && s:get_num_buffers() == 1
endfun "}}}


fun! obsession#is_allowed(dir) abort "{{{
  return get(g:, 'obsession_auto_save', v:true)
        \ || obsession#exists(a:dir)
endfun "}}}


fun! obsession#get_undo_file(dir) abort "{{{
  let hash = obsession#get_hash(a:dir)
  return path#join(s:undo_dir, hash)
endfun "}}}


fun! obsession#save_undo_history(dir) abort "{{{
  let undo_file = obsession#get_undo_file(a:dir)
  if !filewritable(s:undo_dir)
    call mkdir(s:undo_dir, 'p', 0700)
  endif
  exe printf('wundo! %s', undo_file)
endfun "}}}


fun! obsession#read_undo_history(dir) abort "{{{
  let undo_file = obsession#get_undo_file(a:dir)
  if !filereadable(undo_file)
    return
  endif
  silent! exe printf('rundo %s', undo_file)
endfun "}}}


" TODO check if we have options or files that should actually
" prevent a session from being loaded instead of
" merely checking whether args are present.
fun! obsession#started_with_args() abort "{{{
  return !empty(argv())
endfun "}}}

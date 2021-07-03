if exists('g:obsession_plugin_loaded')
  finish
endif
let g:obsession_plugin_loaded = v:true
let s:obsession_initialized = v:false

let s:default_exclusion_dirs = [$HOME, '/tmp']
let exclusion_dirs = get(g:, 'obsession_exlusion_dirs', s:default_exclusion_dirs)
if index(exclusion_dirs, getcwd()) > -1
  finish
endif

let s:work_dir = getcwd()


fun! s:uninitialize() abort "{{{
  call obsession#remove_session_file(s:work_dir)
  if !s:obsession_initialized
    return
  endif

  augroup obsession_save_progress
    au!
  augroup END
  augroup! obsession_save_progress
endfun "}}}


fun! s:save_session() abort "{{{
  call obsession#save_session_by_dir(s:work_dir)
  call s:safely_init_autogroups()
endfun "}}}


fun! s:restore_session() abort "{{{
  call s:safely_init_autogroups()
  call obsession#restore_session_by_dir_if_exists(s:work_dir)
endfun "}}}


fun! s:store_if_allowed() abort "{{{
  if !obsession#is_allowed(s:work_dir)
    return
  elseif obsession#is_empty_view() || obsession#is_git_related()
    return
  endif
  call obsession#save_session_by_dir(s:work_dir)
endfun "}}}


fun! s:safely_init_autogroups() abort "{{{
  if s:obsession_initialized
    return
  endif

  augroup obsession_save_progress
    au!
    au BufEnter * call s:store_if_allowed()
    au VimLeavePre * call s:store_if_allowed()
  augroup END

  let s:obsession_initialized = v:true
endfun "}}}


fun! s:init_commands() abort "{{{
  command!
        \ -nargs=0
        \ Unobsess
        \ call <sid>uninitialize()

  command!
        \ -nargs=0
        \ Obsess
        \ call <sid>save_session()

  command!
        \ -nargs=0
        \ Obload
        \ call <sid>restore_session()
endfun "}}}


fun! s:init() abort "{{{
  if obsession#is_git_related()
    return
  endif
  if obsession#exists(s:work_dir) && obsession#ack(s:work_dir)
    call obsession#restore_session_by_dir_if_exists(s:work_dir)
    call s:safely_init_autogroups()
  elseif obsession#is_allowed(s:work_dir)
    call s:safely_init_autogroups()
  endif
  call s:init_commands()

endfun "}}}


call s:init()
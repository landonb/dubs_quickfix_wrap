" vim:tw=0:ts=2:sw=2:et:norl:
" Author: Landon Bouma <https://tallybark.com/>
" Project: https://github.com/landonb/dubs_quickfix_wrap#🌯
" Summary: Quickfix-related commands
" License: GPLv3

" -------------------------------------------------------------------

" ABOUT:
"
" A simple wrapper around QuickFix.
"
" - Creates a toggle around :copen and :cclose
"
" - Remembers the last window height.

" -------------------------------------------------------------------

" GUARD: Press <F9> to reload this plugin (or :source it).
" - Via: https://github.com/embrace-vim/vim-source-reloader#↩️

if expand('%:p') ==# expand('<sfile>:p')
  unlet! g:plugin_dubs_quickfix_wrap
endif

if exists('g:plugin_dubs_quickfix_wrap') || &cp

  finish
endif

let g:plugin_dubs_quickfix_wrap = 1

" -------------------------------------------------------------------

" Sticky Height:
" - Note that (Neo)vim sets &winfixheight = 1 on the quickfix window,
"   so it shouldn't change size when you open/close wiindow panes or
"   resize the application window (i.e., unaffected by &equalalways).

" Spell Checking:
" - If you generally enable spell check and want to avoid distracting
"   spell checks in the quickfix results, especially useful when
"   searching code, consider adding an autocmd to disable spell,
"   e.g.,:
"
"   autocmd BufWinEnter quickfix setlocal nospell

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" Quickfix Toggle
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" http://vim.wikia.com/wiki/Toggle_to_open_or_close_the_quickfix_window
" (Quickfix is Vim's search results window, among other things.
"  It's also global, as opposed to the one-per-window location list.)

" Alt-Shift-3 // Toggle Quickfix Window
" -------------------------------------
" Opt-in <Shift-Alt-3> aka <M-#> Quickfix toggle.
if get(g:, 'dubs_quickfix_wrap_create_maps', 0)
  " Ideally, we'd suss meta enablement and only use <M-#> or ‹ but we're not
  " that savvy. Also it's best if user create these maps themselves (which is
  " why these maps are opt-in), so not gonna worry about it further.
  nnoremap <M-#> :QFix(0)<CR>
  inoremap <M-#> <C-O>:QFix(0)<CR>
  if has('macunix')
    " Literal macOS <Option-#>.
    nnoremap ‹ :QFix(0)<CR>
    inoremap ‹ <C-O>:QFix(0)<CR>
  endif
endif

" Latest Quickfix window height, used to restore on :copen.
function! s:QuickfixWinHeight() abort
  return get(g:, 'jah_Quickfix_Win_Height', 8)
endfunction

command -bang -nargs=* QFix
  \ :call <SID>QFixToggle(<bang>0, <args>)
function! <SID>QFixToggle(forced, tail_it)
  let l:is_qfix_showing = s:IsQuickFixShowing()
  if (l:is_qfix_showing == 1 && a:forced != 1) || a:forced == -1
    " Already showing and not being forced open, or being force closed.
    if l:is_qfix_showing == 1
      call <SID>QFixToggle_Hide()
    endif
  elseif (l:is_qfix_showing == 0 && a:forced != -1) || a:forced == 1
    " Not showing and not being forced-hidden, or being forced to show.
    if l:is_qfix_showing == 0
      call <SID>QFixToggle_Show()
    endif
  endif
  if s:IsQuickFixShowing() == 1 && a:tail_it == 1
    " Scroll to the bottom of the Quickfix window .
    " (This is useful to see if there are any make errors.)
    let l:restore_winnr = winnr()
    copen
    normal G
    execute l:restore_winnr . 'wincmd w'
  endif
endfunction

function! s:QFixToggle_Hide()
  " Remember the active window.
  let l:restore_winnr = s:QFixFindSafeWindow()
  " Switch to the Quickfix window.
  copen
  " Remember the height of the Quickfix window.
  let g:jah_Quickfix_Win_Height = winheight(winnr())
  " If the window above the Quickfix is a Location List, then closing
  " the Quickfix window messes up the Location List's height. We'll fix
  " it later.
  " - DUNNO: This functionality has not been verified in ages.
  let l:prev_winnr = winnr("k") != winnr() ? winnr("k") : 0
  " Close the Quickfix window.
  cclose
  " Resize the location list, if applicable.
  call s:QFixResizeLocationList(l:prev_winnr, l:restore_winnr)
endfunction

function! s:QFixFindSafeWindow()
  let l:restore_winnr = winnr()

  " 2017-12-14: Get outta the quickfix window!
  if (&buftype == 'quickfix')
    if winnr('$') > 1
      try
        wincmd p
        let l:restore_winnr = winnr()
        wincmd p
      catch
        " echom "Buffer is locked! Cannot switch windows."
      endtry
    else
      enew
    endif
  endif

  return l:restore_winnr
endfunction

function! s:QFixResizeLocationList(prev_winnr, restore_winnr)
  if a:prev_winnr != 0 && getbufvar(winbufnr(a:prev_winnr), "&filetype") == 'qf'
    " Switch to the location list.
    execute '' . a:prev_winnr . 'wincmd w'
    " Resize the location list.
    execute "resize -" . s:QuickfixWinHeight()
  endif
  " Reactivate the previously active window.
  execute a:restore_winnr . 'wincmd w'
endfunction

function! s:QFixToggle_Show()
  let l:restore_winnr = winnr()
  " Use botright so that copen uses the full width of the window.
  " - A plain copen creates a Quickfix window positioned under
  "   and as wide as the last window.
  execute "botright copen " . s:QuickfixWinHeight()
  execute l:restore_winnr . 'wincmd w'
endfunction

function! s:IsQuickFixShowing() abort
  return getqflist({'winid' : 1}).winid != 0
endfunction

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" Search-Replace Text in All Files Listed in Quickfix Window
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" Search and replace selected term all files listed in Quickfix
" -------------------------------------------------------------
" This fcn. opens every file in the Quickfix list and does a bufdo, e.g., 
"    :bufdo .,$s/Search/Replace/g

" NOTE: This fcn. opens each QF result and runs substitute.
" - It works, but it's somewhat klunky, and slow. You might be
"   better off using `sed` from a shell. Or a different plugin.

" Typical use: Search for a term in the project directory.
"              Open one of the results, select the term,
"              type \S, refine the regex and add the substitution,
"              then hit <Enter>. Substitutions galore!

" See also: There are much more advanced search-replace plugins.
" - E.g., see grug-far:
"   https://github.com/MagicDuck/grug-far.nvim

" NOTE: If you're running Noice, you won't see the cmdline until you
" press a key...
" - INERT: Is there a work around?

if get(g:, 'dubs_quickfix_wrap_create_maps', 0)
  nnoremap <LocalLeader>SQ "sy:call QuickfixSubstituteAll("<C-r>s", "")<Left><Left>
endif

" USAGE: This fcn. requires the user to do an initial search. That is, this 
"        fcn. does not search the term being replaced, but rather just uses
"        the existing Quickfix error list
function QuickfixSubstituteAll(search, replace)
  " Remember the current buffer so we can jump back to it later
  let l:curwinnr = winnr()
  let l:curbufnr = winbufnr("%")

  " Remember if the Quickfix is currently showing so we can hide it
  let l:hide_quickfix = !(s:IsQuickFixShowing())

  " Open and jump to the Quickfix/error list
  copen

  " Make sure we're on the first line
  normal gg

  " Make sure that's at least one error in the list
  let l:errors_count = len(getqflist({'winid' : 1}))
  let l:buffers_edited = 0

  if l:errors_count
    " Open all the files listed, starting with the first file in the list
    cc! 1
    " Open the remaining files using a handy Quickfix command
    let l:line_num_cur = line(".")
    let l:line_num_prev = 0
    while l:line_num_cur != l:line_num_prev
      " The cnf command opens the next file listed in the error list, and it 
      " reports an error if there isn't a next file to open. We can suppress 
      " the error with a banged-silence command, and we can check if we've 
      " opened the last file by checking if the cursor has changed lines.
      silent! cnf
      " Make sure we jump back to the Quickfix window.
      copen
      let l:line_num_prev = l:line_num_cur
      let l:line_num_cur = line(".")
    endwhile
    " Run the find/replace command on all the open buffers.
    " NOTE: If the user has buffers open that aren't in Quickfix,
    "       these will also be run through this command.
    "
    " First show the user how many matches there are.
    " NOTE: Moved to last call of fcn., otherwise the [b]buffer
    "       command overwrites it, even with silent! in use.
    copen
    normal gg
    " REFER: substitute flags:
    "   g - global (find all matches, not just one)
    "   n - don't replace, just count matches
    "   I - don't ignore case
    execute ".,$s/" . a:search . "/" . a:replace . "/gnI"
    "
    " Go back to the window the user was in, otherwise we'll open 
    " the buffers in the Quickfix window.
    exe l:curwinnr . "wincmd w"
    " Walk the quickfix list and perform the find/replace operations.
    let l:walking = 1
    let l:prev_bufnr = -1
    cc 1
    while l:walking
      let l:cur_bufnr = bufnr()
      if l:prev_bufnr != l:cur_bufnr
        if getbufvar(l:cur_bufnr, '&modifiable') == 1
          execute "silent! .,$s/" . a:search . "/" . a:replace . "/gI"

          let l:buffers_edited += 1
        endif
      endif
      let l:prev_bufnr = l:cur_bufnr
      try
        cnext
      catch
        let l:walking = 0
      endtry
    endwhile
  endif

  " Close Quickfix if it was originally closed.
  if l:hide_quickfix
    call s:QFixToggle(-1, 0)
  endif

  " Go back to the window and buffer the user called us from.
  exe l:curwinnr . "wincmd w"
  silent! execute "buffer " . l:curbufnr

  " Print a status message.
  if !l:errors_count
    echo "Nothing to do: no errors in the Quickfix error list!"
  else
    echom "Edited " .. string(l:buffers_edited) .. " files (from " .. string(l:errors_count) .. " qf items)"
  endif
endfunction


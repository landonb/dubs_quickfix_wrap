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
" Height Issues
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" Toggle Annoyance
" ------------------------------------------------------
" When toggling the quickfix window,
" make sure it only increases/decreases
" the height of the window adjacent to 
" it (above it). Default Vim behavior 
" is to resize all window the same size.
set noequalalways

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

" See also: <Leader>s (\s), \S's little sibling that just
"           find-replaces in the current buffer.

" See also: There are much more advanced search-replace plugins.
" - E.g., see grug-far:
"   https://github.com/MagicDuck/grug-far.nvim

" NOTE: If you're running Noice, you won't see the cmdline until you
" press a key...
" - INERT: Is there a work around?

if get(g:, 'dubs_quickfix_wrap_create_maps', 0)
  nnoremap <Leader>SQ "sy:call QuickfixSubstituteAll("<C-r>s", "")<Left><Left>
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
  " Get some stats on the error list
  let l:first_line_len = col("$")
  let l:window_last_line = line("w$")
  let l:errors_exist = (l:window_last_line > 1) || (l:first_line_len > 1)

  " Make sure that's at least one error in the list
  if l:errors_exist
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
    " g - global (find all matches, not just one)
    " n - don't replace, just count matches
    " I - don't ignore care
    execute ".,$s/" . a:search . "/" . a:replace . "/gnI"
    "
    " Go back to the window the user was in, otherwise we'll open 
    " the buffers in the Quickfix window.
    exe l:curwinnr . "wincmd w"
    " Perform the find/replace operation.
    " e - skip errors (else it stops when it tries the Quickfix buffer)
    "execute "silent! bufdo .,$s/" . a:search . "/" . a:replace . "/geI"
    " NOTE The last command fails on "no modifiable", even though I 
    "      though the -e switch should get around that. Alas, it doesn't, 
    "      so go through the buffers the old fashioned way.
    bfirst
    let l:bufnrs = filter(range(1, bufnr('$')), 'buflisted(v:val)')
    for l:curnr in l:bufnrs
      if getbufvar(l:curnr, '&modifiable') == 1
        execute "silent! .,$s/" . a:search . "/" . a:replace . "/gI"
      endif
      bnext
    endfor
  endif

  " Close Quickfix if it was originally closed.
  if l:hide_quickfix
    " So, "s:QFixToggle(-1, 0)" does not work, but "call <SID>..." does
    call <SID>QFixToggle(-1, 0)
  endif

  " Go back to the window and buffer the user called us from.
  exe l:curwinnr . "wincmd w"
  " Ug. This silent! doesn't work like if does when I just run it myself...
  "execute "silent! buffer! " . l:curbufnr
  silent! execute "buffer " . l:curbufnr

  " Print a status message.
  if !l:errors_exist
    echo "Nothing to do: no errors in the Quickfix error list!"
  else
    " This is weird, but it's the only way I can figure out 
    " how to show the user how many changes were made
    " NOTE Calling :messages shows the whole message file, 
    "      which might be larger than a single page. Fortunately, 
    "      we can call g< to see just the last message, which 
    "      handles to be the s//gn call that gave us a count.
    execute "g<"
  endif
endfunction

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" Obsolete Functions
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" Always sort the Quickfix list
" ------------------------------------------------------
" http://vim.wikia.com/wiki/Automatically_sort_Quickfix_list
function! s:CompareQuickfixEntries(i1, i2)
  if bufname(a:i1.bufnr) == bufname(a:i2.bufnr)
    return a:i1.lnum == a:i2.lnum ? 0 : (a:i1.lnum < a:i2.lnum ? -1 : 1)
  else
    return bufname(a:i1.bufnr) < bufname(a:i2.bufnr) ? -1 : 1
  endif
endfunction

function! s:SortUniqQFList()
  let sortedList = sort(getqflist(), 's:CompareQuickfixEntries')
  let uniqedList = []
  let last = ''
  for item in sortedList
    let this = bufname(item.bufnr) . "\t" . item.lnum
    if this !=# last
      call add(uniqedList, item)
      let last = this
    endif
  endfor
  call setqflist(uniqedList)
endfunction

" 2014.01.31: [lb] moved from Vim 7.3 and Vim 7.4, from Fedora 14
"             to Linux Mint 16, and now this fcn. messes up our
"             Cyclopath <F7> function, which is to open the flash
"             log file. In latter Vim, it opens the log, but it
"             _only_ shows matching entries, i.e., errors and
"             their files and line numbers, but the rest of the
"             log file is omitted. How can I debug easily without
"             my trace messages?
"             Anyway, this feature is silly: we don't need to sort
"             the quickfix list and remove duplicates, since we're
"             inspecting log files and not, e.g., well, I don't
"             know what the use case of this feature is.
"autocmd! QuickfixCmdPost * call s:SortUniqQFList()

" 2016.01.27: What's up with spell check enabled in the quickfix?
"             It's annoying when I'm reading code!
autocmd BufWinEnter quickfix setlocal nospell


" File: dubs_quickfix_wrap.vim
" Author: Landon Bouma (landonb &#x40; retrosoft &#x2E; com)
" Last Modified: 2017.12.14
" Project Page: https://github.com/landonb/dubs_quickfix_wrap
" Summary: Quickfix wrapper
" License: GPLv3
" -------------------------------------------------------------------
" Copyright © 2009, 2015-2017 Landon Bouma.
" 
" This file is part of Dubs Vim.
" 
" Dubs Vim is free software: you can redistribute it and/or
" modify it under the terms of the GNU General Public License
" as published by the Free Software Foundation, either version
" 3 of the License, or (at your option) any later version.
" 
" Dubs Vim is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty
" of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See
" the GNU General Public License for more details.
" 
" You should have received a copy of the GNU General Public License
" along with Dubs Vim. If not, see <http://www.gnu.org/licenses/>
" or write Free Software Foundation, Inc., 51 Franklin Street,
"                     Fifth Floor, Boston, MA 02110-1301, USA.
" ===================================================================

" ------------------------------------------
" About:

" A simple wrapper around QuickFix.
"
" The quickfix window is nifty but has a few limitations:
"
"   - There's no easy, built-in method for toggling
"     its visibility.
"
"   - When hiding the quickfix, it affects other windows'
"     heights, which this script stops from happening.

if exists("g:plugin_dubs_quickfix_wrap") || &cp
  finish
endif
let g:plugin_dubs_quickfix_wrap = 1

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" Quickfix Toggle
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" http://vim.wikia.com/wiki/Toggle_to_open_or_close_the_quickfix_window
" (Quickfix is Vim's search results window, among other things.
"  It's also global, as opposed to the one-per-window location list.)

" Alt-Shift-3 // Toggle Search Results
" --------------------------------
" Or, in Vim terms, quickfix window
" BUGBUG Sometimes after closing quickfix
"        toggling the window no longer 
"        works (you'll see :QFix in the 
"        command-line window but nothing
"        happens). For now, just use 
"        :copen to force it open, then 
"        toggling works again.
" (Note: It's M-#, not M-S-3)
" SYNC_ME: Dubs Vim's <M-????> mappings are spread across plugins. [M-S-3]
nnoremap <M-#> :QFix(0)<CR>
inoremap <M-#> <C-O>:QFix(0)<CR>
"cnoremap <M-#> <C-C>:QFix<CR>
"onoremap <M-#> <C-C>:QFix<CR>

" TODO Make height settable or at least 
"      remember/restore between toggles
"let g:jah_Quickfix_Win_Height=14
let g:jah_Quickfix_Win_Height=8

command -bang -nargs=* QFix
  \ :call <SID>QFixToggle(<bang>0, <args>)
function! <SID>QFixToggle(forced, tail_it)
  "call inputsave()
  "let TBD = input("forced: ". a:forced, " / tail_it: ". a:tail_it)
  "call inputrestore()
  let l:restore_minibufexp = s:IsMiniBufExplorerShowing()
  let l:is_qfix_showing = s:IsQuickFixShowing()
  if (l:is_qfix_showing == 1 && a:forced != 1) || a:forced == -1
    " Already showing and not being forced open, or being force closed.
    if l:is_qfix_showing == 1
      call <SID>QFixToggle_Hide(l:restore_minibufexp)
    endif
  elseif (l:is_qfix_showing == 0 && a:forced != -1) || a:forced == 1
    " Not showing and not being forced-hidden, or being forced to show.
    if l:is_qfix_showing == 0
      call <SID>QFixToggle_Show(l:restore_minibufexp)
      " FIXME: If a location list is showing, toggling the quickfix
      "        increases the height of the location list each time
      "        the quickfix is shown (decreasing the height of the
      "        buffer window above it).
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

function! s:QFixToggle_Hide(restore_minibufexp)
  " Remember the active window.
  let l:restore_winnr = s:QFixFindSafeWindow()
  " Switch to the Quickfix window.
  copen
  " Remember the height of the Quickfix window.
  let g:jah_Quickfix_Win_Height = winheight(winnr())
  " If the window before the Quickfix is a Location List
  " (e.g., one of Syntastic's), then closing the Quickfix
  " window messes up the Location List's height. We'll fix
  " it later.
  let l:last_llist_winnr = winnr() - 1
  "call inputsave()
  "let TBD = input("g:jah_Quickfix_Win_Height: "
  "                \ . g:jah_Quickfix_Win_Height)
  "call inputrestore()
  " Close the minibuf explorer window (if it's open).
  " 2015.01.15: Deprecated: CMiniBufExplorer, replaced by MBEClose.
  " 2017-11-02: Removed minibufexpl.vim.
  "execute "MBEClose"
  " Close the Quickfix window.
  cclose
  "if a:restore_minibufexp == 1
  "  " Deprecated: execute "MiniBufExplorer"
  "  execute "MBEOpen"
  "endif
  " Resize the location list, if applicable.
  call s:QFixResizeLocationList(l:last_llist_winnr, l:restore_winnr)
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
        "echom "Buffer is locked! Cannot switch windows."
      endtry
    else
      enew
    endif
  endif
  return l:restore_winnr
endfunction

function! s:QFixResizeLocationList(last_llist_winnr, restore_winnr)
  if getbufvar(winbufnr(a:last_llist_winnr), "&filetype") == 'qf'
    " Switch to the location list.
    execute '' . a:last_llist_winnr . 'wincmd w'
    " Resize the location list.
    execute "resize -" . g:jah_Quickfix_Win_Height
  endif
  " Reactivate the previously active window.
  execute a:restore_winnr . 'wincmd w'
endfunction

function! s:QFixToggle_Show(restore_minibufexp)
  let l:restore_winnr = winnr()
  " 2017-11-02: Removed minibufexpl.vim
  "execute "MBEClose"
  " The plain copen command opens the Quickfix window on the bottom of the
  " screen, but it positions itself underneath and makes itself as wide as the
  " right-most window. Fortunately, we can use botright to force copen to use 
  " the full width of the window.
  execute "botright copen " . g:jah_Quickfix_Win_Height
  "if a:restore_minibufexp == 1
  "  "execute "MiniBufExplorer"
  "  execute "MBEOpen"
  "endif
  " NOTE For whatever reason, the previous call to MiniBufExplorer adds 4
  "      lines to the quickfix height, so we go back and fix it
  copen
  exe "resize " . g:jah_Quickfix_Win_Height
  execute l:restore_winnr . 'wincmd w'
endfunction

" Used to track the quickfix window
" [lb] Not sure where I got this from, but 
"      BufWinLeave doesn't always execute, 
"      causing QFixToggle to jam and forcing 
"      the user to :copen manually
"      2011.01.17 Is this problem fixed? I haven't seen it in a while...
augroup QFixToggle
  autocmd!
  autocmd BufWinEnter quickfix 
    \ :let g:qfix_win = bufnr('$')
  autocmd BufWinLeave * 
    \ if exists("g:qfix_win") 
    \     && expand("<abuf>") == g:qfix_win | 
    \   unlet! g:qfix_win | 
    \ endif
augroup END
" 2010.02.24 Switching to simpler/more realiable

" function! s:IsQuickFixShowing()
"   " The quickfix (or error) window is either the last window,
"   " or it's the second-to-last window, if the MiniBufExplorer
"   " window is showing.
"   " Note: The MiniBufExplorer window and the Project window
"   "         both have a &buftype of 'nofile';
"   "       The quickfix and location lists indicate 'quickfix';
"   "       and Using the a real file's buffer number of -1
"   "         return the empty string.
"   let is_showing = 0
"   let cur_winnr = winnr('$')
"   let cnt = 0
"   let cur_bufbr = winbufnr(cur_winnr)
"   while (cur_bufbr != -1 && cnt < 2)
"     " Check if the buffer in window cur_winnr is the quickfix buffer.
"     "   This is a hack: The location list windows are
"     "   indistinguishable from the quickfix window; it's
"     "   up to the code that opens a location list for a
"     "   window to manage it... i.e., Syntastic.
"     if (     getbufvar(cur_bufbr, "&buftype") == "quickfix"
"         \ && getbufvar(cur_bufbr, "&filetype") == "qf")
"       " Checking syntastic_owner_buffer sometimes works -- it's
"       " only really set on the location list that Syntastic opens
"       " -- but if you open the quickfix window after the location
"       " list, for some reason the quickfix window gets the value, too.
"       if (getbufvar(cur_bufbr, "syntastic_owner_buffer") == "")
"         " Definitely not the Syntastic location list.
"         let is_showing = 1
"         break
"       elseif (getbufvar(cur_bufbr, "syntastic_owner_buffer")
"             \ != winbufnr(cur_winnr - 1))
"         " Check the previous window and see if it's the owned buffer.
"         let is_showing = 1
"         break
"       endif
"     endif
"     if (cnt == 0 && getbufvar(cur_bufbr, "&buftype") == "nofile")
"       " Probably the MiniBufExplorer window; try the next window.
"       let cnt = cnt + 1
"       let cur_winnr = cur_winnr - 1
"       let cur_bufbr = winbufnr(cur_winnr)
"     else
"       " We've checked the last two windows and did not identify it.
"       break
"     endif
"   endwhile
"   return is_showing
" endfunction
"
" A much better version of the previous, inspired by:
"  http://vertuxeltes.blogspot.com/2013/10/vim-distinguish-location-list-from.html
"
" FIXME: Move this to an autoload utility, eh.
function! s:IsQuickFixShowing()
  redir => l:buffer_list
  silent ls
  redir END
  let l:quickfix_match = matchlist(
    \ l:buffer_list, '\n\s*\d\+[^\n]*\[Quickfix List\]')
  return empty(l:quickfix_match) ? 0 : 1
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
" MiniBufExplorer Functions
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" Opening and closing the MiniBufExplorer affects the heights of other
" windows, most notably the QuickFix window (if it's open). Specifically, 
" when the MiniBufExplorer is closed and the QuickFix window is visible, 
" rather than the QuickFix window decreasing it size, it expands to include 
" the rows abandoned by the MiniBufExplorer. Thusly, toggling the
" MiniBufExplorer a number of times causes the QuickFix to grow until it 
" consumes the whole screen, because the QuickFix window isn't resized when
" the MiniBufExplorer window is opened (the windows above it are, which are
" probably the windows your code is in). So we have to toggle smartly -- if 
" we're closing the MiniBufExplorer window, we should restore the height of
" the QuickFix window so that it doesn't grow wildly out of control.

function! s:IsMiniBufExplorerShowing()
  let is_showing = 0
  let cur_winnr = 1
  let cur_bufbr = winbufnr(cur_winnr)
  while (cur_bufbr != -1)
    " If the buffer in window cur_winnr is the quickfix buffer.
    if (bufname(cur_bufbr) == "-MiniBufExplorer-")
      let is_showing = 1
      break
    endif
    let cur_winnr = cur_winnr + 1
    let cur_bufbr = winbufnr(cur_winnr)
  endwhile
  return is_showing
endfunction

command -nargs=0 ToggleMiniBufExplorer
  \ :call <SID>ToggleMiniBufExplorer()
function! s:ToggleMiniBufExplorer()
  let l:mbeBufnr = bufnr('-MiniBufExplorer-')
  let l:restore_quick_fix_height = 0
  if s:IsQuickFixShowing() && mbeBufnr != -1
    " Both QuickFix and MiniBufExpl are visible; after we 
    " hide MiniBufExpl, we need to fix the QuickFix height
    let l:restore_winnr = winnr()
    copen
    let g:jah_Quickfix_Win_Height = winheight(winnr())
    let l:restore_quick_fix_height = 1
  endif
  " Toggle the MiniBufExpl window
  "TMiniBufExplorer
  " 2017-11-02: Removed minibufexpl.vim.
  "MBEToggle
  " Restore the QuickFix window height
  if l:restore_quick_fix_height > 0
    copen
    exe "resize " . g:jah_Quickfix_Win_Height
    execute l:restore_winnr . 'wincmd w'
  endif
endfunction

" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
" Search-Replace Text in All Files Listed in Quickfix Window
" ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

" Search and replace selected term all files listed in Quickfix
" ------------------------------------------------------
" This fcn. opens every file in the Quickfix list and does a bufdo, e.g., 
"    :bufdo .,$s/Search/Replace/g

" Typical use: Search for a term in the project directory.
"              Open one of the results, select the term,
"              type \S, refine the regex and add the substitution,
"              then hit <Enter>. Substitutions galore!

" See also: <Leader>s (\s), \S's little sibling that just
"           find-replaces in the current buffer.

" FIXME We could prompt for the replace term, but for now I just 
"       have the user complete the function call...
:noremap <Leader>S "sy:call <SID>QuickfixSubstituteAll("<C-r>s", "")<Left><Left>

" FIXME This fcn. requires the user to do an initial search. That is, this 
"       fcn. does not search the term being replaced, but rather just uses
"       the existing Quickfix error list
function s:QuickfixSubstituteAll(search, replace)
  "call confirm('Search for: ' . a:search . ' / ' . a:replace)
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
    let l:done = 0
    while !l:done
      if getbufvar(bufnr('%'), '&modifiable') == 1
        execute "silent! .,$s/" . a:search . "/" . a:replace . "/gI"
      endif
      bnext
      " We're done once we've processed the last buffer.
      let l:done = bufnr("%") == bufnr("$")
    endwhile
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


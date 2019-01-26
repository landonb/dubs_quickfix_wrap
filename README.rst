###################################
Dubs Vim |em_dash| Quickfix Wrapper
###################################

.. |em_dash| unicode:: 0x2014 .. em dash

About This Plugin
=================

A simple wrapper around QuickFix.

The quickfix window is nifty but has a few limitations:

- There's no easy, built-in method for toggling
  its visibility.

- When hiding the quickfix, it affects other windows'
  heights, which this script stops from happening.

Installation
============

Standard Pathogen installation:

.. code-block:: bash

   cd ~/.vim/bundle/
   git clone https://github.com/landonb/dubs_quickfix_wrap.git

Or, Standard submodule installation:

.. code-block:: bash

   cd ~/.vim/bundle/
   git submodule add https://github.com/landonb/dubs_quickfix_wrap.git

Online help:

.. code-block:: vim

   :Helptags
   :help dubs-quickfix-wrap

Quickfix Wrapper Commands
=========================

==================================  ==================================  ==============================================================================
Key Mapping                         Description                         Notes
==================================  ==================================  ==============================================================================
``<Shift-Alt-3>``                   Toggle Quickfix window.             Show/Hide the
                                                                        `QuickFix <http://vimdoc.sourceforge.net/htmldoc/quickfix.html>`__
                                                                        window.

                                                                        The QuickFix list shows search results, stack traces, and log file output.
                                                                        It occupies the bottom part of the screen, above the command line
                                                                        (or above the MiniBufExplorer, if that's showing).
----------------------------------  ----------------------------------  ------------------------------------------------------------------------------
``\S``                              Search-Replace Text in All Files    First search and populate the quickfix window (e.g.,
                                    Listed in Quickfix Window.          type \g to call GrepPrompt_Simple and start a search).
                                                                        Next, select text and then type \S to start a
                                                                        find-replace operation that'll bufdo all the files
                                                                        listed in the quickfix window.
==================================  ==================================  ==============================================================================


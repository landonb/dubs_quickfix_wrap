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

Installation is easy using the packages feature (see ``:help packages``).

To install the package so that it will automatically load on Vim startup,
use a ``start`` directory, e.g.,

.. code-block:: bash

    mkdir -p ~/.vim/pack/landonb/start
    cd ~/.vim/pack/landonb/start

If you want to test the package first, make it optional instead
(see ``:help pack-add``):

.. code-block:: bash

    mkdir -p ~/.vim/pack/landonb/opt
    cd ~/.vim/pack/landonb/opt

Clone the project to the desired path:

.. code-block:: bash

    git clone https://github.com/landonb/dubs_quickfix_wrap.git

If you installed to the optional path, tell Vim to load the package:

.. code-block:: vim

   :packadd! dubs_quickfix_wrap

Just once, tell Vim to build the online help:

.. code-block:: vim

   :Helptags

Then whenever you want to reference the help from Vim, run:

.. code-block:: vim

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


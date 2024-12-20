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
``<Shift-Alt-3>``                   Toggle Quickfix window              Show/Hide the `QuickFix <https://vimhelp.org/quickfix.txt.html>`__ window.

                                                                        The quickfix list shows search results, stack traces,
                                                                        and log file output. It occupies the bottom part of
                                                                        the screen, above the command line.
---------------------------------  ----------------------------------  ------------------------------------------------------------------------------
 ``\S``                             Search and Replace Text             This is similar to ``\s`` but it searches and replaces
                                    in All Files Listed                 text in all files listed in the quickfix window.
                                    in the QuickFix Window
                                                                        - Hint: Do an ``<F4>`` or ``\g`` search to populate the
                                                                          quickfix list (these two commands are part of
                                                                          `dubs_grep_steady
                                                                          <https://github.com/landonb/dubs_grep_steady#🧐>`__).

                                                                        - Double-click the first entry in the Quickfix search
                                                                          results to open that buffer.

                                                                        - Highlight the text you want to replace and then
                                                                          hit ``\`` and then ``S``.

                                                                        - Type the replacement text and hit return, and the
                                                                          command will find and replace in all of the files
                                                                          in the Quickfix list (using ``:bufdo``).

                                                                        Caveat: If you are not happy with the results, you'll
                                                                        have to |:undo| (or maybe <Ctrl-Z>_ each file that
                                                                        was edited; fortunately, a single undo undoes all
                                                                        of the changes in each buffer.

                                                                        Caveat: If a substring of your replacement text
                                                                        matches the original text, the function will
                                                                        endlessly recurse, oops!

                                                                        - Just type ``<Ctrl-C>`` to stop it (or ``<Cmd-.>``
                                                                          in MacVim).

                                                                        SAVVY: This command is slow! You might be better off
			                                                                  using a Git pipeline to replace text across files.

			                                                                  - For example, run something like this:

			                                                                    ``git ls-files -z | 
			                                                                      xargs -0 -I '{}' bash -c '[ -h "{}" ] \
                                                                  			    || sed -i -e "s/<pat>/<sub>/g" "{}"'``
==================================  ==================================  ==============================================================================


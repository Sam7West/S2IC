# Tcl package index file, version 1.1
# This file is generated by the "pkg_mkIndex" command
# and sourced either when an application starts up or
# by a "package unknown" script.  It invokes the
# "package ifneeded" command to set up package-related
# information so that packages will be loaded automatically
# in response to "package require" commands.  When this
# script is sourced, the variable $dir must contain the
# full path name of this file's directory.

package ifneeded s2ica 1.0 [list source [file join $dir 00_s2ica_main.tcl]]\n[list source [file join $dir 20_preprocessor.tcl]]\n[list source [file join $dir 30_assembler.tcl]]\n[list source [file join $dir 31_lexer.tcl]]\n[list source [file join $dir 32_parser.tcl]]\n[list source [file join $dir 40_linker.tcl]]\n[list source [file join $dir 50_code_generator.tcl]]\n[list source [file join $dir s2ica_error.tcl]]\n[list source [file join $dir tokens.tcl]]\n[list source [file join $dir utils.tcl]]
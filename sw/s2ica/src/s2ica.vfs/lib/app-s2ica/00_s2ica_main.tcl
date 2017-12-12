package provide s2ica 1.0

#_______________________________________________________________
# USAGE:
#
#	s2ica ?flags? ?options? file_1.asm ?file_2.asm? ..
#_______________________________________________________________


proc s2ica argv {

    if [catch {

	# run toolchain: scheduler, assembler, linker, code-generator
	s2ica_main $argv

    } results options ] {

	# filter errors by checking error-code
	
	if { [lindex $::errorCode 0] eq "S2ICA" } {

	    # call handler proc for custom s2ic-errors
	    # TODO: finish custom s2ic error handling..
	    #s2ic_error $::errorCode $errorInfo
	    puts "ERROR: assembly failed"
	    exit
	    
	} else {
	    
	    # else, let interpreter handle
	    return -options $options $results
	    
	}
    }
}


proc s2ica_main args {
    
    namespace import utils::*

    set utils::debug false

    set args [lindex $args 0]

    # debug print
    d_puts 0 "Starting.."
    d_puts 0 ""
    d_puts 0 "args => "
    foreach arg $args { d_puts 0 $arg }
    d_puts 0 ""
    puts "working dir. => [pwd]"
    d_puts 0 ""
    
    
    # set arg. default-values
    set file_out_default "a.hex"
    set dir_out_default [pwd]
        
    #-----------------------------------------------------------
    # parse args
    #-----------------------------------------------------------
    
    # define default CL flags
    array set arg_flags { 
	--debug false
	-h false
	--help false
    }

    # define default CL options
    array set arg_options [subst {
	-o $file_out_default 
	-B $dir_out_default
    } ]
    
    set fid_lst [list]

    # debug print
    d_puts 0 ""
    utils::line dash
    d_puts 0 "Parsing command-line args:"

    # Parse flags:
    d_puts 0 ""
    d_puts 1 "Parsing flags.."
    set index -1
    while { [incr index] < [llength $args] } {
	set flag [lindex $args $index $index]
	if { ! [info exists arg_flags($flag)] }  break
	# else: valid flag
	set arg_flags($flag) true
	d_puts 1 "Got flag: $flag"
    }

    # set debug level
    set utils::debug $arg_flags(--debug)    

    # if requested, print help info.
    if { $arg_flags(-h) || $arg_flags(--help) } {
	puts [read [open $starkit::topdir/lib/app-s2ica/help_info.txt]]
	exit
    }
    
    # Parse options: (flags finished)
    d_puts 0 ""
    d_puts 1 "Parsing options.."
    d_puts 1 "arg. \[ $index / [llength $args] \]"
    
    while { $index < [llength $args] } {
	set option [lindex $args $index]
	set val [lindex $args $index+1]
	puts "option: $option"
	puts "val: $val"
	if { ! [info exists arg_options($option)] } {
	    break
	}
	# else: valid option
	set arg_options($option) $val
	d_puts 1 "Got option: $option, val: $val"
	incr index 2
    }

    # open output file
    set path_out [file join $arg_options(-B) $arg_options(-o) ]
    set fid_out [open $path_out w+]

    
    # Parse (input) file names: (options finished)
    d_puts 0 ""
    d_puts 1 "Parsing file names.."
    d_puts 1 "arg. \[ $index / [llength $args] \]"
    while { $index < [llength $args] } {
	
	set file_name [lindex $args $index]
	set file_path [file normalize $file_name]

	if { ! [file exists $file_path  ] } {
	    puts "ERROR: file '$file_name' could not be found"
	    puts "path: $file_path"
	    exit
	}

	# else: open valid file
	set fid [open $file_path]
	lappend fid_lst $fid

	# debug print
	d_puts 1 "Successfully opened file:"
	d_puts 2 "path: $file_path"
	d_puts 2 "fid:  $fid"

	incr index
    }

    
    # if { [llength $fid_lst] < 1 } {
    # 	error { "Expected atleast one input file name" } \
    # 	    " " {S2ICA WRONG_NUM_ARGS}
    # }
    
    # debug print: flags, options & files
    puts ""
    utils::line dash
    d_puts 0 "flags array =>"
    parray arg_flags
    utils::line dash
    d_puts 0 "options array =>"
    parray arg_options
    utils::line dash
    d_puts 0 "file ID list =>"
    d_puts 0 $fid_lst

    #-----------------------------------------------------------    
    # Assemble each input file 
    #-----------------------------------------------------------

    init_token_enums

    # debug print
    d_puts 0 $utils::equa_line

    # reset:
    set obj_dct_lst [list]

    foreach fid $fid_lst {

	# get input assembly code from file
	set asm_str [read $fid]

	# print
	puts ""
	puts "Assembling file.. (File ID: $fid)"
	d_puts 0 "file string =>"
	d_puts 1 "\"[string range $asm_str 0 $utils::snip_size]...\""		

	#-------------------------------------------------------
	# Preprocess assembly-code string
	#-------------------------------------------------------

	set asm_str [preprocess $asm_str]
	
	# debug print
	utils::line dash
	d_puts 0 ""
	d_puts 0 "After pre-processing: (first $utils::snip_size char's)"
	d_puts 1 "\"[string range $asm_str 0 $utils::snip_size]\""

	#-------------------------------------------------------
	# Assemble to object dict.
	#-------------------------------------------------------

	namespace import assembler::*

	set obj_dct {}
	assemble $asm_str obj_dct
	
	# debug print
	d_puts 0 ""
	d_puts 0 "successfully compiled fid: $fid to object file"

	# add to object-dict. list for linker
	lappend obj_dct_lst $obj_dct

    }

    # debug print
    d_puts 0 ""
    d_puts 0 "..finished compiling all ([llength $obj_dct_lst]) file(s)"
    d_puts 0 ""
    
    #-----------------------------------------------------------
    # Link all dict's (and resolve all labels)
    #-----------------------------------------------------------

    set instr_lst [linker::resolve_all $obj_dct_lst]

    # debug print
    utils::line dash
    d_puts 0 ""
    d_puts 0 [join $instr_lst \n]
    
    #-----------------------------------------------------------
    # Generate hex (target-code) from tokens
    #-----------------------------------------------------------
    
    # reset var's
    set mem_hex_lst [list]
    set mem_hex_str ""

    generate $instr_lst mem_hex_lst

    set mem_hex_str [join $mem_hex_lst \n]
    
    #-----------------------------------------------------------
    # write to output file
    #-----------------------------------------------------------

    puts $fid_out $mem_hex_str

    # debug print
    puts ""
    puts "All done"
    puts " ..wrote target code to file: \"$path_out\""
    puts ""
    
    #-----------------------------------------------------------
    # print formatted instruction memory to stdout
    #-----------------------------------------------------------

    # debug print
    d_puts 0 "Output instruction mem. =>"
    d_puts 0 ""
    
    # print target instruction memory - address & value
    set addr_per_line 8
    set mem_size [llength $mem_hex_lst]
    set whole_line_count [expr ($mem_size / $addr_per_line)]
    set addr 0

    for { set line 0 } { $line < $whole_line_count } { incr line } {
	set line_str "[format 0x%08X $addr]: "
	for { set col 0 } { $col < $addr_per_line } { incr col } {
	    append line_str " [format %04s [lindex $mem_hex_lst $addr]]"
	    incr addr
	}
	d_puts 0 $line_str
    }

    # print any remaining partial line
    if { ($mem_size-1) - $addr > 0 } {
	set line_str "[format 0x%08X $addr]: "
	while { $addr < $mem_size } {
	    append line_str " [format %04s [lindex $mem_hex_lst $addr]]"
	    incr addr
	}
	d_puts 0 $line_str
    }

    
}

package provide s2ica 1.0

# regexp match indices differ post Tcl-8.5  => simple patch-var. fix
namespace eval :: {
    variable patch_tcl86_re_ind 
    set ::patch_tcl86_re_ind [expr ($tcl_version > 8.5) ? 1 : 0]
}

#----------------------------------------------------------------
# 1st pass proc's
#----------------------------------------------------------------

proc scrape_labels {asm_label_str asm_str_name label_arr_name} {

    upvar $asm_str_name asm_str
    upvar $label_arr_name label_arr
    
    # debug print
    d_puts 0 "Running Label Scraper..\n"

    # reset var's
    set asm_str $asm_label_str
    set address 0
    set char_offset -1
    array unset label_arr
    array set label_arr {}

    # N.b. "snippet" = contiguous instructions preceeding current label
    set snippet_re {(.*?)}
    set label_re {^[\s\t]*?([[:alpha:]][\w]*?:)(?:.*$)}
    set chunk_re "$snippet_re$label_re"

    #-----------------------------------------------------------
    # build regular exp. 'OR' atom from each opcode's RE
    #-----------------------------------------------------------
    
    set token_instr_re \{
    
    foreach {name info} $s2ica::token_instr_dct {
	dict with info {
	    append token_instr_re "|$re"
	}
    }
    
    append token_instr_re \}
    
    # debug print
    d_puts 0 "chunk regexp:"
    d_puts 0 " $chunk_re"
    d_puts 0 "instruction regexp:"
    d_puts 0 " $token_instr_re"
    
    #-----------------------------------------------------------
    # match one chunk (i.e. snippet followed by label) at a time
    #-----------------------------------------------------------
    
    while { [incr char_offset] < [string length $asm_label_str] } {

	# debug print
	utils::line dash
	d_puts 0 "search char. offset: $char_offset"
	incr utils::indent_abs
	
	# reset match vars
	set snippet_indices {}
	set label_indices {}
	set snippet_str ""
	set label_str ""
	
	# find next label
	regexp -start $char_offset -indices -lineanchor -- \
	    $chunk_re $asm_label_str \
	    all snippet_indices label_indices
	
	# if no labels remaining - finished label search
	if { [llength $label_indices] == 0 } {
	    d_puts 0 "No more labels, all done";
	    incr utils::indent_abs -1
	    break
	}
	
	# debug print
	d_puts 0 "snippet indices => $snippet_indices"
	d_puts 0 "label indices => $label_indices"

	foreach {start end} $snippet_indices {
	    set snippet_str [string range $asm_label_str $start $end]; break
	}
	foreach {start end} $label_indices {
	    # remove trailing ':'
	    set label_str [string range $asm_label_str $start $end-1]; break
	}
	
	# TODO: more accurate matching of instruction opcodes
	
	# simple count of No. instr's - assume 2nd pass picks up syntax errors

	set opcode_re ""
	append opcode_re \\m ( $token_instr_re ) \\M

	d_puts 0 "opcode counter regexp:"
	d_puts 0 " $opcode_re"

	incr address [regexp -all -nocase -- $opcode_re $snippet_str]

	# check label not already defined locally

	if { [info exists label_arr($label_str)] } {

	    # puts "found label: $label_arr($label_str)"
	    # puts "label array: \"[array get label_arr]\""
	    # return
	    
	    set line_num [regexp -all -- {[\n]} \
			      [string range $asm_label_str 0 [lindex $label_indices 0] ] ]
	    error "Label: $label_str redefined at line ....\n" \
		" " { S2ICA MULT_LABEL_DEFS }
	    puts "ERROR: multiple definitions of label: $label_str"
	    puts ".. redefined at: $address"
	    incr utils::indent_abs -1
	    return 
	}

	set label_arr($label_str) $address

	# remove label declaration from assembly code
	foreach {start end} $label_indices {

	    # replace label (and ':') with whitespace in RETURN-STRING ONLY
	    set ws [string repeat " " [expr ($end+1) - $start]]
	    set asm_str \
		[string replace $asm_str $start $end $ws ]
	    d_puts 0 "after removing labels:"
	    d_puts 0 "\"$asm_str\""
	    break
	}
	
	# move to next section to search for labels
	set char_offset [lindex $label_indices 1]
	
	# debug print	
	d_puts 0 "Got match:"
	d_puts 1 "\nsnippet => \n\"$snippet_str\""
	d_puts 1 "label:	\"$label_str\""
	d_puts 1 "addr: 	$address"
	
	incr utils::indent_abs -1
    }
    
    incr utils::indent_abs -1

    # debug print
    d_puts 0 "\nfirst pass completed.."
    
    return
}


#----------------------------------------------------------------
# 2nd pass proc's
#----------------------------------------------------------------

proc add_token { body_name token_name token_re } {

    #-----------------------------------------------------------
    # utility proc for building regex-switch cases:
    #-----------------------------------------------------------
    
    upvar $body_name body
    
    # import all global ns variables
    global {*}[info globals *]

    set token_id [subst $$token_name]

    # debug print
    d_puts 0 "adding token:\t$token_name\t(id: $token_id) re:$token_re"

    # store token id and string val as list of dicts:
    set cmd "
	d_puts 0 \"Scanned an (id: [format %2d $token_id]) $token_name\"
	set token_val \[lindex \$match_lst 1]
	dict set token id  $token_id
	dict set token val \$token_val
	lappend token_lst \$token"
    #lappend token_lst $token_id
    
    set body "$body \n \{$token_re\} \{ $cmd \n \}"
}


proc tokenize { asm_str token_dct token_lst_name } {

    upvar $token_lst_name token_lst

    # debug print
    d_puts 0 "Running tokenize proc.."
    d_puts 0 ""
    d_puts 0 "label-free assembly string:"
    d_puts 1 "\"[string range $asm_str 0 50] ... \""	

    #-----------------------------------------------------------
    # build regex-switch command (one switch-case per token)
    #-----------------------------------------------------------

    # reset var's
    set token_lst {}
    set re_switch_body ""

    # add tokens to regex-switch body cases
    dict for { name info } $token_dct {
	set re ""
	dict with info {
	    add_token re_switch_body $name "\\A$re"
	}
    }

    # add default case
    set re_switch_body "$re_switch_body \n \
	{ default } { puts \"ERROR: unkown character\"; exit }"

    #-----------------------------------------------------------
    # scan all chars into token list
    #-----------------------------------------------------------

    # reset var's
    set index 0
    set snippet ""
    set index_lst {}
    set match_lst {}

    # scan through assembly string, match one token per loop
    set max [string length $asm_str]
    while { $index < $max } {
	
	#debug print
	d_puts 0 [string repeat - 80]
	
	# attempt to match a token immediately after previous 
	set snippet [string range $asm_str $index end]
	switch -regexp -nocase -indexvar index_lst -matchvar match_lst -- \
	    $snippet $re_switch_body

	# move to end of last string matched
	set char_num [lindex [lindex $index_lst 0] 1]
	incr char_num $::patch_tcl86_re_ind
	incr index $char_num
	
	# debug print
	d_puts 1 "character offset: \[ $index / $max \]"
	d_puts 1 "next $utils::snip_size char's:"
	d_puts 2 "\"[string range $asm_str $index $index+$utils::snip_size]\""
    }

    return 

}



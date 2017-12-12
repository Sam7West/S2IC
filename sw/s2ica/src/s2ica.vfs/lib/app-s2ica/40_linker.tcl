package provide s2ica 1.0

namespace eval linker:: {

    namespace export resolve_labels
    namespace export resolve_all

    proc merge_object_dicts object_dct_lst {
	
	# reset var's	
	set object_all_dct {}
	set instr_all_lst [list]
	array set label_all_arr {}
	set addr_offset 0
	
	# Consecutively merge object dict's checking for multiple def's
	foreach object_dct $object_dct_lst {


	    set instr_lst [dict get $object_dct instr_lst]
	    array unset label_arr
	    array set label_arr [dict get $object_dct label_arr]
	    set instr_count [llength $instr_lst]

	    #-----------------------------------------------------------
	    # merge instruction list
	    #-----------------------------------------------------------    

	    # append object's instructions (allocate consecutively in mem.)
	    set instr_all_lst [concat $instr_all_lst $instr_lst]
			       	    
	    #-----------------------------------------------------------
	    # merge label array
	    #-----------------------------------------------------------

	    # debug print
	    d_puts 0 ""
	    d_puts 0 "master label array => [array get label_all_arr]"

	    # check for multiple label definitions
	    foreach {name addr_rel} [array get label_arr] {

		# debug print
		d_puts 0 "adding label: $name"

		# check for multiple label definitions
		if [info exists label_all_arr($name)] {
		    set msg "..redefinition of label: \"$name\""
		    error $msg -errorcode { S2ICA INSTR_MULT_LAB_DEFS }
		}

		# calculate label's absolute (allocated) mem. address
		set addr_abs [expr $addr_offset + $addr_rel]
		
		# add label to merged array
		set label_all_arr($name) $addr_abs
	    }

	    # set memory offset for appending more instructions
	    incr addr_offset $instr_count

	}
	
	dict set object_all_dct instr_lst	$instr_all_lst
	dict set object_all_dct label_arr	[array get label_all_arr]

	# debug print
	d_puts 0 ""
	d_puts 0 "finished allocating label addresses:"
	d_puts 0 "master label array => [array get label_all_arr]"
	d_puts 0 ""

	return $object_all_dct
    }
    
    proc resolve_labels object_dct {

	set instr_final_lst	[list]
	set instr_unres_lst	[dict get $object_dct instr_lst]
	array set label_arr	[dict get $object_dct label_arr]
	set instr_count		[llength $instr_unres_lst]
	
	# check each line for unresolved symbols
	foreach instr $instr_unres_lst {
	    
	    # reset var's
	    set opcode ""
	    set operand_1 ""
	    set operand_2 ""
	    
	    dict with instr {

		# check if an opcode only instruction
		if { $operand_1 eq "" } {
		    # just copy to 'result' instruction list
		    lappend instr_final_lst $instr
		    continue
		}

		# check for labels in all operands

		foreach oper_name [info vars operand_*] {
		    
		    set operand [subst \$$oper_name]

		    # check if literal => no symbols
		    if [string is digit $operand] {
			continue
		    }

		    # debug print
		    d_puts 0 "got label \"$operand\" ($oper_name)"
		    
		    # check for undefined symbols
		    if ![info exists label_arr($operand)] {
			set msg "..undefined label: \"$operand\""
			error $msg -errorcode { S2ICA INSTR_UNKNOWN_SYMBOL }
		    }
		    
		    # resolve symbol (assume only labels for now)
		    set $oper_name $label_arr($operand) 

		}
	    }
	    
	    # debug print
	    d_puts 0 "appending resolved instruction: $instr"
	    
	    # copy resolved instruction to 'result' instruction list
	    lappend instr_final_lst $instr
	    
	}

	return $instr_final_lst
    }

    
    proc resolve_all {object_dct_lst} {
	
	# debug print
	d_puts 0 $utils::equa_line
	d_puts 0 "Running Linker.."

	# Pseudo link: merge all object arrays and resolve labels
	set object_all_dct [merge_object_dicts $object_dct_lst]
	
	# Resolve labels..
	return [resolve_labels $object_all_dct]
    }
}

package provide s2ica 1.0

# define error codes
namespace eval s2ica {

    variable error_code
    
    array set error_code {
	INPUT_WRONG_NUM_ARGS	\
	    "ERROR: Wrong number of args.."

	INSTR_MULT_LAB_DEFS \
	    "ERROR: Multiple definitions of label.."
	INSTR_TOO_MANY_ARGS	\
	    "ERROR: Unexpected extra characters before end-of-line.."
	INSTR_TOO_FEW_ARGS	\
	    "ERROR: Unexpected extra characters before end-of-line.."
	INSTR_UNKNOWN_OPCODE	\
	    "ERROR: unknown opcode"
	INSTR_EARLY_EOF		\
	    "ERROR: early end of file"
	INSTR_UNKNOWN_SYMBOL	\
	    "ERROR: Unknown symbol (only decimal, hex & labels permitted).."
	CODE_GEN_FAILURE \
	    "ERROR: invalid I2C or JMP type instruction during code generation"
	MISC \
	    "ERROR:"
	
    }
}

proc s2ica_error { s2ica_error inline_msg } {

    set inline_msg [lindex [split $errorInfo \n] 0]
    
    if 0 {
    puts -------------
    puts $s2ica_error_lst
    puts $inline_msg
    puts -------------
    }
    
    # N.b. Typically inline_msg is of format "expected ... \n got ..."
    # s2ica_error_code used to print pre-defined generic error messages 

    # remove s2ica id string
    set s2ica_error_lst [lrange $s2ica_error_lst 1 end]

    set num_args [llength $s2ica_error_lst]
    set s2ica_error_code [lindex $s2ica_error_lst 0]

    puts "s2ica_error_code => $s2ica_error_code"
    #puts $s2ica::error_code($s2ica_error_code)

   # check valid s2ica error code returned
    if { ![info exists s2ica::error_code($s2ica_error_code) ] } {
	puts "shouldn't be reading this.. invalid error code returned"
	return
    }
    
    switch $num_args {

	1 {
	    # Expect: [ s2ica_error_code ]	    
	    puts "ERROR: $s2ica::error_code($s2ica_error_code)"
	    puts $inline_msg
	}
	
	4 {
	    # Expect: [ s2ica_error, line_str, file_name, line_num ]
	    puts $s2ica::error_code($s2ica_error_code)
	    puts $inline_msg
	}
	
	default {
	    puts "incorrect number of args in s2ica error thrown.. got $num_args"
	    return
	}
    }
	
}

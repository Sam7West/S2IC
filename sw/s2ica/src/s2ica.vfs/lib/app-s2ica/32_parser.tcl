package provide s2ica 1.0

namespace eval parser:: {
    
    namespace export parse_all

    
    proc parse_oper oper_name {

	upvar $oper_name oper
	
	if { $parser::index >= [llength $parser::token_lst] } { return false }	
	set token [lindex $parser::token_lst $parser::index]
	set id [dict get $token id]
	set val [dict get $token val]

	
	if { $id == $::e_int } {

	    # if integer
	    d_puts 0 "Got an int: val => $val"

	} elseif { $id == $::e_hex } {

	    # else-if hexadecimal
	    d_puts 0 "Got a hexdigit: val => $val"
	    set val [format %u $val]
	    
	} elseif { $id == $::e_sym } {

	    # else-if symbol
	    d_puts 0 "Got a symbol.."
	    
	} else {

	    # else unrecognised operand
	    set msg "..failed to parse operand: \"$val\" at line $parser::line_num"
	    error $msg -errorcode { S2ICA INSTR_UNKNOWN_SYMBOL }
	    
	}

	# set operand arg to return
	set oper $val
	
	# move to next token
	incr parser::index
	
	return true
    }

    proc parse_nl args {
	
	if { $parser::index >= [llength $parser::token_lst] } { return false }
	set token [lindex $parser::token_lst $parser::index]
	set id [dict get $token id]
	set val [dict get $token val]
	
	if { $id != $::e_nl } {
	    set msg "..expected newline, "
	    append msg "got token: \{ $token \}, at line: $parser::line_num"
	    error $msg -errorcode { S2ICA UNEXPECTED_SYMBOL }
	}	
	
	# move to next token
	incr parser::index
	
	return true
	
    }

    proc parse_ws_greedy args {

	#-------------------------------------------------------
	# parse whitespace token
	#-------------------------------------------------------

	# check if EOF
	if { $parser::index >= [llength $parser::token_lst] } { 
	    set msg "..parsing instruction, line No. $parser::index.."
	    error $msg -errorcode { S2ICA EARLY_EOF }
	}
	
	# get current token
	set token [lindex $parser::token_lst $parser::index ]
	set id [dict get $token id]
	set val [dict get $token val]
	
	# expect whitespace
	if { $id != $::e_ws } {
	    set msg "..expected whitespace, "
	    append msg "got token: \{ $token \}, at line: $parser::line_num"
	    error $msg -errorcode { S2ICA UNEXPECTED_SYMBOL }
	}
	
	# move to next token
	incr parser::index

	#-------------------------------------------------------
	# recursively check for more whitespace 
	#-------------------------------------------------------
	
	# check if EOF
	if { $parser::index >= [llength $parser::token_lst] } { 
	    return true
	}
	
	# get next token
	set next_token [lindex $parser::token_lst $parser::index]
	set next_id [dict get $next_token id]
	set next_val [dict get $next_token val]

	# continue if more whitespace
	if { $next_id == $::e_ws } {
	    parse_ws_greedy
	}

	# else: all done
	return true
    }

    proc parse_instr {token_instr_dct instr_name} {

	# return-variable
	upvar $instr_name instr

	# check if EOF
	if { $parser::index >= [llength $parser::token_lst] } { 
	    set msg "..parsing instruction, line No. $parser::index"
	    error $msg -errorcode { S2ICA EARLY_EOF }
	}

	# get current token
	set token [lindex $parser::token_lst $parser::index]
	set id [dict get $token id]
	set val [dict get $token val]

	#-------------------------------------------------------
	# Parse opcode and get No. of arg's expected
	#-------------------------------------------------------	

	# debug print
	d_puts 0 ""
	d_puts 0 "Parsing opcode.."

	set match false
	set operc ""
	
	foreach { opcode info } $token_instr_dct {

	    set e_opcode [subst \$::$opcode]

	    if { $e_opcode eq $id } {

		set match true

		dict with info {
		    set s [expr $operc == 1 ? {""} : {"s"} ]
		    d_puts 1 "Got id:     $opcode"
		    d_puts 1 "Expecting:  $operc argument$s"

		}
		
		# move to next token
		incr parser::index
		
		break;
	    }
	}

	# check if couldn't identify opcode
	if { ! $match } {
	    set msg "..instead got token: \"$val\" at line $parser::line_num"
	    error $msg -errorcode { S2ICA INSTR_UNKNOWN_OPCODE }
	}	
	
	#-------------------------------------------------------
	# parse depending on No. of args epexcted
	#-------------------------------------------------------

	# reset var's
	set operand_1 ""
	set operand_2 ""
	
	# parses till end of instruction
	switch $operc {

	    0 {
		# set return instruction
		dict set instr e_opcode	$e_opcode		
		
		return true
	    }

	    1 {
		# expect whitespace
		if [catch {parse_ws_greedy} result option ] {
		    append result \n "..parsing instruction: \"$id\""
		    return -code error -options $option $result
		}
		
		# debug print		
		d_puts 0 ""
		d_puts 0 "parsing first operand.."

		incr utils::indent_abs

		# expect first operand
		if [catch {parse_oper operand_1} result option ] {
		    append result \n "..parsing instruction: \"$id\""
		    return -code error -options $option $result
		}

		incr utils::indent_abs -1
		
		# set return instruction 
		dict set instr e_opcode		$e_opcode
		dict set instr operand_1	$operand_1
		
		return true
		
	    }
	    
	    2 {
		# expect whitespace
		if [catch {parse_ws_greedy} result option ] {
		    append result \n "..parsing instruction: \"$id\""
		    return -code error -options $option $result
		}
		
		# debug print		
		d_puts 0 ""
		d_puts 0 "parsing first operand.."

		# expect first operand
		incr utils::indent_abs
		if [catch {parse_oper operand_1} result option ] {
		    append result \n "..parsing instruction: \"$id\""
		    return -code error -options $option $result
		}
		incr utils::indent_abs -1

		# expect whitespace
		if [catch {parse_ws_greedy} result option ] {
		    append result \n "..parsing instruction: \"$id\""
		    return -code error -options $option $result
		}
		
		# debug print		
		d_puts 0 ""
		d_puts 0 "parsing second operand.."

		# expect first operand

		incr utils::indent_abs
		if [catch {parse_oper operand_2} result option ] {
		    append result \n "..parsing instruction: \"$id\""
		    return -code error -options $option $result
		}
		incr utils::indent_abs -1

		# return arg instruction
		dict set instr e_opcode		$e_opcode
		dict set instr operand_1	$operand_1
		dict set instr operand_2	$operand_2
		
		return true
	    }	    
	    
	    default {
		set msg ".. no code to handle \"$operc\" operands, line No. $parser::index"
		error $msg -errorcode { S2ICA MISC }
		
	    }
	}
	    
    }

    # n.b. parser utility proc's throw errors if unsuccessful..
    # => optional/OR-branch parsing should catch & ignore these errors

    proc parse_all { token_lst_arg token_instr_dct instr_lst_name } {

	# debug print
	utils::line equa
	d_puts 0 "Running parser.."
	
	upvar $instr_lst_name instr_lst
	
	variable index 0
	variable token_lst $token_lst_arg

	# Line No. just used for error-info printing:
	variable line_num

	# reset var.
	set instr_lst {}
	set line_num 0

	# #-------------------------------------------------------
	# # build instruction regular exp.
	# #-------------------------------------------------------
 	# set instr_re \{

	# foreach { name info } $token_instr_dct {
	#     append instr_re |[subst \$::$name]
	# }

	# append instr_re |\}

	
	#-------------------------------------------------------
	# build shared switch-cases for instructions
	#-------------------------------------------------------
	
 	set instr_share_case_lst {}
	
	foreach { name info } $token_instr_dct {
	    lappend instr_share_case_lst [subst \$::$name]
	    lappend instr_share_case_lst -
	}

	set instr_share_case_lst [lrange $instr_share_case_lst 0 end-1]

	#d_puts 0 $instr_share_case_lst

	#-------------------------------------------------------
	# build switch body - expect an opcode, whitespace or empty line
	#-------------------------------------------------------

	set switch_body ""

	# shared switch-case for all instruction opcodes
	
	append switch_body $instr_share_case_lst
	append switch_body " \{" {

	    incr utils::indent_abs 

	    # debug print

	    #puts [string repeat o 60]
	    set i $parser::index
	    #puts "parsed:"
	    #puts [lrange $parser::token_lst 0 $i-1]
	    #puts "remaining: [lrange $parser::token_lst $i $i+3].."
	    #puts "index: $i"

	    d_puts 0 ""
	    d_puts 0 "token index: \[ $i / [llength $parser::token_lst] \]"
	    d_puts 0 "parsing instruction"

	    
	    incr utils::indent_abs	    

	    # parse an I2C or address-jump instruction
	    set instr {}
	    if [catch {parse_instr $token_instr_dct instr} result option] {
		append result \n "..parsing instruction (id: $id)"
		return -code error -options $option $result
	    }

	    incr utils::indent_abs -1

	    #puts [string repeat o 60]
	    set i $parser::index
	    #puts "index: $i"
	    #puts [lrange $parser::token_lst 0 $i-1]
	    #puts "[lrange $parser::token_lst $i $i+3].."

	    d_puts 0 ""
	    d_puts 0 "token index: \[ $i / [llength $parser::token_lst] \]"
	    d_puts 0 "parsing optional whitespace.."
	    
	    # expect optional whitespace till end of line
	    catch {parse_ws_greedy}

	    #puts [string repeat o 60]
	    set i $parser::index
	    # puts "index: $i"
	    # puts [lrange $parser::token_lst 0 $i-1]
	    # puts "[lrange $parser::token_lst $i $i+3].."

	    d_puts 0 ""
	    d_puts 0 "token index: \[ $i / [llength $parser::token_lst] \]"
	    d_puts 0 "parsing newline character.."
	    
	    # if not EOF => expect newline 
	    if { $parser::index < [llength $parser::token_lst] } {
		if [catch {parse_nl} result option] {
		    
		    append result \n "..parsing instruction (id: $id)"
		    return -code error -options $option $result
		    
		}
	    }
	    
	    incr utils::indent_abs -1
	    
	    # store parsed instruction
	    d_puts 0 "appending instruction: \{ $instr \}"
	    lappend instr_lst $instr


	} "\} "

	# add case for whitespace
	
	append switch_body $::e_ws
	append switch_body " \{" {

	    # debug print
	    d_puts 0 ""
	    d_puts 0 "parsed token: whitespace"

	    if [catch {parse_ws_greedy} result option] {
		append result \n "..parsing whitespace"
		return -code error -options $option $result
	    }

	    # debug print
	    d_puts 0 ""
	    d_puts 0 "successfully parsed line"

	} "\} "

	# add case for newline
	
	append switch_body "$::e_nl"
	append switch_body " \{" {

	    # debug print
	    d_puts 0 ""
	    d_puts 0 "got newline token"

	    if [catch {parse_nl} result option] {
		append result \n "..parsing newline"
		return -code error -options $option $result
	    }

	    # debug print
	    d_puts 0 ""
	    d_puts 0 "successfully parsed line"

	} "\} "

	# add default case (error)
	
	append switch_body default
	append switch_body " \{" {

	    set msg "..expected instruction opcode or empty line"
	    append msg "got token: \{ $token \}, at line: $parser::line_num"
	    error $msg -errorcode { S2ICA INSTR_UNKNOWN_OPCODE }
	    
	} "\} "

	#-------------------------------------------------------
	# Parse all tokens
	#-------------------------------------------------------

	while { $parser::index < [llength $parser::token_lst] } {

	    # get lookahead token
	    set token [lindex $parser::token_lst $parser::index]
	    set id [dict get $token id]
	    set val [dict get $token val]

	    # debug print
	    utils::line dash
	    d_puts 0 "attempting to parse line.. (lookahead-token ID: $id)"

	    switch $id $switch_body
	}
	
	return
    }
    
}



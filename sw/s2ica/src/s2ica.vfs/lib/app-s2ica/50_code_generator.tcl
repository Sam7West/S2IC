package provide s2ica 1.0

proc generate_jmp { asm_instr_dct hex_str_name } {
    
    global {*}[info globals *]
    
    upvar $hex_str_name hex_str

    set e_opcode  [dict get $asm_instr_dct e_opcode]

    switch $e_opcode \
	$e_jmp {

	    #---------------------------------------------------
	    # generate a jump instruction
	    #---------------------------------------------------	    

	    # get operands
	    set operand_1 [dict get $asm_instr_dct operand_1]

	    # set instruction fields	    
	    set rst_addr_ctr	1
	    set brc_flag	0
	    set address		$operand_1

	    if { $address >= [expr pow(2, 8)] } {
		puts "address: $address"
		puts "ERROR: instr. \"address\" arg val exceeds 8 bits"
		return 
	    }

	    # [15]	: 0x8000 = 0b1000,0000,0000,0000 
	    # [12]	: 0x1000 = 0b0001,0000,0000,0000 
	    # [8:0]	: 0x01FF = 0b0000,0001,1111,1111 

	    # fields to contiguous mem. (shift and bit mask)
	    set hex_str \
		[expr "
			( 0x8000 & ($rst_addr_ctr	<< 15)	) +
			( 0x1000 & ($brc_flag		<< 12)	) +
			( 0x01FF & ($address)			)
		   " ]
	} \
	$e_brc {

	    #---------------------------------------------------
	    # generate a branch instruction
	    #---------------------------------------------------

	    # get operands
	    set operand_1 [dict get $asm_instr_dct operand_1]
	    set operand_2 [dict get $asm_instr_dct operand_2]

	    # set instruction fields
	    set rst_addr_ctr	1
	    set brc_flag	1
	    set condition	$operand_1
	    set address		$operand_2

	    # check for bit field overflows
	    # nb correct checking..
	    if { $condition >= [expr pow(2, 4)] } {
		set msg "..branch \"condition\" operand exceeds 4 bits"
		error $msg -errorcode { S2ICA CODE_GEN_FAILURE }
	    }
	    
	    if { $address >= [expr pow(2, 8)] } {
		puts "address: $address"
		exit
		set msg "..branch \"address\" operand exceeds 8 bits"
		error $msg -errorcode { S2ICA CODE_GEN_FAILURE }
	    }
	    
	    # [15]	: 0x8000 = 0b1000,0000,0000,0000 
	    # [12]	: 0x1000 = 0b0001,0000,0000,0000 
	    # [11:8]	: 0x0F00 = 0b0000,1111,0000,0000 
	    # [7:0]	: 0x00FF = 0b0000,0000,1111,1111

	    # fields to contiguous mem. (shift and bit mask)
	    set hex_str \
		[expr "
			( 0x8000 & ($rst_addr_ctr	<< 15)	) +
			( 0x1000 & ($brc_flag		<< 12)	) +
			( 0x0F00 & ($condition		<< 8 )	) +
			( 0x00FF & ($address)			)
		   " ]
	} \
	default {

	    #---------------------------------------------------	    
	    # else, not a jump type instruction
	    #---------------------------------------------------

	    # debug print
	    d_puts 0 "couldn't recognise opcode: $e_opcode"

	    return false
	    
	}

    
    # format string as hex. digit
    set hex_str [format %X $hex_str]
    
    # successfully generated hex code
    return true
}

proc generate_i2c { asm_instr_dct hex_str_name } {

    global {*}[info globals *]
    
    upvar $hex_str_name hex_str

    # get opcode
    set e_opcode  [dict get $asm_instr_dct e_opcode]

    # debug print
    d_puts 1 "generate_i2c"
    d_puts 2 "asm_instr_dct (input arg.) => \"$asm_instr_dct\""
    d_puts 2 "Got e_opcode: $e_opcode"    

    # set instruction fields
    set rst_addr_ctr	0
    set oper_type	0
    set byte_id		0
    set address		0
    
    switch $e_opcode \
	$e_nop { set oper_type 0 } \
	$e_sta { set oper_type 2 } \
	$e_sto { set oper_type 3 } \
	$e_wr  { set oper_type 4 } \
	$e_rda { set oper_type 6 } \
	$e_rdn { set oper_type 7 } \
	default { return false }

    # if instruction has an operand:

    if { ($oper_type == 4) || ($oper_type == 6) || ($oper_type == 7) } {

	# get operand
	set operand_1 [dict get $asm_instr_dct operand_1]

	# check for bit overflow
	if { $address >= [expr pow(2, 8)] } {
	    set msg "..\"address\" operand exceeds 8 bits"
	    error $msg -errorcode { S2ICA CODE_GEN_FAILURE }
	}

	# set instruction field
	set address	$operand_1
    }

    
    # check for field bit-overflows
    
    if { $rst_addr_ctr >= [expr pow(2,1)] } {
	puts "ERROR: \"reset address counter\" field exceeds 1 bits"
	return
    }
    
    if { $oper_type >= [expr pow(2,3)] } {
	puts "ERROR: \"operand type\" field exceeds 3 bits"
	return
    }

    if { $byte_id >= [expr pow(2,4)] } {
	puts "ERROR: \"byte ID\" field exceeds 4 bits"
	return
    }
    
    
    # [15]   : 0x8000 = 0b1000,0000,0000,0000
    # [14:12]: 0x7000 = 0b0111,0000,0000,0000
    # [11:8] : 0x0F00 = 0b0000,1111,0000,0000
    # [7:0]  : 0x00FF = 0b0000,0000,1111,1111

    # fields to contiguous mem. (shift and bit mask)
    set hex_str \
	[expr "
		       ( 0x8000 & ($rst_addr_ctr	<< 15)	) +
		       ( 0x7000 & ($oper_type		<< 12)	) +
		       ( 0x0F00 & ($byte_id		<< 8 )	) +
		       ( 0x00FF & ($address)			)
		   " ]

    # format string as hex. digit
    set hex_str [format %X $hex_str]

    # return success
    return true

    
}

proc generate { asm_instr_dct_lst hex_lst_name } {

    upvar $hex_lst_name hex_lst

    global {*}[info globals *]

    utils::line equa
    d_puts 0 "Running generate.."
    d_puts 0 ""

    #-------------------------------------------------------
    # attempt to generate I2C or address-jump type instruction
    #-------------------------------------------------------

    set hex_lst [list]
    
    foreach asm_instr_dct $asm_instr_dct_lst {

	#set utils::debug false
	
	if [ catch {

	    set hex_str ""

	    if ![generate_i2c $asm_instr_dct hex_str] {
		
		if ![generate_jmp $asm_instr_dct hex_str] {

		    # otherwise, invalid instruction
		    set msg "..assembling instruction: \"$asm_instr_dct\""
		    error $msg -errorcode { S2ICA CODE_GEN_FAILURE }
		}
	    }

	    # debug print
	    d_puts 0 "\$hex_str => \"$hex_str\""
	    
	    # append to result list
	    lappend hex_lst $hex_str
	    
	} result option ] {
	    append result "..whilst assembling instruction: \"$asm_instr_dct\""
	    return -code error -options $option $result
	}
    }

    #set utils::debug true
    
}


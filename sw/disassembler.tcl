
proc disassemble { hex_str } {

    set line [string repeat - 40]
    
    set debug_str ""
    set asm_str ""
    set instr_val ""

    # Instr. fields:
    set byte_id ""
    set lower_8 ""
    set address ""

    puts "\n\n$hex_str\n\n"

    # Disassemble
    # (build string of machine code and print debug info)

    puts "\nHEX\tBINARY\t\t\tTYPE\t\tByteID\tDATA/ADDRESS\n"
    
    foreach { instr } [split $hex_str] {

	set instr_val [scan $instr %X]

	if [string equal $instr_val ""] {
	    # just ignore:
	    break
	}

	# print fields: (mask and bit shift)
	append debug_str "0x[format %04X $instr_val]"
	append debug_str "\tb'[format %016b $instr_val]"

	# DETERMINE INSTRUCTION TYPE
	if [expr ! ($instr_val & 0b1000000000000000) ] {

	    # I2C INSTRUCTION

	    # instruction type
	    set type [expr ($instr_val & 0b0111000000000000) >> 12 ]
	    set byte_id [expr ($instr_val & 0b0000111100000000) >> 8 ]
	    set lower_8 [expr ($instr_val & 0b0000000011111111) ]

	    switch $type {
		0 {
		    append asm_str "NOP"
		    append debug_str "\tNo_Op     "
		}
		2 {
		    append asm_str "STA"
		    append debug_str "\tStart     "
		}
		3 {
		    append asm_str "STO"
		    append debug_str "\tStop      "
		}
		4 {
		    append asm_str "WR"
		    append asm_str "\t0x[format %X $lower_8]"
		    append debug_str "\tWrite     "
		}
		6 {
		    append asm_str "RDA"		    
		    append asm_str "\t0x[format %X $lower_8]"
		    append debug_str "\tRead_Ack  "
		}
		7 {
		    append asm_str "RDN"
		    append asm_str "\t0x[format %X $lower_8]"
		    append debug_str "\tReadd_Nack"
		}
		default { puts "no es bueno: unknown type"; return }
	    }

	    append debug_str "\t0x[format %X $byte_id]"
	    append debug_str "\t0x[format %X $lower_8]"


	} else {
	    
	    # RESET ADDRESS COUNTER == true
	    
	    set address [expr $instr_val & 0b0000000111111111 ] 
	    set byte_id [expr ($instr_val & 0b0000111100000000) >> 8 ]
	    
	    # if ( [15] && [12] )
	    if [expr ($instr_val & 0b0001000000000000) ] {

		# Branch (conditional jump)
		set cond [expr ($instr_val & 0b0000111100000000) >> 8 ]
		# 7:0 address
		set address [expr $address & 0b11111111]

		append asm_str "BRC"
		append asm_str "\t0d$cond"
		append asm_str "\t0x[format %X $address]"
		
		set debug_str "\n$line\n$debug_str"
		append debug_str "\tBRC"
		append debug_str "  \t\t0x[format %X $byte_id]"
		append debug_str "\n\tif \{ cond\[$cond\] \}"
		append debug_str "\n\t\tjust execute next instr."
		append debug_str "\n\telse"
		append debug_str "\n\t\tJMP 0x[format %X $address] \[7:0\] (address)"
		append debug_str "\n$line"
		
	    } else {		

		# Unconditional jump
		#set debug_str "\nHEX\tBINARY\t\t\tTYPE\tADDR\[8:0\]\n$debug_str"

		# 8:0 address
		
		append asm_str "JMP"
		append asm_str "\t0x[format %X $address]"

		set debug_str "\n$debug_str"
		append debug_str "\tJMP"

		append debug_str "  \t\t0x[format %X $byte_id]"
		append debug_str "\t0x[format %X $address] \[8:0\] (address)"
	    }

	    append debug_str "\n"
	}

	append asm_str "\n"

	puts $debug_str
	set debug_str ""
	
    }

    return $asm_str
    
}

# default: disassemble the assembler's output
proc dasm { {file_hex ""} } {

    set line [string repeat - 40]
    
    set fid_asm ""
    set fid_hex ""

    set hex_str ""
    set asm_str ""



    # check input file argument passed
    if { $file_hex eq "" } {
	puts "ERROR: expected file-name argument to disassembler"
	return error
    }

    set file_asm "[file rootname $file_hex].asm"
    
    #_______________________________________________________________
    # Open: input (hex) & output (asm) files
    #_______________________________________________________________
    
    set fid_hex [open [file normalize [file join . $file_hex] ] r]
    set fid_asm [open [file normalize [file join . $file_asm] ] w+]

    set hex_str [read $fid_hex]
    set asm_str [read $fid_asm]
    
    #_______________________________________________________________
    # Disassemble
    #_______________________________________________________________
    
    set asm_str [disassemble $hex_str]
    
    # Write disassembler output to file
    puts $fid_asm $asm_str

    # Close the files
    close $fid_hex
    close $fid_asm

    puts "Succesfully completed disassembly and wrote to:\n\t$file_asm"
    return
}

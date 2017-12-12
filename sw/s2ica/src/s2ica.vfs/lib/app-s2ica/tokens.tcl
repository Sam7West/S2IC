package provide s2ica 1.0


proc init_token_enums args {

    namespace import utils::*

    # initialise enums in global namespace
    add_enum [dict keys $s2ica::token_all_dct]
    
}

namespace eval s2ica {

    variable token_other_dct
    variable token_instr_dct
    variable token_all_dct

    set token_other_dct {
	e_nl	{ re {[\n]} }
	e_ws	{ re {[\s\t]+?} }
	e_int	{ re {([0-9]+)(?=[\s\t]+?)} }
	e_hex	{ re {(0x[A-Fa-f0-9]+)} }
	e_sym	{ re {([[:alpha:]][0-9a-zA-Z_]*)} }
    }
    
    set token_instr_dct {
	e_nop	{ re {NOP\M} operc 0 }
	e_sta	{ re {STA\M} operc 0 }
	e_sto	{ re {STO\M} operc 0 }
	e_rda 	{ re {RDA\M} operc 1 }
	e_rdn	{ re {RDN\M} operc 1 }
	e_wr 	{ re {WR\M}  operc 1 }
	e_jmp	{ re {JMP\M} operc 1 }
	e_brc	{ re {BRC\M} operc 2 }
    	e_cll	{ re {CLL\M} operc 1 }
    	e_rtn	{ re {RTN\M} operc 0 }
    }

    set token_all_dct [concat $token_instr_dct $token_other_dct]
    
}



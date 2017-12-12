package provide s2ica 1.0

namespace eval assembler:: {

    namespace export assemble

    #-----------------------------------------------------------
    # build object file/array from assembly code
    #-----------------------------------------------------------
    
    proc assemble { asm_label_str obj_dct_name } {

	upvar $obj_dct_name obj_dct
	
	# debug print
	d_puts 0 $utils::equa_line
	d_puts 0 "Running assembler.."
	d_puts 0 "Assembling string:"
	d_puts 1 "\"[string range $asm_label_str 0 $utils::snip_size]...\""
	
	#-------------------------------------------------------
	# 1st pass: Identify labels
	#-------------------------------------------------------

	# debug print
	d_puts 0 $utils::equa_line
	d_puts 0 ""
	d_puts 0 "First pass - identifying labels and symbols"	
	
	#reset var's
	set asm_str ""
	array set asm_label_arr {}

	incr utils::indent_abs

	# separate labels from assembly code
	scrape_labels $asm_label_str asm_str asm_label_arr	
	
	incr utils::indent_abs -1

	# debug print
	utils::line dash
	d_puts 0 ""
	d_puts 0 "label-free assembly code: (first $utils::snip_size chars)"
	d_puts 2 "\"[string range $asm_str 0 $utils::snip_size]\""
	d_puts 0 ""
	d_puts 0 "labels identified: =>"
	d_puts 2 "\"[array get asm_label_arr]\""

	#-------------------------------------------------------
	# 2nd pass: Tokenize 
	#-------------------------------------------------------

	#reset var
	set asm_token_lst [list]

	d_puts 0 "Second pass - tokenize label-free assembly string"
	
	incr utils::indent_abs
	# Scan (label-free) character string into tokens
	tokenize $asm_str $s2ica::token_all_dct asm_token_lst
	incr utils::indent_abs -1

	global {*}[info globals *]

	# debug print
	utils::line dash
	d_puts 0 ""
	d_puts 0 "tokenized assembly code =>"
	d_puts 0 "\{[lrange $asm_token_lst 0 $utils::snip_size] ... \}"
	d_puts 0 ""
	d_puts 0 "labels identified =>"
	d_puts 1 [array get asm_label_arr]
	d_puts 0 ""
	d_puts 0 "\$s2ica::token_instr_dct =>"
	d_puts 1 $s2ica::token_instr_dct

	#-------------------------------------------------------
	# 3rd pass: Parse tokens into instructions
	#-------------------------------------------------------

	# reset var's
	set asm_instr_lst {}

	incr utils::indent_abs

	# parse tokens into contiguous memory instruction list
	parser::parse_all $asm_token_lst $s2ica::token_instr_dct asm_instr_lst

	incr utils::indent_abs -1

	# debug print
	utils::line dash
	d_puts 0 ""
	d_puts 0 "Finished assembly"
	d_puts 1 "parsed instructions list:"
	d_puts 1 $asm_instr_lst
	d_puts 0 $utils::equa_line

	set obj_dct {}
	dict set obj_dct label_arr [array get asm_label_arr]
	dict set obj_dct instr_lst $asm_instr_lst
	
	return 
    }
}

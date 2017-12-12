package provide s2ica 1.0

proc preprocess { str } {

    # debug print
    d_puts 0 ""
    utils::line dash
    d_puts 0 "Running pre-processer.."

    incr utils::indent_abs
    
    # reset 
    set constants [dict create]

    # Remove comments
    set str [regsub -all -lineanchor -- {;.*?$} $str ""]
    
    # Find " #DEFINE " constants
    
    d_puts 0 "Looking for constants.."
    

    set re_lst \
	[list \
	     {(?:\#define)} \
	     {([a-z][a-z0-9_]*)} \
	     {(?:(0x[A-Fa-f0-9]+\M|[0-9]+\M))} \
	]
    set re [join $re_lst {[\s\t]+?}]

    set lst [split $str \n]

    set i -1
    set n 0
    
    foreach line $lst {

	incr i
	incr n
	set name ""
	set val ""
	
	set count [regexp -lineanchor -nocase -- $re $line all name val]

	if { $count == 0 } { continue }

	# else: matched a constant

	# clear line from source
	lset lst $i ""
	
	# error checking
	if { $name eq "" } {
	    puts "ERROR: expected constant name at line $n"
	    exit
	}
	if { $val eq "" } {
	    puts "ERROR: expected constant value at line $n"
	    exit
	}
	if [dict exists $constants $name] {
	    puts "ERROR: Multiple definitions of $name"
	    puts "..redefined at line: $n"
	    exit
	}

	# store value
	dict set constants $name $val
	d_puts 1 "Identified: \"$name\" = $val"
    }

    set str [join $lst \n]
    
    d_puts 0 ""
    dict for { name val } $constants {
	d_puts 0 "checking name: $name"
	set str [regsub -all -- $name $str $val]
    }

    incr utils::indent_abs -1
    return $str
    
}    

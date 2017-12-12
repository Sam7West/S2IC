package provide s2ica 1.0

namespace eval ::utils {

    namespace export d_puts
    namespace export add_enum
    namespace export line
    
    
    variable debug
    variable snip_size
    variable indent_abs
    variable equa_line
    variable dash_line
    variable star_line
    variable stop_line
    
    set debug false
    set snip_size 50
    set width 80
    set indent_abs 0
    set equa_line [string repeat = $width]
    set dash_line [string repeat - $width]
    set star_line [string repeat * $width]
    set stop_line [string repeat . $width]

    proc line type {

	# only print if debug flag set
	if {! $utils::debug } { return }

	catch { puts [subst \$utils::$type\_line] }
    }

    proc d_puts { indent_rel str } {
	
	# only print if debug flag set
	if {! $utils::debug } { return }
	
	set indent_str ""
	set out_str ""

	# indent beginning of each line 
	set indent_str [string repeat \t [expr $utils::indent_abs + $indent_rel] ]
	regsub -all -lineanchor {^} $str $indent_str out_str
	
	puts $out_str
    }

    
    # pseudo-enum
    proc add_enum { name_lst } {

	# initialise if first call
	if ![info exists ::var_count] {
	    variable ::var_count 0
	}

	# store each enum in global ns
	foreach name $name_lst {

	    # disallow overwriting
	    if [info exists ::$name] {
		#puts "WARNING: ignoring attempted overwrite of enum \"$name\""
		continue
	    }

	    # declare in global ns
	    variable ::$name $::var_count

	    # debug print
	    d_puts 0 "adding enum: \$$name => $var_count"
	    
	    # update calling proc/shell's scope
	    uplevel 1 global $name 

	    # update enum count
	    incr ::var_count
	}

    }


}

# just import upon "source" command
namespace import utils::*

# tokens.tcl depends on utils => call after sourcing
#add_all_tokens

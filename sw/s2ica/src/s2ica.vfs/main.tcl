# skip main.tcl if sourcing this kit 
if { [starkit::startup] eq "sourced" } {
    return
}

package require s2ica 1.0
package require starkit

# Run S2ICA: S2IC-Kit (kit = scheduler, assembler, linker & code-generator)
s2ica $argv



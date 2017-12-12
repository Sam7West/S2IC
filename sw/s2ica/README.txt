__________________________________________________________________________________

S2ICA: Smart Serial Interface Controller, Assembler

(n.b. Assembler = Scheduler, assembler, linker & code-generator toolchain)



__________________________________________________________________________________

USAGE: 
	s2ica ?flags? ?options? file_1.asm, ?file_2.asm? ..
	(N.b. max 8 arg's)

FLAGS:
	-h, --help	Print this usage message
	--debug		print debugging information

OPTIONS:
	-B DIR		Directory to place output files
	-o filename	Outputfile name
	
__________________________________________________________________________________

Windows specifics:

 o	Run "~/s2ic/sw/s2ica/bin/setpathtemp.bat" to add bin dir. to the session
	PATH.

 o	N.b. Due to a quirk of Windows,	non-GUI Starkit applications require
	running a Tclkit which excludes Tk package (tclkit-shell). Hence,
	s2ica.kit should always be invoked using tclkitsh852.exe and
	"third_party/ ... /tclunit.kit" using tclkit-8.6.3-win32-ix86.exe.
	(As shown in test_gui.bat and s2ica.bat)

__________________________________________________________________________________
BUILD: N.b. currently only Windows build implemented

 o	Makefile included in ~/s2ic/tools/s2ic/	(GNU Make required)
 
	CD /s2ic/sw/s2ica/
	make
	=>
	/s2ic/tools/s2ic/bin/
		test_gui.bat
		s2ica.bat
		s2ica.kit	

 o	Cross-platform capable deployment of Tcl script proj. achieved using
	STand-Alone-Runtime kit (StaRkit).
	Default makefile recipe builds (source) s2ica.vfs dir's into runnable
	~.kit's (in bin directory).
	
 o	(Windows build also includes recipes for s2ica.bat & test_gui.bat files.)
 
__________________________________________________________________________________

TEST:

 o	Third party application "tclunit" included in project (copyright
	Bob Techentin 1st Nov 2005) which provides a GUI built on tcltest package
	to run the assembler software tests located in: /s2ic/tools/s2ic/test/
	
 o	Run using (Windows) command: /bin/test_gui.bat ./test

__________________________________________________________________________________

Example:

 o	Directory: s2ic/tools/s2ic/example contains an assembly code (/asm/) and
	output compiled-instructions (/hex/) folder.
	The /asm/ folder contains a dummy "ex_sensor_subroutines.asm" file with
	subroutines for an example I2C sensor device and a file "ex_main.asm"
	which conditionally calls into different subroutines.

 o	A Windows batch command "ex_run.bat" is also included which calls s2ica
 	with the example files as input and will assemble and link both files (with
	the print debugging flag set ON) and place the output in the /hex/ folder.

__________________________________________________________________________________

3P_DIR		= ../third_party
TCLKIT_WIN_CLI	= $(3P_DIR)/tclkit/tclkitsh852.exe
TCLKIT_WIN_GUI	= $(3P_DIR)/tclkit/tclkit-8.6.3-win32-ix86.exe
SDXKIT		= $(3P_DIR)/sdx/sdx.kit
TCLUNIT		= $(3P_DIR)/tclunit/tclunit-0.1/tclunit.kit
BIN		= bin
SRC		= src
TEST		= test
BIN_REV		= ..
SRC_REV		= ..
APP_CLI		= s2ica
APP_GUI		= 
KIT_CLI		= $(patsubst %, $(BIN)/%.kit, $(APP_CLI))
KIT_GUI		= $(patsubst %, $(BIN)/%.kit, $(APP_GUI))


ifeq ($(OS),Windows_NT)

#__________________________________________________________________
# Windows build
#__________________________________________________________________

BAT_CLI		= $(KIT_CLI:.kit=.bat)
BAT_GUI		= $(KIT_GUI:.kit=.bat)
TEST_BAT	= $(BIN)/test_gui.bat

.SUFFIXES: .tcl .kit .bat

default: all

all: print_info $(KIT_CLI) $(KIT_GUI) $(BAT_CLI) $(BAT_GUI) $(TEST_BAT)

# KIT recipe
.SECONDEXPANSION:
$(KIT_CLI) : $(BIN)/%.kit : $$(wildcard $(SRC)/%.vfs/lib/app-%/*.tcl)
	cd $(SRC); \
	"$(SRC_REV)/$(TCLKIT_WIN_CLI)" \
	"$(SRC_REV)/$(SDXKIT)" \
	wrap $(SRC_REV)/$@ \
	;rm $(SRC_REV)/$(BIN)/$*.bat

# Windows .bat recipe - runs .kit using tclkitsh (W/O Tk)
$(BAT_CLI) :
	echo @\"%~dp0/$(BIN_REV)/$(TCLKIT_WIN_CLI)\" \
	\"%~dp0/$(*F).kit\" %1 %2 %3 %4 %5 %6 %7 %8 %9 \
	> $@

# Windows .bat recipe - runs .kit using tclkit (WITH Tk)
$(BAT_GUI) :
	echo @\"%~dp0/$(BIN_REV)/$(TCLKIT_WIN_GUI)\" \
	\"%~dp0/$(*F).kit\" %1 %2 %3 %4 %5 %6 %7 %8 %9 \
	> $@

# test batch file (run tclunit.kit) recipe
$(TEST_BAT) :
	echo @\"%~dp0/$(BIN_REV)/$(TCLKIT_WIN_GUI)\" \
	\"%~dp0\$(BIN_REV)/$(TCLUNIT)\" %1 \
	> $@

print_info:
	$(info Build target: Windows)

clean: 
	$(RM) $(KIT_CLI) $(KIT_GUI) $(BAT_CLI) $(BAT_GUI) $(TEST_BAT)


#__________________________________________________________________

else

UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Linux)

#__________________________________________________________________
# LINUX build
#__________________________________________________________________

# ..TODO

$(info Linux build currently unimplemented)

#__________________________________________________________________

endif

ifeq ($(UNAME_S),Darwin)

#__________________________________________________________________
# MAC-OSX build
#__________________________________________________________________

# ..TODO

$(info MAC OSX build currently unimplemented)

#__________________________________________________________________

endif

endif

# makefile
# Used for building executables from 64-bit x86 assembly language
#
# Programmer: Mayer Goldberg, 2023

NASM_EXE = nasm
NASM_OPTIONS = -g
NASM_OPTIONS_64 = -f elf64
NASM_COMMAND_64 = $(NASM_EXE) $(NASM_OPTIONS) $(NASM_OPTIONS_64) \
                  -l $*.lst $<
GCC_EXE = gcc
GCC_OPTIONS = -g
GCC_OPTIONS_64 = -m64 -no-pie
GCC_COMMAND_64 = $(GCC_EXE) $(GCC_OPTIONS) $(GCC_OPTIONS_64) -o $* $*.o

compiler-backup:
	mv backup backup.old
	mkdir backup
	cp compiler.ml ./backup/
	cp epilogue.asm ./backup/
	cp init.scm ./backup/
	cp generate-scoped-expressions.scm ./backup/
	cp list-of-functions.text ./backup/
	cp makefile ./backup/
	cp pc.ml ./backup/
	cp problems.ml ./backup/
	cp prologue-1.asm ./backup/
	cp prologue-2.asm ./backup/
	cp visualization.ml ./backup/

.SUFFIXES:	.asm .o .s
%.o:	%.asm
	$(NASM_COMMAND_64)

%:	%.o
	$(GCC_COMMAND_64)

%.objdump:	%
	objdump -l -F -g -M intel-mnemonic -S --wide -d -s $* > $*.objdump
	a2ps \
	--landscape \
	-sPAPERSIZE=a4 \
	-R \
	--columns=1 \
	--pretty-print=nasm \
	--highlight-level=heavy \
	--line-numbers=1 \
		$*.objdump -o $*_objdump.ps
	ps2pdf -sPAPERSIZE=a4 $*_objdump.ps
	rm -f $*.ps

%.pdf:	%.asm
	a2ps \
	--landscape \
	-R \
	--columns=1 \
	--pretty-print=nasm \
	--highlight-level=heavy \
	--line-numbers=1 \
	$*.asm -o $*.ps
	ps2pdf -sPAPERSIZE=a4 $*.ps
	rm -f $*.ps

# end of input

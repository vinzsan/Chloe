ASSEMBLER = nasm
ASM_FLAGS = -f elf64 -g -F dwarf

LINKER = ld
LD_FLAGS = 

OUT = test
SRC = $(wildcard src/*.asm)
OBJ = $(SRC:.asm=.o)

all: $(OUT)

%.o	: %.asm
	$(ASSEMBLER) $(ASM_FLAGS) $< -o $@
	
$(OUT) : $(OBJ)
	$(LINKER) $(OBJ) -o $(OUT)
	
clean:
	rm -f $(OBJ) $(OUT)

.PHONY:	all clean

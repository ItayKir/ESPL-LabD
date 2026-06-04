# Makefile to compile NASM code and link it with the C standard library

# Default target
all: multi

# Link the object file to create the executable
multi: multi.o
	gcc -m32 multi.o -o multi

# Compile the assembly code into an ELF32 object file
multi.o: multi.s
	nasm -f elf32 multi.s -o multi.o

# Clean up generated files
clean:
	rm -f multi.o multi
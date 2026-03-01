all: program

program: main.o lib.o
	gcc -no-pie main.o lib.o -o program

main.o: main.c
	gcc -c main.c -o main.o

lib.o: lib.asm
	fasm lib.asm lib.o

clean:
	rm -f *.o program
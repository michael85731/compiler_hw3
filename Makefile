cc = gcc
output = output.exe
target = test
javaa = ./javaa/./javaa.exe

all: clean generate compile execute

execute: $(target).class
	java $(target)

compile: $(output) $(target).jasm $(target).class
$(target).jasm: 
	./$(output) $(target).rust
$(target).class:
	$(javaa) $(target).jasm 

generate: $(output)
$(output): parser.tab.c parser.tab.h lex.yy.c
	$(cc) -o $(output) lex.yy.c parser.tab.c -lm -lfl
lex.yy.c: scanner.l
	flex -l scanner.l
parser.tab.c parser.tab.h: parser.y
	bison -vd parser.y

.PHONY: clean
clean:
	rm -f $(output) *.jasm *.class parser.tab.c parser.tab.h lex.yy.c
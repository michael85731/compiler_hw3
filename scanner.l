%{
 /* C defineition */
#include <stdio.h>
#include <stdlib.h>
#include "parser.tab.h"

int returnLineCount();

char lastInput[1000];
int lineCount = 1;
%}

/* State definitions*/
%s COMMENT

/* Format token definitions */
letters [A-Za-z]

digits [0-9]+
integer {digits}
plain_real {digits}"."{digits}
expreal {digits}"."{digits}[Ee][+-]?{digits}
real {plain_real}|{expreal}

%%
 /* Space ignore */
" " {  }

 /* Comment */
"/*" {
    BEGIN(COMMENT); 
}

<COMMENT>{
"*/" { BEGIN(0); }
[^*\n]+ 
"*" 
}

"//".* {

}

 /* Delimiters */

^.*\n {
    strcpy(lastInput, yytext);
    REJECT;
}

\n {
    //printf("%d: %s", lineCount, lastInput);
    lineCount++;
    return LINEBREAK;
}

, { return ','; }
: { return ':'; }
; { 
    yylval.string = strdup(yytext);
    return ';';
}
\( { return '('; }
\) { return ')'; }
\[ { return '['; }
\] { return ']'; }
\{ { return '{'; }
\} { return '}'; }

 /* Type keywords */
bool {
    yylval.string = strdup(yytext); 
    return BOOL; 
}
char { 
    yylval.string = strdup(yytext);
    return CHAR; 
}
float { 
    yylval.string = strdup(yytext);
    return FLOAT; 
}
int { 
    yylval.string = strdup(yytext);
    return INT; 
}
str { 
    yylval.string = strdup(yytext);
    return STR; 
}
i32 { 
    yylval.string = strdup(yytext);
    return I32; 
}
f32 { 
    yylval.string = strdup(yytext);
    return F32; 
}

 /* Boolean value keywords */
true { 
    yylval.string = strdup(yytext);
    return TRUE; 
}
false { 
    yylval.string = strdup(yytext);
    return FALSE; 
}

 /* Other keywords*/
break { return BREAK; }
continue { return CONTINUE; }
do { return DO; }
else { return ELSE; }
enum { return ENUM; }
extern { return EXTERN; }
for { return FOR; }
fn { return FN; }
if { return IF; }
in { return IN; }
let { return LET; }
loop { return LOOP; }
match { return MATCH; }
mut { return MUT; }
print { return PRINT; }
println { return PRINTLN; }
pub { return PUB; }
return { return RETURN; }
self { return SELF; }
static { return STATIC; }
struct { return STRUCT; }
use { return USE; }
where { return WHERE; }
while { return WHILE; }


 /* Operators */
\+ { return '+'; }
- { return '-'; }
\* { return '*'; }
\/ { return '/'; }
% { return '%'; }
\< { return LESS; }
\<= { return LESSEQUAL; }
\>= { return GRATEREQUAL; }
\> { return GRATER; }
== { return EQUAL; }
!= { return NOTASSIGN; }
&& { return AND; }
\|\| { return OR; }
! { return '!'; }
= { return '='; }
\-\> { return ASSIGNRETURNTYPE; }

 /* String */
\"{letters}.*\" {
    yylval.string = strdup(yytext); 
    return STRING; 
}

 /* Numbers */
{integer} { 
    yylval.string = strdup(yytext); 
    return INTEGER; 
}
{plain_real} { return PLAINREAL; }
{expreal} { return EXPREAL; }
 /* {real} { printf("<REAL>\n"); } */

 /* Identifiers */
{letters}(({letters}|{digits})*)? {
    yylval.string = strdup(yytext); 
    return ID;
}

%%

int returnLineCount(){
    return (lineCount);
}
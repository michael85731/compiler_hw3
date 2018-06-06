%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct symboltableslot{
    char name[100];
    int mutable;
    char dataType[10];
    char value[100];
    int stackIndex;
    char format[200];  // For function definition
    int insideVariableIndex;    // For function's inside variable
};
typedef struct symboltableslot SymbolTableSlot;
SymbolTableSlot symbolTable[50][100];
void symbolTableInit();
int findAvailable();
int* lookup(char* name);
void dump();
int checkIdExist(char* name);
void storeVariableSlot(char* field, char* data);
void storeFunctionSlot(char* field, char* data, char* specifyFunction);

FILE* file;
char className[100];
void fileInit(char* target);
void fileEnd();
void writeLine(char* code);
void classNameFilter(char* target);

int returnLineCount();

int symbolTableCounter = 0;
int stackIndexCounter = 0;
int blockCounter = 0;
int lastBlockCounter = 0;
int writeValueSwitch = 1;
char stringBuffer[100];
char lineBuffer[100];

void writeValue(int type, char* value);
void writeVariableDefinition();
void writeIdAssignment();
void writeLoadVariableValue();
void writeFunctionDefinition();
void writeBooleanExpression();
void writePrintExpression(int part, char* method);
void writeFunctionInvocation();
void writeFunctionInvocationParameter(char* dataType);
void writeIfBlock(int part);
void writeWhileBlock(int part);
%}

 /* Keyword */
%token BOOL
%token BREAK
%token CHAR
%token CONTINUE
%token DO
%token ELSE
%token ENUM
%token EXTERN
%token FALSE
%token FLOAT
%token FOR
%token FN
%token IF
%token IN
%token INT
%token LET
%token LOOP
%token MATCH
%token MUT
%token PRINT
%token PRINTLN
%token PUB
%token RETURN
%token SELF
%token STATIC
%token STR
%token STRUCT
%token TRUE
%token USE
%token WHERE
%token WHILE
%token I32
%token F32
 
 /* Operator */
%token EQUAL
%token LESS 
%token LESSEQUAL
%token GRATER
%token GRATEREQUAL
%token NOTASSIGN
%token OR
%token AND
%token ASSIGNRETURNTYPE

%union{
    int number;
    char *string;
}

 /* String */
%token <string> STRING

 /* Numbers */
%token <string> INTEGER
%token PLAINREAL
%token EXPREAL
%token REAL

 /* Identifiers */
%token <string> ID

 /* Operator priority*/
%left '+''-'
%left '*''/'
%nonassoc UMINUS

%token LINEBREAK
%%

PROGRAM: FUNCTION | DECLARATION | LINEBREAK | PROGRAM PROGRAM;
TYPE: BOOL | STR | STRING | INT | FLOAT | I32 | F32;
VALUE: TRUE { writeValue(0, "1"); } 
       | FALSE { writeValue(0, "0"); } 
       | STRING { writeValue(1, yylval.string); } 
       | INTEGER { writeValue(2, yylval.string); }
;
ASSIGNABLE: VALUE | ID;
DECLARATION: CONSTANTDECLARATION ';'
             | VARIABLEDECLARATION ';'
             | ARRAYDECLARATION ';'
             | FUNCTIONCALL ';'
             | STATEMENT ';'
             | IFBLOCK
             | WHILEBLOCK
;
CONSTANTDECLARATION: CONSTANTDEFINE '=' VALUE
                     {
                        storeVariableSlot("mutable", "0");
                        storeVariableSlot("dataType", "int");
                        storeVariableSlot("value", yylval.string);
                        storeVariableSlot("name", stringBuffer);
                     }
                     | CONSTANTDEFINE ':' TYPE
                     {
                        storeVariableSlot("mutable", "0");
                        storeVariableSlot("dataType", yylval.string);
                     } '=' VALUE
                     {
                        storeVariableSlot("value", yylval.string);
                        storeVariableSlot("name", stringBuffer);
                     }
;
CONSTANTDEFINE: LET ID { writeValueSwitch = 0; strcpy(stringBuffer, $2); };
VARIABLEDECLARATION: LET MUT ID
                     {
                        writeValueSwitch = 1;
                        storeVariableSlot("mutable", "1");
                        storeVariableSlot("dataType", "int");
                        storeVariableSlot("name", $3);

                        /* Given default value 0 */
                        writeValue(2, "0");
                        
                        if(symbolTableCounter == 0){
                            sprintf(stringBuffer, "int %s", $3);
                        }else{
                            sprintf(stringBuffer, "%s", $3);
                        }
                        writeVariableDefinition();
                     }
                     | LET MUT ID '=' ASSIGNABLE
                     {
                        writeValueSwitch = 1;
                        storeVariableSlot("mutable", "1");
                        storeVariableSlot("dataType", "int");
                        storeVariableSlot("name", $3);
                        if(symbolTableCounter == 0){
                            sprintf(stringBuffer, "int %s = %s", $3, yylval.string);
                        }else{
                            sprintf(stringBuffer, "%s", $3);
                        }
                        writeVariableDefinition();
                     }
                     | LET MUT ID ':' TYPE
                     {
                        writeValueSwitch = 1;
                        storeVariableSlot("mutable", "1");
                        storeVariableSlot("dataType", yylval.string);
                        storeVariableSlot("name", $3); 

                        /* Given default value 0 */
                        writeValue(2, "0");

                        if(symbolTableCounter == 0){
                            sprintf(stringBuffer, "%s %s", yylval.string, $3);
                        }else{
                            sprintf(stringBuffer, "%s", $3);
                        }
                        writeVariableDefinition();
                     }
                     | LET MUT ID ':' TYPE
                     {
                        writeValueSwitch = 1;
                        storeVariableSlot("mutable", "1");
                        storeVariableSlot("dataType", yylval.string);
                        sprintf(stringBuffer, "%s %s", yylval.string, $3);
                     } '=' ASSIGNABLE
                     { 
                        /* Backup stringBuffer content */
                        char tempBuffer[100];
                        strcpy(tempBuffer, stringBuffer);

                        /* Separate stringBuffer to get name argument */
                        char name[100];
                        char *namePointer = strtok(stringBuffer, " ");
                        while(namePointer != NULL){
                            strcpy(name, namePointer);
                            namePointer = strtok(NULL, " ");
                        }
                        storeVariableSlot("name", name);

                        /* Recover stringBuffer's original content */
                        strcpy(stringBuffer, tempBuffer);

                        if(symbolTableCounter == 0){
                            sprintf(stringBuffer, "%s = %s", stringBuffer, yylval.string);
                        }else{
                            sprintf(stringBuffer, "%s", name);
                        }

                        writeVariableDefinition();
                     }
;
ARRAYDECLARATION: LET MUT ID '[' TYPE ',' INTEGER ']';
FUNCTION: FUNCTIONATTR '(' ')' 
          {
              writeFunctionDefinition();
          }
          BLOCKSTATEMENT 
          {
              writeLine("return"); 
              writeLine("}"); 
          }
          | FUNCTIONATTR '(' ')' ASSIGNRETURNTYPE TYPE 
          {
              storeFunctionSlot("dataType", yylval.string, stringBuffer);
              writeFunctionDefinition();
          }
          BLOCKSTATEMENT 
          {
              writeLine("ireturn"); 
              writeLine("}"); 
          }
          | FUNCTIONATTR '(' FUNCTIONDEFINEPARAMETER ')' 
          {
              writeFunctionDefinition();
          }
          BLOCKSTATEMENT 
          {
              writeLine("return"); 
              writeLine("}"); 
          } 
          | FUNCTIONATTR '(' FUNCTIONDEFINEPARAMETER ')' ASSIGNRETURNTYPE TYPE
          {
              storeFunctionSlot("dataType", yylval.string, stringBuffer);
              writeFunctionDefinition();
          }
          BLOCKSTATEMENT 
          {
              writeLine("ireturn"); 
              writeLine("}"); 
          }
          
;
FUNCTIONATTR: FN ID 
              {
                  symbolTableCounter++;
                  stackIndexCounter = 0;
                  storeFunctionSlot("name", $2, "0");
                  strcpy(stringBuffer, $2);
              }
;
FUNCTIONDEFINEPARAMETER: ID ':' TYPE
                         {  
                             storeVariableSlot("mutable", "1");
                             storeVariableSlot("dataType", yylval.string);
                             storeVariableSlot("name", $1);
                             storeFunctionSlot("format", yylval.string, stringBuffer);
                         }
                         | ID ':' TYPE
                         {
                             storeVariableSlot("mutable", "1");
                             storeVariableSlot("dataType", yylval.string);
                             storeVariableSlot("name", $1);
                             storeFunctionSlot("format", yylval.string, stringBuffer);
                         }
                         ',' FUNCTIONDEFINEPARAMETER
                         
;
BLOCKSTATEMENT: '{' PROGRAM '}'
                | LINEBREAK '{' PROGRAM '}'
;
STATEMENT: ID '=' EXPRESSION
           {
              if(!checkIdExist($1)){
                  yyerror(strcat($1, " not define\n"));
              }

              strcpy(stringBuffer, $1);
              writeIdAssignment();
           }
           | RETURN EXPRESSION
           | PRINT '(' { strcpy(stringBuffer, "print"); writePrintExpression(0, "0"); } EXPRESSION ')' { writePrintExpression(1, "print"); }
           | PRINTLN '(' { strcpy(stringBuffer, "println"); writePrintExpression(0, "0"); } EXPRESSION ')' { writePrintExpression(1, "println"); }
           | PRINT { strcpy(stringBuffer, "print"); writePrintExpression(0, "0"); } EXPRESSION { writePrintExpression(1, "print"); }
           | PRINTLN { strcpy(stringBuffer, "println"); writePrintExpression(0, "0"); } EXPRESSION { writePrintExpression(1, "println"); }
;
EXPRESSION: EXPRESSION LESS EXPRESSION { strcpy(stringBuffer, "iflt"); writeBooleanExpression(); }
            | EXPRESSION LESSEQUAL EXPRESSION { strcpy(stringBuffer, "ifle"); writeBooleanExpression(); }
            | EXPRESSION GRATER EXPRESSION { strcpy(stringBuffer, "ifgt"); writeBooleanExpression(); }
            | EXPRESSION GRATEREQUAL EXPRESSION { strcpy(stringBuffer, "ifge"); writeBooleanExpression(); }
            | EXPRESSION NOTASSIGN EXPRESSION { strcpy(stringBuffer, "ifne"); writeBooleanExpression(); }
            | EXPRESSION EQUAL EXPRESSION { strcpy(stringBuffer, "ifeq"); writeBooleanExpression(); }
            | EXPRESSION OR EXPRESSION { writeLine("ior"); } 
            | EXPRESSION AND EXPRESSION { writeLine("iand"); } 
            | '!' EXPRESSION { writeLine("ixor"); } 
            | '-' EXPRESSION %prec UMINUS { writeLine("ineg"); }
            | EXPRESSION '+' EXPRESSION { writeLine("iadd"); } 
            | EXPRESSION '-' EXPRESSION { writeLine("isub"); }
            | EXPRESSION '*' EXPRESSION { writeLine("imul"); }
            | EXPRESSION '/' EXPRESSION { writeLine("idiv"); }
            | EXPRESSION '%' EXPRESSION { writeLine("irem"); }
            | FUNCTIONCALL
            | VALUE
            | ID 
            {
                if(!checkIdExist($1)){
                    yyerror(strcat($1, " not define\n"));
                }

                strcpy(stringBuffer, $1);
                writeLoadVariableValue();
            }
;
FUNCTIONCALL: ID '(' ')'
              {
                  if(!checkIdExist($1)){
                      yyerror(strcat($1, " not define\n"));
                  }
                  strcpy(stringBuffer, $1);
                  writeFunctionInvocation();
              }
              | ID '(' FUNCTIONCALLPARAMETER ')'
              {
                  if(!checkIdExist($1)){
                      yyerror(strcat($1, " not define\n"));
                  }
                  strcpy(stringBuffer, $1);
                  writeFunctionInvocation();
              }
;
FUNCTIONCALLPARAMETER: TRUE { strcpy(stringBuffer, "1"); writeFunctionInvocationParameter("boolean"); } 
                       | FALSE { strcpy(stringBuffer, "0"); writeFunctionInvocationParameter("boolean"); }
                       | STRING { strcpy(stringBuffer, yylval.string); writeFunctionInvocationParameter("string"); }
                       | INTEGER { strcpy(stringBuffer, yylval.string); writeFunctionInvocationParameter("integer"); }
                       | ID
{
    if(!checkIdExist($1)){
        yyerror(strcat($1, " not define\n"));
    }

    strcpy(stringBuffer, yylval.string);
    writeFunctionInvocationParameter("id");
}
| FUNCTIONCALLPARAMETER ',' FUNCTIONCALLPARAMETER;
IFBLOCK: IFDECLARATION { writeIfBlock(2); } | IFDECLARATION ELSEBLOCK;
IFDECLARATION: IF '(' EXPRESSION ')' 
               { 
                   writeIfBlock(0); 
               } 
               BLOCKSTATEMENT
;
ELSEBLOCK: ELSE 
           {
               writeIfBlock(1);
               writeIfBlock(2);
           }
           BLOCKSTATEMENT
           {
               writeIfBlock(3);
           }
;
WHILEBLOCK: WHILE 
            {
                writeWhileBlock(0);    
            } 
            '(' EXPRESSION ')' 
            {
                writeWhileBlock(1);
            }
            BLOCKSTATEMENT
            {
                writeWhileBlock(2);
            }
;

%%
int main(int argc, char *argv[]){
    symbolTableInit();
    fileInit(argv[1]);

    if(!yyparse()){
        printf("\nParsing complete\n");
    }else{
        printf("\nParsing failed\n");
    }
    printf("\n");
    dump();

    fileEnd();
    printf("\n");       // Just for looking purpose
}

void yyerror(char const *s){
    int line = returnLineCount();
    printf ("line %d: %s\n", line, s);
}

void fileInit(char* target){
    /* Open the specify file for yacc */
    stdin = fopen(target, "r");
    
    /* Filter the file name */
    classNameFilter(target);

    /* Create output .jasm file */
    sprintf(stringBuffer, "%s.jasm", className);
    file = fopen(stringBuffer, "w");

    /* Write corresponed class name(same as file name) */
    sprintf(stringBuffer, "class %s", className);
    writeLine(stringBuffer);
    writeLine("{");
}

void classNameFilter(char* target){
    int counter = 0;
    strcpy(className, "");
    while(target[counter] != '.'){
        sprintf(className, "%s%c", className, target[counter]);
        counter++;
    }
}

void fileEnd(){
    /* Check is there any main's definition, if not will create one */
    int* position = lookup("main");
    if(position[0] == -1){
        yyerror("main not define");
        writeLine("method public static void main(java.lang.String[])");
        writeLine("max_stack 15");
        writeLine("max_locals 15");
        writeLine("{");
        writeLine("return");
        writeLine("}");
    }
    writeLine("}");
    fclose(file);
}

void writeLine(char* code){
    char line[255];
    strcpy(line, code);

    /* If dectect main define, change to following string */
    if(strstr(code, "main") != NULL){
        strcpy(line, "method public static void main(java.lang.String[])");
    }
    strcpy(lineBuffer, line);
    strcat(line, "\n");
    fputs(line, file);
}

void writeValue(int type, char* value){
    /* Global variable and constant will not generate any definition */
    if(symbolTableCounter != 0 && writeValueSwitch == 1){
        char line[100];
        /*
            Use type parameter to separate different data type
            0 = boolean
            1 = string
            2 = integer 
        */
        switch(type){
            case 0:
                sprintf(line, "iconst_%s", value);
                break;
            case 1:
                sprintf(line, "ldc %s", value);
                break;
            case 2:
                sprintf(line, "sipush %s", value);
                break;
        }
        writeLine(line);
    }
    writeValueSwitch = 1;
}

void writeVariableDefinition(){
    char line[100];

    if(symbolTableCounter == 0)
    {   
        /* Global variable define */
        sprintf(line, "field static %s", stringBuffer);
        writeLine(line);
    }
    else
    {
        /* Local variable define */
        int* position;
        position = lookup(stringBuffer);
        sprintf(line, "istore %d", symbolTable[position[0]][position[1]].stackIndex);
        writeLine(line);
    }
}

void writeFunctionDefinition(){
    char line[100];
    int* position = lookup(stringBuffer);

    if(!strcmp(symbolTable[position[0]][position[1]].dataType ,"0")){
        if(!strcmp(symbolTable[position[0]][position[1]].format, "0")){
            sprintf(line, "method public static void %s()", symbolTable[position[0]][position[1]].name);
        }else{
            sprintf(line, "method public static void %s(%s)", symbolTable[position[0]][position[1]].name, symbolTable[position[0]][position[1]].format);
        }
    }else{
        if(!strcmp(symbolTable[position[0]][position[1]].format, "0")){
            sprintf(line, "method public static %s %s()", symbolTable[position[0]][position[1]].dataType, symbolTable[position[0]][position[1]].name);
        }else{
            sprintf(line, "method public static %s %s(%s)", symbolTable[position[0]][position[1]].dataType, symbolTable[position[0]][position[1]].name, symbolTable[position[0]][position[1]].format);
        }
    }

    writeLine(line);
    writeLine("max_stack 15");
    writeLine("max_locals 15");
    writeLine("{");
}

void writeIdAssignment(){
    char line[100];
    int* position = lookup(stringBuffer);
    
    if(symbolTable[position[0]][position[1]].mutable){
        if(position[0] == 0){
            /* Modify global variable */
            if(!strcmp(symbolTable[position[0]][position[1]].dataType, "0")){
                /* Default data type(int) */
                sprintf(line, "putstatic int %s.%s", className, stringBuffer);
            }else{
                sprintf(line, "putstatic %s %s.%s", symbolTable[position[0]][position[1]].dataType, className, stringBuffer);
            }
        }else{
            /* Modify local variable */
            sprintf(line, "istore %d", symbolTable[position[0]][position[1]].stackIndex);
        }
        writeLine(line);
    }else{
        writeLine("pop");
        yyerror("Try to modify constant");
    }
}

void writeLoadVariableValue(){
    char line[100];
    int* position = lookup(stringBuffer);

    if(symbolTable[position[0]][position[1]].mutable == 0) 
    {
        /* Constant */
        sprintf(line, "sipush %s", symbolTable[position[0]][position[1]].value);    
    }
    else
    {
        /* Variable */
        if(position[0] == 0){
            /* Global */
            sprintf(line, "getstatic %s %s.%s", symbolTable[position[0]][position[1]].dataType, className, symbolTable[position[0]][position[1]].name);
        }else{
            /* Local */
            sprintf(line, "iload %d", symbolTable[position[0]][position[1]].stackIndex);
        }
    }

    writeLine(line);
}

void writePrintExpression(int part, char* method){
    char line[100];
    char type[100];
    char *stringDectector;
    stringDectector = strstr(lineBuffer, "ldc");

    /* Detect last value is string or int */
    if(stringDectector == NULL){
        strcpy(type, "int");
    }else{
        strcpy(type, "java.lang.String");
    }

    switch(part){
        case 0:
            writeLine("getstatic java.io.PrintStream java.lang.System.out");
            break;
        case 1:
            sprintf(line, "invokevirtual void java.io.PrintStream.%s(%s)", method, type);
            writeLine(line);
            break;
    }
}

void writeFunctionInvocation(){
    char line[100];
    int* position = lookup(stringBuffer);
    if(!strcmp(symbolTable[position[0]][position[1]].dataType ,"0")){
        if(!strcmp(symbolTable[position[0]][position[1]].format, "0")){
            sprintf(line, "invokestatic void %s.%s()", className, symbolTable[position[0]][position[1]].name);
        }else{
            sprintf(line, "invokestatic void %s.%s(%s)", className, symbolTable[position[0]][position[1]].name, symbolTable[position[0]][position[1]].format);
        }
    }else{
        if(!strcmp(symbolTable[position[0]][position[1]].format, "0")){
            sprintf(line, "invokestatic %s %s.%s()", symbolTable[position[0]][position[1]].dataType, className, symbolTable[position[0]][position[1]].name);
        }else{
            sprintf(line, "invokestatic %s %s.%s(%s)", symbolTable[position[0]][position[1]].dataType, className, symbolTable[position[0]][position[1]].name, symbolTable[position[0]][position[1]].format);
        }
    }

    writeLine(line);
}

void writeFunctionInvocationParameter(char* dataType){
    char line[100];

    if(!strcmp(dataType, "boolean")){
        sprintf(line, "iconst_%s", stringBuffer);
        writeLine(line);
    }else if(!strcmp(dataType, "integer")){
        sprintf(line, "sipush %s", yylval.string);
        writeLine(line);
    }else if(!strcmp(dataType, "string")){
        sprintf(line, "ldc \"%s\"");
        writeLine(line);
    }else if(!strcmp(dataType, "id")){
        writeLoadVariableValue();
    }else{
        /* Do nothing */
    }
}

void writeBooleanExpression(){
    char line[100];
    writeLine("isub");
    sprintf(line, "%s B%d", stringBuffer, blockCounter);
    writeLine(line);

    /* Expression is false(not jump) */
    sprintf(line, "iconst_0");
    writeLine(line);
    sprintf(line, "goto B%d", blockCounter+1);
    writeLine(line);

    /* Expressionis true(jump) */
    sprintf(line, "B%d:", blockCounter);
    writeLine(line);
    sprintf(line, "iconst_1");
    writeLine(line);
    sprintf(line, "B%d:", blockCounter+1);
    writeLine(line);

    blockCounter += 2;
}

void writeIfBlock(int part){
    char line[100];
    /*
        Use part parameter to separate different state
        0 = Specify false block
        1 = When the true part end, goto the next execute part(when else statement exist)
        2 = Define false block(when else statement exist), or the next execute part
        3 = The next execute part(when else statement exist)
    */
    switch(part){
        case 0:
            sprintf(line, "ifeq B%d", blockCounter);
            writeLine(line);
            blockCounter += 2;
            break;
        case 1:
            sprintf(line, "goto B%d", blockCounter-1);
            writeLine(line);
            break;
        case 2:
            sprintf(line, "B%d:", blockCounter-2);
            writeLine(line);
            break;
        case 3:
            sprintf(line, "B%d:", blockCounter-1);
            writeLine(line);
            break;
    }
}

void writeWhileBlock(int part){
    char line[100];

    /*
        Use part parameter to separate different state
        0 = Specify while loop block
        1 = Condition check is held(not held will jump to the next execute)
        2 = Write Goto the loop start and define next execute part
    */
    switch(part){
        case 0:
            sprintf(line, "B%d:", blockCounter);
            writeLine(line);
            blockCounter += 2;
            lastBlockCounter = blockCounter;
            break;
        case 1:
            sprintf(line, "ifeq B%d", lastBlockCounter-1);
            writeLine(line);
            break;
        case 2:
            sprintf(line, "goto B%d", lastBlockCounter-2);
            writeLine(line);
            sprintf(line, "B%d:", lastBlockCounter-1);
            writeLine(line);
            break;
    }
}

void symbolTableInit(){
    for(int i=0;i<50;i++){
        for(int j=0;j<100;j++){
            strcpy(symbolTable[i][j].name, "0");
            symbolTable[i][j].mutable = 0;
            strcpy(symbolTable[i][j].dataType, "0");
            strcpy(symbolTable[i][j].value, "0");
            symbolTable[i][j].stackIndex = 0;
            strcpy(symbolTable[i][j].format, "0");
            symbolTable[i][j].insideVariableIndex = 0;
        }
    }
}

void storeVariableSlot(char* field, char* data){
    int available = findAvailable(symbolTableCounter);

    if(!strcmp("name", field))
    {
        /* Constant's do not take any place in local stack */
        if(symbolTable[symbolTableCounter][available].mutable){
            symbolTable[symbolTableCounter][available].stackIndex = stackIndexCounter;
        }else{
            stackIndexCounter--;
        }
        
        strcpy(symbolTable[symbolTableCounter][available].name, data);
        stackIndexCounter++;
    }
    else if(!strcmp("mutable", field))
    {
        symbolTable[symbolTableCounter][available].mutable = atoi(data);
    }
    else if(!strcmp("dataType", field))
    {
        strcpy(symbolTable[symbolTableCounter][available].dataType, data);
    }
    else if(!strcmp("value", field))
    {
        strcpy(symbolTable[symbolTableCounter][available].value, data);
    }
    else
    {
        /* Do nothing */
    }
}

void storeFunctionSlot(char* field, char* data, char* specifyFunction){
    int* targetPosition = lookup(specifyFunction);  // targetPosition[1] means the position in rootTable 0

    if(!strcmp("name", field))
    {
        int available = findAvailable(0);
        strcpy(symbolTable[0][available].name, data);
        symbolTable[0][available].insideVariableIndex = symbolTableCounter;
    }
    else if(!strcmp("dataType", field))
    {
        strcpy(symbolTable[0][targetPosition[1]].dataType, data);
    }
    else if(!strcmp("format", field))
    {
        char format[100];

        if(!strcmp(symbolTable[0][targetPosition[1]].format, "0"))
        {
            /* If current function's parameter is empty */
            strcpy(symbolTable[0][targetPosition[1]].format, data);
        }else
        {
            /* Not empty, concat exist format and current format with comma */
            strcpy(format, symbolTable[0][targetPosition[1]].format);
            strcat(format, ",");
            strcat(format, data);
            strcpy(symbolTable[0][targetPosition[1]].format, format);
        }

    }
    else if(!strcmp("insideVariableIndex", field))
    {
        symbolTable[0][targetPosition[1]].insideVariableIndex = atoi(data);
    }
    else
    {
        /* Do nothing */
    }
}

int findAvailable(int table){
    int position = 0;

    while(1)
    {
        if(!strcmp(symbolTable[table][position].name, "0")){
            break;
        }else{
            position++;
        }
    }

    return position;
}

int checkIdExist(char* name){
    int* result = lookup(name);
    int hint = 0;
    if(result[0] == -1){
        hint = 0;
    }else{
        hint = 1;
    }
    return hint;
}

int* lookup(char* name){
    int static result[2];

    /* Only search current table and root table */
    for(int i=0;i<100;i++){
        result[0] = -1;
        result[1] = -1;

        if(!strcmp(symbolTable[symbolTableCounter][i].name, name)){
            result[0] = symbolTableCounter;
            result[1] = i;
            break;
        }

        if(!strcmp(symbolTable[0][i].name, name)){
            result[0] = 0;
            result[1] = i;
            break;
        }
    }

    return result;
}

void dump(){
    for(int i=0;i<50;i++){
        if(strcmp(symbolTable[i][0].name, "0")){
            printf("Level: %d\n-------------------\n", i);
        }else{
            continue;
        }

        for(int j=0;j<100;j++){
            if(strcmp(symbolTable[i][j].name, "0")){
                printf("name: %s\n", symbolTable[i][j].name);
                printf("mutable: %d\n", symbolTable[i][j].mutable);
                printf("data type: %s\n", symbolTable[i][j].dataType);
                printf("vaule: %s\n", symbolTable[i][j].value);
                printf("stack index: %d\n", symbolTable[i][j].stackIndex);
                printf("format: %s\n", symbolTable[i][j].format);
                printf("table index: %d\n\n", symbolTable[i][j].insideVariableIndex);
            }else{
                continue;
            }
        }
    }
}
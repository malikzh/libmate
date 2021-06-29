%top {
    #include "../mate.h"
    #include "parser.h"
    #define YY_EXTRA_TYPE am_parser_t*
    #define yyterminate() return T_EOF;

    #define YY_USER_ACTION {         \
        yylloc->first_line = yylloc->last_line; \
        yylloc->last_line  = yylineno;    \
    }
}

%option outfile="lexer.c"
%option noinput nounput noyywrap 8bit nodefault                                 
%option yylineno
%option reentrant bison-bridge bison-locations

whitespace [ \t]
newline    [\r\n]
alpha      [a-zA-Z_]
digit      [0-9]
alphadigit [a-zA-Z_0-9]

%%

<INITIAL>{
    {whitespace}+            ;
    {newline}                ;
    {alpha}{alphadigit}*     return T_IDENTIFIER;
    "."                      return '.';
}

"\0"                         yyterminate();
<<EOF>>                      yyterminate();
[\x01-\x7f]|[\x80-\xff]+     {printf("lex Unknown character = '%d', '%s'", (char)yytext[0], yytext); yyerror(yylloc, yyextra, NULL, "Invalid input");}

%%

void lexer_initialize(am_parser_t* parser) {
    yylex_init_extra(parser, &parser->scanner);
    yyrestart(parser->fd, parser->scanner);
}

void lexer_destroy(am_parser_t* parser) {
    yylex_destroy(parser->scanner);
}

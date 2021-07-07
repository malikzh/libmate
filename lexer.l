%top {
    #include "../mate.h"
    #include "parser.h"
    #include "../lexer.h"
    #include <stdlib.h>
    #define YY_EXTRA_TYPE am_parser_t*
    #define yyterminate() return T_EOF;

    #define YY_USER_ACTION {         \
        yylloc->first_line = yylloc->last_line; \
        yylloc->last_line  = yylineno;    \
    }

    char* strbuf = NULL;


    #define STRBUF_CLEAR() strbuffer_clear(&strbuf)
    #define STRBUF_CONCAT(str) strbuffer_concat(&strbuf, str)
    #define STRBUF_PUT(c) strbuffer_put(&strbuf, c)
    #define STRBUF_COPY() strbuffer_copy(strbuf)

    #define LEXER_ERRBUF_SIZE 200

    #define LEXER_ERROR() char errstr[LEXER_ERRBUF_SIZE]; snprintf(errstr, LEXER_ERRBUF_SIZE, "Lexical error: Unexpected input '%s'", yytext); yyerror(yylloc, yyextra, NULL, errstr)

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
hex        [a-fA-F0-9]
bin        [01]

%s STRING_S
%s STRING_D
%s COMMENT_S
%s COMMENT_D
%s SHEBANG
%%

<INITIAL>{
    {whitespace}+            ;
    {newline}                ;
    ";"                      return ';';


    "++"                     return T_INCREMENT;
    "--"                     return T_DECREMENT;
    "**"                     return T_POWER;
    ">="                     return T_GTE;
    "<="                     return T_LTE;
    "=="                     return T_EQUAL;
    "!="                     return T_NOT_EQUAL;
    "+="                     return T_ASSIGN_ADD;
    "-="                     return T_ASSIGN_SUB;
    "*="                     return T_ASSIGN_MUL;
    "/="                     return T_ASSIGN_DIV;
    "%="                     return T_ASSIGN_MOD;
    "//"                     { BEGIN(COMMENT_S); }
    "/*"                     { BEGIN(COMMENT_D); }
    "#!"                     { if (yylineno > 1) { LEXER_ERROR(); } else { BEGIN(SHEBANG); } }
    "("                      return '(';
    ")"                      return ')';
    "["                      return '[';
    "]"                      return ']';
    "{"                      return '{';
    "}"                      return '}';
    "."                      return '.';
    ","                      return ',';
    "+"                      return '+';
    "-"                      return '-';
    "*"                      return '*';
    "/"                      return '/';
    "%"                      return '%';
    ">"                      return '>';
    "<"                      return '<';
    "?"                      return '?';
    ":"                      return ':';
    "="                      return '=';
    "@"                      return '@';
    "|"                      return '|';

    "true"                   return T_TRUE;
    "false"                  return T_FALSE;
    "not"                    return T_NOT;
    "and"                    return T_AND;
    "or"                     return T_OR;
    "implements"             return T_IMPLEMENTS;
    "typeof"                 return T_TYPEOF;
    "func"                   return T_FUNC;
    "defer"                  return T_DEFER;
    "if"                     return T_IF;
    "else"                   return T_ELSE;
    "dump"                   return T_DUMP;
    "require"                return T_REQUIRE;
    "switch"                 return T_SWITCH;
    "case"                   return T_CASE;
    "continue"               return T_CONTINUE;
    "break"                  return T_BREAK;
    "default"                return T_DEFAULT;
    "define"                 return T_DEFINE;
    "while"                  return T_WHILE;
    "for"                    return T_FOR;
    "struct"                 return T_STRUCT;
    "array"                  return T_ARRAY;
    "iface"                  return T_IFACE;
    "null"                   return T_NULL;
    "var"                    return T_VAR;
    "return"                 return T_RETURN;
    "const"                  return T_CONST;
    "native"                 return T_NATIVE;

    {alpha}{alphadigit}*     { yylval->str = strdup(yytext); return T_IDENTIFIER; }
    \"                       { BEGIN(STRING_D); STRBUF_CLEAR(); }
    \'                       { BEGIN(STRING_S); STRBUF_CLEAR(); }
    0x{hex}+                 { yylval->i = strtol(yytext + 2, NULL, 16); return T_INTEGER; }
    0b{bin}+                 { yylval->i = strtol(yytext + 2, NULL, 2); return T_INTEGER; }
    {digit}+                 { yylval->i = atol(yytext); return T_INTEGER; }
    {digit}+\.{digit}+       { yylval->f = strtod(yytext, NULL); return T_FLOAT; }
    \.{digit}+               { yylval->f = strtod(yytext, NULL); return T_FLOAT; }
    \${alpha}{alphadigit}*   { yylval->str = strdup(yytext + 1); return T_VARIABLE; }
}

<COMMENT_S,SHEBANG>{
    {newline}                { BEGIN(INITIAL); }
    [\x01-\xFF]              ;
}

<COMMENT_D>{
    "*/"                     { BEGIN(INITIAL); }
    [\x01-\xFF]              ;
}

<STRING_D>{
    \\\"                     STRBUF_PUT('\"');
    [^\\"]*                  STRBUF_CONCAT(yytext);
    \"                       { yylval->str = STRBUF_COPY(); BEGIN(INITIAL); return T_STRING; }
}

<STRING_S>{
    \\\'                     STRBUF_PUT('\'');
    [^\\']*                  STRBUF_CONCAT(yytext);
    \'                       { yylval->str = STRBUF_COPY(); BEGIN(INITIAL); return T_STRING; }
}

<STRING_D,STRING_S>{
    \\a                      STRBUF_PUT('\a');
    \\b                      STRBUF_PUT('\b');
    \\f                      STRBUF_PUT('\f');
    \\n                      STRBUF_PUT('\n');
    \\r                      STRBUF_PUT('\r');
    \\t                      STRBUF_PUT('\t');
    \\v                      STRBUF_PUT('\v');
    \\\\                     STRBUF_PUT('\\');
    \\                       STRBUF_PUT('\\');
}

"\0"                         yyterminate();
<<EOF>>                      yyterminate();
[\x01-\xFF]                  { LEXER_ERROR(); }

%%

void lexer_initialize(am_parser_t* parser) {
    yylex_init_extra(parser, &parser->scanner);
    yyrestart(parser->fd, parser->scanner);
}

void lexer_destroy(am_parser_t* parser) {
    yylex_destroy(parser->scanner);
}

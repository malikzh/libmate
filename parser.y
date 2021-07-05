%glr-parser
%defines "parser.h"
%define parse.error verbose
%verbose
%file-prefix "parser"
%output "parser.c"
%define api.pure
%locations
%parse-param {am_parser_t *info}
%parse-param {void *scanner}
%lex-param   {void *scanner}

%code requires {
    #include<stdlib.h>
    #include "../mate.h"
    #include "../ast.h"

    #define YYLTYPE am_node_location_t

    struct am_parser {
        const char* filename;
        FILE* fd;
        const char* input;
        am_node_t* root;
        void* scanner;
    };
}

%union {
    const char* str;
    am_node_t* node;
    intmax_t i;
    double f;
}

%code provides
{
    void lexer_initialize(am_parser_t* parser);
    void lexer_destroy(am_parser_t* parser);
    void yyerror(am_node_location_t *location, am_parser_t* parser, void *scanner,  const char *msg);
    #define YY_DECL int yylex \
               (YYSTYPE* yylval_param, am_node_location_t* yylloc_param , void *yyscanner)
    extern YY_DECL;
}

%{
        //
        #define NODE_A(mean, a) ast_create_node(mean, &yylloc, a, NULL, NULL, NULL);
        #define NODE_S(mean, str) ast_create_node(mean, &yylloc, NULL, NULL, NULL, str)
%}

%token T_EOF 0 "T_EOF"
%token T_UNDEFINED

%token T_IDENTIFIER T_VARIABLE T_STRING T_INTEGER T_FLOAT T_TRUE T_FALSE
%token T_INCREMENT T_DECREMENT T_LTE T_GTE T_EQUAL T_NOT_EQUAL T_POWER
%token T_ASSIGN_ADD T_ASSIGN_SUB T_ASSIGN_MUL T_ASSIGN_DIV T_ASSIGN_MOD
%token T_NOT T_AND T_OR T_IMPLEMENTS T_TYPEOF T_FUNC T_DEFER T_ERROR T_IF T_ELSE T_DUMP T_RESET
%token T_REQUIRE T_SWITCH T_CASE T_CONTINUE T_BREAK T_DEFAULT T_DEFINE
%token T_WHILE T_FOR T_STRUCT T_ARRAY T_IFACE T_NULL T_VAR T_RETURN T_CONST T_NATIVE

%type <node> source_code expression_primary

%start program 
%%

expression_primary: T_VARIABLE { $$ = NODE_S(AM_I_RESOLVE_VARIABLE, yylval.str); }
                  ;

source_code: expression_primary { $$ = NODE_A(AM_S_IM, $1) }
           ;

program: source_code { info->root = NODE_A(AM_S_ROOT, $1); }
       ;
%%

void yyerror(am_node_location_t *location, am_parser_t* parser, void *scanner,  const char *msg) {
    printf("err: %s\n", msg);
}

am_parser_t* am_parser_create_from_fd(const char* filename, FILE* fd) {
    am_parser_t* parser = (am_parser_t*)malloc(sizeof(am_parser_t));
    parser->fd = fd;
    parser->input = NULL;
    parser->root = NULL;

    // Initialize scanner
    lexer_initialize(parser);

    return parser;
}

am_parser_t* am_parser_create_from_str(const char* filename, const char* input) {
    // TODO: create string parser;
    return NULL;
}

int am_parser_parse(am_parser_t* parser) {
    return yyparse(parser, parser->scanner);
}

am_node_t* am_parser_get_ast_root(am_parser_t* parser) {
    return parser->root;
}

void am_parser_destroy(am_parser_t* parser) {
    lexer_destroy(parser);
    // TODO: destroy ast tree
    free(parser);
}

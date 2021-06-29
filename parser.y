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

%token T_EOF 0 "T_EOF"
%token T_UNDEFINED
%token T_IDENTIFIER

//%start expression_property
%%

expression_property: '.' T_IDENTIFIER 
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

void am_parser_destroy(am_parser_t* parser) {
    lexer_destroy(parser);
    free(parser);
}

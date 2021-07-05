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
        #define NODE(mean) ast_create_node(mean, &yylloc, NULL, NULL, NULL, NULL);
        #define NODE_A(mean, a) ast_create_node(mean, &yylloc, a, NULL, NULL, NULL);
        #define NODE_AB(mean, a, b) ast_create_node(mean, &yylloc, a, b, NULL, NULL);
        #define NODE_ABC(mean, a, b, c) ast_create_node(mean, &yylloc, a, b, c, NULL);
        #define NODE_S(mean, str) ast_create_node(mean, &yylloc, NULL, NULL, NULL, str)
        #define NODE_AS(mean, a, str) ast_create_node(mean, &yylloc, a, NULL, NULL, str)
%}

%token T_EOF 0 "T_EOF"
%token T_UNDEFINED

%token T_IDENTIFIER T_VARIABLE T_STRING T_INTEGER T_FLOAT T_TRUE T_FALSE
%token T_INCREMENT T_DECREMENT T_LTE T_GTE T_EQUAL T_NOT_EQUAL T_POWER
%token T_ASSIGN_ADD T_ASSIGN_SUB T_ASSIGN_MUL T_ASSIGN_DIV T_ASSIGN_MOD
%token T_NOT T_AND T_OR T_IMPLEMENTS T_TYPEOF T_FUNC T_DEFER T_ERROR T_IF T_ELSE T_DUMP T_RESET
%token T_REQUIRE T_SWITCH T_CASE T_CONTINUE T_BREAK T_DEFAULT T_DEFINE
%token T_WHILE T_FOR T_STRUCT T_ARRAY T_IFACE T_NULL T_VAR T_RETURN T_CONST T_NATIVE

%type <str> T_IDENTIFIER T_STRING T_INTEGER T_FLOAT T_VARIABLE
%type <node> source_code expression_primary symbol expression_literal expression array_literal_items
%type <node> array_literal struct_literal_items struct_literal_item struct_literal function_body
%type <node> typename function_argument function_arguments expression_function function_call
%type <node> expression_postfix expression_prefix expression_mul expression_power expression_add
%type <node> expression_rel expression_eq expression_and expression_or expression_specific 
%type <node> expression_ternary

%start program 
%%

symbol: symbol '.' T_IDENTIFIER                         { $$ = NODE_AS(AM_S_SYMBOL, $1, $3); }
      | T_IDENTIFIER                                    { $$ = NODE_S(AM_S_SYMBOL, $1); }
      ;

typename: typename '|' symbol                           { $$ = NODE_AB(AM_S_TYPENAME, $1, $3); }
        | symbol                                        { $$ = $1; }
        ;

array_literal_items: array_literal_items ',' expression { $$ = NODE_AB(AM_S_ARRAY_ITEMS, $1, $3); }
                   | expression                         { $$ = $1; }
                   ;

array_literal: T_ARRAY '[' ']'                          { $$ = NULL; }
             | T_ARRAY '[' array_literal_items ']'      { $$ = $3; }
             ;

struct_literal_item: T_IDENTIFIER ':' expression        { $$ = NODE_AS(AM_S_STRUCT_ITEM, $3, $1); }
                   | T_STRING ':' expression            { $$ = NODE_AS(AM_S_STRUCT_ITEM, $3, $1); }
                   ;

struct_literal_items: struct_literal_items ',' struct_literal_item { $$ = NODE_AB(AM_S_STRUCT_ITEMS, $1, $3); }
                    | struct_literal_item                          { $$ = $1; }
                    ;

struct_literal: T_STRUCT '{' '}'                        { $$ = NULL; } 
              | T_STRUCT '{' struct_literal_items '}'   { $$ = $3; }
              ;

function_argument: T_VARIABLE ':' typename              { $$ = NODE_AS(AM_S_FUNCTION_ARGUMENT, $3, $1); }
                 | T_VARIABLE                           { $$ = NODE_S(AM_S_FUNCTION_ARGUMENT, $1); }
                 ;

function_arguments: %empty                                   { $$ = NULL; }
                  | function_arguments ',' function_argument { $$ = NODE_AB(AM_S_FUNCTION_ARGUMENTS, $1, $3); }
                  | function_argument                        { $$ = $1; }
                  ;

expression_function: T_FUNC '(' function_arguments ')' '{' function_body '}' { $$ = NODE_AB(AM_S_FUNCTION_CALLBACK, $3, $6); }
                   ;



expression_literal: T_STRING                            { $$ = NODE_S(AM_S_STRING, $1); }
                  | T_INTEGER                           { $$ = NODE_S(AM_S_INT, $1); }
                  | T_FLOAT                             { $$ = NODE_S(AM_S_FLOAT, $1); }
                  | T_TRUE                              { $$ = NODE(AM_S_TRUE); }
                  | T_FALSE                             { $$ = NODE(AM_S_FALSE); }
                  | T_NULL                              { $$ = NODE(AM_S_NULL); }
                  | array_literal                       { $$ = NODE_A(AM_S_ARRAY, $1); }
                  | struct_literal                      { $$ = NODE_A(AM_S_STRUCT, $1); }
                  | expression_function                 { $$ = $1; }
                  ;



expression_primary: T_VARIABLE                          { $$ = NODE_S(AM_I_RESOLVE_VARIABLE, $1); }
                  | T_IDENTIFIER                        { $$ = NODE_S(AM_S_SYMBOL, $1); }
                  | expression_literal                  { $$ = $1; }
                  | '(' expression ')'                  { $$ = $2; }
                  ;

function_call: expression_postfix '(' ')'               { $$ = NODE_A(AM_I_FUNC_CALL, $1) }
             | expression_postfix '(' array_literal_items ')' { $$ = NODE_AB(AM_I_FUNC_CALL, $1, $3); }
             ;

expression_postfix: function_call                         { $$ = $1; }
                  | expression_postfix '[' expression ']' { $$ = NODE_AB(AM_I_INDEX, $1, $3); }
                  | expression_primary T_INCREMENT        { $$ = NODE_A(AM_I_POST_INC, $1); }
                  | expression_primary T_DECREMENT        { $$ = NODE_A(AM_I_POST_DEC, $1); }
                  | expression_postfix '.' T_IDENTIFIER   { $$ = NODE_AS(AM_I_OBJECT_INDEX, $1, $3); }
                  | expression_primary                    { $$ = $1; }
                  ;

expression_prefix: expression_postfix                     { $$ = $1; }
                 | T_INCREMENT expression_postfix         { $$ = NODE_A(AM_I_PRE_INC, $2); }
                 | T_DECREMENT expression_postfix         { $$ = NODE_A(AM_I_PRE_DEC, $2); }
                 | '+' expression_prefix                  { $$ = NODE_A(AM_I_UPLUS, $2); }
                 | '-' expression_prefix                  { $$ = NODE_A(AM_I_UMINUS, $2); }
                 | T_NOT expression_prefix                { $$ = NODE_A(AM_I_NOT, $2); }
                 | '<' symbol '>' expression_prefix       { $$ = NODE_AB(AM_I_CAST, $4, $2); }
                 | '@' expression_postfix                 { $$ = NODE_A(AM_I_ERROF, $2); }
                 ;

expression_specific: expression_prefix                                { $$ = $1; }
                   | expression_prefix T_IMPLEMENTS expression_prefix { $$ = NODE_AB(AM_I_IMPLEMENTS, $1, $3); }
                   | T_TYPEOF expression_prefix                       { $$ = NODE_A(AM_I_TYPEOF, $2); }
                   ;

expression_power: expression_specific                          { $$ = $1; }
                | expression_specific T_POWER expression_power { $$ = NODE_AB(AM_I_POW, $1, $3); }
                ;

expression_mul: expression_power                          { $$ = $1; }
              | expression_mul '*' expression_power       { $$ = NODE_AB(AM_I_MUL, $1, $3); }
              | expression_mul '/' expression_power       { $$ = NODE_AB(AM_I_DIV, $1, $3); }
              | expression_mul '%' expression_power       { $$ = NODE_AB(AM_I_MOD, $1, $3); }
              ;

expression_add: expression_mul                            { $$ = $1; }
              | expression_add '+' expression_mul         { $$ = NODE_AB(AM_I_ADD, $1, $3); } 
              | expression_add '-' expression_mul         { $$ = NODE_AB(AM_I_SUB, $1, $3); } 
              ;

expression_rel: expression_add                            { $$ = $1; }
              | expression_add '>' expression_add         { $$ = NODE_AB(AM_I_GT, $1, $3); }
              | expression_add '<' expression_add         { $$ = NODE_AB(AM_I_LT, $1, $3); }
              | expression_add T_GTE expression_add         { $$ = NODE_AB(AM_I_GTE, $1, $3); }
              | expression_add T_LTE expression_add         { $$ = NODE_AB(AM_I_LTE, $1, $3); }
              ;

expression_eq: expression_rel                             { $$ = $1; }
             | expression_eq T_EQUAL expression_rel       { $$ = NODE_AB(AM_I_EQ, $1, $3); }
             | expression_eq T_NOT_EQUAL expression_rel   { $$ = NODE_AB(AM_I_NEQ, $1, $3); }
             ;

expression_and: expression_eq                             { $$ = $1; }
              | expression_and T_AND expression_eq        { $$ = NODE_AB(AM_I_AND, $1, $3); }
              ;

expression_or: expression_and                             { $$ = $1; }
             | expression_or T_OR expression_and        { $$ = NODE_AB(AM_I_OR, $1, $3); }
             ;

expression_ternary: expression_or                             { $$ = $1; }
                  | expression_or '?' expression_ternary ':' expression_ternary { $$ = NODE_ABC(AM_I_TERNARY, $1, $3, $5); }
                  ;

expression: expression_ternary                                { $$ = $1; }
          ;

function_body: %empty                                   { $$ = NULL; }
             | expression                               { $$ = $1; }
             ;

source_code: function_body                              { $$ = $1; }
           ;

program: source_code                                    { info->root = NODE_A(AM_S_ROOT, $1); }
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

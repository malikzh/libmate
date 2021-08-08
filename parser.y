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
        const char* msg;
        struct yy_buffer_state* buffer;
    };

    void am_parser_set_error(am_parser_t* parser, const char* message);
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
        #define NODE(mean) ast_create_node(mean, &yylloc, NULL, NULL, NULL, NULL, NULL, NULL);
        #define NODE_A(mean, a) ast_create_node(mean, &yylloc, a, NULL, NULL, NULL, NULL, NULL);
        #define NODE_AB(mean, a, b) ast_create_node(mean, &yylloc, a, b, NULL, NULL, NULL, NULL);
        #define NODE_ABC(mean, a, b, c) ast_create_node(mean, &yylloc, a, b, c, NULL, NULL, NULL);
        #define NODE_ABCD(mean, a, b, c, d) ast_create_node(mean, &yylloc, a, b, c, d, NULL, NULL);
        #define NODE_ABCS(mean, a, b, c, s) ast_create_node(mean, &yylloc, a, b, c, NULL, s, NULL);
        #define NODE_S(mean, str) ast_create_node(mean, &yylloc, NULL, NULL, NULL, NULL, str, NULL)
        #define NODE_SS(mean, str, str2) ast_create_node(mean, &yylloc, NULL, NULL, NULL, NULL, str, str2)
        #define NODE_AS(mean, a, str) ast_create_node(mean, &yylloc, a, NULL, NULL, NULL, str, NULL)
        #define NODE_ABS(mean, a, b, str) ast_create_node(mean, &yylloc, a, b, NULL, NULL, str, NULL)
%}

%token T_EOF 0 "T_EOF"
%token T_UNDEFINED

%token T_IDENTIFIER T_VARIABLE T_STRING T_INTEGER T_FLOAT T_TRUE T_FALSE T_ALIAS
%token T_INCREMENT T_DECREMENT T_LTE T_GTE T_EQUAL T_NOT_EQUAL T_POWER
%token T_ASSIGN_ADD T_ASSIGN_SUB T_ASSIGN_MUL T_ASSIGN_DIV T_ASSIGN_MOD
%token T_NOT T_AND T_OR T_IMPLEMENTS T_TYPEOF T_FUNC T_DEFER T_IF T_ELSE T_DUMP
%token T_REQUIRE T_SWITCH T_CASE T_CONTINUE T_BREAK T_DEFAULT T_DEFINE
%token T_WHILE T_FOR T_STRUCT T_ARRAY T_IFACE T_NULL T_VAR T_RETURN T_CONST T_NATIVE

%type <str> T_IDENTIFIER T_STRING T_INTEGER T_FLOAT T_VARIABLE
%type <node> expression_primary symbol expression_literal expression array_literal_items
%type <node> array_literal struct_literal_items struct_literal_item struct_literal function_body
%type <node> typename function_argument function_arguments expression_function function_call
%type <node> expression_postfix expression_prefix expression_mul expression_power expression_add
%type <node> expression_rel expression_eq expression_and expression_or expression_specific 
%type <node> expression_ternary expression_assign function_arguments_types_only typename_func
%type <node> statement statements stmt_defer stmt_if stmt_dump stmt_case stmt_default
%type <node> stmt_switch stmt_case_body_list stmt_case_body stmt_continue stmt_break stmt_var 
%type <node> stmt_var_type stmt_var_expression stmt_const stmt_return stmt_while stmt_while_else
%type <node> stmt_for_init stmt_for_condition stmt_for_action stmt_for stmt_for_head stmt_foreach_head
%type <node> expression_list stmt_for_init_expression stmt_for_init_expression_list require_item
%type <node> require_item_list block_require block_define define_func block_define_list block_definitions
%type <node> meta_tag_values meta_tag_list meta_tag_section meta_tag define_const define_right_side
%type <node> define_alias typename_id define_native define_struct struct_field struct_field_list
%type <node> define_iface iface_func iface_func_list program iface_extends iface_extends_list

%start program 
%%

symbol: symbol '.' T_IDENTIFIER                         { $$ = NODE_AS(AM_S_SYMBOL, $1, $3); }
      | T_IDENTIFIER                                    { $$ = NODE_S(AM_S_SYMBOL, $1); }
      ;

function_arguments_types_only: %empty                                     { $$ = NULL; }
                             | function_arguments_types_only ',' typename { $$ = NODE_AB(AM_S_TYPENAME, $1, $3); }
                             | typename                                   { $$ = $1; }
                             ;

typename_func: T_FUNC '(' function_arguments_types_only ')' '<' typename '>'  { $$ = NODE_AB(AM_S_TYPENAME_FUNC, $3, $6); }
             | T_FUNC '(' function_arguments_types_only ')' { $$ = NODE_A(AM_S_TYPENAME_FUNC, $3); }
             ;

typename_id: symbol '[' ']'                                { $$ = NODE_A(AM_S_TYPENAME_ARRAY_OF, $1); }
        | symbol                                        { $$ = $1; }
        | T_ARRAY                                       { $$ = NODE(AM_S_TYPENAME_ARRAY); }
        | T_STRUCT                                      { $$ = NODE(AM_S_TYPENAME_STRUCT); }
        | typename_func                                 { $$ = NODE_A(AM_S_TYPENAME_FUNC, $1); }
        ;

typename: typename '|' typename_id                      { $$ = NODE_AB(AM_S_TYPENAME, $1, $3); }
        | typename_id                                   { $$ = $1; }
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
                   | T_FUNC '(' function_arguments ')' '<' typename '>' '{' function_body '}' { $$ = NODE_ABC(AM_S_FUNCTION_CALLBACK, $3, $9, $6); }
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
                  | T_VARIABLE                          { $$ = NODE_S(AM_I_RESOLVE_VARIABLE, $1); }
                  | T_IDENTIFIER                        { $$ = NODE_S(AM_S_SYMBOL, $1); }
                  ;



expression_primary: expression_literal                  { $$ = $1; }
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
                  | expression_postfix '@'                { $$ = NODE_A(AM_I_METAOF, $1); }
                  | expression_primary                    { $$ = $1; }
                  ;
               
expression_prefix: expression_postfix                     { $$ = $1; }
                 | T_INCREMENT expression_postfix         { $$ = NODE_A(AM_I_PRE_INC, $2); }
                 | T_DECREMENT expression_postfix         { $$ = NODE_A(AM_I_PRE_DEC, $2); }
                 | '+' expression_prefix                  { $$ = NODE_A(AM_I_UPLUS, $2); }
                 | '-' expression_prefix                  { $$ = NODE_A(AM_I_UMINUS, $2); }
                 | T_NOT expression_prefix                { $$ = NODE_A(AM_I_NOT, $2); }
                 | '<' symbol '>' expression_prefix       { $$ = NODE_AB(AM_I_CAST, $4, $2); }
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

expression_assign: expression_ternary                                   { $$ = $1; }
                 | expression_postfix '=' expression_assign             { $$ = NODE_AB(AM_I_ASSIGN, $1, $3); }
                 | expression_postfix T_ASSIGN_ADD expression_assign    { $$ = NODE_AB(AM_I_ASSIGN_ADD, $1, $3); }
                 | expression_postfix T_ASSIGN_SUB expression_assign    { $$ = NODE_AB(AM_I_ASSIGN_SUB, $1, $3); }
                 | expression_postfix T_ASSIGN_MUL expression_assign    { $$ = NODE_AB(AM_I_ASSIGN_MUL, $1, $3); }
                 | expression_postfix T_ASSIGN_DIV expression_assign    { $$ = NODE_AB(AM_I_ASSIGN_DIV, $1, $3); }
                 | expression_postfix T_ASSIGN_MOD expression_assign    { $$ = NODE_AB(AM_I_ASSIGN_MOD, $1, $3); }
                 ;

expression: expression_assign                                { $$ = $1; }
          ;

expression_list: expression_list ',' expression                      { $$ = NODE_AB(AM_S_EXPRESSIONS, $1, $3); }
               | expression                                      { $$ = $1; }
               ;

stmt_defer: T_DEFER expression ';'                           { $$ = NODE_A(AM_S_DEFER, $2); }
          ;

stmt_if: T_IF expression '{' function_body '}'                              { $$ = NODE_AB(AM_S_IF, $2, $4); }
       | T_IF expression '{' function_body '}' T_ELSE '{' function_body '}' { $$ = NODE_ABC(AM_S_IF, $2, $4, $8); }
       | T_IF expression '{' function_body '}' T_ELSE stmt_if               { $$ = NODE_ABC(AM_S_IF, $2, $4, $7); }
       ;

stmt_dump: T_DUMP expression ';'                             { $$ = NODE_A(AM_S_DUMP, $2); }
         ;

stmt_case: T_CASE expression ':'                             { $$ = $2; }
         ;

stmt_case_body: stmt_case function_body                      { $$ = NODE_AB(AM_S_SWITCH_CASE, $1, $2); }
              ;

stmt_case_body_list: stmt_case_body_list stmt_case_body      { $$ = NODE_AB(AM_S_SWITCH_CASE_LIST, $1, $2); }
                   | stmt_case_body                          { $$ = $1; }
                   ;

stmt_default: T_DEFAULT ':' function_body                    { $$ = NODE_A(AM_S_SWITCH_DEFAULT, $3); }
            | %empty                                         { $$ = NULL; }
            ;

stmt_switch: T_SWITCH expression '{' stmt_case_body_list stmt_default '}' { $$ = NODE_ABC(AM_S_SWITCH, $2, $4, $5); }
           | T_SWITCH '{' stmt_case_body_list stmt_default '}'            { $$ = NODE_ABC(AM_S_SWITCH, NULL, $3, $4); }
           ;

stmt_continue: T_CONTINUE T_INTEGER ';'                      { $$ = NODE_S(AM_I_CONTINUE, $2); }
             | T_CONTINUE ';'                                { $$ = NODE_S(AM_I_CONTINUE, NULL); }
             ;

stmt_break: T_BREAK T_INTEGER ';'                            { $$ = NODE_S(AM_I_BREAK, $2); }
          | T_BREAK ';'                                      { $$ = NODE_S(AM_I_BREAK, NULL);  }
          ;

stmt_var_type: ':' typename                                  { $$ = $2; }
             | %empty                                        { $$ = NULL; }
             ;

stmt_var_expression: '=' expression                          { $$ = $2; }
                   | %empty                                  { $$ = NULL; }
                   ;

stmt_var: T_VAR T_VARIABLE stmt_var_type stmt_var_expression ';'   { $$ = NODE_ABS(AM_S_VAR, $3, $4, $2); }
        ;

stmt_const: T_CONST T_VARIABLE '=' expression ';'     { $$ = NODE_AS(AM_S_CONST, $4, $2); }
          ;

stmt_return: T_RETURN expression ';'                         { $$ = NODE_A(AM_I_RETURN, $2); }
           ;

stmt_while_else: T_ELSE '{' function_body '}'                { $$ = $3; }
               | %empty                                      { $$ = NULL; }
               ;

stmt_while: T_WHILE expression '{' function_body '}' stmt_while_else     { $$ = NODE_ABC(AM_S_WHILE, $2, $4, $6); }
          | T_WHILE '{' function_body '}' stmt_while_else                { $$ = NODE_ABC(AM_S_WHILE, NULL, $3, $5); }
          ;

stmt_for_init_expression: expression                                     { $$ = $1; }
                        | stmt_var                                       { $$ = $1; }
                        ;

stmt_for_init_expression_list: stmt_for_init_expression_list ',' stmt_for_init_expression   { $$ =  NODE_AB(AM_S_STATEMENTS, $1, $3); }
                             | stmt_for_init_expression                                     { $$ = $1; }
                             ;
                             
stmt_for_init: stmt_for_init_expression_list ';'                         { $$ = $1; }
             | ';'                                                       { $$ = NULL; }
             ;

stmt_for_condition: expression_list ';'                                  { $$ = $1; }
                  | ';'                                                  { $$ = NULL; }
                  ;

stmt_for_action: expression_list                                         { $$ = $1; }
               | %empty                                                  { $$ = NULL; }
               ;

stmt_for_head: stmt_for_init stmt_for_condition stmt_for_action          { $$ = NODE_ABC(AM_S_FOR_HEAD, $1, $2, $3); }
             ;

stmt_foreach_head: expression_postfix ':' expression                     { $$ = NODE_AB(AMS_S_FOREACH_HEAD, $1, $3); }
                 ;

stmt_for: T_FOR stmt_for_head '{' function_body '}' stmt_while_else      { $$ = NODE_ABC(AM_S_FOR, $2, $4, $6); }
        | T_FOR stmt_foreach_head '{' function_body '}' stmt_while_else  { $$ = NODE_ABC(AM_S_FOR, $2, $4, $6); }
        ;

statement: expression ';'                                    { $$ = $1; }
         | stmt_defer                                        { $$ = $1; }
         | stmt_if                                           { $$ = $1; }
         | stmt_dump                                         { $$ = $1; }
         | stmt_switch                                       { $$ = $1; }
         | stmt_continue                                     { $$ = $1; }
         | stmt_break                                        { $$ = $1; }
         | stmt_var                                          { $$ = $1; }
         | stmt_const                                        { $$ = $1; }
         | stmt_return                                       { $$ = $1; }
         | stmt_while                                        { $$ = $1; }
         | stmt_for                                          { $$ = $1; }
         | ';'                                               { $$ = NULL; }
         ;

statements: statements statement                             { $$ = NODE_AB(AM_S_STATEMENTS, $1, $2); }
          | statement                                        { $$ = $1; }
          ;

function_body: %empty                                        { $$ = NULL; }
             | statements                                    { $$ = $1; }
             ;


require_item: T_IDENTIFIER T_STRING                          { $$ = NODE_SS(AM_S_REQUIRE_ITEM, $1, $2); }
            | '.' T_STRING                                   { $$ = NODE_SS(AM_S_REQUIRE_ITEM, ".", $2); }
            | T_STRING                                       { $$ = NODE_SS(AM_S_REQUIRE_ITEM, NULL, $1); }
            ;

require_item_list: require_item_list require_item            { $$ = NODE_AB(AM_S_REQUIRE_ITEM_LIST, $1, $2);  }
                 | require_item                              { $$ = $1; }
                 ;

block_require: T_REQUIRE '(' require_item_list ')'           { $$ = NODE_A(AM_S_REQUIRE, $3); }
             | T_REQUIRE '(' ')'                             { $$ = NULL; }
             | %empty                                        { $$ = NULL; }
             ;

define_func: T_FUNC symbol '(' function_arguments ')' '<' typename '>' '{' function_body '}' { $$ = NODE_ABCD(AM_S_FUNC, $2, $4, $7, $10); }
           | T_FUNC symbol '(' function_arguments ')' '{' function_body '}' { $$ = NODE_ABCD(AM_S_FUNC, $2, $4, NULL, $7); }
           ;

define_const: T_CONST T_VARIABLE '=' expression ';'          { $$ = NODE_AS(AM_S_CONST, $4, $2); }
            ;

define_alias: T_ALIAS T_IDENTIFIER typename ';'              { $$ = NODE_AS(AM_S_ALIAS, $3, $2); }
            ;

define_native: T_NATIVE T_IDENTIFIER '(' function_arguments ')' '<' typename '>' ';'  { $$ = NODE_ABS(AM_S_NATIVE, $4, $7, $2); }
             | T_NATIVE T_IDENTIFIER '(' function_arguments ')' ';'  { $$ = NODE_ABS(AM_S_NATIVE, $4, NULL, $2); }
             ;

struct_field: meta_tag_section typename T_VARIABLE ';'       { $$ =  NODE_ABS(AM_S_STRUCT_FIELD, $1, $2, $3); }
            ;

struct_field_list: struct_field_list struct_field            { $$ = NODE_AB(AM_S_STRUCT_FIELD_LIST, $1, $2); }
                 | struct_field                              { $$ = $1; }
                 ;

define_struct: T_STRUCT T_IDENTIFIER '{' struct_field_list '}' { $$ = NODE_AS(AM_S_STRUCT, $4, $2); }
             | T_STRUCT T_IDENTIFIER '{'  '}'                  { $$ = NODE_AS(AM_S_STRUCT, NULL, $2); }
             ;

iface_func: T_IDENTIFIER '(' function_arguments ')' '<' typename '>' ';' { $$ = NODE_ABS(AM_S_IFACE_FUNC, $3, $6, $1); }
          | T_IDENTIFIER '(' function_arguments ')' ';'                  { $$ = NODE_ABS(AM_S_IFACE_FUNC, $3, NULL, $1); }
          ;

iface_func_list: iface_func_list iface_func                            { $$ = NODE_AB(AM_S_FUNC_LIST, $1, $2); }
               | iface_func                                             { $$ = $1; }
               ;

iface_extends_list: symbol                                              { $$ = $1; }
                  | iface_extends_list ',' symbol                       { $$ = NODE_AB(AM_S_IFACE_EXTENDS_LIST, $1, $3); }
                  ;

iface_extends: ':' iface_extends_list                                   { $$ = $2; }
             | %empty                                                   { $$ = NULL; }
             ;

define_iface: T_IFACE T_IDENTIFIER iface_extends '{' iface_func_list '}'              { $$ = NODE_ABS(AM_S_IFACE, $5, $3, $2); }
            | T_IFACE T_IDENTIFIER iface_extends '{' '}'                              { $$ = NODE_ABS(AM_S_IFACE, NULL, $3, $2); }
            ;

meta_tag_values: meta_tag_values ',' expression_literal      { $$ = NODE_AB(AM_S_EXPRESSIONS, $1, $3); }
               | expression_literal                          { $$ = $1; }
               ;

meta_tag: '@' T_IDENTIFIER '(' meta_tag_values ')'           { $$ = NODE_AS(AM_S_META_TAG, $4, $2); }
        | '@' T_IDENTIFIER                                   { $$ = NODE_AS(AM_S_META_TAG, NULL, $2); }
        ;

meta_tag_list: meta_tag_list meta_tag                        { $$ = NODE_AB(AM_S_META_TAG_LIST, $1, $2); }
             | meta_tag                                      { $$ = $1; }
             ;

meta_tag_section: %empty                                     { $$ = NULL; }
                | meta_tag_list                              { $$ = $1; }
                ;

define_right_side: define_func                               { $$ = $1; }
                 | define_const                              { $$ = $1; }
                 | define_alias                              { $$ = $1; }
                 | define_native                             { $$ = $1; }
                 | define_struct                             { $$ = $1; }
                 | define_iface                              { $$ = $1; }
                 ;

block_define: meta_tag_section T_DEFINE define_right_side    { $$ = NODE_AB(AM_S_DEFINE, $1, $3); }
            ;

block_define_list: block_define_list block_define            { $$ = NODE_AB(AM_S_DEFINES, $1, $2); }
                 | block_define                              { $$ = $1; }
                 ;

block_definitions: %empty                                    { $$ = NULL; }
                 | block_define_list                         { $$ = $1; }
                 ;

program: block_require block_definitions                 { info->root = NODE_AB(AM_S_ROOT, $1, $2); }
       ;
%%

void yyerror(am_node_location_t *location, am_parser_t* parser, void *scanner,  const char *msg) {
    const char* template = "Error: '%s'. File: %s:%d";
    int line = (location->first_line == 0 ? location->last_line : location->first_line);
    size_t sz = snprintf(NULL, 0, template, msg, parser->filename, line);

    char* err = (char*)malloc(sz + 1);

    sprintf(err, template, msg, parser->filename, line);
    am_parser_set_error(parser, (const char*)err);
}

am_parser_t* am_parser_create_from_fd(const char* filename, FILE* fd) {
    am_parser_t* parser = (am_parser_t*)malloc(sizeof(am_parser_t));
    parser->fd = fd;
    parser->input = NULL;
    parser->root = NULL;
    parser->msg = NULL;
    parser->filename = filename;
    parser->buffer = NULL;

    // Initialize scanner
    lexer_initialize(parser);

    return parser;
}

am_parser_t* am_parser_create_from_str(const char* filename, const char* str) {
    am_parser_t* parser = (am_parser_t*)malloc(sizeof(am_parser_t));
    parser->fd = NULL;
    parser->input = str;
    parser->root = NULL;
    parser->msg = NULL;
    parser->filename = filename;
    parser->buffer = NULL;

    // Initialize scanner
    lexer_initialize(parser);

    return parser;
}

int am_parser_parse(am_parser_t* parser) {
    return yyparse(parser, parser->scanner);
}

am_node_t* am_parser_get_ast_root(am_parser_t* parser) {
    return parser->root;
}

void am_parser_destroy(am_parser_t* parser) {
    lexer_destroy(parser);
    ast_free(parser->root);
    free(parser);
}

const char* am_parser_get_error(am_parser_t* parser) {
    return parser->msg;
}

void am_parser_set_error(am_parser_t* parser, const char* message) {
    if (parser->msg != NULL) {
        free((void*)parser->msg);
    }

    parser->msg = message;
}

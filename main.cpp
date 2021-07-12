#include<iostream>
#include "mate.h"

int main(int argc, char** argv) {
    am_parser_t* parser = am_parser_create_from_fd("test.mate", stdin);
    am_parser_parse(parser);
    am_parser_destroy(parser);

    auto ast = am_parser_get_ast_root(parser);

    am_processor_t* proc = (am_processor_t*)calloc(1, sizeof(am_processor_t));

    am_parser_process_ast(parser, proc, NULL);

    auto err = am_parser_get_error(parser);

    std::cout <<  "end. Error message: " << (err != NULL ? err : "NULL" ) << std::endl;
    return 0;
}

#include<iostream>
#include "mate.h"

int main(int argc, char** argv) {
    am_parser_t* parser = am_parser_create_from_fd("test.mate", stdin);
    am_parser_parse(parser);
    am_parser_destroy(parser);
    auto err = am_parser_get_error(parser);

    std::cout <<  "end. Error message: " << (err != NULL ? err : "NULL" ) << std::endl;
    return 0;
}

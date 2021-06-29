#include<iostream>
#include "mate.h"

int main(int argc, char** argv) {
    am_parser_t* parser = am_parser_create_from_fd("test.mate", stdin);
    am_parser_parse(parser);
    am_parser_destroy(parser);

    std::cout <<  "end" << std::endl;
    return 0;
}

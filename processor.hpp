#ifndef LIBMATE_PROCESSOR_H
#define LIBMATE_PROCESSOR_H

extern "C" {
    void am_parser_set_error(am_parser_t* parser, const char* message);
}

#define ERROR(message) am_parser_set_error(parser, message);

bool pr_block_require(const am_node_t* node, am_parser_t* parser, const am_processor_t* proc, void* param);
bool pr_require_item_list(const am_node_t* node, am_parser_t* parser, const am_processor_t* proc, void* param);
bool pr_require_item(const am_node_t* node, am_parser_t* parser, const am_processor_t* proc, void* param);

#endif

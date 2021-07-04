#include <stdlib.h>
#include <string.h>
#include "lexer.h"

void strbuffer_clear(char** buffer) {
    if (*buffer != NULL) {
        (*buffer)[0] = '\0';
    } else {
        *buffer = (char*)malloc(sizeof(char));
        (*buffer)[0] = '\0';
    }
}

void strbuffer_concat(char** buffer, char* str) {
    const size_t str_len = strlen(str);
    const size_t buffer_len = strlen(*buffer);

    *buffer = (char*)realloc(*buffer, (str_len + buffer_len + 1) * sizeof(char));
    strcat(*buffer, str);
}

void strbuffer_put(char** buffer, char c) {
    const size_t buffer_len = strlen(*buffer);

    *buffer = (char*)realloc(*buffer, (buffer_len + 2) * sizeof(char));
    (*buffer)[buffer_len] = c;
    (*buffer)[buffer_len + 1] = '\0';
}

const char* strbuffer_copy(char* buffer) {
    const size_t buffer_len = strlen(buffer);

    char* buf2 = (char*)malloc(sizeof(char) * (buffer_len + 1));

    strcpy(buf2, buffer);

    return (const char*)buf2;
}

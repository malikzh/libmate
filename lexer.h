#ifndef LIBMATE_LEXER_H
#define LIBMATE_LEXER_H

void strbuffer_clear(char** buffer);
void strbuffer_concat(char** buffer, char* str);
void strbuffer_put(char** buffer, char str);
const char* strbuffer_copy(char* buffer);

#endif

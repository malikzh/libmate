cmake_minimum_required(VERSION 3.17.0)
project(automate VERSION 0.1.0)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++20")
set(CMAKE_C_STANDARD 11)

set(LIBMATE_SRC parser.c parser.h lexer.c)
set(LIBMATE_TESTS main.cpp)

add_library(mate STATIC ${LIBMATE_SRC})
add_executable(mate-test ${LIBMATE_TESTS})
target_link_libraries(mate-test mate)

cmake_minimum_required(VERSION 3.17.0)
project(libmate)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++20")
set(CMAKE_C_STANDARD 11)

set(LIBMATE_SRC lexer.h strbuffer.c ast.c ast.h)
set(LIBMATE_TESTS main.cpp)

if (CI_MODE EQUAL 1)
    set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/.github/cmake-modules)
endif()

find_package(bison REQUIRED)
find_package(flex REQUIRED)

# Bison fix for Mac OS
if (CMAKE_HOST_SYSTEM_NAME MATCHES "Darwin")
    execute_process(
        COMMAND brew --prefix bison 
        RESULT_VARIABLE BREW_BISON
        OUTPUT_VARIABLE BREW_BISON_PREFIX
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if (BREW_BISON EQUAL 0 AND EXISTS "${BREW_BISON_PREFIX}")
        message(STATUS "Found Bison keg installed by Homebrew at ${BREW_BISON_PREFIX}")
        set(BISON_EXECUTABLE "${BREW_BISON_PREFIX}/bin/bison")
    endif()

    execute_process(
        COMMAND brew --prefix flex 
        RESULT_VARIABLE BREW_FLEX
        OUTPUT_VARIABLE BREW_FLEX_PREFIX
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    if (BREW_FLEX EQUAL 0 AND EXISTS "${BREW_FLEX_PREFIX}")
        message(STATUS "Found Flex keg installed by Homebrew at ${BREW_FLEX_PREFIX}")
        set(FLEX_EXECUTABLE "${BREW_FLEX_PREFIX}/bin/flex")
    endif()
endif()

bison_target(MATEPARSER parser.y ${CMAKE_CURRENT_BINARY_DIR}/parser.c)
flex_target(MATELEXER lexer.l ${CMAKE_CURRENT_BINARY_DIR}/lexer.c)

add_library(mate STATIC ${LIBMATE_SRC} ${BISON_MATEPARSER_OUTPUTS} ${FLEX_MATELEXER_OUTPUTS})
add_executable(mate-test ${LIBMATE_TESTS})
target_link_libraries(mate-test mate)

if(CMAKE_BUILD_TYPE MATCHES Release)
    message("INFO: Build mode is RELEASE")
else()
    message("INFO: Build mode is DEBUG")
    target_compile_definitions(mate PRIVATE AM_DEBUG)
endif()

install(TARGETS mate DESTINATION lib)
install(FILES mate.h DESTINATION include)
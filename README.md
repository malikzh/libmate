# LIBMATE

MATE programming language AST construction library

## Dependencies

- [GNU Bison](https://www.gnu.org/software/bison/) v3.7+
- [Flex](https://github.com/westes/flex) v2.5+
- [CMake](https://cmake.org/) 3.17

## Build

```bash
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make
make install
```

> If you need debug build type, set 
> `CMAKE_BUILD_TYPE=Debug`

## Usage

```c++
#include<iostream>
#include "mate.h"

int main(int argc, char** argv) {
    am_parser_t* parser = am_parser_create_from_fd("test.mate", stdin);
    am_parser_parse(parser);
    am_parser_destroy(parser);
    auto err = am_parser_get_error(parser);

    // AST root node
    am_node_t* root_node = am_parser_get_ast_root(parser);

    std::cout << (err != NULL ? err : "NULL" ) << std::endl;
    return 0;
}
```

## Documentation

todo

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## Authors

- [@malikzh](https://github.com/malikzh) &lt;Malik Zharykov&gt;

## License

[MIT](./LICENSE)
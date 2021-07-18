<div style="text-align: center; font-size: 64px;">🤖</div>

<p style="text-align: center;font-weight: bold;font-size: 48px;">libMATE</p>


<p style="text-align: center;">
    MATE programming language <a href="https://en.wikipedia.org/wiki/Abstract_syntax_tree">AST</a> construction library
</p>


---

<div style="text-align: center; padding-top: 10px;">
    <img src="https://github.com/empla/libmate/actions/workflows/cmake.yml/badge.svg" alt="CI Build status">
    <img alt="GitHub code size in bytes" src="https://img.shields.io/github/languages/code-size/empla/libmate?style=plastic">
    <img alt="GitHub tag (latest SemVer)" src="https://img.shields.io/github/v/tag/empla/libmate?label=version">
</div>

---

<div style="height: 30px;">&nbsp;</div>

## 🧩 Dependencies

- [GNU Bison](https://www.gnu.org/software/bison/) v3.7+
- [Flex](https://github.com/westes/flex) v2.5+
- [CMake](https://cmake.org/) 3.17

## 🛠 Build

```bash
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make
make install
```

> If you need debug build type, set 
> `CMAKE_BUILD_TYPE=Debug`

## 📌 Usage

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

## 📖 Documentation

todo

## 🤝 Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## 📝 Authors

- [@malikzh](https://github.com/malikzh) &lt;Malik Zharykov&gt;

## 📄 License

[MIT](./LICENSE)

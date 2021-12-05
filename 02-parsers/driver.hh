#pragma once

#include <map>
#include <string>
#include <fstream>
#include <variant>
#include "scanner.h"
#include "parser.hh"

#include "runnable.h"


class Driver {
public:
    Driver();
    std::map<std::string, std::variant<int, std::string>> variables;
    int result;
    int parse(const std::string& f);
    std::string file;


    void scan_begin();
    void scan_end();

    bool trace_parsing;
    bool trace_scanning;
    yy::location location;

    friend class Scanner;
    Scanner scanner;
    yy::parser parser;
    bool location_debug;

    int run_program();
    void set_executable(std::shared_ptr<Runnable>);

private:
    std::ifstream stream;
    std::shared_ptr<Runnable> program;
};

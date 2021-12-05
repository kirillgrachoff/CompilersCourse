#include <utility>

#include "driver.hh"
#include "parser.hh"



Driver::Driver() :
    trace_parsing(false),
    trace_scanning(false),
    location_debug(false),
    scanner(*this), parser(scanner, *this) {
}


int Driver::parse(const std::string& f) {
    file = f;
    // initialize location positions
    location.initialize(&file);
    scan_begin();
    parser.set_debug_level(trace_parsing);
    int res = parser();
    scan_end();
    return res;
}

void Driver::scan_begin() {
    scanner.set_debug(trace_scanning);
  if (file.empty () || file == "-") {
  } else {
    stream.open(file);
    std::cerr << "File name is " << file << std::endl;

    // Restart scanner resetting buffer!
    scanner.yyrestart(&stream);
  }
}

void Driver::scan_end()
{
    stream.close();
}

int Driver::run_program() {
    int res;
    try {
        res = program->run();
        if (res != 0) return res;
    } catch (std::exception& ex) {
        std::cerr << ex.what() << '\n';
        throw;
    }
    return res;
}

void Driver::set_executable(std::shared_ptr<Runnable> exe) {
    program = std::move(exe);
}


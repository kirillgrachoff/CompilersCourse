#include <iostream>
#include <driver.hh>

int main(int argc, char** argv) {
    int result = 0;
    Driver driver;

    for (int i = 1; i < argc; ++i) {
        if (argv[i] == std::string("-p")) {
            driver.trace_parsing = true;
        } else if (argv[i] == std::string("-s")) {
            driver.trace_scanning = true;
        } else if (argv[i] == std::string("-l")) {
            driver.location_debug = true;
        } else if (!driver.parse(argv[i])) {
            result = driver.result;
        } else {
            result = 1;
        }
    }
    if (result == 0) {
        result = driver.run_program();
        std::cout << "Process finished with exit code " << result << std::endl;
    }

    return result;
}
#include "runnable.h"

int RunnableFor::run() {
    int err;
    if (init) {
        err = init->run();
        if (err != 0) return err;
    }
    while (std::get<int>(condition->get())) {

        err = body->run();
        if (err != 0) return err;

        if (increment) {
            err = increment->run();
            if (err != 0) return err;
        }
    }
    return 0;
}

int RunnableIf::run() {
    int err;
    if (init) {
        err = init->run();
        if (err != 0) return err;
    }
    if (std::get<int>(condition->get())) {
        err = body->run();
        if (err != 0) return err;
    } else {
        if (else_body) {
            err = else_body->run();
            if (err != 0) return err;
        }
    }
    return 0;
}
int RunnableAssign::run() {
    driver_.variables[name] = value->get();
    return 0;
}
int RunnablePrint::run() {
    auto arg = value->get();
    std::cout << "Output: ";
    if (std::holds_alternative<int>(arg)) {
        std::cout << std::get<int>(arg) << std::endl;
    } else {
        std::cout << std::get<std::string>(arg) << std::endl;
    }
    return 0;
}
int RunnableEmpty::run() {
    return 0;
}
int RunnableSeq::run() {
    int err;
    err = a->run();
    if (err != 0) return err;
    err = b->run();
    if (err != 0) return err;
    return 0;
}

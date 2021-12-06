#include "expression.h"

Variable::Variable(const std::string& name, Driver& driver) : name(name), driver_(driver) {}

std::variant<int, std::string> Variable::get() {
    return driver_.variables[name];
}

void Variable::set(const std::variant<int, std::string>& value) {
    driver_.variables[name] = value;
}

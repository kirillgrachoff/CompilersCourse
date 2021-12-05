#pragma once

#include <variant>
#include <memory>
#include <iostream>
#include "driver.hh"

template <typename Function>
class ExpressionInt;
template <typename Function>
class ExpressionString;
template <typename Function>
class ExpressionBoth;

class Expression {
public:
    virtual std::variant<int, std::string> get() = 0;
    virtual ~Expression() = default;
};

template <typename T>
class Value : public Expression {
private:
    const T value;

public:
    Value(const T& value) : value(value) {
        static_assert(std::is_same_v<T, std::string> || std::is_same_v<T, int>);
    }

    std::variant<int, std::string> get() override {
        return {value};
    }

    ~Value() override = default;
};

class Variable : public Expression {
    const std::string name;
    Driver& driver_;

public:
    Variable(const std::string& name, Driver& driver);

    std::variant<int, std::string> get() override;

    void set(const std::variant<int, std::string>& value);

    ~Variable() = default;
};

template <typename Function>
class ExpressionBoth : public Expression {
private:
    std::shared_ptr<Expression> a;
    std::shared_ptr<Expression> b;
    Function func;

public:
    ExpressionBoth(std::shared_ptr<Expression> a, std::shared_ptr<Expression> b, Function func)
            : a(a), b(b), func(func) {}

    std::variant<int, std::string> get() override {
        auto a_value = a->get();
        auto b_value = b->get();
        if (std::holds_alternative<int>(a_value)) {
            return {func(std::get<int>(a_value), std::get<int>(b_value))};
        } else if (std::holds_alternative<std::string>(a_value)) {
            return {func(std::get<std::string>(a_value), std::get<std::string>(b_value))};
        }
        throw std::runtime_error("variant contains nothing");
    }
};

template <typename HeldType, typename Function>
class ExpressionOne : public Expression {
private:
    std::shared_ptr<Expression> a;
    std::shared_ptr<Expression> b;
    Function func;

public:
    ExpressionOne(std::shared_ptr<Expression> a, std::shared_ptr<Expression> b, Function func)
            : a(a), b(b), func(func) {}

    std::variant<int, std::string> get() override {
        auto a_value = a->get();
        auto b_value = b->get();
        return {func(std::get<HeldType>(a_value), std::get<HeldType>(b_value))};
    }
};

template <typename Function>
class ExpressionInt : public ExpressionOne<int, Function> {
public:
    using ExpressionOne<int, Function>::ExpressionOne;
};

template <typename Function>
class ExpressionString : public ExpressionOne<std::string, Function> {
public:
    using ExpressionOne<std::string, Function>::ExpressionOne;
};

template <template <typename> typename UnderlyingClass, typename Function>
std::shared_ptr<Expression> new_expression(std::shared_ptr<Expression> a, std::shared_ptr<Expression> b, Function func) {
    return std::make_shared<UnderlyingClass<Function>>(a, b, func);
}

template <typename T>
std::shared_ptr<Expression> new_value(const T& value) {
    return std::make_shared<Value<T>>(value);
}

template <typename Function>
class UnaryExpressionBoth : public Expression {
private:
    std::shared_ptr<Expression> a;
    Function func;

public:
    UnaryExpressionBoth(std::shared_ptr<Expression> a, Function func)
            : a(a), func(func) {}

    std::variant<int, std::string> get() override {
        auto a_value = a->get();
        if (std::holds_alternative<int>(a_value)) {
            return {func(std::get<int>(a_value))};
        } else if (std::holds_alternative<std::string>(a_value)) {
            return {func(std::get<std::string>(a_value))};
        }
    }
};

template <typename Function>
class UnaryExpressionInt : public Expression {
private:
    std::shared_ptr<Expression> a;
    Function func;

public:
    UnaryExpressionInt(std::shared_ptr<Expression> a, Function func)
            : a(a), func(func) {}

    std::variant<int, std::string> get() override {
        auto a_value = a->get();
        return {func(std::get<int>(a_value))};
    }
};

template <typename Function>
class UnaryExpressionString : public Expression {
private:
    std::shared_ptr<Expression> a;
    Function func;

public:
    UnaryExpressionString(std::shared_ptr<Expression> a, Function func)
            : a(a), func(func) {}

    std::variant<int, std::string> get() override {
        auto a_value = a->get();
        return {func(std::get<std::string>(a_value))};
    }
};

template <template <typename> typename UnderlyingClass, typename Function>
std::shared_ptr<Expression> new_expression(std::shared_ptr<Expression> a, Function func) {
    return std::make_shared<UnderlyingClass<Function>>(a, func);
}

#pragma once

#include <expression.h>

class Runnable {
public:
    Runnable() = default;
    virtual int run() = 0;
    virtual ~Runnable() = default;
};

class RunnableFor : public Runnable {
private:
    std::shared_ptr<Runnable> init;
    std::shared_ptr<Expression> condition;
    std::shared_ptr<Runnable> increment;
    std::shared_ptr<Runnable> body;

public:
    RunnableFor(std::shared_ptr<Runnable> init, std::shared_ptr<Expression> condition, std::shared_ptr<Runnable> increment, std::shared_ptr<Runnable> body)
            : init(init), condition(condition), increment(increment), body(body) {}
    int run() override;
};

class RunnableIf : public Runnable {
    std::shared_ptr<Runnable> init;
    std::shared_ptr<Expression> condition;
    std::shared_ptr<Runnable> body;
    std::shared_ptr<Runnable> else_body;

public:
    RunnableIf(std::shared_ptr<Runnable> init, std::shared_ptr<Expression> condition, std::shared_ptr<Runnable> body, std::shared_ptr<Runnable> else_body)
            : init(init), condition(condition), body(body), else_body(else_body) {}
    int run() override;
};

class RunnableAssign : public Runnable {
    std::string name;
    std::shared_ptr<Expression> value;
    Driver& driver_;

public:
    RunnableAssign(const std::string& name, std::shared_ptr<Expression> value, Driver& driver)
            : name(name), value(value), driver_(driver) {}
    int run() override;
};

class RunnablePrint : public Runnable {
private:
    std::shared_ptr<Expression> value;
public:
    RunnablePrint(std::shared_ptr<Expression> value)
            : value(value) {}
    int run() override;
};

class RunnableEmpty : public Runnable {
public:
    int run() override;
};

class RunnableSeq : public Runnable {
private:
    std::shared_ptr<Runnable> a;
    std::shared_ptr<Runnable> b;
public:
    RunnableSeq(std::shared_ptr<Runnable> a, std::shared_ptr<Runnable> b)
            : a(a), b(b) {}
    int run() override;
};

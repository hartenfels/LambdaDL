unit module LambdaDL::Context;


class Context is export {
    has Str $.orig is required;
    has Int $.from is required;
    has Int $.to   is required;

    method new($/) {
        return self.bless(:orig($/.orig), :from($/.from), :to($/.to));
    }

    method   line() { $.orig.substr(0, $.from + 1).lines.elems }
    method before() { $.orig.substr(0, $.from).lines[*-1] // '' }
    method  after() { $.orig.substr(   $.from).lines[ 0 ] // '' }
}


class X::LambdaDL is Exception {
    has Str     $.msg;
    has Context $.ctx;

    method message() { $.msg }
}


class X::LambdaDL::Parse  is X::LambdaDL        is export {}

class X::LambdaDL::Syntax is X::LambdaDL::Parse is export {
    has Str $.rule is required;

    method message() { "Syntax error: $.msg" }
}


class X::LambdaDL::NoDataSource is X::LambdaDL is export {
    method message() { "Can't query knowledge base without a data source" }
}


class X::LambdaDL::UnknownIdentifier is X::LambdaDL is export {
    method message() { "Unknown identifier '$.msg'" }
}


class X::LambdaDL::T is X::LambdaDL is export {
    has @.types;

    method new($ctx, @types) { self.bless(:$ctx, :@types) }

    method message() { sprintf self.fmt, |@.types }
}


class X::LambdaDL::TUnite is X::LambdaDL::T is export {
    method fmt() { "can't unite types:\n - %s\n - %s" }
}

class X::LambdaDL::TIntersect is X::LambdaDL::T is export {
    method fmt() { "can't intersect types:\n - %s\n - %s" }
}

class X::LambdaDL::TConsTail is X::LambdaDL::T is export {
    method fmt() { "cons tail needs to be a list, but is %s" }
}

class X::LambdaDL::TCons is X::LambdaDL::T is export {
    method fmt() { "can't cons a %s onto a %s" }
}

class X::LambdaDL::THead is X::LambdaDL::T is export {
    method fmt() { "can't chop the head off of a %s" }
}

class X::LambdaDL::TTail is X::LambdaDL::T is export {
    method fmt() { "can't chop the tail off of a %s" }
}

class X::LambdaDL::TMapFunc is X::LambdaDL::T is export {
    method fmt() { "can't use a %s as map's function" }
}

class X::LambdaDL::TMapList is X::LambdaDL::T is export {
    method fmt() { "can't use a %s as map's list" }
}

class X::LambdaDL::TMap is X::LambdaDL::T is export {
    method fmt() { "can't use a %s to map over a %s" }
}

class X::LambdaDL::TCall is X::LambdaDL::T is export {
    method fmt() { "can't call a %s" }
}

class X::LambdaDL::TArg is X::LambdaDL::T is export {
    method fmt() { "function takes %s, but got %s" }
}

class X::LambdaDL::TEquiv is X::LambdaDL::T is export {
    method fmt() { "can't equivalate a %s with a %s" }
}

class X::LambdaDL::TCond is X::LambdaDL::T is export {
    method fmt() { "if condition needs to be %s, but got %s" }
}

class X::LambdaDL::TFix is X::LambdaDL::T is export {
    method fmt() { "can't fix a %s" }
}

class X::LambdaDL::TQuery is X::LambdaDL::T is export {
    method fmt() { "query %s is unsatisfiable" }
}

class X::LambdaDL::TProjection is X::LambdaDL::T is export {
    method fmt() { "can't project on a %s" }
}

class X::LambdaDL::TSwitch is X::LambdaDL::T is export {
    method fmt() { "case topic %s isn't a semantic type" }
}

class X::LambdaDL::TCase is X::LambdaDL::T is export {
    method fmt() { "matching %s against %s will never work" }
}

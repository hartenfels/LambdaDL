unit module LambdaDL::TypeCheck;
use LambdaDL::AST;
use LambdaDL::Context;
use LambdaDL::DL;


sub xi(Context() $ctx, Str:D $msg) {
    die X::LambdaDL::UnknownIdentifier.new(:$msg, :$ctx);
}

sub xt(Context() $ctx, $cls, *@types) {
    die X::LambdaDL::{"T$cls"}.new($ctx, @types);
}


class Type {
    method Str() { $.id }

    method unifies-with($other) {
        return $other ~~ self.WHAT && self.unify($other) ?? self !! Type;
    }

    method check($other, $ctx, $fmt) {
        return self.unifies-with($other) || xt $ctx, $fmt, self, $other;
    }

    method check-list   ($ctx, $fmt) { xt $ctx, $fmt, self }
    method check-func   ($ctx, $fmt) { xt $ctx, $fmt, self }
    method check-concept($ctx, $fmt) { xt $ctx, $fmt, self }
}

class Type::Unknown is Type {
    method id() { '(unknown)' }

    method unify($) { False }
}

class Type::Primitive is Type {
    has Str:D $.id is required;

    method unify($other) { $.id eq $other.id }
}

class Type::List is Type {
    has Type:D $.of is required;

    method id() { $.of ~ '[]' }

    method unify($other) { $.of.unifies-with($other.of) }

    method check-list($, $) { self }
}

class Type::Func is Type {
    has Type:D $.arg is required;
    has Type:D $.ret is required;

    method id() { "($.arg → $.ret)" }

    method unify($other) {
        return $.arg.unifies-with($other.arg) && $.ret.unifies-with($other.ret);
    }

    method check-func($, $) { self }
}

class Type::Concept is Type {
    has $.of is required;

    method id() { "$.of" }

    method unify($other) { $.of.comparable($other.of) }

    method check-concept($, $) { self }

    method check-sat($ctx, $fmt) {
        xt $ctx, $fmt, self unless $.of.satisfiable;
        return self;
    }
}


constant \unknown-type = Type::Unknown.new;
constant \bool-type    = Type::Primitive.new(:id( 'bool' ));
constant \string-type  = Type::Primitive.new(:id('string'));

sub func-type($arg, $ret) { Type::Func.new(:$arg, :$ret) }

sub list-type($of) { Type::List.new(:$of) }

sub concept-type($of) { Type::Concept.new(:$of) }


class Scope {
    has $.ast;
    has $.sym;

    method new($ast, $sym = Map.new) { self.bless(:$ast, :$sym) }

    method subscope($name, $type) {
        return Scope.new($.ast, Map.new: $.sym.flat, $name => $type);
    }

    method kb() { self.ast.kb }


    multi method t([PrimitiveType, 'bool'  ]) {   bool-type }
    multi method t([PrimitiveType, 'string']) { string-type }

    multi method t([ListType, $type]) { list-type self.t($type) }

    multi method t([FuncType, $lhs, $rhs]) {
        my $lhs-type = self.t($lhs);
        my $rhs-type = self.t($rhs);
        return func-type $lhs-type, $rhs-type;
    }

    multi method t([ConceptType, $concept]) { concept-type dl($.kb, $concept) }

    multi method t([Primitive, Bool $]) { bool-type   }
    multi method t([Primitive, Str  $]) { string-type }

    multi method t([Nil, $type]) { list-type self.t($type) }

    multi method t([Cons $ctx, $head, $tail]) {
        my $head-type = self.t($head);
        my $tail-type = self.t($tail).check-list($ctx, 'ConsTail');
        return $tail-type.unifies-with(list-type $head-type)
            || xt $ctx, 'Cons', $head-type, $tail-type;
    }

    multi method t([Head $ctx, $list]) {
        return self.t($list).check-list($ctx, 'Head').of;
    }

    multi method t([Tail $ctx, $list]) {
        return self.t($list).check-list($ctx, 'Tail');
    }

    multi method t([MapIn $ctx, $func, $list]) {
        my $func-type = self.t($func).check-func($ctx, 'MapFunc');
        my $list-type = self.t($list).check-list($ctx, 'MapList');
        if $func-type.arg.unifies-with($list-type.of) {
            return $func-type.ret;
        }
        else {
            xt $ctx, 'Map', $func-type, $list-type;
        }
    }

    multi method t([Application $ctx, $func, $arg]) {
        my $func-type = self.t($func).check-func($ctx, 'Call');
        $func-type.arg.check(self.t($arg), $ctx, 'Arg');
        return $func-type.ret;
    }

    multi method t([Equiv $ctx, $lhs, $rhs]) {
        self.t($lhs).check(self.t($rhs), $ctx, 'Equiv');
        return bool-type;
    }

    multi method t([Identifier $ctx, $name]) {
        return $.sym{$name} || xi $ctx, $name;
    }

    multi method t([Let, [Identifier, $name], $value, $in]) {
        my $type  = self.t($value);
        my $inner = self.subscope($name, $type);
        return $inner.t($in);
    }

    multi method t([Lambda, [Identifier, $name], $arg, $term]) {
        my $arg-type = self.t($arg);
        my $inner    = self.subscope($name, $arg-type);
        return func-type $arg-type, $inner.t($term);
    }

    multi method t([If $ctx, $cond, $then, $else]) {
        bool-type.check(self.t($cond), $ctx, 'Cond');
        return self.t($then).check(self.t($else), $ctx, 'Branch');
    }

    multi method t([Fix $ctx, $term]) {
        return self.t($term).check-func($ctx, 'Fix').ret;
    }

    multi method t([Query $ctx, $concept]) {
        my $type = concept-type(dl($.kb, $concept)).check-sat($ctx, 'Query');
        return list-type $type;
    }

    multi method t([Projection $ctx, $term, $role]) {
        my $concept = self.t($term).check-concept($ctx, 'Projection');
        my $proj    = dl-r($.kb, [Inverse, $role]).exists($concept.of);
        return list-type concept-type $proj;
    }


    method check() { self.t($.ast.term) }
}


sub check-type($ast) is export { Scope.new($ast).check }

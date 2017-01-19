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

    method unify($) { True }

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

class Type::Bool   is Type { method id() { 'bool'   } }
class Type::String is Type { method id() { 'string' } }

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

    method unify($other) { $.of.subtype($other.of) }

    method check-concept($, $) { self }

    method check-sat($ctx, $fmt) {
        xt $ctx, $fmt, self unless $.of.satisfiable;
        return self;
    }
}


constant \bool-type    = Type::Bool.new;
constant \string-type  = Type::String.new;

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


    multi method unite($, Type::Bool   $, Type::Bool   $) { bool-type   }
    multi method unite($, Type::String $, Type::String $) { string-type }

    multi method unite($ctx, Type::List $a, Type::List $b) {
        return list-type self.unite($ctx, $a.of, $b.of);
    }

    multi method unite($, Type::Concept $a, Type::Concept $b) {
        return concept-type $a.of.union($b.of);
    }

    multi method unite($ctx, Type::Func $a, Type::Func $b) {
        return func-type self.intersect($ctx, $a.arg, $b.arg),
                         self.unite(    $ctx, $a.ret, $b.ret);
    }

    multi method unite($ctx, $a, $b) { xt $ctx, 'Unite', $a, $b }


    multi method intersect($, Type::Bool   $, Type::Bool   $) { bool-type   }
    multi method intersect($, Type::String $, Type::String $) { string-type }

    multi method intersect($ctx, Type::List $a, Type::List $b) {
        return list-type self.intersect($a.of, $b.of);
    }

    multi method unite($ctx, Type::Func $a, Type::Func $b) {
        return func-type self.unite(    $ctx, $a.arg, $b.arg),
                         self.intersect($ctx, $a.ret, $b.ret);
    }

    multi method intersect($, Type::Concept $a, Type::Concept $b) {
        return concept-type $a.of.intersect($b.of);
    }

    multi method intersect($ctx, $a, $b) { xt $ctx, 'Intersect', $a, $b }


    method join-types($ctx, *@types) {
        return reduce { self.unite($ctx, $^a, $^b) }, @types;
    }


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

    multi method t([Null $ctx, $term]) {
        self.t($term).check-list($ctx, 'Null');
        return bool-type;
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
        return self.join-types($ctx, self.t($then), self.t($else));
    }

    multi method t([Fix $ctx, $term]) {
        return self.t($term).check-func($ctx, 'Fix').ret;
    }

    multi method t([Obj, [Atom, $iri]]) {
        return concept-type $.kb.concept($iri);
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

    multi method t([Switch $ctx, $topic, $default, *@cases]) {
        my $topic-type = self.t($topic).check-concept($ctx, 'Topic');

        my &case = sub ([Case $ctx, $concept, [Identifier, $name], $term]) {
            my $case-type = concept-type dl($.kb, $concept);

            xt $ctx, 'Case', $case-type, $topic-type
                unless $case-type.unifies-with($topic-type);

            my $inner = self.subscope($name, $case-type);
            return $inner.t($term);
        };

        return self.join-types($ctx, |map(&case, @cases), self.t($default));
    }


    method check() { self.t($.ast.term) }
}


sub check-type($ast) is export { Scope.new($ast).check }

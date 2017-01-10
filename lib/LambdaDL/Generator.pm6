unit class LambdaDL::Generator;
use LambdaDL::AST;


constant \preamble := q:to/END_OF_PREAMBLE/;
    my $head = sub head($list) {
        return $list[0] if $list.elems;
        die "can't chop the head off of an empty list";
    };

    my $tail = sub tail($list) {
        return [|$list[1..*]] if $list.elems;
        die "can't chop the tail off of an empty list";
    };

    my $fix = sub fix($f) {
        return (-> $x { $x.($x) }).(-> $y { $f.(-> $x { $y.($y).($x) }) });
    };
    END_OF_PREAMBLE


has $.ast;


multi method gen($_: [Primitive, Bool $b]) { $b ?? 'True' !! 'False' }
multi method gen($_: [Primitive, Str  $s]) { qq/"$s"/  }

multi method gen($_: [Identifier, $name]) { "$name" }

multi method gen($_: [Nil, $]) { '[]' }

multi method gen($_: [Cons, $head, $tail]) {
    "[{.gen: $head}, |{.gen: $tail}]"
}

multi method gen($_: [Head, $list]) {
    "\$head.({.gen: $list})"
}

multi method gen($_: [Tail, $list]) {
    "\$tail.({.gen: $list})"
}

multi method gen($_: [Application, $func, $arg]) {
    "({.gen: $func}).({.gen: $arg})"
}

multi method gen($_: [Equiv, $lhs, $rhs]) {
    "({.gen: $lhs} eqv {.gen: $rhs})"
}

multi method gen($_: [Let, $ident, $value, $in]) {
    "do \{ my \\{.gen: $ident} := do \{ {.gen: $value} }; {.gen: $in} \}"
}

multi method gen($_: [Lambda, $ident, $, $term]) {
    "-> \\{.gen: $ident} \{ {.gen: $term} }"
}

multi method gen($_: [If, $cond, $then, $else]) {
    "({.gen: $cond} ?? {.gen: $then} !! {.gen: $else})"
}

multi method gen($_: [Fix, $term]) {
    "\$fix.({.gen: $term})"
}


method generate() { "{preamble}\n{self.gen($.ast.term)}\n" }

sub generate($ast) is export {
    return LambdaDL::Generator.new(:$ast).generate;
}

unit module LambdaDL::Generator;
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


multi sub gen([Primitive, Bool $b]) { $b ?? 'True' !! 'False' }
multi sub gen([Primitive, Str  $s]) { qq/"$s"/  }

multi sub gen([Identifier, $name]) { "$name" }

multi sub gen([Nil, $]) { '[]' }

multi sub gen([Cons, $head, $tail]) {
    "[{gen $head}, |{gen $tail}]"
}

multi sub gen([Head, $list]) {
    "\$head.({gen $list})"
}

multi sub gen([Tail, $list]) {
    "\$tail.({gen $list})"
}

multi sub gen([Application, $func, $arg]) {
    "({gen $func}).({gen $arg})"
}

multi sub gen([Equiv, $lhs, $rhs]) {
    "({gen $lhs} eqv {gen $rhs})"
}

multi sub gen([Let, $ident, $value, $in]) {
    "do \{ my \\{gen $ident} := do \{ {gen $value} }; {gen $in} \}"
}

multi sub gen([Lambda, $ident, $, $term]) {
    "-> \\{gen $ident} \{ {gen $term} }"
}

multi sub gen([If, $cond, $then, $else]) {
    "({gen $cond} ?? {gen $then} !! {gen $else})"
}

multi sub gen([Fix, $term]) {
    "\$fix.({gen $term})"
}


sub generate($ast) is export {
    return "{preamble}\n{gen($ast)}\n";
}

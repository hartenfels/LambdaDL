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


method gen-kb() {
    my $body;

    with $.ast.path {
        $body = qq:to/END_OF_KB/;
            state \$base = LambdaDL::KnowledgeBase.new(｢{.IO.absolute}｣);
            return \$base;
        END_OF_KB
    }
    else {
        $body = q:to/END_OF_KB/;
            die "Can't query knowledge base without a data source";
        END_OF_KB
    }

    return "my \$kb = sub kb() \{\n$body};\n";
}


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

multi method gen($_: [Null, $list]) {
    "!{.gen: $list}"
}

multi method gen($_: [MapIn, $func, $list]) {
    "[{.gen($list)}.map({.gen: $func})]"
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

multi method gen($_: [[Atom,    $iri ]]) { "\$kb().atom(｢$iri｣)"  }
multi method gen($_: [[Inverse, $atom]]) { "{.gen: [$atom]}.invert" }

multi method gen($_: [Atom, $iri]) { "\$kb().concept(｢$iri｣)" }

multi method gen($_: [Everything]) { '$kb().everything()' }
multi method gen($_: [Nothing   ]) { '$kb().nothing()'    }

multi method gen($_: [Not, $concept]) { "{.gen: $concept}.not" }

multi method gen($_: [Intersect, $a, $b]) { "{.gen: $a}.intersect({.gen: $b})" }
multi method gen($_: [Union,     $a, $b]) { "{.gen: $a}.union({    .gen: $b})" }

multi method gen($_: [Exists, $r, $c]) { "{.gen: [$r]}.exists({ .gen: $c})" }
multi method gen($_: [ForAll, $r, $c]) { "{.gen: [$r]}.for-all({.gen: $c})" }

multi method gen($_: [Query, $dl]) { "{.gen: $dl}.query" }

multi method gen($_: [Projection, $term, $role]) {
    "{.gen: $term}.project({.gen: [$role]})"
}


method generate() {
    return qq:to/END_OF_CODE/;
        {preamble}
        {self.gen-kb}
        {self.gen($.ast.term)}
        END_OF_CODE
}

sub generate($ast) is export {
    return LambdaDL::Generator.new(:$ast).generate;
}

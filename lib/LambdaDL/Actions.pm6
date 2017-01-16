unit class LambdaDL::Actions;
use LambdaDL::AST;


sub left-right($/) {
    if $<rhs> {
        my ($type, $rhs) = |$<rhs>.made;
        return ast $/, $type, $<lhs>, $rhs;
    }
    else {
        return $<lhs>.made;
    }
}


method TOP($/) {
    make LambdaDL::AST.new(:term($<term>.made), :path($<kb>.?made));
}


method kb($/) { make $<path>.made }

method path($/) { make $/.Str.trim }


method term($/) {
    if $<terms>.elems == 1 {
        make $<terms>[0].made;
    }
    else {
        make reduce { ast $/, Application, $^a, $^b }, |$<terms>».made;
    }
}


method in-term($/) { make left-right $/ }


method term-lhs:sym<paren>($/) { make $<term>.made }

method term-lhs:sym<let>($/) { make ast $/, Let, $<ident>, $<spec>, $<in> }
method term-lhs:sym<fix>($/) { make ast $/, Fix, $<term> }

method term-lhs:sym<letrec>($/) {
    my $inner = ast $/, Fix, ast $/, Lambda, $<ident>, $<type>, $<spec>;
    make ast $/, Let, $<ident>, $inner, $<in>;
}

method term-lhs:sym<if>($/) { make ast $/, If, $<if>, $<then>, $<else> }

method term-lhs:sym<cons>($/) { make ast $/, Cons, $<head>, $<tail> }
method term-lhs:sym<null>($/) { make ast $/, Null, $<term>          }
method term-lhs:sym<head>($/) { make ast $/, Head, $<term>          }
method term-lhs:sym<tail>($/) { make ast $/, Tail, $<term>          }

method term-lhs:sym<map>($/) { make ast $/, MapIn, $<func>, $<list> }

method term-lhs:sym<query>($/) { make ast $/, Query, $<concept> }

method term-lhs:sym<identifier>($/) { make $<ident>.made }

method term-lhs:sym<value>($/) { make $<value>.made }

method term-lhs:sym<case>($/) {
    make ast $/, Switch, $<term>, |$<case>, $<default>
}


method term-rhs:sym<equiv>($/) { make [Equiv,       $<term>] }
method term-rhs:sym<proj >($/) { make [Projection,  $<role>] }


method case($/) { make ast $/, Case, $<concept>, $<ident>, $<term> }


method role($/) {
    my $atom = $<atom>.made;
    make $<inverse> ?? ast $/, Inverse, $atom !! $atom;
}


method value:sym<nil      >($/) { make ast $/, Nil, $<type> }
method value:sym<object   >($/) { make ast $/, Obj, $<atom> }

method value:sym<primitive>($/) { make $<primitive-value>.made }

method value:sym<lambda   >($/) {
    make ast $/, Lambda, $<ident>, $<type>, $<term>;
}


method primitive-value:sym<true  >($/) { make ast $/, Primitive, True  }
method primitive-value:sym<false >($/) { make ast $/, Primitive, False }
method primitive-value:sym<string>($/) { make ast $/, Primitive, $<string> }


method string($/) { make $<str>».made.join }
method   char($/) { make $/.Str }
method escape($/) { make $/.Str }


method type($/) { make left-right $/ }

method type-lhs($/) {
    make $<list> ?? ast $/, ListType, $<base> !! $<base>.made;
}

method type-rhs($/) { make [FuncType, $<type>] }

method type-base:sym<paren  >($/) { make $/<type>.made }

method type-base:sym<concept>($/) { make ast $/,   ConceptType, $<concept> }
method type-base:sym<string >($/) { make ast $/, PrimitiveType, 'string'   }
method type-base:sym<bool   >($/) { make ast $/, PrimitiveType, 'bool'     }


method concept($/) { make left-right $/ }

method concept-lhs:sym<paren >($/) { make $<concept>.made }
method concept-lhs:sym<atom  >($/) { make $<atom>.made }

method concept-lhs:sym<top   >($/) { make ast $/, Everything }
method concept-lhs:sym<bottom>($/) { make ast $/,    Nothing }

method concept-lhs:sym<not   >($/) { make ast $/, Not, $<concept> }

method concept-lhs:sym<exists>($/) { make ast $/, Exists, $<role>, $<concept> }
method concept-lhs:sym<forall>($/) { make ast $/, ForAll, $<role>, $<concept> }

method concept-rhs:sym<union>($/) { make [Union,     $<concept>] }
method concept-rhs:sym<isect>($/) { make [Intersect, $<concept>] }


method atom($/) { make ast $/, Atom, "$<prefix>:$<suffix>" }

method ident($/) { make ast $/, Identifier, $/.Str }


method Concept($/) { make $<inner>.made }
method Ident  ($/) { make $<inner>.made }
method Path   ($/) { make $<inner>.made }
method Role   ($/) { make $<inner>.made }
method Term   ($/) { make $<inner>.made }
method Type   ($/) { make $<inner>.made }

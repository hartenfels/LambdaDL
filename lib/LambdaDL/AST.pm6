unit module LambdaDL::AST;
use LambdaDL::Context;


enum NodeType is export <
    Equiv Projection Application
    Let Fix If
    Cons Null Head Tail
    Switch Case Query
    Nil Obj Lambda Primitive
    PrimitiveType ConceptType ListType FuncType
    Everything Nothing Not Intersect Union Exists ForAll
    Atom Inverse
    Identifier
>;


proto sub pretty(|) returns Str is export(:pretty) { * }

multi sub pretty(Str  $_) { qq/"$_"/ }
multi sub pretty(Bool $_) { qq/?$_/ }

multi sub pretty([NodeType $type, *@args]) {
    return join "\n", "$type", |@args.map: { pretty($_).indent(4) };
}


sub ast($/, NodeType:D $type, **@args) is export {
    return [
        $type but Context.new($/),
        |@args.map: { $_ ~~ Match ?? .made !! $_ },
    ];
}

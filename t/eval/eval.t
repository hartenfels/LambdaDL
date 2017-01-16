use v6;
use Test;
use LambdaDL::Generator;
use LambdaDL::Parser;
use LambdaDL::TypeCheck;


sub eval($file) {
    my $ast = LambdaDL::Parser.parse(slurp "t/eval/data/$file.lambda");
    check-type($ast);

    my $code = generate($ast);

    use MONKEY-SEE-NO-EVAL;
    return EVAL($code);
}


sub iri($id) { "<http://example.org/music#$id>" }


cmp-ok eval('list'), 'eqv', ['same', 'different', 'different', 'same'],
       'list test results in expected list';


cmp-ok eval('rec'), 'eqv', False, 'recursion test with fix point works';


is eval('query').gist, "[{iri 'beatles'} {iri 'hendrix'}]", 'query execution';


is eval('project').gist, "[[] [{iri 'beatles'}]]", 'projection';


done-testing;

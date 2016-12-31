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


cmp-ok eval('list'), 'eqv', ['same', 'different', 'different', 'same'],
       'list test results in expected list';


cmp-ok eval('rec'), 'eqv', False, 'recursion test with fix point works';


done-testing;

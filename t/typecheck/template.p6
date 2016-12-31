use v6;
use Test;
use LambdaDL::Context;
use LambdaDL::Parser;
use LambdaDL::TypeCheck;


$_ = slurp 'FILE';
s:g/^^ \h* '#' .*? \n//;

for map { .split("|", 2)».trim }, .lines -> [$expect, $code] {
    my $ast  = LambdaDL::Parser.parse($code);
    my $type = try check-type($ast);

    if $expect ~~ /^\!(.+)$/ {
        my $class = X::LambdaDL::{"T$0"};
        ok $! ~~ $class, "error {$!.WHAT.^name} is {$class.^name} from '$code'";
    }
    else {
        is $type, $expect, "got type '$expect' from '$code'";
    }
}


done-testing;

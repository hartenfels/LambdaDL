use v6;
use Test;
use LambdaDL::Grammar;
use LambdaDL::Actions;
use LambdaDL::AST :pretty;


sub parse(Str:D $text) {
    return LambdaDL::Grammar.parse($text, :actions(LambdaDL::Actions));
}


$_ = slurp 'FILE';
s:g/^^ \h* '#' .*? \n//;

for .comb(/\S .*? <?before \n ** 2..* || \n? $>/) -> $code, $expect {
    my $match   = try parse($code);
    my ($c, $e) = ($code, $expect)».indent(2);

    if ($expect eq '!') {
        nok $match, "no parse for:\n$c";
    }
    else {
        my $made = $match ?? pretty($match.made.term) !! '';
        is $made, $expect, "parse for:\n$c\ngives:\n$e";
    }
}


done-testing;

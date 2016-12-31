#!/usr/bin/env perl6
use LambdaDL::Context;
use LambdaDL::Generator;
use LambdaDL::Parser;
use LambdaDL::TypeCheck;


sub red   (Str() $text) { "\e[31m$text\e[0m" }
sub green (Str() $text) { "\e[32m$text\e[0m" }
sub yellow(Str() $text) { "\e[33m$text\e[0m" }


sub eject($!, $file, $symbol = '⏏') {
    $*ERR.print(red($!), " in '$file'");

    with $!.ctx {
        $*ERR.print(
            ", line {.line}\n–––––> ",
            green(.before), yellow($symbol), red(.after)
        );
    }

    $*ERR.print("\n");

    exit 1;
}


our sub run(Str:D $file, IO::Handle:D $input, IO::Handle $output?) is export {
    my $text = $input.slurp-rest;
    my $ast  = try LambdaDL::Parser.parse($text);

    with $! {
        eject $_, $file when X::LambdaDL;
        .rethrow;
    }

    try check-type($ast);

    with $! {
        eject $_, $file, '⁉' when X::LambdaDL::UnknownIdentifier;
        eject $_, $file, '✘' when X::LambdaDL::T;
        eject $_, $file      when X::LambdaDL;
        .rethrow;
    }

    my $code = generate($ast);

    if $output {
        $output.print("say do \{\n{$code.indent(4)}}\n");
    }
    else {
        use MONKEY-SEE-NO-EVAL;
        say EVAL($code);
    }
}

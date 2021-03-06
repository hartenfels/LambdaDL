#!/usr/bin/env perl6
use lib $?FILE.IO.parent.absolute;
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


sub ready-output($code) {
    return qq:to/END_OF_CODE/;
        #!$*EXECUTABLE
        use lib ｢$?FILE.IO.parent.absolute()｣;
        use LambdaDL::KnowledgeBase;

        unless \%*ENV<LAMBDADL_SET_UP> \{
            \%*ENV<LAMBDADL_SET_UP> = '1';
            \%*ENV<LD_LIBRARY_PATH> = ｢%*ENV<LD_LIBRARY_PATH>｣;
            exit run(\$*EXECUTABLE, \$?FILE, |@*ARGS).exitcode;
        }

        say do \{
        $code.trim.indent(4)
        };
        END_OF_CODE
}


sub lambdadl(Str:D $file, IO::Handle:D $input, IO::Handle $output?) is export {
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
        $output.print(ready-output($code));
    }
    else {
        use MONKEY-SEE-NO-EVAL;
        say EVAL($code);
    }
}


sub source(Str:D $path, IO::Handle:D $default, *%flags) {
    use fatal;
    return $default if $path eq '-';
    return $path.IO.open(|%flags);
    CATCH {
        $*ERR.print(.message, "\n");
        exit 1;
    }
}

sub MAIN(Str $file, Str :output(:o($o))) {
    my IO::Handle $input  = source($file, $*IN, :r);
    my IO::Handle $output = source($o, $*OUT, :w) if defined $o;

    chdir $file.IO.parent if $file ne '-';

    lambdadl($file, $input, $output);

    $output.close if $output;
    chmod 0o755, $o if defined $o && $o ne '-';
}

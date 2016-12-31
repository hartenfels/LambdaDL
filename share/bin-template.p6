#!/usr/bin/env __PERL6__
constant $DIR = $?FILE.IO.parent;
use lib $DIR.child('lib').absolute;
use LambdaDL;


%*ENV<LD_LIBRARY_PATH> = join ':',
    $DIR.child('blib').absolute,
    '__LIBPATH__',
    %*ENV<LD_LIBRARY_PATH> || ();


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

    LambdaDL::run($file, $input, $output);

    $output.close if $output;
}

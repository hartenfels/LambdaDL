#!/usr/bin/env __PERL6__
my $dir = $?FILE.IO.parent;


my $blib = $dir.child('blib').absolute;
my @libs = split ':', '__LIBPATH__';

%*ENV<LD_LIBRARY_PATH> = join ':', $blib, |@libs, %*ENV<LD_LIBRARY_PATH> || ();


my $lambdadl = $dir.child('lib').child('LambdaDL.pm6').absolute;

exit run($*EXECUTABLE, $lambdadl, |@*ARGS).exitcode;

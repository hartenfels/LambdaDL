# LambdaDL - Perl 6 Implementation

Work in progress.


## Requirements

* Perl 6 - <http://rakudo.org/>

* Java JDK 8, shouldn't matter if it's Oracle or OpenJDK

* A Unix-like environment (C compiler, sh, make, perl)


## Building

First run `./configure` (which isn't autoconf). It should figure out where all
your JNI headers and libraries are. If it can't, follow the instructions it
gives to help it.

Then run `make` to build the Java and C libraries.

Then you can run `./lambdadl` proper.


## BUGS

* Precedence of `=` is too high and doesn't list associate.

* Type checking for nominal concepts might be wrong?

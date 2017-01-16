# NAME

LambdaDL – a λ-DL implementation in Perl 6


# SYNOPSIS

Build it:

    ./configure
    make

Write some λ-DL code:

    // influences.lambda
    @share/music.rdf
    map
        λ(artist:<:MusicArtist>).
            case artist of
                type <:MusicArtist> as a → a.<:influencedBy>
                default nil[<:MusicArtist>]
    in
        query <:MusicArtist>

And run it:

    ./lambdadl influences.lambda


# DESCRIPTION

Re-implementation of λ-DL so that I understand how it works. See
<https://west.uni-koblenz.de/lambda-dl> for a thorough explanation of the idea.

That page also provides the original prototype for the language. However, it's
written in F♯ and interfaces with the Java reasoner by running an external
process for every query. Due to the JVM's glacial startup time, it is rather
slow.

This project uses Perl 6 instead and interfaces with the same Java reasoner via
C. So despite Perl 6's own (as of now) glacial speed, it's much faster at
running those queries. It is also able to keep direct references to the Java
objects around, rather than having to juggle string IDs around.

There's some changes to the original language:

* Identifiers follow the same rules as Perl 6, so `don't-panic` is a valid
  variable or function name.

* `cons a, b` instead of `cons a b` to avoid visual ambiguity with function
  application.

* `→` is used instead of `->` and `⁻` instead of `^-`. It's 2017, things should
  support Unicode.

* `map FUNC in LIST` is supported because I couldn't be bothered to implement
  it in λ-DL itself.

It also doesn't implement a λ calculus interpreter, instead it just generates
Perl 6 code and evaluates that.


# REQUIREMENTS

* Perl 6 - <http://rakudo.org/>

* Java JDK 8, shouldn't matter if it's Oracle or OpenJDK

* A Unix-like environment (C compiler, sh, make, perl)


# BUILDING

First run `./configure` (which isn't autoconf). It should figure out where all
your JNI headers and libraries are. If it can't, follow the instructions it
gives to help it.

Then run `make` to build the Java and C libraries and run the tests.


# USAGE

Run `./lambdadl LAMBDADL-FILE` to compile and evaluate a LambdaDL program. If
you want a runnable script instead, use `./lambdadl --output=SCRIPT-FILE
LAMBDADL-FILE` instead.


# BUGS

* Precedence of `=` is too high and doesn't list associate.

* Type checking for nominal concepts might be wrong?


# LICENSE

[Apache License, Version 2](LICENSE)

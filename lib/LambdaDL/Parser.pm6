unit class LambdaDL::Parser;
use LambdaDL::Actions;
use LambdaDL::Context;
use LambdaDL::Grammar;


method parse(Str() $text) {
    my $match = LambdaDL::Grammar.parse($text, :actions(LambdaDL::Actions));
    return $match.?made
        || die X::LambdaDL::Parse.new(msg => "No parse for '$text'");
}

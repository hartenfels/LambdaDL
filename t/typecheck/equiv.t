use v6;
use Test;
use LambdaDL::Context;
use LambdaDL::Parser;
use LambdaDL::TypeCheck;


sub ct($code) { check-type(LambdaDL::Parser.parse($code)) }


is ct('"a"  = "a"'  ), 'bool';
is ct('true = false'), 'bool';


throws-like { ct '"a"   = true'      }, X::LambdaDL::TEquiv;
throws-like { ct 'false = nil[bool]' }, X::LambdaDL::TEquiv;


done-testing;

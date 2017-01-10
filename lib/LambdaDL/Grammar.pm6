unit grammar LambdaDL::Grammar;
use LambdaDL::Context;

constant @reserved-words = <
    let in fix letrec if then else cons null head tail
    query true false case of default nil type as λ
>;


token TOP { <ws> <kb>? <ws> <term=.Term> <ws> <garbage> }


rule kb { '@' <path=.Path> }

token path { \V+ <?{ $/ ~~ /\S/ }> }


# Application needs to be left-associative, but the grammar can't have
# left-recursive rules. So we build a repetition and reduce it later.
rule term    { <terms=.in-term>+ }
rule in-term { <lhs=.term-lhs> <rhs=.term-rhs>? }


proto rule term-lhs { * }

rule term-lhs:sym<paren> { '(' <term> <.RParen> }

rule term-lhs:sym<let> {
    'let'     <ident=.Ident>
    <.Equals> <spec=.Term>
    <.In>     <in=.Term>
}

rule term-lhs:sym<fix> { 'fix' <term=.Term> }

rule term-lhs:sym<letrec> {
    'letrec'  <ident=.Ident>
    <.Colon>  <type=.Type>
    <.Equals> <spec=.Term>
    <.In>     <in=.Term>
}

rule term-lhs:sym<if> {
    'if'    <if=.Term>
    <.Then> <then=.Term>
    <.Else> <else=.Term>
}

# List constructor notation in the paper is ambiguous with application. The F#
# parser solves this by not allowing applications in list constructors, but
# that's weird. So we require a disambiguating comma instead.
rule term-lhs:sym<cons> { 'cons' <head=.Term> <.Comma> <tail=.Term> }

rule term-lhs:sym<null> { 'null' <term=.Term> }
rule term-lhs:sym<head> { 'head' <term=.Term> }
rule term-lhs:sym<tail> { 'tail' <term=.Term> }

rule term-lhs:sym<query> { 'query' <concept=.Concept> }

rule term-lhs:sym<identifier> { <ident> }

rule term-lhs:sym<value> { <value> }

rule term-lhs:sym<case> {
    'case'     <term=.Term>
    <.Of>      <case>*
    <.Default> <default=.Term>
}


proto rule term-rhs { * }

rule term-rhs:sym<equiv> { '=' <term=.Term> }
rule term-rhs:sym<proj > { '.' <role=.Role> }


rule case {
    'type'   <concept=.Concept>
    <.As>    <ident=.Ident>
    <.Arrow> <term=.Term>
}


rule role { <atom> [ $<inverse>='⁻' ]? }


proto rule value { * }

rule value:sym<nil      > { 'nil' <.LBracket> <type=.Type> <.RBracket> }
rule value:sym<object   > { <atom> }
rule value:sym<primitive> { <primitive-value> }
rule value:sym<lambda   > {
    'λ' <.LParen>
        <ident=.Ident> <.Colon> <type=.Type>
    <.RParen>
    <.Dot> <term=.Term>
}


proto token primitive-value { * }

token primitive-value:sym<true  > { 'true'  }
token primitive-value:sym<false > { 'false' }
token primitive-value:sym<string> { '"' <string> <.Quote> }

token string { [ <str=.char> | <str=.escape> ]* }
token char   { <-[ " \\ ]>+ }
token escape { \\ $<key>=<[ bfnrt " \\ ]> }


rule type { <lhs=.type-lhs> <rhs=.type-rhs>? }

rule type-lhs { <base=.type-base> [ $<list>='[]' ]? }
rule type-rhs { '→' <type=.Type> }

proto rule type-base { * }

rule type-base:sym<paren  > { '(' <type> <.RParen> }
rule type-base:sym<concept> { <concept> }
rule type-base:sym<string > { 'string' }
rule type-base:sym<bool   > { 'bool'   }


rule concept { <lhs=.concept-lhs> <rhs=.concept-rhs>? }

proto rule concept-lhs { * }

rule concept-lhs:sym<paren > { '(' <concept> <.RParen> }
rule concept-lhs:sym<atom  > { <atom> }
rule concept-lhs:sym<top   > { '⊤' }
rule concept-lhs:sym<bottom> { '⊥' }
rule concept-lhs:sym<not   > { '¬' <concept=.Concept> }
rule concept-lhs:sym<exists> { '∃' <role=.Role> <.Dot> <concept=.Concept> }
rule concept-lhs:sym<forall> { '∀' <role=.Role> <.Dot> <concept=.Concept> }

proto rule concept-rhs { * }

rule concept-rhs:sym<union> { '⊔' <concept=.Concept> }
rule concept-rhs:sym<isect> { '⊓' <concept=.Concept> }


token atom { '<' $<prefix>=\w* <.Colon> $<suffix>=\w+ <.RAngle> }

# Identifiers work like in Perl 6.
token ident {
    [ <:L> || '_' ]     # start with a letter or underscore
    \w*                 # continue with any word character
    [ <[ - ' ]> \w+ ]*  # dashes and apostrophes may connect words
    <?{ $/ ne any @reserved-words }> # check that it's not a reserved word
}


token ws { <blank>* }

proto token blank { * }

token blank:sym<line > { '//' \V* }
token blank:sym<block> { '/*' .*? <.RComment> }
token blank:sym<plain> { \s+ }


token Concept { <inner=.concept> || <needed('a concept'    )> }
token Ident   { <inner=.ident>   || <needed('an identifier')> }
token Path    { <inner=.path>    || <needed('a path'       )> }
token Role    { <inner=.role>    || <needed('a role'       )> }
token Term    { <inner=.term>    || <needed('a term'       )> }
token Type    { <inner=.type>    || <needed('a type'       )> }

token Arrow    { '→'       || <needed("'→'"      )> }
token As       { 'as'      || <needed("'as'"     )> }
token Colon    { ':'       || <needed("':'"      )> }
token Comma    { ','       || <needed("','"      )> }
token Dot      { '.'       || <needed("'.'"      )> }
token Default  { 'default' || <needed("'default'")> }
token Else     { 'else'    || <needed("'else'"   )> }
token Equals   { '='       || <needed("'='"      )> }
token If       { 'if'      || <needed("'if'"     )> }
token In       { 'in'      || <needed("'in'"     )> }
token LBracket { '['       || <needed("'['"      )> }
token LParen   { '('       || <needed("'('"      )> }
token Of       { 'of'      || <needed("'of'"     )> }
token Quote    { '"'       || <needed("'\"'"     )> }
token RAngle   { '>'       || <needed("'>'"      )> }
token RBracket { ']'       || <needed("']'"      )> }
token RComment { '*/'      || <needed("'*/'"     )> }
token RParen   { ')'       || <needed("')'"      )> }
token Then     { 'then'    || <needed("'then'"   )> }


sub at(Int $up) {
    return callframe($up).code.name;
}

sub ex($match, $rule, $msg) {
    die X::LambdaDL::Syntax.new(:ctx(Context.new: $match), :$rule, :$msg);
}

method needed($need) {
    ex self.MATCH, at(3), "expected $need here";
}

method found-garbage() {
    ex self.MATCH, at(3), "garbage after root term";
}

rule garbage { \S .* <found-garbage()> || <ws> }

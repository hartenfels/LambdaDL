use v6;
use Test;
use LambdaDL::Context;
use LambdaDL::Parser;
use LambdaDL::TypeCheck;


sub proj($code) {
    return check-type(LambdaDL::Parser.parse("@share/music.rdf\n$code"));
}

sub iri($id) { "<http://example.org/music#$id>" }


is proj('(head query <:MusicArtist>).<:influencedBy>'),
   "ObjectSomeValuesFrom(InverseOf({iri 'influencedBy'}) {iri 'MusicArtist'})[]",
   'projecting songs of a music artist';


throws-like { proj 'true.<:Song>' },
            X::LambdaDL::TProjection,
            'no projecting booleans';

throws-like { proj '(query <:MusicArtist>).<:influencedBy>' },
            X::LambdaDL::TProjection,
            'no projecting lists of concepts';


done-testing;

use v6;
use Test;
use LambdaDL::Context;
use LambdaDL::Parser;
use LambdaDL::TypeCheck;


sub query($code) {
    return check-type(LambdaDL::Parser.parse("@share/music.rdf\nquery $code"));
}

sub iri($id) { "<http://example.org/music#$id>" }


is query('⊤'),
   'owl:Thing[]',
   'query for ⊤';

is query('<:MusicArtist>'),
   "{iri 'MusicArtist'}[]",
   'query for MusicArtists';

is query('<:MusicArtist> ⊔ <:Song>'),
   "ObjectUnionOf({iri 'MusicArtist'} {iri 'Song'})[]",
   'query for union of MusicArtists and Songs';


throws-like { query '⊥' },
            X::LambdaDL::TQuery,
            'query after nothing is unsatisfiable';


done-testing;

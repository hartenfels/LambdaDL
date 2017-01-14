use v6;
use LambdaDL::AST;
use LambdaDL::DL;
use LambdaDL::KnowledgeBase;
use Test;

my $kb = LambdaDL::KnowledgeBase.new('share/music.rdf');


is dl($kb, [Everything]), 'owl:Thing',   'dl for ⊤';
is dl($kb, [Nothing   ]), 'owl:Nothing', 'dl for ⊥';


is dl($kb, [Atom, 'xsd:string']),
   'xsd:string',
   'dl for <xsd:string>';

is dl($kb, [Atom, ':MusicArtist']),
   '<http://example.org/music#MusicArtist>',
   'dl for <:MusicArtist>';

is dl($kb, [Atom, 'What:Ever']),
   '<What:Ever>',
   'dl for <What:Ever>';


is dl($kb, [Not, [Everything]]),
   'ObjectComplementOf(owl:Thing)',
   'dl for ¬⊤';


is dl($kb, [Intersect, [Nothing], [Everything]]),
   'ObjectIntersectionOf(owl:Nothing owl:Thing)',
   'dl for ⊥ ⊔ ⊤';

is dl($kb, [Union, [Nothing], [Everything]]),
   'ObjectUnionOf(owl:Nothing owl:Thing)',
   'dl for ⊥ ⊔ ⊤';

# Intersection and union sets get sorted by their name, so turning around the
# order of operands should still result in the same stringification.

is dl($kb, [Intersect, [Everything], [Nothing]]),
   'ObjectIntersectionOf(owl:Nothing owl:Thing)',
   'dl for ⊤ ⊓ ⊥';

is dl($kb, [Union, [Everything], [Nothing]]),
   'ObjectUnionOf(owl:Nothing owl:Thing)',
   'dl for ⊤ ⊔ ⊥';


is dl($kb, [Exists, [Atom, ':MusicArtist'], [Everything]]),
   'ObjectSomeValuesFrom(<http://example.org/music#MusicArtist> owl:Thing)',
   'dl for ∃<:MusicArtist>.⊤';

is dl($kb, [ForAll, [Atom, ':MusicArtist'], [Everything]]),
   'ObjectAllValuesFrom(<http://example.org/music#MusicArtist> owl:Thing)',
   'dl for ∀<:MusicArtist>.⊤';


done-testing;

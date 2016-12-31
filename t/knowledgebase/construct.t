use v6;
use LambdaDL::KnowledgeBase;
use Test;


lives-ok { LambdaDL::KnowledgeBase.new('share/music.rdf') }, 'valid construct';


nok try LambdaDL::KnowledgeBase.new('nonexistent.rdf'), 'bad construct';

ok $! ~~ X::Java, 'wrapped Java exception is thrown';

is $!.class-name, "org.semanticweb.owlapi.io.OWLOntologyInputSourceException",
   'expected Java exception is thrown';


done-testing;

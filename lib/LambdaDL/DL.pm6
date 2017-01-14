unit module LambdaDL::DL;
use LambdaDL::AST;


proto sub dl-r(|) is export {*}

multi sub dl-r($kb, [Atom,    $iri ]) { $kb.atom($iri)          }
multi sub dl-r($kb, [Inverse, $atom]) { dl-r($kb, $atom).invert }


proto sub dl(|) is export {*}

multi sub dl($kb, [Atom, $iri]) { $kb.concept($iri)     }

multi sub dl($kb, [Everything]) { $kb.everything }
multi sub dl($kb, [Nothing   ]) { $kb.nothing    }

multi sub dl($kb, [Not, $concept]) { dl($kb, $concept).not }

multi sub dl($kb, [Intersect, $a, $b]) { dl($kb, $a).intersect: dl($kb, $b) }
multi sub dl($kb, [Union,     $a, $b]) { dl($kb, $a).union:     dl($kb, $b) }

multi sub dl($kb, [Exists, $r, $c]) { dl-r($kb, $r).exists:  dl($kb, $c) }
multi sub dl($kb, [ForAll, $r, $c]) { dl-r($kb, $r).for-all: dl($kb, $c) }

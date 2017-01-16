unit class LambdaDL::KnowledgeBase;
use NativeCall;


constant $STRING     = 'Ljava/lang/String;';
constant $ROLE       = 'Lorg/semanticweb/owlapi/model/OWLObjectPropertyExpression;';
constant $CONCEPT    = 'Lorg/semanticweb/owlapi/model/OWLClassExpression;';
constant $INDIVIDUAL = 'Lorg/semanticweb/owlapi/model/OWLNamedIndividual;';


sub jcall(&func, *@args) { ... }


class JObject is repr('CPointer') {
    method as-str() {
        my $buf;
        jcall(&ldl_j2s, self, sub (uint32 $len --> blob16) {
            return $buf = blob16.new(0 xx $len);
        });
        return $buf.decode('UTF-16');
    }

    method Str() {
        return jcall(&ldl_o, self, 'toString', "()$STRING").as-str;
    }
}


sub ldl_have_jvm(--> int32)
    is native('lambdadl') { ... }

sub ldl_init_jvm(CArray[Str], int32, int32 is rw --> int32)
    is native('lambdadl') { ... }

sub ldl_check_exception(--> JObject)
    is native('lambdadl') { ... }

sub ldl_s2j(blob16, uint32 --> JObject)     is native('lambdadl') { ... }
sub ldl_j2s(JObject, & (uint32 --> blob16)) is native('lambdadl') { ... }

sub ldl_get_class_name(JObject --> JObject)
    is native('lambdadl') { ... }

sub ldl_new_KnowledgeBase(blob16, uint32 --> JObject)
    is native('lambdadl') { ... }

sub ldl_root  (JObject --> JObject) is native('lambdadl') { ... }
sub ldl_unroot(JObject)             is native('lambdadl') { ... }

sub ldl_b_o(JObject, JObject, Str, Str --> int32)
    is native('lambdadl') { ... }

sub ldl_b_oo(JObject, JObject, JObject, Str, Str --> int32)
    is native('lambdadl') { ... }

sub ldl_o(JObject, Str, Str --> JObject)
    is native('lambdadl') { ... }

sub ldl_o_o(JObject, JObject, Str, Str --> JObject)
    is native('lambdadl') { ... }

sub ldl_o_oo(JObject, JObject, JObject, Str, Str --> JObject)
    is native('lambdadl') { ... }

sub ldl_v(JObject, Str)
    is native('lambdadl') { ... }

sub ldl_each(JObject, & (JObject))
    is native('lambdadl') { ... }


sub init-jvm() {
    return False if ldl_have_jvm;

    my $dir    = $?FILE.IO.parent.parent.parent;
    my $hermit = $dir.child('vendor').child('HermiT.jar').absolute;
    my $blib   = $dir.child('blib').absolute;

    my CArray[Str] $opts .= new;
    $opts[0] = "-Djava.class.path=$hermit\:$blib";

    my int32 $error;

    given ldl_init_jvm($opts, 1, $error) {
        when 0  { return True                            }
        when 1  { die "Can't set up JVM options: $error" }
        when 2  { die "Can't create JVM: $error"         }
        default { die "Unknown JVM init error: $error"   }
    }
}


our $in-exception;

class X::Java is Exception is export {
    has JObject $.ex is required;

    method message(--> Str) {
        temp $in-exception = True;
        return jcall(&ldl_o, $!ex, 'getMessage', "()$STRING").as-str;
    }

    method print-stack-trace(--> X::Java:D) {
        temp $in-exception = True;
        jcall(&ldl_v, $!ex, 'printStackTrace');
        return self;
    }

    method class-name(--> Str) {
        temp $in-exception = True;
        return ldl_get_class_name($!ex).as-str;
    }
}


sub jcall(&func, *@args) {
    my $retval = func(|map { .?JObject // $_ }, @args);

    if ldl_check_exception() -> $ex {
        if ($in-exception) {
            die 'Error while handling exception';
        }
        else {
            die X::Java.new(:$ex);
        }
    }

    return $retval;
}


sub enc(Str:D $s) {
    my $b = $s.encode('UTF-16');
    return $b, $b.elems;
}


role Rooted {
    has LambdaDL::KnowledgeBase:D $!kb  is required;
    has JObject:D                 $!obj is required;

    submethod BUILD(:$!kb, :$obj) { $!obj = ldl_root($obj) }

    submethod DESTROY { ldl_unroot($!obj)      }

    method new(LambdaDL::KnowledgeBase:D $kb, JObject:D $obj) {
        return self.bless(:$kb, :$obj);
    }

    method gist   () { ~$!obj }
    method Str    () { ~$!obj }
    method JObject() {  $!obj }
}


class Individual { ... }


class Concept does Rooted {
    method not(--> Concept:D) {
        my $not = jcall(&ldl_o_o, $!kb, $!obj, 'not', "($CONCEPT)$CONCEPT");
        return Concept.new: $!kb, $not;
    }

    method intersect(Concept() $with --> Concept:D) {
        my $intersect = jcall(&ldl_o_oo, $!kb, $!obj, $with, 'intersect',
                              "($CONCEPT$CONCEPT)$CONCEPT");
        return Concept.new: $!kb, $intersect;
    }

    method union(Concept() $with --> Concept:D) {
        my $union = jcall(&ldl_o_oo, $!kb, $!obj, $with, 'union',
                          "($CONCEPT$CONCEPT)$CONCEPT");
        return Concept.new: $!kb, $union;
    }

    method satisfiable(--> Bool:D) {
        return so jcall(&ldl_b_o, $!kb, $!obj, 'satisfiable', "($CONCEPT)Z");
    }

    method comparable(Concept() $with --> Bool:D) {
        return so jcall(&ldl_b_oo, $!kb, $!obj, $with, 'comparable',
                        "($CONCEPT$CONCEPT)Z");
    }

    method query(--> Array[Individual]) {
        return $!kb.individuals: jcall &ldl_o_o, $!kb, $!obj, 'query',
                                       "($CONCEPT)[$INDIVIDUAL";
    }

    method like(Individual() $individual --> Bool:D) {
        return so jcall &ldl_b_oo, $!kb, $individual, $!obj, 'member',
                        "($INDIVIDUAL$CONCEPT)Z";
    }
}


class Role does Rooted {
    method invert(--> Role:D) {
        my $inv = jcall(&ldl_o_o, $!kb, $!obj, 'invert', "($ROLE)$ROLE");
        return Role.new: $!kb, $inv;
    }

    method exists(Concept() $in --> Concept:D) {
        my $exists = jcall(&ldl_o_oo, $!kb, $!obj, $in, 'exists',
                           "($ROLE$CONCEPT)$CONCEPT");
        return Concept.new: $!kb, $exists;
    }

    method for-all(Concept() $in --> Concept:D) {
        my $for-all = jcall(&ldl_o_oo, $!kb, $!obj, $in, 'forAll',
                            "($ROLE$CONCEPT)$CONCEPT");
        return Concept.new: $!kb, $for-all;
    }
}


class Individual does Rooted {
    method project(Role() $on --> Array[Individual]) {
        return $!kb.individuals: jcall &ldl_o_oo, $!kb, $!obj, $on, 'project',
                                       "($INDIVIDUAL$ROLE)[$INDIVIDUAL";
    }
}


has JObject:D $!kb is required;

submethod BUILD(Str:D :$path) {
    init-jvm;
    $!kb = ldl_root(jcall(&ldl_new_KnowledgeBase, enc($path)));
}

submethod DESTROY { ldl_unroot($!kb) }

method new(Str $at) {
    state %cache;
    my $path = $at.IO.absolute;
    return %cache{$path} //= self.bless(:$path);
}

method JObject() { $!kb }


method atom(Str() $iri --> Role) {
    my $jstr = jcall(&ldl_s2j, enc($iri));
    my $role = jcall(&ldl_o_o, $!kb, $jstr, 'role', "($STRING)$ROLE");
    return Role.new: self, $role;
}


method concept(Str() $iri --> Concept:D) {
    my $jstr    = jcall(&ldl_s2j, enc($iri));
    my $concept = jcall(&ldl_o_o, $!kb, $jstr, 'concept', "($STRING)$CONCEPT");
    return Concept.new: self, $concept;
}

method everything(--> Concept:D) {
    my $top = jcall(&ldl_o, $!kb, 'everything', "()$CONCEPT");
    return Concept.new: self, $top;
}

method nothing(--> Concept:D) {
    my $bot = jcall(&ldl_o, $!kb, 'nothing', "()$CONCEPT");
    return Concept.new: self, $bot;
}


method nominal(Str() $iri --> Individual:D) {
    my $jstr       = jcall &ldl_s2j, enc($iri);
    my $individual = jcall &ldl_o_o, $!kb, $jstr, 'nominal',
                           "($STRING)$INDIVIDUAL";
    return Individual.new: self, $individual;
}

method individuals(JObject() $jarray --> Array[Individual]) {
    my Array[Individual] $accu .= new;
    jcall &ldl_each, $jarray, -> JObject $obj {
        $accu.push(Individual.new: self, $obj);
    };
    return $accu;
}

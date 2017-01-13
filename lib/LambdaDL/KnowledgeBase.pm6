unit class LambdaDL::KnowledgeBase;
use NativeCall;


constant $STRING  = 'Ljava/lang/String;';
constant $ROLE    = 'Lorg/semanticweb/owlapi/model/OWLObjectPropertyExpression;';
constant $CONCEPT = 'Lorg/semanticweb/owlapi/model/OWLClassExpression;';


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

sub ldl_v(JObject, Str)
    is native('lambdadl') { ... }

sub ldl_o(JObject, Str, Str --> JObject)
    is native('lambdadl') { ... }

sub ldl_o_o(JObject, JObject, Str, Str --> JObject)
    is native('lambdadl') { ... }

sub ldl_o_oo(JObject, JObject, JObject, Str, Str --> JObject)
    is native('lambdadl') { ... }


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
    my $retval = func(|@args);

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
    has JObject:D                 $.obj is required;

    submethod BUILD(:$!kb, :$obj) { $!obj = ldl_root($obj) }

    submethod DESTROY { ldl_unroot($!obj)      }

    method new(LambdaDL::KnowledgeBase:D $kb, JObject:D $obj) {
        return self.bless(:$kb, :$obj);
    }

    method jkb() { $!kb.kb }
}


class Concept does Rooted {
    method not(--> Concept:D) {
        my $not = jcall(&ldl_o_o, $!kb, $!obj, 'not', "($CONCEPT)$CONCEPT");
        return Concept.new: $!kb, $not;
    }

    method intersect(Concept() $with --> Concept:D) {
        my $intersect = jcall(&ldl_o_oo, $.jkb, $!obj, $with.obj, 'intersect',
                              "($CONCEPT$CONCEPT)$CONCEPT");
        return Concept.new: $!kb, $intersect;
    }

    method union(Concept() $with --> Concept:D) {
        my $union = jcall(&ldl_o_oo, $.jkb, $!obj, $with.obj, 'union',
                          "($CONCEPT$CONCEPT)$CONCEPT");
        return Concept.new: $!kb, $union;
    }
}


class Role does Rooted {
    method invert(--> Role:D) {
        my $inv = jcall(&ldl_o_o, $.jkb, $!obj, 'invert', "($ROLE)$ROLE");
        return Role.new: $!kb, $inv;
    }

    method exists(Concept() $in --> Concept:D) {
        my $exists = jcall(&ldl_o_oo, $.jkb, $!obj, $in.obj, 'exists',
                           "($ROLE$CONCEPT)$CONCEPT");
        return Concept.new: $!kb, $exists;
    }

    method for-all(Concept() $in --> Concept:D) {
        my $for-all = jcall(&ldl_o_oo, $.jkb, $!obj, $in.obj, 'forAll',
                            "($ROLE$CONCEPT)$CONCEPT");
        return Concept.new: $!kb, $for-all;
    }
}


has JObject:D $.kb is required;

submethod BUILD(Str:D :$path) {
    $!kb = ldl_root(jcall(&ldl_new_KnowledgeBase, enc($path)));
}

submethod DESTROY { ldl_unroot($!kb) }

method new(Str() $path) { self.bless(:$path) }


method atom(Str() $iri --> Role) {
    my $jstr = jcall(&ldl_s2j, enc($iri));
    my $role = jcall(&ldl_o_o, $!kb, $jstr, 'role', "($STRING)$ROLE");
    return Role.new: self, $role;
}


method everything(--> Concept:D) {
    my $top = jcall(&ldl_o, $!kb, 'everything', "()$CONCEPT");
    return Concept.new: self, $top;
}

method nothing(--> Concept:D) {
    my $bot = jcall(&ldl_o, $!kb, 'nothing', "()$CONCEPT");
    return Concept.new: self, $bot;
}

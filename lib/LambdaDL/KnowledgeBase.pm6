unit class LambdaDL::KnowledgeBase;
use NativeCall;


sub jcall(&func, *@args) { ... }


class JObject is repr('CPointer') {
    method Str() {
        my $buf;
        jcall(&ldl_str, self, sub (uint32 $len --> blob16) {
            return $buf = blob16.new(0 xx $len);
        });
        return $buf.decode('utf-16');
    }
}


sub ldl_check_exception(--> JObject)
    is native('lambdadl') { ... }

sub ldl_str(JObject, & (uint32 --> blob16))
    is native('lambdadl') { ... }

sub ldl_get_class_name(JObject --> JObject)
    is native('lambdadl') { ... }

sub ldl_new_KnowledgeBase(blob16, uint32 --> JObject)
    is native('lambdadl') { ... }

sub ldl_call_v(JObject, Str)
    is native('lambdadl') { ... }

sub ldl_call_vo(JObject, Str, Str --> JObject)
    is native('lambdadl') { ... }


our $in-exception;

class X::Java is Exception is export {
    has JObject $.ex is required;

    method message(--> Str) {
        temp $in-exception = True;
        return ~jcall(&ldl_call_vo, $!ex, 'getMessage', '()Ljava/lang/String;');
    }

    method print-stack-trace(--> X::Java:D) {
        temp $in-exception = True;
        jcall(&ldl_call_v, $!ex, 'printStackTrace');
        return self;
    }

    method class-name(--> Str) {
        temp $in-exception = True;
        return ~ldl_get_class_name($!ex);
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


has JObject:D $.obj is required;

method new(Str:D $path --> LambdaDL::KnowledgeBase) {
    my $obj = jcall(&ldl_new_KnowledgeBase, enc($path));
    return self.bless(:$obj);
}

method dump-hierarchies(--> Str:D) {
    return ~jcall(&ldl_call_vo, $!obj, 'dumpHierarchies',
                  '()Ljava/lang/String;');
}

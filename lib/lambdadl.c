#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <jni.h>


#define NOTHING

#define J_FIND_CLASS(cls, name, retval) \
    if (!(cls = (*env)->FindClass(env, name))) { \
        fprintf(stderr, "Can't find class '%s'\n", name); \
        return retval; \
    }

#define J_FIND_METHOD(meth, cls, name, args, retval) \
    if (!(meth = (*env)->GetMethodID(env, cls, name, args))) { \
        fprintf(stderr, "Can't find method '%s'\n", name); \
        return retval; \
    }

#define J_GET_OBJECT_CLASS(cls, obj, retval) \
    if (!obj || !(cls = (*env)->GetObjectClass(env, obj))) { \
        fprintf(stderr, "Can't get object class for '%p'\n", (void *)obj); \
        return retval; \
    }

#define J_ARGS const char *name, const char *signature


static JavaVM *jvm = NULL;
static JNIEnv *env = NULL;


int ldl_init_jvm(void)
{
    JavaVMInitArgs args;
    JavaVMOption   options;
    int            status;

    options.optionString    = "-Djava.class.path=vendor/HermiT.jar:blib";
    args.version            = JNI_VERSION_1_8;
    args.nOptions           = 1;
    args.options            = &options;
    args.ignoreUnrecognized = 0;

    status = JNI_CreateJavaVM(&jvm, (void **)&env, &args);

    if (status < 0 || !env) {
        fprintf(stderr, "Can't start JVM: %d\n", status);
        return -1;
    }

    return 0;
}


jthrowable ldl_check_exception(void)
{
    jthrowable ex = (*env)->ExceptionOccurred(env);
    (*env)->ExceptionClear(env);
    return ex;
}


jobject ldl_new_KnowledgeBase(const jchar *path, unsigned int len)
{
    jclass    cls;
    jmethodID mid;
    jstring   str;
    jobject   obj;

    if (!env && ldl_init_jvm() != 0) {
        return NULL;
    }

    J_FIND_CLASS(cls, "KnowledgeBase", NULL);
    J_FIND_METHOD(mid, cls, "<init>", "(Ljava/lang/String;)V", NULL);

    if (!(str = (*env)->NewString(env, path, len))) {
        return NULL;
    }

    if (!(obj = (*env)->NewObject(env, cls, mid, str))) {
        return NULL;
    }

    return obj;
}


jobject ldl_root(jobject obj)
{
    return (*env)->NewGlobalRef(env, obj);
}

void ldl_unroot(jobject obj)
{
    (*env)->DeleteGlobalRef(env, obj);
}


jstring ldl_s2j(const jchar *str, unsigned int len)
{
    return (*env)->NewString(env, str, len);
}


void ldl_j2s(jstring str, jchar *(*gimme_buf)(unsigned int))
{
    jsize        len;
    const jchar *chars;

    len   = (*env)->GetStringLength(env, str);
    chars = (*env)->GetStringChars(env, str, JNI_FALSE);

    memcpy(gimme_buf(len), chars, len * sizeof(*chars));

    (*env)->ReleaseStringChars(env, str, chars);
}


static jobject call_o(jobject obj, const char *name, const char *signature, ...)
{
    va_list   args;
    jclass    cls;
    jmethodID mid;
    jobject   ret;

    J_GET_OBJECT_CLASS(cls, obj, NULL);
    J_FIND_METHOD(mid, cls, name, signature, NULL);

    va_start(args, signature);
    ret = (*env)->CallObjectMethodV(env, obj, mid, args);
    va_end(args);

    return ret;
}

jobject ldl_o(jobject obj, J_ARGS)
{
    return call_o(obj, name, signature);
}

jobject ldl_o_o(jobject obj, jobject arg1, J_ARGS)
{
    return call_o(obj, name, signature, arg1);
}

jobject ldl_o_oo(jobject obj, jobject arg1, jobject arg2, J_ARGS)
{
    return call_o(obj, name, signature, arg1, arg2);
}


void ldl_v(jobject obj, const char *name)
{
    jclass    cls;
    jmethodID mid;

    J_GET_OBJECT_CLASS(cls, obj, NOTHING);
    J_FIND_METHOD(mid, cls, name, "()V", NOTHING);

    (*env)->CallVoidMethod(env, obj, mid);
}


jobject ldl_get_class_name(jobject obj)
{
    jclass    cls;
    jmethodID mid;
    jobject   co;

    J_GET_OBJECT_CLASS(cls, obj, NULL);
    J_FIND_METHOD(mid, cls, "getClass", "()Ljava/lang/Class;", NULL);

    if (!(co = (*env)->CallObjectMethod(env, obj, mid))) {
        return NULL;
    }

    return ldl_o(co, "getName", "()Ljava/lang/String;");
}

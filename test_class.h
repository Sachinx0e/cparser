/* DO NOT EDIT THIS FILE - it is machine generated */
#include <jni.h>
/* Header for class test_class */

#ifndef _Included_test_class
#define _Included_test_class
#ifdef __cplusplus
extern "C" {
#endif
/*
 * Class:     test_class
 * Method:    test_class
 * Signature: (I)J
 */
JNIEXPORT jlong JNICALL Java_test_1class_test_1class__I
  (JNIEnv *, jclass, jint);

/*
 * Class:     test_class
 * Method:    test_class
 * Signature: (Ljava/lang/String;)J
 */
JNIEXPORT jlong JNICALL Java_test_1class_test_1class__Ljava_lang_String_2
  (JNIEnv *, jclass, jstring);

/*
 * Class:     test_class
 * Method:    test_function
 * Signature: (JI)V
 */
JNIEXPORT void JNICALL Java_test_1class_test_1function__JI
  (JNIEnv *, jclass, jlong, jint);

/*
 * Class:     test_class
 * Method:    test_function_return
 * Signature: (J)Ljava/lang/String;
 */
JNIEXPORT jstring JNICALL Java_test_1class_test_1function_1return
  (JNIEnv *, jclass, jlong);

/*
 * Class:     test_class
 * Method:    test_function_static
 * Signature: (I)Ljava/lang/String;
 */
JNIEXPORT jstring JNICALL Java_test_1class_test_1function_1static
  (JNIEnv *, jclass, jint);

/*
 * Class:     test_class
 * Method:    finalize
 * Signature: (J)V
 */
JNIEXPORT void JNICALL Java_test_1class_finalize
  (JNIEnv *, jclass, jlong);

/*
 * Class:     test_class
 * Method:    test_function
 * Signature: (J)V
 */
JNIEXPORT void JNICALL Java_test_1class_test_1function__J
  (JNIEnv *, jclass, jlong);

#ifdef __cplusplus
}
#endif
#endif

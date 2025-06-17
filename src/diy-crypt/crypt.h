#ifndef _CRYPT_H
#define _CRYPT_H

#ifdef __cplusplus
extern "C" {
#endif

/* Simple crypt implementation for Android nginx build */

struct crypt_data {
    char initialized;
    char __buf[256];
};

/* Main crypt function */
char *crypt(const char *key, const char *salt);

/* Thread-safe crypt function */
char *crypt_r(const char *key, const char *salt, struct crypt_data *data);

#ifdef __cplusplus
}
#endif

#endif /* _CRYPT_H */

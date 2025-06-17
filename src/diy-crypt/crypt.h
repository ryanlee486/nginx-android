/* DIY libcrypt implementation for Android nginx build
 * Compatible with standard Unix crypt API and behavior
 */

#ifndef _CRYPT_H
#define _CRYPT_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Output buffer size - matches libxcrypt CRYPT_OUTPUT_SIZE */
#define CRYPT_OUTPUT_SIZE 384

/* Maximum passphrase size - matches libxcrypt */
#define CRYPT_MAX_PASSPHRASE_SIZE 512

/* Internal data size for crypt_data structure */
#define CRYPT_DATA_INTERNAL_SIZE 32768

/* Thread-safe data structure - matches libxcrypt layout */
struct crypt_data {
    /* Output buffer for the result */
    char output[CRYPT_OUTPUT_SIZE];

    /* Initialization flag */
    char initialized;

    /* Internal scratch space */
    char internal[CRYPT_DATA_INTERNAL_SIZE];
};

/* Main crypt function - uses static buffer */
char *crypt(const char *phrase, const char *setting);

/* Thread-safe crypt function */
char *crypt_r(const char *phrase, const char *setting, struct crypt_data *data);

/* Extended crypt functions for compatibility */
char *crypt_rn(const char *phrase, const char *setting, void *data, int size);
char *crypt_ra(const char *phrase, const char *setting, void **data, int *size);

/* Salt generation functions */
char *crypt_gensalt(const char *prefix, unsigned long count,
                   const char *rbytes, int nrbytes);
char *crypt_gensalt_rn(const char *prefix, unsigned long count,
                      const char *rbytes, int nrbytes,
                      char *output, int output_size);
char *crypt_gensalt_ra(const char *prefix, unsigned long count,
                      const char *rbytes, int nrbytes,
                      char **output, int *output_size);

#ifdef __cplusplus
}
#endif

#endif /* _CRYPT_H */

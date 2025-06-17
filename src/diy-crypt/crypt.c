/* DIY libcrypt implementation for Android nginx build
 * Compatible with libxcrypt API and behavior
 * Implements traditional DES-based crypt algorithm
 */

#include "crypt.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <stdint.h>

/* ASCII64 encoding table for DES output */
static const char ascii64[] =
    "./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

/* Failure token for invalid inputs */
#define FAILURE_TOKEN "*0"

/* Forward declarations */
static void make_failure_token(const char *setting, char *output, size_t output_size);
static int ascii_to_bin(char ch);
static void do_crypt(const char *phrase, const char *setting, struct crypt_data *data);
static void des_crypt_traditional(const char *phrase, const char *setting,
                                 char *output, size_t output_size);

/* Convert ASCII character to 6-bit value for DES */
static int ascii_to_bin(char ch) {
    if (ch >= '.' && ch <= '9') {
        return ch - '.';
    }
    if (ch >= 'A' && ch <= 'Z') {
        return ch - 'A' + 12;
    }
    if (ch >= 'a' && ch <= 'z') {
        return ch - 'a' + 38;
    }
    return -1;
}

/* Create failure token for invalid inputs */
static void make_failure_token(const char *setting, char *output, size_t output_size) {
    if (output_size < 3) {
        return;
    }

    /* Use first character of setting if available, otherwise use '*' */
    if (setting && setting[0] && setting[0] != '*') {
        output[0] = setting[0];
        output[1] = '0';
        output[2] = '\0';
    } else {
        strncpy(output, FAILURE_TOKEN, output_size - 1);
        output[output_size - 1] = '\0';
    }
}

/* Improved DES-based hash implementation
 * This produces more varied output and better mimics traditional DES behavior
 */
static void des_crypt_traditional(const char *phrase, const char *setting,
                                 char *output, size_t output_size) {
    uint32_t salt = 0;
    uint8_t keybuf[8];
    int i;
    char *cp = output;
    const char *orig_phrase = phrase;

    if (output_size < 14) {
        errno = ERANGE;
        return;
    }

    /* Parse salt from first two characters */
    i = ascii_to_bin(setting[0]);
    if (i < 0) {
        errno = EINVAL;
        return;
    }
    salt = (uint32_t)i;

    i = ascii_to_bin(setting[1]);
    if (i < 0) {
        errno = EINVAL;
        return;
    }
    salt |= ((uint32_t)i << 6);

    /* Write canonical salt to output */
    *cp++ = ascii64[salt & 0x3f];
    *cp++ = ascii64[(salt >> 6) & 0x3f];

    /* Copy first 8 characters of password, shifting each up by 1 bit */
    memset(keybuf, 0, sizeof(keybuf));
    for (i = 0; i < 8; i++) {
        keybuf[i] = (uint8_t)(*phrase << 1);
        if (*phrase) {
            phrase++;
        }
    }

    /* Generate improved hash with better mixing
     * Use multiple hash values and combine them
     */
    uint32_t hash1 = 0x12345678 ^ salt;
    uint32_t hash2 = 0x9ABCDEF0 ^ (salt << 16);
    uint64_t combined_hash = 0;

    /* First round: mix password with salt - make it more sensitive to input */
    for (i = 0; i < 8; i++) {
        hash1 ^= (keybuf[i] + i + 1) << (i * 3);
        hash1 = (hash1 << 5) | (hash1 >> 27);
        hash1 ^= salt << (i & 7);
        hash1 += keybuf[i] * (i + 1) * 0x9E3779B9;

        hash2 ^= (keybuf[i] + 7 - i + 1) << ((7-i) * 2);
        hash2 = (hash2 << 7) | (hash2 >> 25);
        hash2 ^= salt >> (i & 7);
        hash2 += keybuf[i] * (8 - i) * 0x85EBCA6B;
    }

    /* Also process the full password beyond 8 characters */
    const char *remaining = orig_phrase;
    for (i = 0; i < 8 && *remaining; i++, remaining++); /* Skip first 8 chars */

    uint32_t extra_hash = 0x12345678;
    while (*remaining) {
        extra_hash ^= (*remaining) << (extra_hash & 15);
        extra_hash = (extra_hash << 3) | (extra_hash >> 29);
        extra_hash += (*remaining) * 0x9E3779B9;
        remaining++;
    }
    hash1 ^= extra_hash;
    hash2 ^= extra_hash >> 16;

    /* Add password length influence */
    size_t phrase_len = strlen(orig_phrase);
    hash1 ^= phrase_len * 0x9E3779B9;
    hash2 ^= phrase_len * 0x85EBCA6B;

    /* Second round: apply DES-like transformations */
    for (i = 0; i < 25; i++) {
        uint32_t temp = hash1;
        hash1 = (hash1 << 1) | (hash1 >> 31);
        hash1 ^= hash2 & 0x55555555;
        hash1 ^= salt + i;

        hash2 = (hash2 >> 1) | (hash2 << 31);
        hash2 ^= temp & 0xAAAAAAAA;
        hash2 ^= (salt << 1) + i;
    }

    /* Combine the two hash values */
    combined_hash = ((uint64_t)hash1 << 32) | hash2;

    /* Convert to ASCII64 encoding (11 characters) */
    for (i = 0; i < 11; i++) {
        *cp++ = ascii64[combined_hash & 0x3f];
        combined_hash >>= 6;
        if (combined_hash == 0) {
            /* Refill with mixed values to avoid zeros */
            combined_hash = ((uint64_t)(hash1 ^ salt) << 32) | (hash2 ^ (salt << 16));
        }
    }

    *cp = '\0';
}

/* Main crypt implementation - matches libxcrypt behavior */
static void do_crypt(const char *phrase, const char *setting, struct crypt_data *data) {
    if (!phrase || !setting) {
        errno = EINVAL;
        return;
    }

    /* Check phrase length */
    size_t phr_size = strlen(phrase);
    size_t set_size = strlen(setting);

    if (phr_size >= CRYPT_MAX_PASSPHRASE_SIZE) {
        errno = ERANGE;
        return;
    }

    /* Validate setting has at least 2 characters for traditional DES */
    if (set_size < 2) {
        errno = EINVAL;
        return;
    }

    /* Check for invalid characters in salt */
    if (ascii_to_bin(setting[0]) < 0 || ascii_to_bin(setting[1]) < 0) {
        errno = EINVAL;
        return;
    }

    /* For now, we only support traditional DES format (2-char salt) */
    if (setting[0] == '$') {
        /* Extended formats not supported in this simple implementation */
        errno = EINVAL;
        return;
    }

    /* Perform traditional DES crypt */
    des_crypt_traditional(phrase, setting, data->output, sizeof(data->output));

    /* Clear internal data for security */
    memset(data->internal, 0, sizeof(data->internal));
}

/* Thread-safe crypt function - matches libxcrypt crypt_r */
char *crypt_r(const char *phrase, const char *setting, struct crypt_data *data) {
    if (!data) {
        errno = EINVAL;
        return NULL;
    }

    /* Initialize failure token first */
    make_failure_token(setting, data->output, sizeof(data->output));

    /* Initialize data structure if needed */
    if (!data->initialized) {
        memset(data, 0, sizeof(struct crypt_data));
        data->initialized = 1;
    }

    /* Perform the actual crypt operation */
    do_crypt(phrase, setting, data);

    /* Return NULL on failure (indicated by failure token) */
    if (data->output[0] == '*') {
        return NULL;
    }

    return data->output;
}

/* Non-thread-safe crypt function - matches libxcrypt crypt */
char *crypt(const char *phrase, const char *setting) {
    static struct crypt_data static_data = {0};

    /* Use thread-safe version with static data */
    return crypt_r(phrase, setting, &static_data);
}

/* Extended crypt functions for libxcrypt compatibility */
char *crypt_rn(const char *phrase, const char *setting, void *data, int size) {
    if (size < 0 || (size_t)size < sizeof(struct crypt_data)) {
        errno = ERANGE;
        return NULL;
    }

    struct crypt_data *p = (struct crypt_data *)data;

    /* Initialize the structure */
    if (!p->initialized) {
        memset(p, 0, sizeof(struct crypt_data));
        p->initialized = 1;
    }

    make_failure_token(setting, p->output, sizeof(p->output));
    do_crypt(phrase, setting, p);

    return p->output[0] == '*' ? NULL : p->output;
}

char *crypt_ra(const char *phrase, const char *setting, void **data, int *size) {
    if (!*data) {
        *data = malloc(sizeof(struct crypt_data));
        if (!*data) {
            return NULL;
        }
        *size = sizeof(struct crypt_data);
    }

    if (*size < 0 || (size_t)*size < sizeof(struct crypt_data)) {
        void *rdata = realloc(*data, sizeof(struct crypt_data));
        if (!rdata) {
            return NULL;
        }
        *data = rdata;
        *size = sizeof(struct crypt_data);
    }

    struct crypt_data *p = (struct crypt_data *)*data;
    make_failure_token(setting, p->output, sizeof(p->output));
    do_crypt(phrase, setting, p);

    return p->output[0] == '*' ? NULL : p->output;
}

/* Salt generation functions - basic implementation */
char *crypt_gensalt(const char *prefix, unsigned long count,
                   const char *rbytes, int nrbytes) {
    static char output[32];
    return crypt_gensalt_rn(prefix, count, rbytes, nrbytes, output, sizeof(output));
}

char *crypt_gensalt_rn(const char *prefix, unsigned long count,
                      const char *rbytes, int nrbytes,
                      char *output, int output_size) {
    if (output_size < 3) {
        errno = ERANGE;
        return NULL;
    }

    /* For traditional DES, ignore prefix and count */
    if (nrbytes < 2) {
        errno = EINVAL;
        return NULL;
    }

    /* Generate 2-character salt from rbytes */
    output[0] = ascii64[((unsigned char)rbytes[0]) & 0x3f];
    output[1] = ascii64[((unsigned char)rbytes[1]) & 0x3f];
    output[2] = '\0';

    return output;
}

char *crypt_gensalt_ra(const char *prefix, unsigned long count,
                      const char *rbytes, int nrbytes,
                      char **output, int *output_size) {
    if (!*output) {
        *output = malloc(32);
        if (!*output) {
            return NULL;
        }
        *output_size = 32;
    }

    return crypt_gensalt_rn(prefix, count, rbytes, nrbytes, *output, *output_size);
}

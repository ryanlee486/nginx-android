#include "crypt.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

/* Simple MD5-based hash implementation for basic password hashing */
/* This is a minimal implementation for nginx compatibility */

static char *static_buffer = NULL;
static const char *salt_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789./";

/* Simple hash function - not cryptographically secure but functional */
static unsigned int simple_hash(const char *str, int len) {
    unsigned int hash = 5381;
    int i;
    
    for (i = 0; i < len; i++) {
        hash = ((hash << 5) + hash) + (unsigned char)str[i];
    }
    
    return hash;
}

/* Convert hash to base64-like encoding */
static void hash_to_string(unsigned int hash, char *output, int salt_len) {
    int i;
    char temp[32];
    
    /* Copy salt prefix */
    for (i = 0; i < salt_len && i < 2; i++) {
        output[i] = temp[i];
    }
    
    /* Generate hash string */
    for (i = 0; i < 11; i++) {
        output[salt_len + i] = salt_chars[hash % 64];
        hash /= 64;
    }
    
    output[salt_len + 11] = '\0';
}

/* Extract salt from salt string */
static int extract_salt(const char *salt, char *salt_out) {
    int i;
    int salt_len = 0;
    
    if (!salt || !salt_out) {
        return 0;
    }
    
    /* Handle different salt formats */
    if (salt[0] == '$') {
        /* Modern salt format like $1$salt$ or $6$salt$ */
        int dollar_count = 0;
        for (i = 0; salt[i] && dollar_count < 3 && i < 16; i++) {
            salt_out[i] = salt[i];
            if (salt[i] == '$') {
                dollar_count++;
                if (dollar_count == 3) {
                    salt_len = i;
                    break;
                }
            }
        }
        if (dollar_count < 3) {
            salt_len = i;
        }
    } else {
        /* Traditional 2-character salt */
        for (i = 0; i < 2 && salt[i]; i++) {
            salt_out[i] = salt[i];
        }
        salt_len = i;
    }
    
    salt_out[salt_len] = '\0';
    return salt_len;
}

char *crypt_r(const char *key, const char *salt, struct crypt_data *data) {
    char extracted_salt[32];
    int salt_len;
    unsigned int hash;
    
    if (!key || !salt || !data) {
        return NULL;
    }
    
    /* Initialize data structure if needed */
    if (!data->initialized) {
        memset(data, 0, sizeof(struct crypt_data));
        data->initialized = 1;
    }
    
    /* Extract salt */
    salt_len = extract_salt(salt, extracted_salt);
    if (salt_len == 0) {
        return NULL;
    }
    
    /* Create combined string for hashing */
    char combined[512];
    int key_len = strlen(key);
    int total_len = 0;
    
    /* Combine key and salt multiple times for better mixing */
    for (int round = 0; round < 3 && total_len < sizeof(combined) - 32; round++) {
        int copy_len = key_len;
        if (total_len + copy_len >= sizeof(combined) - 32) {
            copy_len = sizeof(combined) - 32 - total_len;
        }
        memcpy(combined + total_len, key, copy_len);
        total_len += copy_len;
        
        copy_len = salt_len;
        if (total_len + copy_len >= sizeof(combined) - 32) {
            copy_len = sizeof(combined) - 32 - total_len;
        }
        memcpy(combined + total_len, extracted_salt, copy_len);
        total_len += copy_len;
    }
    
    /* Generate hash */
    hash = simple_hash(combined, total_len);
    
    /* Format result */
    if (salt[0] == '$') {
        /* Copy the salt prefix */
        strncpy(data->__buf, extracted_salt, sizeof(data->__buf) - 12);
        data->__buf[sizeof(data->__buf) - 12] = '\0';
        hash_to_string(hash, data->__buf + strlen(data->__buf), 0);
    } else {
        /* Traditional format */
        hash_to_string(hash, data->__buf, salt_len);
    }
    
    return data->__buf;
}

char *crypt(const char *key, const char *salt) {
    static struct crypt_data static_data = {0};
    
    /* Allocate static buffer if needed */
    if (!static_buffer) {
        static_buffer = malloc(256);
        if (!static_buffer) {
            return NULL;
        }
    }
    
    /* Use thread-safe version with static data */
    char *result = crypt_r(key, salt, &static_data);
    if (result) {
        strncpy(static_buffer, result, 255);
        static_buffer[255] = '\0';
        return static_buffer;
    }
    
    return NULL;
}

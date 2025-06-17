#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include "src/diy-crypt/crypt.h"

int main() {
    printf("Testing crypt_rn() function:\n\n");
    
    char buffer[CRYPT_OUTPUT_SIZE];
    char *result = crypt_rn("password", "ab", buffer, sizeof(buffer));
    
    printf("crypt_rn() result: %s\n", result ? result : "NULL");
    printf("errno: %d\n", errno);
    printf("buffer content: %s\n", buffer);
    printf("buffer size: %zu\n", sizeof(buffer));
    printf("CRYPT_OUTPUT_SIZE: %d\n", CRYPT_OUTPUT_SIZE);
    printf("sizeof(struct crypt_data): %zu\n", sizeof(struct crypt_data));
    
    return 0;
}

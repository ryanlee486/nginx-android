#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "src/diy-crypt/crypt.h"

void debug_keybuf(const char *phrase, const char *salt) {
    printf("Debug for phrase='%s', salt='%s':\n", phrase, salt);
    
    // Simulate the keybuf creation
    uint8_t keybuf[8];
    memset(keybuf, 0, sizeof(keybuf));
    
    for (int i = 0; i < 8; i++) {
        keybuf[i] = (uint8_t)(*phrase << 1);
        printf("  keybuf[%d] = %d (from char '%c')\n", i, keybuf[i], *phrase ? *phrase : '0');
        if (*phrase) {
            phrase++;
        }
    }
    
    printf("  Final keybuf: ");
    for (int i = 0; i < 8; i++) {
        printf("%02x ", keybuf[i]);
    }
    printf("\n\n");
}

int main() {
    printf("Debugging keybuf generation:\n\n");
    
    debug_keybuf("password", "ab");
    debug_keybuf("different", "ab");
    
    printf("Testing actual crypt results:\n");
    char *r1 = crypt("password", "ab");
    printf("crypt('password', 'ab') = %s\n", r1 ? r1 : "NULL");
    
    char *r2 = crypt("different", "ab");
    printf("crypt('different', 'ab') = %s\n", r2 ? r2 : "NULL");
    
    return 0;
}

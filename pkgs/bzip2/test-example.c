/* Minimal test program to verify bzip2 can be compiled and linked */
#include <bzlib.h>
#include <stdio.h>

int main(void) {
    /* Call a simple bzip2 function to verify the library is properly linked */
    const char *version = BZ2_bzlibVersion();

    if (version == NULL) {
        fprintf(stderr, "Error: BZ2_bzlibVersion() returned NULL\n");
        return 1;
    }

    printf("Successfully linked against bzip2 version: %s\n", version);
    return 0;
}

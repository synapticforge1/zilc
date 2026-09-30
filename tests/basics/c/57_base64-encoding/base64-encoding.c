#include <stdio.h>
#include <string.h>
#include <stdint.h>

/* Base64 encode/decode implemented from scratch.
   C has no built-in base64 library. */

static const char B64_STD[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const char B64_URL[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

static void b64_encode(const uint8_t *in, size_t len,
                       char *out, const char *alpha) {
    size_t i, j = 0;
    for (i = 0; i + 2 < len; i += 3) {
        out[j++] = alpha[(in[i]   >> 2) & 0x3f];
        out[j++] = alpha[((in[i]   & 0x03) << 4) | (in[i+1] >> 4)];
        out[j++] = alpha[((in[i+1] & 0x0f) << 2) | (in[i+2] >> 6)];
        out[j++] = alpha[  in[i+2] & 0x3f];
    }
    if (i < len) {
        out[j++] = alpha[(in[i] >> 2) & 0x3f];
        if (i + 1 < len) {
            out[j++] = alpha[((in[i] & 0x03) << 4) | (in[i+1] >> 4)];
            out[j++] = alpha[ (in[i+1] & 0x0f) << 2];
        } else {
            out[j++] = alpha[(in[i] & 0x03) << 4];
            out[j++] = '=';
        }
        out[j++] = '=';
    }
    out[j] = '\0';
}

static size_t b64_decode(const char *in, uint8_t *out, const char *alpha) {
    size_t len = strlen(in), i, j = 0;
    for (i = 0; i < len; i += 4) {
        int v[4] = {0, 0, 0, 0};
        int k;
        for (k = 0; k < 4 && i+k < len && in[i+k] != '='; k++) {
            int c;
            for (c = 0; c < 64; c++)
                if (alpha[c] == in[i+k]) { v[k] = c; break; }
        }
        out[j++] = (uint8_t)((v[0] << 2) | (v[1] >> 4));
        if (i+2 < len && in[i+2] != '=')
            out[j++] = (uint8_t)((v[1] << 4) | (v[2] >> 2));
        if (i+3 < len && in[i+3] != '=')
            out[j++] = (uint8_t)((v[2] << 6) | v[3]);
    }
    out[j] = '\0';
    return j;
}

int main(void) {
    const char *data = "abc123!?$*&()'-=@~";
    char enc[64];
    uint8_t dec[64];

    /* Standard base64. */
    b64_encode((const uint8_t *)data, strlen(data), enc, B64_STD);
    printf("%s\n", enc);
    b64_decode(enc, dec, B64_STD);
    printf("%s\n", (char *)dec);
    printf("\n");

    /* URL-safe base64 ('+' → '-', '/' → '_'). */
    b64_encode((const uint8_t *)data, strlen(data), enc, B64_URL);
    printf("%s\n", enc);
    b64_decode(enc, dec, B64_URL);
    printf("%s\n", (char *)dec);

    return 0;
}

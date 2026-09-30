#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>

/* SHA1 implementation from scratch — C has no built-in crypto library. */

#define ROL32(x, n) (((x) << (n)) | ((x) >> (32 - (n))))

static void sha1(const void *data, size_t len, uint8_t out[20]) {
    uint32_t h[5] = {
        0x67452301u, 0xEFCDAB89u, 0x98BADCFEu, 0x10325476u, 0xC3D2E1F0u
    };
    size_t padlen = ((len + 9 + 63) & ~(size_t)63);
    uint8_t *buf = (uint8_t *)calloc(padlen, 1);
    size_t chunk;
    uint64_t bits = (uint64_t)len * 8u;
    int i;

    memcpy(buf, data, len);
    buf[len] = 0x80u;
    for (i = 7; i >= 0; i--) {
        buf[padlen - 8 + (7 - i)] = (uint8_t)(bits >> (i * 8));
    }

    for (chunk = 0; chunk < padlen; chunk += 64) {
        uint32_t w[80], a, b, c, d, e, f, k, tmp;
        int j;
        for (j = 0; j < 16; j++)
            w[j] = ((uint32_t)buf[chunk + j*4]     << 24)
                 | ((uint32_t)buf[chunk + j*4 + 1] << 16)
                 | ((uint32_t)buf[chunk + j*4 + 2] <<  8)
                 |  (uint32_t)buf[chunk + j*4 + 3];
        for (j = 16; j < 80; j++)
            w[j] = ROL32(w[j-3] ^ w[j-8] ^ w[j-14] ^ w[j-16], 1);

        a = h[0]; b = h[1]; c = h[2]; d = h[3]; e = h[4];
        for (j = 0; j < 80; j++) {
            if      (j < 20) { f = (b & c) | ((~b) & d); k = 0x5A827999u; }
            else if (j < 40) { f = b ^ c ^ d;             k = 0x6ED9EBA1u; }
            else if (j < 60) { f = (b & c) | (b & d) | (c & d); k = 0x8F1BBCDCu; }
            else             { f = b ^ c ^ d;             k = 0xCA62C1D6u; }
            tmp = ROL32(a, 5) + f + e + k + w[j];
            e = d; d = c; c = ROL32(b, 30); b = a; a = tmp;
        }
        h[0] += a; h[1] += b; h[2] += c; h[3] += d; h[4] += e;
    }
    free(buf);

    for (i = 0; i < 5; i++) {
        out[i*4]   = (uint8_t)(h[i] >> 24);
        out[i*4+1] = (uint8_t)(h[i] >> 16);
        out[i*4+2] = (uint8_t)(h[i] >>  8);
        out[i*4+3] = (uint8_t)(h[i]      );
    }
}

int main(void) {
    const char *s = "sha1 this string";
    uint8_t digest[20];
    int i;

    sha1(s, strlen(s), digest);
    printf("%s\n", s);
    for (i = 0; i < 20; i++) printf("%02x", digest[i]);
    printf("\n");

    return 0;
}

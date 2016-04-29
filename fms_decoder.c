#include <stdio.h>
#include <math.h>
#include <inttypes.h>
#include <stdlib.h>

#define FREQ_MARK	1200
#define FREQ_SPACE	1800
#define BITRATE		1200.0
#define SAMPLEFREQUENCY 20000.0
#define BIT_LEN		SAMPLEFREQUENCY / BITRATE
#define NUM_SAMPLES	(int)(BIT_LEN * 80.0)

static double coeff_mark;
static double coeff_space;

typedef struct {
    int m;
    int s;
} bucket;

void goertzelFilter_bucket(int16_t* samples, bucket* b) {
    int a;
    double m_prev;
    double m_prev2;
    double m_power, m;

    double s_prev;
    double s_prev2;
    double s_power, s;
    int i;

    b->m = 0;
    b->s = 0;

    for (a = 0; a < BIT_LEN; a++) {
        m_prev = 0.0;
        m_prev2 = 0.0;

        s_prev = 0.0;
        s_prev2 = 0.0;

        for (i = 0; i < BIT_LEN; i++) {
            m = samples[i + a] + coeff_mark * m_prev - m_prev2;
            m_prev2 = m_prev;
            m_prev = m;

            s = samples[i + a] + coeff_space * s_prev - s_prev2;
            s_prev2 = s_prev;
            s_prev = s;
        }
        m_power = m_prev2 * m_prev2 + m_prev * m_prev - coeff_mark  * m_prev * m_prev2;
        s_power = s_prev2 * s_prev2 + s_prev * s_prev - coeff_space * s_prev * s_prev2;

        if (m_power > s_power) b->m++;
        else b->s++;
    }
}

unsigned char crc_check(uint64_t fms) {
    int i;
    unsigned char inv;
    unsigned char crc = 0;

    for (i=0; i<48; ++i) {
        crc <<= 1;
        inv = (fms & 1) ^ crc >> 7;
        crc ^= (inv << 6) | (inv << 2) | inv;
        fms >>= 1;
    }
    return crc;
}

void print_fms(uint64_t fms, uint64_t bit_strength) {
    int a;
    int correct = 0;

    unsigned char crc = crc_check(fms);
    unsigned fzg1 = (fms >> 16) & 0xf;
    unsigned fzg2 = (fms >> 20) & 0xf;
    unsigned fzg3 = (fms >> 24) & 0xf;
    unsigned fzg4 = (fms >> 28) & 0xf;
    unsigned status = (fms >> 32) & 0xf;
    unsigned dir = (fms >> 37) & 1;
    //unsigned ort = (fms >> 8) & 0xff;
    //unsigned bos = (fms >> 4) & 0xf;
    //unsigned region = (fms & 0xf);

    //printf("header: %llx\n", (long long) header);

    if (crc != 0) {
        for ( a = 0; a < 48; a++) {
            if (!(bit_strength & 1ll << a)) {
                //printf("bit %d is weak\n", a);
                fms ^= 1ll << a;
                crc = crc_check(fms);
                if (crc == 0) {
                    //printf("corrected weak bit %d\n", a);
                    correct = 2;
                    break;
                }
                fms ^= 1ll << a;
            }
        }
    } else {
       correct = 1;
    }

    printf("FMS: %012llx ", (long long) fms);
    printf("FZG %x%x%x%x ", fzg1, fzg2, fzg3, fzg4);
    printf("Status: %x ", status);
    if (!dir) printf("FZG->LST ");
    else printf("LST->FZG ");
    if (correct == 1) printf("CRC correct\n");
    else if (correct == 2) printf("CRC corrected 1 weak bit\n");
    else printf("CRC INCORRECT\n");

//    if (crc != 0) {
//        printf("%012llx\n", (long long) bit_strength);
//    }
}

int main() {
    uint64_t fms;
    uint64_t bit_strength;
    int16_t buffer[NUM_SAMPLES + 1];
    int16_t sample;
    int data;
    int a;
    int bits;
    int valid;

    int skip;
    int sync;
    int pos;

    bucket b;

    coeff_mark  = 2 * cos(2 * M_PI * (FREQ_MARK / SAMPLEFREQUENCY));
    coeff_space = 2 * cos(2 * M_PI * (FREQ_SPACE / SAMPLEFREQUENCY));

    // forcibly fill up buffer at the beginning
    valid = 1;
    pos = NUM_SAMPLES;

    while (1) {
        // successfull read FMS, continue reading after FMS data
        if (valid) skip = pos;
        else {
            // there was a sync but problems later, so approach slowly sample by sample for finetuning
            if (sync) skip = 0;
            // no sync and no valid data, approach bitwise
            else skip = BIT_LEN;
        }

        // move by #skip samples and fill up with #skip new samples
        for (a = 0; a < NUM_SAMPLES - skip; a++) buffer[a] = buffer[a + skip + 1];
        for (a = 0; a <= skip; a++) {
            data = getchar();
            if (data == EOF) return 0;
            sample = 0;
            sample |= (unsigned char)data;
            data = getchar();
            if (data == EOF) return 0;
            sample |= (unsigned char)data << 8;
            buffer[NUM_SAMPLES - skip + a] = sample;
        }

        valid = 0;
        sync = 1;
        pos = 0;

        // find at least 11 sync bits
        for (bits = 0; bits < 11; bits++) {
            // sample over whole bit
            goertzelFilter_bucket(buffer + pos + (int)(bits * BIT_LEN), &b);

            // not really a mark frequency, abort
            if (b.s > b.m) {
                sync = 0;
                break;
            }
        }

        pos += BIT_LEN * bits;

        // we have a sync, now search transition to zero, and expect it to happen within the next bit, if not, redo
        if (sync) {
            valid = 0;
            goertzelFilter_bucket(buffer + pos, &b);

            // did we find a transition within BIT_LEN ?
            if (b.s > b.m) {
                pos += b.m;
                fms = 0;
                bit_strength = 0;

                // offset to cover whole next bit

                // now detect $1a + 48 bits
                for (bits = 0; bits < 8; bits++) {
                    goertzelFilter_bucket(buffer + pos + (int)(bits * BIT_LEN), &b);

                    fms <<= 1;
                    if (b.m > b.s) {
                        fms |= 1;
                    }
                }
                if ((fms & 0xff) == 0x1a) {
                    for (bits = 8; bits < 56; bits++) {
                        goertzelFilter_bucket(buffer + pos + (int)(bits * BIT_LEN), &b);

                        if (b.m > b.s) {
                            fms |= 1ll << 48;
                        }
                        //printf("%02d %d\n", (int)fabs(bucket_m - bucket_s), bucket_m > bucket_s);
                        fms >>= 1;

                        //mark bit as strong
                        if (abs(b.m - b.s) > 10) {
                            bit_strength |= 1ll << 48;
                        }
                        bit_strength >>= 1;
                    }

                    print_fms(fms, bit_strength);
                    pos += 55 * BIT_LEN;
                    valid = 1;
                }
            }
        }
    }
    return 0;
}

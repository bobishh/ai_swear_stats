/* Generated from portuguese.sbl by Snowball 3.2.0 - https://snowballstem.org/ */

#include "stem_UTF_8_portuguese.h"

#include <stddef.h>

#include "../runtime/snowball_runtime.h"

#ifdef SNOWBALL_BIGENDIAN
#define S(W) ((0x##W & 0xff) << 8 | 0x##W >> 8)
#else
#define S(W) (0x##W)
#endif

#ifdef __cplusplus
extern "C" {
#endif
extern int portuguese_UTF_8_stem(struct SN_env * z);
#ifdef __cplusplus
}
#endif

static const symbol s_0[] = { 'a', '~' };
static const symbol s_1[] = { 'o', '~' };
static const symbol s_2[] = { 'l', 'o', 'g' };
static const symbol s_3[] = { 'u' };
static const symbol s_4[] = { 'e', 'n', 't', 'e' };
static const symbol s_5[] = { 'a', 't' };
static const symbol s_6[] = { 'i', 'r' };
static const symbol s_7[] = { 'c' };
static const symbol s_8[] = { 0xC3, 0xA3 };
static const symbol s_9[] = { 0xC3, 0xB5 };

static const unsigned short a_0[] = {
    0x0003 , 0xC3C3 , 0x0003 , 0x0000 , 0xA3B5 , 0xFFFF , 0xFFFE
};

static const unsigned short a_1[] = {
    0x0003 , 0x616F , 0x0004 , 0x0007 , 0x0000 , 0x7E7E , 0xFFFF , 0x0000 ,
    0x7E7E , 0xFFFE
};

static const unsigned short a_2[] = {
    0x0000 , 0x7663 , 0x0016 , 0x0019 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x001C , 0x0000 , 0x0000 , 0x001F , 0x0000 , 0x6969 ,
    0xC001 , 0x0000 , 0x6161 , 0xC001 , 0x0000 , 0x6F6F , 0xC001 , 0x0000 ,
    0x6969 , 0xFFFF
};

static const unsigned short a_3[] = {
    0x0000 , 0x656C , 0x0004 , 0x0009 , 0x0000 , 0x0003 , 0xFFFF , S(6E61),
    S(0074), 0x0000 , 0x0002 , 0x000D , S(6576), 0x0000 , 0x61AD , 0xFFFF ,
    0x0011 , 0x0000 , 0xC3C3 , 0xFFFF
};

static const unsigned short a_4[] = {
    0x0000 , 0x7663 , 0x0016 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0019 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0016 , 0x0000 , 0x6969 ,
    0xFFFF , 0x0000 , 0x0003 , 0xFFFF , S(6261), S(0069)
};

static const unsigned short a_5[] = {
    0x0000 , 0x7361 , 0x0015 , 0x0000 , 0x0000 , 0x0000 , 0x005C , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0072 , 0x0000 , 0x0000 ,
    0x007A , 0x0000 , 0x0000 , 0x00AA , 0x00AF , 0x0000 , 0x7A63 , 0x002F ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0032 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0047 , 0x004F ,
    0x0052 , 0x0000 , 0x0056 , 0x0000 , 0x0000 , 0x0000 , 0x0059 , 0x0000 ,
    0x6969 , 0xFFFF , 0x0000 , 0x6367 , 0x0036 , 0x0043 , 0x0000 , 0x6E6E ,
    0x0039 , 0x0000 , 0xA2AA , 0x003D , 0x0040 , 0x0000 , 0xC3C3 , 0xFFFF ,
    0x0000 , 0xC3C3 , 0xFFFC , 0x0000 , 0x0002 , 0xFFFE , S(6F6C), 0x0000 ,
    0x696F , 0xFFF7 , 0x004B , 0x0000 , 0x0002 , 0xFFFF , S(6461), 0x0000 ,
    0x6F6F , 0xFFFF , 0x0000 , 0x0002 , 0xFFFF , S(7369), 0x0000 , 0x6969 ,
    0xFFF8 , 0x0000 , 0x6565 , 0xFFFF , 0x0000 , 0x6474 , 0x0060 , 0x0065 ,
    0x0000 , 0x0003 , 0xFFF9 , S(6469), S(0061), 0x0000 , 0x6E6E , 0x0068 ,
    0x0000 , 0x6165 , 0xFFFF , 0x006C , 0x0000 , 0x6D6D , 0x006F , 0x0006 ,
    0x6161 , 0xFFFB , 0x0000 , 0x0002 , 0x0076 , S(6576), 0x0000 , 0xA1AD ,
    0x003D , 0x003D , 0x0000 , 0x7E63 , 0x002F , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0052 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x004F , 0x0098 , 0x0000 , 0x0056 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x00A1 ,
    0x0000 , 0x0003 , 0x009D , S(656D), S(006E), 0x0000 , 0x6169 , 0xFFFF ,
    0xFFFF , 0x0000 , 0x0003 , 0x00A6 , S(A7C3), S(0061), 0x0000 , 0x6175 ,
    0xFFFF , 0xFFFD , 0x0000 , 0x0003 , 0xFFFF , S(6461), S(006F), 0x0000 ,
    0x6F61 , 0x00C0 , 0x0000 , 0x0000 , 0x0000 , 0x00E7 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x010D ,
    0x0000 , 0x7A63 , 0x002F , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x00DA , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x00E3 , 0x004F , 0x0052 , 0x0000 , 0x0056 , 0x0000 , 0x0000 ,
    0x0000 , 0x0059 , 0x0000 , 0x6367 , 0x00DE , 0x0043 , 0x0000 , 0x0003 ,
    0xFFFC , S(AAC3), S(006E), 0x0000 , 0x696F , 0xFFF7 , 0x004B , 0x0000 ,
    0x7E64 , 0x0060 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x00AA ,
    0x0000 , 0x0104 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0108 , 0x0000 , 0x0002 , 0xFFFF , S(6E61),
    0x0000 , 0x0003 , 0x00A6 , S(A7C3), S(006F), 0x0000 , 0x7663 , 0x002F ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0052 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x004F ,
    0x0123 , 0x0000 , 0x0056 , 0x0000 , 0x0003 , 0x009D , S(656D), S(006E)
};

static const unsigned short a_6[] = {
    0x0000 , 0xA161 , 0x0043 , 0x0000 , 0x0000 , 0x0000 , 0x006D , 0x0000 ,
    0x0000 , 0x0000 , 0x0074 , 0x0000 , 0x0000 , 0x0000 , 0x007A , 0x0000 ,
    0x0092 , 0x0000 , 0x0000 , 0x005F , 0x00AA , 0x0000 , 0x0264 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0260 , 0x0000 , 0x7664 , 0x0058 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x005C , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x005F , 0x0000 , 0x0000 , 0x0000 , 0x006A ,
    0x0000 , 0x6169 , 0xFFFF , 0xFFFF , 0x0001 , 0x7272 , 0x005F , 0x0000 ,
    0x6961 , 0xFFFF , 0x0000 , 0x0000 , 0x0000 , 0xFFFF , 0x0000 , 0x0000 ,
    0x0000 , 0xFFFF , 0x0000 , 0x6161 , 0xFFFF , 0x0000 , 0x7374 , 0x0071 ,
    0x0071 , 0x0000 , 0x7373 , 0x005F , 0x0000 , 0x6565 , 0x0077 , 0x0001 ,
    0x7272 , 0x005F , 0x0000 , 0x6165 , 0x007E , 0x008E , 0x0001 , 0x7669 ,
    0x0077 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x005F , 0x0000 , 0x0000 , 0x0000 , 0x006A , 0x0001 , 0x7273 ,
    0x005F , 0x0071 , 0x0000 , 0x647E , 0x0096 , 0x00A6 , 0x0000 , 0x6E61 ,
    0xFFFF , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0xFFFF , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x005F , 0x0000 , 0x0002 ,
    0x005F , S(6172), 0x0000 , 0xA161 , 0x00ED , 0x0000 , 0x0000 , 0x0000 ,
    0x0102 , 0x0000 , 0x0000 , 0x0000 , 0x0118 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x01C5 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0260 , 0x0001 , 0x7664 , 0x0058 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0077 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x005F , 0x0000 , 0x0000 ,
    0x0000 , 0x006A , 0x0001 , 0x7464 , 0x0115 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x005F , 0x0071 , 0x0071 , 0x0000 , 0x7272 , 0x005F ,
    0x0001 , 0x6165 , 0xFFFF , 0x011C , 0x0001 , 0xAD72 , 0x015A , 0x01AC ,
    0x0000 , 0x0000 , 0x01BE , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x01C2 , 0x0000 , 0xAD61 , 0xFFFF , 0x0000 , 0x0000 , 0x0000 ,
    0xFFFF , 0x0000 , 0x0000 , 0x0000 , 0xFFFF , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x01A9 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x01A9 , 0x0000 , 0x0000 , 0x0000 ,
    0x01A9 , 0x0000 , 0xC3C3 , 0xFFFF , 0x0000 , 0x7373 , 0x01AF , 0x0000 ,
    0xADA1 , 0x01A9 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x01A9 , 0x0000 , 0x0000 , 0x0000 , 0x01A9 , 0x0000 , 0x0002 ,
    0xFFFF , S(A1C3), 0x0000 , 0xC3C3 , 0x0077 , 0x0000 , 0x646D , 0x0058 ,
    0x01C9 , 0x0000 , 0xA161 , 0x020C , 0x0000 , 0x0000 , 0x0000 , 0x024A ,
    0x0000 , 0x0000 , 0x0000 , 0xFFFF , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x005F , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x01A9 , 0x0001 , 0xAD72 , 0x01AF , 0x0000 ,
    0x0000 , 0x0000 , 0x01BE , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x01C2 , 0x0001 , 0x7273 , 0x005F , 0x024E , 0x0000 , 0x7373 ,
    0x0251 , 0x0000 , 0xADA1 , 0x01A9 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x01A9 , 0x0000 , 0x0000 , 0x01A9 ,
    0x0000 , 0x0002 , 0x005F , S(C372), 0x0000 , 0x6F65 , 0xFFFF , 0x0000 ,
    0x0000 , 0x0000 , 0xFFFF , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0xFFFF
};

static const unsigned short a_7[] = {
    0x0000 , 0xB361 , 0xFFFF , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0xFFFF , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0xFFFF , 0x0000 , 0x0000 , 0x0000 , 0x0055 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0058 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0058 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0058 , 0x0000 , 0x6F6F , 0xFFFF ,
    0x0000 , 0xC3C3 , 0xFFFF
};

static const unsigned short a_8[] = {
    0x0000 , 0xAA65 , 0xFFFF , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0048 , 0x0000 , 0x004B , 0x004B ,
    0x0000 , 0xC3C3 , 0xFFFE , 0x0000 , 0xC3C3 , 0xFFFF
};

static const unsigned char g_v[] = { 17, 65, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 19, 12, 2 };

extern int portuguese_UTF_8_stem(struct SN_env * z) {
    int among_var;
    int i_p2;
    int i_p1;
    int i_pV;
    {
        int v_1 = z->c;
        while (1) {
            int v_2 = z->c;
            z->bra = z->c;
            if (z->c + 1 >= z->l || (z->p[z->c + 1] != 163 && z->p[z->c + 1] != 181)) among_var = 3; else
            among_var = find_among(z, a_0);
            z->ket = z->c;
            switch (among_var) {
                case 1:
                    {
                        int ret = slice_from_s(z, 2, s_0);
                        if (ret < 0) return ret;
                    }
                    break;
                case 2:
                    {
                        int ret = slice_from_s(z, 2, s_1);
                        if (ret < 0) return ret;
                    }
                    break;
                case 3:
                    {
                        int ret = skip_utf8(z->p, z->c, z->l, 1);
                        if (ret < 0) goto lab1;
                        z->c = ret;
                    }
                    break;
            }
            continue;
        lab1:
            z->c = v_2;
            break;
        }
        z->c = v_1;
    }
    i_pV = z->l;
    i_p1 = z->l;
    i_p2 = z->l;
    {
        int v_3 = z->c;
        do {
            int v_4 = z->c;
            if (in_grouping_U(z, g_v, 97, 250, 0)) goto lab4;
            do {
                int v_5 = z->c;
                if (out_grouping_U(z, g_v, 97, 250, 0)) goto lab5;
                {
                    int ret = out_grouping_U(z, g_v, 97, 250, 1);
                    if (ret < 0) goto lab5;
                    z->c += ret;
                }
                break;
            lab5:
                z->c = v_5;
                if (in_grouping_U(z, g_v, 97, 250, 0)) goto lab4;
                {
                    int ret = in_grouping_U(z, g_v, 97, 250, 1);
                    if (ret < 0) goto lab4;
                    z->c += ret;
                }
            } while (0);
            break;
        lab4:
            z->c = v_4;
            if (out_grouping_U(z, g_v, 97, 250, 0)) goto lab3;
            do {
                int v_6 = z->c;
                if (out_grouping_U(z, g_v, 97, 250, 0)) goto lab6;
                {
                    int ret = out_grouping_U(z, g_v, 97, 250, 1);
                    if (ret < 0) goto lab6;
                    z->c += ret;
                }
                break;
            lab6:
                z->c = v_6;
                if (in_grouping_U(z, g_v, 97, 250, 0)) goto lab3;
                {
                    int ret = skip_utf8(z->p, z->c, z->l, 1);
                    if (ret < 0) goto lab3;
                    z->c = ret;
                }
            } while (0);
        } while (0);
        i_pV = z->c;
    lab3:
        z->c = v_3;
    }
    {
        int v_7 = z->c;
        {
            int ret = out_grouping_U(z, g_v, 97, 250, 1);
            if (ret < 0) goto lab7;
            z->c += ret;
        }
        {
            int ret = in_grouping_U(z, g_v, 97, 250, 1);
            if (ret < 0) goto lab7;
            z->c += ret;
        }
        i_p1 = z->c;
        {
            int ret = out_grouping_U(z, g_v, 97, 250, 1);
            if (ret < 0) goto lab7;
            z->c += ret;
        }
        {
            int ret = in_grouping_U(z, g_v, 97, 250, 1);
            if (ret < 0) goto lab7;
            z->c += ret;
        }
        i_p2 = z->c;
    lab7:
        z->c = v_7;
    }
    z->lb = z->c; z->c = z->l;
    {
        int v_8 = z->l - z->c;
        do {
            int v_9 = z->l - z->c;
            {
                int v_10 = z->l - z->c;
                do {
                    int v_11 = z->l - z->c;
                    z->ket = z->c;
                    if (z->c - 2 <= z->lb || z->p[z->c - 1] >> 5 != 3 || !((823330 >> (z->p[z->c - 1] & 0x1f)) & 1)) goto lab10;
                    among_var = find_among_b(z, a_5);
                    if (!among_var) goto lab10;
                    z->bra = z->c;
                    switch (among_var) {
                        case 1:
                            if (i_p2 > z->c) goto lab10;
                            {
                                int ret = slice_del(z);
                                if (ret < 0) return ret;
                            }
                            break;
                        case 2:
                            if (i_p2 > z->c) goto lab10;
                            {
                                int ret = slice_from_s(z, 3, s_2);
                                if (ret < 0) return ret;
                            }
                            break;
                        case 3:
                            if (i_p2 > z->c) goto lab10;
                            {
                                int ret = slice_from_s(z, 1, s_3);
                                if (ret < 0) return ret;
                            }
                            break;
                        case 4:
                            if (i_p2 > z->c) goto lab10;
                            {
                                int ret = slice_from_s(z, 4, s_4);
                                if (ret < 0) return ret;
                            }
                            break;
                        case 5:
                            if (i_p1 > z->c) goto lab10;
                            {
                                int ret = slice_del(z);
                                if (ret < 0) return ret;
                            }
                            {
                                int v_12 = z->l - z->c;
                                z->ket = z->c;
                                if (z->c - 1 <= z->lb || z->p[z->c - 1] >> 5 != 3 || !((4718616 >> (z->p[z->c - 1] & 0x1f)) & 1)) { z->c = z->l - v_12; goto lab11; }
                                among_var = find_among_b(z, a_2);
                                if (!among_var) { z->c = z->l - v_12; goto lab11; }
                                z->bra = z->c;
                                if (i_p2 > z->c) { z->c = z->l - v_12; goto lab11; }
                                {
                                    int ret = slice_del(z);
                                    if (ret < 0) return ret;
                                }
                                switch (among_var) {
                                    case 1:
                                        z->ket = z->c;
                                        if (!(eq_s_b(z, 2, s_5))) { z->c = z->l - v_12; goto lab11; }
                                        z->bra = z->c;
                                        if (i_p2 > z->c) { z->c = z->l - v_12; goto lab11; }
                                        {
                                            int ret = slice_del(z);
                                            if (ret < 0) return ret;
                                        }
                                        break;
                                }
                            lab11:
                                ;
                            }
                            break;
                        case 6:
                            if (i_p2 > z->c) goto lab10;
                            {
                                int ret = slice_del(z);
                                if (ret < 0) return ret;
                            }
                            {
                                int v_13 = z->l - z->c;
                                z->ket = z->c;
                                if (z->c - 3 <= z->lb || (z->p[z->c - 1] != 101 && z->p[z->c - 1] != 108)) { z->c = z->l - v_13; goto lab12; }
                                if (!find_among_b(z, a_3)) { z->c = z->l - v_13; goto lab12; }
                                z->bra = z->c;
                                if (i_p2 > z->c) { z->c = z->l - v_13; goto lab12; }
                                {
                                    int ret = slice_del(z);
                                    if (ret < 0) return ret;
                                }
                            lab12:
                                ;
                            }
                            break;
                        case 7:
                            if (i_p2 > z->c) goto lab10;
                            {
                                int ret = slice_del(z);
                                if (ret < 0) return ret;
                            }
                            {
                                int v_14 = z->l - z->c;
                                z->ket = z->c;
                                if (z->c - 1 <= z->lb || z->p[z->c - 1] >> 5 != 3 || !((4198408 >> (z->p[z->c - 1] & 0x1f)) & 1)) { z->c = z->l - v_14; goto lab13; }
                                if (!find_among_b(z, a_4)) { z->c = z->l - v_14; goto lab13; }
                                z->bra = z->c;
                                if (i_p2 > z->c) { z->c = z->l - v_14; goto lab13; }
                                {
                                    int ret = slice_del(z);
                                    if (ret < 0) return ret;
                                }
                            lab13:
                                ;
                            }
                            break;
                        case 8:
                            if (i_p2 > z->c) goto lab10;
                            {
                                int ret = slice_del(z);
                                if (ret < 0) return ret;
                            }
                            {
                                int v_15 = z->l - z->c;
                                z->ket = z->c;
                                if (!(eq_s_b(z, 2, s_5))) { z->c = z->l - v_15; goto lab14; }
                                z->bra = z->c;
                                if (i_p2 > z->c) { z->c = z->l - v_15; goto lab14; }
                                {
                                    int ret = slice_del(z);
                                    if (ret < 0) return ret;
                                }
                            lab14:
                                ;
                            }
                            break;
                        case 9:
                            if (i_pV > z->c) goto lab10;
                            if (z->c <= z->lb || z->p[z->c - 1] != 'e') goto lab10;
                            z->c--;
                            {
                                int ret = slice_from_s(z, 2, s_6);
                                if (ret < 0) return ret;
                            }
                            break;
                    }
                    break;
                lab10:
                    z->c = z->l - v_11;
                    {
                        int v_16;
                        if (z->c < i_pV) goto lab9;
                        v_16 = z->lb; z->lb = i_pV;
                        z->ket = z->c;
                        if (!find_among_b(z, a_6)) { z->lb = v_16; goto lab9; }
                        z->bra = z->c;
                        {
                            int ret = slice_del(z);
                            if (ret < 0) return ret;
                        }
                        z->lb = v_16;
                    }
                } while (0);
                z->c = z->l - v_10;
                {
                    int v_17 = z->l - z->c;
                    z->ket = z->c;
                    if (z->c <= z->lb || z->p[z->c - 1] != 'i') goto lab15;
                    z->c--;
                    z->bra = z->c;
                    {
                        int v_18 = z->l - z->c;
                        if (z->c <= z->lb || z->p[z->c - 1] != 'c') goto lab15;
                        z->c--;
                        z->c = z->l - v_18;
                    }
                    if (i_pV > z->c) goto lab15;
                    {
                        int ret = slice_del(z);
                        if (ret < 0) return ret;
                    }
                lab15:
                    z->c = z->l - v_17;
                }
            }
            break;
        lab9:
            z->c = z->l - v_9;
            z->ket = z->c;
            if (!find_among_b(z, a_7)) goto lab8;
            z->bra = z->c;
            if (i_pV > z->c) goto lab8;
            {
                int ret = slice_del(z);
                if (ret < 0) return ret;
            }
        } while (0);
    lab8:
        z->c = z->l - v_8;
    }
    {
        int v_19 = z->l - z->c;
        z->ket = z->c;
        among_var = find_among_b(z, a_8);
        if (!among_var) goto lab16;
        z->bra = z->c;
        switch (among_var) {
            case 1:
                if (i_pV > z->c) goto lab16;
                {
                    int ret = slice_del(z);
                    if (ret < 0) return ret;
                }
                z->ket = z->c;
                do {
                    int v_20 = z->l - z->c;
                    if (z->c <= z->lb || z->p[z->c - 1] != 'u') goto lab17;
                    z->c--;
                    z->bra = z->c;
                    {
                        int v_21 = z->l - z->c;
                        if (z->c <= z->lb || z->p[z->c - 1] != 'g') goto lab17;
                        z->c--;
                        z->c = z->l - v_21;
                    }
                    break;
                lab17:
                    z->c = z->l - v_20;
                    if (z->c <= z->lb || z->p[z->c - 1] != 'i') goto lab16;
                    z->c--;
                    z->bra = z->c;
                    {
                        int v_22 = z->l - z->c;
                        if (z->c <= z->lb || z->p[z->c - 1] != 'c') goto lab16;
                        z->c--;
                        z->c = z->l - v_22;
                    }
                } while (0);
                if (i_pV > z->c) goto lab16;
                {
                    int ret = slice_del(z);
                    if (ret < 0) return ret;
                }
                break;
            case 2:
                {
                    int ret = slice_from_s(z, 1, s_7);
                    if (ret < 0) return ret;
                }
                break;
        }
    lab16:
        z->c = z->l - v_19;
    }
    z->c = z->lb;
    {
        int v_23 = z->c;
        while (1) {
            int v_24 = z->c;
            z->bra = z->c;
            if (z->c + 1 >= z->l || z->p[z->c + 1] != 126) among_var = 3; else
            among_var = find_among(z, a_1);
            z->ket = z->c;
            switch (among_var) {
                case 1:
                    {
                        int ret = slice_from_s(z, 2, s_8);
                        if (ret < 0) return ret;
                    }
                    break;
                case 2:
                    {
                        int ret = slice_from_s(z, 2, s_9);
                        if (ret < 0) return ret;
                    }
                    break;
                case 3:
                    {
                        int ret = skip_utf8(z->p, z->c, z->l, 1);
                        if (ret < 0) goto lab19;
                        z->c = ret;
                    }
                    break;
            }
            continue;
        lab19:
            z->c = v_24;
            break;
        }
        z->c = v_23;
    }
    return 1;
}

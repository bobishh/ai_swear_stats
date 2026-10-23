/* Generated from dutch.sbl by Snowball 3.2.0 - https://snowballstem.org/ */

#include "stem_UTF_8_dutch.h"

#include <stddef.h>

#include "../runtime/snowball_runtime.h"

struct SN_local {
    struct SN_env z;
    int i_p2;
    int i_p1;
    symbol * s_ch;
};

typedef struct SN_local SN_local;

#ifdef SNOWBALL_BIGENDIAN
#define S(W) ((0x##W & 0xff) << 8 | 0x##W >> 8)
#else
#define S(W) (0x##W)
#endif

#ifdef __cplusplus
extern "C" {
#endif
extern int dutch_UTF_8_stem(struct SN_env * z);
#ifdef __cplusplus
}
#endif

static int r_measure(struct SN_env * z);
static int r_Step_1c(struct SN_env * z);
static int r_lengthen_V(struct SN_env * z);
static int r_V(struct SN_env * z);
static int r_C(struct SN_env * z);

#define s_33 (s_0 + 1)
#define s_29 (s_3 + 2)
#define s_27 (s_4 + 1)
#define s_30 (s_16 + 1)
#define s_0 (s_18 + 1)
#define s_21 (s_19 + 1)
#define s_32 (s_19 + 2)
#define s_7 (s_20 + 2)
#define s_23 (s_20 + 1)
#define s_26 (s_22 + 2)
#define s_6 (s_25 + 1)
#define s_4 (s_5 + 1)
#define s_13 (s_17 + 1)
#define s_5 (s_2 + 2)
#define s_17 (s_15 + 2)
#define s_20 (s_12 + 1)
#define s_14 (s_25 + 2)
#define s_10 (s_19 + 3)
static const symbol s_1[] = { 'e', 0xC3, 0xAB, 'e' };
static const symbol s_2[] = { 'i', 'e', 'e', 'n', 'd' };
static const symbol s_3[] = { 'i', 'n', 'k' };
static const symbol s_38[] = { 'z' };
static const symbol s_36[] = { 'w' };
static const symbol s_8[] = { 0xC3, 0xA9 };
static const symbol s_9[] = { 'a', 'u' };
static const symbol s_28[] = { 'i', 'n', 'n' };
static const symbol s_11[] = { 'h', 'e', 'i', 'd' };
static const symbol s_12[] = { '\'', 't', 'e', 'e', 'r' };
static const symbol s_37[] = { 'x' };
static const symbol s_31[] = { 'b' };
static const symbol s_15[] = { 'i', 'n', 'g', 'e', 't' };
static const symbol s_16[] = { 'm', 'p' };
static const symbol s_35[] = { 'v' };
static const symbol s_18[] = { 'l', 'i', 'j', 'k' };
static const symbol s_19[] = { 'i', 's', 'c', 'h', 'e', 'd' };
static const symbol s_34[] = { 'q' };
static const symbol s_22[] = { 'i', 'e', 'f' };
static const symbol s_24[] = { 'i', 'l', 'd' };
static const symbol s_25[] = { 'a', 'a', 'r', 'n', 't' };

static const unsigned short a_0[] = {
    0x0000 , 0xBC61 , 0xFFFF , 0x0000 , 0x0000 , 0x0000 , 0xFFFE , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0xFFFF , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0xFFFF , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x005E , 0x005E , 0x005E , 0x0000 , 0x005E , 0x0000 , 0x0000 ,
    0x0000 , 0x0061 , 0x0061 , 0x0061 , 0x0064 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x005E , 0x005E , 0x005E , 0x0000 , 0x005E ,
    0x0000 , 0x0000 , 0x005E , 0x005E , 0x005E , 0x005E , 0x0000 , 0xC3C3 ,
    0xFFFF , 0x0000 , 0xC3C3 , 0xFFFE , 0x0000 , 0xC3C3 , 0x0067 , 0x0000 ,
    0x6569 , 0xFFFD , 0xFFFC
};

static const unsigned short a_1[] = {
    0x0000 , 0x7365 , 0x0011 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0015 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0018 , 0x0000 , 0x0002 , 0xFFF8 , S(646E), 0x0000 , 0x6565 , 0xFFF9 ,
    0x0002 , 0xA927 , 0xFFFF , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x009D , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x00A0 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x00A3 , 0x0004 , 0x6969 , 0xFFFD ,
    0x0000 , 0x6161 , 0xFFFA , 0x0000 , 0xC3C3 , 0xFFFB
};

static const unsigned short a_2[] = {
    0x0000 , 0x6565 , 0x0003 , 0x0000 , 0x7664 , 0xFFFB , 0x0000 , 0x0000 ,
    0xFFFE , 0x0018 , 0x0000 , 0xFFFF , 0x001D , 0xFFF7 , 0x0000 , 0x0022 ,
    0x0000 , 0x0000 , 0x0000 , 0xFFF8 , 0xFFF9 , 0xFFFA , 0x0000 , 0x0025 ,
    0x0000 , 0x0003 , 0xFFFC , S(7369), S(0063), 0x0000 , 0x0003 , 0xFFFD ,
    S(696C), S(006A), 0x0000 , 0x6565 , 0xFFF6 , 0x0000 , 0x0002 , 0xFFF5 ,
    S(6569)
};

static const unsigned short a_3[] = {
    0x0000 , 0x7464 , 0x0013 , 0x0018 , 0x0000 , 0x0034 , 0x0000 , 0x0000 ,
    0x0038 , 0x0000 , 0x0040 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0044 , 0x0000 , 0x0051 , 0x0000 , 0x0003 , 0xFFFD , S(6568), S(0069),
    0x0000 , 0x696D , 0x001C , 0x0030 , 0x0000 , 0x7466 , 0xFFF9 , 0xFFF8 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x002D , 0x0000 , 0x6161 , 0xFFFF ,
    0x0000 , 0x0002 , 0xFFFB , S(7369), 0x0000 , 0x0002 , 0xFFFB , S(6E69),
    0x0000 , 0x0002 , 0x003C , S(6972), 0x0000 , 0x6165 , 0xFFFA , 0xFFFB ,
    0x0000 , 0x0002 , 0xFFFD , S(6573), 0x0000 , 0x6565 , 0x0047 , 0x0000 ,
    0x6474 , 0x004B , 0x004E , 0x0000 , 0x7272 , 0xFFFC , 0x0000 , 0x7373 ,
    0xFFFD , 0x0000 , 0x6973 , 0x0055 , 0x005A , 0x0000 , 0x0003 , 0xFFFE ,
    S(7469), S(0065), 0x0000 , 0x6474 , 0xFFF6 , 0xFFF7
};

static const unsigned short a_4[] = {
    0x0000 , 0x7464 , 0x0013 , 0x0000 , 0x0017 , 0x001C , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x002B , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0031 , 0x0000 , 0x005B , 0x0000 , 0x0002 , 0xFFF7 , S(6E65), 0x0000 ,
    0x0004 , 0xFFFE , S(7461), S(6569), 0x0000 , 0x6969 , 0x001F , 0x0000 ,
    0x7274 , 0x0023 , 0x0026 , 0x0000 , 0x6565 , 0xFFF7 , 0x0000 , 0x0003 ,
    0xFFFD , S(6361), S(0068), 0x0000 , 0x0005 , 0xFFFF , S(6F69), S(656E),
    S(0065), 0x0000 , 0x6165 , 0x0035 , 0x004B , 0x0000 , 0x6161 , 0x0038 ,
    0x0000 , 0x7262 , 0xFFFD , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0xFFFB , 0x0000 , 0xFFFC , 0x0000 ,
    0x0000 , 0x0000 , 0xFFFA , 0x0000 , 0x676B , 0x004F , 0x0056 , 0x0000 ,
    0x6969 , 0x0052 , 0x0000 , 0x7274 , 0x0023 , 0x0026 , 0x0000 , 0x0003 ,
    0xFFF8 , S(696C), S(006A), 0x0000 , 0x6E73 , 0x005F , 0x0063 , 0x0000 ,
    0x0002 , 0xFFF9 , S(6174), 0x0000 , 0x676B , 0x0067 , 0x0056 , 0x0000 ,
    0x6969 , 0x0052
};

static const unsigned short a_5[] = {
    0x0000 , 0x7467 , 0x0010 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0013 , 0x0000 , 0x0018 ,
    0x0000 , 0x6969 , 0xFFFF , 0x0000 , 0x0003 , 0xFFFF , S(6769), S(0065),
    0x0000 , 0x0003 , 0xFFFF , S(6769), S(0073)
};

static const unsigned short a_6[] = {
    0x0000 , 0x7474 , 0x0003 , 0x0000 , 0x7066 , 0xFFFE , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0xFFFF , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0xFFFD
};

static const unsigned short a_7[] = {
    0x0000 , 0x7A62 , 0x001B , 0x001E , 0x0021 , 0x0000 , 0x0024 , 0x0027 ,
    0x002A , 0x0000 , 0x002D , 0x0030 , 0x0033 , 0x0036 , 0x0039 , 0x0000 ,
    0x003C , 0x003F , 0x0042 , 0x0045 , 0x0048 , 0x0000 , 0x004B , 0x004E ,
    0x0051 , 0x0000 , 0x0054 , 0x0000 , 0x6262 , 0xFFFF , 0x0000 , 0x6363 ,
    0xFFFE , 0x0000 , 0x6464 , 0xFFFD , 0x0000 , 0x6666 , 0xFFFC , 0x0000 ,
    0x6767 , 0xFFFB , 0x0000 , 0x6868 , 0xFFFA , 0x0000 , 0x6A6A , 0xFFF9 ,
    0x0000 , 0x6B6B , 0xFFF8 , 0x0000 , 0x6C6C , 0xFFF7 , 0x0000 , 0x6D6D ,
    0xFFF6 , 0x0000 , 0x6E6E , 0xFFF5 , 0x0000 , 0x7070 , 0xFFF4 , 0x0000 ,
    0x7171 , 0xFFF3 , 0x0000 , 0x7272 , 0xFFF2 , 0x0000 , 0x7373 , 0xFFF1 ,
    0x0000 , 0x7474 , 0xFFF0 , 0x0004 , 0x7676 , 0xFFEF , 0x0000 , 0x7777 ,
    0xFFEE , 0x0000 , 0x7878 , 0xFFED , 0x000F , 0x7A7A , 0xFFEC
};

static const unsigned short a_8[] = {
    0x0000 , 0x6474 , 0xFFFF , 0xFFFE
};

static const unsigned short a_9[] = {
    0x3FFF , 0x6576 , 0x0004 , 0x0008 , 0x0000 , 0x0002 , 0xFFFF , S(7466),
    0x0000 , 0x6161 , 0x000B , 0x0000 , 0x7261 , 0xFFFF , 0x0000 , 0x0000 ,
    0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 ,
    0x001F , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0000 , 0x0022 , 0x0001 ,
    0x6969 , 0xC001 , 0x0000 , 0x6565 , 0xFFFF
};

static const unsigned short a_10[] = {
    0x0000 , 0xC3C3 , 0x0003 , 0x0000 , 0xABAF , 0xFFFF , 0xFFFE
};

static const unsigned short a_11[] = {
    0x0000 , 0xC3C3 , 0x0003 , 0x0000 , 0xABAF , 0xFFFF , 0xFFFE
};

static const unsigned char g_E[] = { 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 120 };

static const unsigned char g_AIOU[] = { 1, 65, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 11, 120, 46, 15 };

static const unsigned char g_AEIOU[] = { 17, 65, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 139, 127, 46, 15 };

static const unsigned char g_v[] = { 17, 65, 16, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 139, 127, 46, 15 };

static const unsigned char g_v_WX[] = { 17, 65, 208, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 139, 127, 46, 15 };

static int r_V(struct SN_env * z) {
    {
        int v_1 = z->l - z->c;
        do {
            if (in_grouping_b_U(z, g_v, 97, 252, 0)) goto lab0;
            break;
        lab0:
            if (!(eq_s_b(z, 2, s_0))) return 0;
        } while (0);
        z->c = z->l - v_1;
    }
    return 1;
}

static int r_C(struct SN_env * z) {
    {
        int v_1 = z->l - z->c;
        if (!(eq_s_b(z, 2, s_0))) goto lab0;
        return 0;
    lab0:
        if (out_grouping_b_U(z, g_v, 97, 252, 0)) return 0;
        z->c = z->l - v_1;
    }
    return 1;
}

static int r_lengthen_V(struct SN_env * z) {
    int among_var;
    {
        int v_1 = z->l - z->c;
        if (out_grouping_b_U(z, g_v_WX, 97, 252, 0)) goto lab0;
        z->ket = z->c;
        among_var = find_among_b(z, a_0);
        if (!among_var) goto lab0;
        z->bra = z->c;
        switch (among_var) {
            case 1:
                {
                    int v_2 = z->l - z->c;
                    do {
                        if (out_grouping_b_U(z, g_AEIOU, 97, 252, 0)) goto lab1;
                        break;
                    lab1:
                        if (z->c > z->lb) goto lab0;
                    } while (0);
                    z->c = z->l - v_2;
                }
                {
                    int ret = slice_to(z, &((SN_local *)z)->s_ch);
                    if (ret < 0) return ret;
                }
                {
                    int saved_c = z->c;
                    int ret = insert_v(z, z->c, z->c, ((SN_local *)z)->s_ch);
                    z->c = saved_c;
                    if (ret < 0) return ret;
                }
                break;
            case 2:
                {
                    int v_3 = z->l - z->c;
                    do {
                        if (out_grouping_b_U(z, g_AEIOU, 97, 252, 0)) goto lab2;
                        break;
                    lab2:
                        if (z->c > z->lb) goto lab0;
                    } while (0);
                    {
                        int v_4 = z->l - z->c;
                        do {
                            if (in_grouping_b_U(z, g_AIOU, 97, 252, 0)) goto lab4;
                            break;
                        lab4:
                            if (in_grouping_b_U(z, g_E, 101, 235, 0)) goto lab3;
                            if (z->c > z->lb) goto lab3;
                        } while (0);
                        goto lab0;
                    lab3:
                        z->c = z->l - v_4;
                    }
                    {
                        int v_5 = z->l - z->c;
                        {
                            int ret = skip_b_utf8(z->p, z->c, z->lb, 1);
                            if (ret < 0) goto lab5;
                            z->c = ret;
                        }
                        if (in_grouping_b_U(z, g_AIOU, 97, 252, 0)) goto lab5;
                        if (out_grouping_b_U(z, g_AEIOU, 97, 252, 0)) goto lab5;
                        goto lab0;
                    lab5:
                        z->c = z->l - v_5;
                    }
                    z->c = z->l - v_3;
                }
                {
                    int ret = slice_to(z, &((SN_local *)z)->s_ch);
                    if (ret < 0) return ret;
                }
                {
                    int saved_c = z->c;
                    int ret = insert_v(z, z->c, z->c, ((SN_local *)z)->s_ch);
                    z->c = saved_c;
                    if (ret < 0) return ret;
                }
                break;
            case 3:
                {
                    int ret = slice_from_s(z, 4, s_1);
                    if (ret < 0) return ret;
                }
                break;
            case 4:
                {
                    int ret = slice_from_s(z, 3, s_2);
                    if (ret < 0) return ret;
                }
                break;
        }
    lab0:
        z->c = z->l - v_1;
    }
    return 1;
}

static int r_Step_1c(struct SN_env * z) {
    int among_var;
    z->ket = z->c;
    if (z->c <= z->lb || (z->p[z->c - 1] != 100 && z->p[z->c - 1] != 116)) return 0;
    among_var = find_among_b(z, a_8);
    if (!among_var) return 0;
    z->bra = z->c;
    if (((SN_local *)z)->i_p1 > z->c) return 0;
    {
        int ret = r_C(z);
        if (ret == 0) return ret;
    }
    switch (among_var) {
        case 1:
            {
                int v_1 = z->l - z->c;
                if (z->c <= z->lb || z->p[z->c - 1] != 'n') goto lab0;
                z->c--;
                if (((SN_local *)z)->i_p1 > z->c) goto lab0;
                return 0;
            lab0:
                z->c = z->l - v_1;
            }
            do {
                int v_2 = z->l - z->c;
                if (!(eq_s_b(z, 2, s_3))) goto lab1;
                if (z->c > z->lb) goto lab1;
                {
                    int ret = slice_from_s(z, 1, s_4);
                    if (ret < 0) return ret;
                }
                break;
            lab1:
                z->c = z->l - v_2;
                {
                    int ret = slice_del(z);
                    if (ret < 0) return ret;
                }
            } while (0);
            break;
        case 2:
            {
                int v_3 = z->l - z->c;
                if (z->c <= z->lb || z->p[z->c - 1] != 'h') goto lab2;
                z->c--;
                if (((SN_local *)z)->i_p1 > z->c) goto lab2;
                return 0;
            lab2:
                z->c = z->l - v_3;
            }
            {
                int v_4 = z->l - z->c;
                if (!(eq_s_b(z, 2, s_5))) goto lab3;
                if (z->c > z->lb) goto lab3;
                return 0;
            lab3:
                z->c = z->l - v_4;
            }
            {
                int ret = slice_del(z);
                if (ret < 0) return ret;
            }
            break;
    }
    return 1;
}

static int r_measure(struct SN_env * z) {
    ((SN_local *)z)->i_p1 = z->l;
    ((SN_local *)z)->i_p2 = z->l;
    {
        int v_1 = z->c;
        while (1) {
            if (out_grouping_U(z, g_v, 97, 252, 0)) goto lab1;
            continue;
        lab1:
            break;
        }
        {
            int v_2 = 1;
            while (1) {
                int v_3 = z->c;
                do {
                    if (!(eq_s(z, 2, s_0))) goto lab3;
                    break;
                lab3:
                    if (in_grouping_U(z, g_v, 97, 252, 0)) goto lab2;
                } while (0);
                v_2--;
                continue;
            lab2:
                z->c = v_3;
                break;
            }
            if (v_2 > 0) goto lab0;
        }
        if (out_grouping_U(z, g_v, 97, 252, 0)) goto lab0;
        ((SN_local *)z)->i_p1 = z->c;
        while (1) {
            if (out_grouping_U(z, g_v, 97, 252, 0)) goto lab4;
            continue;
        lab4:
            break;
        }
        {
            int v_4 = 1;
            while (1) {
                int v_5 = z->c;
                do {
                    if (!(eq_s(z, 2, s_0))) goto lab6;
                    break;
                lab6:
                    if (in_grouping_U(z, g_v, 97, 252, 0)) goto lab5;
                } while (0);
                v_4--;
                continue;
            lab5:
                z->c = v_5;
                break;
            }
            if (v_4 > 0) goto lab0;
        }
        if (out_grouping_U(z, g_v, 97, 252, 0)) goto lab0;
        ((SN_local *)z)->i_p2 = z->c;
    lab0:
        z->c = v_1;
    }
    return 1;
}

extern int dutch_UTF_8_stem(struct SN_env * z) {
    int among_var;
    int b_GE_removed;
    int b_stemmed;
    b_stemmed = 0;
    {
        int ret = r_measure(z);
        if (ret == 0) return ret;
    }
    z->lb = z->c; z->c = z->l;
    {
        int v_1 = z->l - z->c;
        z->ket = z->c;
        if (z->c <= z->lb || z->p[z->c - 1] >> 5 != 3 || !((540704 >> (z->p[z->c - 1] & 0x1f)) & 1)) goto lab0;
        among_var = find_among_b(z, a_1);
        if (!among_var) goto lab0;
        z->bra = z->c;
        switch (among_var) {
            case 1:
                {
                    int ret = slice_del(z);
                    if (ret < 0) return ret;
                }
                break;
            case 2:
                if (((SN_local *)z)->i_p1 > z->c) goto lab0;
                {
                    int v_2 = z->l - z->c;
                    if (z->c <= z->lb || z->p[z->c - 1] != 't') goto lab1;
                    z->c--;
                    if (((SN_local *)z)->i_p1 > z->c) goto lab1;
                    goto lab0;
                lab1:
                    z->c = z->l - v_2;
                }
                if (!r_C(z)) goto lab0;
                {
                    int ret = slice_del(z);
                    if (ret < 0) return ret;
                }
                break;
            case 3:
                if (((SN_local *)z)->i_p1 > z->c) goto lab0;
                {
                    int ret = slice_from_s(z, 2, s_2);
                    if (ret < 0) return ret;
                }
                break;
            case 4:
                do {
                    int v_3 = z->l - z->c;
                    {
                        int v_4 = z->l - z->c;
                        if (!(eq_s_b(z, 2, s_6))) goto lab2;
                        if (((SN_local *)z)->i_p1 > z->c) goto lab2;
                        if (!r_C(z)) goto lab2;
                        z->c = z->l - v_4;
                    }
                    {
                        int ret = slice_del(z);
                        if (ret < 0) return ret;
                    }
                    {
                        int ret = r_lengthen_V(z);
                        if (ret < 0) return ret;
                    }
                    break;
                lab2:
                    z->c = z->l - v_3;
                    {
                        int v_5 = z->l - z->c;
                        if (!(eq_s_b(z, 2, s_7))) goto lab3;
                        if (((SN_local *)z)->i_p1 > z->c) goto lab3;
                        if (!r_C(z)) goto lab3;
                        z->c = z->l - v_5;
                    }
                    {
                        int ret = slice_del(z);
                        if (ret < 0) return ret;
                    }
                    break;
                lab3:
                    z->c = z->l - v_3;
                    if (((SN_local *)z)->i_p1 > z->c) goto lab0;
                    if (!r_C(z)) goto lab0;
                    {
                        int ret = slice_from_s(z, 1, s_1);
                        if (ret < 0) return ret;
                    }
                } while (0);
                break;
            case 5:
                if (((SN_local *)z)->i_p1 > z->c) goto lab0;
                {
                    int ret = slice_from_s(z, 2, s_8);
                    if (ret < 0) return ret;
                }
                break;
            case 6:
                if (((SN_local *)z)->i_p1 > z->c) goto lab0;
                if (!r_V(z)) goto lab0;
                {
                    int ret = slice_from_s(z, 2, s_9);
                    if (ret < 0) return ret;
                }
                break;
            case 7:
                do {
                    int v_6 = z->l - z->c;
                    if (!(eq_s_b(z, 3, s_10))) goto lab4;
                    if (((SN_local *)z)->i_p1 > z->c) goto lab4;
                    z->bra = z->c;
                    {
                        int ret = slice_from_s(z, 4, s_11);
                        if (ret < 0) return ret;
                    }
                    break;
                lab4:
                    z->c = z->l - v_6;
                    if (!(eq_s_b(z, 2, s_4))) goto lab5;
                    {
                        int ret = slice_del(z);
                        if (ret < 0) return ret;
                    }
                    break;
                lab5:
                    z->c = z->l - v_6;
                    if (z->c <= z->lb || z->p[z->c - 1] != 'd') goto lab6;
                    z->c--;
                    if (((SN_local *)z)->i_p1 > z->c) goto lab6;
                    if (!r_C(z)) goto lab6;
                    z->bra = z->c;
                    {
                        int ret = slice_del(z);
                        if (ret < 0) return ret;
                    }
                    break;
                lab6:
                    z->c = z->l - v_6;
                    do {
                        if (z->c <= z->lb || z->p[z->c - 1] != 'i') goto lab8;
                        z->c--;
                        break;
                    lab8:
                        if (z->c <= z->lb || z->p[z->c - 1] != 'j') goto lab7;
                        z->c--;
                    } while (0);
                    if (!r_V(z)) goto lab7;
                    {
                        int ret = slice_del(z);
                        if (ret < 0) return ret;
                    }
                    break;
                lab7:
                    z->c = z->l - v_6;
                    if (((SN_local *)z)->i_p1 > z->c) goto lab0;
                    if (!r_C(z)) goto lab0;
                    {
                        int ret = slice_del(z);
                        if (ret < 0) return ret;
                    }
                    {
                        int ret = r_lengthen_V(z);
                        if (ret < 0) return ret;
                    }
                } while (0);
                break;
            case 8:
                {
                    int ret = slice_from_s(z, 2, s_4);
                    if (ret < 0) return ret;
                }
                break;
        }
        b_stemmed = 1;
    lab0:
        z->c = z->l - v_1;
    }
    {
        int v_7 = z->l - z->c;
        z->ket = z->c;
        if (z->c - 1 <= z->lb || z->p[z->c - 1] != 101) goto lab9;
        among_var = find_among_b(z, a_2);
        if (!among_var) goto lab9;
        z->bra = z->c;
        switch (among_var) {
            case 1:
                do {
                    int v_8 = z->l - z->c;
                    if (!(eq_s_b(z, 2, s_12))) goto lab10;
                    z->bra = z->c;
                    {
                        int ret = slice_del(z);
                        if (ret < 0) return ret;
                    }
                    break;
                lab10:
                    z->c = z->l - v_8;
                    if (!(eq_s_b(z, 2, s_13))) goto lab11;
                    z->bra = z->c;
                    if (((SN_local *)z)->i_p1 > z->c) goto lab11;
                    if (!r_C(z)) goto lab11;
                    {
                        int ret = slice_del(z);
                        if (ret < 0) return ret;
                    }
                    break;
                lab11:
                    z->c = z->l - v_8;
                    if (!(eq_s_b(z, 3, s_14))) goto lab12;
                    z->bra = z->c;
                    {
                        int ret = slice_from_s(z, 2, s_14);
                        if (ret < 0) return ret;
                    }
                    break;
                lab12:
                    z->c = z->l - v_8;
                    if (z->c <= z->lb || z->p[z->c - 1] != 't') goto lab13;
                    z->c--;
                    z->bra = z->c;
                    if (((SN_local *)z)->i_p1 > z->c) goto lab13;
                    {
                        int v_9 = z->l - z->c;
                        {
                            int ret = skip_b_utf8(z->p, z->c, z->lb, 1);
                            if (ret < 0) goto lab13;
                            z->c = ret;
                        }
                        do {
                            if (in_grouping_b_U(z, g_v, 97, 252, 0)) goto lab14;
                            break;
                        lab14:
                            if (!(eq_s_b(z, 2, s_0))) goto lab13;
                        } while (0);
                        z->c = z->l - v_9;
                    }
                    {
                        int ret = slice_del(z);
                        if (ret < 0) return ret;
                    }
                    break;
                lab13:
                    z->c = z->l - v_8;
                    if (!(eq_s_b(z, 3, s_3))) goto lab15;
                    z->bra = z->c;
                    {
                        int ret = slice_from_s(z, 3, s_15);
                        if (ret < 0) return ret;
                    }
                    break;
                lab15:
                    z->c = z->l - v_8;
                    if (!(eq_s_b(z, 2, s_16))) goto lab16;
                    z->bra = z->c;
                    {
                        int ret = slice_from_s(z, 1, s_16);
                        if (ret < 0) return ret;
                    }
                    break;
                lab16:
                    z->c = z->l - v_8;
                    if (z->c <= z->lb || z->p[z->c - 1] != '\'') goto lab17;
                    z->c--;
                    z->bra = z->c;
                    if (((SN_local *)z)->i_p1 > z->c) goto lab17;
                    {
                        int ret = slice_del(z);
                        if (ret < 0) return ret;
                    }
                    break;
                lab17:
                    z->c = z->l - v_8;
                    z->bra = z->c;
                    if (((SN_local *)z)->i_p1 > z->c) goto lab9;
                    if (!r_C(z)) goto lab9;
                    {
                        int ret = slice_del(z);
                        if (ret < 0) return ret;
                    }
                } while (0);
                break;
            case 2:
                if (((SN_local *)z)->i_p1 > z->c) goto lab9;
                {
                    int ret = slice_from_s(z, 1, s_17);
                    if (ret < 0) return ret;
                }
                break;
            case 3:
                if (((SN_local *)z)->i_p1 > z->c) goto lab9;
                {
                    int ret = slice_from_s(z, 4, s_18);
                    if (ret < 0) return ret;
                }
                break;
            case 4:
                if (((SN_local *)z)->i_p1 > z->c) goto lab9;
                {
                    int ret = slice_from_s(z, 4, s_19);
                    if (ret < 0) return ret;
                }
                break;
            case 5:
                if (((SN_local *)z)->i_p1 > z->c) goto lab9;
                if (!r_C(z)) goto lab9;
                {
                    int ret = slice_del(z);
                    if (ret < 0) return ret;
                }
                break;
            case 6:
                if (((SN_local *)z)->i_p1 > z->c) goto lab9;
                {
                    int ret = slice_from_s(z, 1, s_20);
                    if (ret < 0) return ret;
                }
                break;
            case 7:
                if (((SN_local *)z)->i_p1 > z->c) goto lab9;
                {
                    int ret = slice_from_s(z, 1, s_21);
                    if (ret < 0) return ret;
                }
                break;
            case 8:
                if (((SN_local *)z)->i_p1 > z->c) goto lab9;
                {
                    int ret = slice_from_s(z, 1, s_14);
                    if (ret < 0) return ret;
                }
                break;
            case 9:
                if (((SN_local *)z)->i_p1 > z->c) goto lab9;
                {
                    int ret = slice_del(z);
                    if (ret < 0) return ret;
                }
                {
                    int ret = insert_s(z, z->c, z->c, 1, s_18);
                    if (ret < 0) return ret;
                }
                {
                    int ret = r_lengthen_V(z);
                    if (ret < 0) return ret;
                }
                break;
            case 10:
                if (((SN_local *)z)->i_p1 > z->c) goto lab9;
                if (!r_C(z)) goto lab9;
                {
                    int ret = slice_del(z);
                    if (ret < 0) return ret;
                }
                {
                    int ret = insert_s(z, z->c, z->c, 2, s_5);
                    if (ret < 0) return ret;
                }
                {
                    int ret = r_lengthen_V(z);
                    if (ret < 0) return ret;
                }
                break;
            case 11:
                if (((SN_local *)z)->i_p1 > z->c) goto lab9;
                if (!r_C(z)) goto lab9;
                {
                    int ret = slice_from_s(z, 3, s_22);
                    if (ret < 0) return ret;
                }
                break;
        }
        b_stemmed = 1;
    lab9:
        z->c = z->l - v_7;
    }
    {
        int v_10 = z->l - z->c;
        z->ket = z->c;
        if (z->c - 2 <= z->lb || z->p[z->c - 1] >> 5 != 3 || !((1316016 >> (z->p[z->c - 1] & 0x1f)) & 1)) goto lab18;
        among_var = find_among_b(z, a_3);
        if (!among_var) goto lab18;
        z->bra = z->c;
        switch (among_var) {
            case 1:
                if (((SN_local *)z)->i_p1 > z->c) goto lab18;
                {
                    int ret = slice_from_s(z, 3, s_23);
                    if (ret < 0) return ret;
                }
                break;
            case 2:
                if (((SN_local *)z)->i_p1 > z->c) goto lab18;
                {
                    int ret = slice_del(z);
                    if (ret < 0) return ret;
                }
                {
                    int ret = r_lengthen_V(z);
                    if (ret < 0) return ret;
                }
                break;
            case 3:
                if (((SN_local *)z)->i_p1 > z->c) goto lab18;
                {
                    int ret = slice_del(z);
                    if (ret < 0) return ret;
                }
                break;
            case 4:
                {
                    int ret = slice_from_s(z, 1, s_14);
                    if (ret < 0) return ret;
                }
                break;
            case 5:
                do {
                    int v_11 = z->l - z->c;
                    if (!(eq_s_b(z, 3, s_24))) goto lab19;
                    {
                        int ret = slice_from_s(z, 2, s_7);
                        if (ret < 0) return ret;
                    }
                    break;
                lab19:
                    z->c = z->l - v_11;
                    if (((SN_local *)z)->i_p1 > z->c) goto lab18;
                    {
                        int ret = slice_del(z);
                        if (ret < 0) return ret;
                    }
                    {
                        int ret = r_lengthen_V(z);
                        if (ret < 0) return ret;
                    }
                } while (0);
                break;
            case 6:
                if (((SN_local *)z)->i_p1 > z->c) goto lab18;
                if (!r_C(z)) goto lab18;
                {
                    int ret = slice_from_s(z, 3, s_25);
                    if (ret < 0) return ret;
                }
                break;
            case 7:
                if (((SN_local *)z)->i_p2 > z->c) goto lab18;
                {
                    int ret = slice_del(z);
                    if (ret < 0) return ret;
                }
                {
                    int ret = insert_s(z, z->c, z->c, 1, s_26);
                    if (ret < 0) return ret;
                }
                {
                    int ret = r_lengthen_V(z);
                    if (ret < 0) return ret;
                }
                break;
            case 8:
                if (((SN_local *)z)->i_p2 > z->c) goto lab18;
                {
                    int ret = slice_del(z);
                    if (ret < 0) return ret;
                }
                {
                    int ret = insert_s(z, z->c, z->c, 1, s_17);
                    if (ret < 0) return ret;
                }
                {
                    int ret = r_lengthen_V(z);
                    if (ret < 0) return ret;
                }
                break;
            case 9:
                if (((SN_local *)z)->i_p1 > z->c) goto lab18;
                if (!r_C(z)) goto lab18;
                {
                    int ret = slice_from_s(z, 1, s_20);
                    if (ret < 0) return ret;
                }
                break;
            case 10:
                if (((SN_local *)z)->i_p1 > z->c) goto lab18;
                if (!r_C(z)) goto lab18;
                {
                    int ret = slice_from_s(z, 1, s_27);
                    if (ret < 0) return ret;
                }
                break;
        }
        b_stemmed = 1;
    lab18:
        z->c = z->l - v_10;
    }
    {
        int v_12 = z->l - z->c;
        do {
            int v_13 = z->l - z->c;
            z->ket = z->c;
            if (z->c - 2 <= z->lb || z->p[z->c - 1] >> 5 != 3 || !((1315024 >> (z->p[z->c - 1] & 0x1f)) & 1)) goto lab21;
            among_var = find_among_b(z, a_4);
            if (!among_var) goto lab21;
            z->bra = z->c;
            switch (among_var) {
                case 1:
                    if (((SN_local *)z)->i_p1 > z->c) goto lab21;
                    {
                        int ret = slice_from_s(z, 2, s_2);
                        if (ret < 0) return ret;
                    }
                    break;
                case 2:
                    if (((SN_local *)z)->i_p1 > z->c) goto lab21;
                    {
                        int ret = slice_from_s(z, 3, s_23);
                        if (ret < 0) return ret;
                    }
                    break;
                case 3:
                    if (((SN_local *)z)->i_p1 > z->c) goto lab21;
                    {
                        int ret = slice_del(z);
                        if (ret < 0) return ret;
                    }
                    break;
                case 4:
                    if (((SN_local *)z)->i_p1 > z->c) goto lab21;
                    if (!r_V(z)) goto lab21;
                    {
                        int ret = slice_from_s(z, 1, s_4);
                        if (ret < 0) return ret;
                    }
                    break;
                case 5:
                    if (((SN_local *)z)->i_p1 > z->c) goto lab21;
                    if (!r_V(z)) goto lab21;
                    {
                        int ret = slice_from_s(z, 1, s_18);
                        if (ret < 0) return ret;
                    }
                    break;
                case 6:
                    if (((SN_local *)z)->i_p1 > z->c) goto lab21;
                    if (!r_V(z)) goto lab21;
                    {
                        int ret = slice_from_s(z, 1, s_14);
                        if (ret < 0) return ret;
                    }
                    break;
                case 7:
                    if (((SN_local *)z)->i_p1 > z->c) goto lab21;
                    {
                        int ret = slice_from_s(z, 4, s_20);
                        if (ret < 0) return ret;
                    }
                    break;
                case 8:
                    if (((SN_local *)z)->i_p1 > z->c) goto lab21;
                    {
                        int ret = slice_from_s(z, 4, s_18);
                        if (ret < 0) return ret;
                    }
                    break;
                case 9:
                    if (((SN_local *)z)->i_p1 > z->c) goto lab21;
                    if (!r_C(z)) goto lab21;
                    {
                        int ret = slice_del(z);
                        if (ret < 0) return ret;
                    }
                    {
                        int ret = r_lengthen_V(z);
                        if (ret < 0) return ret;
                    }
                    break;
            }
            break;
        lab21:
            z->c = z->l - v_13;
            z->ket = z->c;
            if (z->c - 1 <= z->lb || z->p[z->c - 1] >> 5 != 3 || !((1310848 >> (z->p[z->c - 1] & 0x1f)) & 1)) goto lab20;
            if (!find_among_b(z, a_5)) goto lab20;
            z->bra = z->c;
            if (((SN_local *)z)->i_p1 > z->c) goto lab20;
            {
                int v_14 = z->l - z->c;
                if (!(eq_s_b(z, 3, s_28))) goto lab22;
                if (z->c > z->lb) goto lab22;
                goto lab20;
            lab22:
                z->c = z->l - v_14;
            }
            if (!r_C(z)) goto lab20;
            {
                int ret = slice_del(z);
                if (ret < 0) return ret;
            }
            {
                int ret = r_lengthen_V(z);
                if (ret < 0) return ret;
            }
        } while (0);
        b_stemmed = 1;
    lab20:
        z->c = z->l - v_12;
    }
    z->c = z->lb;
    b_GE_removed = 0;
    {
        int v_15 = z->c;
        {
            int v_16 = z->c;
            z->bra = z->c;
            if (!(eq_s(z, 2, s_17))) goto lab23;
            z->ket = z->c;
            {
                int v_17 = z->c;
                {
                    int ret = skip_utf8(z->p, z->c, z->l, 3);
                    if (ret < 0) goto lab23;
                    z->c = ret;
                }
                z->c = v_17;
            }
            {
                int v_18 = z->c;
                while (1) {
                    int v_19 = z->c;
                    do {
                        if (!(eq_s(z, 2, s_0))) goto lab25;
                        break;
                    lab25:
                        if (in_grouping_U(z, g_v, 97, 252, 0)) goto lab24;
                    } while (0);
                    break;
                lab24:
                    z->c = v_19;
                    {
                        int ret = skip_utf8(z->p, z->c, z->l, 1);
                        if (ret < 0) goto lab23;
                        z->c = ret;
                    }
                }
                while (1) {
                    int v_20 = z->c;
                    do {
                        if (!(eq_s(z, 2, s_0))) goto lab27;
                        break;
                    lab27:
                        if (in_grouping_U(z, g_v, 97, 252, 0)) goto lab26;
                    } while (0);
                    continue;
                lab26:
                    z->c = v_20;
                    break;
                }
                if (z->c >= z->l) goto lab23;
                z->c = v_18;
            }
            if (z->c + 2 >= z->l || z->p[z->c + 2] >> 5 != 3 || !((1314818 >> (z->p[z->c + 2] & 0x1f)) & 1)) among_var = -1; else
            among_var = find_among(z, a_9);
            switch (among_var) {
                case 1:
                    goto lab23;
                    break;
            }
            b_GE_removed = 1;
            {
                int ret = slice_del(z);
                if (ret < 0) return ret;
            }
            {
                int v_21 = z->c;
                z->bra = z->c;
                if (z->c + 1 >= z->l || (z->p[z->c + 1] != 171 && z->p[z->c + 1] != 175)) goto lab28;
                among_var = find_among(z, a_10);
                if (!among_var) goto lab28;
                z->ket = z->c;
                switch (among_var) {
                    case 1:
                        {
                            int ret = slice_from_s(z, 1, s_1);
                            if (ret < 0) return ret;
                        }
                        break;
                    case 2:
                        {
                            int ret = slice_from_s(z, 1, s_0);
                            if (ret < 0) return ret;
                        }
                        break;
                }
            lab28:
                z->c = v_21;
            }
            z->c = v_16;
            r_measure(z);
        }
    lab23:
        z->c = v_15;
    }
    z->lb = z->c; z->c = z->l;
    {
        int v_22 = z->l - z->c;
        if (!b_GE_removed) goto lab29;
        b_stemmed = 1;
        {
            int ret = r_Step_1c(z);
            if (ret == 0) goto lab29;
            if (ret < 0) return ret;
        }
    lab29:
        z->c = z->l - v_22;
    }
    z->c = z->lb;
    b_GE_removed = 0;
    {
        int v_23 = z->c;
        {
            int v_24 = z->c;
            {
                int ret = skip_utf8(z->p, z->c, z->l, 1);
                if (ret < 0) goto lab30;
                z->c = ret;
            }
            while (1) {
                z->bra = z->c;
                if (!(eq_s(z, 2, s_17))) goto lab31;
                z->ket = z->c;
                break;
            lab31:
                {
                    int ret = skip_utf8(z->p, z->c, z->l, 1);
                    if (ret < 0) goto lab30;
                    z->c = ret;
                }
            }
            {
                int v_25 = z->c;
                {
                    int ret = skip_utf8(z->p, z->c, z->l, 3);
                    if (ret < 0) goto lab30;
                    z->c = ret;
                }
                z->c = v_25;
            }
            {
                int v_26 = z->c;
                while (1) {
                    int v_27 = z->c;
                    do {
                        if (!(eq_s(z, 2, s_0))) goto lab33;
                        break;
                    lab33:
                        if (in_grouping_U(z, g_v, 97, 252, 0)) goto lab32;
                    } while (0);
                    break;
                lab32:
                    z->c = v_27;
                    {
                        int ret = skip_utf8(z->p, z->c, z->l, 1);
                        if (ret < 0) goto lab30;
                        z->c = ret;
                    }
                }
                while (1) {
                    int v_28 = z->c;
                    do {
                        if (!(eq_s(z, 2, s_0))) goto lab35;
                        break;
                    lab35:
                        if (in_grouping_U(z, g_v, 97, 252, 0)) goto lab34;
                    } while (0);
                    continue;
                lab34:
                    z->c = v_28;
                    break;
                }
                if (z->c >= z->l) goto lab30;
                z->c = v_26;
            }
            b_GE_removed = 1;
            {
                int ret = slice_del(z);
                if (ret < 0) return ret;
            }
            {
                int v_29 = z->c;
                z->bra = z->c;
                if (z->c + 1 >= z->l || (z->p[z->c + 1] != 171 && z->p[z->c + 1] != 175)) goto lab36;
                among_var = find_among(z, a_11);
                if (!among_var) goto lab36;
                z->ket = z->c;
                switch (among_var) {
                    case 1:
                        {
                            int ret = slice_from_s(z, 1, s_1);
                            if (ret < 0) return ret;
                        }
                        break;
                    case 2:
                        {
                            int ret = slice_from_s(z, 1, s_0);
                            if (ret < 0) return ret;
                        }
                        break;
                }
            lab36:
                z->c = v_29;
            }
            z->c = v_24;
            r_measure(z);
        }
    lab30:
        z->c = v_23;
    }
    z->lb = z->c; z->c = z->l;
    {
        int v_30 = z->l - z->c;
        if (!b_GE_removed) goto lab37;
        b_stemmed = 1;
        {
            int ret = r_Step_1c(z);
            if (ret == 0) goto lab37;
            if (ret < 0) return ret;
        }
    lab37:
        z->c = z->l - v_30;
    }
    z->c = z->lb;
    z->lb = z->c; z->c = z->l;
    {
        int v_31 = z->l - z->c;
        z->ket = z->c;
        if (z->c - 1 <= z->lb || z->p[z->c - 1] != 116) goto lab38;
        among_var = find_among_b(z, a_6);
        if (!among_var) goto lab38;
        z->bra = z->c;
        switch (among_var) {
            case 1:
                {
                    int ret = slice_from_s(z, 1, s_29);
                    if (ret < 0) return ret;
                }
                break;
            case 2:
                {
                    int ret = slice_from_s(z, 1, s_26);
                    if (ret < 0) return ret;
                }
                break;
            case 3:
                {
                    int ret = slice_from_s(z, 1, s_30);
                    if (ret < 0) return ret;
                }
                break;
        }
        b_stemmed = 1;
    lab38:
        z->c = z->l - v_31;
    }
    {
        int v_32 = z->l - z->c;
        if (!b_stemmed) goto lab39;
        z->ket = z->c;
        if (z->c <= z->lb || z->p[z->c - 1] >> 5 != 3 || !((98532828 >> (z->p[z->c - 1] & 0x1f)) & 1)) goto lab39;
        among_var = find_among_b(z, a_7);
        if (!among_var) goto lab39;
        z->bra = z->c;
        switch (among_var) {
            case 1:
                {
                    int ret = slice_from_s(z, 1, s_31);
                    if (ret < 0) return ret;
                }
                break;
            case 2:
                {
                    int ret = slice_from_s(z, 1, s_32);
                    if (ret < 0) return ret;
                }
                break;
            case 3:
                {
                    int ret = slice_from_s(z, 1, s_27);
                    if (ret < 0) return ret;
                }
                break;
            case 4:
                {
                    int ret = slice_from_s(z, 1, s_26);
                    if (ret < 0) return ret;
                }
                break;
            case 5:
                {
                    int ret = slice_from_s(z, 1, s_17);
                    if (ret < 0) return ret;
                }
                break;
            case 6:
                {
                    int ret = slice_from_s(z, 1, s_10);
                    if (ret < 0) return ret;
                }
                break;
            case 7:
                {
                    int ret = slice_from_s(z, 1, s_33);
                    if (ret < 0) return ret;
                }
                break;
            case 8:
                {
                    int ret = slice_from_s(z, 1, s_29);
                    if (ret < 0) return ret;
                }
                break;
            case 9:
                {
                    int ret = slice_from_s(z, 1, s_18);
                    if (ret < 0) return ret;
                }
                break;
            case 10:
                {
                    int ret = slice_from_s(z, 1, s_16);
                    if (ret < 0) return ret;
                }
                break;
            case 11:
                {
                    int v_33 = z->l - z->c;
                    if (z->c <= z->lb || z->p[z->c - 1] != 'i') goto lab40;
                    z->c--;
                    if (z->c > z->lb) goto lab40;
                    goto lab39;
                lab40:
                    z->c = z->l - v_33;
                }
                {
                    int ret = slice_from_s(z, 1, s_4);
                    if (ret < 0) return ret;
                }
                break;
            case 12:
                {
                    int ret = slice_from_s(z, 1, s_30);
                    if (ret < 0) return ret;
                }
                break;
            case 13:
                {
                    int ret = slice_from_s(z, 1, s_34);
                    if (ret < 0) return ret;
                }
                break;
            case 14:
                {
                    int ret = slice_from_s(z, 1, s_14);
                    if (ret < 0) return ret;
                }
                break;
            case 15:
                {
                    int ret = slice_from_s(z, 1, s_21);
                    if (ret < 0) return ret;
                }
                break;
            case 16:
                {
                    int ret = slice_from_s(z, 1, s_20);
                    if (ret < 0) return ret;
                }
                break;
            case 17:
                {
                    int ret = slice_from_s(z, 1, s_35);
                    if (ret < 0) return ret;
                }
                break;
            case 18:
                {
                    int ret = slice_from_s(z, 1, s_36);
                    if (ret < 0) return ret;
                }
                break;
            case 19:
                {
                    int ret = slice_from_s(z, 1, s_37);
                    if (ret < 0) return ret;
                }
                break;
            case 20:
                {
                    int ret = slice_from_s(z, 1, s_38);
                    if (ret < 0) return ret;
                }
                break;
        }
    lab39:
        z->c = z->l - v_32;
    }
    z->c = z->lb;
    return 1;
}

extern struct SN_env * dutch_UTF_8_create_env(void) {
    struct SN_env * z = SN_new_env(sizeof(SN_local));
    if (z) {
        if ((((SN_local *)z)->s_ch = create_s()) == NULL) {
            dutch_UTF_8_close_env(z);
            return NULL;
        }
    }
    return z;
}

extern void dutch_UTF_8_close_env(struct SN_env * z) {
    if (!z) return;
    lose_s(((SN_local *)z)->s_ch);
    SN_delete_env(z);
}


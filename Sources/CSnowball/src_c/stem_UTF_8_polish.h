/* Generated from polish.sbl by Snowball 3.2.0 - https://snowballstem.org/ */

#ifdef __cplusplus
extern "C" {
#endif

struct SN_env;

extern struct SN_env * polish_UTF_8_create_env(void);
#define polish_UTF_8_close_env SN_delete_env

extern int polish_UTF_8_stem(struct SN_env * z);

#ifdef __cplusplus
}
#endif

#include "include/StemmerBridge.h"

#include <limits.h>
#include <string.h>

#include "runtime/snowball_runtime.h"
#include "src_c/stem_UTF_8_dutch.h"
#include "src_c/stem_UTF_8_english.h"
#include "src_c/stem_UTF_8_french.h"
#include "src_c/stem_UTF_8_german.h"
#include "src_c/stem_UTF_8_italian.h"
#include "src_c/stem_UTF_8_polish.h"
#include "src_c/stem_UTF_8_portuguese.h"
#include "src_c/stem_UTF_8_russian.h"
#include "src_c/stem_UTF_8_spanish.h"

typedef int (*StemFunction)(struct SN_env *);
typedef struct SN_env *(*CreateEnvironment)(void);
typedef void (*CloseEnvironment)(struct SN_env *);

static int functions_for_language(
    const char *language, StemFunction *stem, CreateEnvironment *create, CloseEnvironment *close)
{
#define USE_STEMMER(NAME) \
    *stem = NAME##_UTF_8_stem; \
    *create = NAME##_UTF_8_create_env; \
    *close = NAME##_UTF_8_close_env

    if (strcmp(language, "en") == 0) {
        USE_STEMMER(english);
    } else if (strcmp(language, "ru") == 0) {
        USE_STEMMER(russian);
    } else if (strcmp(language, "de") == 0) {
        USE_STEMMER(german);
    } else if (strcmp(language, "es") == 0) {
        USE_STEMMER(spanish);
    } else if (strcmp(language, "fr") == 0) {
        USE_STEMMER(french);
    } else if (strcmp(language, "it") == 0) {
        USE_STEMMER(italian);
    } else if (strcmp(language, "pt") == 0) {
        USE_STEMMER(portuguese);
    } else if (strcmp(language, "nl") == 0) {
        USE_STEMMER(dutch);
    } else if (strcmp(language, "pl") == 0) {
        USE_STEMMER(polish);
    } else {
        return 0;
    }
#undef USE_STEMMER
    return 1;
}

int csnowball_stem(const char *language, const char *input, char *output, size_t output_capacity)
{
    StemFunction stem = NULL;
    CreateEnvironment create = NULL;
    CloseEnvironment close = NULL;
    struct SN_env *environment = NULL;
    size_t input_length;
    int result = -1;

    if (language == NULL || input == NULL || output == NULL || output_capacity == 0 ||
        !functions_for_language(language, &stem, &create, &close)) {
        return -1;
    }
    input_length = strlen(input);
    if (input_length > INT_MAX) {
        return -1;
    }
    environment = create();
    if (environment == NULL) {
        goto cleanup;
    }
    if (SN_set_current(environment, (int)input_length, (const symbol *)input) < 0 || stem(environment) < 0) {
        goto cleanup;
    }
    if ((size_t)environment->l + 1 > output_capacity) {
        goto cleanup;
    }
    memcpy(output, environment->p, (size_t)environment->l);
    output[environment->l] = '\0';
    result = environment->l;

cleanup:
    if (environment != NULL) {
        close(environment);
    }
    return result;
}

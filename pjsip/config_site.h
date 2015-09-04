#define PJ_CONFIG_IPHONE 1
#define PJ_IPHONE_OS_HAS_MULTITASKING_SUPPORT 1
#define PJ_ACTIVESOCK_TCP_IPHONE_OS_BG 1
// Disable conferencing use switch board, to decrease latency: https://trac.pjsip.org/repos/wiki/FAQ#audio-latency
#define PJMEDIA_CONF_USE_SWITCH_BOARD 1
#include <pj/config_site_sample.h>

// enable G729
#define PJMEDIA_HAS_G729_CODEC 1


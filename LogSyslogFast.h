#ifndef __LOGSYSLOGFAST_H__
#define __LOGSYSLOGFAST_H__

#include <time.h>

#define LOG_RFC3164 0
#define LOG_RFC5424 1

/* must match constants in LogSyslogFast.pm */
#define LOG_UDP  0
#define LOG_TCP  1
#define LOG_UNIX 2
#define LOG_TLS  3

#ifdef USE_TLS
#include <openssl/ssl.h>
#include <openssl/err.h>
#endif

typedef struct {

    /* configuration */
    int    priority;            /* RFC3164/4.1.1 PRI Part */
    char*  sender;              /* sender hostname */
    char*  name;                /* sending program name */
    int    pid;                 /* sending program pid */
    int    format;              /* RFC3164 or RFC5424 */

    /* resource handles */
    int    sock;                /* socket fd */

    /* internal state */
    time_t last_time;           /* time when the prefix was last generated */
    char*  linebuf;             /* log line, including prefix and message */
    int    bufsize;             /* current size of linebuf */
    size_t prefix_len;          /* length of the prefix string */
    char*  msg_start;           /* pointer into linebuf after end of prefix */
    const char* time_format;    /* strftime format string */
    const char* msg_format;     /* snprintf format string */

#ifdef USE_TLS
    /* TLS handles */
    SSL_CTX *ssl_client_ctx;
    SSL *clientssl;
#endif 

    /* error reporting */
    const char* err;            /* error string */

} LogSyslogFast;

typedef struct {

    char* hostname;

    char* cert_file;
    char* cert;

    char* key_file;
    char* key;

    char* ca_file;
    char* ca;
    char* ca_path;

    int   check_crl;
    char* crl_file;

    int   verify_mode;
    int   verify_depth;
} SSLopts;


LogSyslogFast* LSF_alloc();
SSLopts*       LSF_ssl_opts_alloc();
int LSF_init(LogSyslogFast* logger, int proto, const char* hostname, int port, int facility, int severity, const char* sender, const char* name, SSLopts* ssl_opts);
int LSF_destroy(LogSyslogFast* logger);

#ifdef USE_TLS
int LSF_set_ssl_opts(LogSyslogFast* logger, SSLopts* ssl_opts);
#endif
int LSF_set_receiver(LogSyslogFast* logger, int proto, const char* hostname, int port, SSLopts* ssl_opts);

void LSF_set_priority(LogSyslogFast* logger, int facility, int severity);
void LSF_set_facility(LogSyslogFast* logger, int facility);
void LSF_set_severity(LogSyslogFast* logger, int severity);
int LSF_set_sender(LogSyslogFast* logger, const char* sender);
int LSF_set_name(LogSyslogFast* logger, const char* name);
void LSF_set_pid(LogSyslogFast* logger, int pid);
int LSF_set_format(LogSyslogFast* logger, int format);

int LSF_get_priority(LogSyslogFast* logger);
int LSF_get_facility(LogSyslogFast* logger);
int LSF_get_severity(LogSyslogFast* logger);
const char* LSF_get_sender(LogSyslogFast* logger);
const char* LSF_get_name(LogSyslogFast* logger);
int LSF_get_pid(LogSyslogFast* logger);
int LSF_get_format(LogSyslogFast* logger);
int LSF_get_tls(LogSyslogFast* logger);
int LSF_can_tls();

int LSF_get_sock(LogSyslogFast* logger);

int LSF_send(LogSyslogFast* logger, const char* msg, int len, time_t t);

#endif

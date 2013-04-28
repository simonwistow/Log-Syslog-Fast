#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "LogSyslogFast.h"

#include "const-c.inc"

static void option(SSLopts* ssl_opts, SV *tag, SV *value)
{
    STRLEN len, len2;
    char *key = SvPV(tag, len);
    char *val = SvPV(value, len2);
    
    if (!strcmp(key, "SSL_hostname")) {
        ssl_opts->hostname = val;
    } else if (!strcmp(key, "SSL_cert_file")) {
        ssl_opts->cert_file = val;
    } else if (!strcmp(key, "SSL_cert")) {
        ssl_opts->cert = val;
    } else if (!strcmp(key, "SSL_key_file")) {
        ssl_opts->key_file = val;
    } else if (!strcmp(key, "SSL_key")) {
        ssl_opts->key = val;
    } else if (!strcmp(key, "SSL_ca_file")) {
        ssl_opts->ca_file = val;
    } else if (!strcmp(key, "SSL_ca_path")) {
        ssl_opts->ca_path = val;
    } else if (!strcmp(key, "SSL_verify_mode")) {
        ssl_opts->verify_mode = atoi(val);
    } else if (!strcmp(key, "SSL_check_crl")) {
        ssl_opts->check_crl = 1;
    } else if (!strcmp(key, "SSL_crl_file")) {
        ssl_opts->crl_file = val;
    } else {
       warn("Unknown option %s => %s", key, val); 
    }
}

MODULE = Log::Syslog::Fast		PACKAGE = Log::Syslog::Fast

INCLUDE: const-xs.inc

PROTOTYPES: ENABLE

LogSyslogFast*
new(class, proto, hostname, port, facility, severity, sender, name, ...)
    char* class
    int proto
    char* hostname
    int port
    int facility
    int severity
    char* sender
    char* name
CODE:
    if (!hostname)
        croak("hostname required");
    if (!sender)
        croak("sender required");
    if (!name)
        croak("name required");

    if (items-8 % 2 == 0) croak("Odd number of elements in options");        

    SSLopts* ssl_opts = LSF_ssl_opts_alloc();
    int i;
    for (i = 8; i < items; i += 2) option(ssl_opts, ST(i), ST(i + 1));
    
    RETVAL = LSF_alloc();
    if (!RETVAL)
        croak("Error in ->new: malloc failed");
    if (LSF_init(RETVAL, proto, hostname, port, facility, severity, sender, name, ssl_opts) < 0)
        croak("Error in ->new: %s", RETVAL->err);

    free(ssl_opts);
OUTPUT:
    RETVAL

void
DESTROY(logger)
    LogSyslogFast* logger
CODE:
    if (LSF_destroy(logger))
        croak("Error in close: %s", logger->err);

int
send(logger, logmsg, now = time(0))
    LogSyslogFast* logger
    SV* logmsg
    time_t now
ALIAS:
    emit = 1
INIT:
    STRLEN msglen;
    const char* msgstr;
    msgstr = SvPV(logmsg, msglen);
CODE:
    RETVAL = LSF_send(logger, msgstr, msglen, now);
    if (RETVAL < 0)
        croak("Error while sending: %s", logger->err);
OUTPUT:
    RETVAL

void
set_receiver(logger, proto, hostname, port, ...)
    LogSyslogFast* logger
    int proto
    char* hostname
    int port
ALIAS:
    setReceiver = 1
CODE:
    if (!hostname)
        croak("hostname required");
    
    if (items-4 % 2 == 0) croak("Odd number of elements in options");        

    SSLopts* ssl_opts = LSF_ssl_opts_alloc();
    int i;
    for (i = 4; i < items; i += 2) option(ssl_opts, ST(i), ST(i + 1));
        
    int ret = LSF_set_receiver(logger, proto, hostname, port, ssl_opts);
    
    free(ssl_opts);
    
    if (ret < 0)
        croak("Error in set_receiver: %s", logger->err);

void
set_priority(logger, facility, severity)
    LogSyslogFast* logger
    int facility
    int severity
ALIAS:
    setPriority = 1
CODE:
    LSF_set_priority(logger, facility, severity);

void
set_facility(logger, facility)
    LogSyslogFast* logger
    int facility
CODE:
    LSF_set_facility(logger, facility);

void
set_severity(logger, severity)
    LogSyslogFast* logger
    int severity
CODE:
    LSF_set_severity(logger, severity);

void
set_sender(logger, sender)
    LogSyslogFast* logger
    char* sender
ALIAS:
    setSender = 1
CODE:
    if (!sender)
        croak("sender required");
    int ret = LSF_set_sender(logger, sender);
    if (ret < 0)
        croak("Error in set_sender: %s", logger->err);

void
set_name(logger, name)
    LogSyslogFast* logger
    char* name
ALIAS:
    setName = 1
CODE:
    if (!name)
        croak("name required");
    int ret = LSF_set_name(logger, name);
    if (ret < 0)
        croak("Error in set_name: %s", logger->err);

void
set_pid(logger, pid)
    LogSyslogFast* logger
    int pid
ALIAS:
    setPid = 1
CODE:
    LSF_set_pid(logger, pid);

void
set_format(logger, format)
    LogSyslogFast* logger
    int format
ALIAS:
    setFormat = 1
CODE:
    int ret = LSF_set_format(logger, format);
    if (ret < 0)
        croak("Error in set_format: %s", logger->err);

void
set_tls(logger, tls)
    LogSyslogFast* logger
    int tls
ALIAS:
    setTLS = 1
CODE:
    if (tls)
      croak("TLS not supported in XS module. Try ::PP");

int
get_priority(logger)
    LogSyslogFast* logger
CODE:
    RETVAL = LSF_get_priority(logger);
OUTPUT:
    RETVAL

int
get_facility(logger)
    LogSyslogFast* logger
CODE:
    RETVAL = LSF_get_facility(logger);
OUTPUT:
    RETVAL

int
get_severity(logger)
    LogSyslogFast* logger
CODE:
    RETVAL = LSF_get_severity(logger);
OUTPUT:
    RETVAL

const char*
get_sender(logger)
    LogSyslogFast* logger
CODE:
    RETVAL = LSF_get_sender(logger);
OUTPUT:
    RETVAL

const char*
get_name(logger)
    LogSyslogFast* logger
CODE:
    RETVAL = LSF_get_name(logger);
OUTPUT:
    RETVAL

int
get_pid(logger)
    LogSyslogFast* logger
CODE:
    RETVAL = LSF_get_pid(logger);
OUTPUT:
    RETVAL

int
get_format(logger)
    LogSyslogFast* logger
CODE:
    RETVAL = LSF_get_format(logger);
OUTPUT:
    RETVAL
    
int
get_tls(logger)
    LogSyslogFast* logger
CODE:
    RETVAL = LSF_get_tls(logger);
OUTPUT:
    RETVAL

int
can_tls(...)
CODE:
    RETVAL = LSF_can_tls();
OUTPUT:
    RETVAL

int
_get_sock(logger)
    LogSyslogFast* logger
CODE:
    RETVAL = LSF_get_sock(logger);
OUTPUT:
    RETVAL

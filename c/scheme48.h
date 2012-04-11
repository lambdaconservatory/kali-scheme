typedef long scheme_value;

#define FIXNUM_TAG 0
#define FIXNUMP(x) (((long)(x) & 3L) == FIXNUM_TAG)
#define IMMEDIATE_TAG 1
#define IMMEDIATEP(x) (((long)(x) & 3L) == IMMEDIATE_TAG)
#define HEADER_TAG 2
#define HEADERP(x) (((long)(x) & 3L) == HEADER_TAG)
#define STOB_TAG 3
#define STOBP(x) (((long)(x) & 3L) == STOB_TAG)

#define ENTER_FIXNUM(n)   ((scheme_value)((n) << 2))
#define EXTRACT_FIXNUM(x) ((long)(x) >> 2)

#define MISC_IMMEDIATE(n) (scheme_value)(IMMEDIATE_TAG | ((n) << 2))
#define SCHFALSE    MISC_IMMEDIATE(0)
#define SCHTRUE    MISC_IMMEDIATE(1)
#define SCHCHAR    MISC_IMMEDIATE(2)
#define SCHUNSPECIFIC    MISC_IMMEDIATE(3)
#define SCHUNDEFINED    MISC_IMMEDIATE(4)
#define SCHEOF    MISC_IMMEDIATE(5)
#define SCHNULL    MISC_IMMEDIATE(6)
#define UNDEFINED SCHUNDEFINED
#define UNSPECIFIC SCHUNSPECIFIC

#define ENTER_BOOLEAN(n) ((n) ? SCHTRUE : SCHFALSE)
#define EXTRACT_BOOLEAN(x) ((x) != SCHFALSE)

#define ENTER_CHAR(c) (SCHCHAR | ((c) << 8))
#define EXTRACT_CHAR(x) ((x) >> 8)
#define CHARP(x) ((((long) (x)) & 0xff) == SCHCHAR)

#define ADDRESS_AFTER_HEADER(x, type) ((type *)((x) - STOB_TAG))
#define STOB_REF(x, i) ((ADDRESS_AFTER_HEADER(x, long))[i])
#define STOB_TYPE(x)   ((STOB_HEADER(x)>>2)&31)
#define STOB_HEADER(x) (STOB_REF((x),-1))
#define STOB_BLENGTH(x) (STOB_HEADER(x) >> 8)
#define STOB_LLENGTH(x) (STOB_HEADER(x) >> 10)

#define STOBTYPE_PAIR 0
#define PAIRP(x) (STOBP(x) && (STOB_TYPE(x) == STOBTYPE_PAIR))
#define STOBTYPE_SYMBOL 1
#define SYMBOLP(x) (STOBP(x) && (STOB_TYPE(x) == STOBTYPE_SYMBOL))
#define STOBTYPE_VECTOR 2
#define VECTORP(x) (STOBP(x) && (STOB_TYPE(x) == STOBTYPE_VECTOR))
#define STOBTYPE_CLOSURE 3
#define CLOSUREP(x) (STOBP(x) && (STOB_TYPE(x) == STOBTYPE_CLOSURE))
#define STOBTYPE_LOCATION 4
#define LOCATIONP(x) (STOBP(x) && (STOB_TYPE(x) == STOBTYPE_LOCATION))
#define STOBTYPE_CHANNEL 5
#define CHANNELP(x) (STOBP(x) && (STOB_TYPE(x) == STOBTYPE_CHANNEL))
#define STOBTYPE_PORT 6
#define PORTP(x) (STOBP(x) && (STOB_TYPE(x) == STOBTYPE_PORT))
#define STOBTYPE_RATNUM 7
#define RATNUMP(x) (STOBP(x) && (STOB_TYPE(x) == STOBTYPE_RATNUM))
#define STOBTYPE_RECORD 8
#define RECORDP(x) (STOBP(x) && (STOB_TYPE(x) == STOBTYPE_RECORD))
#define STOBTYPE_CONTINUATION 9
#define CONTINUATIONP(x) (STOBP(x) && (STOB_TYPE(x) == STOBTYPE_CONTINUATION))
#define STOBTYPE_EXTENDED_NUMBER 10
#define EXTENDED_NUMBERP(x) (STOBP(x) && (STOB_TYPE(x) == STOBTYPE_EXTENDED_NUMBER))
#define STOBTYPE_TEMPLATE 11
#define TEMPLATEP(x) (STOBP(x) && (STOB_TYPE(x) == STOBTYPE_TEMPLATE))
#define STOBTYPE_WEAK_POINTER 12
#define WEAK_POINTERP(x) (STOBP(x) && (STOB_TYPE(x) == STOBTYPE_WEAK_POINTER))
#define STOBTYPE_EXTERNAL 13
#define EXTERNALP(x) (STOBP(x) && (STOB_TYPE(x) == STOBTYPE_EXTERNAL))
#define STOBTYPE_UNUSED_D_HEADER1 14
#define UNUSED_D_HEADER1P(x) (STOBP(x) && (STOB_TYPE(x) == STOBTYPE_UNUSED_D_HEADER1))
#define STOBTYPE_UNUSED_D_HEADER2 15
#define UNUSED_D_HEADER2P(x) (STOBP(x) && (STOB_TYPE(x) == STOBTYPE_UNUSED_D_HEADER2))
#define STOBTYPE_STRING 16
#define STRINGP(x) (STOBP(x) && (STOB_TYPE(x) == STOBTYPE_STRING))
#define STOBTYPE_CODE_VECTOR 17
#define CODE_VECTORP(x) (STOBP(x) && (STOB_TYPE(x) == STOBTYPE_CODE_VECTOR))
#define STOBTYPE_DOUBLE 18
#define DOUBLEP(x) (STOBP(x) && (STOB_TYPE(x) == STOBTYPE_DOUBLE))
#define STOBTYPE_BIGNUM 19
#define BIGNUMP(x) (STOBP(x) && (STOB_TYPE(x) == STOBTYPE_BIGNUM))

#define CAR(x) STOB_REF(x, 0)
#define CDR(x) STOB_REF(x, 1)
#define SYMBOL_TO_STRING(x) STOB_REF(x, 0)
#define LOCATION_ID(x) STOB_REF(x, 0)
#define CONTENTS(x) STOB_REF(x, 1)
#define CLOSURE_TEMPLATE(x) STOB_REF(x, 0)
#define CLOSURE_ENV(x) STOB_REF(x, 1)
#define WEAK_POINTER_REF(x) STOB_REF(x, 0)
#define EXTERNAL_NAME(x) STOB_REF(x, 0)
#define EXTERNAL_VALUE(x) STOB_REF(x, 1)
#define PORT_HANDLER(x) STOB_REF(x, 0)
#define PORT_STATUS(x) STOB_REF(x, 1)
#define PORT_LOCK(x) STOB_REF(x, 2)
#define PORT_LOCKEDP(x) STOB_REF(x, 3)
#define PORT_DATA(x) STOB_REF(x, 4)
#define PORT_BUFFER(x) STOB_REF(x, 5)
#define PORT_INDEX(x) STOB_REF(x, 6)
#define PORT_LIMIT(x) STOB_REF(x, 7)
#define PORT_PENDING_EOFP(x) STOB_REF(x, 8)
#define CHANNEL_STATUS(x) STOB_REF(x, 0)
#define CHANNEL_ID(x) STOB_REF(x, 1)
#define CHANNEL_OS_INDEX(x) STOB_REF(x, 2)

#define VECTOR_LENGTH(x) STOB_LLENGTH(x)
#define VECTOR_REF(x, i) STOB_REF(x, i)
#define CODE_VECTOR_LENGTH(x)  STOB_BLENGTH(x)
#define CODE_VECTOR_REF(x, i)  (ADDRESS_AFTER_HEADER(x, unsigned char)[i])
#define STRING_LENGTH(x)  (STOB_BLENGTH(x)-1)
#define STRING_REF(x, i)  (ADDRESS_AFTER_HEADER(x, char)[i])

/* A Bison parser, made by GNU Bison 2.3.  */

/* Skeleton implementation for Bison's Yacc-like parsers in C

   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006
   Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output.  */
#define YYBISON 1

/* Bison version.  */
#define YYBISON_VERSION "2.3"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 0

/* Using locations.  */
#define YYLSP_NEEDED 0



/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     sySkip = 258,
     syRoutine = 259,
     sySimpleRoutine = 260,
     sySubsystem = 261,
     syKernelUser = 262,
     syKernelServer = 263,
     syMsgOption = 264,
     syUseSpecialReplyPort = 265,
     syConsumeOnSendError = 266,
     syMsgSeqno = 267,
     syWaitTime = 268,
     sySendTime = 269,
     syNoWaitTime = 270,
     syNoSendTime = 271,
     syErrorProc = 272,
     syServerPrefix = 273,
     syUserPrefix = 274,
     syServerDemux = 275,
     syRCSId = 276,
     syImport = 277,
     syUImport = 278,
     sySImport = 279,
     syIImport = 280,
     syDImport = 281,
     syIn = 282,
     syOut = 283,
     syInOut = 284,
     syUserImpl = 285,
     syServerImpl = 286,
     syRequestPort = 287,
     syReplyPort = 288,
     sySReplyPort = 289,
     syUReplyPort = 290,
     syType = 291,
     syArray = 292,
     syStruct = 293,
     syOf = 294,
     syInTran = 295,
     syOutTran = 296,
     syDestructor = 297,
     syCType = 298,
     syCUserType = 299,
     syUserTypeLimit = 300,
     syOnStackLimit = 301,
     syCServerType = 302,
     syPointerTo = 303,
     syPointerToIfNot = 304,
     syValueOf = 305,
     syCString = 306,
     sySecToken = 307,
     syUserSecToken = 308,
     syServerSecToken = 309,
     syAuditToken = 310,
     syUserAuditToken = 311,
     syServerAuditToken = 312,
     syServerContextToken = 313,
     syColon = 314,
     sySemi = 315,
     syComma = 316,
     syPlus = 317,
     syMinus = 318,
     syStar = 319,
     syDiv = 320,
     syLParen = 321,
     syRParen = 322,
     syEqual = 323,
     syCaret = 324,
     syTilde = 325,
     syLAngle = 326,
     syRAngle = 327,
     syLBrack = 328,
     syRBrack = 329,
     syBar = 330,
     syError = 331,
     syNumber = 332,
     sySymbolicType = 333,
     syIdentifier = 334,
     syString = 335,
     syQString = 336,
     syFileName = 337,
     syIPCFlag = 338
   };
#endif
/* Tokens.  */
#define sySkip 258
#define syRoutine 259
#define sySimpleRoutine 260
#define sySubsystem 261
#define syKernelUser 262
#define syKernelServer 263
#define syMsgOption 264
#define syUseSpecialReplyPort 265
#define syConsumeOnSendError 266
#define syMsgSeqno 267
#define syWaitTime 268
#define sySendTime 269
#define syNoWaitTime 270
#define syNoSendTime 271
#define syErrorProc 272
#define syServerPrefix 273
#define syUserPrefix 274
#define syServerDemux 275
#define syRCSId 276
#define syImport 277
#define syUImport 278
#define sySImport 279
#define syIImport 280
#define syDImport 281
#define syIn 282
#define syOut 283
#define syInOut 284
#define syUserImpl 285
#define syServerImpl 286
#define syRequestPort 287
#define syReplyPort 288
#define sySReplyPort 289
#define syUReplyPort 290
#define syType 291
#define syArray 292
#define syStruct 293
#define syOf 294
#define syInTran 295
#define syOutTran 296
#define syDestructor 297
#define syCType 298
#define syCUserType 299
#define syUserTypeLimit 300
#define syOnStackLimit 301
#define syCServerType 302
#define syPointerTo 303
#define syPointerToIfNot 304
#define syValueOf 305
#define syCString 306
#define sySecToken 307
#define syUserSecToken 308
#define syServerSecToken 309
#define syAuditToken 310
#define syUserAuditToken 311
#define syServerAuditToken 312
#define syServerContextToken 313
#define syColon 314
#define sySemi 315
#define syComma 316
#define syPlus 317
#define syMinus 318
#define syStar 319
#define syDiv 320
#define syLParen 321
#define syRParen 322
#define syEqual 323
#define syCaret 324
#define syTilde 325
#define syLAngle 326
#define syRAngle 327
#define syLBrack 328
#define syRBrack 329
#define syBar 330
#define syError 331
#define syNumber 332
#define sySymbolicType 333
#define syIdentifier 334
#define syString 335
#define syQString 336
#define syFileName 337
#define syIPCFlag 338




/* Copy the first part of user declarations.  */
#line 156 "parser.y"


#include <stdio.h>
#include "lexxer.h"
#include "strdefs.h"
#include "type.h"
#include "routine.h"
#include "statement.h"
#include "global.h"
#include "error.h"

static char *import_name(statement_kind_t sk);
extern int yylex(void);

/* forward declaration */
void yyerror(char *s);



/* Enabling traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif

/* Enabling verbose error messages.  */
#ifdef YYERROR_VERBOSE
# undef YYERROR_VERBOSE
# define YYERROR_VERBOSE 1
#else
# define YYERROR_VERBOSE 0
#endif

/* Enabling the token table.  */
#ifndef YYTOKEN_TABLE
# define YYTOKEN_TABLE 0
#endif

#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE
#line 176 "parser.y"
{
    u_int number;
    identifier_t identifier;
    string_t string;
    statement_kind_t statement_kind;
    ipc_type_t *type;
    struct
    {
      u_int innumber;		/* msgt_name value, when sending */
      string_t instr;
      u_int outnumber;	/* msgt_name value, when receiving */
      string_t outstr;
      u_int size;		/* 0 means there is no default size */
    } symtype;
    routine_t *routine;
    arg_kind_t direction;
    argument_t *argument;
    ipc_flags_t flag;
}
/* Line 193 of yacc.c.  */
#line 301 "parser.c"
	YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif



/* Copy the second part of user declarations.  */


/* Line 216 of yacc.c.  */
#line 314 "parser.c"

#ifdef short
# undef short
#endif

#ifdef YYTYPE_UINT8
typedef YYTYPE_UINT8 yytype_uint8;
#else
typedef unsigned char yytype_uint8;
#endif

#ifdef YYTYPE_INT8
typedef YYTYPE_INT8 yytype_int8;
#elif (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
typedef signed char yytype_int8;
#else
typedef short int yytype_int8;
#endif

#ifdef YYTYPE_UINT16
typedef YYTYPE_UINT16 yytype_uint16;
#else
typedef unsigned short int yytype_uint16;
#endif

#ifdef YYTYPE_INT16
typedef YYTYPE_INT16 yytype_int16;
#else
typedef short int yytype_int16;
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif ! defined YYSIZE_T && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned int
# endif
#endif

#define YYSIZE_MAXIMUM ((YYSIZE_T) -1)

#ifndef YY_
# if defined YYENABLE_NLS && YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(msgid) dgettext ("bison-runtime", msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(msgid) msgid
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YYUSE(e) ((void) (e))
#else
# define YYUSE(e) /* empty */
#endif

/* Identity function, used to suppress warnings about constant conditions.  */
#ifndef lint
# define YYID(n) (n)
#else
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static int
YYID (int i)
#else
static int
YYID (i)
    int i;
#endif
{
  return i;
}
#endif

#if ! defined yyoverflow || YYERROR_VERBOSE

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# ifdef YYSTACK_USE_ALLOCA
#  if YYSTACK_USE_ALLOCA
#   ifdef __GNUC__
#    define YYSTACK_ALLOC __builtin_alloca
#   elif defined __BUILTIN_VA_ARG_INCR
#    include <alloca.h> /* INFRINGES ON USER NAME SPACE */
#   elif defined _AIX
#    define YYSTACK_ALLOC __alloca
#   elif defined _MSC_VER
#    include <malloc.h> /* INFRINGES ON USER NAME SPACE */
#    define alloca _alloca
#   else
#    define YYSTACK_ALLOC alloca
#    if ! defined _ALLOCA_H && ! defined _STDLIB_H && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#     ifndef _STDLIB_H
#      define _STDLIB_H 1
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's `empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (YYID (0))
#  ifndef YYSTACK_ALLOC_MAXIMUM
    /* The OS might guarantee only one guard page at the bottom of the stack,
       and a page size can be as small as 4096 bytes.  So we cannot safely
       invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
       to allow for a few compiler-allocated temporary stack slots.  */
#   define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2006 */
#  endif
# else
#  define YYSTACK_ALLOC YYMALLOC
#  define YYSTACK_FREE YYFREE
#  ifndef YYSTACK_ALLOC_MAXIMUM
#   define YYSTACK_ALLOC_MAXIMUM YYSIZE_MAXIMUM
#  endif
#  if (defined __cplusplus && ! defined _STDLIB_H \
       && ! ((defined YYMALLOC || defined malloc) \
	     && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef _STDLIB_H
#    define _STDLIB_H 1
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined _STDLIB_H && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined _STDLIB_H && (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
# endif
#endif /* ! defined yyoverflow || YYERROR_VERBOSE */


#if (! defined yyoverflow \
     && (! defined __cplusplus \
	 || (defined YYSTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yytype_int16 yyss;
  YYSTYPE yyvs;
  };

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (sizeof (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (sizeof (yytype_int16) + sizeof (YYSTYPE)) \
      + YYSTACK_GAP_MAXIMUM)

/* Copy COUNT objects from FROM to TO.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(To, From, Count) \
      __builtin_memcpy (To, From, (Count) * sizeof (*(From)))
#  else
#   define YYCOPY(To, From, Count)		\
      do					\
	{					\
	  YYSIZE_T yyi;				\
	  for (yyi = 0; yyi < (Count); yyi++)	\
	    (To)[yyi] = (From)[yyi];		\
	}					\
      while (YYID (0))
#  endif
# endif

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack)					\
    do									\
      {									\
	YYSIZE_T yynewbytes;						\
	YYCOPY (&yyptr->Stack, Stack, yysize);				\
	Stack = &yyptr->Stack;						\
	yynewbytes = yystacksize * sizeof (*Stack) + YYSTACK_GAP_MAXIMUM; \
	yyptr += yynewbytes / sizeof (*yyptr);				\
      }									\
    while (YYID (0))

#endif

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  2
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   271

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  84
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  52
/* YYNRULES -- Number of rules.  */
#define YYNRULES  134
/* YYNRULES -- Number of states.  */
#define YYNSTATES  255

/* YYTRANSLATE(YYLEX) -- Bison symbol number corresponding to YYLEX.  */
#define YYUNDEFTOK  2
#define YYMAXUTOK   338

#define YYTRANSLATE(YYX)						\
  ((unsigned int) (YYX) <= YYMAXUTOK ? yytranslate[YYX] : YYUNDEFTOK)

/* YYTRANSLATE[YYLEX] -- Bison symbol number corresponding to YYLEX.  */
static const yytype_uint8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39,    40,    41,    42,    43,    44,
      45,    46,    47,    48,    49,    50,    51,    52,    53,    54,
      55,    56,    57,    58,    59,    60,    61,    62,    63,    64,
      65,    66,    67,    68,    69,    70,    71,    72,    73,    74,
      75,    76,    77,    78,    79,    80,    81,    82,    83
};

#if YYDEBUG
/* YYPRHS[YYN] -- Index of the first RHS symbol of rule number YYN in
   YYRHS.  */
static const yytype_uint16 yyprhs[] =
{
       0,     0,     3,     4,     7,    10,    13,    16,    19,    22,
      25,    28,    31,    34,    37,    40,    43,    46,    49,    52,
      55,    58,    60,    63,    68,    70,    71,    74,    76,    78,
      80,    82,    86,    89,    93,    96,    99,   103,   105,   109,
     111,   114,   117,   120,   123,   127,   129,   131,   133,   135,
     137,   141,   144,   148,   150,   159,   168,   176,   181,   186,
     191,   193,   195,   198,   201,   204,   207,   209,   211,   216,
     223,   228,   230,   237,   239,   241,   243,   247,   249,   254,
     260,   268,   274,   280,   285,   292,   294,   297,   301,   305,
     309,   313,   315,   319,   321,   323,   327,   331,   334,   338,
     340,   342,   346,   350,   355,   359,   360,   362,   364,   366,
     368,   370,   372,   374,   376,   378,   380,   382,   384,   386,
     388,   390,   392,   394,   396,   398,   400,   403,   406,   409,
     410,   414,   420,   421,   422
};

/* YYRHS -- A `-1'-separated list of the rules' RHS.  */
static const yytype_int16 yyrhs[] =
{
      85,     0,    -1,    -1,    85,    86,    -1,    87,    60,    -1,
      98,    60,    -1,    99,    60,    -1,    93,    60,    -1,    94,
      60,    -1,    95,    60,    -1,    96,    60,    -1,    97,    60,
      -1,   100,    60,    -1,   101,    60,    -1,   102,    60,    -1,
     103,    60,    -1,   107,    60,    -1,   122,    60,    -1,     3,
      60,    -1,   104,    60,    -1,   106,    60,    -1,    60,    -1,
       1,    60,    -1,    88,    89,    91,    92,    -1,     6,    -1,
      -1,    89,    90,    -1,     7,    -1,     8,    -1,    79,    -1,
      77,    -1,   133,     9,    80,    -1,    10,    77,    -1,   133,
      11,    80,    -1,    45,    77,    -1,    46,    77,    -1,   133,
      13,    80,    -1,    15,    -1,   133,    14,    80,    -1,    16,
      -1,    17,    79,    -1,    18,    79,    -1,    19,    79,    -1,
      20,    79,    -1,   134,   105,    82,    -1,    22,    -1,    23,
      -1,    24,    -1,    25,    -1,    26,    -1,   135,    21,    81,
      -1,    36,   108,    -1,    79,    68,   109,    -1,   110,    -1,
     109,    40,    59,    79,    79,    66,    79,    67,    -1,   109,
      41,    59,    79,    79,    66,    79,    67,    -1,   109,    42,
      59,    79,    66,    79,    67,    -1,   109,    43,    59,    79,
      -1,   109,    44,    59,    79,    -1,   109,    47,    59,    79,
      -1,   112,    -1,   115,    -1,   116,   110,    -1,   117,   110,
      -1,    69,   110,    -1,   118,   110,    -1,   119,    -1,   111,
      -1,    48,    66,   120,    67,    -1,    49,    66,   120,    61,
     120,    67,    -1,    50,    66,   120,    67,    -1,   114,    -1,
      66,   114,    61,   121,   132,    67,    -1,    77,    -1,    78,
      -1,   113,    -1,   113,    75,   113,    -1,    79,    -1,    37,
      73,    74,    39,    -1,    37,    73,    64,    74,    39,    -1,
      37,    73,    64,    59,   121,    74,    39,    -1,    37,    73,
     121,    74,    39,    -1,    38,    73,   121,    74,    39,    -1,
      51,    73,   121,    74,    -1,    51,    73,    64,    59,   121,
      74,    -1,    79,    -1,   120,    79,    -1,   121,    62,   121,
      -1,   121,    63,   121,    -1,   121,    64,   121,    -1,   121,
      65,   121,    -1,    77,    -1,    66,   121,    67,    -1,   123,
      -1,   124,    -1,     4,    79,   125,    -1,     5,    79,   125,
      -1,    66,    67,    -1,    66,   126,    67,    -1,   127,    -1,
     128,    -1,   127,    60,   126,    -1,   128,    60,   126,    -1,
     129,    79,   131,   132,    -1,   130,    79,   131,    -1,    -1,
      27,    -1,    28,    -1,    29,    -1,    32,    -1,    33,    -1,
      34,    -1,    35,    -1,    13,    -1,    14,    -1,     9,    -1,
      52,    -1,    54,    -1,    53,    -1,    55,    -1,    57,    -1,
      56,    -1,    58,    -1,    12,    -1,    31,    -1,    30,    -1,
      59,    79,    -1,    59,   108,    -1,    59,   111,    -1,    -1,
     132,    61,    83,    -1,   132,    61,    83,    73,    74,    -1,
      -1,    -1,    -1
};

/* YYRLINE[YYN] -- source line where rule number YYN was defined.  */
static const yytype_uint16 yyrline[] =
{
       0,   198,   198,   199,   202,   203,   204,   205,   206,   207,
     208,   209,   210,   211,   212,   213,   214,   215,   225,   227,
     228,   229,   230,   234,   246,   257,   258,   261,   271,   279,
     282,   285,   300,   307,   323,   326,   330,   336,   344,   350,
     358,   366,   374,   382,   390,   401,   402,   403,   404,   405,
     408,   418,   428,   432,   434,   451,   468,   481,   493,   501,
     513,   515,   517,   519,   521,   523,   525,   527,   531,   533,
     536,   540,   546,   553,   559,   563,   565,   587,   591,   593,
     595,   600,   604,   608,   610,   615,   617,   621,   623,   625,
     627,   629,   631,   636,   637,   640,   644,   648,   650,   655,
     657,   659,   664,   671,   691,   701,   702,   703,   704,   705,
     706,   707,   708,   709,   710,   711,   712,   713,   714,   715,
     716,   717,   718,   719,   724,   725,   729,   735,   737,   742,
     743,   750,   759,   763,   767
};
#endif

#if YYDEBUG || YYERROR_VERBOSE || YYTOKEN_TABLE
/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "$end", "error", "$undefined", "sySkip", "syRoutine", "sySimpleRoutine",
  "sySubsystem", "syKernelUser", "syKernelServer", "syMsgOption",
  "syUseSpecialReplyPort", "syConsumeOnSendError", "syMsgSeqno",
  "syWaitTime", "sySendTime", "syNoWaitTime", "syNoSendTime",
  "syErrorProc", "syServerPrefix", "syUserPrefix", "syServerDemux",
  "syRCSId", "syImport", "syUImport", "sySImport", "syIImport",
  "syDImport", "syIn", "syOut", "syInOut", "syUserImpl", "syServerImpl",
  "syRequestPort", "syReplyPort", "sySReplyPort", "syUReplyPort", "syType",
  "syArray", "syStruct", "syOf", "syInTran", "syOutTran", "syDestructor",
  "syCType", "syCUserType", "syUserTypeLimit", "syOnStackLimit",
  "syCServerType", "syPointerTo", "syPointerToIfNot", "syValueOf",
  "syCString", "sySecToken", "syUserSecToken", "syServerSecToken",
  "syAuditToken", "syUserAuditToken", "syServerAuditToken",
  "syServerContextToken", "syColon", "sySemi", "syComma", "syPlus",
  "syMinus", "syStar", "syDiv", "syLParen", "syRParen", "syEqual",
  "syCaret", "syTilde", "syLAngle", "syRAngle", "syLBrack", "syRBrack",
  "syBar", "syError", "syNumber", "sySymbolicType", "syIdentifier",
  "syString", "syQString", "syFileName", "syIPCFlag", "$accept",
  "Statements", "Statement", "Subsystem", "SubsystemStart",
  "SubsystemMods", "SubsystemMod", "SubsystemName", "SubsystemBase",
  "MsgOption", "UseSpecialReplyPort", "ConsumeOnSendError",
  "UserTypeLimit", "OnStackLimit", "WaitTime", "SendTime", "Error",
  "ServerPrefix", "UserPrefix", "ServerDemux", "Import", "ImportIndicant",
  "RCSDecl", "TypeDecl", "NamedTypeSpec", "TransTypeSpec", "TypeSpec",
  "NativeTypeSpec", "BasicTypeSpec", "PrimIPCType", "IPCType",
  "PrevTypeSpec", "VarArrayHead", "ArrayHead", "StructHead", "CStringSpec",
  "TypePhrase", "IntExp", "RoutineDecl", "Routine", "SimpleRoutine",
  "Arguments", "ArgumentList", "Argument", "Trailer", "Direction",
  "TrImplKeyword", "ArgumentType", "IPCFlags", "LookString",
  "LookFileName", "LookQString", 0
};
#endif

# ifdef YYPRINT
/* YYTOKNUM[YYLEX-NUM] -- Internal token number corresponding to
   token YYLEX-NUM.  */
static const yytype_uint16 yytoknum[] =
{
       0,   256,   257,   258,   259,   260,   261,   262,   263,   264,
     265,   266,   267,   268,   269,   270,   271,   272,   273,   274,
     275,   276,   277,   278,   279,   280,   281,   282,   283,   284,
     285,   286,   287,   288,   289,   290,   291,   292,   293,   294,
     295,   296,   297,   298,   299,   300,   301,   302,   303,   304,
     305,   306,   307,   308,   309,   310,   311,   312,   313,   314,
     315,   316,   317,   318,   319,   320,   321,   322,   323,   324,
     325,   326,   327,   328,   329,   330,   331,   332,   333,   334,
     335,   336,   337,   338
};
# endif

/* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const yytype_uint8 yyr1[] =
{
       0,    84,    85,    85,    86,    86,    86,    86,    86,    86,
      86,    86,    86,    86,    86,    86,    86,    86,    86,    86,
      86,    86,    86,    87,    88,    89,    89,    90,    90,    91,
      92,    93,    94,    95,    96,    97,    98,    98,    99,    99,
     100,   101,   102,   103,   104,   105,   105,   105,   105,   105,
     106,   107,   108,   109,   109,   109,   109,   109,   109,   109,
     110,   110,   110,   110,   110,   110,   110,   110,   111,   111,
     111,   112,   112,   113,   113,   114,   114,   115,   116,   116,
     116,   117,   118,   119,   119,   120,   120,   121,   121,   121,
     121,   121,   121,   122,   122,   123,   124,   125,   125,   126,
     126,   126,   126,   127,   128,   129,   129,   129,   129,   129,
     129,   129,   129,   129,   129,   129,   129,   129,   129,   129,
     129,   129,   129,   129,   130,   130,   131,   131,   131,   132,
     132,   132,   133,   134,   135
};

/* YYR2[YYN] -- Number of symbols composing right hand side of rule YYN.  */
static const yytype_uint8 yyr2[] =
{
       0,     2,     0,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     1,     2,     4,     1,     0,     2,     1,     1,     1,
       1,     3,     2,     3,     2,     2,     3,     1,     3,     1,
       2,     2,     2,     2,     3,     1,     1,     1,     1,     1,
       3,     2,     3,     1,     8,     8,     7,     4,     4,     4,
       1,     1,     2,     2,     2,     2,     1,     1,     4,     6,
       4,     1,     6,     1,     1,     1,     3,     1,     4,     5,
       7,     5,     5,     4,     6,     1,     2,     3,     3,     3,
       3,     1,     3,     1,     1,     3,     3,     2,     3,     1,
       1,     3,     3,     4,     3,     0,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     2,     2,     2,     0,
       3,     5,     0,     0,     0
};

/* YYDEFACT[STATE-NAME] -- Default rule to reduce with in state
   STATE-NUM when YYTABLE doesn't specify something else to do.  Zero
   means the default is an error.  */
static const yytype_uint8 yydefact[] =
{
       2,     0,     1,     0,     0,     0,     0,    24,     0,    37,
      39,     0,     0,     0,     0,     0,     0,     0,    21,     3,
       0,    25,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,    93,    94,     0,
       0,     0,    22,    18,     0,     0,    32,    40,    41,    42,
      43,     0,    51,    34,    35,     4,     0,     7,     8,     9,
      10,    11,     5,     6,    12,    13,    14,    15,    19,    20,
      16,    17,     0,     0,     0,     0,    45,    46,    47,    48,
      49,     0,     0,   105,    95,    96,     0,    27,    28,    29,
      26,     0,    31,    33,    36,    38,    44,    50,   115,   123,
     113,   114,   106,   107,   108,   125,   124,   109,   110,   111,
     112,   116,   118,   117,   119,   121,   120,   122,    97,     0,
      99,   100,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,    73,    74,    77,    52,    53,    67,    60,    75,
      71,    61,     0,     0,     0,    66,    30,    23,    98,   105,
     105,     0,     0,     0,     0,     0,     0,     0,     0,     0,
      64,     0,     0,     0,     0,     0,     0,     0,    62,    63,
      65,   101,   102,     0,   129,   104,     0,     0,     0,    91,
       0,     0,    85,     0,     0,     0,     0,     0,     0,     0,
       0,     0,     0,     0,     0,    76,   126,   127,   128,   103,
       0,     0,     0,    78,     0,     0,     0,     0,     0,     0,
      68,    86,     0,    70,     0,    83,   129,     0,     0,     0,
      57,    58,    59,     0,     0,    79,    92,    87,    88,    89,
      90,    81,    82,     0,     0,     0,     0,     0,     0,   130,
       0,    69,    84,    72,     0,     0,     0,     0,    80,     0,
       0,    56,   131,    54,    55
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int16 yydefgoto[] =
{
      -1,     1,    19,    20,    21,    56,    90,    91,   147,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    81,    34,    35,    52,   135,   136,   137,   138,   139,
     140,   141,   142,   143,   144,   145,   183,   180,    36,    37,
      38,    84,   119,   120,   121,   122,   123,   174,   199,    39,
      40,    41
};

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
#define YYPACT_NINF -148
static const yytype_int16 yypact[] =
{
    -148,     2,  -148,   -56,   -46,   -43,   -39,  -148,   -35,  -148,
    -148,   -34,   -15,    11,    36,    46,    29,    59,  -148,  -148,
      24,  -148,    80,    92,    97,    98,    99,   100,   117,   118,
     120,   121,   123,   137,   144,   146,   147,  -148,  -148,    74,
     177,   163,  -148,  -148,   142,   142,  -148,  -148,  -148,  -148,
    -148,   141,  -148,  -148,  -148,  -148,    -7,  -148,  -148,  -148,
    -148,  -148,  -148,  -148,  -148,  -148,  -148,  -148,  -148,  -148,
    -148,  -148,   130,   132,   133,   134,  -148,  -148,  -148,  -148,
    -148,   129,   135,    64,  -148,  -148,   113,  -148,  -148,  -148,
    -148,   138,  -148,  -148,  -148,  -148,  -148,  -148,  -148,  -148,
    -148,  -148,  -148,  -148,  -148,  -148,  -148,  -148,  -148,  -148,
    -148,  -148,  -148,  -148,  -148,  -148,  -148,  -148,  -148,   150,
     158,   159,   143,   145,   148,   152,   154,   157,   160,   155,
      27,   113,  -148,  -148,  -148,    67,  -148,  -148,  -148,   156,
    -148,  -148,   113,   113,   113,  -148,  -148,  -148,  -148,   114,
     114,   168,   168,   -23,    47,   151,   151,   151,   -27,   171,
    -148,   170,   174,   175,   176,   178,   179,    27,  -148,  -148,
    -148,  -148,  -148,   -18,  -148,  -148,   -25,    47,   197,  -148,
      38,    91,  -148,   -21,   -26,    -8,   180,   111,    47,   161,
     162,   164,   165,   166,   167,  -148,   141,  -148,  -148,   181,
      47,   208,    70,  -148,    47,    47,    47,    47,   209,   210,
    -148,  -148,   151,  -148,    47,  -148,     5,   172,   173,   184,
    -148,  -148,  -148,   182,   124,  -148,  -148,    65,    65,  -148,
    -148,  -148,  -148,     7,   131,    -1,   187,   188,   183,   185,
     216,  -148,  -148,  -148,   189,   190,   192,   186,  -148,   194,
     196,  -148,  -148,  -148,  -148
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] =
{
    -148,  -148,  -148,  -148,  -148,  -148,  -148,  -148,  -148,  -148,
    -148,  -148,  -148,  -148,  -148,  -148,  -148,  -148,  -148,  -148,
    -148,  -148,  -148,  -148,    83,  -148,   -87,    84,  -148,   103,
     136,  -148,  -148,  -148,  -148,  -148,  -147,  -125,  -148,  -148,
    -148,   219,   -11,  -148,  -148,  -148,  -148,   115,    55,  -148,
    -148,  -148
};

/* YYTABLE[YYPACT[STATE-NUM]].  What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule which
   number is the opposite.  If zero, do what YYDEFACT says.
   If YYTABLE_NINF, syntax error.  */
#define YYTABLE_NINF -135
static const yytype_int16 yytable[] =
{
      87,    88,     2,     3,    42,     4,     5,     6,     7,   184,
     185,  -132,     8,  -132,    43,  -132,  -132,     9,    10,    11,
      12,    13,    14,  -134,  -133,  -133,  -133,  -133,  -133,   181,
     126,   127,   128,   187,   200,   212,    44,   186,    15,   177,
      45,   176,    46,   177,   160,    47,   210,    16,    17,   201,
     179,   178,   202,   211,   179,   168,   169,   170,   211,   213,
     223,   196,    18,   216,    48,   233,   243,   204,   205,   206,
     207,   211,    89,    98,   241,   224,    99,   100,   101,   227,
     228,   229,   230,    72,    55,    73,   211,    74,    75,   234,
      49,   102,   103,   104,   105,   106,   107,   108,   109,   110,
     204,   205,   206,   207,   132,   133,    53,   161,   162,   163,
     164,   165,   208,   177,   166,    50,   111,   112,   113,   114,
     115,   116,   117,    98,   179,    51,    99,   100,   101,   206,
     207,   118,   204,   205,   206,   207,    54,   226,   171,   172,
      57,   102,   103,   104,   105,   106,   107,   108,   109,   110,
     124,   125,    58,   204,   205,   206,   207,    59,    60,    61,
      62,   126,   127,   128,   129,   209,   111,   112,   113,   114,
     115,   116,   117,   204,   205,   206,   207,    63,    64,   130,
      65,    66,   131,    67,    82,   215,   204,   205,   206,   207,
     132,   133,   134,   204,   205,   206,   207,    68,   240,    76,
      77,    78,    79,    80,    69,   242,    70,    71,    83,    86,
      92,    96,    93,    94,    95,   146,    97,   148,   149,   150,
     155,   153,   151,   156,   152,   154,   157,   173,   158,   189,
     182,   167,   188,   190,   191,   192,   203,   193,   194,   214,
     217,   218,   223,   219,   220,   221,   222,   225,   231,   232,
     238,   236,   237,   244,   245,   248,   197,   198,   247,   251,
     252,   253,   246,   254,    85,   239,   159,   175,   249,   250,
     195,   235
};

static const yytype_uint8 yycheck[] =
{
       7,     8,     0,     1,    60,     3,     4,     5,     6,   156,
     157,     9,    10,    11,    60,    13,    14,    15,    16,    17,
      18,    19,    20,    21,    22,    23,    24,    25,    26,   154,
      48,    49,    50,   158,    59,    61,    79,    64,    36,    66,
      79,    64,    77,    66,   131,    79,    67,    45,    46,    74,
      77,    74,   177,    79,    77,   142,   143,   144,    79,    67,
      61,    79,    60,   188,    79,   212,    67,    62,    63,    64,
      65,    79,    79,     9,    67,   200,    12,    13,    14,   204,
     205,   206,   207,     9,    60,    11,    79,    13,    14,   214,
      79,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      62,    63,    64,    65,    77,    78,    77,    40,    41,    42,
      43,    44,    74,    66,    47,    79,    52,    53,    54,    55,
      56,    57,    58,     9,    77,    79,    12,    13,    14,    64,
      65,    67,    62,    63,    64,    65,    77,    67,   149,   150,
      60,    27,    28,    29,    30,    31,    32,    33,    34,    35,
      37,    38,    60,    62,    63,    64,    65,    60,    60,    60,
      60,    48,    49,    50,    51,    74,    52,    53,    54,    55,
      56,    57,    58,    62,    63,    64,    65,    60,    60,    66,
      60,    60,    69,    60,    21,    74,    62,    63,    64,    65,
      77,    78,    79,    62,    63,    64,    65,    60,    74,    22,
      23,    24,    25,    26,    60,    74,    60,    60,    66,    68,
      80,    82,    80,    80,    80,    77,    81,    67,    60,    60,
      66,    73,    79,    66,    79,    73,    66,    59,    73,    59,
      79,    75,    61,    59,    59,    59,    39,    59,    59,    59,
      79,    79,    61,    79,    79,    79,    79,    39,    39,    39,
      66,    79,    79,    66,    66,    39,   173,   173,    73,    67,
      74,    67,    79,    67,    45,    83,   130,   152,    79,    79,
     167,   216
};

/* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
   symbol of state STATE-NUM.  */
static const yytype_uint8 yystos[] =
{
       0,    85,     0,     1,     3,     4,     5,     6,    10,    15,
      16,    17,    18,    19,    20,    36,    45,    46,    60,    86,
      87,    88,    93,    94,    95,    96,    97,    98,    99,   100,
     101,   102,   103,   104,   106,   107,   122,   123,   124,   133,
     134,   135,    60,    60,    79,    79,    77,    79,    79,    79,
      79,    79,   108,    77,    77,    60,    89,    60,    60,    60,
      60,    60,    60,    60,    60,    60,    60,    60,    60,    60,
      60,    60,     9,    11,    13,    14,    22,    23,    24,    25,
      26,   105,    21,    66,   125,   125,    68,     7,     8,    79,
      90,    91,    80,    80,    80,    80,    82,    81,     9,    12,
      13,    14,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    52,    53,    54,    55,    56,    57,    58,    67,   126,
     127,   128,   129,   130,    37,    38,    48,    49,    50,    51,
      66,    69,    77,    78,    79,   109,   110,   111,   112,   113,
     114,   115,   116,   117,   118,   119,    77,    92,    67,    60,
      60,    79,    79,    73,    73,    66,    66,    66,    73,   114,
     110,    40,    41,    42,    43,    44,    47,    75,   110,   110,
     110,   126,   126,    59,   131,   131,    64,    66,    74,    77,
     121,   121,    79,   120,   120,   120,    64,   121,    61,    59,
      59,    59,    59,    59,    59,   113,    79,   108,   111,   132,
      59,    74,   121,    39,    62,    63,    64,    65,    74,    74,
      67,    79,    61,    67,    59,    74,   121,    79,    79,    79,
      79,    79,    79,    61,   121,    39,    67,   121,   121,   121,
     121,    39,    39,   120,   121,   132,    79,    79,    66,    83,
      74,    67,    74,    67,    66,    66,    79,    73,    39,    79,
      79,    67,    74,    67,    67
};

#define yyerrok		(yyerrstatus = 0)
#define yyclearin	(yychar = YYEMPTY)
#define YYEMPTY		(-2)
#define YYEOF		0

#define YYACCEPT	goto yyacceptlab
#define YYABORT		goto yyabortlab
#define YYERROR		goto yyerrorlab


/* Like YYERROR except do call yyerror.  This remains here temporarily
   to ease the transition to the new meaning of YYERROR, for GCC.
   Once GCC version 2 has supplanted version 1, this can go.  */

#define YYFAIL		goto yyerrlab

#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)					\
do								\
  if (yychar == YYEMPTY && yylen == 1)				\
    {								\
      yychar = (Token);						\
      yylval = (Value);						\
      yytoken = YYTRANSLATE (yychar);				\
      YYPOPSTACK (1);						\
      goto yybackup;						\
    }								\
  else								\
    {								\
      yyerror (YY_("syntax error: cannot back up")); \
      YYERROR;							\
    }								\
while (YYID (0))


#define YYTERROR	1
#define YYERRCODE	256


/* YYLLOC_DEFAULT -- Set CURRENT to span from RHS[1] to RHS[N].
   If N is 0, then set CURRENT to the empty location which ends
   the previous symbol: RHS[0] (always defined).  */

#define YYRHSLOC(Rhs, K) ((Rhs)[K])
#ifndef YYLLOC_DEFAULT
# define YYLLOC_DEFAULT(Current, Rhs, N)				\
    do									\
      if (YYID (N))                                                    \
	{								\
	  (Current).first_line   = YYRHSLOC (Rhs, 1).first_line;	\
	  (Current).first_column = YYRHSLOC (Rhs, 1).first_column;	\
	  (Current).last_line    = YYRHSLOC (Rhs, N).last_line;		\
	  (Current).last_column  = YYRHSLOC (Rhs, N).last_column;	\
	}								\
      else								\
	{								\
	  (Current).first_line   = (Current).last_line   =		\
	    YYRHSLOC (Rhs, 0).last_line;				\
	  (Current).first_column = (Current).last_column =		\
	    YYRHSLOC (Rhs, 0).last_column;				\
	}								\
    while (YYID (0))
#endif


/* YY_LOCATION_PRINT -- Print the location on the stream.
   This macro was not mandated originally: define only if we know
   we won't break user code: when these are the locations we know.  */

#ifndef YY_LOCATION_PRINT
# if defined YYLTYPE_IS_TRIVIAL && YYLTYPE_IS_TRIVIAL
#  define YY_LOCATION_PRINT(File, Loc)			\
     fprintf (File, "%d.%d-%d.%d",			\
	      (Loc).first_line, (Loc).first_column,	\
	      (Loc).last_line,  (Loc).last_column)
# else
#  define YY_LOCATION_PRINT(File, Loc) ((void) 0)
# endif
#endif


/* YYLEX -- calling `yylex' with the right arguments.  */

#ifdef YYLEX_PARAM
# define YYLEX yylex (YYLEX_PARAM)
#else
# define YYLEX yylex ()
#endif

/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)			\
do {						\
  if (yydebug)					\
    YYFPRINTF Args;				\
} while (YYID (0))

# define YY_SYMBOL_PRINT(Title, Type, Value, Location)			  \
do {									  \
  if (yydebug)								  \
    {									  \
      YYFPRINTF (stderr, "%s ", Title);					  \
      yy_symbol_print (stderr,						  \
		  Type, Value); \
      YYFPRINTF (stderr, "\n");						  \
    }									  \
} while (YYID (0))


/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

/*ARGSUSED*/
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_symbol_value_print (FILE *yyoutput, int yytype, YYSTYPE const * const yyvaluep)
#else
static void
yy_symbol_value_print (yyoutput, yytype, yyvaluep)
    FILE *yyoutput;
    int yytype;
    YYSTYPE const * const yyvaluep;
#endif
{
  if (!yyvaluep)
    return;
# ifdef YYPRINT
  if (yytype < YYNTOKENS)
    YYPRINT (yyoutput, yytoknum[yytype], *yyvaluep);
# else
  YYUSE (yyoutput);
# endif
  switch (yytype)
    {
      default:
	break;
    }
}


/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_symbol_print (FILE *yyoutput, int yytype, YYSTYPE const * const yyvaluep)
#else
static void
yy_symbol_print (yyoutput, yytype, yyvaluep)
    FILE *yyoutput;
    int yytype;
    YYSTYPE const * const yyvaluep;
#endif
{
  if (yytype < YYNTOKENS)
    YYFPRINTF (yyoutput, "token %s (", yytname[yytype]);
  else
    YYFPRINTF (yyoutput, "nterm %s (", yytname[yytype]);

  yy_symbol_value_print (yyoutput, yytype, yyvaluep);
  YYFPRINTF (yyoutput, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_stack_print (yytype_int16 *bottom, yytype_int16 *top)
#else
static void
yy_stack_print (bottom, top)
    yytype_int16 *bottom;
    yytype_int16 *top;
#endif
{
  YYFPRINTF (stderr, "Stack now");
  for (; bottom <= top; ++bottom)
    YYFPRINTF (stderr, " %d", *bottom);
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)				\
do {								\
  if (yydebug)							\
    yy_stack_print ((Bottom), (Top));				\
} while (YYID (0))


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yy_reduce_print (YYSTYPE *yyvsp, int yyrule)
#else
static void
yy_reduce_print (yyvsp, yyrule)
    YYSTYPE *yyvsp;
    int yyrule;
#endif
{
  int yynrhs = yyr2[yyrule];
  int yyi;
  unsigned long int yylno = yyrline[yyrule];
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %lu):\n",
	     yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      fprintf (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr, yyrhs[yyprhs[yyrule] + yyi],
		       &(yyvsp[(yyi + 1) - (yynrhs)])
		       		       );
      fprintf (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)		\
do {					\
  if (yydebug)				\
    yy_reduce_print (yyvsp, Rule); \
} while (YYID (0))

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args)
# define YY_SYMBOL_PRINT(Title, Type, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !YYDEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef	YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif



#if YYERROR_VERBOSE

# ifndef yystrlen
#  if defined __GLIBC__ && defined _STRING_H
#   define yystrlen strlen
#  else
/* Return the length of YYSTR.  */
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static YYSIZE_T
yystrlen (const char *yystr)
#else
static YYSIZE_T
yystrlen (yystr)
    const char *yystr;
#endif
{
  YYSIZE_T yylen;
  for (yylen = 0; yystr[yylen]; yylen++)
    continue;
  return yylen;
}
#  endif
# endif

# ifndef yystpcpy
#  if defined __GLIBC__ && defined _STRING_H && defined _GNU_SOURCE
#   define yystpcpy stpcpy
#  else
/* Copy YYSRC to YYDEST, returning the address of the terminating '\0' in
   YYDEST.  */
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static char *
yystpcpy (char *yydest, const char *yysrc)
#else
static char *
yystpcpy (yydest, yysrc)
    char *yydest;
    const char *yysrc;
#endif
{
  char *yyd = yydest;
  const char *yys = yysrc;

  while ((*yyd++ = *yys++) != '\0')
    continue;

  return yyd - 1;
}
#  endif
# endif

# ifndef yytnamerr
/* Copy to YYRES the contents of YYSTR after stripping away unnecessary
   quotes and backslashes, so that it's suitable for yyerror.  The
   heuristic is that double-quoting is unnecessary unless the string
   contains an apostrophe, a comma, or backslash (other than
   backslash-backslash).  YYSTR is taken from yytname.  If YYRES is
   null, do not copy; instead, return the length of what the result
   would have been.  */
static YYSIZE_T
yytnamerr (char *yyres, const char *yystr)
{
  if (*yystr == '"')
    {
      YYSIZE_T yyn = 0;
      char const *yyp = yystr;

      for (;;)
	switch (*++yyp)
	  {
	  case '\'':
	  case ',':
	    goto do_not_strip_quotes;

	  case '\\':
	    if (*++yyp != '\\')
	      goto do_not_strip_quotes;
	    /* Fall through.  */
	  default:
	    if (yyres)
	      yyres[yyn] = *yyp;
	    yyn++;
	    break;

	  case '"':
	    if (yyres)
	      yyres[yyn] = '\0';
	    return yyn;
	  }
    do_not_strip_quotes: ;
    }

  if (! yyres)
    return yystrlen (yystr);

  return yystpcpy (yyres, yystr) - yyres;
}
# endif

/* Copy into YYRESULT an error message about the unexpected token
   YYCHAR while in state YYSTATE.  Return the number of bytes copied,
   including the terminating null byte.  If YYRESULT is null, do not
   copy anything; just return the number of bytes that would be
   copied.  As a special case, return 0 if an ordinary "syntax error"
   message will do.  Return YYSIZE_MAXIMUM if overflow occurs during
   size calculation.  */
static YYSIZE_T
yysyntax_error (char *yyresult, int yystate, int yychar)
{
  int yyn = yypact[yystate];

  if (! (YYPACT_NINF < yyn && yyn <= YYLAST))
    return 0;
  else
    {
      int yytype = YYTRANSLATE (yychar);
      YYSIZE_T yysize0 = yytnamerr (0, yytname[yytype]);
      YYSIZE_T yysize = yysize0;
      YYSIZE_T yysize1;
      int yysize_overflow = 0;
      enum { YYERROR_VERBOSE_ARGS_MAXIMUM = 5 };
      char const *yyarg[YYERROR_VERBOSE_ARGS_MAXIMUM];
      int yyx;

# if 0
      /* This is so xgettext sees the translatable formats that are
	 constructed on the fly.  */
      YY_("syntax error, unexpected %s");
      YY_("syntax error, unexpected %s, expecting %s");
      YY_("syntax error, unexpected %s, expecting %s or %s");
      YY_("syntax error, unexpected %s, expecting %s or %s or %s");
      YY_("syntax error, unexpected %s, expecting %s or %s or %s or %s");
# endif
      char *yyfmt;
      char const *yyf;
      static char const yyunexpected[] = "syntax error, unexpected %s";
      static char const yyexpecting[] = ", expecting %s";
      static char const yyor[] = " or %s";
      char yyformat[sizeof yyunexpected
		    + sizeof yyexpecting - 1
		    + ((YYERROR_VERBOSE_ARGS_MAXIMUM - 2)
		       * (sizeof yyor - 1))];
      char const *yyprefix = yyexpecting;

      /* Start YYX at -YYN if negative to avoid negative indexes in
	 YYCHECK.  */
      int yyxbegin = yyn < 0 ? -yyn : 0;

      /* Stay within bounds of both yycheck and yytname.  */
      int yychecklim = YYLAST - yyn + 1;
      int yyxend = yychecklim < YYNTOKENS ? yychecklim : YYNTOKENS;
      int yycount = 1;

      yyarg[0] = yytname[yytype];
      yyfmt = yystpcpy (yyformat, yyunexpected);

      for (yyx = yyxbegin; yyx < yyxend; ++yyx)
	if (yycheck[yyx + yyn] == yyx && yyx != YYTERROR)
	  {
	    if (yycount == YYERROR_VERBOSE_ARGS_MAXIMUM)
	      {
		yycount = 1;
		yysize = yysize0;
		yyformat[sizeof yyunexpected - 1] = '\0';
		break;
	      }
	    yyarg[yycount++] = yytname[yyx];
	    yysize1 = yysize + yytnamerr (0, yytname[yyx]);
	    yysize_overflow |= (yysize1 < yysize);
	    yysize = yysize1;
	    yyfmt = yystpcpy (yyfmt, yyprefix);
	    yyprefix = yyor;
	  }

      yyf = YY_(yyformat);
      yysize1 = yysize + yystrlen (yyf);
      yysize_overflow |= (yysize1 < yysize);
      yysize = yysize1;

      if (yysize_overflow)
	return YYSIZE_MAXIMUM;

      if (yyresult)
	{
	  /* Avoid sprintf, as that infringes on the user's name space.
	     Don't have undefined behavior even if the translation
	     produced a string with the wrong number of "%s"s.  */
	  char *yyp = yyresult;
	  int yyi = 0;
	  while ((*yyp = *yyf) != '\0')
	    {
	      if (*yyp == '%' && yyf[1] == 's' && yyi < yycount)
		{
		  yyp += yytnamerr (yyp, yyarg[yyi++]);
		  yyf += 2;
		}
	      else
		{
		  yyp++;
		  yyf++;
		}
	    }
	}
      return yysize;
    }
}
#endif /* YYERROR_VERBOSE */


/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

/*ARGSUSED*/
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
static void
yydestruct (const char *yymsg, int yytype, YYSTYPE *yyvaluep)
#else
static void
yydestruct (yymsg, yytype, yyvaluep)
    const char *yymsg;
    int yytype;
    YYSTYPE *yyvaluep;
#endif
{
  YYUSE (yyvaluep);

  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yytype, yyvaluep, yylocationp);

  switch (yytype)
    {

      default:
	break;
    }
}


/* Prevent warnings from -Wmissing-prototypes.  */

#ifdef YYPARSE_PARAM
#if defined __STDC__ || defined __cplusplus
int yyparse (void *YYPARSE_PARAM);
#else
int yyparse ();
#endif
#else /* ! YYPARSE_PARAM */
#if defined __STDC__ || defined __cplusplus
int yyparse (void);
#else
int yyparse ();
#endif
#endif /* ! YYPARSE_PARAM */



/* The look-ahead symbol.  */
int yychar;

/* The semantic value of the look-ahead symbol.  */
YYSTYPE yylval;

/* Number of syntax errors so far.  */
int yynerrs;



/*----------.
| yyparse.  |
`----------*/

#ifdef YYPARSE_PARAM
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
int
yyparse (void *YYPARSE_PARAM)
#else
int
yyparse (YYPARSE_PARAM)
    void *YYPARSE_PARAM;
#endif
#else /* ! YYPARSE_PARAM */
#if (defined __STDC__ || defined __C99__FUNC__ \
     || defined __cplusplus || defined _MSC_VER)
int
yyparse (void)
#else
int
yyparse ()

#endif
#endif
{
  
  int yystate;
  int yyn;
  int yyresult;
  /* Number of tokens to shift before error messages enabled.  */
  int yyerrstatus;
  /* Look-ahead token as an internal (translated) token number.  */
  int yytoken = 0;
#if YYERROR_VERBOSE
  /* Buffer for error messages, and its allocated size.  */
  char yymsgbuf[128];
  char *yymsg = yymsgbuf;
  YYSIZE_T yymsg_alloc = sizeof yymsgbuf;
#endif

  /* Three stacks and their tools:
     `yyss': related to states,
     `yyvs': related to semantic values,
     `yyls': related to locations.

     Refer to the stacks thru separate pointers, to allow yyoverflow
     to reallocate them elsewhere.  */

  /* The state stack.  */
  yytype_int16 yyssa[YYINITDEPTH];
  yytype_int16 *yyss = yyssa;
  yytype_int16 *yyssp;

  /* The semantic value stack.  */
  YYSTYPE yyvsa[YYINITDEPTH];
  YYSTYPE *yyvs = yyvsa;
  YYSTYPE *yyvsp;



#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N))

  YYSIZE_T yystacksize = YYINITDEPTH;

  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;


  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yystate = 0;
  yyerrstatus = 0;
  yynerrs = 0;
  yychar = YYEMPTY;		/* Cause a token to be read.  */

  /* Initialize stack pointers.
     Waste one element of value and location stack
     so that they stay on the same level as the state stack.
     The wasted elements are never initialized.  */

  yyssp = yyss;
  yyvsp = yyvs;

  goto yysetstate;

/*------------------------------------------------------------.
| yynewstate -- Push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
 yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;

 yysetstate:
  *yyssp = yystate;

  if (yyss + yystacksize - 1 <= yyssp)
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYSIZE_T yysize = yyssp - yyss + 1;

#ifdef yyoverflow
      {
	/* Give user a chance to reallocate the stack.  Use copies of
	   these so that the &'s don't force the real ones into
	   memory.  */
	YYSTYPE *yyvs1 = yyvs;
	yytype_int16 *yyss1 = yyss;


	/* Each stack pointer address is followed by the size of the
	   data in use in that stack, in bytes.  This used to be a
	   conditional around just the two extra args, but that might
	   be undefined if yyoverflow is a macro.  */
	yyoverflow (YY_("memory exhausted"),
		    &yyss1, yysize * sizeof (*yyssp),
		    &yyvs1, yysize * sizeof (*yyvsp),

		    &yystacksize);

	yyss = yyss1;
	yyvs = yyvs1;
      }
#else /* no yyoverflow */
# ifndef YYSTACK_RELOCATE
      goto yyexhaustedlab;
# else
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
	goto yyexhaustedlab;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
	yystacksize = YYMAXDEPTH;

      {
	yytype_int16 *yyss1 = yyss;
	union yyalloc *yyptr =
	  (union yyalloc *) YYSTACK_ALLOC (YYSTACK_BYTES (yystacksize));
	if (! yyptr)
	  goto yyexhaustedlab;
	YYSTACK_RELOCATE (yyss);
	YYSTACK_RELOCATE (yyvs);

#  undef YYSTACK_RELOCATE
	if (yyss1 != yyssa)
	  YYSTACK_FREE (yyss1);
      }
# endif
#endif /* no yyoverflow */

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;


      YYDPRINTF ((stderr, "Stack size increased to %lu\n",
		  (unsigned long int) yystacksize));

      if (yyss + yystacksize - 1 <= yyssp)
	YYABORT;
    }

  YYDPRINTF ((stderr, "Entering state %d\n", yystate));

  goto yybackup;

/*-----------.
| yybackup.  |
`-----------*/
yybackup:

  /* Do appropriate processing given the current state.  Read a
     look-ahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to look-ahead token.  */
  yyn = yypact[yystate];
  if (yyn == YYPACT_NINF)
    goto yydefault;

  /* Not known => get a look-ahead token if don't already have one.  */

  /* YYCHAR is either YYEMPTY or YYEOF or a valid look-ahead symbol.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token: "));
      yychar = YYLEX;
    }

  if (yychar <= YYEOF)
    {
      yychar = yytoken = YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yyn == 0 || yyn == YYTABLE_NINF)
	goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  if (yyn == YYFINAL)
    YYACCEPT;

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the look-ahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);

  /* Discard the shifted token unless it is eof.  */
  if (yychar != YYEOF)
    yychar = YYEMPTY;

  yystate = yyn;
  *++yyvsp = yylval;

  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- Do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     `$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];


  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
        case 17:
#line 216 "parser.y"
    {
    statement_t *st = stAlloc();

    st->stKind = skRoutine;
    st->stRoutine = (yyvsp[(1) - (2)].routine);
    rtCheckRoutine((yyvsp[(1) - (2)].routine));
    if (BeVerbose)
      rtPrintRoutine((yyvsp[(1) - (2)].routine));
;}
    break;

  case 18:
#line 226 "parser.y"
    { rtSkip(); ;}
    break;

  case 22:
#line 231 "parser.y"
    { yyerrok; ;}
    break;

  case 23:
#line 236 "parser.y"
    {
  if (BeVerbose) {
    printf("Subsystem %s: base = %u%s%s\n\n",
    SubsystemName, SubsystemBase,
    IsKernelUser ? ", KernelUser" : "",
    IsKernelServer ? ", KernelServer" : "");
  }
;}
    break;

  case 24:
#line 247 "parser.y"
    {
    if (SubsystemName != strNULL) {
      warn("previous Subsystem decl (of %s) will be ignored", SubsystemName);
      IsKernelUser = FALSE;
      IsKernelServer = FALSE;
      strfree(SubsystemName);
    }
;}
    break;

  case 27:
#line 262 "parser.y"
    {
    if (IsKernelUser)
      warn("duplicate KernelUser keyword");
    if (!UseMsgRPC) {
      warn("with KernelUser the -R option is meaningless");
      UseMsgRPC = TRUE;
    }
    IsKernelUser = TRUE;
;}
    break;

  case 28:
#line 272 "parser.y"
    {
    if (IsKernelServer)
      warn("duplicate KernelServer keyword");
    IsKernelServer = TRUE;
;}
    break;

  case 29:
#line 279 "parser.y"
    { SubsystemName = (yyvsp[(1) - (1)].identifier); ;}
    break;

  case 30:
#line 282 "parser.y"
    { SubsystemBase = (yyvsp[(1) - (1)].number); ;}
    break;

  case 31:
#line 286 "parser.y"
    {
    if (streql((yyvsp[(3) - (3)].string), "MACH_MSG_OPTION_NONE")) {
      MsgOption = strNULL;
      if (BeVerbose)
          printf("MsgOption: canceled\n\n");
    }
    else {
      MsgOption = (yyvsp[(3) - (3)].string);
      if (BeVerbose)
          printf("MsgOption %s\n\n",(yyvsp[(3) - (3)].string));
    }
;}
    break;

  case 32:
#line 301 "parser.y"
    {
    UseSpecialReplyPort = ((yyvsp[(2) - (2)].number) != 0);
    HasUseSpecialReplyPort |= UseSpecialReplyPort;
;}
    break;

  case 33:
#line 308 "parser.y"
    {
    if (strcasecmp((yyvsp[(3) - (3)].string), "None") == 0) {
        ConsumeOnSendError = ConsumeOnSendErrorNone;
    } else if (strcasecmp((yyvsp[(3) - (3)].string), "Timeout") == 0) {
        ConsumeOnSendError = ConsumeOnSendErrorTimeout;
        HasConsumeOnSendError = TRUE;
    } else if (strcasecmp((yyvsp[(3) - (3)].string), "Any") == 0) {
        ConsumeOnSendError = ConsumeOnSendErrorAny;
        HasConsumeOnSendError = TRUE;
    } else {
        error("syntax error");
    }
;}
    break;

  case 34:
#line 324 "parser.y"
    {UserTypeLimit = (yyvsp[(2) - (2)].number); ;}
    break;

  case 35:
#line 327 "parser.y"
    {MaxMessSizeOnStack = (yyvsp[(2) - (2)].number); ;}
    break;

  case 36:
#line 331 "parser.y"
    {
    WaitTime = (yyvsp[(3) - (3)].string);
    if (BeVerbose)
      printf("WaitTime %s\n\n", WaitTime);
;}
    break;

  case 37:
#line 337 "parser.y"
    {
    WaitTime = strNULL;
    if (BeVerbose)
      printf("NoWaitTime\n\n");
;}
    break;

  case 38:
#line 345 "parser.y"
    {
    SendTime = (yyvsp[(3) - (3)].string);
    if (BeVerbose)
      printf("SendTime %s\n\n", SendTime);
;}
    break;

  case 39:
#line 351 "parser.y"
    {
    SendTime = strNULL;
    if (BeVerbose)
      printf("NoSendTime\n\n");
;}
    break;

  case 40:
#line 359 "parser.y"
    {
    ErrorProc = (yyvsp[(2) - (2)].identifier);
    if (BeVerbose)
      printf("ErrorProc %s\n\n", ErrorProc);
;}
    break;

  case 41:
#line 367 "parser.y"
    {
    ServerPrefix = (yyvsp[(2) - (2)].identifier);
    if (BeVerbose)
      printf("ServerPrefix %s\n\n", ServerPrefix);
;}
    break;

  case 42:
#line 375 "parser.y"
    {
    UserPrefix = (yyvsp[(2) - (2)].identifier);
    if (BeVerbose)
      printf("UserPrefix %s\n\n", UserPrefix);
;}
    break;

  case 43:
#line 383 "parser.y"
    {
    ServerDemux = (yyvsp[(2) - (2)].identifier);
    if (BeVerbose)
      printf("ServerDemux %s\n\n", ServerDemux);
;}
    break;

  case 44:
#line 391 "parser.y"
    {
    statement_t *st = stAlloc();
    st->stKind = (yyvsp[(2) - (3)].statement_kind);
    st->stFileName = (yyvsp[(3) - (3)].string);

    if (BeVerbose)
      printf("%s %s\n\n", import_name((yyvsp[(2) - (3)].statement_kind)), (yyvsp[(3) - (3)].string));
;}
    break;

  case 45:
#line 401 "parser.y"
    { (yyval.statement_kind) = skImport; ;}
    break;

  case 46:
#line 402 "parser.y"
    { (yyval.statement_kind) = skUImport; ;}
    break;

  case 47:
#line 403 "parser.y"
    { (yyval.statement_kind) = skSImport; ;}
    break;

  case 48:
#line 404 "parser.y"
    { (yyval.statement_kind) = skIImport; ;}
    break;

  case 49:
#line 405 "parser.y"
    { (yyval.statement_kind) = skDImport; ;}
    break;

  case 50:
#line 409 "parser.y"
    {
    if (RCSId != strNULL)
      warn("previous RCS decl will be ignored");
    if (BeVerbose)
      printf("RCSId %s\n\n", (yyvsp[(3) - (3)].string));
    RCSId = (yyvsp[(3) - (3)].string);
;}
    break;

  case 51:
#line 419 "parser.y"
    {
    identifier_t name = (yyvsp[(2) - (2)].type)->itName;

    if (itLookUp(name) != itNULL)
      warn("overriding previous definition of %s", name);
    itInsert(name, (yyvsp[(2) - (2)].type));
;}
    break;

  case 52:
#line 429 "parser.y"
    { itTypeDecl((yyvsp[(1) - (3)].identifier), (yyval.type) = (yyvsp[(3) - (3)].type)); ;}
    break;

  case 53:
#line 433 "parser.y"
    { (yyval.type) = itResetType((yyvsp[(1) - (1)].type)); ;}
    break;

  case 54:
#line 436 "parser.y"
    {
    (yyval.type) = (yyvsp[(1) - (8)].type);

    if (((yyval.type)->itTransType != strNULL) && !streql((yyval.type)->itTransType, (yyvsp[(4) - (8)].identifier)))
      warn("conflicting translation types (%s, %s)", (yyval.type)->itTransType, (yyvsp[(4) - (8)].identifier));
    (yyval.type)->itTransType = (yyvsp[(4) - (8)].identifier);

    if (((yyval.type)->itInTrans != strNULL) && !streql((yyval.type)->itInTrans, (yyvsp[(5) - (8)].identifier)))
      warn("conflicting in-translation functions (%s, %s)", (yyval.type)->itInTrans, (yyvsp[(5) - (8)].identifier));
    (yyval.type)->itInTrans = (yyvsp[(5) - (8)].identifier);

    if (((yyval.type)->itServerType != strNULL) && !streql((yyval.type)->itServerType, (yyvsp[(7) - (8)].identifier)))
      warn("conflicting server types (%s, %s)", (yyval.type)->itServerType, (yyvsp[(7) - (8)].identifier));
    (yyval.type)->itServerType = (yyvsp[(7) - (8)].identifier);
;}
    break;

  case 55:
#line 453 "parser.y"
    {
    (yyval.type) = (yyvsp[(1) - (8)].type);

    if (((yyval.type)->itServerType != strNULL) && !streql((yyval.type)->itServerType, (yyvsp[(4) - (8)].identifier)))
      warn("conflicting server types (%s, %s)", (yyval.type)->itServerType, (yyvsp[(4) - (8)].identifier));
    (yyval.type)->itServerType = (yyvsp[(4) - (8)].identifier);

    if (((yyval.type)->itOutTrans != strNULL) && !streql((yyval.type)->itOutTrans, (yyvsp[(5) - (8)].identifier)))
      warn("conflicting out-translation functions (%s, %s)", (yyval.type)->itOutTrans, (yyvsp[(5) - (8)].identifier));
    (yyval.type)->itOutTrans = (yyvsp[(5) - (8)].identifier);

    if (((yyval.type)->itTransType != strNULL) && !streql((yyval.type)->itTransType, (yyvsp[(7) - (8)].identifier)))
      warn("conflicting translation types (%s, %s)", (yyval.type)->itTransType, (yyvsp[(7) - (8)].identifier));
    (yyval.type)->itTransType = (yyvsp[(7) - (8)].identifier);
;}
    break;

  case 56:
#line 470 "parser.y"
    {
    (yyval.type) = (yyvsp[(1) - (7)].type);

    if (((yyval.type)->itDestructor != strNULL) && !streql((yyval.type)->itDestructor, (yyvsp[(4) - (7)].identifier)))
      warn("conflicting destructor functions (%s, %s)", (yyval.type)->itDestructor, (yyvsp[(4) - (7)].identifier));
    (yyval.type)->itDestructor = (yyvsp[(4) - (7)].identifier);

    if (((yyval.type)->itTransType != strNULL) && !streql((yyval.type)->itTransType, (yyvsp[(6) - (7)].identifier)))
      warn("conflicting translation types (%s, %s)", (yyval.type)->itTransType, (yyvsp[(6) - (7)].identifier));
    (yyval.type)->itTransType = (yyvsp[(6) - (7)].identifier);
;}
    break;

  case 57:
#line 482 "parser.y"
    {
    (yyval.type) = (yyvsp[(1) - (4)].type);

    if (((yyval.type)->itUserType != strNULL) && !streql((yyval.type)->itUserType, (yyvsp[(4) - (4)].identifier)))
      warn("conflicting user types (%s, %s)", (yyval.type)->itUserType, (yyvsp[(4) - (4)].identifier));
    (yyval.type)->itUserType = (yyvsp[(4) - (4)].identifier);

    if (((yyval.type)->itServerType != strNULL) && !streql((yyval.type)->itServerType, (yyvsp[(4) - (4)].identifier)))
      warn("conflicting server types (%s, %s)", (yyval.type)->itServerType, (yyvsp[(4) - (4)].identifier));
    (yyval.type)->itServerType = (yyvsp[(4) - (4)].identifier);
;}
    break;

  case 58:
#line 494 "parser.y"
    {
    (yyval.type) = (yyvsp[(1) - (4)].type);

    if (((yyval.type)->itUserType != strNULL) && !streql((yyval.type)->itUserType, (yyvsp[(4) - (4)].identifier)))
      warn("conflicting user types (%s, %s)", (yyval.type)->itUserType, (yyvsp[(4) - (4)].identifier));
    (yyval.type)->itUserType = (yyvsp[(4) - (4)].identifier);
;}
    break;

  case 59:
#line 503 "parser.y"
    {
    (yyval.type) = (yyvsp[(1) - (4)].type);

    if (((yyval.type)->itServerType != strNULL) && !streql((yyval.type)->itServerType, (yyvsp[(4) - (4)].identifier)))
	warn("conflicting server types (%s, %s)",
	     (yyval.type)->itServerType, (yyvsp[(4) - (4)].identifier));
    (yyval.type)->itServerType = (yyvsp[(4) - (4)].identifier);
;}
    break;

  case 60:
#line 514 "parser.y"
    { (yyval.type) = (yyvsp[(1) - (1)].type); ;}
    break;

  case 61:
#line 516 "parser.y"
    { (yyval.type) = (yyvsp[(1) - (1)].type); ;}
    break;

  case 62:
#line 518 "parser.y"
    { (yyval.type) = itVarArrayDecl((yyvsp[(1) - (2)].number), (yyvsp[(2) - (2)].type)); ;}
    break;

  case 63:
#line 520 "parser.y"
    { (yyval.type) = itArrayDecl((yyvsp[(1) - (2)].number), (yyvsp[(2) - (2)].type)); ;}
    break;

  case 64:
#line 522 "parser.y"
    { (yyval.type) = itPtrDecl((yyvsp[(2) - (2)].type)); ;}
    break;

  case 65:
#line 524 "parser.y"
    { (yyval.type) = itStructDecl((yyvsp[(1) - (2)].number), (yyvsp[(2) - (2)].type)); ;}
    break;

  case 66:
#line 526 "parser.y"
    { (yyval.type) = (yyvsp[(1) - (1)].type); ;}
    break;

  case 67:
#line 528 "parser.y"
    { (yyval.type) = (yyvsp[(1) - (1)].type); ;}
    break;

  case 68:
#line 532 "parser.y"
    { (yyval.type) = itNativeType((yyvsp[(3) - (4)].identifier), TRUE, 0); ;}
    break;

  case 69:
#line 535 "parser.y"
    { (yyval.type) = itNativeType((yyvsp[(3) - (6)].identifier), TRUE, (yyvsp[(5) - (6)].identifier)); ;}
    break;

  case 70:
#line 537 "parser.y"
    { (yyval.type) = itNativeType((yyvsp[(3) - (4)].identifier), FALSE, 0); ;}
    break;

  case 71:
#line 541 "parser.y"
    {
    (yyval.type) = itShortDecl((yyvsp[(1) - (1)].symtype).innumber, (yyvsp[(1) - (1)].symtype).instr,
		     (yyvsp[(1) - (1)].symtype).outnumber, (yyvsp[(1) - (1)].symtype).outstr,
		     (yyvsp[(1) - (1)].symtype).size);
;}
    break;

  case 72:
#line 548 "parser.y"
    {
    error("Long form type declarations aren't allowed any longer\n");
;}
    break;

  case 73:
#line 554 "parser.y"
    {
    (yyval.symtype).innumber = (yyval.symtype).outnumber = (yyvsp[(1) - (1)].number);
    (yyval.symtype).instr = (yyval.symtype).outstr = strNULL;
    (yyval.symtype).size = 0;
;}
    break;

  case 74:
#line 560 "parser.y"
    { (yyval.symtype) = (yyvsp[(1) - (1)].symtype); ;}
    break;

  case 75:
#line 564 "parser.y"
    { (yyval.symtype) = (yyvsp[(1) - (1)].symtype); ;}
    break;

  case 76:
#line 566 "parser.y"
    {
  if ((yyvsp[(1) - (3)].symtype).size != (yyvsp[(3) - (3)].symtype).size) {
    if ((yyvsp[(1) - (3)].symtype).size == 0)
      (yyval.symtype).size = (yyvsp[(3) - (3)].symtype).size;
    else if ((yyvsp[(3) - (3)].symtype).size == 0)
      (yyval.symtype).size = (yyvsp[(1) - (3)].symtype).size;
    else {
      error("sizes in IPCTypes (%d, %d) aren't equal",
      (yyvsp[(1) - (3)].symtype).size, (yyvsp[(3) - (3)].symtype).size);
      (yyval.symtype).size = 0;
    }
  }
  else
    (yyval.symtype).size = (yyvsp[(1) - (3)].symtype).size;
  (yyval.symtype).innumber = (yyvsp[(1) - (3)].symtype).innumber;
  (yyval.symtype).instr = (yyvsp[(1) - (3)].symtype).instr;
  (yyval.symtype).outnumber = (yyvsp[(3) - (3)].symtype).outnumber;
  (yyval.symtype).outstr = (yyvsp[(3) - (3)].symtype).outstr;
;}
    break;

  case 77:
#line 588 "parser.y"
    { (yyval.type) = itPrevDecl((yyvsp[(1) - (1)].identifier)); ;}
    break;

  case 78:
#line 592 "parser.y"
    { (yyval.number) = 0; ;}
    break;

  case 79:
#line 594 "parser.y"
    { (yyval.number) = 0; ;}
    break;

  case 80:
#line 597 "parser.y"
    { (yyval.number) = (yyvsp[(5) - (7)].number); ;}
    break;

  case 81:
#line 601 "parser.y"
    { (yyval.number) = (yyvsp[(3) - (5)].number); ;}
    break;

  case 82:
#line 605 "parser.y"
    { (yyval.number) = (yyvsp[(3) - (5)].number); ;}
    break;

  case 83:
#line 609 "parser.y"
    { (yyval.type) = itCStringDecl((yyvsp[(3) - (4)].number), FALSE); ;}
    break;

  case 84:
#line 612 "parser.y"
    { (yyval.type) = itCStringDecl((yyvsp[(5) - (6)].number), TRUE); ;}
    break;

  case 85:
#line 616 "parser.y"
    { (yyval.identifier) = (yyvsp[(1) - (1)].identifier); ;}
    break;

  case 86:
#line 618 "parser.y"
    { (yyval.identifier) = strphrase((yyvsp[(1) - (2)].identifier), (yyvsp[(2) - (2)].identifier)); strfree((yyvsp[(2) - (2)].identifier)); ;}
    break;

  case 87:
#line 622 "parser.y"
    { (yyval.number) = (yyvsp[(1) - (3)].number) + (yyvsp[(3) - (3)].number);	;}
    break;

  case 88:
#line 624 "parser.y"
    { (yyval.number) = (yyvsp[(1) - (3)].number) - (yyvsp[(3) - (3)].number);	;}
    break;

  case 89:
#line 626 "parser.y"
    { (yyval.number) = (yyvsp[(1) - (3)].number) * (yyvsp[(3) - (3)].number);	;}
    break;

  case 90:
#line 628 "parser.y"
    { (yyval.number) = (yyvsp[(1) - (3)].number) / (yyvsp[(3) - (3)].number);	;}
    break;

  case 91:
#line 630 "parser.y"
    { (yyval.number) = (yyvsp[(1) - (1)].number);	;}
    break;

  case 92:
#line 632 "parser.y"
    { (yyval.number) = (yyvsp[(2) - (3)].number);	;}
    break;

  case 93:
#line 636 "parser.y"
    { (yyval.routine) = (yyvsp[(1) - (1)].routine); ;}
    break;

  case 94:
#line 637 "parser.y"
    { (yyval.routine) = (yyvsp[(1) - (1)].routine); ;}
    break;

  case 95:
#line 641 "parser.y"
    { (yyval.routine) = rtMakeRoutine((yyvsp[(2) - (3)].identifier), (yyvsp[(3) - (3)].argument)); ;}
    break;

  case 96:
#line 645 "parser.y"
    { (yyval.routine) = rtMakeSimpleRoutine((yyvsp[(2) - (3)].identifier), (yyvsp[(3) - (3)].argument)); ;}
    break;

  case 97:
#line 649 "parser.y"
    { (yyval.argument) = argNULL; ;}
    break;

  case 98:
#line 651 "parser.y"
    { (yyval.argument) = (yyvsp[(2) - (3)].argument); ;}
    break;

  case 99:
#line 656 "parser.y"
    { (yyval.argument) = (yyvsp[(1) - (1)].argument); ;}
    break;

  case 100:
#line 658 "parser.y"
    { (yyval.argument) = (yyvsp[(1) - (1)].argument); ;}
    break;

  case 101:
#line 660 "parser.y"
    {
  (yyval.argument) = (yyvsp[(1) - (3)].argument);
  (yyval.argument)->argNext = (yyvsp[(3) - (3)].argument);
;}
    break;

  case 102:
#line 665 "parser.y"
    {
  (yyval.argument) = (yyvsp[(1) - (3)].argument);
  (yyval.argument)->argNext = (yyvsp[(3) - (3)].argument);
;}
    break;

  case 103:
#line 672 "parser.y"
    {
  (yyval.argument) = argAlloc();
  (yyval.argument)->argKind = (yyvsp[(1) - (4)].direction);
  (yyval.argument)->argName = (yyvsp[(2) - (4)].identifier);
  (yyval.argument)->argType = (yyvsp[(3) - (4)].type);
  (yyval.argument)->argFlags = (yyvsp[(4) - (4)].flag);
  if ((yyvsp[(3) - (4)].type) && (yyvsp[(3) - (4)].type)->itNative) {
      if ((yyvsp[(1) - (4)].direction) != akIn && (yyvsp[(1) - (4)].direction) != akOut && (yyvsp[(1) - (4)].direction) != akInOut)
        error("Illegal direction specified");

      if (!((yyvsp[(3) - (4)].type)->itNativePointer) && (yyvsp[(1) - (4)].direction) != akIn)
        error("ValueOf only valid for in");

      if (((yyvsp[(3) - (4)].type)->itBadValue) != NULL && (yyvsp[(1) - (4)].direction) != akIn)
        error("PointerToIfNot only valid for in");
  }
;}
    break;

  case 104:
#line 692 "parser.y"
    {
    (yyval.argument) = argAlloc();
    (yyval.argument)->argKind = (yyvsp[(1) - (3)].direction);
    (yyval.argument)->argName = (yyvsp[(2) - (3)].identifier);
    (yyval.argument)->argType = (yyvsp[(3) - (3)].type);
;}
    break;

  case 105:
#line 701 "parser.y"
    { (yyval.direction) = akNone; ;}
    break;

  case 106:
#line 702 "parser.y"
    { (yyval.direction) = akIn; ;}
    break;

  case 107:
#line 703 "parser.y"
    { (yyval.direction) = akOut; ;}
    break;

  case 108:
#line 704 "parser.y"
    { (yyval.direction) = akInOut; ;}
    break;

  case 109:
#line 705 "parser.y"
    { (yyval.direction) = akRequestPort; ;}
    break;

  case 110:
#line 706 "parser.y"
    { (yyval.direction) = akReplyPort; ;}
    break;

  case 111:
#line 707 "parser.y"
    { (yyval.direction) = akSReplyPort; ;}
    break;

  case 112:
#line 708 "parser.y"
    { (yyval.direction) = akUReplyPort; ;}
    break;

  case 113:
#line 709 "parser.y"
    { (yyval.direction) = akWaitTime; ;}
    break;

  case 114:
#line 710 "parser.y"
    { (yyval.direction) = akSendTime; ;}
    break;

  case 115:
#line 711 "parser.y"
    { (yyval.direction) = akMsgOption; ;}
    break;

  case 116:
#line 712 "parser.y"
    { (yyval.direction) = akSecToken; ;}
    break;

  case 117:
#line 713 "parser.y"
    { (yyval.direction) = akServerSecToken; ;}
    break;

  case 118:
#line 714 "parser.y"
    { (yyval.direction) = akUserSecToken; ;}
    break;

  case 119:
#line 715 "parser.y"
    { (yyval.direction) = akAuditToken; ;}
    break;

  case 120:
#line 716 "parser.y"
    { (yyval.direction) = akServerAuditToken; ;}
    break;

  case 121:
#line 717 "parser.y"
    { (yyval.direction) = akUserAuditToken; ;}
    break;

  case 122:
#line 718 "parser.y"
    { (yyval.direction) = akServerContextToken; ;}
    break;

  case 123:
#line 719 "parser.y"
    { (yyval.direction) = akMsgSeqno; ;}
    break;

  case 124:
#line 724 "parser.y"
    { (yyval.direction) = akServerImpl; ;}
    break;

  case 125:
#line 725 "parser.y"
    { (yyval.direction) = akUserImpl; ;}
    break;

  case 126:
#line 730 "parser.y"
    {
  (yyval.type) = itLookUp((yyvsp[(2) - (2)].identifier));
  if ((yyval.type) == itNULL)
    error("type '%s' not defined", (yyvsp[(2) - (2)].identifier));
;}
    break;

  case 127:
#line 736 "parser.y"
    { (yyval.type) = (yyvsp[(2) - (2)].type); ;}
    break;

  case 128:
#line 738 "parser.y"
    { (yyval.type) = (yyvsp[(2) - (2)].type); ;}
    break;

  case 129:
#line 742 "parser.y"
    { (yyval.flag) = flNone; ;}
    break;

  case 130:
#line 744 "parser.y"
    {
  if ((yyvsp[(1) - (3)].flag) & (yyvsp[(3) - (3)].flag))
    warn("redundant IPC flag ignored");
  else
    (yyval.flag) = (yyvsp[(1) - (3)].flag) | (yyvsp[(3) - (3)].flag);
;}
    break;

  case 131:
#line 751 "parser.y"
    {
  if ((yyvsp[(3) - (5)].flag) != flDealloc)
    warn("only Dealloc is variable");
  else
    (yyval.flag) = (yyvsp[(1) - (5)].flag) | flMaybeDealloc;
;}
    break;

  case 132:
#line 759 "parser.y"
    { LookString(); ;}
    break;

  case 133:
#line 763 "parser.y"
    { LookFileName(); ;}
    break;

  case 134:
#line 767 "parser.y"
    { LookQString(); ;}
    break;


/* Line 1267 of yacc.c.  */
#line 2576 "parser.c"
      default: break;
    }
  YY_SYMBOL_PRINT ("-> $$ =", yyr1[yyn], &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);

  *++yyvsp = yyval;


  /* Now `shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */

  yyn = yyr1[yyn];

  yystate = yypgoto[yyn - YYNTOKENS] + *yyssp;
  if (0 <= yystate && yystate <= YYLAST && yycheck[yystate] == *yyssp)
    yystate = yytable[yystate];
  else
    yystate = yydefgoto[yyn - YYNTOKENS];

  goto yynewstate;


/*------------------------------------.
| yyerrlab -- here on detecting error |
`------------------------------------*/
yyerrlab:
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
#if ! YYERROR_VERBOSE
      yyerror (YY_("syntax error"));
#else
      {
	YYSIZE_T yysize = yysyntax_error (0, yystate, yychar);
	if (yymsg_alloc < yysize && yymsg_alloc < YYSTACK_ALLOC_MAXIMUM)
	  {
	    YYSIZE_T yyalloc = 2 * yysize;
	    if (! (yysize <= yyalloc && yyalloc <= YYSTACK_ALLOC_MAXIMUM))
	      yyalloc = YYSTACK_ALLOC_MAXIMUM;
	    if (yymsg != yymsgbuf)
	      YYSTACK_FREE (yymsg);
	    yymsg = (char *) YYSTACK_ALLOC (yyalloc);
	    if (yymsg)
	      yymsg_alloc = yyalloc;
	    else
	      {
		yymsg = yymsgbuf;
		yymsg_alloc = sizeof yymsgbuf;
	      }
	  }

	if (0 < yysize && yysize <= yymsg_alloc)
	  {
	    (void) yysyntax_error (yymsg, yystate, yychar);
	    yyerror (yymsg);
	  }
	else
	  {
	    yyerror (YY_("syntax error"));
	    if (yysize != 0)
	      goto yyexhaustedlab;
	  }
      }
#endif
    }



  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse look-ahead token after an
	 error, discard it.  */

      if (yychar <= YYEOF)
	{
	  /* Return failure if at end of input.  */
	  if (yychar == YYEOF)
	    YYABORT;
	}
      else
	{
	  yydestruct ("Error: discarding",
		      yytoken, &yylval);
	  yychar = YYEMPTY;
	}
    }

  /* Else will try to reuse look-ahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:

  /* Pacify compilers like GCC when the user code never invokes
     YYERROR and the label yyerrorlab therefore never appears in user
     code.  */
  if (/*CONSTCOND*/ 0)
     goto yyerrorlab;

  /* Do not reclaim the symbols of the rule which action triggered
     this YYERROR.  */
  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);
  yystate = *yyssp;
  goto yyerrlab1;


/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
  yyerrstatus = 3;	/* Each real token shifted decrements this.  */

  for (;;)
    {
      yyn = yypact[yystate];
      if (yyn != YYPACT_NINF)
	{
	  yyn += YYTERROR;
	  if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYTERROR)
	    {
	      yyn = yytable[yyn];
	      if (0 < yyn)
		break;
	    }
	}

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
	YYABORT;


      yydestruct ("Error: popping",
		  yystos[yystate], yyvsp);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  if (yyn == YYFINAL)
    YYACCEPT;

  *++yyvsp = yylval;


  /* Shift the error token.  */
  YY_SYMBOL_PRINT ("Shifting", yystos[yyn], yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturn;

/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturn;

#ifndef yyoverflow
/*-------------------------------------------------.
| yyexhaustedlab -- memory exhaustion comes here.  |
`-------------------------------------------------*/
yyexhaustedlab:
  yyerror (YY_("memory exhausted"));
  yyresult = 2;
  /* Fall through.  */
#endif

yyreturn:
  if (yychar != YYEOF && yychar != YYEMPTY)
     yydestruct ("Cleanup: discarding lookahead",
		 yytoken, &yylval);
  /* Do not reclaim the symbols of the rule which action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
		  yystos[*yyssp], yyvsp);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif
#if YYERROR_VERBOSE
  if (yymsg != yymsgbuf)
    YYSTACK_FREE (yymsg);
#endif
  /* Make sure YYID is used.  */
  return YYID (yyresult);
}


#line 770 "parser.y"


void
yyerror(char *s)
{
  error(s);
}

static char *
import_name(statement_kind_t sk)
{
  switch (sk) {

    case skImport:
      return "Import";

    case skSImport:
      return "SImport";

    case skUImport:
      return "UImport";

    case skIImport:
      return "IImport";

    case skDImport:
      return "DImport";

    default:
      fatal("import_name(%d): not import statement", (int) sk);
      /*NOTREACHED*/
      return strNULL;
  }
}


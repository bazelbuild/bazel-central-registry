/* A Bison parser, made by GNU Bison 2.3.  */

/* Skeleton interface for Bison's Yacc-like parsers in C

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
/* Line 1529 of yacc.c.  */
#line 235 "parser.h"
	YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif

extern YYSTYPE yylval;


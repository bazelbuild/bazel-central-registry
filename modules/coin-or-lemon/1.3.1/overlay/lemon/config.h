// # Copyright 2021 Google LLC
// #
// # Licensed under the Apache License, Version 2.0 (the "License");
// # you may not use this file except in compliance with the License.
// # You may obtain a copy of the License at
// #
// #      http://www.apache.org/licenses/LICENSE-2.0
// #
// # Unless required by applicable law or agreed to in writing, software
// # distributed under the License is distributed on an "AS IS" BASIS,
// # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// # See the License for the specific language governing permissions and
// # limitations under the License.

#define LEMON_VERSION "1.3.1"
#define LEMON_HAVE_LONG_LONG 1

/* #undef LEMON_HAVE_LP */
/* #undef LEMON_HAVE_MIP */
#define LEMON_HAVE_GLPK 1
/* #undef LEMON_HAVE_CPLEX */
/* #undef LEMON_HAVE_SOPLEX */
/* #undef LEMON_HAVE_CLP */
/* #undef LEMON_HAVE_CBC */

#define _LEMON_CPLEX 1
#define _LEMON_CLP 2
#define _LEMON_GLPK 3
#define _LEMON_SOPLEX 4
#define _LEMON_CBC 5

/* #undef LEMON_DEFAULT_LP */
/* #undef LEMON_DEFAULT_MIP */
#define LEMON_DEFAULT_LP _LEMON_GLPK
#define LEMON_DEFAULT_MIP _LEMON_GLPK

#define LEMON_USE_PTHREAD 1
/* #undef LEMON_USE_WIN32_THREADS */

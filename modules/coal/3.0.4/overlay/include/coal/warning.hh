#ifndef COAL_WARNING_HH
#define COAL_WARNING_HH

#define COAL_WARN_STRINGISE_IMPL(x) #x
#define COAL_WARN_STRINGISE(x) COAL_WARN_STRINGISE_IMPL(x)
#ifdef __GNUC__
#define COAL_WARN(exp) ("WARNING: " exp)
#else
#define COAL_WARN(exp) (__FILE__ "(" COAL_WARN_STRINGISE(__LINE__) ") : WARNING: " exp)
#endif

#endif  // COAL_WARNING_HH

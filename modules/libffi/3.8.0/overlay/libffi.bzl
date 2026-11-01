"""Utils for libffi."""

def define(key, value):
    if value == None:
        return "/* #undef %s */" % key
    else:
        return "#define %s %s" % (key, value)

def substitutions(input):
    return {"@%s@" % k: define(k, v) for k, v in input.items()}

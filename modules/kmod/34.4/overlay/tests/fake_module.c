/* The .modinfo section of a kernel module, without the kernel: what modinfo
 * prints, and what depmod and modprobe index (depends, alias). */
#define MODINFO(name, text) \
	static const char name[] __attribute__((section(".modinfo"), used)) = text

MODINFO(license, "license=GPL");
MODINFO(author, "author=Bazel Central Registry");
MODINFO(description, "description=A module for the kmod smoke test");
MODINFO(depends, "depends=");
MODINFO(alias, "alias=bazel:fake");
MODINFO(parm, "parm=level:verbosity (int)");

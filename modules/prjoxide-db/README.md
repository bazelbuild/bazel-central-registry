# prjoxide-db

All versions should be paried with a `prjoxide` versions. Since `prjoxide` has no official releases
as of yet this will knowingly lead to some redundancies in which archives are representitive of which
versions. But it is important to guarantee the correct coupling of `prjoxide-db <--> prjoxide` and
that will require a new `projoxide` version due to the circular `prjoxide-db <--> prjoxide` pins in
`MODULE.bazel` (which we use to guarantee version matching).

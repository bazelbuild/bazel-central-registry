// SPDX-License-Identifier: Apache-2.0
//
// Overlay-only file added by the openfpgaloader BCR port. Declares the
// resolver used by the patched call sites in altera.cpp / xilinx.cpp /
// efinix.cpp to locate spiOverJtag / bpiOverJtag bridge bitstreams.

#ifndef SRC_DATARESOLVER_HPP_
#define SRC_DATARESOLVER_HPP_

#include <string>

// Resolve the on-disk path of a data file shipped with the binary.
//
// When built with -DUSE_RULES_CC_RUNFILES this first tries Bazel's runfiles
// tree at `openfpgaloader/<subdir>/<basename>`. If that lookup fails, or the
// binary was built without runfiles support, this falls back to upstream's
// behaviour: `$OPENFPGALOADER_SOJ_DIR/<basename>` (env-var override) or
// `DATA_DIR "/openFPGALoader/<basename>"` otherwise.
std::string resolveDataFile(const std::string& subdir,
                            const std::string& basename);

#endif  // SRC_DATARESOLVER_HPP_

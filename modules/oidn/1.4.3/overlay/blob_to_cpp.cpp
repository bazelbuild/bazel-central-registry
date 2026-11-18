// Copyright 2009-2021 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

// C++ port of scripts/blob_to_cpp.py with the same command line and output, so
// that the Bazel build can embed the trained weights without requiring Python.

#include <algorithm>
#include <fstream>
#include <iostream>
#include <iterator>
#include <string>
#include <vector>

namespace {

  std::vector<std::string> splitNamespace(const std::string& ns)
  {
    std::vector<std::string> scopes;
    if (ns.empty())
      return scopes;

    size_t begin = 0;
    for (;;)
    {
      const size_t end = ns.find("::", begin);
      scopes.push_back(ns.substr(begin, end == std::string::npos ? std::string::npos : end - begin));
      if (end == std::string::npos)
        return scopes;
      begin = end + 2;
    }
  }

  std::string getBaseName(const std::string& path)
  {
    const size_t pos = path.find_last_of("/\\");
    return pos == std::string::npos ? path : path.substr(pos + 1);
  }

  std::string removeExtension(const std::string& name)
  {
    const size_t pos = name.find_last_of('.');
    return (pos == std::string::npos || pos == 0) ? name : name.substr(0, pos);
  }

  void writePrologue(std::string& out, const std::string& inName)
  {
    out += "// Generated from: " + inName + "\n\n";
  }

  void writeNamespaceBegin(std::string& out, const std::vector<std::string>& scopes)
  {
    for (const std::string& scope : scopes)
      out += "namespace " + scope + " {\n";
    if (!scopes.empty())
      out += "\n";
  }

  void writeNamespaceEnd(std::string& out, const std::vector<std::string>& scopes)
  {
    if (!scopes.empty())
      out += "\n";
    for (auto it = scopes.rbegin(); it != scopes.rend(); ++it)
      out += "} // namespace " + *it + "\n";
  }

  bool writeFile(const std::string& path, const std::string& contents)
  {
    std::ofstream file(path, std::ios::binary);
    file.write(contents.data(), static_cast<std::streamsize>(contents.size()));
    file.close();
    return !file.fail();
  }

  int usage()
  {
    std::cerr << "usage: blob_to_cpp [-n NAMESPACE] -o OUTPUT [-H OUTPUT_HEADER] input" << std::endl;
    return 2;
  }

} // namespace

int main(int argc, char* argv[])
{
  std::string inPath, cppPath, hppPath, ns;
  for (int i = 1; i < argc; ++i)
  {
    const std::string arg = argv[i];
    if ((arg == "-n" || arg == "--namespace") && i + 1 < argc)
      ns = argv[++i];
    else if ((arg == "-o" || arg == "--output") && i + 1 < argc)
      cppPath = argv[++i];
    else if ((arg == "-H" || arg == "--output-header") && i + 1 < argc)
      hppPath = argv[++i];
    else if (inPath.empty() && !arg.empty() && arg[0] != '-')
      inPath = arg;
    else
      return usage();
  }
  if (inPath.empty() || cppPath.empty())
    return usage();

  // Read the input file
  std::ifstream inFile(inPath, std::ios::binary);
  if (!inFile)
  {
    std::cerr << "Error: input file \"" << inPath << "\" does not exist" << std::endl;
    return 2;
  }
  const std::vector<unsigned char> inData((std::istreambuf_iterator<char>(inFile)),
                                          std::istreambuf_iterator<char>());

  // Check whether the file is a Git LFS pointer
  const std::string lfsHeader = "version https://git-lfs.github.com/spec/";
  if (inData.size() >= lfsHeader.size() && std::equal(lfsHeader.begin(), lfsHeader.end(), inData.begin()))
  {
    std::cerr << "Error: The file \"" << inPath << "\" is a Git LFS pointer. "
              << "Please install Git LFS and clone the repository again." << std::endl;
    return 1;
  }

  const std::string inName = getBaseName(inPath);
  const std::string varName = removeExtension(inName);
  const std::string inSize = std::to_string(inData.size());
  const std::vector<std::string> scopes = splitNamespace(ns);

  // Write the source file
  std::string cpp;
  cpp.reserve(inData.size() * 4 + 256);
  writePrologue(cpp, inName);
  writeNamespaceBegin(cpp, scopes);
  cpp += "extern const unsigned char " + varName + "[" + inSize + "] = {";
  for (size_t i = 0; i < inData.size(); ++i)
  {
    if (i > 0)
      cpp += ',';
    if ((i + 1) % 20 == 1)
      cpp += '\n';
    cpp += std::to_string(inData[i]);
  }
  cpp += "\n};\n";
  writeNamespaceEnd(cpp, scopes);
  if (!writeFile(cppPath, cpp))
  {
    std::cerr << "Error: cannot write \"" << cppPath << "\"" << std::endl;
    return 1;
  }

  // Write the header file
  if (!hppPath.empty())
  {
    std::string hpp;
    writePrologue(hpp, inName);
    writeNamespaceBegin(hpp, scopes);
    hpp += "extern const unsigned char " + varName + "[" + inSize + "];\n";
    writeNamespaceEnd(hpp, scopes);
    if (!writeFile(hppPath, hpp))
    {
      std::cerr << "Error: cannot write \"" << hppPath << "\"" << std::endl;
      return 1;
    }
  }

  return 0;
}

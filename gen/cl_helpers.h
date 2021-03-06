//===-- gen/cl_helpers.h - Command line processing helpers ------*- C++ -*-===//
//
//                         LDC – the LLVM D compiler
//
// This file is distributed under the BSD-style LDC license. See the LICENSE
// file for details.
//
//===----------------------------------------------------------------------===//
//
// Helpers to augment the LLVM command line parsing library with some extra
// functionality.
//
//===----------------------------------------------------------------------===//

#ifndef LDC_GEN_CL_HELPERS_H
#define LDC_GEN_CL_HELPERS_H

#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Compiler.h"
#include "gen/llvmcompat.h"

#if LDC_LLVM_VER >= 500
#define LLVM_END_WITH_NULL
#endif

template <typename TYPE> struct Array;
typedef Array<const char *> Strings;

namespace opts {
namespace cl = llvm::cl;

/// Duplicate the string and replace '/' with '\' on Windows.
char *dupPathString(const std::string &src);

/// Helper function to handle -of, -od, etc.
/// llvm::cl::opt<std::string> --> char*
void initFromPathString(const char *&dest, const cl::opt<std::string> &src);

/// Helper class to determine values
template <class DT> struct FlagParserDataType {};

template <> struct FlagParserDataType<bool> {
  static bool true_val() { return true; }
  static bool false_val() { return false; }
};

template <> struct FlagParserDataType<cl::boolOrDefault> {
  static cl::boolOrDefault true_val() { return cl::BOU_TRUE; }
  static cl::boolOrDefault false_val() { return cl::BOU_FALSE; }
};

template <class DataType> class FlagParser : public cl::generic_parser_base {
protected:
  llvm::SmallVector<std::pair<std::string, DataType>, 2> switches;
  cl::Option &owner() const { return Owner; }

public:
  FlagParser(cl::Option &O) : generic_parser_base(O) {}
  typedef DataType parser_data_type;

  void initialize() {
    std::string Name(owner().ArgStr);
    switches.push_back(
        make_pair("enable-" + Name, FlagParserDataType<DataType>::true_val()));
    switches.push_back(make_pair("disable-" + Name,
                                 FlagParserDataType<DataType>::false_val()));
    // Replace <foo> with -enable-<foo> and register -disable-<foo>.
    // A literal option can only registered if the argstr is empty -
    // just do this first.
    owner().setArgStr("");
    AddLiteralOption(Owner, strdup(switches[1].first.data()));
    owner().setArgStr(switches[0].first.data());
  }

  enum cl::ValueExpected getValueExpectedFlagDefault() const {
    return cl::ValueOptional;
  }

  // Implement virtual functions needed by generic_parser_base
  unsigned getNumOptions() const LLVM_OVERRIDE { return 1; }
#if LDC_LLVM_VER >= 400
  llvm::StringRef
#else
  const char *
#endif
  getOption(unsigned N) const LLVM_OVERRIDE {
    assert(N == 0);
#if LDC_LLVM_VER >= 308 && LDC_LLVM_VER < 400
    return owner().ArgStr.data();
#else
    return owner().ArgStr;
#endif
  }

#if LDC_LLVM_VER >= 400
  llvm::StringRef
#else
  const char *
#endif
  getDescription(unsigned N) const LLVM_OVERRIDE {
    assert(N == 0);
#if LDC_LLVM_VER >= 308 && LDC_LLVM_VER < 400
    return owner().HelpStr.data();
#else
    return owner().HelpStr;
#endif
  }

private:
  struct OptionValue : cl::OptionValueBase<DataType, false> {
    OptionValue(){};
  };
  const OptionValue EmptyOptionValue;

public:
  // getOptionValue - Return the value of option name N.
  const cl::GenericOptionValue &getOptionValue(unsigned N) const LLVM_OVERRIDE {
    return EmptyOptionValue;
  }

  // parse - Return true on error.
  bool parse(cl::Option &O, llvm::StringRef ArgName, llvm::StringRef Arg,
             DataType &Val) {
    for (const auto &pair : switches) {
      const auto &name = pair.first;
      if (name == ArgName || (name.size() < ArgName.size() &&
                              ArgName.substr(0, name.size()) == name &&
                              ArgName[name.size()] == '=')) {
        if (!parse(owner(), Arg, Val)) {
          Val = (Val == pair.second)
                    ? FlagParserDataType<DataType>::true_val()
                    : FlagParserDataType<DataType>::false_val();
          return false;
        }
        // Invalid option value
        break;
      }
    }
    return true;
  }

#if LDC_LLVM_VER >= 308
  void getExtraOptionNames(llvm::SmallVectorImpl<llvm::StringRef> &Names) {
#else
  void getExtraOptionNames(llvm::SmallVectorImpl<const char *> &Names) {
#endif
    for (auto I = switches.begin() + 1, E = switches.end(); I != E; ++I) {
      Names.push_back(I->first.data());
    }
  }

private:
  static bool parse(cl::Option &O, llvm::StringRef Arg, DataType &Val) {
    if (Arg == "" || Arg == "true" || Arg == "TRUE" || Arg == "True" ||
        Arg == "1") {
      Val = FlagParserDataType<DataType>::true_val();
      return false;
    }

    if (Arg == "false" || Arg == "FALSE" || Arg == "False" || Arg == "0") {
      Val = FlagParserDataType<DataType>::false_val();
      return false;
    }
    return O.error("'" + Arg +
                   "' is invalid value for boolean argument! Try 0 or 1");
  }
};

/// Helper class for options that set multiple flags
class MultiSetter {
  std::vector<bool *> locations;
  bool invert;
  explicit MultiSetter(bool); // not implemented, disable auto-conversion
public:
  MultiSetter(bool invert, bool *p, ...) LLVM_END_WITH_NULL;

  void operator=(bool val);
};

/// Helper class to fill Strings with char* when given strings
/// (Errors on empty strings)
class StringsAdapter {
  const char *name;
  Strings **arrp;

public:
  StringsAdapter(const char *name_, Strings *&arr) {
    name = name_;
    arrp = &arr;
    assert(name);
    assert(arrp);
  }

  void push_back(const char *cstr);

  void push_back(const std::string &str) { push_back(str.c_str()); }
};
}


#if LDC_LLVM_VER >= 400
#define clEnumValues llvm::cl::values
#else
template <typename DataType, typename... OptsTy>
llvm::cl::ValuesClass<DataType> clEnumValues(const char *Arg, DataType Val,
                                             const char *Desc,
                                             OptsTy... Options) {
  return llvm::cl::values(Arg, Val, Desc, Options..., clEnumValEnd);
}
#endif

#endif

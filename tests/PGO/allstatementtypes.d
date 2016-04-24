// Test instrumentation of all 'simple' AST statement types.

// Disable autogenerated boundschecking to declutter the generated code.
// See boundscheck.d for boundschecking instrumenation tests.

// RUN: %ldc -boundscheck=off -c -output-ll -fprofile-instr-generate="hoihoihoi" -of=%t.ll %s && FileCheck %s --check-prefix=PROFGEN < %t.ll

// PROFGEN-DAG: @[[FILENAME:.+]] ={{.*}} constant{{.*}} c"hoihoihoi\00"

// RUN: %ldc -boundscheck=off -fprofile-instr-generate=%t.profraw -run %s  \
// RUN:   &&  %profdata merge %t.profraw -o %t.profdata \
// RUN:   &&  %ldc -boundscheck=off -c -output-ll -of=%t2.ll -fprofile-instr-use=%t.profdata %s \
// RUN:   &&  FileCheck %s -check-prefix=PROFUSE < %t2.ll

extern(C):  // simplify name mangling for simpler string matching

// PROFGEN-DAG: @[[FL:__(llvm_profile_counters|profc)_for_loop]] ={{.*}} global [7 x i64] zeroinitializer
// PROFGEN-DAG: @[[FEL:__(llvm_profile_counters|profc)_foreach_loop]] ={{.*}} global [5 x i64] zeroinitializer
// PROFGEN-DAG: @[[FERL:__(llvm_profile_counters|profc)_foreachrange_loop]] ={{.*}} global [6 x i64] zeroinitializer
// PROFGEN-DAG: @[[LG:__(llvm_profile_counters|profc)_label_goto]] ={{.*}} global [7 x i64] zeroinitializer
// PROFGEN-DAG: @[[SWC:__(llvm_profile_counters|profc)_c_switches]] ={{.*}} global [23 x i64] zeroinitializer
// PROFGEN-DAG: @[[DSW:__(llvm_profile_counters|profc)_d_switches]] ={{.*}} global [15 x i64] zeroinitializer
// PROFGEN-DAG: @[[BOOL:__(llvm_profile_counters|profc)_booleanlogic]] ={{.*}} global [9 x i64] zeroinitializer
// PROFGEN-DAG: @[[DW:__(llvm_profile_counters|profc)_do_while]] ={{.*}} global [6 x i64] zeroinitializer

// PROFGEN-LABEL: @for_loop()
// PROFUSE-LABEL: @for_loop()
// PROFGEN: store {{.*}} @[[FL]], i64 0, i64 0
// PROFUSE-SAME: !prof ![[FL0:[0-9]+]]
void for_loop() {
  uint i;
  // PROFGEN: store {{.*}} @[[FL]], i64 0, i64 1
  // PROFUSE: br {{.*}} !prof ![[FL1:[0-9]+]]
  for (i = 0; i < 400; ++i) {
    // PROFGEN: store {{.*}} @[[FL]], i64 0, i64 2
    // PROFUSE: br {{.*}} !prof ![[FL2:[0-9]+]]
    if (i > 389) {
        break;
    } else {
      // PROFGEN: store {{.*}} @[[FL]], i64 0, i64 3
      // PROFUSE: br {{.*}} !prof ![[FL3:[0-9]+]]
      if (i) {}
    }

    // PROFGEN: store {{.*}} @[[FL]], i64 0, i64 4
    // PROFUSE: br {{.*}} !prof ![[FL4:[0-9]+]]
    if (i > 2) {
        continue;
    }
  }

  // PROFGEN: store {{.*}} @[[FL]], i64 0, i64 5
  // PROFUSE: br {{.*}} !prof ![[FL5:[0-9]+]]
  // PROFGEN: store {{.*}} @[[FL]], i64 0, i64 6
  // PROFUSE: br {{.*}} !prof ![[FL6:[0-9]+]]
  for (uint a = i ? 2 : 1; /+ empty condition +/; ) {
    break;
  }
}

// PROFGEN-LABEL: @foreach_loop()
// PROFUSE-LABEL: @foreach_loop()
// PROFGEN: store {{.*}} @[[FEL]], i64 0, i64 0
// PROFUSE-SAME: !prof ![[FEL0:[0-9]+]]
void foreach_loop() {
  // PROFGEN: store {{.*}} @[[FEL]], i64 0, i64 1
  // PROFUSE: br {{.*}} !prof ![[FEL1:[0-9]+]]
  foreach (i; 0..400) {
    // PROFGEN: store {{.*}} @[[FEL]], i64 0, i64 2
    // PROFUSE: br {{.*}} !prof ![[FEL2:[0-9]+]]
    if (i > 389) {
        break;
    } else {
      // PROFGEN: store {{.*}} @[[FEL]], i64 0, i64 3
      // PROFUSE: br {{.*}} !prof ![[FEL3:[0-9]+]]
      if (i) {}
    }
    // PROFGEN: store {{.*}} @[[FEL]], i64 0, i64 4
    // PROFUSE: br {{.*}} !prof ![[FEL4:[0-9]+]]
    if (i > 2) {
        continue;
    }
  }
}

// PROFGEN-LABEL: @foreachrange_loop()
// PROFUSE-LABEL: @foreachrange_loop()
// PROFGEN: store {{.*}} @[[FERL]], i64 0, i64 0
// PROFUSE-SAME: !prof ![[FERL0:[0-9]+]]
void foreachrange_loop() {
  import std.range : iota;
  auto f = false;
  // PROFGEN: store {{.*}} @[[FERL]], i64 0, i64 1
  // PROFUSE: br {{.*}} !prof ![[FERL1:[0-9]+]]
  // PROFGEN: store {{.*}} @[[FERL]], i64 0, i64 2
  // PROFUSE: br {{.*}} !prof ![[FERL2:[0-9]+]]
  foreach (i; f ? iota(0,200) : iota(0,400)) {
    // PROFGEN: store {{.*}} @[[FERL]], i64 0, i64 3
    // PROFUSE: br {{.*}} !prof ![[FERL3:[0-9]+]]
    if (i > 389) {
        break;
    } else {
      // PROFGEN: store {{.*}} @[[FERL]], i64 0, i64 4
      // PROFUSE: br {{.*}} !prof ![[FERL4:[0-9]+]]
      if (i) {}
    }
    // PROFGEN: store {{.*}} @[[FERL]], i64 0, i64 5
    // PROFUSE: br {{.*}} !prof ![[FERL5:[0-9]+]]
    if (i > 2) {
        continue;
    }
  }
}


// PROFGEN-LABEL: @label_goto()
// PROFUSE-LABEL: @label_goto()
// PROFGEN: store {{.*}} @[[LG]], i64 0, i64 0
// PROFUSE-SAME: !prof ![[LG0:[0-9]+]]
void label_goto() {
  int i = 0; // 1x
  // PROFGEN: store {{.*}} @[[LG]], i64 0, i64 1
start:
  ++i; // 10x
  // PROFGEN: store {{.*}} @[[LG]], i64 0, i64 2
  // PROFUSE: br {{.*}} !prof ![[LG2:[0-9]+]]
  if (i >= 10) // 10x
  {
    goto end; // 1x
  }
  goto start; // 9x

  // PROFGEN: store {{.*}} @[[LG]], i64 0, i64 3
  // PROFUSE-NOT: br {{.*}} !prof
  // PROFUSE: br
  if (i >= 567) {} // 0x (never reached -> no weights)
// PROFGEN: store {{.*}} @[[LG]], i64 0, i64 4
doublelabel: // 0x
// PROFGEN: store {{.*}} @[[LG]], i64 0, i64 5
end: // 1x
  ++i; // 1x
// Also emit counter for label at end of function:
// PROFGEN: store {{.*}} @[[LG]], i64 0, i64 6
emptylabel: // 1x
}

// PROFGEN-LABEL: @c_switches()
// PROFUSE-LABEL: @c_switches()
// PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 0
// PROFUSE-SAME: !prof ![[SW0:[0-9]+]]
void c_switches() {
  static int weights[] = [1, 2, 2, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 5];

  // The switch counter blocks are generated in the following order:
  // - default block
  // - cases
  // - switch end

  // No cases -> no weights
  switch (weights[0]) {
  // PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 2
  default:
    break;
  }
  // PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 1


  // PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 3
  // PROFUSE: br {{.*}} !prof ![[SW1:[0-9]+]]
  for (int i = 0; i < weights.length; ++i) {

    // PROFUSE: switch {{.*}} [
    // PROFUSE: ], !prof ![[SW2:[0-9]+]]
    switch (weights[i]) {
    // default counter:
    // PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 20

    // PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 5
    case 1:
      // PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 6
      // PROFUSE: br {{.*}} !prof ![[SW3:[0-9]+]]
      if (i) {}
      // fallthrough
    // PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 7
    case 2:
      // PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 8
      // PROFUSE: br {{.*}} !prof ![[SW4:[0-9]+]]
      if (i) {}
      break;
    // PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 9
    case 3:
      // PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 10
      // PROFUSE: br {{.*}} !prof ![[SW5:[0-9]+]]
      if (i) {}
      continue;
    // PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 11
    case 4:
      // PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 12
      // PROFUSE: br {{.*}} !prof ![[SW6:[0-9]+]]
      if (i) {}
      // PROFUSE: switch {{.*}} [
      // PROFUSE: ], !prof ![[SW7:[0-9]+]]
      switch (i) {
      // default counter:
      // PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 19

      // PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 14
      // PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 15
      // PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 16
      // PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 17
      case 6: .. case 9:
        // PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 18
        // PROFUSE: br {{.*}} !prof ![[SW8:[0-9]+]]
        if (i) {}
        continue;
      default:
      }
      // PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 13
      // fallthrough

    default:
      // PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 21
      // PROFUSE: br {{.*}} !prof ![[SW9:[0-9]+]]
      if (i == weights.length - 1)
        return;
    }
    // PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 4
  }

  // PROFGEN: store {{.*}} @[[SWC]], i64 0, i64 22
  // Never reached -> no weights
  if (weights[0]) {}

  // PROFGEN-NOT: store {{.*}} @[[SWC]],
  // PROFUSE-NOT: br {{.*}} !prof ![0-9]+
}


// test the particulars of switches using D features
// PROFGEN-LABEL: @d_switches()
// PROFUSE-LABEL: @d_switches()
// PROFGEN: store {{.*}} @[[DSW]], i64 0, i64 0
// PROFUSE-SAME: !prof ![[DSW0:[0-9]+]]
void d_switches() {
  uint i;
  // PROFGEN: store {{.*}} @[[DSW]], i64 0, i64 1
  // PROFUSE: br {{.*}} !prof ![[DSW1:[0-9]+]]
  for (i = 1; i < 4; ++i) {

    // PROFUSE: switch {{.*}} [
    // PROFUSE: ], !prof ![[DSW2:[0-9]+]]
    switch (i) {
    // default counter:
    // PROFGEN: store {{.*}} @[[DSW]], i64 0, i64 10

    // PROFGEN: store {{.*}} @[[DSW]], i64 0, i64 3
    case 1: // 2x (gototarget)
      // PROFGEN: store {{.*}} @[[DSW]], i64 0, i64 4

      // PROFGEN: store {{.*}} @[[DSW]], i64 0, i64 5
      // PROFUSE: br {{.*}} !prof ![[DSW5:[0-9]+]]
      if (i != 1) {}
      goto default;

    // PROFGEN: store {{.*}} @[[DSW]], i64 0, i64 6
    case 11: // 0x
      // PROFGEN: store {{.*}} @[[DSW]], i64 0, i64 7
      // never reached, no branch weights
      if (i != 11) {}

    // PROFGEN: store {{.*}} @[[DSW]], i64 0, i64 8
    case 2: // 1x
      // PROFGEN: store {{.*}} @[[DSW]], i64 0, i64 9
      // PROFUSE: br {{.*}} !prof ![[DSW9:[0-9]+]]
      if (i != 2) {}
      goto case 1;

    default: // 2x (gototarget)
      // PROFGEN: store {{.*}} @[[DSW]], i64 0, i64 11
      // fall through

    // PROFGEN: store {{.*}} @[[DSW]], i64 0, i64 12
    case 5: // 2x (fallthrough)
      // PROFGEN: store {{.*}} @[[DSW]], i64 0, i64 13
      // PROFUSE: br {{.*}} !prof ![[DSW13:[0-9]+]]
      if (i != 5) {}
      break;
    }
    // PROFGEN: store {{.*}} @[[DSW]], i64 0, i64 2
  }

  // PROFGEN: store {{.*}} @[[DSW]], i64 0, i64 14
  // PROFUSE: br {{.*}} !prof ![[DSW14:[0-9]+]]
  if (i) {}

  // PROFGEN-NOT: store {{.*}} @[[DSW]],
  // PROFUSE-NOT: br {{.*}} !prof ![0-9]+
}

// PROFGEN-LABEL: @booleanlogic()
// PROFUSE-LABEL: @booleanlogic()
// PROFGEN: store {{.*}} @[[BOOL]], i64 0, i64 0
// PROFUSE-SAME: !prof ![[BOOL0:[0-9]+]]
void booleanlogic() {
  bool t = true, f = false;
  bool x;

  // PROFGEN: store {{.*}} @[[BOOL]], i64 0, i64 1
  // PROFUSE: br {{.*}} !prof ![[BOOL1:[0-9]+]]
  x = f && t;

  // PROFGEN: store {{.*}} @[[BOOL]], i64 0, i64 2
  // PROFGEN: store {{.*}} @[[BOOL]], i64 0, i64 3
  // PROFUSE: br {{.*}} !prof ![[BOOL2:[0-9]+]]
  // 2nd is never reached -> no weights
  x = f && (f && t);

  // PROFGEN: store {{.*}} @[[BOOL]], i64 0, i64 4
  // PROFUSE: br {{.*}} !prof ![[BOOL4:[0-9]+]]
  x = t || f;

  // PROFGEN: store {{.*}} @[[BOOL]], i64 0, i64 6
  // PROFGEN: store {{.*}} @[[BOOL]], i64 0, i64 5
  // PROFUSE: br {{.*}} !prof ![[BOOL6:[0-9]+]]
  // PROFUSE: br {{.*}} !prof ![[BOOL5:[0-9]+]]
  x = (f || f) || t;

  // PROFGEN: store {{.*}} @[[BOOL]], i64 0, i64 7
  // PROFGEN: store {{.*}} @[[BOOL]], i64 0, i64 8
  // PROFUSE: br {{.*}} !prof ![[BOOL7:[0-9]+]]
  // PROFUSE: br {{.*}} !prof ![[BOOL8:[0-9]+]]
  x = f ? t : (f && t);

  // PROFGEN-NOT: store {{.*}} @[[BOOL]],
  // PROFUSE-NOT: br {{.*}} !prof ![0-9]+
}

// PROFGEN-LABEL: @do_while()
// PROFUSE-LABEL: @do_while()
// PROFGEN: store {{.*}} @[[DW]], i64 0, i64 0
// PROFUSE-SAME: !prof ![[DW0:[0-9]+]]
void do_while() {
  int i;
  // PROFGEN: store {{.*}} @[[DW]], i64 0, i64 1
  do {
    ++i;

    // PROFGEN: store {{.*}} @[[DW]], i64 0, i64 2
    // PROFUSE: br {{.*}} !prof ![[DW2:[0-9]+]]
    if (i < 10) {
      continue;
    }

    // PROFGEN: store {{.*}} @[[DW]], i64 0, i64 3
    // PROFUSE: br {{.*}} !prof ![[DW3:[0-9]+]]
    if (i >= 33) {
      break;
    }
  } while (i < 6633);
  // PROFUSE: br {{.*}} !prof ![[DW1:[0-9]+]]

  // (while is lowered to a for statement)
  // PROFGEN: store {{.*}} @[[DW]], i64 0, i64 4
  // PROFUSE: br {{.*}} !prof ![[DW4:[0-9]+]]
  while (i > 2) {
    --i;
    // PROFGEN: store {{.*}} @[[DW]], i64 0, i64 5
    // PROFUSE: br {{.*}} !prof ![[DW5:[0-9]+]]
    if (i < 321) {}
  }
}

// PROFGEN-LABEL: @_Dmain(
// PROFUSE-LABEL: @_Dmain(
extern(D):
void main() {
  // Simply tests that all conditional branches have branch weights:
  // PROFUSE-NOT: {{br i1 %[0-9]+, label %[A-Za-z0-9\.]+, label %[A-Za-z0-9\.]+$}}

  for_loop();
  foreach_loop();
  foreachrange_loop();
  label_goto();
  c_switches();
  d_switches();
  booleanlogic();
  do_while();

  // Detect function end:
  // PROFUSE:      ret i32 0
  // PROFUSE-NEXT: }
}

// PROFGEN-DAG: call {{.*}} @__llvm_profile_override_default_filename{{.*}} @[[FILENAME]]

// PROFUSE-DAG: ![[FL0]] = !{!"function_entry_count", i64 1}
// PROFUSE-DAG: ![[FL1]] = !{!"branch_weights", i32 392, i32 1}
// PROFUSE-DAG: ![[FL2]] = !{!"branch_weights", i32 2, i32 391}
// PROFUSE-DAG: ![[FL3]] = !{!"branch_weights", i32 390, i32 2}
// PROFUSE-DAG: ![[FL4]] = !{!"branch_weights", i32 388, i32 4}
// PROFUSE-DAG: ![[FL5]] = !{!"branch_weights", i32 2, i32 1}
// PROFUSE-DAG: ![[FL6]] = !{!"branch_weights", i32 2, i32 1}

// PROFUSE-DAG: ![[FEL0]] = !{!"function_entry_count", i64 1}
// PROFUSE-DAG: ![[FEL1]] = !{!"branch_weights", i32 392, i32 1}
// PROFUSE-DAG: ![[FEL2]] = !{!"branch_weights", i32 2, i32 391}
// PROFUSE-DAG: ![[FEL3]] = !{!"branch_weights", i32 390, i32 2}
// PROFUSE-DAG: ![[FEL4]] = !{!"branch_weights", i32 388, i32 4}

// PROFUSE-DAG: ![[FERL0]] = !{!"function_entry_count", i64 1}
// PROFUSE-DAG: ![[FERL1]] = !{!"branch_weights", i32 1, i32 2}
// PROFUSE-DAG: ![[FERL2]] = !{!"branch_weights", i32 392, i32 1}
// PROFUSE-DAG: ![[FERL3]] = !{!"branch_weights", i32 2, i32 391}
// PROFUSE-DAG: ![[FERL4]] = !{!"branch_weights", i32 390, i32 2}
// PROFUSE-DAG: ![[FERL5]] = !{!"branch_weights", i32 388, i32 4}

// PROFUSE-DAG: ![[LG0]] = !{!"function_entry_count", i64 1}
// PROFUSE-DAG: ![[LG2]] = !{!"branch_weights", i32 2, i32 10}

// PROFUSE-DAG: ![[SW0]] = !{!"function_entry_count", i64 1}
// PROFUSE-DAG: ![[SW1]] = !{!"branch_weights", i32 16, i32 1}
// PROFUSE-DAG: ![[SW2]] = !{!"branch_weights", i32 6, i32 2, i32 3, i32 4, i32 5}
// PROFUSE-DAG: ![[SW3]] = !{!"branch_weights", i32 1, i32 2}
// PROFUSE-DAG: ![[SW4]] = !{!"branch_weights", i32 3, i32 2}
// PROFUSE-DAG: ![[SW5]] = !{!"branch_weights", i32 4, i32 1}
// PROFUSE-DAG: ![[SW6]] = !{!"branch_weights", i32 5, i32 1}
// PROFUSE-DAG: ![[SW7]] = !{!"branch_weights", i32 1, i32 2, i32 2, i32 2, i32 2}
// PROFUSE-DAG: ![[SW8]] = !{!"branch_weights", i32 5, i32 1}
// PROFUSE-DAG: ![[SW9]] = !{!"branch_weights", i32 2, i32 5}

// PROFUSE-DAG: ![[DSW0]] = !{!"function_entry_count", i64 1}
// PROFUSE-DAG: ![[DSW1]] = !{!"branch_weights", i32 4, i32 2}
// PROFUSE-DAG: ![[DSW2]] = !{!"branch_weights", i32 2, i32 2, i32 1, i32 2, i32 1}
// PROFUSE-DAG: ![[DSW5]] = !{!"branch_weights", i32 2, i32 2}
// PROFUSE-DAG: ![[DSW9]] = !{!"branch_weights", i32 1, i32 2}
// PROFUSE-DAG: ![[DSW13]] = !{!"branch_weights", i32 4, i32 1}

// PROFUSE-DAG: ![[BOOL0]] = !{!"function_entry_count", i64 1}
// PROFUSE-DAG: ![[BOOL1]] = !{!"branch_weights", i32 1, i32 2}
// PROFUSE-DAG: ![[BOOL2]] = !{!"branch_weights", i32 1, i32 2}
// PROFUSE-DAG: ![[BOOL4]] = !{!"branch_weights", i32 2, i32 1}
// PROFUSE-DAG: ![[BOOL5]] = !{!"branch_weights", i32 1, i32 2}
// PROFUSE-DAG: ![[BOOL6]] = !{!"branch_weights", i32 1, i32 2}
// PROFUSE-DAG: ![[BOOL7]] = !{!"branch_weights", i32 1, i32 2}
// PROFUSE-DAG: ![[BOOL8]] = !{!"branch_weights", i32 1, i32 2}

// PROFUSE-DAG: ![[DW0]] = !{!"function_entry_count", i64 1}
// PROFUSE-DAG: ![[DW1]] = !{!"branch_weights", i32 33, i32 1}
// PROFUSE-DAG: ![[DW2]] = !{!"branch_weights", i32 10, i32 25}
// PROFUSE-DAG: ![[DW3]] = !{!"branch_weights", i32 2, i32 24}
// PROFUSE-DAG: ![[DW4]] = !{!"branch_weights", i32 32, i32 2}
// PROFUSE-DAG: ![[DW5]] = !{!"branch_weights", i32 32, i32 1}

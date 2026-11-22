#include "simp/SimpSolver.h"

#include <cstdio>

using namespace Glucose;

int main() {
  SimpSolver s;
  s.verbosity = 0;
  Var a = s.newVar();
  Var b = s.newVar();

  // (a | b) & (!a | b): satisfiable, and b must be true.
  vec<Lit> clause;
  clause.push(mkLit(a));
  clause.push(mkLit(b));
  s.addClause(clause);
  s.addClause(~mkLit(a), mkLit(b));
  if (!s.solve() || s.modelValue(b) != l_True) {
    std::fprintf(stderr, "expected SAT with b = true\n");
    return 1;
  }

  // Assuming !b contradicts the above.
  vec<Lit> assumptions;
  assumptions.push(~mkLit(b));
  if (s.solve(assumptions)) {
    std::fprintf(stderr, "expected UNSAT under !b\n");
    return 1;
  }
  return 0;
}

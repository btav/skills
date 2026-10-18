# Shared lenses

Six ways of looking at a change, used by review (to sharpen findings) and diff walkthroughs (to sharpen lens notes). A lens can help spot a concrete problem; it never justifies a comment or note you wouldn't otherwise leave. If the only reason to flag something is "it violates law X", drop it.

- **YAGNI** — speculative abstraction, config knob with no caller, parameter added "for later", branch that can't be reached today.
- **DRY (real)** — the same knowledge now expressed in two places. Coincidental similarity doesn't count.
- **Law of Demeter** — `a.b.c.d` chains that reach through and depend on the internals of an unrelated object.
- **Hyrum's Law** — exported signature, return shape, error shape, ordering, or timing changed in a way that consumers may silently depend on, even if the typed contract still compiles.
- **Premature Optimization** — micro-opt (manual unrolling, custom hash, hand-rolled cache) added off the hot path with no benchmark.
- **Broken Windows** — commented-out code, `// TODO(remove)`, dead imports, or half-finished work *introduced by this change*. Pre-existing rot is out of scope.

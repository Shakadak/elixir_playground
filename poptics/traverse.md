```haskell
traverse :: (Cocartesian p, Monoidal p) ⇒ p a b → p (FunList a c t) (FunList b c t)
traverse k = dimap out inn (right (par k (traverse k)))
```

Informally, traverse k uses `out` to analyse the `FunList`, determining whether
- it is `Done`
- or consists of `More` applied to a `head` and a `taill`;
  in the latter case (the combinator right lifts a transformer to act on the right-hand component in a sum type),
  it applies `k` to the `head` and recursively calls `traverse k` on the tail;
  then it reassembles the results using `inn`.

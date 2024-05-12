import Syntax

example1 = lam("x", lam("y", lam("z", op("+", op("+", var("x"), var("y")), var("z")))))

IO.inspect(example1)

x1 =
  Sd.Infer.infer(example1)
  |> IO.inspect()

Sd.Infer.runInfer(TypeEnv.empty(), x1)
|> IO.inspect()

Sd.Infer.inferExpr(TypeEnv.empty(), example1)
|> IO.inspect()

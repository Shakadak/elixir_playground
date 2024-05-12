import FiniteDomain
import ComputationExpression

test = compute FiniteDomain do
  let! x = newVar 0..3
  let! y = newVar 0..3
  do! (lessThan x, y) |> (mplus (same x, y))
  do! x |> (hasValue 2)
  pure! labelling [x, y]
end

runTest = runFD test

IO.inspect(runTest |> Enum.to_list(), label: "runTest |> to_list")

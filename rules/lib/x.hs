module Tuto where

chainCPS :: ((a -> r) -> r) -> (a -> (b -> r) -> r) -> ((b -> r) -> r)
chainCPS    ma f = \k -> ma (\x -> f x k)
-- chainCPS f fk = \k -> f (\x -> fk x k)
-- chainCPS f fk = \k -> f ((flip fk) k)

chainCPS2 :: ((a -> r) -> r) -> (a -> (b -> r) -> r) -> (b -> r) -> r
chainCPS2   ma f = \k -> ma (\x -> f x k)

cmap :: (a -> b) -> ((a -> r) -> r) -> ((b -> r) -> r)
cmap f ma = \k -> k (ma f)

map f ma = \ k -> ma (\ x -> (k (f x)))


module Link(link) where

import Util

link :: [String] -> IO ()
link xs = do
    let ys = xs ++ ["ghc" | "base" `elem` xs]
    deps <- mapM (\x -> do d <- depends x; return (x, ys `intersect` d)) ys
    mapM_ (\d -> convert d (fromJust $ lookup d deps)) $ order deps
    when (length xs > 1) $
        system_ $ unwords $ "hoogle" : "/output=result/default.hoo" : ["/combine=result/" ++ map toLower x | x <- xs]


convert :: String -> [String] -> IO ()
convert hoo dep = system_ $ unwords $
    ["hoogle","/convert=result/" ++ hoo,"/output=result/" ++ map toLower hoo ++ ".hoo"] ++
    ["/data=result/" ++ d | d <- dep]


depends :: String -> IO [String]
depends x = do
    src <- readFile $ "result/" ++ x ++ ".txt"
    return [d
        | x <- takeWhile (\x -> null x || "--" `isPrefixOf` x || "@" `isPrefixOf` x) $ lines src
        , ("@depends ",d) <- [splitAt 9 x]]


order :: (Show a, Eq a) => [(a,[a])] -> [a]
order = f []
    where
        f done xs | null xs = []
                  | null now = error $ "Link.order, circular: " ++ show (done,xs)
                  | otherwise = now2 ++ f (now2++done) later
            where (now,later) = partition (\x -> null $ snd x \\ done) xs
                  now2 = map fst now

module System.Time.Extra(
    sleep,
    subtractTime,
    showTime,
    offsetTime, offsetTimeIncrease, duration
    ) where

import Control.Concurrent
import Data.Time.Clock
import Numeric.Extra
import Data.IORef


sleep :: Double -> IO ()
sleep x = threadDelay $ ceiling $ x * 1000000


subtractTime :: UTCTime -> UTCTime -> Double
subtractTime end start = fromRational $ toRational $ end `diffUTCTime` start


showTime :: Double -> String
showTime x | x >= 3600 = f (x / 60) "h" "m"
           | x >= 60 = f x "m" "s"
           | otherwise = showDP 2 x ++ "s"
    where
        f x m s = show ms ++ m ++ ['0' | ss < 10] ++ show ss ++ m
            where (ms,ss) = round x `divMod` 60



-- | Call once at the start, then call repeatedly to get Time values out
offsetTime :: IO (IO Double)
offsetTime = do
    start <- getCurrentTime
    return $ do
        end <- getCurrentTime
        return $ end `subtractTime` start

-- | Like offsetTime, but results will never decrease (though they may stay the same)
offsetTimeIncrease :: IO (IO Double)
offsetTimeIncrease = do
    t <- offsetTime
    ref <- newIORef 0
    return $ do
        t <- t
        atomicModifyIORef ref $ \o -> let m = max t o in m `seq` (m, m)


duration :: IO a -> IO (Double, a)
duration act = do
    time <- offsetTime
    res <- act
    time <- time
    return (time, res)

module Main where

import Lib
import System.Environment (getEnv)
import Data.Text (pack)

main :: IO ()
main = do
    dbUrl <- getEnv "DATABASE_URL"
    port <- read <$> getEnv "PORT"
    participantLimit <- read <$> getEnv "PARTICIPANT_LIMIT"
    pw <- AdminPassword . pack <$> getEnv "ADMIN_PASSWORD"
    startApp dbUrl port participantLimit pw

{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Types
    ( Participant(..)
    , Sleepover(..)
    , ParticipantId(..)
    , GymSleepingLimit(..)
    , CampingSleepingLimit(..)
    , GymSleepingLimitReached(..)
    , CampingSleepingLimitReached(..)
    ) where

import qualified Data.Text as T
import Data.Time.Calendar (Day)
import Web.HttpApiData (FromHttpApiData)

-- CouldntSelect represents a participant which registered when all sleepover spots were already taken.
data Sleepover = Camping | NoNights | GymSleeping | CouldntSelect deriving (Show, Ord, Eq)

newtype ParticipantId = ParticipantId Int deriving (FromHttpApiData, Show)

data Participant = Participant
    { participantName :: T.Text
    , participantBirthday :: Day
    , participantStreet :: T.Text
    , participantPostalCode :: T.Text
    , participantCity :: T.Text
    , participantSleepovers :: Sleepover
    , participantCountry :: T.Text
    , participantComment :: Maybe T.Text
    , participantEmail :: Maybe T.Text
    } deriving (Show)

newtype GymSleepingLimit = GymSleepingLimit Int
newtype CampingSleepingLimit = CampingSleepingLimit Int

data GymSleepingLimitReached = GymSleepingLimitReached | EnoughGymSleepingSpots deriving (Show, Eq)
data CampingSleepingLimitReached = CampingSleepingLimitReached | EnoughTentSpots deriving (Show, Eq)

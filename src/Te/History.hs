{-# LANGUAGE ExtendedDefaultRules #-}

module Te.History (record, last) where

import Import

import Data.Text (strip, intercalate, splitOn, concat, Text(..))
import Shelly

import Te.Types (TestRunner(..))
import Te.Util


record :: TestRunner -> Sh ()
record (TestRunner executable args) = do
  let stringArgs = intercalate " " args
      historyCommand = fromText $ concat ["echo \"", executable, " ", stringArgs, "\" >> .te-history"]
  escaping False $ run_ historyCommand []


last :: Sh (Maybe TestRunner)
last = do
  lastHistoryItem <- readHistory
  let item = splitOn " " $ strip lastHistoryItem
  return $ case (headMay item) of
             Nothing -> Nothing
             Just "" -> Nothing
             Just executable -> Just $ TestRunner executable (tailSafe item)
  where
    readHistory = do
      file <- hasFile ".te-history"
      case file of
        True -> cmd "tail" "-1" ".te-history" :: Sh Text
        False -> return ""

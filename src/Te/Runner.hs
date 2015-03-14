{-# LANGUAGE ExtendedDefaultRules #-}

module Te.Runner (runTest, hasPipe, hasFile, getTestRunner, lastTestRunner, TestRunner(..), isTestRunner) where

import System.Process
import Data.Text (Text, pack, unpack, replicate, concat, intercalate)
import Data.Text.Read (decimal)
import Data.Maybe
import Control.Monad (mapM)

import Shelly

import Import
import Te.Util
import Te.Types
import qualified Te.History as History


runTest :: TestRunner -> Sh ()
runTest testRunner@(NewTestRunner exe args) = do
  History.record testRunner
  runTest' exe args

runTest (OldTestRunner exe args) = runTest' exe args

runTest' :: Executable -> [Argument] -> Sh ()
runTest' exe args = do
  let executable = unpack exe
      arguments = fmap unpack args
  liftIO $ rawSystem executable arguments

  columns <- silently $ cmd "tput" "cols" :: Sh Text
  let int = case (decimal columns) of
              Right (i, _) -> i
              Left _ -> 5

  echo $ replicate int "-"
  echo ""


getTestRunner :: [Text] -> Sh (Maybe TestRunner)
getTestRunner args = do
  runners <- mapM (getRunner args) frameworks
  let validRunners = catMaybes runners
  return $ case (catMaybes runners) of
             [] -> Nothing
             (r:_) -> Just r


lastTestRunner :: Sh (Maybe TestRunner)
lastTestRunner = History.last


frameworks :: [TestFramework]
frameworks = [RSpec, Minitest]


getRunner :: [Argument] -> TestFramework -> Sh (Maybe TestRunner)
getRunner args RSpec = do
  rspecFile <- hasFile ".rspec"
  return $ case rspecFile of
             True -> Just $ NewTestRunner "rspec" args
             False -> Nothing

getRunner args Minitest = do
  testFile <- hasFile "test"
  return $ case testFile of
             True -> Just $ NewTestRunner "rake" ("test" : args)
             False -> Nothing

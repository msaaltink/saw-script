
module Main where

import qualified Verifier.SAW.TypedAST as SC

import SAWScript.AST
import SAWScript.Compiler

import SAWScript.Token
import SAWScript.Lexer
import SAWScript.Parser

import SAWScript.FindMain
import SAWScript.ResolveSyns
import SAWScript.LiftPoly
import SAWScript.TypeCheck
import SAWScript.ConvertType

import SAWScript.ToSAWCore

import Control.Arrow
import Control.Applicative
import Control.Exception
import Control.Monad
import Data.Maybe
import Data.List
import Test.QuickCheck

import System.IO
import System.Environment
import System.Directory
import System.Posix.Files
import System.FilePath.Posix

main :: IO ()
main = getArgs >>= mapM_ (\f -> readFile f >>= runCompiler (translateFile f))

-- TODO: type check then translate to SAWCore
translateFile :: FilePath -> Compiler String SC.Module
translateFile f s = do
  m <- compileModule f s
  either fail return $ translateModule m

-- | Full compiler pipeline, so far.
compileModule :: FilePath -> Compiler String (Module' PType Type)
compileModule f = formModule f >=> typeModule

-- | Takes unlexed text to Module
formModule :: FilePath -> Compiler String (Module MPType)
formModule f = scan f >=> parseModule >=> findMain mname
  where mname = dropExtension (takeFileName f)

-- | Takes module from untyped to fully typed
typeModule :: Compiler (Module MPType) (Module' PType Type)
typeModule = resolveSyns >=> liftPoly >=> typeCheck >=> convertType

-- | Wrapper around compiler function to format the result or error
runCompiler :: (Show b) => Compiler a b -> a -> IO ()
runCompiler f a = do
  runE (f a)
    (putStrLn . ("Error\n" ++) . indent 2)  -- failure
    (putStrLn . indent 2 . show)            -- success
  putStrLn ""

-- testing external files -----------------------------------------------------

-- | Filters files by whitelisted prefixes. If the filter set is null, allow all files through.
filesToRun :: [String] -> [FilePath] -> [FilePath]
filesToRun run = if null run
  then id
  else filter (or . (isPrefixOf <$> run <*>) . pure . takeBaseName)

-- | Resolve the paths of all SAWScript files in directory
getTestFiles :: FilePath -> IO [FilePath]
getTestFiles dir = do
  allFiles <- map (dir </>) <$> getDirectoryContents dir
  fs <- desiredFiles allFiles
  return fs
  where
  desiredFiles :: [FilePath] -> IO [FilePath]
  desiredFiles = filterM (fmap isRegularFile . getFileStatus) >=>
    return . filter ((== ".saw") . takeExtension)

testAllFiles :: IO ()
testAllFiles = do
  fs <- filesToRun <$> getArgs <*> getTestFiles "../test"
  forM_ fs $ \f -> do
    putStrLn $ replicate 60 '*'
    putStrLn ("Testing file " ++ show f)
    contents <- readFile f
    runCompiler (compileModule f) contents

-- testing pre-parsed modules -------------------------------------------------

{-
-- | A few hand written tests
testAllModules :: IO ()
testAllModules = forM_
  [ ( "m1"       , m1  )
  , ( "m1b"      , m1b )
  , ( "m1c"      , m1c )
  , ( "m2"       , m2  )
  , ( "m2b"      , m2b )
  , ( "m3"       , m3  )
  , ( "m4"       , m4  )
  , ( "m5"       , m5  )
  , ( "m6"       , m6  )
  , ( "inferBit" , inferBit )
  ] $
  (\(lab,mod) -> do
     labelModule lab
     runCompiler typeModule mod)
  where
  labelModule :: String -> IO ()
  labelModule n = putStrLn (n ++ ":")
-}

indent :: Int -> String -> String
indent n = unlines . map (replicate n ' ' ++) . lines


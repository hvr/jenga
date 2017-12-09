{-# LANGUAGE OverloadedStrings #-}

module Jenga.Git.SubModules
  ( GitSubmodule (..)
  , findSubmodules
  ) where

import           Control.Monad.Catch (handleIOError)

import           Data.Char (isSpace)
import qualified Data.List as DL

import           System.Directory (listDirectory, doesDirectoryExist, getCurrentDirectory)
import           System.FilePath ((</>), takeDirectory, takeExtension)


data GitSubmodule = GitSubmodule
  { smDirectory :: FilePath
  , smCabalFile :: FilePath
  }


findSubmodules :: IO [GitSubmodule]
findSubmodules = do
  topdir <- findGitTopLevel
  mapM mkGitSubmodule =<< readSubmodules topdir
  where
    mkGitSubmodule dir = do
      files <- filter isCabalFile <$> listDirectory dir
      case files of
        [x] -> pure $ GitSubmodule dir (dir </> x)
        xs -> error $ "findSubmodules :" ++ show xs

    isCabalFile file =
      takeExtension file == ".cabal"

readSubmodules :: FilePath -> IO [FilePath]
readSubmodules fpath =
  handleIOError handler $ do
    xs <- lines <$> readFile (fpath </> ".gitmodules")
    pure $ map clean $ filter isPathLine xs
  where
    isPathLine xs = DL.isPrefixOf "path" $ dropWhile isSpace xs

    handler :: IOError -> IO [a]
    handler e = print e >> pure []

    clean = dropWhile isSpace . take 1 . dropWhile (/= '-')


findGitTopLevel :: IO FilePath
findGitTopLevel =
  loop =<< getCurrentDirectory
  where
    loop "/" = do error "findGitTopLevel failed"
    loop cur = do
      exists <- doesDirectoryExist $ cur </> ".git"
      if exists
        then pure cur
        else loop (takeDirectory cur)



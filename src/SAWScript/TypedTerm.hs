{- |
Module           : $Header$
Description      :
License          : BSD3
Stability        : provisional
Point-of-contact : huffman
-}
module SAWScript.TypedTerm where

import Data.Map (Map)
import qualified Data.Map as Map

import Cryptol.ModuleSystem.Name (nameIdent)
import qualified Cryptol.TypeCheck.AST as C
import Cryptol.Utils.PP (pretty)

import Verifier.SAW.Cryptol (scCryptolType)
import Verifier.SAW.SharedTerm

-- Typed terms -----------------------------------------------------------------

{- Within SAWScript, we represent an object language term as a SAWCore
shared term paired with a Cryptol type schema. The Cryptol type is
used for type inference/checking of inline Cryptol expressions. -}

data TypedTerm s =
  TypedTerm
  { ttSchema :: C.Schema
  , ttTerm :: SharedTerm s
  }

mkTypedTerm :: SharedContext s -> SharedTerm s -> IO (TypedTerm s)
mkTypedTerm sc trm = do
  ty <- scTypeOf sc trm
  ct <- scCryptolType sc ty
  return $ TypedTerm (C.Forall [] [] ct) trm

-- Typed modules ---------------------------------------------------------------

{- In SAWScript, we can refer to a Cryptol module as a first class
value. These are represented simply as maps from names to typed
terms. -}

data CryptolModule s =
  CryptolModule (Map C.Name C.TySyn) (Map C.Name (TypedTerm s))

showCryptolModule :: CryptolModule s -> String
showCryptolModule (CryptolModule sm tm) =
  unlines $
    (if Map.null sm then [] else
       "Type Synonyms" : "=============" : map showTSyn (Map.elems sm) ++ [""]) ++
    "Symbols" : "=======" : map showBinding (Map.assocs tm)
  where
    showTSyn (C.TySyn name params _props rhs) =
      "    " ++ unwords (pretty (nameIdent name) : map pretty params) ++ " = " ++ pretty rhs
    showBinding (name, TypedTerm schema _) =
      "    " ++ pretty (nameIdent name) ++ " : " ++ pretty schema

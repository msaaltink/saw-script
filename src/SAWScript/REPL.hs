{- |
Module           : $Header$
Description      :
License          : Free for non-commercial use. See LICENSE.
Stability        : provisional
Point-of-contact : huffman
-}
module SAWScript.REPL (run) where

import SAWScript.Options (Options)
import SAWScript.REPL.Logo (displayLogo)
import SAWScript.REPL.Haskeline (repl)

-- | Main function
run :: Options -> IO ()
run opts = do
  displayLogo True
  repl Nothing opts (return ())

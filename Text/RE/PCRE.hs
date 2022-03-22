{-# LANGUAGE FlexibleContexts               #-}
{-# LANGUAGE CPP                            #-}
{-# OPTIONS_GHC -fno-warn-duplicate-exports #-}
#if __GLASGOW_HASKELL__ >= 800
{-# OPTIONS_GHC -fno-warn-redundant-constraints #-}
#endif
{-# OPTIONS_GHC -fno-warn-dodgy-exports         #-}
{-# OPTIONS_GHC -fno-warn-unused-imports        #-}

module Text.RE.PCRE
  (
  -- * Tutorial
  -- $tutorial

  -- * About this Module
  -- $about

  -- * The 'Matches' and 'Match' Operators
    (*=~)
  , (?=~)
  -- * The 'SearchReplace' Operators
  , (*=~/)
  , (?=~/)
  -- * The 'Matches' Type
  , Matches
  , matchesSource
  , allMatches
  , anyMatches
  , countMatches
  , matches
  -- * The 'Match' Type
  , Match
  , matchSource
  , matched
  , matchedText
  -- * The Macros and Parsers
  -- $macros
  , module Text.RE.TestBench.Parsers
  -- * The 'RE' Type
  , RE
  , regexType
  , reOptions
  , reSource
  , reCaptureNames
  , reRegex
  -- * Options
  -- $options
  , SimpleREOptions(..)
  , IsOption(..)
  , REOptions
  , defaultREOptions
  , noPreludeREOptions
  , unpackSimpleREOptions
  -- * Compiling and Escaping REs
  , SearchReplace(..)
  , compileRegex
  , compileRegexWith
  , compileRegexWithOptions
  , compileSearchReplace
  , compileSearchReplaceWith
  , compileSearchReplaceWithOptions
  , escape
  , escapeWith
  , escapeWithOptions
  , escapeREString
  -- * The Classic regex-base Match Operators
  , (=~)
  , (=~~)
  -- * The re Quasi Quoters
  -- $re
  , re
  , reMultilineSensitive
  , reMultilineInsensitive
  , reBlockSensitive
  , reBlockInsensitive
  , reMS
  , reMI
  , reBS
  , reBI
  , re_
  -- * The Ed Quasi Quoters
  -- $ed
  , ed
  , edMultilineSensitive
  , edMultilineInsensitive
  , edBlockSensitive
  , edBlockInsensitive
  , edMS
  , edMI
  , edBS
  , edBI
  , ed_
  -- * The cp Quasi Quoters
  , cp
  -- * RE Macros Standard Environment
  -- $prelude
  , prelude
  , preludeEnv
  , preludeTestsFailing
  , preludeTable
  , preludeSummary
  , preludeSources
  , preludeSource
  -- * IsRegex
  -- $isregex
  , module Text.RE.Tools.IsRegex
  -- * The IsRegex Instances
  -- $instances
  , module Text.RE.PCRE.ByteString
  , module Text.RE.PCRE.ByteString.Lazy
  , module Text.RE.PCRE.Sequence
  , module Text.RE.PCRE.String
  ) where

import           Control.Monad.Fail
import           Text.RE.PCRE.ByteString()
import           Text.RE.PCRE.ByteString.Lazy()
import           Text.RE.PCRE.Sequence()
import           Text.RE.PCRE.String()
import           Text.RE.REOptions
import           Text.RE.Replace
import           Text.RE.TestBench.Parsers
import           Text.RE.Tools.IsRegex
import           Text.RE.ZeInternals
import           Text.RE.ZeInternals.PCRE
import           Text.RE.ZeInternals.SearchReplace.PCRE
import qualified Text.Regex.Base                          as B
import qualified Text.Regex.PCRE                          as PCRE


-- | find all the matches in the argument text; e.g., to count the number
-- of naturals in s:
--
--   @countMatches $ s *=~ [re|[0-9]+|]@
--
(*=~) :: IsRegex RE s
      => s
      -> RE
      -> Matches s
(*=~) bs rex = addCaptureNamesToMatches (reCaptureNames rex) $ matchMany rex bs

-- | find the first match in the argument text; e.g., to test if there
-- is a natural number in the input text:
--
--   @matched $ s ?=~ [re|[0-9]+|]@
--
(?=~) :: IsRegex RE s
      => s
      -> RE
      -> Match s
(?=~) bs rex = addCaptureNamesToMatch (reCaptureNames rex) $ matchOnce rex bs

-- | search and replace all matches in the argument text; e.g., this section
-- will convert every YYYY-MM-DD format date in its argument text into a
-- DD\/MM\/YYYY date:
--
--   @(*=~\/ [ed|${y}([0-9]{4})-0*${m}([0-9]{2})-0*${d}([0-9]{2})\/\/\/${d}\/${m}\/${y}|])@
--
(*=~/) :: IsRegex RE s => s -> SearchReplace RE s -> s
(*=~/) = flip searchReplaceAll

-- | search and replace the first occurrence only (if any) in the input text
-- e.g., to prefix the first string of four hex digits in the imput text,
-- if any, with @0x@:
--
--  @(?=~\/ [ed|[0-9A-Fa-f]{4}\/\/\/0x$0|])
--
(?=~/) :: IsRegex RE s => s -> SearchReplace RE s -> s
(?=~/) = flip searchReplaceFirst

-- | the regex-base polymorphic match operator
(=~) :: ( B.RegexContext PCRE.Regex s a
        , B.RegexMaker   PCRE.Regex PCRE.CompOption PCRE.ExecOption s
        )
     => s
     -> RE
     -> a
(=~) bs rex = B.match (reRegex rex) bs

-- | the regex-base monadic, polymorphic match operator
(=~~) :: ( Monad m, MonadFail m
         , B.RegexContext PCRE.Regex s a
         , B.RegexMaker   PCRE.Regex PCRE.CompOption PCRE.ExecOption s
         )
      => s
      -> RE
      -> m a
(=~~) bs rex = B.matchM (reRegex rex) bs

-- $tutorial
-- We have a regex tutorial at <http://tutorial.regex.uk>.

-- $about
-- This module provides access to the back end through polymorphic functions
-- that operate over all of the String\/Text\/ByteString types supported by the
-- back end. The module also provides all of the specialised back-end functionality
-- that will not be needed by most regex clients. If you don't need this generality
-- then you might want to consider using one of the simpler modules that have been
-- specialised for each of these types:
--
-- * "Text.RE.PCRE.ByteString"
-- * "Text.RE.PCRE.ByteString.Lazy"
-- * "Text.RE.PCRE.Sequence"
-- * "Text.RE.PCRE.String"

-- $macros
-- There are a number of RE macros and corresponding Haskell parsers
-- for parsing the matched text into appropriate Haskell types. See
-- the [Macros Tables](http://regex.uk/macros) for details.

-- $options
-- You can specify different compilation options by appending a
-- to the name of an [re| ... |] or [ed| ... \/\/\/ ... |] quasi quoter
-- to select the corresponding compilation option. For example, the
-- section,
--
--  @(?=~/ [edBlockInsensitive|foo$\/\/\/bar|])@
--
-- will replace a @foo@ suffix of the argument text, of any
-- capitalisation, with a (lower case) @bar@. If you need to specify the
-- options dynamically, use the @[re_| ... |]@ and @[ed_| ... \/\/\/ ... |]@
-- quasi quoters, which generate functions that take an 'IsOption' option
-- (e.g., a 'SimpleReOptions' value) and yields a 'RE' or 'SearchReplace'
-- as appropriate. For example if you have a 'SimpleReOptions' value in
-- @sro@ then
--
--  @(?=~/ [ed_|foo$\/\/\/bar|] sro)@
--
-- will compile the @foo$@ RE according to the value of @sro@. For more
-- on specifying RE options see "Text.RE.REOptions".

-- $re
-- The @[re|.*|]@ quasi quoters, with variants for specifying different
-- options to the RE compiler (see "Text.RE.REOptions"), and the
-- specialised back-end types and functions.

-- $ed
-- The -- | the @[ed| ... \/\/\/ ... |]@ quasi quoters; for example,
--
--  @[ed|${y}([0-9]{4})-0*${m}([0-9]{2})-0*${d}([0-9]{2})\/\/\/${d}\/${m}\/${y}|])@
--
-- represents a @SearchReplace@ that will convert a YYYY-MM-DD format date
-- into a DD\/MM\/YYYY format date.
--
-- The only difference between these quasi quoters is the RE options that are set,
-- using the same conventions as the @[re| ... |]@ quasi quoters.
--

-- $isregex
-- The 'IsRegex' class is used to abstract over the different regex back ends and
-- the text types they work with -- see "Text.RE.Tools.IsRegex" for details.

-- $instances
-- These module exports merely provide the 'IsRegex' instances.

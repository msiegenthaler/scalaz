{-
This belongs in its own library
-}

module Scalac(none,
              source,
              line,
              vars,
              notailcalls,
              jvm15,
              jvm14,
              msil,
              debug,
              nowarn,
              verbose,
              deprecation,
              unchecked,
              classpath,
              sourcepath,
              bootclasspath,
              extdirs,
              Scalac.directory,
              encoding,
              target,
              Scalac.print,
              optimise,
              explaintypes,
              uniqid,
              version,
              help,
              (#),
              scalac,
              scalacd,
              scalac',
              scalacd',
              ScalacDebug,
              ScalacTarget,
              Scalac,
              Scalac',
              (!*!),
              fscalac,
              reset,
              shutdown,
              server,
              flags,
              fast,
              fsc,
              Fsc,
              Fsc',
              fsc') where

import Compile
import System.Cmd
import System.Exit
import System.FilePath
import Data.Char
import Data.List

data ScalacDebug = None | Source | Line | Vars | NoTailCalls
  deriving Eq

none :: ScalacDebug
none = None

source :: ScalacDebug
source = Source

line :: ScalacDebug
line = Line

vars :: ScalacDebug
vars = Vars

notailcalls :: ScalacDebug
notailcalls = NoTailCalls

instance Show ScalacDebug where
  show None = "none"
  show Source = "source"
  show Line = "line"
  show Vars = "vars"
  show NoTailCalls = "notailcalls"

data ScalacTarget = JVM1_5 | JVM1_4 | MSIL
  deriving Eq

jvm15 :: ScalacTarget
jvm15 = JVM1_5

jvm14 :: ScalacTarget
jvm14 = JVM1_4

msil :: ScalacTarget
msil = MSIL

instance Show ScalacTarget where
  show JVM1_5 = "jvm-1.5"
  show JVM1_4 = "jvm-1.4"
  show MSIL = "msil"

-- todo support -X options
data Scalac = Scalac {
  debug :: Maybe ScalacDebug,
  nowarn :: Bool,
  verbose :: Bool,
  deprecation :: Bool,
  unchecked :: Bool,
  classpath :: Maybe [FilePath],
  sourcepath :: Maybe [FilePath],
  bootclasspath :: Maybe [FilePath],
  extdirs :: Maybe [FilePath],
  directory :: Maybe FilePath,
  encoding :: Maybe String,
  target :: Maybe ScalacTarget,
  print :: Bool,
  optimise :: Bool,
  explaintypes :: Bool,
  uniqid :: Bool,
  version :: Bool,
  help :: Bool,
  (#) :: Maybe FilePath
}

scalac :: Scalac
scalac = Scalac Nothing False False False False Nothing Nothing Nothing Nothing Nothing Nothing Nothing False False False False False False Nothing

scalacd :: Scalac
scalacd = scalac {
                   debug = Just vars,
                   verbose = True,
                   deprecation = True,
                   unchecked = True,
                   explaintypes = True
                 }

-- not exported
dscalac :: String -> [String] -> Scalac -> String
dscalac com r (Scalac debug
                      nowarn
                      verbose
                      deprecation
                      unchecked
                      classpath
                      sourcepath
                      bootclasspath
                      extdirs
                      directory
                      encoding
                      target
                      print
                      optimise
                      explaintypes
                      uniqid
                      version
                      help
                      script) = intercalate " " $ filter (not . null) [com,
                                c "g" show debug,
                                b "nowarn" nowarn,
                                b "verbose" verbose,
                                b "deprecation" deprecation,
                                b "unchecked" unchecked,
                                p "classpath" classpath,
                                p "sourcepath" sourcepath,
                                p "bootclasspath" bootclasspath,
                                p "extdirs" extdirs,
                                s "d" id directory,
                                s "encoding" id encoding,
                                s "target" show target,
                                b "print" print,
                                b "optimise" optimise,
                                b "explaintypes" explaintypes,
                                b "uniqid" uniqid,
                                b "version" version,
                                b "help" help,
                                m ((:) '@') script] ++ r

-- not exported
d :: String -> String
d = (:) '-'

-- not exported
b :: String -> Bool -> String
b = b' . d

-- not exported
b' :: [a] -> Bool -> [a]
b' s k = if k then s else []

-- not exported
m :: (k -> [a]) -> Maybe k -> [a]
m = maybe []

-- not exported
c :: String -> (k -> String) -> Maybe k -> String
c = v ':'

-- not exported
s :: String -> (k -> String) -> Maybe k -> String
s = v ' '

-- not exported
v :: Char -> String -> (k -> String) -> Maybe k -> String
v c k s = m (\z -> '-' : k ++ [c] ++ s z)

-- not exported
p :: String -> Maybe [FilePath] -> String
p s = m (\z -> d s ++ ' ' : if null z then "\"\"" else intercalate [searchPathSeparator] (fmap surround z))

-- not exported
surround :: String -> String
surround s = '"' : s ++ ['"']

-- not exported
docompile :: String -> (String -> IO a) -> [String] -> IO ExitCode
docompile z k ps = let v = z ++ ' ' : intercalate " " (fmap surround ps) in do k v >> system v

-- not exported
doscalac :: Scalac -> (String -> IO a) -> [String] -> IO ExitCode
doscalac s = docompile (dscalac "scalac" [] s)

instance Compile Scalac where
  s !!! ps = doscalac s (const $ return ()) ps

newtype Scalac' = Scalac' Scalac

instance Compile Scalac' where
  Scalac' s !!! ps = doscalac s (Prelude.print) ps

scalac' :: Scalac -> Scalac'
scalac' = Scalac'

(!*!) :: (Compile c) => c -> [FilePath] -> IO ExitCode
(!*!) = recurse ".scala"

scalacd' :: Scalac'
scalacd' = scalac' scalacd

data Fsc = Fsc {
  fscalac :: Scalac,
  reset :: Bool,
  shutdown :: Bool,
  server :: Maybe (String, String),
  flags :: [String]
}

fast :: Scalac -> Fsc
fast s = Fsc s False False Nothing []

fsc :: Fsc
fsc = fast scalac

-- not exported
dofsc :: Fsc -> (String -> IO a) -> [String] -> IO ExitCode
dofsc (Fsc fscalac reset shutdown server flags) = docompile (dscalac "fsc" [b "reset" reset, b "shutdown" shutdown, m (uncurry (++)) server, intercalate " " (fmap ("-J" ++) flags)] fscalac)

instance Compile Fsc where
  s !!! ps = dofsc s (const $ return ()) ps

newtype Fsc' = Fsc' Fsc

instance Compile Fsc' where
  Fsc' s !!! ps = dofsc s (Prelude.print) ps

fsc' :: Fsc -> Fsc'
fsc' = Fsc'
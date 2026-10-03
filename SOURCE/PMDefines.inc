{
  Code now assumes at least D2006.  Older compilers will not accept the code

  Conditional defines used by this source code file: Please avoid conflicting
  defines in your environment

  D2009Up    => defined under Delphi2009 and up
  D2010Up    => defined under Delphi2010 and up
  DXEUp      => defined under Delphi XE and up
  DXE2Up    => defined under Delphi XE2 and up
  DXE3Up    => defined under Delphi XE3 and up
  DXE4Up    => defined under Delphi XE4 and up
  PlusMemo   => always defined
  TPlusMemo  => always defined
  PMDEBUG    => used to include debug code.
}

{$IF CompilerVersion >= 18} {$DEFINE D2006Up} {$IFEND}
{$IF CompilerVersion >= 20} {$DEFINE D2009Up} {$IFEND}
{$IF CompilerVersion >= 21} {$DEFINE D2010Up} {$IFEND}
{$IF CompilerVersion >= 22} {$DEFINE DXEUp} {$IFEND}
{$IF CompilerVersion >= 23} {$DEFINE DXE2Up} {$IFEND}
{$IF CompilerVersion >= 24} {$DEFINE DXE3Up} {$IFEND}
{$IF CompilerVersion >= 25} {$DEFINE DXE4Up} {$IFEND}

{$A+} { PlusMemo requires word alignment of data }
{$B-} { not complete boolean evaluation }
{$H+} { long strings }
{$J+} { writeable typed constants }

// These also include equivalent C++ Builder versions
// Delphi 2006: 18.0 (VER180)  (ALSO defined in Delphi 2007)
// Delphi 2007: 18.5 (VER185)
// Delphi 2009: 20.0 (VER200)
// Delphi 2010: 21.0 (VER210)
// Delphi XE: 22.0 (VER220)
// Delphi XE2: 23.0 (VER230)
// Delphi XE3: 24.0 (VER240)
// Delphi XE4: 25.0 (VER250)
// Delphi XE5: 26.0 (VER260)
// Delphi XE6: 27.0 (VER270)
// Delphi XE7: 28.0 (VER280)
// Delphi XE8: 29.0 (VER290)
// Delphi 10 Seattle 30.0 (VER300)
// Delphi 10.1 Berlin 31.0 (VER310)
// Delphi 10.2 Tokyo 32.0 (VER320)
// Delphi 10.3 Rio 33.0 (VER330)
// Delphi 10.4 Sydney 34.0 (VER340)
// Delphi 11 Alexandria: 35.0 (VER350)
// Delphi 12 Athens: 36.0 (VER360)
// Delphi 13 Florence: 37.0 (VER370)

// Compiler defines for LIBSUFFIX
//
// NOTE:  When using AUTO on newer compilers, it uses the package version
// for the suffix, not the compiler version.  So I am doing likewise.
// The package version numbers might look unexpected.

{$IFDEF VER180} {$LIBSUFFIX '100'} {$ENDIF} // Delphi 2006         BSDVER 4.0
{$IFDEF VER185} {$LIBSUFFIX '110'} {$ENDIF} // Delphi 2007         BSDVER 5.0
{$IFDEF VER200} {$LIBSUFFIX '120'} {$ENDIF} // Delphi 2009         BSDVER 6.0
{$IFDEF VER210} {$LIBSUFFIX '140'} {$ENDIF} // Delphi 2010         BSDVER 7.0
{$IFDEF VER220} {$LIBSUFFIX '150'} {$ENDIF} // Delphi XE           BSDVER 8.0
{$IFDEF VER230} {$LIBSUFFIX '160'} {$ENDIF} // Delphi XE2          BSDVER 9.0
{$IFDEF VER240} {$LIBSUFFIX '170'} {$ENDIF} // Delphi XE3          BSDVER 10.0
{$IFDEF VER250} {$LIBSUFFIX '180'} {$ENDIF} // Delphi XE4          BSDVER 11.0
{$IFDEF VER260} {$LIBSUFFIX '190'} {$ENDIF} // Delphi XE5          BSDVER 12.0
{$IFDEF VER270} {$LIBSUFFIX '200'} {$ENDIF} // Delphi XE6          BSDVER 14.0  (13.0 skipped)
{$IFDEF VER280} {$LIBSUFFIX '210'} {$ENDIF} // Delphi XE7          BSDVER 15.0
{$IFDEF VER290} {$LIBSUFFIX '220'} {$ENDIF} // Delphi XE8          BDSVER 16.0
{$IFDEF VER300} {$LIBSUFFIX '230'} {$ENDIF} // Delphi 10 Seattle   BSDVER 17.0
{$IFDEF VER310} {$LIBSUFFIX '240'} {$ENDIF} // Delphi 10.1 Berlin  BSDVER 18.0
{$IFDEF VER320} {$LIBSUFFIX '250'} {$ENDIF} // Delphi 10.2 Tokyo   BSDVER 19.0
{$IFDEF VER330} {$LIBSUFFIX '260'} {$ENDIF} // Delphi 10.3 Rio     BSDVER 20.0

// Not needed from 10.4 Sydney on.  Will use LIBSUFFIX AUTO


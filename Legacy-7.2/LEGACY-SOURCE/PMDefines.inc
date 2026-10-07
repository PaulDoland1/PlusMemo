{ Conditional defines used by this source code file: Please avoid conflicting defines in your environment
  D6New      => defined under D6 and up
  D7New      => defined under D7 and up
  D2009Up    => defined under Delphi2009 and up
  D2010Up    => defined under Delphi2010 and up
  DXEUp      => defined under Delphi XE and up
  DXE2Up    => defined under Delphi XE2 and up
  DXE3Up    => defined under Delphi XE3 and up
  DXE4Up    => defined under Delphi XE4 and up
  PlusMemo   => always defined
  TPlusMemo  => always defined
  PMDEBUG    => used to include debug code. }

{$IFDEF VER140} {$DEFINE D6New} {$ENDIF}
{$IFDEF VER150} {$DEFINE D6New} {$ENDIF}
{$IFDEF VER170} {$DEFINE D6New} {$ENDIF}
{$IFDEF VER180} {$DEFINE D6New} {$ENDIF}

{$IFDEF VER150} {$DEFINE D7New} {$ENDIF}
{$IFDEF VER170} {$DEFINE D7New} {$ENDIF}
{$IFDEF VER180} {$DEFINE D7New} {$ENDIF}
{$IFDEF VER180} {$DEFINE D2006Up} {$ENDIF}

{$IFDEF VER200}
    {$DEFINE D6New}
    {$DEFINE D7New}
    {$DEFINE D2006Up}
    {$DEFINE D2009Up}
{$ENDIF}

{$IFDEF VER210}
    {$DEFINE D6New}
    {$DEFINE D7New}
    {$DEFINE D2006Up}
    {$DEFINE D2009Up}
    {$DEFINE D2010Up}
{$ENDIF}

{$IFDEF VER220}
    {$DEFINE D6New}
    {$DEFINE D7New}
    {$DEFINE D2006Up}
    {$DEFINE D2009Up}
    {$DEFINE D2010Up}
    {$DEFINE DXEUp}
{$ENDIF}

{$IFDEF VER230}
    {$DEFINE D6New}
    {$DEFINE D7New}
    {$DEFINE D2006Up}
    {$DEFINE D2009Up}
    {$DEFINE D2010Up}
    {$DEFINE DXEUp}
    {$DEFINE DXE2Up}
{$ENDIF}

{$IFDEF VER240}
    {$DEFINE D6New}
    {$DEFINE D7New}
    {$DEFINE D2006Up}
    {$DEFINE D2009Up}
    {$DEFINE D2010Up}
    {$DEFINE DXEUp}
    {$DEFINE DXE2Up}
    {$DEFINE DXE3Up}
{$ENDIF}

{$IFDEF VER250}
    {$DEFINE D6New}
    {$DEFINE D7New}
    {$DEFINE D2006Up}
    {$DEFINE D2009Up}
    {$DEFINE D2010Up}
    {$DEFINE DXEUp}
    {$DEFINE DXE2Up}
    {$DEFINE DXE3Up}
    {$DEFINE DXE4Up}
{$ENDIF}

{$IFDEF VER260}
    {$DEFINE D6New}
    {$DEFINE D7New}
    {$DEFINE D2006Up}
    {$DEFINE D2009Up}
    {$DEFINE D2010Up}
    {$DEFINE DXEUp}
    {$DEFINE DXE2Up}
    {$DEFINE DXE3Up}
    {$DEFINE DXE4Up}
    {$DEFINE DXE5Up}
{$ENDIF}

{$IFDEF VER270}
    {$DEFINE D6New}
    {$DEFINE D7New}
    {$DEFINE D2006Up}
    {$DEFINE D2009Up}
    {$DEFINE D2010Up}
    {$DEFINE DXEUp}
    {$DEFINE DXE2Up}
    {$DEFINE DXE3Up}
    {$DEFINE DXE4Up}
    {$DEFINE DXE5Up}
{$ENDIF}

{$IFDEF VER280}
    {$DEFINE D6New}
    {$DEFINE D7New}
    {$DEFINE D2006Up}
    {$DEFINE D2009Up}
    {$DEFINE D2010Up}
    {$DEFINE DXEUp}
    {$DEFINE DXE2Up}
    {$DEFINE DXE3Up}
    {$DEFINE DXE4Up}
    {$DEFINE DXE5Up}
{$ENDIF}

{$IFDEF VER290}
    {$DEFINE D6New}
    {$DEFINE D7New}
    {$DEFINE D2006Up}
    {$DEFINE D2009Up}
    {$DEFINE D2010Up}
    {$DEFINE DXEUp}
    {$DEFINE DXE2Up}
    {$DEFINE DXE3Up}
    {$DEFINE DXE4Up}
    {$DEFINE DXE5Up}
{$ENDIF}
{$IFDEF VER300}
    {$DEFINE D6New}
    {$DEFINE D7New}
    {$DEFINE D2006Up}
    {$DEFINE D2009Up}
    {$DEFINE D2010Up}
    {$DEFINE DXEUp}
    {$DEFINE DXE2Up}
    {$DEFINE DXE3Up}
    {$DEFINE DXE4Up}
    {$DEFINE DXE5Up}
{$ENDIF}
{$IFDEF VER310}
    {$DEFINE D6New}
    {$DEFINE D7New}
    {$DEFINE D2006Up}
    {$DEFINE D2009Up}
    {$DEFINE D2010Up}
    {$DEFINE DXEUp}
    {$DEFINE DXE2Up}
    {$DEFINE DXE3Up}
    {$DEFINE DXE4Up}
    {$DEFINE DXE5Up}
{$ENDIF}
{$IFDEF VER320}
    {$DEFINE D6New}
    {$DEFINE D7New}
    {$DEFINE D2006Up}
    {$DEFINE D2009Up}
    {$DEFINE D2010Up}
    {$DEFINE DXEUp}
    {$DEFINE DXE2Up}
    {$DEFINE DXE3Up}
    {$DEFINE DXE4Up}
    {$DEFINE DXE5Up}
{$ENDIF}
{$IFDEF VER330}
    {$DEFINE D6New}
    {$DEFINE D7New}
    {$DEFINE D2006Up}
    {$DEFINE D2009Up}
    {$DEFINE D2010Up}
    {$DEFINE DXEUp}
    {$DEFINE DXE2Up}
    {$DEFINE DXE3Up}
    {$DEFINE DXE4Up}
    {$DEFINE DXE5Up}
{$ENDIF}
{$A+}  { PlusMemo requires word alignment of data }
{$B-}  { not complete boolean evaluation }
{$H+}  { long strings }
{$J+}  { writeable typed constants }




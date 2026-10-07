unit PlusToFmtReg;

{$I PMDefines.inc}

{$WARN UNSAFE_CAST OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_TYPE OFF}

interface

procedure Register;

implementation

uses
  Classes, PlusMemo, PlusToFormat;

procedure Register;
begin
  RegisterComponents( { UCONVERT } 'PlusMemo' { /UCONVERT } , [TPlusToRTF, TPlusToHtml]);
end;

end.

unit NbHilitReg;

{$I PMDefines.inc}

{$WARN UNSAFE_CAST OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_TYPE OFF}

interface

uses
  Classes, PlusMemo, NbHilit;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents( { UCONVERT } 'PlusMemo' { /UCONVERT } , [TNumberHighlighter]);
end;


end.

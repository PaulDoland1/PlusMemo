unit RegExHilitReg;

{$I PMDefines.inc}

{$WARN UNSAFE_CAST OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_TYPE OFF}

interface

uses
  Classes, PlusMemo, RegExHilit;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents( { UCONVERT } 'PlusMemo' { /UCONVERT } , [TRegExHighlighter])
end;

end.

unit PlusGutReg;

{$I PMDefines.inc}

{$WARN UNSAFE_CAST OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_TYPE OFF}

interface

uses
  Classes, PlusMemo, PlusGutter;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents( { UCONVERT } 'PlusMemo' { /UCONVERT } , [TPlusGutter]);
end;


end.

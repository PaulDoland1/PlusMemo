unit PlusDbReg;

{$I PMDefines.inc}

{$WARN UNSAFE_CAST OFF}
{$WARN UNSAFE_CODE OFF}
{$WARN UNSAFE_TYPE OFF}

interface

uses
  Classes, PlusMemo, Plusdb;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('ECM', [TDBPlusMemo])
end;


end.

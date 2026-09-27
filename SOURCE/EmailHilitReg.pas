unit EmailHilitReg;

{$I PMDefines.inc}

interface

procedure Register;

implementation

uses
  Classes, EmailHilit, ExtHilit, ExtHilitReg, DesignEditors, DesignIntf;

procedure Register;
begin
  RegisterComponents( { UCONVERT } 'PlusMemo' { /UCONVERT } , [TEmailHighlighter]);
  RegisterPropertyEditor(TypeInfo(TExtKeywordList), TEmailHighlighter, 'Keywords', TExtKeywordsProperty);
  RegisterPropertyEditor(TypeInfo(TExtStartStopList), TEmailHighlighter, 'StartStopKeys', TExtStartStopProperty);
end;

end.


unit HtmlHilitReg;

{$I PMDefines.inc}

interface

procedure Register;

implementation

uses Classes, HtmlHighlight, ExtHilit, ExtHilitReg,
  {$IFDEF D6New} DesignEditors, DesignIntf; {$ELSE} DsgnIntf; {$ENDIF}

procedure Register;
begin
  RegisterComponents({UCONVERT}'PlusMemo'{/UCONVERT}, [THtmlHighlighter]);
  RegisterPropertyEditor(TypeInfo(TExtKeywordList), THtmlHighlighter, 'Keywords', TExtKeywordsProperty);
end;

end.


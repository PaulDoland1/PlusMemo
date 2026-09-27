unit HtmlHilitReg;

{$I PMDefines.inc}

interface

procedure Register;

implementation

uses
  Classes, HtmlHighlight, ExtHilit, ExtHilitReg, DesignEditors, DesignIntf;

procedure Register;
begin
  RegisterComponents( { UCONVERT } 'PlusMemo' { /UCONVERT } , [THtmlHighlighter]);
  RegisterPropertyEditor(TypeInfo(TExtKeywordList), THtmlHighlighter, 'Keywords', TExtKeywordsProperty);
end;

end.


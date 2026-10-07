unit SQLHilitReg;

{ © Electro-Concept Mauricie, 2003-2013 }
{ Registration unit for TSQLHighlighter object, used for SQL syntax highlighting
  in a TPlusMemo }

{$I PMDefines.inc}

interface

procedure Register;

implementation

uses Classes, Controls, Dialogs, SQLHilit, PlusMemo, PMSupport, PMemoReg, ExtHilit, PlusKeys, DesignEditors, DesignIntf;

type TSQLKeywordsProperty = class(TKeywordsProperty)
                                 public
                                     procedure Edit; override;
                                 end;

  {$WARN UNSAFE_CAST OFF}
  {$WARN UNSAFE_CODE OFF}

procedure TSQLKeywordsProperty.Edit;
var
  MyHighlight: TSQLHighlighter;
  MyList     : TExtKeywordList;
  tmplist    : TKeywordList;
  i          : Integer;
begin
  MyHighlight:= GetComponent(0) as TSQLHighlighter;
  MyList:= TExtHighlighter(MyHighlight).Keywords;
  tmplist:= TKeywordList.Create;
  tmplist.Assign(MyList);
  if EditKeywordList(tmplist, False, False) then
    begin
      for i:= 0 to tmplist.Count-1 do
        if i<MyList.Count then pKeyInfoLen(MyList.KeyList[i])^.BasicPart:= pKeyInfoLen(tmplist.KeyList[i])^.BasicPart;
      Modified;  
      MyHighlight.ReApplyKeys
    end;
  tmplist.Free
end;


procedure Register;
begin
  RegisterComponents({UCONVERT}'PlusMemo'{/UCONVERT}, [TSQLHighlighter]);
  RegisterPropertyEditor(TypeInfo(TKeywordList), TSQLHighlighter, 'KeywordsOvr', TSQLKeywordsProperty);
end;

function Confirm(Msg: {UCONVERT} string {/UCONVERT}): Boolean;
begin
  Result:= MessageDlg(Msg, mtConfirmation,  [mbOk, mbCancel], 0)=mrOK
end;

begin
  SQLHilit.ConfirmFunc:= Confirm;

end.


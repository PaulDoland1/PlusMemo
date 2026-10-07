unit pmCollapseHandler;

{ © Electro-Concept Mauricie, 2003-2013 }
{ Implements TpmCollapseHandler object, used for rendering collapse bar and sign
  in a TPlusMemo }

{ Note: to install this component on your palette, add this file to your package }
{$I PMDefines.inc}

{$DEFINE pmCollapseHandler}

{$IFDEF D7New}
  {$WARN UNSAFE_CAST OFF}
  {$WARN UNSAFE_CODE OFF}
  {$WARN UNSAFE_TYPE OFF}
{$ENDIF}

interface

uses Classes, Graphics, PMSupport;

type
  TpmCollapseHandler = class(TpmsCollapseHandler, IpmCollapseHandler, IpmsNotify)
    private
      fBarPen: TPen;
      fCollapseSignPen: TPen;
      fMaxLevels: Integer;
      fHint: Boolean;
      fMemoList: TList;
      fNav: TPlusNavigator;
      fMouseDown: Boolean;
      procedure setMaxLevels(const Value: Integer);
      procedure SetBarPen(const Value: TPen);
      procedure SetCollapseSignPen(const Value: TPen);

      //procedure GetLevels(const Par: ParInfo; const Line: LineInfo; var StartLevel, EndLevel, BarLevel: Integer;
      //                    var Collapsed: Boolean);
      procedure InvalidateMemos(Sender: TObject);
      procedure LinkMemo(Sender: TComponent; Attach: Boolean);
      procedure PaintLine(Sender: TComponent; Canvas: pmHDC; XPos, Height: Integer; const par: ParInfo; const line: LineInfo);
      procedure Notify(Sender: TComponent; Events: TpmEvents);

    public
      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;
    published
      property BarPen: TPen read fBarPen write SetBarPen;
      property CollapseSignPen: TPen read fCollapseSignPen write SetCollapseSignPen;
      property HintCollapsedText: Boolean read fHint write fHint default False;
      property MaxLevels: Integer read fMaxLevels write setMaxLevels default 4;
    end;


procedure Register;

implementation

{$R pmCollapseHandler.res}

uses PlusMemo, Windows, Messages, SysUtils, Forms;


{ TpmCollapseHandler }

{$IFDEF pmCollapseHandlerU}
const CollapseCursorResName = 'PMUCOLLAPSECURSOR';
      ExpandCursorResName = 'PMUEXPANDCURSOR';
{$ELSE}
{$IFDEF pmCollapseHandlerA}
const CollapseCursorResName = 'PMACOLLAPSECURSOR';
      ExpandCursorResName = 'PMAEXPANDCURSOR';
{$ELSE}
const CollapseCursorResName = 'PMCOLLAPSECURSOR';
      ExpandCursorResName = 'PMEXPANDCURSOR';
{$ENDIF}
{$ENDIF}

var CollapseCursor: THandle = 0;
    ExpandCursor: THandle = 0;

function GetCollapsedText(Memo: TPlusMemo; Nav: TPlusNavigator): string;
var i: Integer; par: pParInfo;
begin
  Result:= '';
  for i:= Nav.ParNumber + 1 to Memo.Paragraphs.Count-1 do
    begin
      par:= Memo.IParList.Pointers[i];
      if not (pmpHidden in par.ParState) then Break;
      Result:= Result + #13 + par.ParText
    end
end;

constructor TpmCollapseHandler.Create(AOwner: TComponent);
begin
  inherited;
  fMemoList:= TList.Create;
  fMaxLevels:= 4;
  fBarPen:= TPen.Create;
  fBarPen.Color:= $F0CAA6;
  fBarPen.Width:= 7;
  fBarPen.OnChange:= InvalidateMemos;
  fCollapseSignPen:= TPen.Create;
  fCollapseSignPen.OnChange:= InvalidateMemos;
  fNav:= TPlusNavigator.Create(nil);
end;

destructor TpmCollapseHandler.Destroy;
var i: Integer;
begin
  fBarPen.Free;
  fCollapseSignPen.Free;
  fNav.Free;
  for i:= 0 to fMemoList.Count-1 do LinkMemo(TComponent(fMemoList[i]), False);
  fMemoList.Free;
  inherited;
end;

procedure TpmCollapseHandler.InvalidateMemos(Sender: TObject);
var i: Integer;
begin
  for i:= 0 to fMemoList.Count-1 do TPlusMemo(fMemoList[i]).Invalidate
end;

procedure TpmCollapseHandler.LinkMemo(Sender: TComponent;  Attach: Boolean);
var snotify: IpmsNotify; smemo: TPlusMemo; sindex: Integer;
begin
  snotify:= Self;
  sindex:= fMemoList.IndexOf(Sender);
  smemo:= Sender as TPlusMemo;
  if Attach then
    begin
      if sindex<0 then
        begin
          fMemoList.Add(Sender);
          smemo.MsgList.Add(Pointer(snotify))
        end
    end
  else
      if sindex>=0 then
        begin
          fMemoList.Delete(sindex);
          sindex:= smemo.MsgList.IndexOf(Pointer(snotify));
          if sindex>=0 then smemo.MsgList.Items[sindex]:= nil
        end
end;

procedure TpmCollapseHandler.Notify(Sender: TComponent; Events: TpmEvents);
var
  smemo: TPlusMemo;
  x, y: Integer;
  sal, sol, sbl, slevel, sbw, sly, spc2: Integer;
  scl: Boolean;
  scur: Integer;
  newhint: pmNativeString;
  sMsg: Cardinal;

begin
  if csDesigning in ComponentState then Exit;
  smemo:= TPlusMemo(Sender);

  if pmeMessage in Events then
    begin
      sMsg:= smemo.WinMsg.Msg;
      case sMsg of
        WM_LBUTTONDOWN:
          if smemo.MouseNav.fExtra<>0 then
            begin
              sal:= Byte(smemo.MouseNav.Par.BlockState*pmsCBlockLevel);
              if sal<>0 then  // static block
                  if smemo.MouseNav.fExtra>0 then smemo.CollapseBlock(smemo.MouseNav.ParNumber, smemo.MouseNav.fExtra)
                                             else smemo.ExpandBlock(smemo.MouseNav.ParNumber, -smemo.MouseNav.fExtra)
              else
                begin
                  fNav.fPMemo:= Sender;
                  fNav.Assign(smemo.MouseNav);
                  sal:= Abs(smemo.MouseNav.fExtra);
                  fNav.DynNb:= 0;
                  while DynToCollapseLevel(fNav.pDynAttr^)<>sal do
                    begin
                      x:= fNav.DynNb;
                      fNav.DynNb:= x+1;
                      if fNav.DynNb<x+1 then Break  // property DynNb is range limited to the number of dyn codes
                    end;

                  if smemo.MouseNav.fExtra>0 then fNav.Collapse
                                             else fNav.Expand;
                  fNav.Invalidate;
                  fNav.fPMemo:= nil
                end;
              fMouseDown:= True;
              smemo.WinMsg.Result:= 127
            end;

        WM_LBUTTONDBLCLK, WM_LBUTTONUP:
            if smemo.MouseNav.fExtra<>0 then smemo.WinMsg.Result:= 127;


        WM_MOUSEMOVE:
        if fMouseDown then smemo.WinMsg.Result:= 127   // cancel further processing by smemo
      end
    end;  // pmeMessage

  if pmeAfterMessage in Events then
    begin
      sMsg:= smemo.WinMsg.Msg;
      if ((sMsg=WM_MOUSEMOVE) and (not fMouseDown)) or ((sMsg=WM_LBUTTONUP) and fMouseDown) then
        begin
          smemo.MouseNav.fExtra:= 0;
          fMouseDown:= False;
          if not smemo.MouseIsDown then
            begin
              x:= smemo.WinMsg.LParamLo - smemo.LeftOrigin;
              y:= smemo.WinMsg.LParamHi;
              if x<smemo.LeftMargin then
                begin
                  sbw:= fBarPen.Width;
                  if sbw>smemo.LineHeightRT then sbw:= smemo.LineHeightRT;
                  sly:= (y+smemo.TopOrigin) mod smemo.LineHeightRT;
                  spc2:= (smemo.LineHeightRT - sbw) div 2;
                  if (sly>=spc2) and (sly<sbw+spc2) and (x<sbw*MaxLevels) then
                    begin
                      slevel:= x div (sbw + 1);
                      fNav.fPMemo:= smemo;
                      fNav.Assign(smemo.MouseNav);
                      fNav.DisplayY:= y;
                      scl:= fNav.GetCollapseLevels(sal, sol, sbl);
                      if sbl>0 then
                        begin
                          if (slevel=MaxLevels-1) and (slevel<sal) then slevel:= sal;
                          if (slevel>=sal) and (slevel<sbl) then
                            begin
                              if slevel+1<sbl then
                                if fNav.fPar.BlockState*pmsCBlockLevel<>[] then scl:= pmsGetParCollapsed(fNav.fPar^, slevel+1)
                                else
                                  begin
                                    scl:= DynToCollapseLevel(fNav.pDynAttr^)=slevel+1;
                                    while (not scl) and fNav.ForwardToDyn(fNav.fPar.StartOffset+GetParLength(fNav.fPar^)) do
                                      begin
                                        fNav.RightOfDyn;
                                        scl:= DynToCollapseLevel(fNav.pDynAttr^)=slevel+1
                                      end;
                                    if scl then scl:= pmdCollapsed in fNav.pDynAttr.CollpsState
                                  end;

                              if scl then
                                begin
                                  if ExpandCursor=0 then ExpandCursor:= LoadCursor(HInstance, ExpandCursorResName);
                                  scur:= ExpandCursor;
                                  smemo.MouseNav.fExtra:= - (slevel+1);
                                end
                              else
                                begin
                                  if CollapseCursor=0 then CollapseCursor:= LoadCursor(HInstance, CollapseCursorResName);
                                  scur:= CollapseCursor;
                                  smemo.MouseNav.fExtra:= slevel+1
                                end;
                              Windows.SetCursor(scur);
                              smemo.WinMsg.Result:= 127
                            end
                        end;
                      fNav.Invalidate;
                      fNav.fPMemo:= nil
                    end    // x, y in collapse sign area
                end;    // x in left margin

              if fHint then
                begin
                  newhint:= pmNativeString(GetCollapsedText(smemo, smemo.MouseNav));
                  if newhint<>smemo.Hint then
                    begin
                      smemo.Hint:= newhint;
                      Application.CancelHint;
                    end
                end
            end   // not smemo.MouseIsDown
        end    //  MouseMove and not fMouseDown

    end  // pmeAfterMessage

end;

procedure TpmCollapseHandler.PaintLine(Sender: TComponent; Canvas: pmHDC; XPos, Height: Integer;
                                       const par: ParInfo; const line: LineInfo);
var i, x, y, sbarlevel, startlevel, endlevel, sbw2: Integer; sbarcollapsed: Boolean;
    spen: HPen; smode: Integer;
begin
  pmsGetParLevels(Par, Line, startlevel, endlevel, sbarlevel, sbarcollapsed);

  if sbarlevel>0 then
    begin
      smode:= SetROP2(Canvas, R2_MASKPEN);
      spen:= SelectObject(Canvas, fBarPen.Handle);
      for i:= 0 to sbarlevel-1 do
        if i<MaxLevels then
          begin
            x:= i*(fBarPen.Width+1) + fBarPen.Width div 2 - XPos;
            MoveToEx(Canvas, x, 0, nil);
            if i>=endlevel then LineTo(Canvas, x, Height - fBarPen.Width)
                           else LineTo(Canvas, x, Height)
          end;
      SetROP2(Canvas, smode);

      if startlevel<>endlevel then
        begin
          SelectObject(Canvas, fCollapseSignPen.Handle);
          sbw2:= fBarPen.Width;
          if Height<sbw2 then sbw2:= Height;
          y:= (Height - sbw2) div 2;
          for i:= startlevel to endlevel-1 do
            begin
              if i<MaxLevels then x:= i
                             else x:= MaxLevels-1;
              x:= x*(fBarPen.Width+1) + (fBarPen.Width-sbw2) div 2 - XPos;
              Rectangle(Canvas, x, y, x+sbw2, y+sbw2);
              MoveToEx(Canvas, x, y + sbw2 div 2, nil);
              LineTo(Canvas, x + sbw2, y + sbw2 div 2);
              if (i=endlevel-1) and sbarcollapsed then
                begin
                  MoveToEx(Canvas, x + sbw2 div 2, y, nil);
                  LineTo(Canvas, x + sbw2 div 2, y + sbw2)
                end
            end;

          for i:= startlevel-1 downto endlevel do
            begin
              if i<MaxLevels then x:= i
                             else x:= MaxLevels-1;
              x:= x*(fBarPen.Width+1) + (fBarPen.Width-sbw2) div 2 - XPos;
              MoveToEx(Canvas, x, y+sbw2, nil);
              LineTo(Canvas, x + sbw2, y+sbw2)
            end
        end;

      SelectObject(Canvas, spen)
    end
end;

procedure TpmCollapseHandler.SetBarPen(const Value: TPen);
begin
  fBarPen.Assign(Value);
  InvalidateMemos(Self)
end;

procedure TpmCollapseHandler.SetCollapseSignPen(const Value: TPen);
begin
  fCollapseSignPen.Assign(Value);
  InvalidateMemos(Self)
end;

procedure TpmCollapseHandler.setMaxLevels(const Value: Integer);
begin
  if Value<>fMaxLevels then
    begin
      fMaxLevels := Value;
      InvalidateMemos(Self)
    end
end;

procedure Register;
begin
  RegisterComponents({UCONVERT}'PlusMemo'{/UCONVERT}, [TpmCollapseHandler]);
end;

end.

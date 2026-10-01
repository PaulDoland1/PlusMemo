unit PlusGutter;

{ PlusGutter 6.10
  Added AutoWidth property
  © Electro-Concept Mauricie, 1998-2014

  TPlusGutter is a graphic control that can be placed next to a TPlusMemo component and be linked to it.
  It then automatically shows line numbers at the appropriate vertical position.

  It also allows to bookmark lines using Shift+Ctrl+0..9, and to jump from any point to one of
  the bookmarks using Ctrl+0..9. It also shows (optionally) line numbers or paragraph numbers. }

{$I PMDefines.inc}

{$DEFINE PlusGutter}

{$R PlusGutter.res}

{$IFDEF D7New}
  {$WARN UNSAFE_CAST OFF}
  {$WARN UNSAFE_CODE OFF}
  {$WARN UNSAFE_TYPE OFF}
{$ENDIF}

{$DEFINE PLUSGUTTER}

interface

uses
  Messages, Classes, Controls, Graphics, PlusMemo7, PMSupport;

type
  TBookmarkRange = 0..9;

  TpgDrawItemEvent = procedure (Sender: TObject; LineIndex: Integer; { UCONVERT } var Text: string { /UCONVERT } ; var Graphic: TGraphic) of object;
  TpgBookmarkEvent = procedure (Sender: TObject; BookmarkIndex: TBookmarkRange; Navigator: TPlusNavigator;
    var Accept: Boolean) of object;

  TPlusGutter = class(TGraphicControl, IpmsNotify)
  private
    { Fields corresponding to public or published properties }
    fAlignment: TAlignment;
    fAutoWidth: Boolean; // v6.4
    fPlusMemo: TPlusMemo;
    fLineNumbers: Boolean;
    fBookmarks: Boolean;
    fParNumbers: Boolean;
    fIgnoreLast: Boolean;
    fKeepBookmarks: Boolean;
    fRightBorder: Boolean;
    fMouseMemoLine: Integer; // v6.3
    fOnDrawItem: TpgDrawItemEvent;
    fOnSetBookmark, fOnClearBookmark: TpgBookmarkEvent;

    // Private working fields
    fFontWidth: Integer; // v6.4

    { Property access methods }
    procedure SetAlignment(al: TAlignment);
    procedure SetLineNumbers(ln: Boolean);
    procedure SetPlusMemo(Value: TPlusMemo);
    procedure setParNumbers(const Value: Boolean);
    function getBookmarks(BookmarkIndex: TBookmarkRange): Integer;
    function getBookmarkList(BookmarkIndex: TBookmarkRange): TPlusNavigator;
    procedure setIgnoreLast(const Value: Boolean);
    procedure setKeepBookmarks(Value: Boolean);
    procedure setRightBorder(Value: Boolean);
    procedure setOnDrawItem(const Value: TpgDrawItemEvent);
    procedure setAutoWidth(Value: Boolean);

    { Event handler for bookmark navigators OnFree }
    procedure BookMarkFree(Sender: TObject);

    { IpmsNotify }
    procedure Notify(Sender: TComponent; Events: TpmEvents);

  protected
    { these fields put in protected part to support for descendant classes that
      provide their own painting code or other effects }

    { last saved values from PlusMemo we are attached }
    fTopY: Integer;
    fLineCount: Integer;
    fParCount: Integer;
    fWordWrap: Boolean;
    fBookmarkValues: array[TBookmarkRange] of Integer;

    { internal working fields }
    fTrackNav: TPlusNavigator;
    fBookmarkList: array[TBookmarkRange] of TPlusNavigator;

    // Overriden protected methods
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

    procedure MemoWndProc(var Msg: TMessage);
    procedure Scroll(Sender: TObject);
    procedure GetFontWidth;
    procedure SetWidth;

  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    function    BookmarkLine(ALine: Integer; BookmarkIndex: TBookmarkRange): Boolean; virtual;
    procedure   BookmarkPos(Pos: Integer; BookmarkIndex: TBookmarkRange); virtual;
    procedure   ClearBookmarks;
    procedure   JumpToBookmark(BookmarkIndex: TBookmarkRange);

    function GetBookmarkFromLine(ALine: Integer): SmallInt;
    property BookmarksArray[BookmarkIndex: TBookmarkRange]: Integer read getBookmarks;
    property BookmarkList[BookmarkIndex: TBookmarkRange]: TPlusNavigator read getBookmarkList;
    property MouseMemoLine: Integer read fMouseMemoLine;

  published
    { Genuine TPlusGutter properties }
    property Alignment: TAlignment read fAlignment write SetAlignment default taCenter;
    property AutoWidth: Boolean read fAutoWidth write setAutoWidth default False; // v6.4
    property Bookmarks: Boolean read FBookmarks write FBookmarks default True;
    property IgnoreLastLineIfEmpty: Boolean read fIgnoreLast write setIgnoreLast;
    property KeepBookmarks: Boolean read fKeepBookmarks write setKeepBookmarks default True;
    property LineNumbers: Boolean read fLineNumbers write SetLineNumbers default True;
    property ParagraphNumbers: Boolean read fParNumbers write setParNumbers default False;
    property PlusMemo: TPlusMemo read FPlusMemo write SetPlusMemo;
    property RightBorder: Boolean read fRightBorder write setRightBorder default True;
    property OnDrawItem: TpgDrawItemEvent read fOnDrawItem write setOnDrawItem;
    property OnSetBookmark: TpgBookmarkEvent read fOnSetBookmark write fOnSetBookmark;
    property OnClearBookmark: TpgBookmarkEvent read fOnClearBookmark write fOnClearBookmark;

    { Exposition from TGraphicControl }
    property DragCursor;
    property BiDiMode;
    property DragKind;
    property ParentBiDiMode;
    property OnEndDock;
    property OnStartDock;
    property Align;
    property Anchors;
    property Color;
    property Constraints;
    property DragMode;
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

procedure Register;

implementation

uses
  Types, Windows, SysUtils, Forms, ImgList;

var gBookmarkIcons: TImageList;

procedure Register;
begin
  RegisterComponents( { UCONVERT } 'PlusMemo' { /UCONVERT } , [TPlusGutter]);
end;

const
  HotKeys: set of AnsiChar = ['0'..'9'];
  IcnHeight = 10;
  IcnWidth = 10;
  BookmarkLimit = High(TBookmarkRange); // Could be changed to a property if a dynamic number is allowed

constructor TPlusGutter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csOpaque];

  { Initialize inherited properties }
  Width := 30;
  Height := 50;

  { Initialize new properties }
  fLineNumbers := True;
  fAlignment := taCenter;
  fBookmarks := True;
  fRightBorder := True;
  fKeepBookmarks := True;

  { Initialize the list of bitmaps }
  if gBookmarkIcons = nil then
  begin
    gBookmarkIcons := TImageList.CreateSize(IcnWidth, IcnHeight);
    gBookmarkIcons.DrawingStyle := dsTransparent;
    gBookmarkIcons.ResInstLoad(HInstance, rtBitmap,
    { UCONVERT }
                                 {$IFDEF PLUSGUTTERU}  'PGU_BOOKMARKICONS1',
                                 {$ELSE}
                                     {$IFDEF PLUSGUTTERA}  'PGA_BOOKMARKICONS1',
                                     {$ELSE} 'PG_BOOKMARKICONS1',
                                     {$ENDIF}
                                 {$ENDIF}
      clWhite)
    { /UCONVERT } ;
  end
end;

destructor TPlusGutter.Destroy;
var i: Integer;
begin
  SetPlusMemo(nil);
  fTrackNav.Free;
  for i := 0 to BookmarkLimit do
    if fBookmarkList[i] <> nil then
      fBookmarkList[i].OnFree := nil;
  inherited Destroy;
end;

procedure TPlusGutter.setAlignment(al: TAlignment);
begin
  if al <> fAlignment then
  begin
    fAlignment := al;
    Invalidate
  end
end;

procedure TPlusGutter.setAutoWidth(Value: Boolean);
begin
  if Value <> fAutoWidth then
  begin
    fAutoWidth := Value;
    if Value and (Parent <> nil) and Parent.HandleAllocated then
    begin
      if fFontWidth = 0 then
        GetFontWidth;
      SetWidth
    end;
  end;
end;

procedure TPlusGutter.setIgnoreLast(const Value: Boolean);
begin
  if Value <> fIgnoreLast then
  begin
    fIgnoreLast := Value;
    Invalidate
  end
end;

procedure TPlusGutter.SetLineNumbers(ln: Boolean);
begin
  if ln <> fLineNumbers then
  begin
    fLineNumbers := ln;
    Invalidate
  end
end;

procedure TPlusGutter.SetPlusMemo(Value: TPlusMemo);
var i: Integer; sif: IpmsNotify;
begin
  if fPlusMemo = Value then
    Exit;

  { Clear the old bookmarks }
  for i := 0 to BookmarkLimit do
    FreeAndNil(fBookmarkList[i]);
  sif := Self;
  if fPlusMemo <> nil then
  begin
    fPlusMemo.MsgList.Remove(Pointer(sif));
    fPlusMemo.NotifyList.Remove(Pointer(sif))
  end;
  fPlusMemo := Value;
  if fPlusMemo <> nil then
  begin
    fPlusMemo.MsgList.Add(Pointer(sif));
    fPlusMemo.NotifyList.Add(Pointer(sif));
    fPlusMemo.FreeNotification(Self);
    if fIgnoreLast then
    begin
      fLineCount := fPlusMemo.Lines.Count;
      fParcount := fPlusMemo.Paragraphs.Count
    end else
    begin
      fLineCount := fPlusMemo.LineCount;
      fParCount := fPlusMemo.ParagraphCount
    end
  end else
  begin
    fLineCount := 0;
    fParCount := 0
  end;
  Invalidate
end;

procedure TPlusGutter.setParNumbers(const Value: Boolean);
begin
  if Value <> fParNumbers then
  begin
    fParNumbers := Value;
    Invalidate
  end
end;

procedure TPlusGutter.Scroll(Sender: TObject);
var currenttopy: LongInt;
  r: TRect;
begin
  if (Parent <> nil) and Parent.HandleAllocated then
  begin
    r := BoundsRect;
    if (fPlusMemo.LineCount <> fLineCount) or (fPlusMemo.ParagraphCount <> fParCount) then
      Invalidate
    else
    begin
      currenttopy := fPlusMemo.TopOrigin;
      ScrollWindow(Parent.Handle, 0, fTopY - currenttopy, @r, @r);
      fTopY := currenttopy
    end
  end
end;

procedure TPlusGutter.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  if Assigned(fPlusMemo) and (fPlusMemo.HandleAllocated) then
    fMouseMemoLine := (fPlusMemo.ScreenToClient(ClientToScreen(Point(0, Y))).Y + fPlusMemo.TopOrigin) div fPlusMemo.LineHeightRT
  else
    fMouseMemoLine := -1;
  inherited
end;

procedure TPlusGutter.Paint;
var
  scanvas: TCanvas; { local Canvas reference }
  clRect: TRect; { local value of clip rectangle }
  sclient: TRect; { local value of ClientRect }
  DrawY: Integer; { Y value where we are drawing }
  DrawLine: Integer; { line index being drawn }
  DrawIndex: Integer; { bookmark index of current line being drawn }
  LHeight: Integer; { local value of line height }
  i: Integer;
  DigitWidth: Integer; { width of a digit, used only if LineNumbers=True or with OnDrawItem }
  CWidth: Integer; { local value of ClientWidth, minus border }
  t: pmNativeString; { temporary string used if LineNumbers = True }
  LeftText: Integer; { left coordinate of text or bookmark icon }
  po: TPoint;
  mt: Integer;
  IconYAdd: Integer; { used in centering the bookmark icon vertically }
  sgraph: TGraphic;

begin
  if fAutoWidth and (fFontWidth = 0) then
  begin
    GetFontWidth;
    SetWidth;
    Exit
  end;

  sclient := ClientRect;
  scanvas := Canvas;
  clRect := scanvas.ClipRect;
  sgraph := nil;
  IntersectRect(clRect, sclient, clRect);

  {$IFDEF PMDEBUG}
  OutputDebugString( { UCONVERT } PChar { /UCONVERT } ('PG: Painting ' + IntToStr(clRect.Left) + ',' + IntToStr(clRect.Top) + ',' +
    IntToStr(clRect.Right) + ',' + IntToStr(clRect.Bottom)));
  {$ENDIF}
  if fRightBorder then
    CWidth := sclient.Right - 2
  else
    CWidth := sclient.Right;

  { Fill with color }
  scanvas.Brush.Color := Color;
  scanvas.Brush.Style := bsSolid;
  scanvas.FillRect(clRect);
  scanvas.Brush.Style := bsClear;

  { Draw the right border, which is 2 pixels wide }
  if clRect.Right > CWidth then
  begin
    scanvas.Pen.Color := clBtnHighlight;
    scanvas.MoveTo(CWidth, clRect.Top);
    scanvas.LineTo(CWidth, clRect.Bottom);
    scanvas.Pen.Color := clBtnShadow;
    scanvas.MoveTo(CWidth + 1, clRect.Top);
    scanvas.LineTo(CWidth + 1, clRect.Bottom);
  end;

  { Draw the bookmarks and line numbers }
  if (fPlusMemo <> nil) and (fPlusMemo.HandleAllocated) then
  begin
    if fTrackNav = nil then
      fTrackNav := TPlusNavigator.Create(nil);
    fTrackNav.fPMemo := fPlusMemo;
    try
      fTrackNav.Assign(fPlusMemo.DisplayStartNav);
      fTopY := fPlusMemo.TopOrigin;
      LHeight := fPlusMemo.LineHeightRT;

      for i := 0 to BookmarkLimit do
        if fBookmarkList[i] <> nil then
          fBookmarkValues[i] := fBookmarkList[i].TrueLineNumber
        else
          fBookmarkValues[i] := -1;

      po := ClientOrigin;
      mt := fPlusMemo.ClientToScreen(Point(0, 0)).Y;
      DrawLine := (po.Y + clRect.Top - mt + FTopY) div lheight;
      if DrawLine < 0 then
        DrawLine := 0;

      fLineCount := fPlusMemo.IParList.fVisibleLineCount;
      fParCount := fPlusMemo.ParagraphCount;
      if fIgnoreLast then
      begin
        Dec(fLineCount, fPlusMemo.LineCount - fPlusMemo.Lines.Count);
        // Lines.Count does not include an empty last line
        fParCount := fPlusMemo.Paragraphs.Count // idem for Paragraphs.Count
        // Note that Lines.Count does not take account of invisible lines
      end;

      fWordWrap := fPlusMemo.WordWrap;

      DigitWidth := 0;
      if LineNumbers or ParagraphNumbers or Assigned(fOnDrawItem) then
      begin
        scanvas.Font := Self.Font;
        SetTextAlign(scanvas.Handle, ta_baseline);
        if Alignment <> taLeftJustify then
          digitwidth := scanvas.TextWidth('0')
        else
          digitwidth := 0;
      end;

      DrawY := DrawLine * LHeight - fTopY + mt - po.Y;
      LeftText := 0;

      IconYAdd := (LHeight - IcnHeight) div 2;
      if IconYAdd + IcnHeight < fPlusMemo.LineBase then
        IconYAdd := fPlusMemo.LineBase - IcnHeight;

      while (DrawY < clRect.Bottom) and (DrawLine < fLineCount) do
      begin
        if Assigned(fOnDrawItem) then
        begin
          fOnDrawItem(Self, DrawLine, t, sgraph);
          case Alignment of
            taLeftJustify: lefttext := 0;
            taRightJustify: lefttext := CWidth - scanvas.TextWidth(t);
            taCenter: lefttext := (CWidth - scanvas.TextWidth(t)) div 2
          end;
          scanvas.TextOut(lefttext, DrawY + fPlusMemo.LineBase, t);
          if sgraph <> nil then
            scanvas.Draw(0, DrawY, sgraph);
        end else
        begin
          DrawIndex := GetBookmarkFromLine(DrawLine);
          if DrawIndex >= 0 then
          begin
            case Alignment of
              taLeftJustify: lefttext := 2;
              taRightJustify: lefttext := CWidth - IcnWidth;
              taCenter: lefttext := (CWidth - IcnWidth) div 2
            end;
            gBookmarkIcons.Draw(scanvas, lefttext, DrawY + iconyadd, DrawIndex)
          end else if LineNumbers or ParagraphNumbers then
          begin
            fTrackNav.VisibleLineNumber := DrawLine;
            if ParagraphNumbers then
              if fTrackNav.ParLine = 0 then
                t := IntToStr(fTrackNav.ParNumber + 1)
              else
                t := ''
            else
              t := IntToStr(fTrackNav.TrueLineNumber + 1);
            if t <> '' then
            begin
              case Alignment of
                taLeftJustify: lefttext := 0;
                taRightJustify: lefttext := CWidth - Length(t) * DigitWidth;
                taCenter: lefttext := (CWidth - Length(t) * DigitWidth) div 2
              end;
              scanvas.TextOut(lefttext, DrawY + fPlusMemo.LineBase, t)
            end
          end
        end;

        Inc(DrawLine);
        Inc(DrawY, LHeight)
      end;
    // while DrawLine<FLineCount
    finally
      fTrackNav.fPMemo := nil
    end
  end;
  // FPlusMemo <> nil
end; // TPlusGutter.Paint

procedure TPlusGutter.Notification(AComponent: TComponent; Operation: TOperation);
var i: Integer;
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (Assigned(FPlusMemo)) and (AComponent = FPlusMemo) then
  begin
    for i := 0 to BookmarkLimit do
      fBookmarkList[i] := nil;
    fPlusMemo := nil;
  end
end;

procedure TPlusGutter.MemoWndProc(var Msg: TMessage);
var
  ss: TShiftState;
  ch: AnsiChar;
  ln: Integer;
begin
  case Msg.Msg of
    WM_KEYDOWN: // check for trying to reach or set a bookmark
      begin
        ss := KeyDataToShiftState(Msg.LParam);
        ch := AnsiChar(Msg.WParam);

        if fBookmarks and (ch in HotKeys) then
        begin
          ln := Integer(Msg.WParam) - Ord('0');
          // mjf: Moved here as a minor performance change.  Added Integer cast.
          if (ssShift in ss) and (ssCtrl in ss) and not(ssAlt in ss) then
          begin
            // set or clear a bookmark
            if GetBookmarkFromLine(fPlusMemo.SelLine) = ln then
              BookmarkLine(fPlusMemo.SelLine, ln)  // this clears it
            else
              BookmarkPos(fPlusMemo.SelStart, ln);
          end else if (ssCtrl in ss) and (ss * [ssShift, ssAlt] = []) and (fBookmarkList[ln] <> nil) then
          begin
            // jump to bookmark
            fPlusMemo.SelStart := FBookmarkList[ln].Pos;
            fPlusMemo.ScrollInView;
          end
        end
      end;

    WM_PAINT: if (fWordWrap <> fPlusMemo.WordWrap) or (fTopY <> fPlusMemo.TopOrigin) or
      (fLineCount <> fPlusMemo.IParList.fVisibleLineCount) then
        Invalidate
  end;
  // case Msg
end; // MemoWndProc

function TPlusGutter.BookmarkLine(ALine: LongInt; BookmarkIndex: TBookmarkRange): Boolean;
var CurrentBIndex: Integer; saccept: Boolean;
begin
  Result := False;
  // Return False if the line is already bookmarked
  CurrentBIndex := GetBookmarkFromLine(ALine);
  saccept := True;

  if CurrentBIndex = BookmarkIndex then
  begin
    // Calling BookmarkLine on a line with already the same bookmark index: remove the bookmark
    if Assigned(fOnClearBookmark) then
      fOnClearBookmark(Self, BookmarkIndex, fBookmarkList[BookmarkIndex], saccept);
    if not saccept then
      Exit;
    Result := True;
    fBookmarkList[BookmarkIndex].Free;
    fBookmarkList[BookmarkIndex] := nil
  end else if CurrentBIndex < 0 then
  begin
    // Add the bookmark
    fBookmarkList[BookmarkIndex] := TPlusNavigator.Create(fPlusMemo);
    fBookmarkList[BookmarkIndex].TrueLineNumber := ALine;
    if Assigned(fOnSetBookmark) then
      fOnSetBookmark(Self, BookmarkIndex, fBookmarkList[BookmarkIndex], saccept);
    if saccept then
    begin
      fBookmarkList[BookmarkIndex].AdjustRight := fBookmarkList[BookmarkIndex].ParOffset = 0;
      if not KeepBookmarks then
      begin
        fBookmarkList[BookmarkIndex].FreeOnDelete := True;
        fBookmarkList[BookmarkIndex].OnFree := BookmarkFree
      end;
      Result := True
    end else
      FreeAndNil(fBookmarkList[BookmarkIndex])
  end;

  if Result then
    Invalidate
end;

procedure TPlusGutter.BookmarkPos(Pos: Integer; BookmarkIndex: TBookmarkRange);
var sbm: TPlusNavigator; saccept: Boolean;
begin
  sbm := fBookmarkList[BookmarkIndex];
  if sbm = nil then
  begin
    saccept := True;
    sbm := TPlusNavigator.Create(fPlusMemo);
    sbm.Pos := Pos;
    if Assigned(fOnSetBookmark) then
      fOnSetBookmark(Self, BookmarkIndex, sbm, saccept);
    if saccept then
    begin
      fBookmarkList[BookmarkIndex] := sbm;
      if not KeepBookmarks then
      begin
        sbm.FreeOnDelete := True;
        sbm.OnFree := BookmarkFree
      end
    end else
    begin
      sbm.Free;
      Exit
    end
  end;

  sbm.Pos := Pos;
  if not KeepBookmarks then
    sbm.Col := 0;
  // place it at beginning of line
  sbm.AdjustRight := sbm.ParOffset = 0;
  Invalidate
end;

function TPlusGutter.GetBookmarkFromLine(ALine: LongInt): SmallInt;
var i: Integer;
begin
  { Iterate through bookmarks and return the bookmark number for ALine or -1 }
  Result := -1;
  for i := 0 to BookmarkLimit do
    if (fBookmarkList[i] <> nil) and (fBookmarkList[i].VisibleLineNumber = ALine) then
    begin
      Result := i;
      Break
    end;
end;

function TPlusGutter.getBookmarks(BookmarkIndex: TBookmarkRange): LongInt;
begin
  if Assigned(fBookmarkList[BookmarkIndex]) then
    Result := fBookmarkList[BookmarkIndex].TrueLineNumber
  else
    Result := -1
end;

procedure TPlusGutter.GetFontWidth;
begin
  fFontWidth := Canvas.TextWidth('0')
end;

function TPlusGutter.getBookmarkList(BookmarkIndex: TBookmarkRange): TPlusNavigator;
begin
  Result := fBookmarkList[BookmarkIndex]
end;

procedure TPlusGutter.ClearBookmarks;
var i: Integer;
begin
  for i := 0 to BookmarkLimit do
    if BookmarksArray[i] >= 0 then
      BookmarkLine(BookmarksArray[i], i)
end;

procedure TPlusGutter.CMFontChanged(var Message: TMessage);
begin
  if (Parent <> nil) and Parent.HandleAllocated then
  begin
    GetFontWidth;
    if fAutoWidth then
      SetWidth
  end else
    fFontWidth := 0;

  inherited
end;

procedure TPlusGutter.JumpToBookmark(BookmarkIndex: TBookmarkRange);
begin
  if Assigned(fPlusMemo) and (BookmarksArray[BookmarkIndex] >= 0) then
  begin
    fPlusMemo.SelStart := fBookmarkList[BookmarkIndex].Pos;
    fPlusMemo.ScrollInView
  end
end;

procedure TPlusGutter.Notify(Sender: TComponent; Events: TpmEvents);
  function SameBookmarks: Boolean;
  var i: Integer;
  begin
    Result := True;
    for i := 0 to BookmarkLimit do
      if (fBookmarkList[i] <> nil) and (fBookmarkValues[i] <> fBookmarkList[i].TrueLineNumber) then
      begin
        Result := False;
        Exit
      end
  end;

var ln, slinecount, oldlinecount, sparcount: Integer;
begin
  if pmeAfterMessage in Events then
    MemoWndProc(fPlusMemo.WinMsg);
  if pmeFontChanged in Events then
    Invalidate;
  // to replace lineheight and other internal values
  if pmeChange in Events then
  begin
    for ln := 0 to BookmarkLimit do
      if fBookmarkList[ln] <> nil then
      begin
        fBookmarkList[ln].AdjustRight := fBookmarkList[ln].ParOffset = 0;
        if not fKeepBookmarks then
          fBookmarkList[ln].Col := 0 // reset it to start of line
      end;

    slinecount := fPlusMemo.IParList.fVisibleLineCount;
    //LineCount;
    sparcount := fPlusMemo.ParagraphCount;
    if fIgnoreLast then
    begin
      Dec(slinecount, fPlusMemo.LineCount - fPlusMemo.Lines.Count);
      sparcount := fPlusMemo.Paragraphs.Count
    end;

    if (slinecount <> fLineCount) or (sparcount <> fParCount) or (not SameBookmarks) then
    begin
      oldlinecount := fLineCount;
      fLineCount := slinecount;
      fParCount := sparcount;
      if (Parent <> nil) and Parent.HandleAllocated then
        if (oldlinecount <> fLineCount) and fAutoWidth then
          SetWidth
        else
          Invalidate
    end
  end;
  if pmeNewContent in Events then
    ClearBookmarks;

  if pmeVScroll in Events then
    Scroll(Self)
end;

procedure TPlusGutter.setOnDrawItem(const Value: TpgDrawItemEvent);
begin
  fOnDrawItem := Value;
  if Assigned(fPlusMemo) then
    Invalidate
end;

procedure TPlusGutter.setKeepBookmarks(Value: Boolean);
var i: Integer;
begin
  if Value <> fKeepBookmarks then
  begin
    fKeepBookmarks := Value;
    for i := 0 to BookmarkLimit do
      if fBookmarkList[i] <> nil then
      begin
        fBookmarkList[i].FreeOnDelete := not Value;
        if not Value then
        begin
          fBookmarkList[i].Col := 0;
          // adjust it to start of line
          fBookmarkList[i].OnFree := BookmarkFree
        end else
          fBookmarkList[i].OnFree := nil
      end
  end
end;

procedure TPlusGutter.setRightBorder(Value: Boolean);
begin
  if Value <> fRightBorder then
  begin
    fRightBorder := Value;
    Invalidate
  end
end;

procedure TPlusGutter.SetWidth;
var ncars: Integer;
begin
  if fLineCount < 98 then
    ncars := 2
  else if fLineCount < 990 then
    ncars := 3
  else if fLineCount < 9950 then
    ncars := 4
  else if fLineCount < 99950 then
    ncars := 5
  else if fLineCount < 999950 then
    ncars := 6
  else
    ncars := 7;
  Width := (ncars + 1) * fFontWidth + 3
end;

{ Event handler for bookmark navigators OnFree }

procedure TPlusGutter.BookMarkFree(Sender: TObject);
var i: Integer;
begin
  for i := 0 to BookmarkLimit do
    if fBookmarkList[i] = Sender then
    begin
      fBookmarkList[i] := nil;
      Break
    end
end;

initialization
gBookmarkIcons := nil;

finalization
FreeAndNil(gBookmarkIcons);

end.

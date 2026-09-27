unit PlusMemo;
{ PlusMemo version 7.5
{ © Electro-Concept Mauricie, 1997-2026 }

{ This is the main source file for the TPlusMemo component.  Other complement source files are
      pmSupport.pas  =>  contains support objects, routines and types
      pmemoreg.pas =>  used only for design time installation
}

{$I PMDefines.inc}

{ Conditional defines used by this source code file: Please avoid conflicting defines in your environment
  PlusMemo   => always defined
  TPLUSMEMO  => always defined
  PMDEBUG    => used to include debug code. }

{$DEFINE PlusMemo}
{$DEFINE TPLUSMEMO}

{$IFDEF TPLUSMEMOU}
  {$DEFINE PM_IMEMESSAGES}
{$ENDIF}
{$IFDEF D2009Up}
  {$DEFINE PM_IMEMESSAGES}
{$ENDIF}

{$IFDEF D7New}
  {$WARN UNSAFE_CAST OFF}
  {$WARN UNSAFE_CODE OFF}
  {$WARN UNSAFE_TYPE OFF}
{$ENDIF}

{$IFNDEF PMDEBUG}
  {$R-}
  {$Q-}
{$ENDIF}
{$T-} { not typed address operator }

{$IFDEF BCB}  {$OBJEXPORTALL On}  {$ENDIF}

interface

uses
  SysUtils, Types, Windows, Graphics, Controls, Classes, Forms,
  Messages, Menus, StdCtrls, {$IFDEF DXE3Up} System.UITypes, {$ENDIF} PMSupport;

const
  ctrlBold = #2; ctrlItalic = #1;
  ctrlUnderline = #21; ctrlHighlight = #3;
  ctrlAltFont = #4; //ctrlPerf      = #0;  { normally #20 as a page break }

  CtrlCodesSet = [ctrlBold, ctrlItalic, ctrlUnderline, ctrlHighlight, ctrlAltFont];

type
  TpmUpdateMode = (umImmediate, umOnNeed);
//   TpmUpdateMode = (umImmediate, umOnNeed, umBackground);  Commenting out umBackground until bugs fixed

  TPlusMemoOption = (pmoKeepColumnPos, pmoPutExtraSpaces,
    pmoWrapCaret, pmoInsertKeyActive,
    pmoWideOverwriteCaret, pmoLargeWordSelect,
    pmoAutoScrollBars, pmoNoDragnDrop,
    pmoAutoIndent, pmoBackIndent,
    pmoWindowsSelColors, pmoFullLineSelect,
    pmoDiscardTrailingSpaces, pmoNoFineScroll,
    pmoNoLineSelection, pmoNoDefaultPopup,
    pmoBlockSelection, pmoAutoLineBreak,
    pmoPlainClipboard, pmoPersistentBlocks,
    pmoNoOverwriteBlocks, pmoSmartTabs, pmoKeepParBackgnd, pmoFixedBackground);

  TPlusMemoOptions = set of TPlusMemoOption;

  TpmNonPrintChar = (pmNPSpace, pmNPTab, pmNPReturn);
  TpmNonPrintChars = set of TpmNonPrintChar;

  TPlusLineBreak = (pbCRLF, pbLFCR, pbCR, pbLF);

  TParseEvent = procedure (Sender: TObject; StartOffset, StopOffset: Integer) of object;

  TContextEvent = procedure(Sender: TObject; Context: Integer; StartOffset, StopOffset: Integer) of object;

  TpmBeforeChangeEvent = procedure(Sender: TObject; var Txt: PChar) of object;

  TPlusMemo = class (TCustomControl, IpmEditAction)
  private
    { fields corresponding to public or published properties }
    fParagraphs: TParagraphsList;
    fPars: TPlusMemoStrings;
    fLines: TStrings;
    fHScrollBar, fVScrollBar: Boolean;
    fUpperCaseType: TpmUpperCase;
    fSelLen: Integer;

    fcp, fDisplayTop: TPlusNavigator;
    fMouseNav: TPlusNavigator;
    fLeftMargin, fRightMargin: Integer;
    fDisplayLeft, fTopOrigin: Integer;
    fTabStops: Integer;
    fAutoLineHeight: Boolean;
    fModified, fReadOnly: Boolean;
    fWantTabs, fWordWrap: Boolean;
    fHideSelection: Boolean;
    fShowEndParSelected: Boolean;
    fEnableHotKeys: Boolean;
    fPassOver, fDisplayOnly: Boolean;
    fAlignment: TAlignment;
    fJustified: Boolean;
    fAltFont: TFont;
    fHTColor, fHBColor: TColor;
    fBorderStyle: TBorderStyle;
    fCaretWidth: Integer;
    fKeywords: TKeywordList;
    fStartStopKeys: TStartStopKeyList;
    fApplyKeyWords,
    fApplyStartStopKeys: Boolean;
    fUpdateMode: TpmUpdateMode;
    fStripStrayCtrlCodes: Boolean;
    fDelimiters: TSysCharSet;
    fEndOfTextPen: TPen;
    fScrollTime: Integer;
    fRightLinePen: TPen;
    fRightLinePos: Integer;
    fSpecUnderlinePen: TPen;
    fOverWrite: Boolean;
    fOptions: TPlusMemoOptions;
    fFixedBMPBackground: Boolean; // Computed when setting Options and Background
    fUndoLevel, fUndoMaxLevel: Integer;
    fUndoList: TList; // List of pointers to TUndoRecord
    fUndoMaxSpace: LongInt;
    fNull: Char;
    fHighlighter: TPlusHighlighter;
    fLineBreak: TPlusLineBreak;
    fMouseWheelFact: Integer;
    fBackground: TPicture;
    fSelBackColor, fSelTextColor: TColor;
    fColumnWrap: Integer;
    fSelStart, fSelStop: TPlusNavigator;
    fLineHeight: Integer;
    fLineBase: Integer;
    fProgressInterval: Cardinal;
    fShowNonPrintChars: TpmNonPrintChars;
    fCollpsHandler: IpmCollapseHandler;
    fCollpsComp: TpmsCollapseHandler;
    fWWChars: string;
    fInternalPopup: TPopupMenu;
    fInternalPopupItems: array of TMenuItem;
    fKeywordsUpperCase: Boolean;
    {$IFDEF D2009Up}
    fEncoding: TEncoding;
    {$ENDIF}

    fOnChange, fOnStyleChange,
    fOnMove, fOnProgress,
    fOnHScroll, fOnVScroll: TNotifyEvent;
    fOnParse: TParseEvent;
    fOnContext: TContextEvent;
    fOnBeforeChange: TpmBeforeChangeEvent;
    fOnAfterMouseDown: TMouseEvent;
    fOnInternalPopup: TNotifyEvent;
    {$IFNDEF D2006Up}
    fOnMouseEnter: TNotifyEvent;
    fOnMouseLeave: TNotifyEvent;
    {$ENDIF}

    { Internal working fields }
    fLineDescent: Integer; { vertical position of descenders in the line }
    fWavyLinePos: Integer; { wavy underline position in line bitmap }
    fWavyLineAmplitude: Integer; { wavy underline amplitude }
    fIndependantCpNav: TPlusNavigator; { navigator used to separate current editing pos from selection
                                                   (pmoPersistentBlocks) }
    fNavigators: TList; { list of TPlusNavigator's attached to me }
    fMaxOneShotChars: Integer;
    fLastScrollTime: Cardinal;
    fInternalScroll: Boolean;

    fDisplayLines: LongInt; { number of lines across the height of the client window }
    fFocused: Boolean; { True when we have focus (necessary in Clx to keep track of changing window) }
    ftmpnav1, ftmpnav2: TPlusNavigator; { temporary usage }
    fformnav1, fformnav2: TPlusNavigator;

    fMouseDownPos: LongInt; { fields related to mouse tracking }
    fMouseWheelAcc: Integer;
    fDragging, fDraggingOutside: Boolean;
    fMouseDown, fDblClick,
    fMouseInContext, fMouseInSel: Boolean;
    fMouseScroll: TMouseScrollType;
    fScrollRate: Integer;

    fStartLineSelection: Integer; { visible line number of line selection range;
                                                  negative value if not in line selection mode }
    fBlockSelection: Boolean; { true if a block is selected or is being selected }
    fBlockStartCol,
    fBlockStopCol: Integer; { column numbers of selected block }
    fBlockOperation: Boolean; { True when the last key down did a block operation }
    fCursor: TCursor;
    fHorzScrollBar, fVertScrollBar: TScrollBar; { used in Clx only }
    fsStyle: TFontStyles; { saved style at caret pos }
    fsPos: Integer; { saved caret position, updated in UpdateCaret }
    fsExtraCols: string; { saved extracol value, updated in UpdateCaret }
    fsSelLenDirty, fsPosDirty: Boolean; { set to True when changing SelLength, tested and resetted in DoSelMove }
    fSelMoveUpdateCount: Integer; { set <> 0 to block OnSelMove events }
    fCaretX, fCaretY: Integer; { caret location on the display }
    fNoCheckFormat: Boolean; { flag for SetSelTextBuf }
    fInSetScroll: Boolean; { flag for SetBounds }
    fSpaceWidth: Integer;
    fVScrollfact, fHScrollFact: Integer;
    fAutoCaretWidth: Boolean;
    fLineBmp: TBitmap;
    fLineWidth: Integer;
    fReceivedKeyUp, fNoPaint: Boolean;
    fInStripCodes: Boolean;
    fTmpLines: TLinesList;
    fCanvas: TCanvas; { if Paint and Reformat should use a different DC }
    fW: Integer; { Client width of this DC }
    fLastProgress: Cardinal; { Tick count of last OnProgress done }
    fLoadStreamSize: Integer; { Set to stream size when doing LoadFromStream }
    fLoadingContent: Boolean;
    fSavingContent: Boolean;

    fRunningSpaceWidth,
    fSpaceKern: Integer;
    fExtraCols: string;
    fXCaretRunningPos: Integer;
    fUndoTotalSize: LongInt;
    fInUndo, fUndoBreak: Boolean;

    fLockedCount: Integer;
    fOldFinalDyn: DynInfoRec;
    fFormatThread: TpmFormatThread;
    fWndProcLevel: Integer; // level of nesting inside WndProc, used in managing destroyed memo list
    {$IFDEF PM_IMEMESSAGES}
    fInComposition: Boolean; // True whenever we are in ime composition mode and the ime window is open
    {$ENDIF}
    { Cached Uppercase text }
    fUpText: PChar;
    fUpParNb: LongInt;
    fUpOffset, fUpLength: Integer;

    { Accessories support }
    fMsgList: TList; // list of IpmsNotify interfaces called within window proc. with pmeMessage event
    fNotifyList: TList; // list of IpmsNotify interfaces called in various conditions

    { property access methods }
    function getCharCount: Integer;
    function getTotalLineCount: Integer;
    function getParBuffers(i: Integer): PChar;
    function getStaticFormat: Boolean;
    function  GetParCount: LongInt;
    function  GetParFromOffset(Pos: LongInt): LongInt;
    procedure setSelLength(l: LongInt);
    function  getSelText: string;
    procedure setSelText(s: string);
    procedure SetSelAttrib(a: Char);
    function  getCurrentStyle: TFontStyles;
    function  getChar(i: LongInt): Char;
    function  getLineString(i: LongInt): string;
    procedure setLines(Value: TStrings);
    function  getParString(i: LongInt): string;
    function  getLinesBuf(i: LongInt): PChar;
    function  getParsBuf(i: LongInt): PChar;
    procedure setParsBuf(i: LongInt; parg: PChar);
    function  getParsOffset(i: LongInt): LongInt;
    procedure setLeftMargin(lm: Integer);
    procedure setRightMargin(rm: Integer);
    procedure setBorderStyle(b: TBorderStyle);
    procedure setTabStops(t: Integer);
    procedure setWordWrap(ww: Boolean);
    procedure setHTColor(c: TColor);
    procedure setHBColor(c: TColor);
    procedure setHideSelection(h: Boolean);
    procedure setfAltFont(f: TFont);
    procedure setSelPar(par: LongInt);
    function  getSelPar: LongInt;
    procedure setSelStart(ss: LongInt);
    procedure setSelLine(line: LongInt);
    function  getSelLine: LongInt;
    procedure setSelCol(col: Integer);
    function  getSelCol: Integer;
    function  getSelStart: LongInt;
    function  getUndoCount: Integer;
    procedure setParString(i: LongInt; const par: string);
    procedure setScrollBars(s: TScrollStyle);
    function  getVersion: { UCONVERT } string { /UCONVERT } ;
    procedure setVersion(const v: { UCONVERT } string { /UCONVERT } );
    procedure setCaretWidth(w: Integer);
    procedure setAlignment(al: TAlignment);
    procedure setJustified(j: Boolean);
    function  getTopLine: LongInt;
    procedure setTopLine(tl: LongInt);
    procedure setDisplayLeft(dl: Integer);
    function  getScrollBars: TScrollStyle;
    procedure setDisplayOnly(d: Boolean);
    procedure setLineHeight(lh: Integer);
    function  getLineHeight: Integer;
    procedure setUpdateMode(um: TpmUpdateMode);
    procedure setDelimiters(const d: TSysCharSet);
    procedure setApplyKeywords(apply: Boolean);
    procedure setApplyStartStopKeys(apply: Boolean);
    procedure setEndOfTextMark(p: TPen);
    procedure setSpecUnderline(p: TPen);
    function  getSeparators: AnsiString;
    procedure setSeparators(const s: AnsiString);
    procedure setOptions(opt: TPlusMemoOptions);
    procedure setOverwrite(ovr: Boolean);
    function  getUndoList(i: Integer): TUndoRecord;
    procedure setUndoMaxLevel(uml: Integer);
    procedure setUndoMaxSpace(ums: LongInt);
    procedure setHighlighter(aHighlighter: TPlusHighlighter);
    function  getCurrentWord: string;
    function  getParBackgnd(i: LongInt): TColor;
    function  getParForegnd(i: LongInt): TColor;
    procedure setParBackgnd(i: LongInt; c: TColor);
    procedure setParForegnd(i: LongInt; c: TColor);
    procedure setTopOrigin(top: LongInt);
    procedure setStaticFormat(ssf: Boolean);
    procedure setBackground(pic: TPicture);
    procedure setSelBackColor(bc: TColor);
    procedure setSelTextColor(tc: TColor);
    procedure setUpperCaseType(ut: TpmUpperCase);
    function GetSelContext: Integer;
    function GetColumnBlockXY: TRect;
    procedure setColumnWrap(cw: Integer);
    procedure setRightLinePen(p: TPen);
    procedure setRightLinePos(pos: Integer);
    function GetTextContent: string;
    procedure setTextContent(const Value: string);
    function GetEditRect: TRect;
    procedure setShowNonPrintChars(Show: TpmNonPrintChars);
    function getParWrapable(i: Integer): Boolean;
    procedure setParWrapable(i: Integer; Wrap: Boolean);
    procedure setCollpsHandler(Handler: TpmsCollapseHandler);
    procedure setWWChars(C: string);
    function getInternalPopup: TPopupMenu;

    { IpmEdit interface (note: CanUndo and CanRedo already present in public part }
    function CanCut: Boolean;
    function CanCopy: Boolean;
    function CanPaste: Boolean;
    function CanSelectAll: Boolean;
    function CanDelete: Boolean;

    { Internal working methods }
    procedure UpdateFontDependantFields;
    function  getFormatCompleted: Integer;
    procedure ETPenChange(Sender: TObject);
    procedure BackgroundChange(Sender: TObject);
    procedure BackgroundFill(dc: pmHDC; const R: TRect; UseBackground, FixedBackground: Boolean; YPos, BgHeight, BgWidth: Integer; BColor: TColor);
    procedure PrepareKeepBlock(var n1, n2: TPlusNavigator; var sBlockExtraCols: TPoint);
    procedure EndKeepBlock(n1, n2: TPlusNavigator; sBlockExtraCols: TPoint);
    function  SmartTabText: string;
    procedure DoSelMove;

    { message handlers }
    procedure PMUpdateBkg(var m: TMessage); message PM_UpdateBkg;

    procedure WMCut(var Message: TMessage); message WM_CUT;
    procedure WMCopy(var Message: TMessage); message WM_COPY;
    procedure WMPaste(var Message: TMessage); message WM_PASTE;
    procedure WMUndo(var Message: TMessage); message WM_UNDO;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMSetFocus(var Message: TMessage); message WM_SETFOCUS;
    procedure WMKillFocus(var Message: TMessage); message WM_KILLFOCUS;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMCtl3Dchanged(var Message: TMessage); message CM_CTL3DCHANGED;
    procedure WMEraseBkgnd(var Message: TMessage); message WM_ERASEBKGND;
    procedure WMSetCursor(var Message: TWMSetCursor); message WM_SETCURSOR;
    procedure WMPaint(var  Message: TMessage); message WM_PAINT;
    procedure WMVSCROLL(var m: TWMScroll); message WM_VSCROLL;
    procedure WMHSCROLL(var m: TWMScroll); message WM_HSCROLL;
    {$IFNDEF D2006Up}
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    {$ENDIF}

    {$IFDEF PM_IMEMESSAGES}
    procedure WMChar(var Message: TWMChar); message WM_CHAR;
    procedure WMImeStartComposition(var Message: TMessage); message WM_IME_STARTCOMPOSITION;
    procedure WMIMEEndComp(var Message: TMessage); message WM_IME_ENDCOMPOSITION;
    procedure SetCompositionWindow(SetPos, SetFont: Boolean);
      {$IFNDEF D2009Up}
    procedure WMImeChar(var Message: TMessage); message WM_IME_CHAR;
    procedure WMGetText(var Message: TMessage); message WM_GETTEXT;
    procedure WMSetText(var Message: TMessage); message WM_SETTEXT;
      {$ENDIF}
    {$ENDIF}

  protected
    { overriden protected methods }
    procedure CreateHandle; override;
    procedure CreateParams(var p: TCreateParams); override;
    procedure DblClick; override;
    procedure DestroyWindowHandle; override;
    function  DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
    procedure FontChanged;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    { UCONVERT }
    procedure KeyPress(var Key: Char); override;
    { /UCONVERT }
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Loaded; override;
    procedure WndProc(var Message: TMessage); override;

    { internal protected methods }
    procedure CleanUp;
    procedure DoNotify(List: TList; Events: TpmEvents);
    procedure Reformat;
    procedure FormatNow(StartPar, StopPar: LongInt; Unconditional, ShowProgress: Boolean);
    procedure ParseStartStopNow(ToReach: LongInt);
    procedure ScrollEvent(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);
    procedure setHScrollParams;
    function setVScrollParams: Boolean; // returns True if client width has changed

    procedure Change; virtual;
    procedure InvalidateLines(start, stop: LongInt; erase: Boolean);
    procedure RemoveUndo(i: Integer);
    procedure UpdateCaret(Recreate: Boolean);
    procedure PlaceCaret;
    procedure SelectWords(ExtendRight: Boolean);

    procedure EndModifications;
    procedure RefreshDisplay;
    function GetCaretWidth: Integer;
    function SelectedBlockText: string;
    procedure CreatePopupMenu;
    procedure PopupClickHandler(Sender: TObject);

  public
    { special support for highlighters and other accessories }
    WinMsg: TMessage;
    LastContext: Integer;
    fMaxLineWidth, fMaxLineNumber: LongInt; { largest line }

    function AttrToExtFontStyles(StaticAttrib: TFontStyles; DynAttrib: Word): TFontStyles;
    function GetUpText(Par: pParInfo; ParNb, Start, Len: Integer): PChar;
    procedure SetupFont(AFont: TFont; style: TFontStyles); virtual;
    property IParList: TParagraphsList read fParagraphs;
    property INavigators: TList read fNavigators;
    property MaxOneShotChars: Integer read fMaxOneShotChars;
    property MsgList: TList read fMsgList;
    property NotifyList: TList read fNotifyList;
    property SpaceWidth: Integer read fSpaceWidth;

    { TControl overrides }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure  SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;

    { TMemo replacements }
    procedure Clear;
    procedure ClearSelection;
    procedure CopyToClipboard;
    procedure CutToClipboard;
    function  GetTextBuf(Buffer: PChar; BufSize: Integer): Integer;
    function  GetTextLen: LongInt;
    function  GetSelTextBuf(Buffer: PChar; BufSize: Integer): Integer;
    procedure PasteFromClipboard;
    procedure SelectAll;
    procedure SetSelTextBuf(t: PChar); virtual;
    procedure SetTextBuf(t: PChar);

    property Modified: Boolean read fModified write fModified;
    property SelStart: LongInt read getSelStart write setSelStart;
    property SelLength: LongInt read fSelLen write setSelLength;
    property SelText: string read getSelText write setSelText;

    { new methods, properties of TPlusMemo }
    procedure BeginUpdate;
    procedure EndUpdate;
    function  CanRedo: Boolean;
    function  CanUndo: Boolean;
    procedure CheckIntegrity;
    procedure ClearStyle(Pos: LongInt);
    procedure ClearStyleRange(FromRange, ToRange: LongInt);
    procedure ClearUndo;
    procedure CollapseAll(CollapseInners: Boolean = True; StaticBlocks: Boolean = True; DynamicBlocks: Boolean = True);
    function  CollapseSel: Boolean;
    function  CollapseBlock(ParNumber: Integer; Level: Integer): Boolean;
    procedure ExpandAll(ExpandInners: Boolean = True; StaticBlocks: Boolean = True; DynamicBlocks: Boolean = True);
    function  ExpandBlock(ParNumber: Integer; Level: Integer): Boolean;
    procedure DoDynParse(StartPar, StopPar: Integer; SectionsOnly: Boolean = True);
    procedure DrawLines(StartLine, StopLine: LongInt; Canvas: TCanvas; Pos: TPoint; VertSpacing: Single);
    function  DynText(Start, Stop: LongInt): string;
    function  ExpandSel: Boolean;
    function  FindTxt(const Text: string; GoForward, MatchCase, WholeWordsOnly, Global: Boolean): Boolean;
    procedure FormatText(Canvas: TCanvas; Width: Integer);
    procedure Finalize;
    function  GetTextPart(Start, Stop: Integer): string;
    function  GetTextPartBuf(Start, Stop: Integer): PChar;
    function  GetBlocksStates(ParNumber: Integer): TBooleanDynArray;
    procedure InsertBlock(const Block: string);
    procedure LoadFromStream(Stream: TStream; Ascii: Boolean = False); virtual;
    procedure MakeCollapsibleBlock(StartPar, StopPar: Integer);
    procedure MakeSelCollapsible;
    procedure MoveCp(Position: Integer);
    procedure ReApplyKeywords;
    procedure RemoveCollapsibleBlock(ParNumber: Integer);
    procedure RemoveSelCollapsible;
    procedure SaveToStream(Stream: TStream; Ascii: Boolean = False); virtual;
    procedure ScrollInView;
    procedure SelectBlock(StartCol, StartLine, StopCol, StopLine: Integer);
    procedure SetBold;
    procedure SetItalic;
    procedure SetUnderline;
    procedure SetHighlight;
    procedure SetAltFont;
    procedure SetDynStyle(Start, Stop: Integer; Style: TFontStyles; ContentDependant: Boolean;
      Context: Integer; Cursor: TCursor; Backgnd, Foregnd: TColor; Collapsible: Boolean); overload;
    procedure SetDynStyle(Start, Stop: TPlusNavigator; Style: TFontStyles; ContentDependant: Boolean;
      Context: Integer; Cursor: TCursor; Backgnd, Foregnd: TColor; Collapsible: Boolean); overload;

    procedure SetDynText(Start, Stop: LongInt; const DText: string);
    procedure SetTopLeft(NewTopOrigin, NewLeftOrigin, ScTime: Integer);
    procedure Redo;
    procedure Undo;
    procedure SaveUndo(Stream: TStream);
    procedure LoadUndo(Stream: TStream);

    property CaretX: Integer read fCaretX;
    property CaretY: Integer read fCaretY;
    property CharCount: Integer read getCharCount;
    property Chars[i: LongInt]: Char read getChar;
    property ColumnBlockSelection: Boolean read fBlockSelection;
    property ColumnBlockXY: TRect read getColumnBlockXY;
    property CurrentPosNav: TPlusNavigator read fcp;
    property CurrentWord: string read getCurrentWord;
    property Delimiters: TSysCharSet read fDelimiters write setDelimiters;
    property DisplayStartNav: TPlusNavigator read fDisplayTop;
    property DraggingSelection: Boolean read fDragging;
    property EditRect: TRect read getEditRect;
    property ExtraCols: string read fExtraCols;
    property FirstVisibleLine: Integer read getTopLine write setTopLine;
    property FormatCompleted: Integer read getFormatCompleted;
    property InternalPopup: TPopupMenu read getInternalPopup;
    property KeywordsUpperCase: Boolean read fKeywordsUpperCase write fKeywordsUpperCase;
    property LeftOrigin: Integer read fDisplayLeft write setDisplayLeft;
    property LineCount: Integer read getTotalLineCount;
    property LineHeightRT: Integer read fLineHeight;
    property LineBase: Integer read fLineBase;
    property LinesArray[i: Integer]: string read getLineString;
    property LinesBuf[i: Integer]: PChar read getLinesBuf;
    property MouseIsDown: Boolean read fMouseDown;
    property MouseNav: TPlusNavigator read fMouseNav;
    property ParagraphCount: Integer read getParCount;
    property Paragraphs: TPlusMemoStrings read fPars;
    property PargrphBuf[i: Integer]: PChar read getParsBuf write setParsBuf;
    property PargrphNumber[Offset: Integer]: Integer read getParFromOffset;
    property PargrphOffset[i: Integer]: LongInt read getParsOffset;
    property ParsArray[i: Integer]: string read getParString write setParString;
    property ParBuffers[i: Integer]: PChar read getParBuffers;
    property ParagraphsBackground[i: Integer]: TColor read getParBackgnd write setParBackgnd;
    property ParagraphsForeground[i: Integer]: TColor read getParForegnd write setParForegnd;
    property ParagraphsWrapable[i: Integer]: Boolean read getParWrapable write setParWrapable;

    property SelContext: Integer read GetSelContext;
    property SelCol: Integer read getSelCol write setSelCol;
    property SelLine: Integer read getSelLine write setSelLine;
    property SelPar: Integer read getSelpar write setSelPar;
    property SelStyle: TFontStyles read getCurrentStyle;
    property SelStartNav: TPlusNavigator read fSelStart;
    property SelStopNav: TPlusNavigator read fSelStop;
    property StripStrayCtrlCodes: Boolean read fStripStrayCtrlCodes write fStripStrayCtrlCodes default True;
    property TopOrigin: Integer read fTopOrigin write setTopOrigin;
    property UndoCount: Integer read getUndoCount;
    property UndoLevel: Integer read fUndoLevel;
    property UndoList[Index: Integer]: TUndoRecord read getUndoList;
    property UndoBreak: Boolean read fUndoBreak write fUndoBreak;
    property Text: string read getTextContent write setTextContent;
    property LoadStreamSize: Integer read fLoadStreamSize;
    {$IFDEF D2009Up}
    property Encoding: TEncoding read fEncoding write fEncoding;
    {$ENDIF}
    property Canvas;

  published
    { TMemo replacements }
    property Alignment: TAlignment read fAlignment write setAlignment;
    property BorderStyle: TBorderStyle read fBorderStyle write setBorderStyle default bsSingle;
    property HideSelection: Boolean read fHideSelection write setHideSelection default True;
    property Lines: TStrings read fLines write setLines;
    property ScrollBars: TScrollStyle read getScrollBars write setScrollBars;
    property WantTabs: Boolean read fWantTabs write fWantTabs default True;
    property WordWrap: Boolean read fWordWrap write setWordWrap default True;

    property OnChange: TNotifyEvent read fOnChange write fOnChange;

    { new properties in TPlusMemo }
    property AltFont: TFont read fAltFont write setfAltFont;
    property ApplyKeyWords: Boolean read fApplyKeyWords write setApplyKeyWords default True;
    property ApplyStartStopKeys: Boolean read fApplyStartStopKeys write setApplyStartStopKeys default True;
    property BackgroundBmp: TPicture read fBackground write setBackground;
    property CaretWidth: Integer read fCaretWidth write setCaretWidth;
    property CollapseHandler: TpmsCollapseHandler read fCollpsComp write setCollpsHandler;
    property ColumnWrap: Integer read fColumnWrap write setColumnWrap;
    property DisplayOnly: Boolean read fDisplayOnly write setDisplayOnly;
    property EnableHotKeys: Boolean read fEnableHotKeys write fEnableHotKeys default True;
    property EndOfTextMark: TPen read fEndOfTextPen write setEndOfTextMark;
    property HighlightBackgnd: TColor read fHBColor write setHBColor default clWindow;
    property HighlightColor: TColor read fHTColor write setHTColor default clRed;
    property Highlighter: TPlusHighlighter read fHighlighter write setHighlighter;
    property Justified: Boolean read fJustified write setJustified;
    property Keywords: TKeywordList read fKeywords write fKeywords;
    property LeftMargin: Integer read fLeftMargin write setLeftMargin default 8;
    property LineBreak: TPlusLineBreak read fLineBreak write fLineBreak default pbCRLF;
    property LineHeight: Integer read getLineHeight write setLineHeight;
    property MouseWheelFactor: Integer read fMouseWheelFact write fMouseWheelFact default - 1;
    property NullReplacement: Char read fNull write fNull default #0;
    property Options: TPlusMemoOptions read fOptions write setOptions;
    property Overwrite: Boolean read fOverwrite write setOverwrite;
    property PassOverCodes: Boolean read fPassOver write fPassOver default True;
    property ProgressInterval: Cardinal read fProgressInterval write fProgressInterval default 300;
    property ReadOnly: Boolean read fReadOnly write fReadOnly default False;
    property RightLinePen: TPen read fRightLinePen write setRightLinePen;
    property RightLinePos: Integer read fRightLinePos write setRightLinePos default 0;
    property RightMargin: Integer read fRightMargin write setRightMargin default 8;
    property ScrollTime: Integer read fScrollTime write fScrollTime default 300;
    property SelBackColor: TColor read fSelBackColor write setSelBackColor default - 1;
    property SelTextColor: TColor read fSelTextColor write setSelTextColor default - 1;
    property Separators: AnsiString read getSeparators write setSeparators;
    property ShowEndParSelected: Boolean read fShowEndParSelected write fShowEndParSelected default True;
    property ShowNonPrintChars: TpmNonPrintChars read fShowNonPrintChars write setShowNonPrintChars default [];
    property SpecUnderline: TPen read fSpecUnderlinePen write setSpecUnderline;
    property StartStopKeys: TStartStopKeyList read fStartStopKeys write fStartStopKeys;
    property StaticFormat: Boolean read getStaticFormat write setStaticFormat default False;
    property TabStops: Integer read fTabStops write setTabStops default 8;
    property UndoMaxSpace: LongInt read fUndoMaxSpace write setUndoMaxSpace default $400000;
    property UndoMaxLevel: Integer read fUndoMaxLevel write setUndoMaxLevel default 65536;
    property UpperCaseType: TpmUpperCase read fUpperCaseType write setUpperCaseType default pmuAscii;
    property UpdateMode: TpmUpdateMode read fUpdateMode write setUpdateMode default umOnNeed;
    property Version: { UCONVERT } string { /UCONVERT } read getVersion write setVersion;
    property WordWrapChars: string read fWWChars write setWWChars;

    { new events in TPlusMemo }
    property OnStyleChange: TNotifyEvent read fOnStyleChange write fOnStyleChange;
    property OnSelMove: TNotifyEvent read fOnMove write fOnMove;
    property OnHScroll: TNotifyEvent read fOnHScroll write fOnHScroll;
    property OnVScroll: TNotifyEvent read fOnVScroll write fOnVScroll;
    property OnProgress: TNotifyEvent read fOnProgress write fOnProgress;
    property OnParse: TParseEvent  read fOnParse write fOnParse;
    property OnContext: TContextEvent read fOnContext write fOnContext;
    property OnBeforeChange: TpmBeforeChangeEvent read fOnBeforeChange write fOnBeforeChange;
    property OnAfterMouseDown: TMouseEvent read fOnAfterMouseDown write fOnAfterMouseDown;
    property OnInternalPopup: TNotifyEvent read fOnInternalPopup write fOnInternalPopup;
    {$IFNDEF D2006Up}
    property OnMouseEnter: TNotifyEvent read fOnMouseEnter write fOnMouseEnter;
    property OnMouseLeave: TNotifyEvent read fOnMouseLeave write fOnMouseLeave;
    {$ENDIF}

    { exposition from TControl and TWinControl }
    property Align;
    property Anchors;
    property Color default clWindow;
    property Constraints;
    property BiDiMode;
    property Ctl3D;
    property DragCursor;
    property DragKind;
    property ParentBiDiMode;
    property ParentCtl3D;
    property OnEndDock;
    property OnStartDock;
    property DragMode;
    property Enabled;
    property Font;
    {$IFDEF TPLUSMEMOU}
    property ImeMode; { specific to TPlusMemoU }
    property ImeName;
    {$ENDIF}
    {$IFDEF D2009Up}
    property ImeMode; { also valid for Delphi 2009 }
    property ImeName;
    {$ENDIF}
    {$IFDEF D2010Up}
    property Touch;
    {$ENDIF}
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDrag;
    property OnContextPopup;
    {$IFDEF D2006Up}
    property OnMouseEnter;
    property OnMouseLeave;
    {$ENDIF}
  end;

const UserUpperCaseProc: TpmUpperCaseProc = nil;

implementation

{$R PM_resources.res}   // The drag-copy and line selection cursors, which are not defined in VCL

uses
  Clipbrd;

const IdSn: AnsiString = { UCONVERT } 'PlusMemo v7.2 KRP0A A24BA0Professional ed.'; { /UCONVERT }

var MemoCount: Integer; { number of TPlusMemo created and still alive }
  PMRightArrowCur: THandle = 0; { Handle of right arrow cursor from PlusMemo.res, loaded when first TPlusMemo created }
  ClipboardBlockFormat: Cardinal; { Clipboard format for blocks, initialized as needed in CopyToClipboard and PasteFrom... }
  gDestroyedMemoList: TList = nil; { List of destroyed memos while inside its WndProc procedure
                                       This list is used to avoid notifications after a TPlusMemo is destroyed
                                       inside one of its own message }

{ type declarations for structures used in Undo buffers }

type OffsetRangeRecord = record Start, Stop, LockCount: Integer end;
  pOffsetRangeRecord = ^OffsetRangeRecord;

const BorlandIDEBlockType = 'Borland IDE Block Type';
  DragCopyCursor = 'PMEMODRAGCOPY';

procedure RegisterCbBlocks;
begin
  if ClipboardBlockFormat = 0 then
    ClipboardBlockFormat := {$IFDEF pmClx} Clipboard. {$ENDIF} RegisterClipboardFormat(BorlandIDEBlockType)
end;

{ *********** TPlusMemo ************** }

{ public methods }

constructor TPlusMemo.Create(AOwner: TComponent); { public methods }
const StartingPar: ParInfo = (ParText: nil; StartOffset: 0; StartLine: 0;
  ParState: [pmpOwnTextBuffer]; BlockState: [];
  ParLength: 0);

begin
  inherited Create(AOwner);

  fMsgList := TList.Create;
  fNotifyList := TList.Create;
  fBackground := TPicture.Create;
  fBackground.OnChange := BackgroundChange;
  fNavigators := TList.Create;
  fDisplayTop := TPlusNavigator.Create(Self);
  fSelStart := TPlusNavigator.Create(Self);
  fSelStop := TPlusNavigator.Create(Self);
  fcp := fSelStart;
  fIndependantCpNav := TPlusNavigator.Create(Self);

  ftmpnav1 := TPlusNavigator.Create(Self);
  ftmpnav2 := TPlusNavigator.Create(Self);
  fformnav1 := TPlusNavigator.Create(Self);
  fformnav2 := TPlusNavigator.Create(Self);
  fMouseNav := TPlusNavigator.Create(Self);

  fUpParNb := -1;

  Inc(MemoCount);
  if MemoCount = 1 then
  begin
    if gDestroyedMemoList = nil then
      gDestroyedMemoList := TList.Create;
  end;

  ControlStyle := [csClickEvents, csCaptureMouse, csDoubleClicks, csReplicatable
                   {$IFDEF D7New}, csNeedsBorderPaint {$ENDIF}];

    if PmRightArrowCur = 0 then
      PmRightArrowCur := LoadCursor(hInstance, 'PMRIGHTARROW');
  if not NewStyleControls then
    ControlStyle := ControlStyle + [csFramed];

  fKeywords := TKeywordList.Create;
  fStartStopKeys := TStartStopKeyList.Create;

  fEndOfTextPen := TPen.Create;
  fEndOfTextPen.Color := clRed;
  fEndOfTextPen.OnChange := ETPenChange;
  fRightLinePen := TPen.Create;
  fRightLinePen.Color := clGray;
  //fRightLinePen.Style:= psDot;  pens have default of psSolid, if set otherwise here, design time psSolid won't apply
  fRightLinePen.OnChange := ETPenChange;
  fSpecUnderlinePen := TPen.Create;
  fSpecUnderlinePen.Color := clRed;
  fSpecUnderlinePen.OnChange := ETPenChange;
  fUndoList := TList.Create;

  { Create a starting paragraph }
  fParagraphs := TParagraphsList.Create;
  fParagraphs.Add(startingpar);
  fParagraphs.fTrueLineCount := 1;
  fParagraphs.fVisibleLineCount := 1;
  fPars := TPlusParaStrings.Create;
  TPlusParaStrings(fPars).Memo := Self;
  fLines := TPlusLinesStrings.Create;
  TPlusLinesStrings(fLines).Memo := Self;
  fTmpLines := TLinesList.Create;

  fDelimiters := [#9, ' ', '.', ',', ';', ':', '=', '<', '>', '$', '%', '&', '/', #13, #10];
  fOptions := [pmoPutExtraSpaces, pmoWideOverwriteCaret, pmoWrapCaret, pmoInsertKeyActive, pmoAutoScrollBars];
  fSelBackColor := clHighlight;
  fSelTextColor := clHighlightText;

  fUpdateMode := umOnNeed;
  fProgressInterval := 300;
  fApplyKeywords := True;
  fApplyStartStopKeys := True;

  fUndoMaxLevel := $10000;
  fUndoMaxSpace := $400000;

  fCaretWidth := 1;
  fAutoLineHeight := True;
  fShowEndParSelected := True;
  fProgressInterval := 300;
  fLeftMargin := 8;
  fRightMargin := 8;
  fBorderStyle := bsSingle;
  fEnableHotKeys := True;
  fCaretWidth := 1;
  fMouseWheelFact := -1;
  fWantTabs := True;
  fWordWrap := True;
  fHTColor := clRed;
  fHBColor := clWindow;
  fHideSelection := True;
  fAltFont := TFont.Create;
  fTabStops := 8;
  fPassOver := True;
  fStripStrayCtrlCodes := True;
  fScrollTime := 300;
  fSpaceWidth := 1;
  fVScrollBar := True;
  fXCaretRunningPos := Low(fXCaretRunningPos);
  // mark as undetermined
  fStartLineSelection := -1;
  // not line selecting
  fHScrollFact := 1;
  fVScrollFact := 1;
  fMaxOneShotChars := 4096;
  Cursor := crIBeam;
  ParentColor := False;
  ParentFont := False;
  Font.Name := 'Arial';
  {$IFDEF pmClx} Font.Weight := fwNormal;
{$ENDIF}
  Color := clWindow;
  Width := 100;
  Height := 60;
  TabStop := true
end;

destructor TPlusMemo.Destroy; { public methods }
var i: Integer;
begin
  if fWndProcLevel > 0 then
    gDestroyedMemoList.Add(Self);
  CollapseHandler := nil;
  if Assigned(fFormatThread) then
    // and not Application.Terminated then
  begin
    fFormatThread.PutToEnd;
    fFormatThread := nil
  end;

  CleanUp;
  fParagraphs.Destroy;
  Dec(MemoCount);

  FreeAndNil(fMsgList);
  // important because inherited Destroy may result in a call to WndProc
  FreeAndNil(fNotifyList);
  FreeAndNil(fUndoList);
  fSelLen := 0;
  // idem
  fKeywords.Free;
  fStartStopKeys.Free;
  fBackground.Free;

  for i := 0 to fNavigators.Count - 1 do
    with TPlusNavigator(fNavigators[i]) do
    begin
      fPMemo := nil;
      Free
    end;

  fNavigators.Free;
  fPars.Free;
  fLines.Free;
  fTmpLines.Free;
  FreeAndNil(fLineBmp);

  fAltFont.Free;
  fEndOfTextPen.Free;
  fRightLinePen.Free;
  fSpecUnderlinePen.Free;

  if fHighlighter <> nil then
  begin
    i := fHighlighter.MemoList.IndexOf(Self);
    if i >= 0 then
      fHighlighter.MemoList.Delete(i)
  end;

  fHorzScrollBar.Free;
  fVertScrollBar.Free;

  inherited Destroy;
end;

procedure TPlusMemo.SetBounds; { public methods }
var sdisplayfilled: Boolean; scheight: Integer;
begin
  if fLineBmp <> nil then
    sdisplayfilled := TopOrigin < fParagraphs.fVisibleLineCount * fLineHeight - EditRect.Bottom + 5
  else
    sdisplayfilled := False;
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  if (fLineBmp <> nil) and (not fInSetScroll) then
  begin
    setHScrollParams;
    SetVScrollParams;
    scheight := EditRect.Bottom;
    if fHScrollBar then
      SetScrollPos(Handle, SB_HORZ, fDisplayLeft div fHScrollFact, True);
    if fVScrollBar then
      SetScrollPos(Handle, SB_VERT, fTopOrigin div fVScrollFact, True);
    if sdisplayfilled and (TopOrigin > fParagraphs.fVisibleLineCount * fLineHeight - scheight + 3) then
      SetTopLeft(pmMaxOf(0, fParagraphs.fVisibleLineCount * fLineHeight - scheight + 3), fDisplayLeft, 0);
  end
end;

procedure TPlusMemo.DoDynParse(StartPar, StopPar: Integer; SectionsOnly: Boolean);
var i: Integer; spar: pParInfo;
begin
  ParseStartStopNow(pmMinOf(StopPar, ParagraphCount));
  if not SectionsOnly then
    for i := pmMaxOf(StartPar, fParagraphs.fUpdateStartPar) to StopPar do
    begin
      spar := fParagraphs.Pointers[i];
      if not(pmpKeywDone in spar.ParState) then
      begin
        fTmpNav1.ParNumber := i;
        fTmpNav2.Assign(fTmpNav1);
        fTmpNav2.ParOffset := GetParLength(spar^);
        ApplyKeywordsListP(fTmpNav1, fTmpNav2);
        fTmpNav1.Invalidate;
        fTmpNav2.Invalidate;
        fTmpNav1.Pos := 0;
        fTmpNav2.Pos := 0
      end;
      Include(spar.ParState, pmpKeywDone)
    end
end;

procedure TPlusMemo.ScrollInView; { public methods }
var newleft, newtop, startp: Integer;
begin
  if (fLockedCount > 0) or (fLineBmp = nil) then
    Exit;
  if not(pmpFormatted in fcp.Par^.ParState) then
    FormatNow(fcp.fParNb, fcp.fParNb, False, False);
  if pmpHidden in fcp.fPar.ParState then
  begin
    BeginUpdate;
    fcp.ExpandAllLevels;
    fParagraphs.CollapseExpandPar(fcp.fParNb, 0, High(Integer), False);
    EndUpdate
  end;

  newleft := fDisplayLeft;

  { check if need to scroll horz. }
  if ((not WordWrap) or (fColumnWrap > 0)) and (not(fAlignment in [taRightJustify, taCenter]) or (fDisplayLeft <> 0)) then
    if fCaretX >= fLineWidth then
    begin
      newLeft := fDisplayLeft + (((fCaretX - fLineWidth) div (5 * fSpaceWidth)) + 1) * 5 * fSpaceWidth;
    end else
    begin
      if fCaretX < 0 then
      begin
        newleft := fDisplayLeft + ((fCaretX div (5 * fSpaceWidth)) - 1) * 5 * fSpaceWidth;
        if newleft < 0 then
          newleft := 0;
      end
    end else
      newLeft := 0;

  { now do the vert. scroll, if needed }
  newtop := fTopOrigin;
  if fCaretY < 0 then
    newtop := fcp.VisibleLineNumber * fLineHeight
  else if fCaretY > EditRect.Bottom - fLineHeight - 3 then
  begin
    // ensure enough lines are formatted starting from top of display
    if (ScrollTime <> 0) and (not fInternalScroll) then
      startp := fDisplayTop.ParNumber
    else
      startp := pmMaxOf(0, fcp.ParNumber - fDisplayLines - 1);
    FormatNow(startp, fcp.ParNumber, False, False);
    if pmoNoFineScroll in Options then
      newtop := pmMaxOf(fcp.VisibleLineNumber - fDisplayLines + 2, 0) * fLineHeight
    else
    begin
      newtop := fcp.VisibleLineNumber * fLineHeight + fLineHeight + 1 - EditRect.Bottom;
      if fcp.VisibleLineNumber = fParagraphs.fVisibleLineCount - 1 then
        Inc(newtop, 2)
    end;
    newtop := pmMinOf(newtop, fcp.VisibleLineNumber * fLineHeight)
  end;

  SetTopLeft(newtop, newleft, ScrollTime)
end; { method ScrollInView }

{ public methods }

function TPlusMemo.GetTextBuf(Buffer: PChar; BufSize: Integer): Integer;
begin
  if fParagraphs.fTextLen + 1 < BufSize then
    Result := fParagraphs.fTextLen
  else
    Result := BufSize - 1;
  ftmpnav1.fPos := 0;
  ftmpnav1.Invalidate;
  ftmpnav1.GetTextBuf(Buffer, Result);
end;

function TPlusMemo.GetTextLen: LongInt;
begin
  Result := CharCount
end;

procedure TPlusMemo.SetTextBuf(t: PChar); { public methods }
begin
  SelectAll;
  SetSelTextBuf(t);
  SelStart := 0;
  if fLockedCount = 0 then
    TopOrigin := 0;
end;

procedure TPlusMemo.SetSelTextBuf(t: PChar); { public methods }
{ All text modifications occurs through this method, except for LoadFromStream }
  procedure AdjustNav(ANav: TPlusNavigator);
  begin
    if ANav.Text = #10 then
      ANav.ParOffset := GetParLength(ANav.fPar^)
  end;

  procedure StripCodes(parnb: Integer);
  var par: pParInfo; part: PChar; j, k, parlen: Integer;
  begin
    par := fParagraphs.Pointers[parnb];
    part := par.ParText;
    parlen := GetParLength(par^);
    j := 0;
    while j < parlen do
      if (part[j] < #26) and (AnsiChar(part[j]) in CtrlCodesSet) then
      begin
        k := j + 1;
        while (k < parlen) and (part[k] < #26) and (AnsiChar(part[k]) in CtrlCodesSet) and (part[k] <> part[j]) do
          Inc(k);
        if (k < parlen) and (part[k] = part[j]) then
          { flush redondant ctrl codes }
        begin
          fInStripCodes := True;
          fNoCheckFormat := True;
          SelStart := par.StartOffset + j;
          SelLength := 1;
          SetSelTextBuf(nil);
          SelStart := par.StartOffset + k - 1;
          SelLength := 1;
          SetSelTextBuf(nil);
          Dec(parlen, 2);
          part := par.ParText;
          fInStripCodes := False;
          fNoCheckFormat := False
        end else
          Inc(j)
      end else
        Inc(j);
  end;

var
  i, nlen, nblen, oldparcount, toffset, loffset, poffset,
  startpos, stoppos, { positions: start of selection, of stop of selection }
  stopp: Integer;
  newundolen: LongInt; { vars used in processing undo }
  newundo: Boolean;
  newundop: PChar;
  oldundop: pOffsetRangeRecord;
  mustparse: Boolean; { whether there is some text to parse for keywords, start-stop keys or simply OnParse event }
  dynstart, { navigator used to find the location of dyn record of start of selection }
  dynstop: TPlusNavigator; { navigator used to find location of dyn record following stop of selection }
  sremoveddyn: Boolean; { whether some DynInfoRec were included in the selection }
  startdynattr: DynInfoRec; { dyn attributes at start of selection }
  foundstop: Boolean; { used in finding the dyn record ending that of start of selection }
  sdorecordundopos: Boolean; { whether to record stop position of undo }
  skcount, sscount: Integer; { used to call Highlighter.FixRange }
begin
  // SetSelTextBuf
  if Assigned(fOnBeforeChange) then
    fOnBeforeChange(Self, t);
  DoNotify(fNotifyList, [pmeBeforeChange]);

  // Adjust selection navigators, which could be positioned in the middle of a CR/LF pair
  AdjustNav(fSelStart);
  AdjustNav(fSelStop);
  if fSelLen < 0 then
    fSelLen := fSelStart.Pos - fSelStop.Pos
  else
    fSelLen := fSelStop.Pos - fSelStart.Pos;

  if (fSelLen = 0) and ((t = nil) or (t^ = #0)) then
    Exit;

  if fBlockSelection then
  begin
    fBlockSelection := False;
    BeginUpdate;
    for i := fSelStart.ParNumber to fSelStop.ParNumber do
    begin
      SelPar := i;
      if fBlockStopCol < fBlockStartCol then
      begin
        nlen := fBlockStopCol;
        nblen := fBlockStartCol
      end else
      begin
        nblen := fBlockStopCol;
        nlen := fBlockStartCol
      end;

      SelCol := ColToOffset(fParagraphs.Pointers[i], nlen, TabStops, StaticFormat);
      SelLength := ColToOffset(fParagraphs.Pointers[i], nblen, TabStops, StaticFormat) - SelCol;
      SetSelTextBuf(nil)
    end;
    EndUpdate;
    if (t = nil) or (t^ = #0) then
      Exit
  end;

  fExtraCols := '';
  fXCaretRunningPos := Low(fXCaretRunningPos);
  fModified := True;

  { set initial values for local stack vars }
  stoppos := fSelStop.Pos;
  startpos := fSelStart.Pos;
  stopp := fSelStop.fParNb;
  fSelStop.RightOfDyn;
  fOldFinalDyn := fSelStop.DynAttr;

  if (fMaxLineNumber >= fSelStart.TrueLineNumber) and (fMaxLineNumber <= fSelStop.TrueLineNumber) then
    fMaxLineNumber := -1;
  { flag as unknown }
  fStartLineSelection := -1;
  { no more line selecting after text change }

  { take care of undo }
  sdorecordundopos := False;
  oldundop := nil;
  if (not fInUndo) and not(ComponentState * [csLoading, csDesigning] <> []) and (fUndoMaxLevel <> 0) then
  begin
    for i := fUndoLevel to fUndoList.Count - 1 do
      RemoveUndo(fUndoLevel);
    if (fSelLen <> 0) or (fUndoLevel = 0) or fUndoBreak then
      newundo := True
    else
    begin
      oldundop := fUndoList[fUndoLevel - 1];
      newundo := (fcp.Pos <> oldundop^.Stop) or (fcp.Pos = oldundop^.Start) or (fLockedCount <> oldundop.LockCount)
    end;

    fUndoBreak := False;
    sdorecordundopos := True;
    if newundo then
    begin
      newundolen := stoppos - startpos + 1 + SizeOf(OffsetRangeRecord);
      newundop := StrAlloc(newundolen);
      GetSelTextBuf(newundop + SizeOf(OffsetRangeRecord), newundolen - SizeOf(OffsetRangeRecord));
      if fUndoLevel >= fUndoList.Count then
      begin
        if fUndoMaxLevel > 0 then
          while fUndoLevel > fUndoMaxLevel do
            RemoveUndo(0);
        fUndoList.Add(newundop)
      end else
      begin
        Dec(fUndoTotalSize, pmStrBufSize(PChar(fUndoList[fUndoLevel])));
        StrDispose(PChar(fUndoList[fUndoLevel]));
        fUndoList[fUndoLevel] := newundop
      end;
      Inc(fUndoTotalSize, newundolen);
      Inc(fUndoLevel);
      oldundop := pOffsetRangeRecord(newundop);
      oldundop^.LockCount := fLockedCount;
      oldundop^.Start := fSelStart.Pos;
      //oldundop^.Stop:= fSelStart.Pos+nblen;    This is done after making content modifications
      if fUndoMaxSpace > 0 then
      begin
        while (fUndoTotalSize > fUndoMaxSpace) and (fUndoLevel < fUndoList.Count) do
          RemoveUndo(fUndoList.Count - 1);
        while (fUndoTotalSize > fUndoMaxSpace) and (fUndoLevel > 0) do
          RemoveUndo(0)
      end;
      if fUndoLevel = 0 then
        sdorecordundopos := False
    end
      //else oldundop^.Stop:= cp+nblen
  end;

  oldparcount := fParagraphs.Count;
  Inc(fLockedCount);
  // avoid dynamic expansion being effective on display
  fParagraphs.InsertBuf(t, fSelStart, fSelStop, pmoDiscardTrailingSpaces in Options, not fNoCheckFormat,
    toffset, loffset, sremoveddyn);
  startpos := fSelStart.fPos;
  // discard trailing spaces may have affected fSelStart
  startdynattr := fSelStart.DynAttr;
  Dec(fLockedCount);
  poffset := fParagraphs.Count - oldparcount;
  if sdorecordundopos then
    oldundop^.Stop := fSelStop.Pos;

  //Ensure first paragraph is marked as not formatted if within BeginUpdate/EndUpdate
  //Otherwise, keep its Formatted state as it is used to avoid formatting longer than necessary
  if fLockedCount > 0 then
    Exclude(fSelStart.fPar^.ParState, pmpFormatted);

  { keep cached uppercase text in sync with the changes }
  if fUpParNb >= fSelStart.fParNb then
  begin
    if fUpParNb > fSelStop.fParNb - poffset then
      Inc(fUpParNb, poffset)
    else
    begin
      StrDispose(fUpText);
      fUpParNb := -1
    end
  end;

  { adjust internally referenced navigators }
  i := 0;
  while i < fNavigators.Count do
  begin
    dynstart := TPlusNavigator(fNavigators[i]);
    if (dynstart <> fSelStart) and (dynstart <> fSelStop) then
    begin
      if dynstart.fPos >= startpos then
        if dynstart.fPos > stoppos then
        begin
          Inc(dynstart.fPos, toffset);
          if dynstart.fPar <> nil then
          begin
            if dynstart.fParNb = stopp then
            begin
              { invalidate it }
              dynstart.fDynNb := -1;
              dynstart.fParLine := -1;
              dynstart.fOffset := dynstart.fPos - dynstart.fPar.StartOffset;
            end;
            Inc(dynstart.fParNb, poffset);
            if poffset <> 0 then
            begin
              dynstart.fPar := fParagraphs.Pointers[dynstart.fParNb];
              if dynstart.fNavLines <> nil then
                dynstart.fNavLines.LLPar := dynstart.fPar
            end
          end
        end else
          // pos>=startpos but <= stoppos
        begin
          if dynstart.AdjustRight then
            if dynstart.FreeOnDelete and (dynstart.fPos < stoppos) then
              FreeAndNil(dynstart)  // Note: this will remove it from fNavigators
            else
              dynstart.Assign(fSelStop)
          else if dynstart.FreeOnDelete and (dynstart.fPos > startpos) then
            FreeAndNil(dynstart)
          else
            dynstart.Assign(fSelStart)
        end;
    end;
    // nav is not fSelStart or fSelStop
    if dynstart <> nil then
      Inc(i)
  end;
  // i loop over navigators

  { now take care of dyn codes }
  { selstart and selstop contain the parse range }
  mustparse := True;
  dynstart := ftmpnav1;
  dynstop := ftmpnav2;
  //fExtraCols:= fSelStop.fOffset;  { used in some highlighters }
  fFormNav1.Assign(fSelStart);
  fFormNav2.Assign(fSelStop);

  if not sremoveddyn then
    { no dyn code has been met in selection }
  begin
    if (startdynattr.DynStyle and $80) <> 0 then
    begin
      if (startdynattr.DynStyle and $40) = 0 then
        mustparse := False
      else
        { content dependant: check if we touched the start key, if so extend the parse range
                                                                           to include it.
                                     check if we touched the stop key, if so extend the parse range;
                                     note: parsing must include the dyn to the right of the
                                           parse range! }
        if startdynattr.Level = -1 then
        begin
          fFormNav1.BackToDyn(0);
          fFormNav2.ForwardToDyn(fParagraphs.fTextLen)
        end else
        begin
          dynstart.Assign(fFormNav1);
          repeat
            with dynstart do
              if BackToDyn(Par^.StartOffset) and (fFormNav1.Pos - Pos <= startdynattr.StartKLen) then
              begin
                fFormNav1.Assign(dynstart);
                fParagraphs.fModStartLine := pmMinOf(fParagraphs.fModStartLine, fFormNav1.TrueLineNumber);
                startdynattr := fFormNav1.DynAttr;
                foundstop := DynToLevel(startdynattr) < 0;
                fParagraphs.fNoCompleteFormat := False
              end else
                foundstop := True
          until foundstop;

          dynstop.Assign(fFormNav2);
          with dynstop do
            if ForwardToDyn(Par^.StartOffset + GetParLength(Par^)) and
              (Pos - fFormNav2.Pos <= fOldFinalDyn.StopKLen) then
            begin
              fFormNav2.Assign(dynstop);
              fOldFinalDyn := fPar^.ParExtra.DynCodes[fDynNb];
              fParagraphs.fNoCompleteFormat := False
            end
        end { content dependant }
    end { selection was inside of dyn }
  end { no dyn code in selection }

  else
  begin
    { there were some dyn codes in the selection: check for start in dyn, stop in dyn }
    fParagraphs.fNoCompleteFormat := False;
    if startdynattr.DynStyle and $80 = $80 then
      if startdynattr.DynStyle and $40 = $40 then
      begin
        { content dependant }
        if startdynattr.Level = -1 then
        begin
          fFormNav1.BackToDyn(0);
          fFormNav2.ForwardToDyn(fParagraphs.fTextLen)
        end else
        begin
          dynstart.Assign(fFormNav1);
          repeat
            with dynstart do
              if BackToDyn(Par^.StartOffset) and (fFormNav1.Pos - Pos <= startdynattr.StartKLen) then
              begin
                fFormNav1.Assign(dynstart);
                fParagraphs.fModStartLine := pmMinOf(fParagraphs.fModStartLine, fFormNav1.TrueLineNumber);
                startdynattr := fFormNav1.DynAttr;
                foundstop := DynToLevel(startdynattr) < 0
              end else
                foundstop := True
          until foundstop;
        end
      end else
      begin
        { not content dependant }
        startdynattr.DynStyle := 0;
        fFormNav1.AddDyn(startdynattr);
        if fFormNav2.ParNumber = fFormNav1.ParNumber then
          fFormNav2.fDynNb := -1
      end;

    if fOldFinalDyn.DynStyle and $80 = $80 then
      if fOldFinalDyn.DynStyle and $40 = $40 then
      begin
        { content dependant }
        dynstop.Assign(fFormNav2);
        with dynstop do
          if ForwardToDyn(Par^.StartOffset + GetParLength(Par^)) and
            (Pos - fFormNav2.Pos < fOldFinalDyn.StopKLen) then
          begin
            fformNav2.Assign(dynstop);
            fOldFinalDyn := fPar^.ParExtra.DynCodes[fDynNb]
          end
      end else if fFormNav2.Pos < fParagraphs.fTextLen then
        fFormNav2.AddDyn(fOldFinalDyn)
  end;

  if pmpParseAll in fFormNav1.Par.ParState then
  begin
    Exclude(fFormNav1.fPar.ParState, pmpParseAll);
    fFormNav1.ParOffset := 0;
    if fFormNav2.fParNb = fFormNav1.fParNb then
      fFormNav2.ParOffset := High(fFormNav2.ParOffset);
    mustparse := True
  end;

  if mustparse then
  begin
    if Assigned(fOnParse) then
    begin
      Inc(fLockedCount);
      Exclude(fSelStart.Par.ParState, pmpFormatted);
      fOnParse(Self, fSelStart.Pos, fSelstop.Pos);
      Dec(fLockedCount)
    end;

    if fLockedCount > 0 then
      fFormNav1.Par^.ParState := fFormNav1.Par^.ParState - [pmpSSDone, pmpKeywDone]
    else
    begin
      if pmpSSDone in fFormNav1.Par^.ParState then
        { don't leave a paragraph semi parsed }
      begin
        if fFormNav2.ParNumber <> fFormNav1.fParNb then
        begin
          fFormNav2.Assign(fFormNav1);
          fFormNav2.ParOffset := GetParLength(fFormNav1.fPar^)
        end;

        if StartStopKeys = nil then
          sscount := 0
        else
          sscount := StartStopKeys.Count;
        if Keywords = nil then
          skcount := 0
        else
          skcount := Keywords.Count;
        if Assigned(Highlighter) then
          Highlighter.FixRange(fFormNav1, fFormNav2, skcount, sscount);
        ApplyStartStopKeyListP(fFormNav1, fFormNav2, fOldFinalDyn);
      end;
      if pmpKeywDone in fFormNav1.Par^.ParState then
        { don't leave a paragraph semi parsed }
      begin
        if fFormNav2.ParNumber <> fFormNav1.fParNb then
        begin
          fFormNav2.Assign(fFormNav1);
          fFormNav2.ParOffset := GetParLength(fFormNav2.fPar^)
        end;
        ApplyKeywordsListP(fFormNav1, fFormNav2);
        Include(fFormNav1.Par^.ParState, pmpKeywDone)
      end
    end
  end;

  fExtraCols := '';
  fSelLen := 0;
  fBlockSelection := False;

  if fInStripCodes then
    Exit;
  if StaticFormat and StripStrayCtrlCodes then
    for i := fSelStart.ParNumber to fSelStop.ParNumber do
      StripCodes(i);
  fSelStart.Assign(fSelStop);
  fcp := fSelstart;
  {$IFDEF PMDEBUG} CheckIntegrity;
{$ENDIF}
  if fLockedCount = 0 then
  begin
    EndModifications;
    //ScrollInView;     // v6.2c
  end;

  fParagraphs.fNoCompleteFormat := False;
end; { method setSelTextBuf }

{ public methods }

function TPlusMemo.GetSelTextBuf(Buffer: PChar; BufSize: Integer): Integer;
begin
  if Abs(fSelLen) + 1 <= BufSize then
    Result := Abs(fSelLen)
  else
    Result := BufSize - 1;
  fSelStart.GetTextBuf(Buffer, Result)
end;

function TPlusMemo.GetTextPart(Start, Stop: Integer): string; { public methods }
begin
  if Start < 0 then
    Start := 0;
  if Stop > fParagraphs.fTextLen then
    Stop := fParagraphs.fTextLen;
  if Stop <= Start then
    Result := ''
  else
  begin
    ftmpnav2.Pos := Start;
    SetLength(Result, Stop - Start);
    ftmpnav2.GetTextBuf(@Result[1], Stop - Start)
  end
end; { method GetTexPart }

function TPlusMemo.GetTextPartBuf(Start, Stop: LongInt): PChar; { public methods }
begin
  if Stop > fParagraphs.fTextLen then
    Stop := fParagraphs.fTextLen;
  if Start < 0 then
    Start := 0;
  if Stop < Start then
    Result := nil
  else
  begin
    Result := StrAlloc(Stop - Start + 1);
    ftmpnav2.Pos := Start;
    ftmpnav2.GetTextBuf(Result, Stop - Start)
  end
end; { method GetTexPartBuf }

function TPlusMemo.GetBlocksStates(ParNumber: Integer): TBooleanDynArray;
var spar: pParInfo; i: Integer;
begin
  spar := fParagraphs.Pointers[ParNumber];
  SetLength(Result, Byte(spar.BlockState * pmsCBlockLevel));
  for i := 0 to High(Result) do
    Result[i] := pmsGetParCollapsed(spar^, i + 1)
end;

procedure TPlusMemo.BeginUpdate; { public methods }
begin
  Inc(fLockedCount)
end;

procedure TPlusMemo.EndUpdate; { public methods }
begin
  Dec(fLockedCount);
  if fLockedCount < 0 then
    fLockedCount := 0;
  if fLockedCount = 0 then
    EndModifications
end;

procedure TPlusMemo.ClearSelection; { public methods }
begin
  SetSelText('');
end;

procedure TPlusMemo.Clear; { public methods }
var stream: TStream;
begin
  //SetTextBuf('')   This method does not really clear the memo: collapsible block for first paragraph, gutter bookmarks, ...
  stream := TMemoryStream.Create;
  try
    LoadFromStream(stream);
  finally
    stream.Free
  end
end;

procedure TPlusMemo.SetBold; { public methods }
begin
  SetSelAttrib(ctrlBold)
end;

procedure TPlusMemo.SetItalic; { public methods }
begin
  SetSelAttrib(ctrlItalic);
end;

procedure TPlusMemo.SetUnderline; { public methods }
begin
  SetSelAttrib(ctrlUnderline)
end;

procedure TPlusMemo.SetHighlight; { public methods }
begin
  SetSelAttrib(ctrlHighlight)
end;

procedure TPlusMemo.SetAltFont; { public methods }
begin
  SetSelAttrib(ctrlAltFont)
end;

procedure TPlusMemo.CopyToClipboard; { public methods }
var
  Data: THandle; DataPtr: PChar;
  sblock: string;
begin
  if SelLength <> 0 then
  begin
    Clipboard.Open;
    if fBlockSelection then
      sblock := SelectedBlockText
    else
    begin
      if pmoPlainClipboard in Options then
        sblock := StripCodes(SelText)
      else
        sblock := SelText
    end;
{$IFDEF TPLUSMEMOU}
    Data := GlobalAlloc(GMEM_MOVEABLE + GMEM_DDESHARE, (Length(sblock) + 1) * 2);
    DataPtr := GlobalLock(Data);
    Move(sblock[1], DataPtr^, (Length(sblock) + 1) * 2);
    GlobalUnlock(Data);
    Clipboard.SetAsHandle(CF_UNICODETEXT, Data);
    if Win32Platform < VER_PLATFORM_WIN32_NT then
      Clipboard.AsText := sblock;
{$ELSE}
    Clipboard.AsText := pmNativeString(sblock);
    if fBlockSelection then
    begin
      RegisterCbBlocks;
      Data := GlobalAlloc(GMEM_MOVEABLE + GMEM_DDESHARE, 1);
      DataPtr := GlobalLock(Data);
      PByte(DataPtr)^ := 2;
      // This signals a block
      GlobalUnlock(Data);
      Clipboard.SetAsHandle(ClipboardBlockFormat, Data);
    end;
{$ENDIF}
    Clipboard.Close
  end
end;

procedure TPlusMemo.CutToClipboard; { public methods }
begin
  CopyToClipboard;
  SetSelText('')
end;

function TPlusMemo.DynText(Start, Stop: LongInt): string;
var tmp: LongInt; dcodes, currpos: Integer;
begin
  if Start = Stop then
  begin
    Result := '';
    Exit
  end;

  if Start > Stop then
  begin
    tmp := Stop;
    Stop := Start;
    Start := tmp
  end;
  ftmpnav1.Pos := Start;

  dcodes := 0;
  while ftmpnav1.ForwardToDyn(Stop) do
  begin
    ftmpnav1.RightOfDyn;
    Inc(dcodes);
  end;

  { make room for dyn info, the position of each, and total number of dyn }
  SetLength(Result, Stop - Start + (dcodes + 1) * (SizeOf(DynInfoRec) + SizeOf(Integer)) + SizeOf(Integer));

  { write the number of dyns }
  pInteger(@Result[1])^ := dcodes + 1;
  currpos := SizeOf(Integer) + 1;

  { write each dyn and its pos }
  ftmpnav1.Pos := Start;
  pDynInfoRec(@Result[currpos])^ := ftmpnav1.DynAttr;
  Inc(currpos, SizeOf(DynInfoRec));
  pInteger(@Result[currpos])^ := 0;
  Inc(currpos, SizeOf(Integer));
  while ftmpnav1.ForwardToDyn(Stop) do
  begin
    ftmpnav1.RightOfDyn;
    pDynInfoRec(@Result[currpos])^ := ftmpnav1.DynAttr;
    Inc(currpos, SizeOf(DynInfoRec));
    pInteger(@Result[currpos])^ := ftmpnav1.Pos - Start;
    Inc(currpos, SizeOf(Integer))
  end;

  ftmpnav1.Pos := Start;
  ftmpnav1.GetTextBuf(PChar(@Result[currpos]), Stop - Start)
end;

procedure TPlusMemo.PasteFromClipboard; { public methods }
var sblock: Boolean;
  s: string;
  snav1, snav2: TPlusNavigator;
  savedblock: TPoint;
  cbh: THandle; cbmem: PChar; cbsize: Cardinal;
begin
  if pmoNoOverwriteBlocks in Options then
    PrepareKeepBlock(snav1, snav2, savedblock);
  if pmoBlockSelection in Options then
  begin
    RegisterCbBlocks;
    sblock := Clipboard.HasFormat(ClipboardBlockFormat);
    if sblock then
      // further check if a #2 is there, which signals a block
    begin
      Clipboard.Open;
      cbh := GetClipboardData(ClipboardBlockFormat);
      cbsize := GlobalSize(cbh);
      cbmem := GlobalLock(cbh);
      if cbsize >= 1 then
        sblock := PByte(cbmem)^ = 2;
      GlobalUnlock(cbh);
      Clipboard.Close
    end
  end else
    sblock := False;

  if Clipboard.HasFormat(CF_TEXT) then
  begin
    fUndoBreak := True;
    {$IFDEF TPLUSMEMOU}
    if Clipboard.HasFormat(CF_UNICODETEXT) then
    begin
      Clipboard.Open;
      cbh := GetClipboardData(CF_UNICODETEXT);
      if cbh <> 0 then
      begin
        cbmem := GlobalLock(cbh);
        s := cbmem;
        GlobalUnlock(cbh)
      end;
      Clipboard.Close
    end else
      {$ENDIF}
      s := string(Clipboard.AsText);

    if sblock then
      InsertBlock(s)
    else
      SelText := s;
    fUndoBreak := True
  end;

  if pmoNoOverwriteBlocks in Options then
    EndKeepBlock(snav1, snav2, savedblock)
end;

procedure TPlusMemo.SelectAll; { public methods }
begin
  Inc(fSelMoveUpdateCount);
  SelStart := fParagraphs.fTextLen;
  Dec(fSelMoveUpdateCount);
  SelLength := -fParagraphs.fTextLen
end;

procedure TPlusMemo.LoadFromStream(Stream: TStream; Ascii: Boolean = False); { public methods }
var i: Integer; b: TpmsLineBreak; savedlines: Integer;
begin
  Modified := True;
  Inc(fLockedCount);
  savedlines := fParagraphs.fTrueLineCount;
  CleanUp;
  b := psbCRLF;
  fLoadingContent := True;
  fLoadStreamSize := Stream.Size;

  try
    fParagraphs.LoadFromStream(Stream, Ascii, NullReplacement, pmoDiscardTrailingSpaces in Options,
      b, OnProgress, ProgressInterval);
    if pmoAutoLineBreak in Options then
      fLineBreak := TPlusLineBreak(b)

  finally
    fLoadingContent := False;
    fMaxLineWidth := 0;
    fMaxLineNumber := -1;
    fStartLineSelection := -1;

    fSelLen := 0;
    fExtraCols := '';
    fcp := fSelStart;
    fXCaretRunningPos := Low(fXCaretRunningPos);

    for i := 0 to fNavigators.Count - 1 do
      with TPlusNavigator(fNavigators[i]) do
      begin
        Invalidate;
        Pos := 0
      end;

    if Assigned(fOnParse) then
      fOnParse(Self, 0, fParagraphs.fTextLen);
    Dec(fLockedCount);
    fTopOrigin := 0;
    fDisplayLeft := 0;

    if Assigned(fOnProgress) then
      fOnProgress(Self);
    if fLockedCount = 0 then
      // EndModifications might be more appropriate
    begin
      fParagraphs.fModStartPar := fParagraphs.Count;
      fParagraphs.fModStopPar := -1;
      fParagraphs.fModStartLine := fParagraphs.fTrueLineCount;
      fParagraphs.fModLinesOffset := 0;
    end else
      fParagraphs.fModLinesOffset := fParagraphs.fTrueLineCount - savedlines;
    // added v6.2e, corrected v7.1

    if not((csReading in ComponentState) or (fLockedCount > 0)) then

      if (fCanvas <> nil) or ((csDesigning in ComponentState) and (fLineBmp <> nil)) then
        FormatNow(0, fParagraphs.Count - 1, True, True)
      else if fLineBmp <> nil then
      begin
        Invalidate;
        case fUpdateMode of
          umImmediate:
            begin
              FormatNow(0, fParagraphs.Count - 1, True, True);
              fParagraphs.fUpdateStartPar := fParagraphs.Count;
              fParagraphs.fUpdateStopPar := -1
            end;
//          umBackground: fFormatThread.FormatEvent.SetEvent  umBackground commented out until fixed
        end;

        Inc(fLockedCount);
        // no reformat operation on client width change
        SetVScrollParams;
        Dec(fLockedCount);
        if fVScrollBar then
          SetScrollPos(Handle, SB_VERT, 0, True);
        setHScrollParams;
        if fHScrollBar then
          SetScrollPos(Handle, SB_HORZ, 0, True);
        UpdateCaret(False);
      end;

{$IFDEF PMDEBUG}
    checkintegrity
{$ENDIF}
  end;
  // finally
  Change;
  DoNotify(fNotifyList, [pmeNewContent])
end; // method LoadFromStream

procedure TPlusMemo.MakeCollapsibleBlock(StartPar, StopPar: Integer);
begin
  BeginUpdate;
  fParagraphs.MakeCollapsibleBlock(StartPar, StopPar);
  EndUpdate
end;

procedure TPlusMemo.MakeSelCollapsible; { public methods }
begin
  MakeCollapsibleBlock(fSelStart.ParNumber, fSelStop.ParNumber)
end;

procedure TPlusMemo.SaveToStream(Stream: TStream; Ascii: Boolean = False); { public methods }
begin
  fSavingContent := True;
  try
    fParagraphs.SaveToStream(Stream, Ascii, StripStrayCtrlCodes, pmoDiscardTrailingSpaces in Options, TpmsLineBreak(LineBreak),
      fOnProgress, fProgressInterval)
  finally
    fSavingContent := False
  end
end;

 { public methods }

function  TPlusMemo.FindTxt(const Text: string; GoForward, MatchCase: Boolean; WholeWordsOnly, Global: Boolean): Boolean;
begin
  Result := FindTextP(Self, Text, GoForward, MatchCase, WholeWordsOnly, Global)
end;

function TPlusMemo.CanUndo: Boolean; { public methods }
begin
  if fInUndo then
    Result := fUndoLevel > 1
  else
    Result := fUndoLevel > 0
end;

function TPlusMemo.CanRedo: Boolean; { public methods }
begin
  if fInUndo then
    Result := fUndoLevel <= fUndoList.Count
  else
    Result := fUndoLevel < fUndoList.Count
end;

procedure TPlusMemo.ClearUndo; { public methods }
var i: Integer;
begin
  for i := 0 to fUndoList.Count - 1 do
    StrDispose(PChar(fUndoList[i]));
  fUndoLevel := 0;
  fUndoTotalSize := 0;
  fUndoList.Clear
end;

function TPlusMemo.CollapseBlock(ParNumber: Integer; Level: Integer): Boolean; { public methods }
begin
  BeginUpdate;
  Result := fParagraphs.CollapseExpandPar(ParNumber, Level, Level, True);
  EndUpdate
end;

procedure TPlusMemo.CollapseAll(CollapseInners: Boolean; StaticBlocks: Boolean; DynamicBlocks: Boolean); { public methods }
var i, j, sclevel, splevel: Integer; spar: pParInfo;
begin
  BeginUpdate;
  sclevel := 0;

  if StaticBlocks then
  begin
    for i := 0 to fParagraphs.Count - 1 do
    begin
      spar := fParagraphs.Pointers[i];
      splevel := Byte(spar.BlockState * pmsCBlockLevel);
      if not CollapseInners and (splevel > 1) then
        splevel := 1;
      for j := sclevel + 1 to splevel do
        CollapseBlock(i, j);
      sclevel := pmsGetParBlockEndLevel(spar^)
    end
  end;

  if DynamicBlocks then
  begin
    DoDynParse(0, fParagraphs.Count - 1, False);
    ftmpnav1.Pos := 0;
    while ftmpnav1.ForwardToDyn(High(Integer)) do
    begin
      while ftmpnav1.AdvanceDyn do
      begin
        splevel := DynToCollapseLevel(ftmpnav1.pDynAttr^);
        if splevel > sclevel then
          if CollapseInners or (splevel = 1) then
            ftmpnav1.Collapse;
        sclevel := splevel
      end
    end
  end;

  EndUpdate
end;

function TPlusMemo.CollapseSel; { public methods }
var slevel: Integer;
begin
  slevel := Byte(fcp.Par.BlockState * pmsCBlockLevel);
  if slevel > 0 then
    Result := CollapseBlock(fcp.ParNumber, slevel)
  else
    Result := fcp.Collapse(True)
end;

function TPlusMemo.ExpandSel: Boolean; { public methods }
var slevel: Integer;
begin
  slevel := Byte(fcp.Par.BlockState * pmsCBlockLevel);
  if slevel > 0 then
    Result := ExpandBlock(fcp.ParNumber, slevel)
  else
    Result := fcp.Expand(True)
end;

procedure TPlusMemo.ExpandAll(ExpandInners: Boolean = True; StaticBlocks: Boolean = True; DynamicBlocks: Boolean = True); { public methods }
var i, j, sclevel, splevel: Integer; spar: pParInfo;
begin
  BeginUpdate;
  sclevel := 0;

  if StaticBlocks then
  begin
    for i := 0 to fParagraphs.Count - 1 do
    begin
      spar := fParagraphs.Pointers[i];
      splevel := Byte(spar.BlockState * pmsCBlockLevel);
      if not ExpandInners and (splevel > 1) then
        splevel := 1;
      for j := sclevel + 1 to splevel do
        ExpandBlock(i, j);
      sclevel := pmsGetParBlockEndLevel(spar^)
      //sclevel:= splevel
    end
  end;

  if DynamicBlocks then
  begin
    ftmpnav1.Pos := 0;
    while ftmpnav1.ForwardToDyn(High(Integer)) do
    begin
      while ftmpnav1.AdvanceDyn do
      begin
        splevel := DynToCollapseLevel(ftmpnav1.pDynAttr^);
        if splevel > sclevel then
          if ExpandInners or (splevel = 1) then
            ftmpnav1.Expand;
        sclevel := splevel
      end
    end
  end;

  EndUpdate
end;

function TPlusMemo.ExpandBlock(ParNumber: Integer; Level: Integer): Boolean;
begin
  BeginUpdate;
  Result := fParagraphs.CollapseExpandPar(ParNumber, Level, Level, False);
  EndUpdate
end;

procedure TPlusMemo.FormatText(Canvas: TCanvas; Width: Integer);
begin
  fW := Width;
  fCanvas := Canvas;
  if (fCanvas <> nil) or (HandleAllocated) then
  begin
    UpdateFontDependantFields;
    Reformat
  end
end;

type TPaintInfo = record
  StartLine, StopLine: LongInt;
  Position: TPoint;
  LineSpacingPix: Single
end;
pPaintInfo = ^TPaintInfo;

procedure TPlusMemo.DrawLines(StartLine, StopLine: LongInt; Canvas: TCanvas; Pos: TPoint; VertSpacing: Single);
var dummy: TMessage; pi: TPaintInfo;
begin
  fCanvas := Canvas;
  pi.Position := pos;
  pi.StartLine := StartLine;
  pi.StopLine := StopLine;
  pi.LineSpacingPix := VertSpacing;
  dummy.{$IFDEF pmClx} Msg {$ELSE} LParam {$ENDIF} := LongInt(@pi);
  WMPAINT(dummy);
  fCanvas := nil;
end;

{  public methods }

procedure TPlusMemo.SetDynText(Start, Stop: LongInt; const DText: string);
var i, dcodes: Integer; startpos, savedlen, currpos: LongInt; pdyn: pDynInfoRec;
  nav1, nav2: TPlusNavigator;
begin
  if DText = '' then
    Exit;
  nav1 := TPlusNavigator.Create(Self);
  nav2 := TPlusNavigator.Create(Self);
  nav1.Assign(fSelStart);
  nav2.Assign(fSelStop);
  savedlen := SelLength;
  Lines.BeginUpdate;
  SelStart := Start;
  SelLength := Stop - Start;

  dcodes := pInteger(@DText[1])^;
  currpos := SizeOf(Integer) + 1;
  startpos := fSelStart.Pos;
  SetSelTextBuf(PChar(@DText[SizeOf(Integer) + dcodes * (SizeOf(DynInfoRec) + SizeOf(Integer)) + 1]));

  for i := 1 to dcodes do
  begin
    pdyn := @DText[currpos];
    Inc(currpos, SizeOf(DynInfoRec));
    fSelStart.Pos := startpos + pInteger(@DText[currpos])^;
    Inc(currpos, SizeOf(Integer));

    { adjust its level and set it as not content dependant }
    with pdyn^ do
      if DynStyle and $80 <> 0 then
      begin
        Level := -1;
        DynStyle := DynStyle and $BF
      end;
    SetDynStyleP(fParagraphs, fSelStart, fSelStop, pdyn^, pdyn^.DynStyle and $80 <> 0, False)
  end;

  fSelStart.Assign(fSelStop);
  if savedlen >= 0 then
  begin
    SelStart := nav1.Pos;
    SelLength := nav2.Pos - ftmpnav1.Pos
  end else
  begin
    SelStart := nav2.Pos;
    SelLength := nav1.Pos - nav2.Pos
  end;

  nav1.Free;
  nav2.Free;
  Lines.EndUpdate
end;

procedure TPlusMemo.SetDynStyle(Start, Stop: LongInt; Style: TFontStyles;
  ContentDependant: Boolean;
  Context: Integer;
  Cursor: TCursor;
  Backgnd, Foregnd: TColor;
  Collapsible: Boolean);
begin
  ftmpnav1.Pos := Start;
  ftmpnav2.Pos := Stop;
  SetDynStyle(ftmpnav1, ftmpnav2, Style, ContentDependant, Context, Cursor, Backgnd, Foregnd, Collapsible);
end;

procedure TPlusMemo.SetDynStyle(Start, Stop: TPlusNavigator; Style: TFontStyles;
  ContentDependant: Boolean;
  Context: Integer;
  Cursor: TCursor;
  Backgnd, Foregnd: TColor;
  Collapsible: Boolean);
var
  dinf: DynInfoRec;
  lastpar: LongInt;
begin
  dinf.DynStyle := Byte(Style);
  dinf.Level := -1;
  if ContentDependant then
    dinf.DynStyle := dinf.DynStyle or $40;
  dinf.Klen := 0;
  dinf.Context := Context;
  dinf.Cursor := Cursor;
  dinf.CollpsState := [];
  if Collapsible then
    Include(dinf.CollpsState, pmdCollapsible);
  dinf.Backgnd := Backgnd;
  dinf.Foregnd := Foregnd;
  lastpar := Stop.ParNumber;
  SetDynStyleP(fParagraphs, Start, Stop, dinf, True, True);
  InvalidateNavs(fNavigators, Start.Pos, lastpar);
  if fLockedCount = 0 then
    EndModifications
end;

procedure TPlusMemo.ClearStyle(Pos: LongInt); { public methods }
var dummy: DynInfoRec;
begin
  ftmpnav1.Pos := Pos;
  if ftmpnav1.DynAttr.DynStyle and $80 <> 0 then
  begin
    BeginUpdate;
    ftmpnav1.ExpandAllLevels;
    ftmpnav2.Assign(ftmpnav1);
    ftmpnav1.BackToDyn(0);
    ftmpnav2.ForwardToDyn(fParagraphs.fTextLen);
    ftmpnav2.RightOfDyn;
    SetDynStyleP(fParagraphs, ftmpnav1, ftmpnav2, dummy, False, True);
    InvalidateNavs(fNavigators, ftmpnav1.Pos, ftmpnav2.ParNumber);
    EndUpdate
  end
end;

procedure TPlusMemo.ClearStyleRange(FromRange, ToRange: LongInt);
var dummy: DynInfoRec;
begin
  BeginUpdate;
  ftmpnav1.Pos := FromRange;
  ftmpnav2.Assign(ftmpnav1);
  ftmpnav2.ExpandAllLevels;
  while (ftmpnav2.Pos < ToRange) do
  begin
    if not ftmpnav2.ForwardToDyn(ToRange) then
      ftmpnav2.Pos := ToRange
    else
    begin
      ftmpnav2.RightOfDyn;
      ftmpnav2.ExpandAllLevels
    end
  end;
  SetDynStyleP(fParagraphs, ftmpnav1, ftmpnav2, dummy, False, True);
  InvalidateNavs(fNavigators, ftmpnav1.Pos, ftmpnav2.ParNumber);
  EndUpdate
end;

procedure TPlusMemo.InsertBlock(const block: string); { public methods }
var slist: TStringList; i, scol, pcol, sline: Integer; s: string; snav1, snav2: TPlusNavigator; savedblock: TPoint;
begin
  if pmoNoOverwriteBlocks in Options then
    PrepareKeepBlock(snav1, snav2, savedblock);
  slist := TStringList.Create;
  Lines.BeginUpdate;
  try
    slist.Text := pmNativeString(block);
    scol := (fCaretX + fDisplayLeft - fLeftMargin) div fSpaceWidth;
    sline := fSelStart.fParNb;
    for i := 0 to slist.Count - 1 do
    begin
      if i + sline >= fParagraphs.Count then
        Paragraphs.Add('');
      SelPar := i + sline;
      SelCol := ColToOffset(fParagraphs.Pointers[i + sline], scol, TabStops, StaticFormat);
      pcol := ColToExtra(fParagraphs.Pointers[i + sline], scol, TabStops, StaticFormat);
      if pcol > 0 then
      begin
        SetLength(s, pcol);
        FillChar(s[1], Length(s), Ord(' '))
      end else
        s := '';
      SelText := s + string(slist[i])
    end;
  finally
    Lines.EndUpdate;
    slist.Free
  end;
  if pmoNoOverwriteBlocks in Options then
    EndKeepBlock(snav1, snav2, savedblock);
  if fLockedCount = 0 then
    ScrollInView
end;

procedure TPlusMemo.MoveCp(Position: Integer); { public methods }
begin
  fIndependantCpNav.Pos := Position;
  fcp := fIndependantCpNav;
  UpdateCaret(False)
end;

procedure TPlusMemo.SelectBlock(StartCol, StartLine, StopCol, StopLine: Integer); { public methods }
  procedure Adjust(var Line: Integer);
  begin
    if Line < 0 then
      Line := 0;
    if Line >= fParagraphs.Count then
      Line := fParagraphs.Count - 1
  end;
var snav: TPlusNavigator; scol: Integer;
begin
  if WordWrap then
    Exit;
  Adjust(StartLine);
  Adjust(StopLine);
  snav := TPlusNavigator.Create(Self);
  snav.ParNumber := StopLine;
  snav.Col := StopCol;
  scol := snav.Col;
  SelStart := snav.Pos;
  snav.ParNumber := StartLine;
  snav.Col := StartCol;
  SelLength := snav.Pos - SelStart;
  fExtraCols := StringOfChar(Char(' '), pmMaxOf(StopCol - scol, 0));
  fBlockSelection := True;
  UpdateCaret(False);
  fBlockStartCol := StartCol;
  fBlockStopCol := StopCol;
  snav.Free
end;

procedure TPlusMemo.ReApplyKeywords; { public methods }
var i: LongInt; spar: pParInfo;
begin
  if csLoading in ComponentState then
    Exit;
  for i := 0 to fParagraphs.Count - 1 do
  begin
    spar := pParInfo(fParagraphs.Pointers[i]);
    spar^.ParState := spar.ParState - [pmpFormatted, pmpSSDone, pmpKeywDone];
    SetDynCount(spar^, 0);
    SetStartDynAttrib(spar^, nil, False)
  end;

  InvalidateNavs(fNavigators, 0, fParagraphs.Count - 1);
  fParagraphs.fLastStartStopParsed := -1;
  Reformat;
  Invalidate;
end;

procedure TPlusMemo.RemoveCollapsibleBlock(ParNumber: Integer); { public methods }
begin
  BeginUpdate;
  fParagraphs.RemoveCollapsibleBlock(ParNumber);
  EndUpdate
end;

procedure TPlusMemo.RemoveSelCollapsible; { public methods }
begin
  RemoveCollapsibleBlock(fcp.ParNumber)
end;

procedure TPlusMemo.LoadUndo(Stream: TStream); { public methods }
var i, scount, slen: Integer; srec: PChar;
begin
  ClearUndo;
  try
    Stream.Read(fUndoLevel, SizeOf(fUndoLevel));
    Stream.Read(scount, SizeOf(scount));
    for i := 0 to scount - 1 do
    begin
      Stream.Read(slen, SizeOf(slen));
      srec := StrAlloc(slen);
      Stream.Read(srec^, slen * SizeOf(Char));
      fUndoList.Add(srec)
    end
  except
    ClearUndo;
    raise
  end
end;

procedure TPlusMemo.SaveUndo(Stream: TStream); { public methods }
var i, scount, slen: Integer; srec: pChar;
begin
  Stream.Write(fUndoLevel, SizeOf(fUndoLevel));
  scount := fUndoList.Count;
  Stream.Write(scount, SizeOf(scount));
  for i := 0 to scount - 1 do
  begin
    srec := fUndoList[i];
    slen := pmStrBufSize(srec);
    Stream.Write(slen, SizeOf(slen));
    Stream.Write(srec^, slen * SizeOf(Char))
  end
end;

procedure TPlusMemo.Undo; { public methods }
var undocopy: PChar; lc: Integer;
  undop: pOffsetRangeRecord;
  undopchar: PChar;
  undorec: TUndoRecord; sdone: Boolean;
  newundolen: Integer;
begin
  fInUndo := True;
  sdone := fUndoLevel = 0;
  BeginUpdate;
  while not sdone do
  begin
    Dec(fUndoLevel);
    undorec := UndoList[fUndoLevel];
    undop := fUndoList[fUndoLevel];
    undopchar := PChar(undop);
    undocopy := StrNew(undorec.UndoText);
    lc := undop.LockCount;
    Dec(fUndoTotalSize, pmStrBufSize(undopchar));
    StrDispose(undopchar);
    SelStart := undorec.UndoStart;
    SelLength := undorec.UndoStop - undorec.UndoStart;
    newundolen := SizeOf(OffsetRangeRecord) + SelLength + 1;
    undopchar := StrAlloc(newundolen);
    undop := pOffsetRangeRecord(undopchar);
    GetSelTextBuf(undopchar + SizeOf(OffsetRangeRecord), newundolen - SizeOf(OffsetRangeRecord));
    undop.Start := fSelStart.Pos;
    undop.Stop := undop.Start + Integer(StrLen(undocopy));
    undop.LockCount := lc;
    fUndoList[fUndoLevel] := undop;
    Inc(fUndoTotalSize, newundolen);
    SetSelTextBuf(undocopy);
    StrDispose(undocopy);
    sdone := (fUndoLevel = 0) or (undorec.LockCount = 0) or (pOffsetRangeRecord(fUndoList[fUndoLevel - 1]).LockCount <> undorec.LockCount)
  end;
  EndUpdate;
  fInUndo := False;
end;

procedure TPlusMemo.Redo; { public methods }
var undocopy: PChar; lc: Integer;
  undop: pOffsetRangeRecord;
  undopchar: PChar;
  undorec: TUndoRecord; sdone: Boolean;
  newundolen: Integer;
begin
  fInUndo := True;
  sdone := fUndoLevel >= fUndoList.Count;
  BeginUpdate;
  while not sdone do
  begin
    undorec := UndoList[fUndoLevel];
    undop := fUndoList[fUndoLevel];
    undopchar := PChar(undop);
    undocopy := StrNew(undorec.UndoText);
    lc := undop.LockCount;
    Dec(fUndoTotalSize, pmStrBufSize(undopchar));
    StrDispose(undopchar);
    SelStart := undorec.UndoStart;
    SelLength := undorec.UndoStop - undorec.UndoStart;
    newundolen := SizeOf(OffsetRangeRecord) + SelLength + 1;
    undopchar := StrAlloc(newundolen);
    undop := pOffsetRangeRecord(undopchar);
    GetSelTextBuf(undopchar + SizeOf(OffsetRangeRecord), newundolen - SizeOf(OffsetRangeRecord));
    undop.Start := fSelStart.Pos;
    undop.Stop := undop.Start + Integer(StrLen(undocopy));
    undop.LockCount := lc;
    fUndoList[fUndoLevel] := undop;
    Inc(fUndoTotalSize, newundolen);
    SetSelTextBuf(undocopy);
    StrDispose(undocopy);
    Inc(fUndoLevel);
    sdone := (fUndoLevel >= fUndoList.Count) or (undorec.LockCount = 0) or (pOffsetRangeRecord(fUndoList[fUndoLevel]).LockCount <> undorec.LockCount)
  end;
  EndUpdate;
  fInUndo := False;
end;

function TPlusMemo.GetCurrentStyle: TFontStyles; { property access methods }
begin
  ParseStartStopNow(fcp.ParNumber);
  Result := AttrToExtFontStyles(fcp.Style, fcp.DynAttr.DynStyle);
end;

function TPlusMemo.GetParCount: LongInt; { property access methods }
begin
  Result := fParagraphs.Count
end;

function TPlusMemo.GetSelText: string; { property access methods }
begin
  if SelLength = 0 then
    Result := ''
  else if fBlockSelection then
    Result := SelectedBlockText
  else
  begin
    SetLength(Result, Abs(SelLength));
    GetSelTextBuf(PChar(Result), Abs(SelLength) + 1)
  end;
end;

procedure TPlusMemo.SetSelText(s: string); { property access methods }
begin
  if (fExtraCols <> '') and (pmoPutExtraSpaces in Options) and ((not fBlockSelection) or (fSelLen = 0)) then
    s := fExtraCols + s;
  SetSelTextBuf(PChar(s))
end;

procedure TPlusMemo.SetSelLength(l: LongInt); { property access methods }
var  start, stop: LongInt; cp: LongInt; newsel: Boolean;
begin
  fBlockSelection := False;
  if l = fSelLen then
    exit;
  fsSelLenDirty := True;
  fUndoBreak := True;
  if fSelLen < 0 then
    cp := fSelStop.Pos
  else
    cp := fSelStart.Pos;
  if cp + l < 0 then
    l := -cp;
  if cp + l > fParagraphs.fTextLen then
    l := fParagraphs.fTextLen - cp;

  newsel := (fcp <> fSelStart) and (fcp <> fSelStop);
  if newsel then
  begin
    start := fSelStart.VisibleLineNumber;
    stop := fSelStop.VisibleLineNumber
  end else
  begin
    if fSelLen > 0 then
      start := fSelStop.VisibleLineNumber
    else
      start := fSelStart.VisibleLineNumber;
    stop := start;
    // to avoid a warning
  end;

  fSelLen := l;
  if fSelLen > 0 then
  begin
    fSelStart.Pos := cp;
    fSelStop.Pos := cp + fSelLen;
    fcp := fSelStart;
    if not newsel then
      stop := fSelStop.VisibleLineNumber
  end else
  begin
    fSelStart.Pos := cp + fSelLen;
    fSelStop.Pos := cp;
    fcp := fSelStop;
    if not newsel then
      stop := fSelStart.VisibleLineNumber
  end;

  if newsel then
  begin
    start := pmMinOf(start, fSelStart.VisibleLineNumber);
    stop := pmMaxOf(stop, fSelStop.VisibleLineNumber)
  end;
  if (not fNoPaint) and (fLineBmp <> nil) then
    InvalidateLines(start, stop, False);
  DoSelMove
end;

procedure TPlusMemo.setBorderStyle(b: TBorderStyle); { property access methods }
begin
  if b <> fBorderStyle then
  begin
    fBorderStyle := b;
    {$IFDEF pmClx} RecreateWidget
    {$ELSE}        RecreateWnd  {$ENDIF}
  end
end;

procedure TPlusMemo.setEndOfTextMark(p: TPen); { property access methods }
begin
  fEndOfTextPen.Assign(p)
end;

procedure TPlusMemo.setRightLinePen(p: TPen); { property access methods }
begin
  fRightLinePen.Assign(p)
end;

procedure TPlusMemo.setSpecUnderline(p: TPen); { property access methods }
begin
  fSpecUnderlinePen.Assign(p)
end;

procedure TPlusMemo.setLeftMargin(lm: Integer); { property access methods }
begin
  if lm <> fLeftMargin then
  begin
    fLeftMargin := lm;
    if WordWrap then
      Reformat;
    if fLineBmp <> nil then
      RefreshDisplay
  end
end;

procedure TPlusMemo.setRightMargin(rm: Integer); { property access methods }
begin
  if rm <> fRightMargin then
  begin
    fRightMargin := rm;
    if WordWrap then
      Reformat;
    if fLineBmp <> nil then
      RefreshDisplay
  end
end;

procedure TPlusMemo.SetTabStops(t: Integer); { property access methods }
begin
  if t <> fTabStops then
  begin
    fTabStops := t;
    if WordWrap then
      Reformat;
    if fLineBmp <> nil then
      RefreshDisplay
  end
end;

procedure TPlusMemo.SetWordWrap(ww: Boolean); { property access methods }
begin
  if ww <> fWordWrap then
  begin
    fWordWrap := ww;
    Reformat;
    if fLineBmp <> nil then
      RefreshDisplay
  end
end;

procedure TPlusMemo.SetHTColor(c: TColor); { property access methods }
begin
  if c <> fHTColor then
  begin
    fHTColor := c;
    if HandleAllocated then
      Invalidate
  end
end;

procedure TPlusMemo.setHBColor(c: TColor); { property access methods }
begin
  if c <> fHBColor then
  begin
    fHBColor := c;
    if HandleAllocated then
      Invalidate
  end
end;

procedure TPlusMemo.setHideSelection(h: Boolean); { property access methods }
begin
  if h <> fHideSelection then
  begin
    fHideSelection := h;
    if (fLineBmp <> nil) and (not Focused) and (fSelLen <> 0) then
      InvalidateLines(fSelStart.VisibleLineNumber, fSelStop.VisibleLineNumber, False)
  end
end;

procedure TPlusMemo.setSelBackColor(bc: TColor); { property access methods }
begin
  if bc <> fSelBackColor then
  begin
    fSelBackColor := bc;
    if (fLineBmp <> nil) and (fSelLen <> 0) then
      InvalidateLines(fSelStart.VisibleLineNumber, fSelStop.VisibleLineNumber, False)
  end
end;

procedure TPlusMemo.setSelTextColor(tc: TColor);
begin
  if tc <> fSelTextColor then
  begin
    fSelTextColor := tc;
    if (fLineBmp <> nil) and (fSelLen <> 0) then
      InvalidateLines(fSelStart.VisibleLineNumber, fSelStop.VisibleLineNumber, False)
  end
end;

function TPlusMemo.getChar(i: LongInt): Char; { property access methods }
begin
  ftmpnav2.Pos := i;
  Result := ftmpnav2.Text
end;

function TPlusMemo.GetCurrentWord: string;
begin
  Result := fcp.Word
end;

function  TPlusMemo.getLineString(i: Integer): string; { property access methods }
begin
  if i < 0 then
  begin
    Result := '';
    Exit end;
  if WordWrap then
  begin
    ftmpnav1.TrueLineNumber := i;
    while fParagraphs.fUpdateStartPar <= ftmpnav1.ParNumber do
    begin
      FormatNow(fParagraphs.fUpdateStartPar, ftmpnav1.ParNumber, False, True);
      ftmpnav1.TrueLineNumber := i
    end
  end else
    ftmpnav1.ParNumber := i;

  if i >= fParagraphs.fTrueLineCount then
    Result := ''
  else
    Result := ftmpnav1.Line
end;

function  TPlusMemo.getParString(i: Integer): string; { property access methods }
var l: Integer; spar: pParInfo;
begin
  spar := fParagraphs.Pointers[i];
  l := GetParLength(spar^);
  SetLength(Result, l);
  Move(spar.ParText^, Result[1], l * SizeOf(Result[1]))
end;

procedure TPlusMemo.setParString(i: Integer; const par: string); { property access methods }
begin
  PargrphBuf[i] := PChar(par)
end;

procedure TPlusMemo.setLines(Value: TStrings); { property access methods }
begin
  fLines.Assign(Value)
end;

function  TPlusMemo.getLinesBuf(i: LongInt): PChar; { property access methods }
var st: PChar;
begin
  if WordWrap then
  begin
    ftmpnav1.TrueLineNumber := i;
    while fParagraphs.fUpdateStartPar <= ftmpnav1.ParNumber do
    begin
      FormatNow(fParagraphs.fUpdateStartPar, ftmpnav1.ParNumber, False, True);
      ftmpnav1.TrueLineNumber := i
    end
  end else
    ftmpnav1.ParNumber := i;

  if (i >= fParagraphs.fTrueLineCount) or (i < 0) then
    Result := nil
  else
    with ftmpnav1.NavLines.LinePointers[i - ftmpnav1.Par^.StartLine]^ do
    begin
      st := ftmpnav1.Par^.ParText;
      Result := StrAlloc(Stop - Start + 1);
      if Stop > Start then
        Move(st[Start], Result^, (Stop - Start) * SizeOf(Result^));
      Result[Stop - Start] := #0
    end
end;

function  TPlusMemo.getParsBuf(i: LongInt): PChar; { property access methods }
var spar: pParInfo; plen: Integer;
begin
  spar := fParagraphs.Pointers[i];
  plen := GetParLength(spar^);
  Result := StrAlloc(plen + 1);
  if plen > 0 then
    Move(spar.ParText^, Result[0], (plen + 1) * SizeOf(Result[0]))
  else
    Result[0] := #0
end;

procedure TPlusMemo.setParsBuf(i: LongInt; parg: PChar); { property access methods }
var sstart, slen, spar, oldparlen: LongInt; sparp: pParInfo;
begin
  spar := SelPar;
  if SelPar = i then
  begin
    SelStart := PargrphOffset[i];
    SelLength := 0 end;
  sstart := SelStart;
  slen := SelLength;

  BeginUpdate;
  while i >= ParagraphCount do
  begin
    // put empty paragraphs
    SelLength := 0;
    SelStart := CharCount;
    SelText := #13#10;
  end;

  sparp := fParagraphs.ParPointers[i];
  SelStart := sparp.StartOffset;
  oldparlen := GetParLength(sparp^);
  SelLength := oldparlen;
  SetSelTextBuf(parg);
  EndUpdate;

  if spar > i then
    SelStart := sstart + GetParLength(sparp^) - oldparlen
  else
    SelStart := sstart;
  if spar <> i then
    SelLength := slen
end;

procedure TPlusMemo.setStaticFormat(ssf: Boolean); { property access methods }
var tmpstream: TMemoryStream;
begin
  if ssf <> StaticFormat then
  begin
    fParagraphs.StaticFormat := ssf;
    if (not(csReading in ComponentState)) and (fParagraphs.fTextLen > 0) then
    begin
      tmpstream := TMemoryStream.Create;
      SaveToStream(tmpstream);
      tmpstream.Position := 0;
      LoadFromStream(tmpstream);
      tmpstream.Free
    end
  end
end;

procedure TPlusMemo.setBackground(pic: TPicture); { property access methods }
begin
  fBackground.Assign(pic)
end;

function TPlusMemo.getParsOffset(i: LongInt): LongInt; { property access methods }
begin
  Result := fParagraphs.ParPointers[i]^.StartOffset
end;

procedure TPlusMemo.setSelPar(par: LongInt); { property access methods }
begin
  if par >= fParagraphs.Count then
    par := fParagraphs.Count - 1;
  SelStart := fParagraphs.ParPointers[par]^.StartOffset
end;

function TPlusMemo.getSelPar: LongInt;
begin
  Result := fcp.ParNumber
end;

procedure TPlusMemo.setSelStart(ss: LongInt); { property access methods }
begin
  SelLength := 0;
  fExtraCols := '';
  fXCaretRunningPos := Low(fXCaretRunningPos);
  if ss < 0 then
    ss := 0;
  if ss > fParagraphs.fTextLen then
    ss := fParagraphs.fTextLen;
  fSelStart.Pos := ss;
  fSelStop.Assign(fSelStart);
  fcp := fSelStart;
  fUndoBreak := True;
  if fLineBmp <> nil then
    UpdateCaret(False)
end;

function TPlusMemo.getSelStart: LongInt;
begin
  Result := fcp.Pos
end;

procedure TPlusMemo.setSelLine(line: LongInt); { property access methods }
begin
  HandleNeeded;
  ftmpnav1.Assign(fcp);
  if WordWrap then
  begin
    ftmpnav1.TrueLineNumber := line;
    while fParagraphs.fUpdateStartPar <= ftmpnav1.ParNumber do
    begin
      FormatNow(fParagraphs.fUpdateStartPar, ftmpnav1.ParNumber, False, True);
      ftmpnav1.TrueLineNumber := line
    end
  end else
    ftmpnav1.ParNumber := line;
  SelStart := ftmpnav1.Pos
end;

function TPlusMemo.getSelLine: LongInt;
begin
  Result := fcp.TrueLineNumber
end;

procedure TPlusMemo.setSelCol(col: Integer); { property access methods }
begin
  SelLength := 0;
  fExtraCols := '';
  fSelStart.Col := col;
  fSelStop.Assign(fSelStart);
  if (pmoKeepColumnPos in Options) and (not WordWrap) and (fSelStart.Col < Col) then
    fExtraCols := StringOfChar(Char(' '), Col - fSelStart.Col);
  UpdateCaret(False)
end;

function TPlusMemo.getSelCol: Integer; { property access methods }
begin
  Result := fcp.Col + Length(fExtraCols)
end;

function TPlusMemo.GetSelContext: Integer; { property access methods }
begin
  Result := fcp.Context
end;

function TPlusMemo.GetColumnBlockXY; { property access methods }
begin
  if not fBlockSelection then
    Result := Rect(0, 0, 0, 0)
  else
  begin
    if fBlockStartCol < fBlockStopCol then
    begin
      Result.Left := fBlockStartCol;
      Result.Right := fBlockStopCol
    end else
    begin
      Result.Left := fBlockStopCol;
      Result.Right := fBlockStartCol
    end;
    Result.Top := fSelStart.TrueLineNumber;
    Result.Bottom := fSelStop.TrueLineNumber
  end
end;

function TPlusMemo.getCharCount: Integer; { property access methods }
begin
  Result := fParagraphs.fTextLen
end;

function TPlusMemo.getTotalLineCount: Integer; { property access methods }
begin
  Result := fParagraphs.fTrueLineCount
end;

procedure TPlusMemo.setfAltFont(f: TFont); { property access methods }
begin
  fAltFont.Assign(f);
  if WordWrap then
    Reformat;
  if fLineBmp <> nil then
    RefreshDisplay
end;

procedure TPlusMemo.setScrollBars(s: TScrollStyle); { property access methods }
var sreformat: Boolean;
begin
  if s <> ScrollBars then
  begin
    sreformat := (s = ssVertical) or (s = ssBoth) <> fVScrollBar;
    fVScrollBar := (s = ssVertical) or (s = ssBoth);
    fHScrollBar := (s = ssHorizontal) or (s = ssBoth);
    if HandleAllocated then
      RecreateWnd;
    if sreformat and WordWrap then
      Reformat
  end
end;

function TPlusMemo.getScrollBars: TScrollStyle; { property access methods }
begin
  if fVScrollBar and fHScrollBar then
    Result := ssBoth
  else if fVScrollBar then
    Result := ssVertical
  else if fHScrollBar then
    Result := ssHorizontal
  else
    Result := ssNone
end;

  {$WARNINGS OFF} // We get a warning under Delphi 2009

function TPlusMemo.getVersion: { UCONVERT } string { /UCONVERT } ; { property access methods }
begin
  Result := Copy(IdSn, 10, 5) + ' ' + Copy(IdSn, 27, 16)
end;
  {$WARNINGS ON}

procedure TPlusMemo.setVersion(const v: { UCONVERT } string { /UCONVERT } ); { property access methods }
begin
end;

procedure TPlusMemo.setCaretWidth(w: Integer); { property access methods }
begin
  if w = 0 then
  begin
    fAutoCaretWidth := True;
    fCaretWidth := fLineHeight div 14 + 1
  end else
  begin
    fAutoCaretWidth := False;
    fCaretWidth := w
  end;
  if Focused then
  begin
    DestroyCaret;
    CreateCaret(Handle, 0, GetCaretWidth, fLineHeight - 1);
    PlaceCaret;
    ShowCaret(Handle)
  end
end;

procedure TPlusMemo.setDelimiters(const d: TSysCharSet); { property access methods }
begin
  fDelimiters := d + [#13, #10];
  if fStartStopKeys <> nil then
    fStartStopKeys.DelChecked := False;
  if csDesigning in ComponentState then
    ReApplyKeywords
end;

procedure TPlusMemo.setApplyKeywords(apply: Boolean); { property access methods }
begin
  if apply <> fApplyKeywords then
  begin
    fApplyKeywords := apply;
    if csDesigning in ComponentState then
      ReApplyKeywords
  end
end;

procedure TPlusMemo.setApplyStartStopKeys(apply: Boolean); { property access methods }
begin
  if apply <> fApplyStartStopKeys then
  begin
    fApplyStartStopKeys := apply;
    if csDesigning in ComponentState then
      ReApplyKeywords
  end
end;

function  TPlusMemo.getSeparators: AnsiString; { property access methods }
var i: AnsiChar;
begin
  Result := '';
  for i := #0 to #255 do
    if i in Delimiters then
      Result := Result + i
end;

procedure TPlusMemo.setSeparators(const s: AnsiString); { property access methods }
var i: Integer; del: TSysCharSet;
begin
  del := [];
  for i := 1 to Length(s) do
    del := del + [s[i]];
  Delimiters := del
end;

procedure TPlusMemo.setOptions(opt: TPlusMemoOptions); { property access methods }
var reform, reshowsel, redraw: Boolean; smod: Boolean; tmpstream: TMemoryStream;
begin
  if opt <> fOptions then
  begin
    reform := (pmoAutoScrollBars in opt) <> (pmoAutoScrollBars in fOptions);
    reshowsel := opt * [pmoWindowsSelColors, pmoFullLineSelect] <> fOptions * [pmoWindowsSelColors, pmoFullLineSelect];
    redraw := opt * [pmoKeepParBackgnd, pmoFixedBackground] <> fOptions * [pmoKeepParBackgnd, pmoFixedBackground];
    fFixedBMPBackground := (pmoFixedBackground in opt) and (fBackground <> nil) and (fBackground.Width > 0) and (fBackground.Height > 0);

    if (not(csReading in ComponentState)) and (pmoDiscardTrailingSpaces in opt) and (not(pmoDiscardTrailingSpaces in fOptions)) then
    begin
      fOptions := opt;
      { remove existing trailing spaces }
      smod := Modified;
      tmpstream := TMemoryStream.Create;
      SaveToStream(tmpstream);
      tmpstream.Position := 0;
      LoadFromStream(tmpstream);
      tmpstream.Free;
      Modified := smod
    end else
    begin
      fOptions := opt;
      if fLineBmp <> nil then
        if reform then
        begin
          if csDesigning in ComponentState then
            ReApplyKeywords end else if redraw then
              Invalidate
            else if reshowsel and (fSelLen <> 0) then
              InvalidateLines(fSelStart.VisibleLineNumber, fSelStop.VisibleLineNumber, False)
    end
  end
end;

procedure TPlusMemo.setOverwrite(ovr: Boolean); { property access methods }
begin
  if ovr <> fOverwrite then
  begin
    fOverwrite := ovr;
    if Focused and (not DisplayOnly) then
      UpdateCaret(True)
  end
end;

procedure TPlusMemo.setShowNonPrintChars(Show: TpmNonPrintChars);
begin
  if Show <> fShowNonPrintChars then
  begin
    fShowNonPrintChars := Show;
    if HandleAllocated then
      Invalidate
  end
end;

procedure TPlusMemo.setHighlighter(aHighlighter: TPlusHighlighter);
begin
  if fHighlighter <> nil then
    fHighlighter.MemoList.Remove(Self);
  fHighlighter := aHighlighter;
  if aHighlighter <> nil then
    aHighlighter.MemoList.Add(Self);
  if ComponentState * [csDesigning, csLoading] = [csDesigning] then
    ReApplyKeywords
end;

procedure TPlusMemo.setUndoMaxLevel(uml: Integer); { property access methods }
var i: Integer;
begin
  if uml >= 0 then
  begin
    for i := fUndoList.Count - 1 downto pmMaxOf(fUndoLevel, uml) do
      RemoveUndo(i);
    while fUndoLevel > uml do
      RemoveUndo(0)
  end;
  fUndoMaxLevel := uml
end;

procedure TPlusMemo.setUndoMaxSpace(ums: LongInt); { property access methods }
begin
  if ums > 0 then
  begin
    while (fUndoList.Count > fUndoLevel) and (fUndoTotalSize > ums) do
      RemoveUndo(fUndoList.Count - 1);
    while (fUndoTotalSize > ums) and (fUndoList.Count > 0) do
      RemoveUndo(0)
  end;
  fUndoMaxSpace := ums
end;

procedure TPlusMemo.setUpdateMode(um: TpmUpdateMode); { property access methods }
begin
  if um <> fUpdateMode then
  begin
    if Assigned(fFormatThread) then
    begin
      fFormatThread.PutToEnd;
      fFormatThread := nil
    end;

    fUpdateMode := um;
    if (not(csDesigning in ComponentState)) and (fLineBmp <> nil) then
      case um of
        umImmediate: FormatNow(fParagraphs.fUpdateStartPar, fParagraphs.fUpdateStopPar, False, True);

//        umBackground:           umBackground commented out until fixed
//          begin
//            fFormatThread := TpmFormatThread.Create(Self);
//            // Note: it is suspended by default
//            if fParagraphs.fUpdateStartPar <= fParagraphs.fUpdateStopPar then
//              fFormatThread.FormatEvent.SetEvent
//          end
      end
  end
end;

procedure TPlusMemo.setUpperCaseType(ut: TpmUpperCase); { property access methods }
begin
  if ut <> fUpperCaseType then
  begin
    fUpperCaseType := ut;
    if fKeywords <> nil then
      fKeywords.UpperCaseType := ut;
    if fStartStopKeys <> nil then
      fStartStopKeys.UpperCaseType := ut;
    if csDesigning in ComponentState then
      ReApplyKeywords
  end
end;

procedure TPlusMemo.setColumnWrap(cw: Integer); { property access methods }
begin
  if cw <> fColumnWrap then
  begin
    fColumnWrap := cw;
    if WordWrap then
    begin
      Reformat;
      RefreshDisplay
    end
  end
end;

procedure TPlusMemo.setRightLinePos(pos: Integer); { property access methods }
begin
  if pos <> fRightLinePos then
  begin
    fRightLinePos := pos;
    Invalidate
  end
end;

procedure TPlusMemo.setAlignment(al: TAlignment); { property access methods }
begin
  if al <> fAlignment then
  begin
    fDisplayLeft := 0;
    if (not WordWrap) and ((fAlignment in [taRightJustify, taCenter]) or
      (al in [taRightJustify, taCenter])) then
    begin
      fAlignment := al;
      Reformat
    end else
    begin
      fAlignment := al;
      if fLineBmp <> nil then
      begin
        UpdateCaret(False);
        Invalidate
      end
    end
  end
end;

procedure TPlusMemo.setJustified(j: Boolean); { property access methods }
begin
  if j <> fJustified then
  begin
    fDisplayLeft := 0;
    fJustified := j;
    if fLineBmp <> nil then
    begin
      UpdateCaret(False);
      Invalidate
    end
  end
end;

function TPlusMemo.getUndoCount: Integer; { property access methods }
begin
  Result := fUndoList.Count
end;

function TPlusMemo.getUndoList(i: Integer): TUndoRecord; { property access methods }
var orp: ^OffsetRangeRecord;
begin
  orp := fUndoList[i];
  with Result do
  begin
    UndoStart := orp^.Start;
    UndoStop := orp^.Stop;
    LockCount := orp^.LockCount;
    UndoText := PChar(orp) + SizeOf(OffsetRangeRecord)
  end
end;

procedure TPlusMemo.setTopLine(tl: LongInt); { property access methods }
begin
  fDisplayTop.TrueLineNumber := tl;
  TopOrigin := fDisplayTop.VisibleLineNumber * fLineHeight
end;

procedure TPlusMemo.SetTopLeft(NewTopOrigin, NewLeftOrigin, ScTime: Integer);
var
  xscroll, yscroll,
  xscrollamount, yscrollamount: Integer;
  timedone, curtime: Cardinal;
  vis: Boolean;
  sevents: TpmEvents;
  screct: TRect;
begin
  vis := fLineBmp <> nil;
  sevents := [];
  if NewLeftOrigin <> fDisplayLeft then
  begin
    xscroll := fDisplayLeft - NewLeftOrigin;
    sevents := [pmeHScroll];
    Inc(fCaretX, xscroll);
    if fXCaretRunningPos <> Low(fXCaretRunningPos) then
      Inc(fXCaretRunningPos, xscroll);
    fDisplayLeft := NewLeftOrigin;
    if vis and fHScrollBar then
      SetScrollPos(Handle, SB_HORZ, fDisplayLeft div fHScrollfact, True)
  end else
    xscroll := 0;

  if NewTopOrigin <> fTopOrigin then
  begin
    yscroll := fTopOrigin - NewTopOrigin;
    Include(sevents, pmeVScroll);
    fTopOrigin := NewTopOrigin;
    if vis then
      fDisplayTop.VisibleLineNumber := pmMaxOf(0, fTopOrigin div fLineHeight);
    Inc(fCaretY, yscroll);
    if vis and fVScrollBar then
      SetScrollPos(Handle, SB_VERT, fTopOrigin div fVScrollFact, True)
  end else
    yscroll := 0;

  if vis and ((xscroll <> 0) or (yscroll <> 0)) then
  begin
    if (ScTime <> 0) and (fLockedCount = 0) and ((not fInternalScroll) or (GetTickCount - fLastScrollTime > 200)) then
    begin
      Inc(fDisplayLeft, xscroll);
      Inc(fTopOrigin, yscroll);
      timedone := GetTickCount;
      fLastScrollTime := timedone + Cardinal(Abs(ScTime));
      while (fTopOrigin <> NewTopOrigin) or (fDisplayLeft <> NewLeftOrigin) do
      begin
        repeat curtime := GetTickCount  until curtime > timedone;
        if ScTime > 0 then
        begin
          yscrollamount := (ScTime + Integer((curtime - fLastScrollTime))) * yscroll div (2 * ScTime);
          xscrollamount := (ScTime + Integer((curtime - fLastScrollTime))) * xscroll div (2 * ScTime)
        end else
        begin
          yscrollamount := ((Integer(timedone) - Integer(curtime)) * yscroll) div ScTime;
          xscrollamount := ((Integer(timedone) - Integer(curtime)) * xscroll) div ScTime
        end;
        if yscroll > 0 then
        begin
          Inc(yscrollamount);
          if yscrollamount > fTopOrigin - NewTopOrigin then
            yscrollamount := fTopOrigin - NewTopOrigin
        end else
        begin
          Dec(yscrollamount);
          if yscrollamount < fTopOrigin - NewTopOrigin then
            yscrollamount := fTopOrigin - NewTopOrigin
        end;
        if xscroll > 0 then
        begin
          Inc(xscrollamount);
          if xscrollamount > fDisplayLeft - NewLeftOrigin then
            xscrollamount := fDisplayLeft - NewLeftOrigin
        end else
        begin
          Dec(xscrollamount);
          if xscrollamount < fDisplayLeft - NewLeftOrigin then
            xscrollamount := fDisplayLeft - NewLeftOrigin
        end;

        Dec(fTopOrigin, yscrollamount);
        Dec(fDisplayLeft, xscrollamount);
        if yscrollamount <> 0 then
          fDisplayTop.VisibleLineNumber := pmMaxOf(0, fTopOrigin div fLineHeight);
        if fFixedBMPBackground or (xscrollamount > 32767) or (xscrollamount < -32768) or (yscrollamount > 32767) or (yscrollamount < -32768) then
          Invalidate
        else
        begin
          screct := EditRect;
          ScrollWindow(Handle, xscrollamount, yscrollamount, @screct, nil)
        end;
        Update;
        if ScTime > 0 then
        begin
          Dec(yscroll, yscrollamount);
          Dec(xscroll, xscrollAmount)
        end;
        timedone := curtime
      end
    end else
      // ScrollTime=0
      if fFixedBMPBackground or (xscroll > 32767) or (xscroll < -32768) or (yscroll > 32767) or (yscroll < -32768) then
        Invalidate
      else
      begin
        screct := EditRect;
        ScrollWindow(Handle, xscroll, yscroll, @screct, nil)
      end;

    if fInternalScroll then
      fLastScrollTime := GetTickCount;
    if yscroll <> 0 then
      fDisplayTop.VisibleLineNumber := pmMaxOf(0, fTopOrigin div fLineHeight);
    if Focused then
      PlaceCaret;
    if (pmeHScroll in sevents) and Assigned(fOnHScroll) then
      fOnHScroll(Self);
    if (pmeVScroll in sevents) and Assigned(fOnVScroll) then
      fOnVScroll(Self);
    if sevents <> [] then
      DoNotify(fNotifyList, sevents)
  end;
end;

procedure TPlusMemo.setTopOrigin(top: LongInt); { property access methods }
begin
  SetTopLeft(top, fDisplayLeft, ScrollTime)
end;

function TPlusMemo.getTopLine: LongInt; { property access methods }
begin
  Result := fDisplayTop.TrueLineNumber
end;

procedure TPlusMemo.setDisplayLeft(dl: Integer); { property access methods }
begin
  SetTopLeft(fTopOrigin, dl, ScrollTime)
end;

procedure TPlusMemo.setDisplayOnly(d: Boolean); { property access methods }
begin
  if d <> fDisplayOnly then
  begin
    if (not fDisplayOnly) and Focused then
      DestroyCaret;
    fDisplayOnly := d;
    if (not fDisplayOnly) and Focused then
    begin
      CreateCaret(Handle, 0, GetCaretWidth, fLineHeight);
      PlaceCaret;
      ShowCaret(Handle)
    end
  end
end;

procedure TPlusMemo.setLineHeight(lh: Integer); { property access methods }
var oldh: Integer;
begin
  oldh := fLineHeight;
  if lh > 65535 then
    lh := 65535;
  if lh > 0 then
  begin
    fLineHeight := lh;
    fAutoLineHeight := False;
  end else
    fAutoLineHeight := True;

  if fLineBmp <> nil then
  begin
    UpdateFontDependantFields;
    if fLineHeight <> oldh then
    begin
      fTopOrigin := (fTopOrigin div oldh) * fLineHeight + (fTopOrigin mod oldh);
      if fVScrollBar then
      begin
        SetVScrollParams;
        SetScrollPos(Handle, SB_VERT, fTopOrigin div fVScrollFact, True)
      end;
      Invalidate;
      UpdateCaret(False);
      if Assigned(fOnVScroll) then
        fOnVScroll(Self)
    end
  end
end;

function TPlusMemo.getLineHeight: Integer; { property access methods }
begin
  if csDesigning in ComponentState then
    if fAutoLineHeight then
      Result := 0
    else
      Result := fLineHeight
  else
    Result := fLineHeight
end;

function TPlusMemo.GetParFromOffset(pos: LongInt): LongInt; { property access methods }
begin
  ftmpnav1.Pos := pos;
  Result := ftmpnav1.ParNumber
end;

function TPlusMemo.getParBackgnd(i: LongInt): TColor; { property access methods }
begin
  Result := pmsGetParBackgnd(pParInfo(fParagraphs.Pointers[i])^)
end;

function TPlusMemo.getParForegnd(i: LongInt): TColor; { property access methods }
begin
  Result := pmsGetParForegnd(pParInfo(fParagraphs.Pointers[i])^)
end;

procedure TPlusMemo.setParBackgnd(i: LongInt; c: TColor); { property access methods }
var spar: pParInfo;
begin
  spar := fParagraphs.Pointers[i];
  pmsSetParBackgnd(spar^, c);
  if fLineBmp <> nil then
    InvalidateLines(spar.StartLine, spar.StartLine + GetLineCount(spar^) - 1, False)
end;

procedure TPlusMemo.setParForegnd(i: LongInt; c: TColor); { property access methods }
var spar: pParInfo;
begin
  spar := fParagraphs.Pointers[i];
  pmsSetParForegnd(spar^, c);
  if fLineBmp <> nil then
    InvalidateLines(spar.StartLine, spar.StartLine + GetLineCount(spar^) - 1, False)
end;

function TPlusMemo.GetTextContent: string; { property access methods }
const Cr: Char = #13; Lf: Char = #10;
var i, indx, plen: Integer; spar: pParInfo;
begin
  SetLength(Result, fParagraphs.fTextLen);
  indx := 1;
  for i := 0 to fParagraphs.Count - 1 do
  begin
    if i > 0 then
    begin
      Move(Cr, Result[indx], SizeOf(Char));
      Move(Lf, Result[Indx + 1], SizeOf(Char));
      Inc(indx, 2)
    end;
    spar := fParagraphs.Pointers[i];
    plen := GetParLength(spar^);
    if plen > 0 then
    begin
      Move(spar.ParText^, Result[indx], plen * SizeOf(Char));
      Inc(indx, plen)
    end
  end
end;

procedure TPlusMemo.setTextContent(const Value: string); { property access methods }
begin
  SetTextBuf(PChar(Value))
end;

function TPlusMemo.GetEditRect: TRect;
begin
  Result := ClientRect;
  if fVertScrollBar <> nil then
    Dec(Result.Right, fVertScrollBar.Width);
  if fHorzScrollBar <> nil then
    Dec(Result.Bottom, fHorzScrollBar.Height)
end;

function TPlusMemo.getParWrapable(i: Integer): Boolean; { property access methods }
begin
  Result := not(pmpNoWrap in fParagraphs.ParPointers[i].ParState)
end;

procedure TPlusMemo.setParWrapable(i: Integer; Wrap: Boolean); { property access methods }
var spar: pParInfo;
begin
  spar := fParagraphs.Pointers[i];
  if Wrap = (pmpNoWrap in spar.ParState) then
  begin
    if Wrap then
      Exclude(spar.ParState, pmpNoWrap)
    else
      Include(spar.ParState, pmpNoWrap);
    if WordWrap then
    begin
      fParagraphs.ExtendMods(i, 0, i);
      if fLockedCount = 0 then
        EndModifications
    end
  end
end;

procedure TPlusMemo.setCollpsHandler(Handler: TpmsCollapseHandler); { property access methods }
var newipms, oldipms: IpmCollapseHandler;
begin
  if Handler <> fCollpsComp then
  begin
    if Assigned(fCollpsComp) and fCollpsComp.GetInterface(IpmCollapseHandler, oldipms) and
      (oldipms = fCollpsHandler) and Assigned(oldipms) then
    begin
      fCollpsHandler.LinkMemo(Self, False);
      fCollpsHandler := nil
    end;
    fCollpsComp := Handler;
    if Assigned(Handler) and Handler.GetInterface(IpmCollapseHandler, newipms) then
    begin
      if Assigned(fCollpsHandler) then
        fCollpsHandler.LinkMemo(Self, False);
      fCollpsHandler := newipms;
      fCollpsHandler.LinkMemo(Self, True)
    end;
    if fCollpsComp <> nil then
      fCollpsComp.FreeNotification(Self);
  end
end;

procedure TPlusMemo.setWWChars(C: string); { property access methods }
begin
  if C <> fWWChars then
  begin
    fWWChars := C;
    if WordWrap and not(csReading in ComponentState) then
      Reformat
  end
end;

function TPlusMemo.getInternalPopup: TPopupMenu; { property access methods }
begin
  if fInternalPopup = nil then
    CreatePopupMenu;
  Result := fInternalPopup
end;

 { protected methods }

procedure TPlusMemo.RemoveUndo(i: Integer);
var up: PChar;
begin
  up := fUndoList[i];
  Dec(fUndoTotalSize, pmStrBufSize(up));
  StrDispose(up);
  fUndoList.Delete(i);
  if i < fUndoLevel then
    Dec(fUndoLevel)
end;

procedure TPlusMemo.PlaceCaret;
var cpos: Integer;
begin
  if WordWrap and (fCaretX >= fLineWidth) then
    cpos := fLineWidth - 1
  else
    cpos := fCaretX;
  SetCaretPos(cpos, fCaretY)
end;

procedure TPlusMemo.UpdateCaret(Recreate: Boolean); { protected methods }
var oldstyle: TFontStyles; sevents: TpmEvents; i: Integer;
begin
  if fLockedCount > 0 then
    Exit;
  if fLineBmp <> nil then
  begin
    if not(pmpFormatted in fcp.Par.ParState) then
    begin
      FormatNow(fcp.ParNumber, fcp.ParNumber, False, False);
      Exit  // FormatNow will call UpdateCaret itself
    end;
    fCaretX := fcp.DisplayX;

    // take account of exta tabs and spaces
    for i := 1 to Length(fExtraCols) do
      if fExtraCols[i] = #9 then
        if fTabStops > 0 then
          fCaretX := fLeftMargin - fDisplayLeft + ((fCaretX + fDisplayLeft - fLeftMargin) div
            (fTabStops * fSpaceWidth) + 1) * (fTabStops * fSpaceWidth)
        else
        begin
          if fTabStops < 0 then
            fCaretX := fLeftMargin - fDisplayLeft + ((fCaretX + fDisplayLeft - fLeftMargin) div (-fTabStops) + 1) * (-fTabStops)
        end else
          fCaretX := fCaretX + fSpaceWidth
  end;

  fCaretY := fcp.VisibleLineNumber * fLineHeight - fTopOrigin;

  if Focused then
  begin
    if Recreate or (Overwrite and (pmoWideOverwriteCaret in Options)) then
    begin
      DestroyCaret;
      CreateCaret(Handle, 0, pmMaxOf(1, GetCaretWidth), fLineHeight);
      ShowCaret(Handle)
    end;
    PlaceCaret
  end;

  sevents := [];
  oldstyle := fsStyle;
  fsStyle := GetCurrentStyle;
  if (fsPos <> fcp.Pos) or (fExtraCols <> fsExtraCols) then
  begin
    sevents := [pmeSelMove];
    fsPos := fcp.Pos;
    fsExtracols := fExtraCols;
    fsPosDirty := True;
    //if Assigned(fOnMove) then fOnMove(Self)   Replaced by DoSelMove in v7.1
  end;
  DoSelMove;

  if fsStyle <> oldstyle then
  begin
    Include(sevents, pmeStyleChange);
    if Assigned(fOnStyleChange) then
      fOnStyleChange(Self)
  end;

  if sevents <> [] then
    DoNotify(fNotifyList, sevents)
end;

procedure TPlusMemo.Reformat; { protected methods }
begin
  fMaxLineWidth := 0;
  fMaxLineNumber := -1;
  fStartLineSelection := -1;
  if csLoading in ComponentState then
    Exit;
  if fLineBmp <> nil then
    SetHScrollParams;
  if fLockedCount > 0 then
  begin
    fParagraphs.MarkUnformatted;
    fParagraphs.fModStartPar := 0;
    fParagraphs.fModStartLine := 0;
    fParagraphs.fModStopPar := fParagraphs.Count - 1;
    Exit
  end;
{$IFDEF PMDEBUG}
  checkintegrity;
{$ENDIF}

  if (fCanvas <> nil) or ((csDesigning in ComponentState) and (fLineBmp <> nil)) then
    FormatNow(0, fParagraphs.Count - 1, True, True)
  else if fLineBmp <> nil then
    case fUpdateMode of
      umImmediate:
        begin
          FormatNow(0, fParagraphs.Count - 1, True, True);
          fParagraphs.fUpdateStartPar := fParagraphs.Count;
          fParagraphs.fUpdateStopPar := -1
        end;
//      umBackground:        umBackground commented out until fixed
//        begin
//          fParagraphs.MarkUnformatted;
//          fFormatThread.FormatEvent.SetEvent//if fFormatThread.Suspended then fFormatThread.Resume
//        end;
      umOnNeed: fParagraphs.MarkUnformatted
    end else
      fParagraphs.MarkUnformatted;
  ;
    {$IFDEF PMDEBUG}
  checkintegrity
    {$ENDIF}
end; { method Reformat }

procedure TPlusMemo.FormatNow(StartPar, StopPar: LongInt; Unconditional, ShowProgress: Boolean); { protected methods }
  { call only when Handle is allocated, or with fCanvas<>nil }
var
  i: Integer; { paragraph loop index }
  dummy1, dummy2: Integer; { used in call to ReformatPar }
  sCanvas: TCanvas; { working canvas, either Self.Canvas or fCanvas if it is not nil }
  oldfont: THandle;
  w, soldmaxwidth: Integer; { formatting width, old value of fMaxLineWidth }
  apar: pParInfo; { pointer used in paragraph loop }
  loffset, vloffset, { number of lines added while running the loop }
  nextstartline: Integer; { running starting line number for paragraphs }
  initdone: Boolean; { whether any paragraph has been formatted }
  lastnotify: Cardinal; { last time OnProgress was called }
  savedupdate: Integer; { previous value of fUpdateStartPar }
  markUpdateCaret: Boolean; { whether we need to update the caret position after the loop }
  newtoporigin: Integer; { new value of top origin if formatted pars. are above displayed ones }
  newlinecount: Integer; { new value of line count after the formatting }
  newoffset: Integer; { change in line number after a paragraph has been formatted }
  trackinternals: Boolean; { whether scrollbars, caret position and other state must track }
begin
  trackinternals := (fCanvas = nil) or (not Unconditional);
  if StopPar >= fParagraphs.Count then
    StopPar := fParagraphs.Count - 1;
  if (not Unconditional) and (StartPar < fParagraphs.fUpdateStartPar) then
    StartPar := fParagraphs.fUpdateStartPar;
  if StartPar > StopPar then
    Exit;

  if not Assigned(fOnProgress) then
    ShowProgress := False;
  if ShowProgress then
    lastnotify := GetTickCount
  else
    lastnotify := 0;
  fNoPaint := True;
  { avoid paint messages to be effective,
                                so that Application.ProcessMessages can be done inside of OnProgress }
  soldmaxwidth := fMaxLineWidth;

  if fCanvas = nil then
  begin
    sCanvas := Canvas;
    w := fLineWidth
  end else
  begin
    sCanvas := fCanvas;
    w := fw
  end;

  loffset := 0;
  vloffset := 0;

  initdone := False;
  markUpdateCaret := False;
  savedupdate := fParagraphs.fUpdateStartPar;

  nextstartline := 0;
  // to avoid a warning
  if not ShowProgress then
    ParseStartStopNow(StopPar);
  // will be done on a per paragraph basis if show progress

  for i := StartPar to StopPar do
  begin
    if ShowProgress then
      ParseStartStopNow(i);
    apar := fParagraphs.Pointers[i];
    if i > StartPar then
      apar^.StartLine := nextstartline
    else
      nextstartline := apar^.StartLine;

    if Unconditional or (not(pmpFormatted in apar^.ParState)) then
    begin
      if ShowProgress and (GetTickCount - lastnotify > ProgressInterval) then
      begin
        fOnProgress(Self);
        if initdone then
          initdone := False;
        lastnotify := GetTickCount
      end;
      dummy1 := 0;
      ReformatParP(Self, sCanvas, not initdone, w, apar, i, dummy1, dummy2, True, oldfont, fRunningSpaceWidth, fSpaceKern,
        newoffset, newlinecount);
      initdone := True;
      Inc(loffset, newoffset);
      if not(pmpHidden in apar.ParState) then
        Inc(vloffset, newoffset);
      if i = fcp.ParNumber then
      begin
        fcp.fParLine := -1;
        markUpdateCaret := True
      end
    end else
      newlinecount := GetLineCount(apar^);

    fParagraphs.fUpdateStartPar := i + 1;
    if not(pmpHidden in apar.ParState) then
      Inc(nextstartline, newlinecount)
  end;
  // for i:= StartPar to StopPar

  if initdone then
  begin
    if fStartLineSelection > nextstartline then
      Inc(fStartLineSelection, loffset)
    else
      fStartLineSelection := -1;
    InvalidateNavs(fNavigators, fParagraphs.ParPointers[StartPar]^.StartOffset, StopPar);
    Inc(fParagraphs.fTrueLineCount, loffset);
    if vloffset <> 0 then
    begin
      Inc(fParagraphs.fVisibleLineCount, vloffset);
      fParagraphs.UpdateLines(fParagraphs.fUpdateStartPar, vloffset);
      if trackinternals then
      begin
        if StartPar <= fDisplayTop.ParNumber then
        begin
          newtoporigin := fDisplayTop.VisibleLineNumber * fLineHeight + fTopOrigin mod fLineHeight;
          if newtoporigin <> fTopOrigin then
          begin
            fTopOrigin := newtoporigin;
            if fVScrollBar then
              SetScrollPos(Handle, SB_VERT, fTopOrigin div fVScrollFact, True)
          end
        end;

        if ((not WordWrap) or (fColumnWrap > 0)) and (fMaxLineNumber > StopPar) then
          Inc(fMaxLineNumber, loffset);
        if SetVScrollParams then
        begin
          fNoPaint := False;
          Exit
        end
      end
    end;

    if trackinternals then
    begin
      if markUpdateCaret or ((vloffset <> 0) and (StartPar < fcp.ParNumber)) then
        UpdateCaret(False);
      if fHScrollBar and (fMaxLineWidth <> soldmaxwidth) and ((not WordWrap) or (fColumnWrap > 0)) then
      begin
        SetHScrollParams;
        SetScrollPos(Handle, SB_HORZ, fDisplayLeft div fHScrollfact, True);
      end
    end
  end;

  fNoPaint := False;
  if startpar <> savedUpdate then
    fParagraphs.fUpdateStartPar := savedUpdate
  else if ShowProgress and (fParagraphs.fUpdateStartPar >= fParagraphs.Count) then
    fOnProgress(Self)
end; // protected method FormatNow

procedure TPlusMemo.ParseStartStopNow(ToReach: LongInt); { protected methods }
var i: LongInt; spar: pParInfo;
begin
  i := fParagraphs.fLastStartStopParsed + 1;
  while i <= ToReach do
  begin
    spar := fParagraphs.Pointers[i];
    if not(pmpSSDone in spar^.ParState) then
    begin
      fTmpNav1.ParNumber := i;
      fTmpNav2.Assign(fTmpNav1);
      fTmpNav2.ParOffset := High(fTmpNav2.ParOffset);
      ApplyStartStopKeyListP(fTmpNav1, fTmpNav2, fOldFinalDyn)
    end;
    Inc(i)
  end;
  fParagraphs.fLastStartStopParsed := i - 1;
end;

procedure TPlusMemo.Change; { protected methods }
begin
  DoNotify(fNotifyList, [pmeChange]);
  if fMsgList.Count > 0 then
    Perform(CM_TEXTCHANGED, 0, 0);
  if Assigned(fOnChange) then
    fOnChange(Self)
end;

procedure TPlusMemo.InvalidateLines(start, stop: Integer; erase: Boolean); { protected methods }
var r: TRect; ch: Integer;
begin
  if start > stop then
  begin
    ch := stop;
    stop := start;
    start := ch end;
  start := start * fLineHeight - fTopOrigin;
  stop := (stop + 1) * fLineHeight - fTopOrigin;
  ch := ClientHeight;
  if (stop > 0) and (start < ch) then
  begin
    r.Left := 0;
    r.Right := fLineWidth;
    r.Top := start;
    if stop > ch then
      r.Bottom := ch
    else
      r.Bottom := stop;
    InvalidateRect(Handle, @r, erase)
  end
end;

{ protected methods }

function TPlusMemo.GetCaretWidth: Integer; { protected methods }
begin
  if (fSelLen = 0) and Overwrite and (pmoWideOverwriteCaret in Options) then
    Result := fcp.DisplayWidth
  else
    Result := fCaretWidth
end;

procedure TPlusMemo.SetSelAttrib(a: Char); { protected methods }
var s: string; sl: Integer; stoppos: Integer; snav: TPlusNavigator;
begin
  if not StaticFormat then
    Exit;
  snav := TPlusNavigator.Create(Self);
  snav.Assign(fSelStart);
  sl := SelLength;
  s := a + SelText + a;
  fNoCheckFormat := True;
  if sl = 0 then
    fInStripCodes := True;
  SelText := s;
  fNoCheckFormat := False;
  fInStripCodes := False;
  stoppos := fSelStart.Pos;
  if sl = 0 then
    SelStart := SelStart + 1
  else if sl > 0 then
  begin
    SelStart := snav.Pos;
    SelLength := stoppos - snav.Pos
  end else
  begin
    SelStart := stoppos;
    SelLength := snav.Pos - stoppos
  end;
  snav.Free
end;

function TPlusMemo.AttrToExtFontStyles(StaticAttrib: TFontStyles; DynAttrib: Word): TFontStyles;
var newattr: Byte; fontstyle: TFontStyles;
begin
  if DynAttrib and $80 <> 0 then
    if DynAttrib and $18 = $18 then
      Byte(Result) := DynAttrib and $A7
    else
      Byte(Result) := DynAttrib and $3F

  else
  begin
    fontstyle := Font.Style;
    newattr := Byte(StaticAttrib) xor Byte(fontstyle);
    Result := TFontStyles(newattr)
  end
end;

procedure TPlusMemo.SetupFont(AFont: TFont; Style: TFontStyles); { protected methods }
var f: TFont;
begin
  if TPlusFontStyle(fsAltFont) in TPlusFontStyles(style) then
    f := fAltFont
  else
    f := Font;
  AFont.Assign(f);
  AFont.Style := Style * [fsBold, fsItalic, fsUnderline, fsStrikeOut];
end;

procedure TPlusMemo.EndModifications; { protected methods }
var
  startp, stopp, newoffset,
  loffset, vloffset,
  newlinecount,
  nextstartline, i, lw,
  smaxwidth, fl, ll: Integer;
  rs: TRect;
  currentp, startpp: pParInfo;
  dc: TCanvas;
  oldfont: THandle;
  dummyint: Integer;
  newtopy, oldtopy: Integer;
  cw: Integer;
  spars: TParagraphsList;
  scchange: Boolean;
begin
  spars := IParList;
  if (spars.fModStartLine >= 0) and (spars.fModStopPar >= 0) then
  begin
    smaxwidth := fMaxLineWidth;
    if fLineBmp <> nil then
    begin
      cw := fLineWidth;
      dc := Canvas
    end else
    begin
      dc := nil;
      cw := Width
    end;

    // parse displayed paragraphs
    stopp := fDisplayTop.ParNumber;
    i := fTopOrigin div LineHeightRT + fDisplayLines;
    while (stopp < spars.Count - 1) and (spars.ParPointers[stopp].StartLine <= i) do
      Inc(stopp);
    if stopp < spars.fModStartPar then
      stopp := spars.fModStartPar;
    Inc(fLockedCount);
    // parsing routines may expand some code, which will do EndModifications if fLockedCount is 0
    ParseStartStopNow(stopp);
    Dec(fLockedCount);

    startp := spars.fModStartPar;
    startpp := spars.Pointers[startp];
    if spars.fModStopPar < startp then
      spars.fModStopPar := startp;

    { Take care of first modified paragraph; reformatting could be avoided once persistent properties
        are implemented for canvas }
    fl := spars.fModStartLine - startpp^.StartLine;
    ReformatParP(Self, dc, True, cw, startpp, startp, fl, ll,
      (spars.fModStopPar > startp) or (not spars.fNoCompleteFormat), oldfont, fRunningSpaceWidth, fSpaceKern, loffset,
      newlinecount);

    if pmpHidden in startpp^.ParState then
    begin
      vloffset := 0;
      nextstartline := startpp^.StartLine
    end else
    begin
      nextstartline := startpp^.StartLine + newlinecount;
      vloffset := loffset
    end;

    // reformat displayed paragraphs
    stopp := startp;
    if (stopp >= fDisplayTop.fParNb) or ((stopp < fDisplayTop.fParNb) and (spars.fModStopPar >= fDisplayTop.fParNb))  then
    begin
      scchange := False;
      repeat
        Inc(stopp);
        if stopp < spars.Count then
        begin
          currentp := spars.Pointers[stopp];
          if (currentp.StartLine > i) or ((stopp > spars.fModStopPar) and (pmpFormatted in currentp.ParState)) then
            scchange := True
        end else
          scchange := True;
        if scchange then
          Dec(stopp)
      until scchange
    end;

    if spars.fUpdateStartPar = startp then
      spars.fUpdateStartPar := stopp + 1
    else
      spars.fUpdateStartPar := pmMinOf(spars.fUpdateStartPar, stopp + 1);
    spars.fUpdateStopPar := pmMaxOf(spars.fUpdateStopPar, spars.fModStopPar);
    currentp := startpp;

    for i := startp + 1 to stopp do
    begin
      currentp := spars.Pointers[i];
      with currentp^ do
      begin
        //if not (pmpFormatted in currentp^.ParState) then
        begin
          dummyint := 0;
          ReformatParP(Self, dc, False, cw, currentp, i, dummyint, ll, True, oldfont, fRunningSpaceWidth, fSpaceKern,
            newoffset, newlinecount);
          loffset := loffset + newoffset;
          if not(pmpHidden in currentp.ParState) then
            vloffset := vloffset + newoffset
        end;
        //else
        //newlinecount:= GetLineCount(currentp^);
        StartLine := nextstartline;
        if not(pmpHidden in currentp.ParState) then
          nextstartline := nextstartline + newlinecount;
      end;
    end;

    if vloffset <> 0 then
      fParagraphs.UpdateLines(stopp + 1, vloffset);
    Inc(fParagraphs.fTrueLineCount, loffset);
    Inc(fParagraphs.fVisibleLineCount, vloffset);
    Inc(vloffset, spars.fModLinesOffset);

    { invalidate PlusNavigators fParLine }
    for i := 0 to INavigators.Count - 1 do
      with TPlusNavigator(INavigators[i]) do
        if (fParLine >= 0) and (fParNb >= startp) and (fParNb <= stopp) then
          if startp = spars.fModStopPar then
          begin
            if fParLine >= fl then
              fParLine := -1
          end else if (fParNb > startp) or (fParLine >= fl) then
            fParLine := -1;

    { update ui }
    if fLineBmp <> nil then
    begin
      if TopOrigin >= 0 then
        newtopy := DisplayStartNav.VisibleLineNumber * LineHeightRT + TopOrigin mod LineHeightRT
      else
        newtopy := TopOrigin;
      oldtopy := TopOrigin;
      scchange := False;
      if (vloffset <> 0) or (newtopy <> oldtopy) then
      begin
        rs.Top := -TopOrigin + (currentp^.StartLine + ll + 1 - vloffset) * LineHeightRT;
        rs.Bottom := EditRect.Bottom;
        rs.Left := 0;
        rs.Right := fLineWidth;
        if BackgroundBmp.Bitmap.Empty then
        begin
          Inc(rs.Bottom, rs.Top);
          ScrollWindow(Handle, 0, vloffset * LineHeightRT + TopOrigin - newtopy, @rs, nil);
        end else
        begin
          if vloffset < 0 then
            Inc(rs.Top, vloffset * LineHeightRT);
          InvalidateRect(Handle, @rs, False)
        end;
        fTopOrigin := newtopy;
        scchange := SetVScrollParams;
        if (not scchange) and (fVScrollFact > 0) and (newtopy <> oldtopy) then
          SetScrollPos(Handle, SB_VERT, fTopOrigin div fVScrollFact, True)
      end;
      { loffset<>0 }

      if ((not WordWrap) or (ColumnWrap > 0)) and (fMaxLineNumber < 0) then
      begin
        fMaxLineWidth := 0;
        for i := 0 to spars.Count - 1 do
        begin
          lw := GetFirstLine(pParInfo(IParList.Pointers[i])^).LineWidth;
          if lw > fMaxLineWidth then
          begin
            fMaxLineWidth := lw;
            fMaxLineNumber := i
          end
        end
      end;

      if fHScrollBar and (fMaxLineWidth <> smaxwidth) and (not scchange) then
      begin
        setHScrollParams;
        SetScrollPos(Handle, SB_HORZ, LeftOrigin div fHScrollfact, True)
      end;

      InvalidateLines(startpp^.StartLine + fl, currentp^.StartLine + ll, False);

      if scchange or (spars.fModStopPar > startp) then
        case UpdateMode of
//          umBackground:        commented out until fixed
//            if (not(csDesigning in ComponentState)) then
//              fFormatThread.FormatEvent.SetEvent;
          umImmediate: FormatNow(spars.fUpdateStartPar, spars.fUpdateStopPar, False, False)
        end;
    end;
    { HandleAllocated }

  end;

  spars.fModStartLine := fParagraphs.fTrueLineCount;
  spars.fModStartPar := spars.Count;
  spars.fModStopPar := -1;
  spars.fModLinesOffset := 0;

  {$IFDEF PMDEBUG}
  CheckIntegrity;
  {$ENDIF}
  if spars.fModified then
  begin
    spars.fModified := False;
    Change
  end;

  if fLineBmp <> nil then
    UpdateCaret(False);
end; { method EndModifications }

procedure TPlusMemo.setHScrollParams; { protected methods }
var scrange: Integer;
  sc: TScrollInfo;
begin
  fInSetScroll := True;
  { avoid SetBounds calling this method }
  fHScrollfact := (fMaxLineWidth + fLeftMargin + fRightMargin) div Integer(32760) + 1;
  scrange := pmMaxOf(0, (fMaxLineWidth + fLeftMargin + fRightMargin - fLineWidth) div fHScrollFact);

  if fHScrollBar then
    with sc do
    begin
      cbSize := SizeOf(sc);
      fMask := sif_range or sif_page;
      nMin := 0;
      nPage := (fLineWidth - fLeftMargin - fRightMargin) div fHScrollfact;
      nMax := scrange + Integer(nPage) - 1;
      if WordWrap and (fColumnWrap = 0) then
        nMax := nPage - 1;
      if not(pmoAutoScrollBars in Options) then
        Inc(nMax);
      if fAlignment in [taRightJustify, taCenter] then
        nMax := nPage;
      SetScrollInfo(Handle, sb_horz, sc, False);
      if nMax < Integer(nPage) then
        LeftOrigin := 0
    end;

  if fLineHeight > 0 then
    fDisplayLines := ClientHeight div fLineHeight + 1
  else
    fDisplayLines := 1;
  fInSetScroll := False
end;

function TPlusMemo.SetVScrollParams: Boolean; { protected methods }
var
  scheight, scrange: Integer;
  susescroll: Boolean;
  sc: TScrollInfo;
  newpage: Integer;
begin
  scheight := ClientHeight;
  susescroll := False;
  if fHorzScrollBar <> nil then
    Dec(scheight, fHorzScrollBar.Height);
  fVscrollfact := (fParagraphs.fVisibleLineCount * fLineHeight) div Integer(32760) + 1;
  fInSetScroll := True;

  if fVScrollBar then
    with sc do
    begin
      cbSize := SizeOf(sc);
      fMask := sif_range or sif_page;
      nMin := 0;
      GetScrollInfo(Handle, sb_vert, sc);
      scrange := pmMaxOf((fParagraphs.fVisibleLineCount * fLineHeight) div fVScrollFact, scheight - fLineHeight - 1);
      if (not(pmoAutoScrollBars in Options)) and (scrange < scheight) then
        Inc(scrange);
      newPage := (scheight - 3) div fVScrollFact;
      susescroll := newPage < scrange;
      if (scrange <> nMax) or (newPage <> Integer(nPage)) then
      begin
        nPage := newPage;
        nMax := scrange;
        SetScrollInfo(Handle, sb_vert, sc, True);
      end
    end;

  fLineWidth := ClientWidth;
  if fVertScrollBar <> nil then
    Dec(fLineWidth, fVertScrollBar.Width);
  Result := fLineWidth <> fLineBmp.Width;

  if Result then
  begin
    { recreate internal drawing bmp with proper width }
    fLineBmp.Width := fLineWidth;
    if fLockedCount = 0 then
      if fWordWrap or (fAlignment <> taLeftJustify) then
      begin
        if fCanvas <> nil then
          // we are in the paint handler
        begin
          fParagraphs.MarkUnformatted;
          fw := fLineWidth;
        end else
        begin
          Reformat;
          Invalidate
        end
      end else
        SetHScrollParams;
    if fVScrollBar and not susescroll then
      TopOrigin := 0   // fVScrollBar added v6.5b
  end;
  fInSetScroll := False
end;

function TPlusMemo.GetUpText(Par: pParInfo; ParNb, Start, Len: Integer): PChar; { protected methods }
var
  newlen: Integer;
  newupt: PChar;
  frontadd: Integer;
  upproc: TpmUpperCaseProc;
begin
  upproc := nil;
  case UpperCaseType of
    pmuAnsi: upproc := pmCharUpper;
    pmuUserDefined: if Assigned(UserUpperCaseProc) then
      upproc := UserUpperCaseProc
  end;

  if Par = nil then
    Par := fParagraphs.Pointers[ParNb];
  if (fUpParNb <> ParNb) or (fUpOffset > Start + Len) or (fUpOffset + fUpLength < Start) then
  begin
    { start with a completely new buffer }
    if fUpText <> nil then
      StrDispose(fUpText);
    fUpText := StrAlloc(Len + 1);
    Move(Par^.ParText[Start], fUpText^, Len * SizeOf(fUpText^));
    fUpText[Len] := #0;
    if Assigned(upproc) then
      upproc(fUpText)
    else
      StrUpper(fUpText);
    fUpOffset := Start;
    fUpLength := Len
  end else
  begin
    { just expand existing buffer if needed }
    frontadd := fUpOffset - Start;
    if frontadd > 0 then
    begin
      newlen := pmMaxOf(Len, fUpLength + frontadd);
      newupt := StrAlloc(newlen + 1);
      Move(Par^.ParText[Start], newupt^, frontadd * SizeOf(newupt^));
      newupt[frontadd] := #0;
      if Assigned(upproc) then
        upproc(newupt)
      else
        StrUpper(newupt);
      Move(fUpText^, newupt[frontadd], (fUpLength + 1) * SizeOf(newupt^));
      if newlen > fUpLength + frontadd then
      begin
        Move(Par^.ParText[fUpOffset + fUpLength], newupt[fUpLength + frontadd], (newlen - (fUpLength + frontadd)) * SizeOf(newupt^));
        newupt[newlen] := #0;
        if Assigned(upproc) then
          upproc(newupt + (frontadd + fUpLength))
        else
          StrUpper(newupt + (frontadd + fUpLength))
      end;
      StrDispose(fUpText);
      fUpText := newupt;
      fUpOffset := Start;
      fUpLength := newlen
    end else if Len > fUpLength + frontadd then
    begin
      newlen := Len - frontadd;
      newupt := StrAlloc(newlen + 1);
      Move(fUpText^, newupt^, fUpLength);
      Move(Par^.ParText[fUpOffset + fUpLength], newupt[fUpLength], (newlen - fUpLength) * SizeOf(newupt^));
      newupt[newlen] := #0;
      if Assigned(upproc) then
        upproc(newupt + fUpLength)
      else
        StrUpper(newupt + fUpLength);
      StrDispose(fUpText);
      fUpText := newupt;
      fUpLength := newlen
    end
  end;

  Result := fUpText + Start - fUpOffset
end;

function TPlusMemo.SelectedBlockText: string; { protected methods }
var i, indx, bstart, bstop: Integer; p: pParInfo; pstop, pstart: Integer;
begin
  if (not fBlockSelection) or (fSelLen = 0) then
    Result := ''
  else
  begin
    if fBlockStartCol > fBlockStopCol then
    begin
      bstop := fBlockStartCol;
      bstart := fBlockStopCol
    end else
    begin
      bstop := fBlockStopCol;
      bstart := fBlockStartCol
    end;
    SetLength(Result, (bstop - bstart + 2) * (fSelStop.ParNumber - fSelStart.ParNumber + 1));
    indx := 1;
    for i := fSelStart.fParNb to fSelStop.fParNb do
    begin
      p := fParagraphs.Pointers[i];
      pstart := ColToOffset(p, bstart, TabStops, StaticFormat);
      pstop := ColToOffset(p, bstop, TabStops, StaticFormat);
      if pstop > pstart then
      begin
        Move(p.ParText[pstart], Result[indx], (pstop - pstart) * SizeOf(Result[1]));
        Inc(indx, pstop - pstart)
      end;
      Result[indx] := #13;
      Result[indx + 1] := #10;
      Inc(indx, 2)
    end;
    Result[indx] := #0;
    SetLength(Result, indx - 1)
  end
end;

procedure TPlusMemo.CreatePopupMenu; { protected methods }
  function CreateMenuItem(const s: pmNativeString; TagValue: Integer): TMenuItem;
  begin
    Result := TMenuItem.Create(fInternalPopup);
    Result.Tag := TagValue;
    Result.Caption := s;
    Result.OnClick := PopupClickHandler;
    fInternalPopup.Items.Add(Result)
  end;
begin
  fInternalPopup := TPopupMenu.Create(Self);
  SetLength(fInternalPopupItems, 8);
  fInternalPopup.OnPopup := PopupClickHandler;
  fInternalPopupItems[0] := CreateMenuItem('&Undo', 100);
  fInternalPopupItems[1] := CreateMenuItem('&Redo', 101);
  fInternalPopupItems[2] := CreateMenuItem('-', 0);
  fInternalPopupItems[3] := CreateMenuItem('Cu&t', 102);
  fInternalPopupItems[4] := CreateMenuItem('&Copy', 103);
  fInternalPopupItems[5] := CreateMenuItem('&Paste', 104);
  fInternalPopupItems[6] := CreateMenuItem('-', 0);
  fInternalPopupItems[7] := CreateMenuItem('&Select all', 105);
end;

procedure TPlusMemo.PopupClickHandler(Sender: TObject); { protected methods }
begin
  if Sender = fInternalPopup then
  begin
    fInternalPopupItems[0].Enabled := CanUndo;
    fInternalPopupItems[1].Enabled := CanRedo;
    fInternalPopupItems[3].Enabled := (SelLength <> 0) and (not(ReadOnly or DisplayOnly));
    fInternalPopupItems[4].Enabled := SelLength <> 0;
    fInternalPopupItems[5].Enabled := {$IFNDEF pmClx} Clipboard.HasFormat(CF_TEXT) and {$ENDIF}
      (not(ReadOnly or DisplayOnly));
    if Assigned(fOnInternalPopup) then
      fOnInternalPopup(Sender)
  end else
    case (Sender as TMenuItem).Tag of
      100: begin
        Undo;
        ScrollInView end;
      101: begin
        Redo;
        ScrollInView end;
      102: begin
        CutToClipboard;
        ScrollInView end;
      103: CopyToClipboard;
      104: begin
        PasteFromClipboard;
        ScrollInView end;
      105: SelectAll
    end
end;

procedure TPlusMemo.RefreshDisplay; { protected methods }
begin
  if fLineBmp <> nil then
  begin
    {$IFDEF PMDEBUG}
    CheckIntegrity;
    {$ENDIF}

    if fDisplayTop.VisibleLineNumber > pmMaxOf(fParagraphs.fVisibleLineCount - fDisplayLines + 1, 0) then
      FirstVisibleLine := pmMaxOf(fParagraphs.fVisibleLineCount - fDisplayLines + 1, 0);
    Invalidate;
    Update;
    UpdateCaret(False);
  end
end;

procedure TPlusMemo.CheckIntegrity; { protected methods }
  { checks wether everything is properly set in internal data structures }
var i, j, line, tline, offset, blevel: Integer; lin: LineInfo;
  loffset: Integer;
  spar: pParInfo;
begin
  line := 0;
  offset := 0;
  tline := 0;
  blevel := 0;
  for i := 0 to fParagraphs.Count - 1 do
  begin
    spar := fParagraphs.Pointers[i];
    if spar.StartLine <> line then
      raise Exception.Create('Error 1' + Version);
    if spar.StartOffset <> offset then
      raise Exception.Create('Error 2 in ' + Version);
    if pmsGetParBlockStartLevel(spar^) <> blevel then
      raise Exception.Create('Error 7 in ' + Version);
    blevel := pmsGetParBlockEndLevel(spar^);

    fTmpLines.LLPar := fParagraphs.Pointers[i];
    loffset := 0;
    for j := 0 to fTmpLines.Count - 1 do
    begin
      lin := fTmpLines[j];
      if lin.Start <> loffset then
        raise Exception.Create('Error 3 in ' + Version);
      loffset := lin.Stop
    end;
    if lin.Stop <> GetParLength(spar^) then
      raise Exception.Create('Error 4 in ' + Version);
    if not(pmpHidden in spar.ParState) then
      line := line + fTmpLines.Count;
    tline := tline + fTmpLines.Count;
    offset := offset + GetParLength(spar^) + 2
  end;
  if offset <> fParagraphs.fTextLen + 2 then
    raise Exception.Create('Error 5 in ' + Version);
  if line <> fParagraphs.fVisibleLineCount then
    raise Exception.Create('Error 6 in ' + Version);
  if tline <> fParagraphs.fTrueLineCount then
    raise Exception.Create('Error 6.01 in ' + Version);
  fTmpLines.LLPar := nil
end;

  { overriden protected methods }

function  TPlusMemo.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; {$IFDEF pmClx} const {$ENDIF} MousePos: TPoint): Boolean;
var sp, snewtopline, sfact: Integer;
begin
  Result := True;
  if fMouseWheelFact < 0 then
    if Win32MajorVersion < 4 then
      sfact := 3
    else
    begin
      SystemParametersInfo(SPI_GETWHEELSCROLLLINES, 0, @sfact, 0);
      if sfact = -1 then
        sfact := pmMaxOf(1, fDisplayLines - 2)
    end else
      sfact := fMouseWheelFact;

  Inc(fMouseWheelAcc, WheelDelta * sfact);
  snewtopline := fDisplayTop.VisibleLineNumber;
  while fMouseWheelAcc <= -120 do
  begin
    Inc(snewtopline);
    Inc(fMouseWheelAcc, 120)
  end;
  while fMouseWheelAcc >= 120 do
  begin
    Dec(snewtopline);
    Dec(fMouseWheelAcc, 120)
  end;
  sp := fParagraphs.fVisibleLineCount - fDisplayLines + 1;
  if snewtopline >= sp then
    snewtopline := sp;
  if snewtopline < 0 then
    snewtopline := 0;
  if pmoNoFineScroll in Options then
    // v6.2c: use SetTopLeft instead of TopOrigin to avoid smooth scrolling
    SetTopLeft(snewtopline * fLineHeight, fDisplayLeft, 0)
  else
    SetTopLeft(pmMinOf(snewtopline * fLineHeight, pmMaxOf(fParagraphs.fVisibleLineCount * fLineHeight - EditRect.Bottom + 3, 0)),
      fDisplayLeft, 0);
  inherited DoMouseWheel(Shift, WheelDelta, MousePos);
end;

procedure TPlusMemo.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var sline, scp, cp: Integer;
begin
  inherited MouseDown(Button, Shift, X, Y);
  Inc(fSelMoveUpdateCount);
  try
    if Button = mbLeft then
    begin
      fBlockSelection := False;
      fMouseDownPos := fMouseNav.Pos;
      fXCaretRunningPos := Low(fXCaretRunningPos);
      if not fDisplayOnly then
      begin
        fMouseDown := True;
        if fDblClick then
          Exit;
        fExtraCols := '';
        fDragging := fMouseInSel and (not ReadOnly);

        if fDragging then
        begin
          fDraggingOutside := False;
          fcp := fMouseNav;
          Screen.Cursor := crDrag;
          {$IFNDEF pmClx}
          ShowCursor(True);
          {$ENDIF}
          UpdateCaret(True);
        end else
        begin
          if (fStartLineSelection >= 0) and (X < fLeftMargin - 2 - fDisplayLeft) then
          begin
            SelStart := fMouseNav.Pos;
            with fMouseNav.NavLines[fMouseNav.ParLine] do
              SelLength := Stop - Start;
            if (fMouseNav.ParNumber < fParagraphs.Count - 1) and (fMouseNav.ParLine >= fMouseNav.fNavLines.Count - 1) then
              SelLength := SelLength + 2;
          end else
          begin
            fStartLineSelection := -1;
            if not(ssShift in Shift) then
              SelLength := 0;
            fBlockSelection := (Shift = [ssLeft, ssAlt]) and (pmoBlockSelection in Options) and (not WordWrap);
            scp := fcp.Pos;
            sline := fcp.VisibleLineNumber;
            ftmpnav1.Assign(fcp);
            if Y >= Int64(fParagraphs.fVisibleLineCount) * fLineHeight - fTopOrigin then
              ftmpnav1.Pos := fParagraphs.fTextLen
            else
            begin
              ftmpnav1.DisplayPos := Point(X, Y);
              if ((pmoKeepColumnPos in Options) or fBlockSelection) and
                ((ftmpnav1.ParOffset >= GetParLength(ftmpnav1.Par^)) or (ftmpnav1.Text = #9)) then
                fExtraCols := StringOfChar(Char(' '), pmMaxOf(X - ftmpnav1.DisplayX, 0) div fSpaceWidth)
            end;
            cp := ftmpnav1.Pos;

            if ssShift in Shift then
            begin
              fSelLen := fSelLen + (scp - cp);
              if fSelLen >= 0 then
              begin
                fSelStart.Assign(ftmpnav1);
                fSelStop.Pos := cp + fSelLen;
                fcp := fSelStart
              end else
              begin
                fSelStart.Pos := cp + fSelLen;
                fSelStop.Assign(ftmpnav1);
                fcp := fSelStop
              end;
              InvalidateLines(fcp.VisibleLineNumber, sline, False { True } )
            end else
            begin
              fSelStart.Assign(ftmpnav1);
              fSelStop.Assign(ftmpnav1);
              fcp := fSelStart end
          end;
          // not line selecting

          fUndoBreak := True;
          UpdateCaret(False);
          if fBlockSelection then
          begin
            fBlockStartCol := (fCaretX + fDisplayLeft - fLeftMargin) div fSpaceWidth;
            fBlockStopCol := fBlockStartCol
          end
        end  // not dragging
      end  // not display only
    end;
    // left button

    if not Focused then
      Windows.SetFocus(Handle);
    if Assigned(fOnAfterMouseDown) then
      OnAfterMouseDown(Self, Button, Shift, X, Y);

  finally
    Dec(fSelMoveUpdateCount);
    DoSelMove
  end;
end; // method MouseDown

{ overriden protected methods }

var CurrentX, CurrentY: Integer;

procedure TPlusMemo.MouseMove(Shift: TShiftState; X, Y: Integer);
var scp, cp, cline, sline: LongInt;

  procedure Scroll;
  var next: LongInt; xfake, yfake, del: Integer;
    scrolltype: TMouseScrollType;
    scrollmsg: TWMScroll;
  begin
    scrolltype := fMouseScroll;
    next := GetTickCount;
    repeat
      while (LongInt(GetTickCount) < next) and (fMouseScroll = scrolltype) do
        Application.ProcessMessages;
      Application.ProcessMessages;
      if fMouseScroll = scrolltype then
      begin
        case fScrollRate of
          1: del := 400;
          2: del := 300;
          3: del := 200;
          4: del := 130;
          5: del := 78;
          6: del := 48;
          7: del := 30
          else
            del := 0
        end;
        next := LongInt(GetTickCount) + del;
        xfake := CurrentX;
        yfake := CurrentY;
        scrollmsg.ScrollBar := 2;
        // no scrolling

        case fMouseScroll of
          msUp: begin
            scrollmsg.ScrollCode := SB_LINEUP;
            scrollmsg.ScrollBar := 0;
            yfake := -fScrollRate * 3;
          end;

          msDown: begin
            scrollmsg.ScrollCode := SB_LINEDOWN;
            scrollmsg.ScrollBar := 0;
            yfake := ClientHeight + fScrollRate * 3;
          end;

          msLeft: begin
            if fDisplayLeft > 0 then
            begin
              scrollmsg.ScrollCode := SB_LINEUP;
              scrollmsg.ScrollBar := 1
            end;
            xfake := -fScrollRate * 3;
          end;

          msRight: begin
            if fDisplayLeft < fMaxLineWidth - ClientWidth then
            begin
              scrollmsg.ScrollCode := SB_LINEDOWN;
              scrollmsg.ScrollBar := 1
            end;
            xfake := ClientWidth + fScrollRate * 3;
          end
        end;

        case scrollmsg.ScrollBar of
          0: WMVSCROLL(scrollmsg);
          1: WMHSCROLL(scrollmsg)
        end;

        MouseMove([ssLeft], xfake, yfake)
      end;

    until fMouseScroll <> scrolltype
  end;

var oldscrolltype: TMouseScrollType;
  lineselect: Boolean;
  sexcols: string;
begin
  CurrentX := X;
  CurrentY := Y;
  if fLockedCount > 0 then
  begin
    inherited MouseMove(Shift, X, Y);
    Exit
  end;

  try
    Inc(fSelMoveUpdateCount);
    fMouseNav.VisibleLineNumber := pmMaxOf((Y + fTopOrigin) div fLineHeight, 0);
    if fMouseNav.VisibleLineNumber - fDisplayTop.VisibleLineNumber >= fDisplayLines then
      fMouseNav.VisibleLineNumber := pmMaxOf(fDisplayTop.VisibleLineNumber + fDisplayLines - 1, 0);
    if not(pmpFormatted in fMouseNav.Par^.ParState) then
    begin
      inherited MouseMove(Shift, X, Y);
      Exit
    end;
    if Y <= fParagraphs.fVisibleLineCount * fLineHeight - fTopOrigin then
      fMouseNav.DisplayX := X
    else
      fMouseNav.Pos := fParagraphs.fTextLen;

    fMouseNav.RightOfDyn;

    if not fMouseDown then
    begin
      lineselect := X < fLeftMargin - 2 - fDisplayLeft;
      if lineselect and (not(pmoNoLineSelection in Options)) then
      begin
        lineselect := fStartLineSelection >= 0;
        fStartLineSelection := fMouseNav.VisibleLineNumber;
        if not lineselect then
        begin
          if not(fMouseInContext or fMouseInSel) then
            fCursor := Cursor;
        end;
        fMouseInSel := False;
        fMouseInContext := False
      end else
        { not line selection }
      begin
        if fStartLineSelection >= 0 then
        begin
          { replace the cursor }
          fStartLineSelection := -1;
          Cursor := fCursor
        end;
        if not(pmoNoDragnDrop in Options) then
          if (fMouseNav.Pos >= fSelStart.Pos) and (fMouseNav.Pos < fSelStop.Pos) and (not fBlockSelection) then
          begin
            if (not fMouseInSel) and (not(ReadOnly or DisplayOnly)) then
            begin
              fMouseInSel := True;
              if not fMouseInContext then
                fCursor := Cursor;
              fMouseInContext := False;
              Cursor := crArrow
            end
          end else if fMouseInSel then
          begin
            fMouseInSel := False;
            Cursor := fCursor
          end
      end;
      { not line selection }

      if not(fMouseInSel or (fStartLineSelection >= 0)) then
        with fMouseNav.DynAttr do
          if (fMouseNav.Pos < fParagraphs.fTextLen) and (DynStyle and $80 <> 0) and (Cursor <> crDefault) then
          begin
            if not fMouseInContext then
              fCursor := Self.Cursor;
            Self.Cursor := Cursor;
            fMouseInContext := True
          end else
          begin
            if fMouseInContext then
              Self.Cursor := fCursor;
            fMouseInContext := False
          end
    end;
    { not fMouseDown }

    if fMouseDown and (ssLeft in Shift) then
    begin
      if Y >= fParagraphs.fVisibleLineCount * fLineHeight - fTopOrigin then
        Y := fParagraphs.fVisibleLineCount * fLineHeight - fTopOrigin - 1;
      oldscrolltype := fMouseScroll;
      fMouseScroll := msNoScroll;
      if (X < 0) and ((X > -24) or (not fDragging)) then
        fMouseScroll := msLeft;
      if (X > ClientWidth) and ((X < ClientWidth + 24) or (not fDragging)) then
        fMouseScroll := msRight;

      if (Y < -3) and ((Y > -27) or (not fDragging)) then
        fMouseScroll := msUp;
      if (Y > ClientHeight) and ((Y < ClientHeight + 24) or (not fDragging)) then
        fMouseScroll := msDown;

      if fMouseScroll in [msUp, msDown] then
        if fDragging and ((X < -3) or (X > ClientWidth + 3)) then
          fMouseScroll := msNoScroll;

      case fMouseScroll of
        msLeft: fScrollRate := (-X) div 3;
        msRight: fScrollRate := (X - ClientWidth) div 3;
        msUp: fScrollRate := (-Y) div 3;
        msDown: fScrollRate := (Y - ClientHeight) div 3
      end;

      if (fMouseScroll <> msNoScroll) and (oldscrolltype <> fMouseScroll) then
        Scroll;

      if fMouseDown then
        if fStartLineSelection >= 0 then
        begin
          if fMouseNav.VisibleLineNumber < fStartLineSelection then
          begin
            cp := fMouseNav.Pos;
            scp := fSelStop.Pos - cp;
            sline := fSelStart.VisibleLineNumber;
            cline := fMouseNav.VisibleLineNumber
          end else if fMouseNav.VisibleLineNumber > fStartLineSelection then
          begin
            ftmpnav1.Assign(fMouseNav);
            if fMouseNav.VisibleLineNumber < fParagraphs.fVisibleLineCount - 1 then
              ftmpnav1.VisibleLineNumber := fMouseNav.VisibleLineNumber + 1
            else
              ftmpnav1.Col := High(ftmpnav1.Col);
            cp := ftmpnav1.Pos;
            scp := fSelStart.Pos - cp;
            sline := fSelStop.VisibleLineNumber;
            cline := ftmpnav1.VisibleLineNumber
          end else
          begin
            ftmpnav1.Assign(fMouseNav);
            if fMouseNav.VisibleLineNumber < fParagraphs.fVisibleLineCount - 1 then
              ftmpnav1.VisibleLineNumber := fMouseNav.VisibleLineNumber + 1
            else
              ftmpnav1.Col := High(ftmpnav1.Col);
            cp := fMouseNav.Pos;
            scp := ftmpnav1.Pos - cp;
            sline := fSelStart.VisibleLineNumber;
            cline := fSelStop.VisibleLineNumber
          end;

          if (SelStart <> cp) or (SelLength <> scp) then
          begin
            fSelLen := scp;
            if fSelLen < 0 then
            begin
              fSelStart.Pos := cp + fSelLen;
              fSelStop.Pos := cp;
              fcp := fSelStop end else
              begin
                fSelStart.Pos := cp;
                fSelStop.Pos := cp + fSelLen;
                fcp := fSelStart end;
            InvalidateLines(sline, cline, False);
            UpdateCaret(False);
          end
        end else
          { mouse down, but not line selection }
          if fDragging then
          begin
            if (CurrentY > 0) and (CurrentY < ClientHeight) and (CurrentX > 0) and (CurrentX < ClientWidth) then
            begin
              UpdateCaret(False);
              if fDraggingOutside then
              begin
                fDraggingOutside := False;
                if ssCtrl in Shift then
                  SetCursor(LoadCursor(HInstance, DragCopyCursor))
                else
                  SetCursor(Screen.Cursors[crDrag])
              end
            end else if (fMouseScroll = msNoScroll) and (not fDraggingOutside) then
            begin
              SetCursor(Screen.Cursors[crNoDrop]);
              fDraggingOutside := True
            end
          end else
            { not dragging }
          begin
            sline := fcp.VisibleLineNumber;
            scp := fcp.Pos;
            sexcols := fExtraCols;
            if fBlockSelection then
              fExtraCols := StringOfChar(Char(' '), pmMaxOf(X - fMouseNav.DisplayPos.X, 0) div fSpaceWidth)
            else
              fExtraCols := '';

            cline := fMouseNav.VisibleLineNumber;
            cp := fMouseNav.Pos;
            if (scp <> cp) or (sexcols <> fExtraCols) then
            begin
              fSelLen := scp + fSelLen - cp;
              if fBlockSelection then
                { refresh all lines part of old selection }
                InvalidateLines(fSelStart.VisibleLineNumber, fSelStop.VisibleLineNumber, False);

              if fSelLen < 0 then
              begin
                fSelStart.Pos := cp + fSelLen;
                fSelStop.Pos := cp;
                fcp := fSelStop end else
                begin
                  fSelStart.Pos := cp;
                  fSelStop.Pos := cp + fSelLen;
                  fcp := fSelStart end;
              if fBlockSelection then
                { refresh all lines part of new selection }
                InvalidateLines(fSelStart.VisibleLineNumber, fSelStop.VisibleLineNumber, False)
              else
                { refresh only lines newly added or removed from selection }
                InvalidateLines(sline, cline, False);
            end;

            if (fsPos <> fcp.Pos) or (sexcols <> fExtraCols) then
            begin
              UpdateCaret(False);
              if fBlockSelection then
                fBlockStopCol := (fCaretX + fDisplayLeft - fLeftMargin) div fSpaceWidth
            end;

            if fDblClick then
            begin
              if fMouseDownPos < cp then
              begin
                fSelStart.Pos := pmMinOf(fMouseDownPos, fSelStart.Pos);
                fSelStop.Assign(fMouseNav);
                fcp := fSelStop
              end else
              begin
                fSelStart.Assign(fMouseNav);
                fSelStop.Pos := pmMaxOf(fMouseDownPos, fSelStop.Pos);
                fcp := fSelStart
              end;
              SelectWords(fMouseNav.Pos >= fSelStop.Pos)
            end
          end { not dragging }

    end;
    { mouse down }
    inherited MouseMove(Shift, X, Y)

  finally
    Dec(fSelMoveUpdateCount);
    DoSelMove
  end;
end; { method MouseMove }

{ overriden protected methods }

procedure TPlusMemo.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var cn: DynInfoRec;
  cnstring: string;
  spos: TPoint;
  sdopopup: Boolean;
  sevents: TpmEvents;
begin
  if fDblClick then
  begin
    fExtraCols := '';
    UpdateCaret(False)
  end;
  fMouseDown := False;
  fDblClick := False;
  fMouseScroll := msNoScroll;

  if (Button = mbRight) and fMouseInSel then
  begin
    fMouseInSel := False;
    Cursor := fCursor
  end;

  CurrentX := X;
  CurrentY := Y;
  sdopopup := True;

  if fDragging then
  begin
    fDragging := False;
    Screen.Cursor := crDefault;
    Cursor := fCursor;
    if fSelLen > 0 then
      fcp := fSelStart
    else
      fcp := fSelStop;

    if not fDraggingOutside then
      if (fMouseNav.Pos >= fSelStart.Pos) and (fMouseNav.Pos < fSelStop.Pos) then
      begin
        SelStart := fMouseNav.Pos;
        if Assigned(fOnMove) then
          fOnMove(Self)
      end else
      begin
        cnstring := SelText;
        BeginUpdate;
        if not(ssCtrl in Shift) then
          SelText := ''
        else
          SelLength := 0;
        SelStart := fMouseNav.Pos;
        SelText := cnstring;
        SelLength := fMouseNav.Pos - SelStart;
        //pOffsetRangeRecord(fUndoList[fUndoLevel-1])^.Coupled:= not (ssCtrl in Shift);
        EndUpdate
      end;
    UpdateCaret(True);
    ScrollInView;
    fMouseInSel := False;
    MouseMove(Shift, X, Y);
    sdopopup := False
  end else
    // not dragging
    if (fMouseDownPos = fMouseNav.Pos) or (Button = mbRight) then
    begin
      cn := fMouseNav.DynAttr;
      if fMouseNav.Pos = fParagraphs.fTextLen then
        cn.DynStyle := 0;
      if (cn.DynStyle and $80 <> 0) and (cn.Context <> 0) then
      begin
        LastContext := cn.Context;
        if Button = mbRight then
          sevents := [pmeRightContext]
        else
          sevents := [pmeContext];
        DoNotify(fNotifyList, sevents);
        if Assigned(fOnContext) then
        begin
          ftmpnav1.Assign(fMouseNav);
          ftmpnav1.BackToDyn(0);
          ftmpnav2.Assign(fMouseNav);
          if not ftmpnav2.ForwardToDyn(fParagraphs.fTextLen) then
            ftmpnav2.Pos := fParagraphs.fTextLen;
          fOnContext(Self, cn.Context, ftmpnav1.Pos, ftmpNav2.Pos)
        end;
        sdopopup := LastContext <> 0
      end
    end;

  inherited MouseUp(Button, Shift, X, Y);
  if sdopopup and (Button = mbRight) and (PopupMenu = nil) and (not(pmoNoDefaultPopup in Options)) then
  begin
    if fInternalPopup = nil then
      CreatePopupMenu;
    spos := ClientToScreen(Point(X, Y));
    fInternalPopup.Popup(spos.X, spos.Y)
  end;
  if not fDisplayOnly and (Button = mbLeft) then
    ScrollInView;
end;

procedure TPlusMemo.DblClick; { overriden protected methods }
begin
  if not fDisplayOnly then
  begin
    fDblClick := True;
    SelectWords(True);
    UpdateCaret(False)
  end;
  inherited DblClick;
end;

procedure TPlusMemo.Loaded; { overriden protected methods }
begin
  inherited Loaded;
  ClearUndo;
  if (ApplyKeywords and (Keywords <> nil) and (Keywords.Count > 0)) or
    (ApplyStartStopKeys and (StartStopKeys <> nil) and (StartStopKeys.Count > 0)) or
    (Highlighter <> nil) then
    ReapplyKeywords
  else
    Reformat;
end;

procedure TPlusMemo.Notification(AComponent: TComponent; Operation: TOperation); { overriden protected methods }
var oldipms: IpmCollapseHandler;
begin
  if (Operation = opRemove) and (AComponent = CollapseHandler) and Assigned(AComponent) then
  begin
    if fCollpsComp.GetInterface(IpmCollapseHandler, oldipms) and (oldipms = fCollpsHandler) and Assigned(oldipms) then
      fCollpsHandler := nil;
    fCollpsComp := nil
  end;
  inherited Notification(AComponent, Operation)
end;

procedure TPlusMemo.WndProc(var Message: TMessage);
var slevel, sindex: Integer;
begin
  Inc(fWndProcLevel);
  slevel := fWndProcLevel;

  WinMsg := Message;
  if Assigned(fMsgList) then
    DoNotify(fMsgList, [pmeMessage]);

  if WinMsg.Result <> 127 then
    inherited WndProc(Message);

  sindex := gDestroyedMemoList.IndexOf(Self);
  if sindex < 0 then
  begin
    Dec(fWndProcLevel);
    if Assigned(fMsgList) then
    begin
      WinMsg := Message;
      DoNotify(fMsgList, [pmeAfterMessage])
    end
  end else if slevel = 1 then
    gDestroyedMemoList.Delete(sindex);
end;

{ overriden protected methods }

procedure TPlusMemo.KeyDown(var Key: Word; Shift: TShiftState);
var ProcessShift: Boolean;

  function IsArrowKey(k: Word): Boolean;
  begin
    Result := (k = VK_LEFT) or (k = VK_RIGHT) or (k = VK_DOWN) or (k = VK_UP)
  end;

  function indentlevel(lnb: LongInt): Word;
  var txt: string;
  begin
    txt := LinesArray[lnb];
    Result := 0;
    while (Result < Length(txt)) and ((txt[Result + 1] = ' ') or (txt[Result + 1] = #9)) do
      Inc(Result);
  end;

  procedure dokeyvmove;
  begin
    fExtraCols := '';
    if (not(pmoPersistentBlocks in Options)) and (not(ssShift in Shift)) then
    begin
      SelLength := 0;
      fBlockSelection := False
    end;
    if (fXCaretRunningPos = Low(fXCaretRunningPos)) or
      (not(WordWrap or (Options * [pmoKeepColumnPos, pmoPutExtraSpaces] <> [pmoPutExtraSpaces]))) then
      fXCaretRunningPos := fCaretX + fDisplayLeft;

    ftmpnav1.DisplayX := fXCaretRunningPos - fDisplayLeft;

    if (fBlockSelection or (pmoKeepColumnPos in Options)) and
      ((ftmpnav1.ParOffset = GetParLength(ftmpnav1.fPar^)) or (ftmpnav1.Text = #9)) and
      ((not(ssShift in Shift)) or fBlockSelection or (pmoPersistentBlocks in Options)) then
    begin
      CurrentX := ftmpnav1.DisplayX;
      if fXCaretRunningPos > CurrentX + fDisplayLeft then
        fExtraCols := StringOfChar(Char(' '), (fXCaretRunningPos - fDisplayLeft - CurrentX) div fSpaceWidth)
    end;
    ProcessShift := True
  end;

var
  sline: Integer;
  sk: Word;
  ilevel,
  icolpos: Integer;
  linenumber: Integer;
  backdone: Boolean;
  firstvline: Integer;
  sextra: Integer;
  snav1, snav2: TPlusNavigator;
  savedblock: TPoint;
  spmenu: TPopupMenu;
  spos: TPoint;

begin
  inherited KeyDown(Key, Shift);

  fBlockOperation := (fBlockOperation and (ssAlt in Shift)) or (Shift = [ssAlt, ssShift]);
  if fLockedCount > 0 then
    Exit;
  if fDragging then
  begin
    if (Key = VK_CONTROL) and (not fDraggingOutside) then
      SetCursor(LoadCursor(HInstance, DragCopyCursor));
    if Key = VK_ESCAPE then
      // cancel the drag operation
    begin
      Screen.Cursor := crDefault;
      Cursor := fCursor;
      fDragging := False;
      SelStart := fMouseNav.Pos;
    end;
    Exit
  end;

  fInternalScroll := True;
  if fDisplayOnly then
  begin
    { effect only display move }
    firstvline := FirstVisibleLine;
    case key of
      VK_HOME: LeftOrigin := 0;
      VK_END: LeftOrigin := pmMaxOf(fMaxLineWidth - ClientWidth + fRightMargin, 0);
      VK_PRIOR: if ssCtrl in Shift then
        FirstVisibleLine := 0
      else
        FirstVisibleLine := pmMaxOf(firstvline - fDisplayLines + 1, 0);

      VK_NEXT: if ssCtrl in Shift then
        FirstVisibleLine := pmMaxOf(LineCount - fDisplayLines + 1, 0)
      else
        FirstVisibleLine := pmMinOf(firstvline + fDisplayLines - 1, pmMaxOf(LineCount - fDisplayLines + 1, 0));

      VK_UP: FirstVisibleLine := pmMaxOf(firstvline - 1, 0);
      VK_DOWN: FirstVisibleLine := pmMinOf(firstvline + 1, pmMaxOf(LineCount - fDisplayLines + 1, 0));
      VK_LEFT: LeftOrigin := pmMaxOf(LeftOrigin - ClientWidth div 5 - 1, 0);
      VK_RIGHT: LeftOrigin := pmMinOf(LeftOrigin + ClientWidth div 5 + 1, pmMaxOf(fMaxLineWidth - ClientWidth + fRightMargin, 0))
    end;
    fInternalScroll := False;
    Exit
  end;

  { not DisplayOnly }
  if (ssCtrl in Shift) and (not(ssAlt in Shift)) then
  begin
    ProcessShift := True;
    fsStyle := GetCurrentStyle;
    fsPos := fcp.Pos;
    if (not fReadOnly) and fEnableHotKeys  then
    begin
      ProcessShift := False;
      case Key of
        $42: SetBold;
        $46: SetAltFont;
        $48: SetHighlight;
        $4A: SetItalic;
        //  v6.4c: changed from Ctrl-I to Ctrl-J to avoid conflict with Window's Tab shortcut
        $54: SetSelText(#9);
        { ctrl T mapped to a TAB }
        $55: SetUnderline;
        $50: SetSelText(#13#10#12);
        // ctrl-P as a page break
        $5A: if ssShift in Shift then
          Redo
        else
          Undo

        else
          ProcessShift := True end
    end;
    if not ProcessShift then
    begin
      ScrollInView;
      // v6.2c
      fInternalScroll := False;
      Key := 0;
      Exit
    end
  end;

  if (Key = VK_APPS) and ((PopupMenu <> nil) or (not(pmoNoDefaultPopup in Options))) then
  begin
    if fInternalPopup = nil then
      CreatePopupMenu;
    if PopupMenu <> nil then
      spmenu := PopupMenu
    else
      spmenu := fInternalPopup;
    spos := ClientToScreen(fcp.DisplayPos);
    spmenu.Popup(spos.X, spos.Y)
  end;

  if Key >= $30 then
    { VK code for '0', lowest value for normal typing }
  begin
    fInternalScroll := False;
    Exit { avoid case statement for text typing }
  end;

  sk := Key;
  Key := 0;
  FormatNow(fcp.ParNumber, fcp.ParNumber, False, False);
  ftmpnav1.Assign(fcp);
  ProcessShift := False;

  if (Shift = [ssAlt, ssShift]) and (pmoBlockSelection in Options) and
    (not WordWrap) and (not fBlockSelection) and (IsArrowKey(sk)) then
  begin
    fBlockSelection := True;
    fBlockStartCol := fcp.ParOffset + Length(fExtraCols);
    fBlockStopCol := fBlockStartCol
  end;

  Inc(fSelMoveUpdateCount);
  try
    case sk of
      VK_TAB: if ssAlt in Shift then
      begin
        Key := VK_TAB;
        fInternalScroll := False;
        Exit end;

      VK_HOME: if not(ssAlt in Shift) then
      begin
        fExtraCols := '';
        if not(pmoPersistentBlocks in Options) then
        begin
          fBlockSelection := False;
          if not(ssShift in Shift) then
            SelLength := 0
        end;
        if ssCtrl in Shift then
          ftmpnav1.Pos := 0
        else
          ftmpnav1.VisibleLineNumber := fcp.VisibleLineNumber;
        fXCaretRunningPos := Low(fXCaretRunningPos);
        ProcessShift := True
      end;

      VK_END: if not(ssAlt in Shift) then
      begin
        fExtraCols := '';
        if not(pmoPersistentBlocks in Options) then
        begin
          fBlockSelection := False;
          if not(ssShift in Shift) then
            SelLength := 0
        end;
        fXCaretRunningPos := Low(fXCaretRunningPos);
        if ssCtrl in Shift then
          ftmpnav1.Pos := fParagraphs.fTextLen
        else
          ftmpnav1.Col := High(ftmpnav1.Col);
        ProcessShift := True
      end;

      VK_PRIOR: if not(ssAlt in Shift) then
      begin
        ftmpnav1.VisibleLineNumber := pmMaxOf(fcp.VisibleLineNumber - fDisplayLines, 0);
        FormatNow(ftmpnav1.fParNb, fcp.fParNb, False, False);
        if (not(ssCtrl in Shift)) and (fCaretY >= 0) and (fCaretY < ClientHeight) then
          TopOrigin := pmMaxOf(0, TopOrigin - (fDisplayLines - 1) * fLineHeight);
        ftmpnav1.VisibleLineNumber := pmMaxOf(fcp.VisibleLineNumber - fDisplayLines + 1, 0);
        dokeyvmove
      end;

      VK_NEXT: if not(ssAlt in Shift) then
      begin
        ftmpnav1.VisibleLineNumber := pmMinOf(fcp.VisibleLineNumber + fDisplayLines - 1, fParagraphs.fVisibleLineCount - 1);
        FormatNow(fcp.fParNb, ftmpnav1.fParNb, False, False);
        if (not(ssCtrl in Shift)) and (fCaretY >= 0) and (fCaretY < ClientHeight) then
          TopOrigin := pmMinOf(TopOrigin + (fDisplayLines - 1) * fLineHeight,
            pmMaxOf(0, fParagraphs.fVisibleLineCount * fLineHeight - EditRect.Bottom + 3));
        ftmpnav1.VisibleLineNumber := pmMinOf(fcp.VisibleLineNumber + fDisplayLines - 1, fParagraphs.fVisibleLineCount - 1);
        dokeyvmove
      end;

      VK_UP: if (not(ssAlt in Shift)) or fBlockSelection then
        if fcp.VisibleLineNumber = 0 then
          inherited KeyDown(sk, Shift)
        else
        begin
          if fcp.fParLine = 0 then
            FormatNow(pmMaxOf(fcp.fParNb - 1, 0), fcp.fParNb - 1, False, False);
          ftmpnav1.VisibleLineNumber := pmMaxOf(fcp.VisibleLineNumber - 1, 0);
          dokeyvmove
        end;

      VK_DOWN: if (not(ssAlt in Shift)) or fBlockSelection then
        if fcp.VisibleLineNumber < fParagraphs.fVisibleLineCount - 1 then
        begin
          if fcp.fParLine = fcp.NavLines.Count - 1 then
            FormatNow(fcp.fParNb + 1, pmMinOf(fcp.fParNb + 1, fParagraphs.Count - 1), False, False);
          ftmpnav1.VisibleLineNumber := fcp.VisibleLineNumber + 1;
          dokeyvmove
        end;

      VK_LEFT:
        if (not(ssAlt in Shift)) or fBlockSelection then
        begin
          fXCaretRunningPos := Low(fXCaretRunningPos);
          if not(ssShift in Shift) and (not(pmoBlockSelection in Options)) then
          begin
            SelLength := 0;
            fBlockSelection := False
          end;
          if (ftmpnav1.Pos > 0) or (fExtraCols <> '') then
          begin
            if ssCtrl in Shift then
            begin
              fExtraCols := '';
              ftmpnav1.ToPreviousWord(Delimiters);
            end else if fExtraCols <> '' then
              fExtraCols := Copy(fExtraCols, 1, Length(fExtraCols) - 1)
            else
            begin
              backdone := False;
              if ftmpnav1.ParOffset > 0 then
              begin
                ftmpnav1.Pos := ftmpnav1.Pos - 1;
                backdone := True;
                if fPassOver and StaticFormat then
                begin
                  while (ftmpnav1.AnsiText in CtrlCodesSet) and (ftmpnav1.ParOffset > 0) do
                    ftmpnav1.Pos := ftmpnav1.Pos - 1;
                  backdone := not(ftmpnav1.AnsiText in CtrlCodesSet)
                end
              end;
              if (not fBlockSelection) and (not backdone) and (ftmpnav1.Pos > 0) then
              begin
                ftmpnav1.Pos := ftmpnav1.Pos - 2;
                if (pmoDiscardTrailingSpaces in Options) and (ftmpnav1.ParOffset > 0) then
                begin
                  ftmpnav1.Pos := ftmpnav1.Pos - 1;
                  while (not backdone) and (ftmpnav1.AnsiText in [' ', #9]) do
                  begin
                    if ftmpnav1.ParOffset > 0 then
                      ftmpnav1.Pos := ftmpnav1.Pos - 1
                    else
                      backdone := True
                  end;
                  if not backdone then
                    ftmpnav1.Pos := ftmpnav1.Pos + 1
                end
              end
            end;
            if not ftmpnav1.IsVisible then
            begin
              ftmpnav1.VisibleLineNumber := ftmpnav1.VisibleLineNumber - 1;
              ftmpnav1.Col := High(ftmpnav1.Col)
            end
          end { if cp>0 }
          else
            inherited KeyDown(sk, Shift);
          ProcessShift := True
        end;

      VK_RIGHT:
        if (not(ssAlt in Shift)) or fBlockSelection then
        begin
          fXCaretRunningPos := Low(fXCaretRunningPos);
          if not(ssShift in Shift) and (not(pmoPersistentBlocks in Options)) then
          begin
            SelLength := 0;
            fBlockSelection := False
          end;
          if ssCtrl in Shift then
          begin
            fExtraCols := '';
            if not(pmoLargeWordSelect in Options) and (ssShift in Shift) then
            begin
              // go until end of current word or next word, if we're already there
              ilevel := ftmpnav1.Pos;
              ftmpnav1.ToEndOfWord(Delimiters);
              if ftmpnav1.Pos = ilevel then
              begin
                ftmpnav1.ToNextWord(Delimiters);
                if (ftmpnav1.ParNumber > fcp.ParNumber) and (fcp.ParOffset < GetParLength(fcp.Par^)) then
                  ftmpnav1.Pos := ftmpnav1.Pos - 2
                else
                  ftmpnav1.ToEndOfWord(Delimiters)
              end
            end else
              ftmpnav1.ToNextWord(Delimiters)
          end else
          begin
            if (ftmpnav1.ParOffset = GetParLength(ftmpnav1.Par^)) and
              ((pmoKeepColumnPos in Options) and (not(pmoWrapCaret in Options)) or fBlockSelection) then
              fExtraCols := fExtraCols + ' '
            else if ftmpnav1.pos < CharCount then
            begin
              fExtraCols := '';
              if StaticFormat and fPassOver then
                while (ftmpnav1.Pos < CharCount) and (ftmpnav1.AnsiText in CtrlCodesSet) do
                  ftmpnav1.Pos := ftmpnav1.Pos + 1;
              if (pmoDiscardTrailingSpaces in Options) and (not fBlockSelection) then
              begin
                { reach the end of paragraph if only spaces remain }
                while (ftmpnav1.Pos < CharCount) and (ftmpnav1.AnsiText in [' ', #9]) do
                  ftmpnav1.Pos := ftmpnav1.Pos + 1;
                if (ftmpnav1.Pos < CharCount) and (ftmpnav1.Text <> #13) then
                  ftmpnav1.Pos := fcp.Pos
              end;
              if ftmpnav1.Pos < CharCount then
                if ftmpnav1.Text = #13 then
                  ftmpnav1.Pos := ftmpnav1.Pos + 2
                else
                  ftmpnav1.Pos := ftmpnav1.Pos + 1;
            end
          end;
          if not ftmpnav1.IsVisible then
            ftmpnav1.VisibleLineNumber := ftmpnav1.VisibleLineNumber;
          ProcessShift := True
        end;

      VK_DELETE:
        if not fReadOnly then
        begin
          if (SelLength = 0) and (pmoKeepColumnPos in Options) then
            sextra := fCaretX
          else
            sextra := Low(sextra);
          if ssShift in Shift then
          begin
            if fSelLen <> 0 then
            begin
              CutToClipboard;
              ScrollInView;
              fInternalScroll := False;
              Exit
            end else if fcp.ParOffset = 0 then
              SelLength := -2
            else
              SelLength := -1;
          end else if (ssCtrl in Shift) and (fSelStart.TrueLineNumber = fSelStop.TrueLineNumber) then
          begin
            fSelStop.Col := High(fSelStop.Col);
            fcp := fSelStart;
            fSelLen := fSelStop.Pos - fSelStart.Pos;
            ClearSelection
          end else
          begin
            fNoPaint := True;
            if pmoNoOverwriteBlocks in Options then
              PrepareKeepBlock(snav1, snav2, savedblock);
            if SelLength = 0 then
              if fcp.ParOffset = GetParLength(fcp.Par^) then
                SelLength := 2
              else
              begin
                if StaticFormat then
                  while (fcp.Pos + SelLength < fParagraphs.fTextLen) and
                    (pmChar(Chars[fcp.Pos + SelLength]) in CtrlCodesSet) do
                    SelLength := SelLength + 1;
                if fSelStop.ParOffset = GetParLength(fSelStop.Par^) then
                  SelLength := SelLength + 2
                else
                  SelLength := SelLength + 1
              end;
            fNoPaint := False;
            ClearSelection;
            if (not WordWrap) and (pmoKeepColumnPos in Options) then
              if sextra > fCaretX then
                fExtraCols := StringOfChar(Char(' '), (sextra - fCaretX) div fSpaceWidth);
            if pmoNoOverwriteBlocks in Options then
              EndKeepBlock(snav1, snav2, savedblock)
          end;
          ScrollInView
        end;

      VK_BACK:
        begin
          fXCaretRunningPos := Low(fXCaretRunningPos);
          if not fReadOnly then
          begin
            fNoPaint := True;
            if pmoNoOverwriteBlocks in Options then
              PrepareKeepBlock(snav1, snav2, savedblock);
            if SelLength = 0 then
              if ssCtrl in Shift then
              begin
                ftmpnav1.ToPreviousWord(Delimiters);
                SelLength := ftmpnav1.Pos - fcp.Pos;
              end else if (fcp.ParOffset = 0) and (fExtraCols = '') then
                SelLength := -2
              else
              begin
                if pmoBackIndent in Options then
                begin
                  icolpos := SelCol;
                  linenumber := SelLine;
                  if (icolpos > 0) and (indentlevel(linenumber) = icolpos) then
                  begin
                    ilevel := icolpos;
                    while (linenumber >= 0) and (ilevel >= icolpos) do
                    begin
                      Dec(linenumber);
                      if linenumber >= 0 then
                        ilevel := indentlevel(linenumber)
                      else
                        ilevel := 0
                    end;
                    SelLength := ilevel - icolpos
                  end
                end;
                if SelLength = 0 then
                  if fExtraCols <> '' then
                    Delete(fExtraCols, Length(fExtraCols), 1)
                  else
                  begin
                    SelLength := -1;
                    if StaticFormat then
                      while (fcp.Pos + SelLength > 0) and (pmChar(Chars[fcp.Pos + SelLength]) in CtrlCodesSet) do
                        if fSelStart.ParOffset = 0 then
                          SelLength := SelLength - 2
                        else
                          SelLength := SelLength - 1
                  end
              end;

            fNoPaint := False;
            if SelLength <> 0 then
            begin
              icolpos := fSelStart.Col;
              sextra := fSelStart.ParLine;
              ClearSelection;
              if (pmoKeepColumnPos in Options) and (fSelStart.ParLine = sextra) then
                fExtraCols := StringOfChar(Char(' '), icolpos - fSelStart.Col)
            end;
            if pmoNoOverwriteBlocks in Options then
              EndKeepBlock(snav1, snav2, savedblock);
            ScrollInView
          end
        end;

      VK_INSERT:
        begin
          if not(ssAlt in Shift) then
          begin
            if (ssShift in Shift) and (not fReadOnly) then
              PasteFromClipboard
            else if ssCtrl in Shift then
              CopyToClipboard
            else if pmoInsertKeyActive in Options then
            begin
              Overwrite := not Overwrite;
              if Assigned(fOnStyleChange) then
                OnStyleChange(Self)
            end;
            ScrollInView;
            fInternalScroll := False;
            Exit
          end
        end else
        begin
          Key := sk;
          fInternalScroll := False;
          Exit end
    end;

    if ProcessShift then
    begin
      if ssShift in Shift then
      begin
        { extend selection and repaint }
        sline := fcp.VisibleLineNumber;
        if pmoPersistentBlocks in Options then
          if fcp.Pos = fSelStart.Pos then
            fSelLen := fSelStop.Pos - fSelStart.Pos
          else if fcp.Pos = fSelStop.Pos then
            fSelLen := fSelStart.Pos - fSelStop.Pos
          else
          begin
            SelLength := 0;
            fcp := fIndependantCPNav
          end;

        if fBlockSelection then
          { refresh all lines part of old selection }
          InvalidateLines(fSelStart.VisibleLineNumber, fSelStop.VisibleLineNumber, False);
        fSelLen := fSelLen + (fcp.Pos - ftmpnav1.Pos);
        if fSelLen >= 0 then
        begin
          fSelStart.Assign(ftmpnav1);
          fSelStop.Pos := ftmpnav1.Pos + fSelLen;
          fcp := fSelStart end else
          begin
            fSelStart.Pos := ftmpnav1.Pos + fSelLen;
            fSelStop.Assign(ftmpnav1);
            fcp := fSelStop end;
        if fBlockSelection then
          { refresh all lines part of new selection }
          InvalidateLines(fSelStart.VisibleLineNumber, fSelStop.VisibleLineNumber, False)
        else
          InvalidateLines(fcp.VisibleLineNumber, sline, False);
        { just invalidate added or removed selection lines }
      end else if (fSelLen <> 0) and (pmoPersistentBlocks in Options) then
      begin
        fIndependantCpNav.Assign(ftmpnav1);
        fcp := fIndependantCpNav
      end else
      begin
        SelLength := 0;
        fSelStart.Assign(ftmpnav1);
        fSelStop.Assign(ftmpnav1);
        fcp := fSelStart
      end;
    end;

    fUndoBreak := True;
    if fBlockSelection and (ssShift in Shift) then
      fBlockStopCol := (fCaretX + fDisplayLeft - fLeftMargin) div fSpaceWidth;
    UpdateCaret(False);
    ScrollInView;
    fReceivedKeyUp := False;
    Update;

  finally
    fInternalScroll := False;
    Dec(fSelMoveUpdateCount);
    DoSelMove
  end;
end; { method KeyDown }

procedure TPlusMemo.KeyPress { UCONVERT } (var Key: Char) { /UCONVERT } ; { overriden protected methods }

var linetext: string;
  ilevel, colpos: Word;
  sline: LongInt;
  snav1, snav2: TPlusNavigator;
  savedblock: TPoint;
begin
  inherited KeyPress(Key);
  if fBlockOperation then
  begin
    fBlockOperation := False;
    Exit
  end;

  if (fLockedCount > 0) or (fDragging) then
    Exit;
  if (fReadOnly and (Key <> #3)) or fDisplayOnly then
    exit;

  fInternalScroll := True;
  snav1 := nil;
  if (pmoNoOverwriteBlocks in Options) and (not(AnsiChar(Key) in [#3, #22, #24])) then
    PrepareKeepBlock(snav1, snav2, savedblock);
  { we avoid PrepareKeepBlock for those keys because
                                                - it is not valid for CopyToClipboard (#3);
                                                - it is already managed for PasteFromClipboard (#22);
                                                - it is not valid for CutToClipboard (#24) }

  if (Key > #30) and (Key <> #127) then
  begin
    if Overwrite and (fSelLen = 0) and (fcp.ParOffset < GetParLength(fcp.fPar^)) then
      SelLength := 1;
    if (Key = ' ') and (SelLength = 0) and (pmoDiscardTrailingSpaces in Options) and
      (fcp.ParOffset = GetParLength(fcp.fPar^)) then
    begin
      fExtraCols := fExtraCols + ' ';
      if snav1 <> nil then
        Dec(fLockedCount);
      // make UpdateCaret effective
      UpdateCaret(False);
      if snav1 <> nil then
        Inc(fLockedCount)
    end else
      SelText := Char(Key)
  end else
  begin
    case Key of
      #13:
        if Overwrite and (SelLength = 0) then
          if SelLine < fParagraphs.fTrueLineCount - 1 then
          begin
            ftmpnav1.TrueLineNumber := SelLine;
            ftmpnav1.VisibleLineNumber := ftmpnav1.VisibleLineNumber + 1;
            SelLine := ftmpnav1.TrueLineNumber;
            //ScrollInView  // v6.2c
          end else
          begin
            SelStart := fParagraphs.fTextLen;
            SelText := #13#10 end else if (SelLength <> 0) or (not(pmoAutoIndent in Options)) then
              SelText := #13#10
            else
            begin
              { autoindent }
              sline := SelLine;
              while (sline >= 0) and (Length(linetext) = 0) do
              begin
                linetext := LinesArray[sline];
                Dec(sline)
              end;
              colpos := SelCol;
              ilevel := 0;
              while (ilevel < Length(linetext)) and (pmChar(linetext[ilevel + 1]) in [' ', #9]) do
                Inc(ilevel);
              if ilevel >= colpos then
                ilevel := colpos;
              if (pmoDiscardTrailingSpaces in Options) and (fcp.ParOffset = GetParLength(fcp.fPar^)) then
              begin
                SelText := #13#10;
                fExtraCols := '';
                if fTabStops <= 0 then
                  fExtraCols := StringOfChar(Char(' '), ilevel)
                else
                  for colpos := 1 to ilevel do
                    if linetext[colpos] = #9 then
                      fExtraCols := fExtraCols + StringOfChar(Char(' '), TabStops)
                    else
                      fExtraCols := fExtraCols + ' ';
                if snav1 <> nil then
                  Dec(fLockedCount);
                // make UpdateCaret effective
                UpdateCaret(False);
                //ScrollInView;    v6.2c
                if snav1 <> nil then
                  Inc(fLockedCount);
              end else
                SelText := #13#10 + Copy(linetext, 1, ilevel);
            end;

      #5: begin
        Invalidate;
        CheckIntegrity end;
      { ctrl-e }
      #1: begin
        SelectAll;
        Exit end;
      // avoid ScrollInView
      #3: begin
        CopyToClipboard;
        Exit end;
      //  avoid ScrollInView
      #22: PasteFromClipboard;
      #24: CutToClipboard;
      #9: if pmoSmartTabs in Options then
        SelText := SelText + SmartTabText
      else if (SelLength = 0) and (pmoDiscardTrailingSpaces in Options) and
      (fcp.ParOffset = GetParLength(fcp.fPar^)) then
      begin
        fExtraCols := fExtraCols + #9;
        if snav1 <> nil then
          Dec(fLockedCount);
        // make UpdateCaret effective
        UpdateCaret(False);
        if snav1 <> nil then
          Inc(fLockedCount)
      end else
        SelText := #9
    end
  end;

  if snav1 <> nil then
    EndKeepBlock(snav1, snav2, savedblock);
  ScrollInView;
  // v6.2c
  fInternalScroll := False;

  { we want to updtate the window if the user keeps a key pressed, so that he sees the effect as the chars accumulate.
    But we don't want if he presses different keys, as this will permit the control to catch up with typing from
    time to time, something which would not be done if so many paint messages are processed }
  if not fReceivedKeyUp then
    Update
  else
    fReceivedKeyUp := False
end;

{ overriden protected methods }

procedure TPlusMemo.KeyUp(var Key: Word; Shift: TShiftState);
begin
  fReceivedKeyUp := True;
  inherited KeyUp(Key, Shift);
  if fDragging and (Key = VK_CONTROL) and (not fDraggingOutside) then
    Screen.Cursor := crDrag
end;

procedure TPlusMemo.CreateHandle; { overriden protected methods }
begin
  inherited;
    {$IFDEF TPLUSMEMOU}
      {$IFNDEF D2009Up}
  if Win32Platform >= VER_PLATFORM_WIN32_NT then
    // make it receive Unicode
    SetWindowLongW(Handle, GWL_WNDPROC, GetWindowLong(Handle, GWL_WNDPROC));
      {$ENDIF}
    {$ENDIF}

  fExtraCols := '';
  fXCaretRunningPos := Low(fXCaretRunningPos);
  fLineBmp := TBitmap.Create;
  fLineBmp.HandleType := bmDDB;
  fLineWidth := ClientWidth;
  if fVertScrollBar <> nil then
    fLineWidth := fLineWidth - fVertScrollBar.Width;
  fLineBmp.Width := fLineWidth;
  UpdateFontDependantFields;

//  umBackground commented out until fixed
//  if (not(csDesigning in ComponentState)) and (UpdateMode = umBackground) then
//  begin
//    fFormatThread := TpmFormatThread.Create(Self);
//  end;

  Reformat;
  fDisplayLeft := 0;
  fTopOrigin := 0;
  fDisplayTop.VisibleLineNumber := 0;
  SetVScrollParams;
  SetHScrollParams;
  if fAutoCaretWidth then
    CaretWidth := 0
  else
    CaretWidth := CaretWidth;
  if fVScrollBar then
    SetScrollPos(Handle, SB_VERT, fTopOrigin div fVScrollFact, True);
  if fHScrollBar then
    SetScrollPos(Handle, SB_HORZ, 0, True);
  if Assigned(fOnVScroll) then
    fOnVScroll(Self);

end;

procedure TPlusMemo.DestroyWindowHandle;
begin
  FreeAndNil(fLineBmp);
  if Assigned(fFormatThread) then
  begin
    fFormatThread.PutToEnd;
    fFormatThread := nil
  end;
  inherited
end;

{ overriden protected methods }

procedure TPlusMemo.CreateParams(var p: TCreateParams);
begin
  inherited CreateParams(p);
  if fVScrollBar then
    p.Style := p.Style or WS_VSCROLL;
  if fHScrollBar then
    p.Style := p.Style or WS_HSCROLL;
  if FBorderStyle = bsSingle then
    if NewStyleControls and Ctl3D then
    begin
      p.Style := p.Style and not WS_BORDER;
      p.ExStyle := p.ExStyle or WS_EX_CLIENTEDGE;
    end else
      p.Style := p.Style or WS_BORDER;
  if Win32Platform >= VER_PLATFORM_WIN32_NT then
    // make it receive Unicode
    p.WindowClass.lpfnWndProc := @DefWindowProcW;
end;

{ ************* message handlers ************************ }

procedure TPlusMemo.PMUpdateBkg(var m: TMessage);
  { reformat a chunck of paragraphs for 25ms, normally called from within TpmFormatThread.Execute }
var
  dummy1, dummy2: Integer;
  oldfont: THandle; w, soldw: Integer;
  apar: pParInfo;
  loffset, vloffset, nextstartline, newlinecount, chunckstart, newoffset: Integer;
  initdone: Boolean;
  chuncktime: Cardinal;
  dch: TCanvas;

  newtop: Integer;
begin
  if (fLockedCount > 0) or (IParList.fUpdateStartPar >= IParList.Count) then
    Exit;
  { if IParList.fUpdateStartPar>=IParList.Count then
  {  begin
      if Assigned(fFormatThread) and (not fFormatThread.Suspended) then fFormatThread.Suspend;
      Exit
    end; }
  initdone := False;
  soldw := fMaxLineWidth;
  if fCanvas = nil then
  begin
    if fLineBmp <> nil then
    begin
      w := fLineWidth;
      dch := Canvas end else
      begin
        w := Width;
        dch := nil end
  end else
  begin
    dch := fCanvas;
    w := fw
  end;

  apar := IParList.Pointers[IParList.fUpdateStartPar];
  nextstartline := apar.StartLine;
  loffset := 0;
  vloffset := 0;
  chunckstart := IParList.fUpdateStartPar;
  {$IFDEF PMDEBUG} OutputDebugString( { UCONVERT } PChar { /UCONVERT } ('Chuncking ' + IntToStr(chunckstart)));
{$ENDIF}

  chuncktime := GetTickCount + 25;

  while (IParList.fUpdateStartPar <= IParList.fUpdateStopPar) and (chuncktime > GetTickCount) do
  begin
    if not(pmpFormatted in apar^.ParState) then
    begin
      if not(pmpSSDone in apar^.ParState) then
        ParseStartStopNow(IParList.fUpdateStartPar);
      dummy1 := 0;
      ReformatParP(Self, dch, not initdone, w, apar, IParList.fUpdateStartPar, dummy1, dummy2, True, oldfont,
        fRunningSpaceWidth, fSpaceKern, newoffset, newlinecount);
      initdone := True;
      Inc(loffset, newoffset);
    end else
    begin
      newlinecount := GetLineCount(apar^);
      newoffset := 0
    end;

    Inc(IParList.fUpdateStartPar);
    if not(pmpHidden in apar^.ParState) then
    begin
      Inc(nextstartline, newlinecount);
      Inc(vloffset, newoffset)
    end;

    if IParList.fUpdateStartPar < IParList.Count then
    begin
      apar := IParList.Pointers[IParList.fUpdateStartPar];
      apar^.StartLine := nextstartline;
    end;
  end;
  { chunck }

  if initdone then
  begin
    if fStartLineSelection > nextstartline then
      Inc(fStartLineSelection, vloffset);

    for w := 0 to fNavigators.Count - 1 do
      with TPlusNavigator(fNavigators[w]) do
        if (fPar <> nil) and (fParNb >= chunckstart) and (fParNb < IParList.fUpdateStartPar) then
          fParLine := -1;

    Inc(fParagraphs.fTrueLineCount, loffset);
    Inc(fParagraphs.fVisibleLineCount, vloffset);
    if ((not WordWrap) or (ColumnWrap > 0)) and (fMaxLineNumber >= IParList.fUpdateStartPar) then
      Inc(fMaxLineNumber, loffset);
    if vloffset <> 0 then
    begin
      fParagraphs.UpdateLines(fParagraphs.fUpdateStartPar + 1, vloffset);
      SetVScrollParams
    end;

    newtop := DisplayStartNav.VisibleLineNumber * fLineHeight + TopOrigin mod fLineHeight;

    if newtop <> fTopOrigin then
    begin
      fTopOrigin := newtop;
      if fVScrollBar then
        SetScrollPos(Handle, SB_VERT, fTopOrigin div fVScrollFact, True)
    end;

    if (CurrentPosNav.fParLine < 0) and (fLineBmp <> nil) then
      UpdateCaret(False);

    if (fMaxLineWidth <> soldw) and ((not WordWrap) or (ColumnWrap > 0)) then
    begin
      SetHScrollParams;
      if fHScrollBar then
        SetScrollPos(Handle, SB_HORZ, LeftOrigin div fHScrollfact, True);
    end;
  end;
  { if initdone }

  if Assigned(OnProgress) and (GetTickCount - fLastProgress > ProgressInterval) then
  begin
    OnProgress(Self);
    fLastProgress := GetTickCount
  end;

{$IFDEF PMDEBUG}
  CheckIntegrity;
{$ENDIF}

  if IParList.fUpdateStartPar > IParList.fUpdateStopPar then
  begin
    IParList.fUpdateStopPar := -1;
    IParList.fUpdateStartPar := IParList.Count;
    if Assigned(OnProgress) then
      OnProgress(Self);
  end else if not Application.Terminated then
    fFormatThread.FormatEvent.SetEvent
end; { message pmUpdateBkgnd }

{$IFDEF TPLUSMEMOU}
{$ENDIF}

procedure TPlusMemo.WMSetFocus; { message handlers }
begin
  inherited;
  fFocused := True;
  if not fDisplayOnly then
  begin
    CreateCaret(Handle, 0, GetCaretWidth, fLineHeight);
    PlaceCaret;
    ShowCaret(Handle)
  end;
  if HideSelection and (fSelLen <> 0) and (fLockedCount = 0) then
    InvalidateLines(fSelStart.VisibleLineNumber, fSelStop.VisibleLineNumber, False);
end;

procedure TPlusMemo.WMKillFocus; { message handlers }
begin
  inherited;
  fFocused := False;
  if not fDisplayOnly then
    DestroyCaret;
  if HideSelection and (fSelLen <> 0) and (fLockedCount = 0) then
    InvalidateLines(fSelStart.VisibleLineNumber, fSelStop.VisibleLineNumber, False);
end;

{ message handlers }

procedure TPlusMemo.WMGetDlgCode(var Message: TWMGetDlgCode); { message handlers }
begin
  inherited;
  Message.Result := DLGC_WANTARROWS or DLGC_WANTCHARS or DLGC_WANTALLKEYS;
  if fWantTabs and (not fDisplayOnly) then
    Message.Result := Message.Result or DLGC_WANTTAB
end;

procedure TPlusMemo.WMCut(var Message: TMessage); { message handlers }
begin
  CutToClipboard;
  ScrollInView  // v6.2f
end;

procedure TPlusMemo.WMCopy(var Message: TMessage); { message handlers }
begin
  CopyToClipboard;
end;

procedure TPlusMemo.WMPaste(var Message: TMessage); { message handlers }
begin
  PasteFromClipboard;
  ScrollInView   // v6.2f
end;

procedure TPlusMemo.WMUndo(var Message: TMessage); { message handlers }
begin
  Undo;
end;

procedure TPlusMemo.WMVScroll(var m: TWMScroll); { message handlers }
begin
  fInternalScroll := True;
  m.Result := 0;
  if fLockedCount > 0 then
    Exit;
  with fDisplayTop do
    case m.ScrollCode of
      SB_LINEDOWN: if (fDisplayTop.VisibleLineNumber < fParagraphs.fVisibleLineCount - 1) and
        (fDisplayTop.VisibleLineNumber < fParagraphs.fVisibleLineCount - fDisplayLines + 2) then
          TopOrigin := (fDisplayTop.VisibleLineNumber + 1) * fLineHeight;

      SB_LINEUP: if fTopOrigin > 0 then
        if fTopOrigin mod fLineHeight <> 0 then
          FirstVisibleLine := FirstVisibleLine
        else
          TopOrigin := (fDisplayTop.VisibleLineNumber - 1) * fLineHeight;
      SB_PAGEUP:
        begin
          ftmpnav1.Assign(fDisplayTop);
          with ftmpnav1 do
            VisibleLineNumber := pmMaxOf(VisibleLineNumber - fDisplayLines + 2, 0);
          FormatNow(ftmpnav1.ParNumber, ParNumber - 1, False, False);
          TopOrigin := pmMaxOf(fDisplayTop.VisibleLineNumber - fDisplayLines + 2, 0) * fLineHeight
        end;

      SB_PAGEDOWN:
        TopOrigin := pmMinOf((fDisplayTop.VisibleLineNumber + fDisplayLines - 1) * fLineHeight,
          pmMaxOf(0, fParagraphs.fVisibleLineCount * fLineHeight - ClientHeight + 3));

      SB_THUMBTRACK: if pmoNoFineScroll in Options then
        TopOrigin := Round(m.Pos * fVScrollFact / fLineHeight) * fLineHeight
      else
        TopOrigin := m.Pos * fVScrollFact;

      SB_TOP: TopOrigin := 0;
      SB_BOTTOM: TopOrigin := pmMaxOf(LineCount - fDisplayLines + 2, 0) * fLineHeight
    end;

  Update;
  fInternalScroll := False
end; { message WM_VSCROLL }

procedure TPlusMemo.WMHScroll(var m: TWMScroll); { message handlers }
begin
  fInternalScroll := True;
  m.Result := 0;
  if fLockedCount > 0 then
    Exit;
  case m.ScrollCode of
    SB_LINEDOWN: LeftOrigin := LeftOrigin + ClientWidth div 20 + 1;
    SB_LINEUP: LeftOrigin := pmMaxOf(LeftOrigin - ClientWidth div 20 - 1, 0);
    SB_PAGEUP: LeftOrigin := pmMaxOf(LeftOrigin - (ClientWidth - ClientWidth div 20), 0);
    SB_PAGEDOWN: LeftOrigin := LeftOrigin + ClientWidth - ClientWidth div 20;
    SB_THUMBTRACK: SetTopLeft(TopOrigin, m.Pos * fHScrollFact, 0);
    SB_TOP: LeftOrigin := 0;
    SB_BOTTOM: LeftOrigin := pmMaxOf(fMaxLineWidth - fLineWidth + 2 + fLeftMargin + fRightMargin, 0)
  end;
  Update;
  fInternalScroll := False
end;

procedure TPlusMemo.WMSetCursor(var Message: TWMSetCursor); { message handlers }
begin
  if (Message.CursorWnd = Handle) and (Message.HitTest = HTCLIENT) and (fStartLineSelection >= 0) then
  begin
    Windows.SetCursor(PMRightArrowCur);
    Message.Result := 1
  end else
    inherited
end;

procedure TPlusMemo.WMEraseBkgnd; { message handlers }
begin
  Message.Result := 1 { no need to paint background }
end;

procedure TPlusMemo.WMPaint; { message handlers }

var dc: pmHDC; // the device context we have to paint on
  InSel: Boolean;
  sKeepParBackgnd: Boolean;
  t: PChar;
  par: pParInfo;
  lin: LineInfo;
  pardyncount: Integer;
  sstyle: TFontStyles;
  currentattr: TFontStyles;
  currentdyn: DynInfoRec;
  curdynnb: Integer;
  currentuppercase: Boolean;
  sustart: Integer;
  stemppos: TPoint;
  sdisplaystartoff,
  sdisplaystopoff: Integer;
  sworkcanvas: TCanvas;
  oldpen: THandle;

  procedure SetCanvasColors(ACanvas: TCanvas);
  var t, b, sf, sb: LongInt;
  begin
    t := Font.Color;
    b := -1;
    { Transparent }
    sf := pmsGetParForegnd(par^);
    if sKeepParBackgnd then
      sb := pmsGetParBackgnd(par^)
    else
      sb := -1;
    if sf = clNone then
      sf := -1;
    if sb = clNone then
      sb := -1;
    if sf <> -1 then
      t := sf;

    if TPlusFontStyle(fsHighlight) in TPlusFontStyles(currentattr) then
    begin
      t := HighlightColor;
      b := HighlightBackgnd
    end;

    with currentdyn do
      if (DynStyle and $80 <> 0) and ((Foregnd <> 0) or (Backgnd <> 0)) then
      begin
        if (sf = -1) and (Foregnd <> -1) and (Foregnd <> clNone) then
          t := Foregnd;
        if (sb = -1) and (Backgnd <> -1) and (Backgnd <> clNone) then
          b := Backgnd
      end;

    if InSel and (Focused or not fHideSelection) then
    begin
      t := SelTextColor;
      b := -1
    end;

    ACanvas.Font.Color := t;
    if b <> -1 then
    begin
      ACanvas.Brush.Style := bsSolid;
      ACanvas.Brush.Color := b
    end else
      ACanvas.Brush.Style := bsClear;
  end;

  procedure SetDC(var Offset: Integer; Maxoffset: Integer; Fetch, ForceSet: Boolean);
  var fontchanged: Boolean; ss: TFontStyles; sdnb: Integer;
  begin
    if Fetch then
    begin
      currentattr := lin.StartAttrib;
      curdynnb := lin.StartDynNb;
      if curdynnb = 0 then
        currentdyn := GetStartDynAttrib(par^)^
      else
        currentdyn := par.ParExtra.DynCodes[curdynnb - 1];
      InSel := (sdisplaystartoff < sdisplaystopoff) and (offset >= sdisplaystartoff) and (offset < sdisplaystopoff)
    end;

    if StaticFormat then
      while (Offset < Maxoffset) and (t[offset] <= #26) and (AnsiChar(t[offset]) in CtrlCodesSet) do
      begin
        Fetch := True;
        XORStyleCode(currentattr, t[offset]);
        Inc(offset)
      end;

    sdnb := curdynnb;
    while (curdynnb < pardyncount) and (par^.ParExtra.DynCodes[curdynnb].DynOffset <= offset) do
      Inc(curdynnb);

    if sdnb <> curdynnb then
    begin
      Fetch := True;
      currentdyn := par^.ParExtra.DynCodes[curdynnb - 1];
    end;

    if Fetch then
    begin
      ss := sstyle;
      sstyle := AttrToExtFontStyles(currentattr, currentdyn.DynStyle);
      fontchanged := ForceSet or (ss <> sstyle);
      currentuppercase := KeywordsUpperCase and (currentdyn.DynStyle and $80 <> 0) and (currentdyn.Level >= 0) and
        (currentdyn.KeyIndex[currentdyn.Level] >= 0)
    end else
      fontchanged := False;

    if Byte(sstyle) and $80 <> 0 then
    begin
      if sustart = High(sustart) then
        sustart := stemppos.X
    end else if sustart <> High(sustart) then
    begin
      if oldpen = 0 then
        oldpen := SelectObject(dc, fSpecUnderlinePen.Handle);
      WavyLine(dc, sustart, stemppos.X, fWavyLinePos + stemppos.Y - fLineBase, fWavyLineAmplitude);
      sustart := High(sustart)
    end;

    if sdisplaystartoff < sdisplaystopoff then
      if InSel then
      begin
        if offset >= sdisplaystopoff then
        begin
          InSel := False;
          Fetch := True
        end
      end else if (offset >= sdisplaystartoff) and (offset < sdisplaystopoff) then
      begin
        InSel := True;
        Fetch := True
      end;

    if Fetch then
    begin
      if fontchanged then
        SetupFont(sworkcanvas.Font, sstyle);
      SetCanvasColors(sworkcanvas);
      dc := sworkcanvas.Handle
    end

  end;

  procedure getwords(var offset: Integer; maxoffset: Integer);
  var soffset: Integer; st: PChar;
  begin
    if curdynnb < pardyncount then
    begin
      soffset := par^.ParExtra.DynCodes[curdynnb].DynOffset;
      if maxoffset > soffset then
        maxoffset := soffset
    end;

    soffset := offset;
    if sdisplaystartoff < sdisplaystopoff then
      if soffset < sdisplaystartoff then
      begin
        if maxoffset > sdisplaystartoff then
          maxoffset := sdisplaystartoff
      end else if soffset < sdisplaystopoff then
        if maxoffset > sdisplaystopoff then
          maxoffset := sdisplaystopoff;

    st := t;
    if StaticFormat then
      while (soffset < maxoffset) and
        ((st[soffset] > #26) or (not(AnsiChar(st[soffset]) in (CtrlCodesSet + [#9])))) do
        Inc(soffset)
    else
      while (soffset < maxoffset) and (st[soffset] <> #9) do
        Inc(soffset);

    offset := soffset
  end;

  procedure getselectionoffsets(parnb: Integer; var offsets: TPoint);
  begin
    if fSelStart.ParNumber < parnb then
      offsets.X := -1
    else if fSelStart.fParNb > parnb then
      offsets.X := High(offsets.X)
    else
      offsets.X := fSelStart.ParOffset;
    if fSelStop.ParNumber < parnb then
      offsets.Y := -1
    else if fSelStop.fParNb > parnb then
      offsets.Y := High(offsets.Y)
    else
      offsets.Y := fSelStop.ParOffset;
  end;

  function GetLineStart(const l: LineInfo; LJustified: Boolean): Integer;
  begin
    if LJustified then
      Result := fLeftMargin
    else
      case Alignment of
        taLeftJustify: Result := fLeftMargin;
        taRightJustify: Result := fLineWidth - fRightMargin - l.LineWidth;
        taCenter: Result := fLeftMargin + (fLineWidth - fLeftMargin - fRightMargin - l.LineWidth) div 2
        else
          Result := 0;
      end;
  end;

  function GetLineStop(const l: LineInfo; LJustified: Boolean): Integer;
  begin
    if (ColumnWrap > 0) and WordWrap and (Alignment = taLeftJustify) then
    begin
      Result := fLeftMargin + l.TotalWidth * fSpaceWidth;
      Exit
    end;

    if LJustified then
      Result := fLineWidth - fRightMargin + l.TotalWidth - l.LineWidth
    else
      case Alignment of
        taLeftJustify: Result := fLeftMargin + l.TotalWidth;
        taRightJustify: Result := fLineWidth - fRightMargin + l.TotalWidth - l.LineWidth;
        taCenter: Result := fLineWidth - fRightMargin + l.TotalWidth - l.LineWidth -
          (fLineWidth - fLeftMargin - fRightMargin - l.LineWidth) div 2
        else
          Result := 0;
      end;
  end;

var r, rp: TRect;
  currentpar: Integer;
  cw: Integer;
  ps: TPaintStruct;
  tm: TTextMetric;
  hdc1: pmHDC;
  leftstart, saveddcnb: Integer;
  lastpainty: Integer;
  slinespacing: Single;
  spos: TPoint;
  enddisp: Integer;
  sbmp: THandle;
  usebackground, fixedbackground: Boolean;
  bgwidth, bgheight: Integer;
  bghandle: THandle;
  fl, ll, i: Integer;
  slinejust: Boolean;
  j, b: Integer;
  k, tlen: Integer;
  joff, koff: Integer;
  sshowspaces: Boolean;
  sblockstartcoord, sblockstopcoord: Integer;
  sblockstartoff, sblockstopoff: Integer;
  StartSelCoord, StopSelCoord: Integer;
  seloffsets: TPoint;
  sdcneedset, satneedfetch: Boolean;
  UseWindowsColors: Boolean;
  npar: pParInfo;

  sbcolor: TColor;
  parbackground: TColor;
  parlines: Integer;
  supdatecaret: Boolean;
  {$IFDEF PMDEBUG}
  dpaintmsg: AnsiString;
  {$ENDIF}

const LinePatternLength: array[TPenStyle] of Integer =
    {$IFNDEF D2006Up}
  (1, 24, 6, 24, 24, 1, 1);
  // TPenStyle = (psSolid, psDash, psDot, psDashDot, psDashDotDot, psClear, psInsideFrame);
    {$ELSE}
  (1, 24, 6, 24, 24, 1, 1, 1, 1);
     // TPenStyle = (psSolid, psDash, psDot, psDashDot, psDashDotDot, psClear, psInsideFrame, psUserStyle, psAlternate);
     {$ENDIF}

begin
  lastpainty := 0;
  slinespacing := 0;

  oldpen := 0;
  sdcneedset := True;
  supdatecaret := False;

  if fCanvas = nil then
  begin
    cw := fLineWidth;
    spos.X := 0;
    spos.Y := 0;
    sworkcanvas := fLineBmp.Canvas;
    if Message.WParam <> 0 then
    begin
      hdc1 := Message.WParam;
      with ps.rcpaint do
      begin
        Top := 0;
        Left := 0;
        Right := cw;
        Bottom := ClientHeight
      end;
    end else
    begin
      hdc1 := BeginPaint(Handle, ps);
    end;

    if fNoPaint or (fLockedCount > 0) then
    begin
      if Message.WParam = 0 then
        EndPaint(Handle, ps);
      Exit
    end;

    // Format displayed lines
    ParseStartStopNow(fDisplayTop.ParNumber);
    currentpar := fDisplayTop.fParNb;
    parlines := fW;
    fCanvas := sworkcanvas;
    // avoid local formatting operations be done on self.canvas because it's unusable here
    fW := fLineWidth;
    supdatecaret := False;
    if not(pmpFormatted in fDisplayTop.fPar^.ParState) then
    begin
      FormatNow(currentpar, currentpar, True, False);
      // Unconditional True to prevent infinite loop in
      if currentpar = fcp.ParNumber then
        supdatecaret := True     // unforeseen circumstances
    end;
    par := fDisplayTop.fPar;

    with ps.rcpaint do
    begin
      lastpainty := Top;
      fl := (Top + fTopOrigin) div fLineHeight;
      if fl < 0 then
        fl := 0;
      ll := (Bottom - 1 + fTopOrigin) div fLineHeight;
      if ll < 0 then
        ll := 0
    end;

    while (currentpar < fParagraphs.Count - 1) and ((pmpHidden in par^.ParState) or (par^.StartLine + GetLineCount(par^) - 1 < fl)) do
    begin
      Inc(currentpar);
      par := fParagraphs.Pointers[currentpar];
      if not(pmpFormatted in par^.ParState) then
      begin
        FormatNow(currentpar, currentpar, False, False);
        if currentpar = fcp.fParNb then
          supdatecaret := True
      end
    end;

    { prepare remaining of display }
    i := currentpar + 1;
    while i < fParagraphs.Count do
    begin
      npar := fParagraphs.Pointers[i];
      if npar.StartLine > ll then
        Break;
      if not(pmpFormatted in npar^.ParState) then
      begin
        FormatNow(i, i, False, False);
        if i = fcp.fParNb then
          supdatecaret := True
      end;
      Inc(i)
    end;

    { replace things }
    fW := parlines;
    fCanvas := nil
  end { fCanvas=nil }

  else
  begin
    fCanvas.Font := Font;
    sworkcanvas := fCanvas;
    {$IFDEF pmClx}
    hdc1 := nil;
    {$ELSE}
    hdc1 := 0;
    {$ENDIF}

    with pPaintInfo(Message.{$IFDEF pmClx} Msg {$ELSE} LParam {$ENDIF})^ do
    begin
      cw := fw;
      fl := StartLine;
      ll := StopLine;
      slinespacing := LineSpacingPix;
      spos := Position
    end;
    ftmpnav1.VisibleLineNumber := fl;
    currentpar := ftmpnav1.ParNumber;
    par := ftmpnav1.fPar
  end;
  { fCanvas<>nil }

  dc := sworkcanvas.Handle;
  SetTextAlign(dc, ta_updatecp or ta_baseline);

  sKeepParBackgnd := pmoKeepParBackgnd in Options;
  usebackground := (fBackground.Width > 0) and (fBackground.Height > 0);
  if usebackground then
  begin
    bgwidth := fBackground.Bitmap.Width;
    bgheight := fBackground.Bitmap.Height;
    usebackground := (bgwidth > 0) and (bgheight > 0)
  end else
  begin
    bgwidth := 0;
    bgheight := 0;
  end;
  fixedbackground := fFixedBMPBackground;

  if fl < fParagraphs.fVisibleLineCount then
  begin
    sblockstartoff := High(sblockstartoff);
    // to avoid warnings
    sblockstopoff := High(sblockstopoff);

    sshowspaces := pmNPSpace in ShowNonPrintChars;
    pardyncount := GetDynCount(par^);
    parbackground := pmsGetParBackgnd(par^);
    if parbackground = -1 then
      parbackground := clNone;
    parlines := GetLineCount(par^);
    UseWindowsColors := pmoWindowsSelColors in Options;

    { set running stack vars }
    fTmpLines.LLPar := par;
    lin := fTmpLines[fl - par^.StartLine];
    t := par^.ParText;
    tlen := GetParLength(par^);
    GetSelectionOffsets(currentpar, seloffsets);
    InSel := UseWindowsColors and (j >= seloffsets.X) and (j < seloffsets.Y);

    sblockstartcoord := High(sblockstartcoord);

    if (fCanvas = nil) and (fl = 0) and (fTopOrigin < 0) then
      BackgroundFill(hdc1, Rect(0, 0, cw, -fTopOrigin), usebackground, fixedbackground, 0, bgheight, bgwidth, Color);

    lastpainty := fl * fLineHeight - fTopOrigin;

    for i := fl to ll do
      if i < fParagraphs.fVisibleLineCount then
      begin
        if fCanvas = nil then
        begin
          r.Left := 0;
          r.Top := 0;
          r.Bottom := fLineHeight;
          r.Right := cw;
          if parbackground = clNone then
            sbcolor := Color
          else
            sbcolor := parbackground;
          BackgroundFill({$IFDEF pmClx} sworkcanvas {$ELSE} dc {$ENDIF},
            r, usebackground and (parbackground = clNone), fixedbackground, lastpainty, bgheight, bgwidth, sbcolor);
          r.Left := fLeftMargin - fDisplayLeft;
          r.Right := cw - fRightMargin - fDisplayLeft
        end else
          { fCanvas<>nil }
        begin
          r.Left := spos.X + fLeftMargin;
          r.Top := spos.Y + Round((i - fl) * slinespacing);
          r.Right := cw + r.Left;
          r.Bottom := r.Top + fLineHeight
        end;

        if (not fJustified) or (lin.JustifyStart >= lin.Stop) then
          case fAlignment of
            taRightJustify: r.Left := r.Right - lin.LineWidth;
            taCenter: r.Left := (r.Left + r.Right - lin.LineWidth) div 2
          end;

        leftstart := r.Left + fDisplayLeft;
        stemppos := r.TopLeft;
        Inc(stemppos.Y, fLineBase);
        j := lin.Start;
        if (fJustified) and (lin.JustifyStart = j) and (lin.Spaces > 0) then
          SetTextJustification(dc, cw - fLeftMargin - fRightMargin - lin.LineWidth, lin.Spaces)
        else
          SetTextJustification(dc, 0, 0);

        { determine where to start and stop drawing the selection }
        slinejust := Justified and (i < par.StartLine + fTmpLines.Count - 1);
        startselcoord := High(startselcoord);
        stopselcoord := High(startselcoord);
        sdisplaystartoff := High(sdisplaystartoff);
        sdisplaystopoff := High(sdisplaystopoff);
        if (lin.Start <= seloffsets.Y) and (fSelLen <> 0) and ((not fHideSelection) or fFocused) then
          if fBlockSelection then
          begin
            if lin.Stop >= seloffsets.X then
            begin
              if sblockstartcoord = High(sblockstartcoord) then
              begin
                { compute block horizontal extents }
                if fBlockStartCol < fBlockStopCol then
                begin
                  sblockstartoff := fBlockStartCol;
                  sblockstopoff := fBlockStopCol
                end else
                begin
                  sblockstartoff := fBlockStopCol;
                  sblockstopoff := fBlockStartCol
                end;
                sblockstartcoord := sblockstartoff * fSpaceWidth - fDisplayLeft + fLeftMargin;
                sblockstopcoord := sblockstopoff * fSpaceWidth - fDisplayLeft + fLeftMargin;
              end;
              startselcoord := sblockstartcoord;
              stopselcoord := sblockstopcoord;
              if UseWindowsColors then
              begin
                sdisplaystartoff := ColToOffset(par, sblockstartoff, fTabStops, StaticFormat);
                sdisplaystopoff := ColToOffset(par, sblockstopoff, fTabStops, StaticFormat);
                if InSel then
                begin
                  InSel := False;
                  SetCanvasColors(sworkcanvas);
                  {$IFNDEF pmClx} dc := sworkcanvas.Handle {$ENDIF}
                end
              end
            end   // lin.Stop>=seloffsets.X
          end    // block selection

          else
            { not Block Selection }
          begin
            if (lin.Start >= seloffsets.X) then
            begin
              if lin.Stop >= seloffsets.X then
                startselcoord := GetLineStart(lin, slinejust) - fDisplayLeft
            end else if (lin.Stop > seloffsets.X) or
              ((lin.Stop = seloffsets.X) and
                (seloffsets.X = tlen) and (seloffsets.Y = High(seloffsets.Y))) then
                  startselcoord := fSelStart.DisplayX;

            if (lin.Stop > seloffsets.Y) or ((lin.Stop = seloffsets.Y) and (i = par^.StartLine + parlines - 1)) then
              stopselcoord := fSelStop.DisplayX
            else if pmoFullLineSelect in Options then
              stopselcoord := High(stopselcoord)
            else
              stopselcoord := GetLineStop(lin, slinejust) - fDisplayLeft;

            if UseWindowsColors then
            begin
              sdisplaystartoff := seloffsets.X;
              sdisplaystopoff := seloffsets.Y
            end
          end;

        { put the background to clHighlight before drawing text }
        if UseWindowsColors and (startselcoord <> High(startselcoord)) then
        begin
          r.Left := startselcoord;
          r.Right := stopselcoord;
          pmRect16(r);
          Brush.Color := fSelBackColor;
          FillRect(dc, r, Brush.Handle);
        end;

        sustart := High(sustart);
        satneedfetch := True;

        { draw the text }
        while j < lin.Stop do
        begin
          setDC(j, lin.Stop, satneedfetch, sdcneedset);
          sdcneedset := False;
          satneedfetch := False;
          if j < lin.Stop then
          begin
            b := j;
            getWords(j, lin.Stop);
            enddisp := j;
            if (not sshowspaces) and (j = lin.Stop) and (i < par^.StartLine + parlines - 1) then
              while (enddisp > b) and (t[enddisp - 1] = ' ') do
                Dec(enddisp);

            PutText(dc, stemppos, t + b, enddisp - b, fMaxOneShotChars, cw + spos.X, sshowspaces, fSpaceWidth, currentuppercase);
            if (j < lin.Stop) and (t[j] = #9) then
            begin
              SetDC(j, lin.Stop, False, False);
              r.Left := stemppos.X;
              if pmNPTab in ShowNonPrintChars then
                PutText(dc, stemppos, #187, 1, 10, High(Integer), False, 0, False);
              r.Right := Leftstart - fDisplayLeft;
              if fTabStops > 0 then
                r.Right := r.Right +
                  ((r.Left - leftstart + fDisplayLeft) div (fTabStops * fSpaceWidth) + 1) * (fTabStops * fSpaceWidth)
              else if fTabStops < 0 then
                r.Right := r.Right +
                  ((r.Left - leftstart + fDisplayLeft) div (-fTabStops) + 1) * (-fTabStops);

              if GetBkMode(dc) = OPAQUE then
                repeat
                  PutText(dc, stemppos, ' ', 1, 10, cw, False, 0, False);
                until (stemppos.X >= r.Right) or (stemppos.X >= cw);
              SetDC(j, j, False, False);

              stemppos.X := r.Right;
              Inc(j);
              if (fJustified) and (lin.JustifyStart <= j) and (lin.Spaces > 0) then
                SetTextJustification(dc, cw - fLeftMargin - fRightMargin - lin.LineWidth, lin.Spaces);
            end;
          end
        end;
        //until (j>=lin.Stop);

        if (Byte(sstyle) and $80 <> 0) and (sustart <> High(sustart)) then
        begin
          if oldpen = 0 then
            oldpen := SelectObject(dc, fSpecUnderlinePen.Handle);
          WavyLine(dc, sustart, stemppos.X, fWavyLinePos + stemppos.Y - fLineBase, fWavyLineAmplitude)
        end;

        if (j = tlen) and (pmNPReturn in ShowNonPrintChars) then
        begin
          r.Left := stemppos.X;
          SetDC(j, tlen, satneedfetch, sdcneedset);
          sdcneedset := False;
          PutText(dc, stemppos, #182, 1, High(Integer), High(Integer), False, 0, False);
          if (seloffsets.Y > tlen) and (seloffsets.X < tlen) and (not(pmoFullLineSelect in Options)) then
            if UseWindowsColors then
            begin
              // extend selection background to include the paragraph return mark
              Brush.Color := fSelBackColor;
              FillRect(dc, Rect(r.Left, 0, stemppos.X, fLineHeight), Brush.Handle);
              stemppos.X := r.Left;
              PutText(dc, stemppos, #182, 1, High(Integer), High(Integer), False, 0, False)
            end else
              StopSelCoord := stemppos.X;
        end;

        { finish drawing the highlight }
        if StartSelCoord <> High(StartSelCoord) then
        begin
          if not UseWindowsColors then
          begin
            r.Left := StartSelCoord;
            r.Right := StopSelCoord;
            pmRect16(r);
            InvertRect(dc, r)
          end else
          begin
            InSel := lin.Stop <= seloffsets.Y;
            if InSel then
            begin
              if lin.Stop = sdisplaystopoff then
              begin
                InSel := False;
                SetCanvasColors(sworkcanvas);
                dc := sworkcanvas.Handle
              end;
              if lin.Stop = sdisplaystartoff then
              begin
                SetCanvasColors(sworkcanvas);
                dc := sworkcanvas.Handle
              end
            end
          end;

          if fShowEndParSelected and (not((pmoFullLineSelect in Options) or fBlockSelection)) and
            (seloffsets.X <= j) and (j = tlen) and (j < seloffsets.Y) and (not(pmNPReturn in ShowNonPrintChars)) then
          begin
            rp.Top := fLineHeight div 3;
            rp.Bottom := 2 * rp.Top;
            rp.Left := StopSelCoord;
            rp.Right := rp.Left + fSpaceWidth div 2 + 1;
            pmRect16(r);
            if UseWindowsColors then
            begin
              Brush.Color := fSelBackColor;
              FillRect(dc, rp, Brush.Handle);
            end else
              InvertRect(dc, rp)
          end
        end;

        { put it on the display }
        if fCanvas = nil then
        begin
          if Assigned(fCollpsHandler) then
            fCollpsHandler.PaintLine(Self, dc, fDisplayLeft, fLineHeight, par^, lin);
          if not BitBlt(hdc1, 0, lastpainty, cw, fLineHeight, dc, 0, 0, SRCCopy) then
            Inc(lastpainty);
          Inc(lastpainty, fLineHeight)
        end;

        { finished for this line, go on with next one }
      {$IFDEF PMDEBUG} OutputDebugString( { UCONVERT } PChar { /UCONVERT } ('Done painting line ' + IntToStr(i)));
{$ENDIF}
        if (i < fParagraphs.fVisibleLineCount - 1) and (i < ll) then
        begin
          if i >= par^.StartLine + parlines - 1 then
          begin
            sustart := pmsGetParForegnd(par^);
            repeat
              Inc(currentpar);
              if currentpar < fParagraphs.Count then
                par := fParagraphs.Pointers[currentpar]
              else
              begin
                par := nil;
                Break
              end
            until not(pmpHidden in par.ParState);
            pardyncount := GetDynCount(par^);
            parbackground := pmsGetParBackgnd(par^);
            if parbackground = -1 then
              parbackground := clNone;
            parlines := GetLineCount(par^);
            if sustart <> pmsGetParForegnd(par^) then
            begin
              SetCanvasColors(sworkcanvas);
              {$IFNDEF pmClx} dc := sworkcanvas.Handle {$ENDIF}
            end;
            fTmpLines.LLPar := par;
            curdynnb := 0;
            t := par^.ParText;
            tlen := GetParLength(par^);
            GetSelectionOffsets(currentpar, seloffsets);
          end;
          if par <> nil then
            lin := fTmpLines[i + 1 - par^.StartLine]
        end
      end;
    // i line loop

  end;
  // if first line < linecount

  if oldpen <> 0 then
    SelectObject(dc, oldpen);

  if fCanvas = nil then
  begin
    r := ps.rcPaint;
    r.Top := lastpainty;
    BackgroundFill(hdc1, r, usebackground, fixedbackground, lastpainty, bgheight, bgwidth, Color);

    if (fEndOfTextPen.Color <> -1) and (ll >= fParagraphs.fVisibleLineCount) and (fl <= fParagraphs.fVisibleLineCount) then
    begin
      r.Top := fParagraphs.fVisibleLineCount * fLineHeight - fTopOrigin + fEndOfTextPen.Width div 2;
      oldpen := SelectObject(hdc1, fEndOfTextPen.Handle);
      Windows.MoveToEx(hdc1, 0, r.Top, nil);
      Windows.LineTo(hdc1, r.Right, r.Top);
    end else
      oldpen := 0;

    if fRightLinePos <> 0 then
    begin
      if fRightLinePos > 0 then
        r.Left := fSpaceWidth * fRightLinePos + fLeftMargin - fDisplayLeft
      else
        r.Left := fLeftMargin - fDisplayLeft - fRightLinePos;
      if (r.Left + fRightLinePen.Width > ps.rcPaint.Left) and (r.Left - fRightLinePen.Width < ps.rcPaint.Right) then
      begin
        if oldpen = 0 then
          oldpen := SelectObject(hdc1, fRightLinePen.Handle)
        else
          SelectObject(hdc1, fRightLinePen.Handle);
        r.Top := ps.rcPaint.Top - (ps.rcPaint.Top + fTopOrigin) mod LinePatternLength[fRightLinePen.Style];
        Windows.MoveToEx(hdc1, r.Left, r.Top, nil);
        Windows.LineTo(hdc1, r.Left, ps.rcPaint.Bottom)
      end
    end;

    if oldpen <> 0 then
      SelectObject(hdc1, oldpen);
    if Message.WParam = 0 then
      EndPaint(Handle, ps)
  end;

  if supdatecaret then
    UpdateCaret(False);
end; { message WM_PAINT }

{$IFDEF PM_IMEMESSAGES}

procedure TPlusMemo.WMChar(var Message: TWMChar); { message handlers }
begin
{$IFDEF D2009Up}
  inherited;
  if fInComposition then
    SetCompositionWindow(True, False)
{$ELSE}
  if (Message.CharCode < 128) or (not IsWindowUnicode(Handle)) or ReadOnly or DisplayOnly then
    inherited
  else
  begin
    SelText := WideChar(Message.CharCode);
    fInternalScroll := True;
    ScrollInView;
    fInternalScroll := False
  end
{$ENDIF}
end;

procedure TPlusMemo.WMImeStartComposition(var Message: TMessage); { message handlers }
begin
  fInComposition := True;
  inherited;
  SetCompositionWindow(True, True)
end;

{ ***** IME handling: VCL SetCompositionWindow does not work if the locale is not FarEast
       at application startup, so we call API directly.
       We could bave used unit Imm, but this would result in static linking of imm32.dll
       which is not necessary in most cases and could slow down the startup process.
       That's why we go with dynamic linking }

type
  TCompositionForm = record
    dwStyle: DWORD;
    ptCurrentPos: TPoint;
    rcArea: TRect;
  end;
  pCompositionForm = ^TCompositionForm;
  HIMC = Integer;

var IMM32Dll: THandle = 0;
  _ImmGetContext: function(hWnd: HWND): HIMC stdcall;
  _ImmReleaseContext: function(hWnd: HWND; hImc: HIMC): Boolean stdcall;
  _ImmSetCompositionWindow: function(hImc: HIMC; lpCompForm: pCompositionForm): Boolean stdcall;
  _ImmSetCompositionFont: function(hImc: HIMC; lpLogfont: PLOGFONT): Boolean stdcall;

procedure TPlusMemo.SetCompositionWindow(SetPos, SetFont: Boolean);
var sh: THandle; cform: TCompositionForm; LFont: TLogFont;
begin
  if IMM32Dll = 0 then
  begin
    IMM32DLL := LoadLibrary('imm32.dll');
    if IMM32DLL <> 0 then
    begin
      @_ImmGetContext := GetProcAddress(IMM32DLL, 'ImmGetContext');
      @_ImmReleaseContext := GetProcAddress(IMM32DLL, 'ImmReleaseContext');
      @_ImmSetCompositionWindow := GetProcAddress(IMM32DLL, 'ImmSetCompositionWindow');
      @_ImmSetCompositionFont := GetProcAddress(IMM32DLL, 'ImmSetCompositionFontW')
    end
  end;

  if IMM32Dll <> 0 then
  begin
    sh := _ImmGetContext(Handle);
    if sh <> 0 then
    begin
      if SetFont then
      begin
        GetObject(Font.Handle, SizeOf(TLogFont), @LFont);
        _ImmSetCompositionFont(sh, @LFont)
      end;
      if SetPos then
      begin
        with CForm do
        begin
          dwStyle := 2;
          //CFS_POINT;
          ptCurrentPos.x := fCaretX;
          ptCurrentPos.y := fCaretY;
        end;
        _ImmSetCompositionWindow(sh, @CForm)
      end;
      _ImmReleaseContext(Handle, sh);
    end
  end;
end;

procedure TPlusMemo.WMIMEEndComp(var Message: TMessage);
begin
  fInComposition := False;
  inherited
end;

{$ENDIF}  // PM_IMEMESSAGES

{$IFDEF TPLUSMEMOU}

procedure TPlusMemo.WMImeChar(var Message: TMessage); { message handlers }
{ UCONVERT }
var tmpchar: array[0..3] of Char;
  tmpwchar: array[0..2] of WideChar;
  tmplen: Integer;
begin
  if IsWindowUnicode(Handle) then
  begin
    SelText := WideChar(Message.WParam);
    Exit
  end;

  tmpchar[0] := Char(Message.WParam shr 8);
  if Message.WParam and $FF00 <> 0 then
  begin
    tmpchar[1] := Char(Message.WParam);
    tmpchar[2] := #0;
    tmplen := 2
  end else
  begin
    tmpchar[0] := Char(Message.WParam);
    tmpchar[1] := #0;
    tmplen := 1
  end;
  tmpwchar[2] := #0;
  tmpwchar[1] := #0;

  MultiByteToWideChar(CP_ACP, 0, @tmpchar, tmplen, @tmpwchar, 2);
  SetSelTextBuf(@tmpwchar)
  { /UCONVERT }
end;

// WM_GETTEXT, WM_SETTEXT: avoid buffer overrun because VCL thinks its a PAnsiChar, but it is PWideChar

procedure TPlusMemo.WMGetText(var Message: TMessage);
var t: PAnsiChar;
begin
  t := PAnsiChar(Message.LParam);
  t^ := #0
end;

procedure TPlusMemo.WMSetText(var Message: TMessage);
begin
  // Nothing to do, inherited Text is unused
end;
{$ENDIF}

procedure TPlusMemo.FontChanged;
 { Called as part of CM_FONTCHANGED handler }
begin
  if fAutoLineHeight then
    fLineHeight := abs(Font.Height) + 1;
  if fLineBmp <> nil then
  begin
    UpdateFontDependantFields;
    Invalidate;
    Reformat;
    fDisplayLeft := 0;
    fTopOrigin := 0;
    fDisplayTop.VisibleLineNumber := 0;
    SetVScrollParams;
    SetHScrollParams;
    if fAutoCaretWidth then
      CaretWidth := 0
    else
      CaretWidth := CaretWidth;
    if fVScrollBar then
      SetScrollPos(Handle, SB_VERT, fTopOrigin div fVScrollFact, True);
    if fHScrollBar then
      SetScrollPos(Handle, SB_HORZ, 0, True);
    if Assigned(fOnVScroll) then
      fOnVScroll(Self);
    UpdateCaret(False)
  end;
  DoNotify(fNotifyList, [pmeFontChanged]);
end;

procedure TPlusMemo.CMFontChanged(var Message: TMessage); { message handlers }
begin
  inherited;
  FontChanged
end;

procedure TPlusMemo.Cmctl3dchanged; { message handlers }
begin
  inherited;
  RecreateWnd;
end;

{$IFNDEF D2006Up}

procedure TPlusMemo.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  if Assigned(fOnMouseEnter) then
    fOnMouseEnter(Self)
end;

procedure TPlusMemo.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if Assigned(fOnMouseLeave) then
    fOnMouseLeave(Self)
end;
{$ENDIF}

procedure TPlusMemo.BackgroundChange(Sender: TObject); { internal working methods }
begin
  fFixedBMPBackground := (pmoFixedBackground in fOptions) and (fBackground.Width > 0) and (fBackground.Height > 0);
  Invalidate
end;

procedure TPlusMemo.BackgroundFill(dc: pmHDC; const R: TRect; UseBackground, FixedBackground: Boolean;
  YPos, BgHeight, BgWidth: Integer; BColor: TColor);
var j, joff, k, koff: Integer; bghandle: THandle;
begin
  if UseBackground then
  begin
    bghandle := fBackground.Bitmap.Canvas.Handle;
    if FixedBackground then
    begin
      if (BgWidth < fLineBmp.Width) or (BgHeight < ClientHeight) then
      begin
        Brush.Color := BColor;
        Windows.FillRect(dc, R, Brush.Handle)
      end;
      Windows.BitBlt(dc, R.Left, R.Top, BgWidth, BgHeight, bghandle, 0, YPos, SRCCOPY)
    end else
    begin
      j := R.Top;
      joff := (fTopOrigin + YPos) mod bgheight;
      if joff < 0 then
        joff := bgheight + joff;
      while j < R.Bottom do
      begin
        k := 0;
        koff := fDisplayLeft mod bgwidth;
        while k < r.Right do
        begin
          Windows.BitBlt(dc, k, j, BgWidth, BgHeight, bghandle, koff, joff, SRCCOPY);
          Inc(k, bgwidth - koff);
          koff := 0
        end;
        Inc(j, bgheight - joff);
        joff := 0
      end
    end
  end else
  begin
    Brush.Color := BColor;
    Windows.FillRect(dc, R, Brush.Handle)
  end;
end;

function TPlusMemo.getParBuffers(i: Integer): PChar;
begin
  Result := fParagraphs.ParPointers[i].ParText
end;

function TPlusMemo.getStaticFormat: Boolean;
begin
  Result := fParagraphs.StaticFormat
end;

procedure TPlusMemo.UpdateFontDependantFields;
var tm: TTextMetric;
  scanvas: TCanvas;
begin
  if fCanvas <> nil then
    scanvas := fCanvas
  else
    scanvas := Self.Canvas;
  scanvas.Font := Font;

  GetTextMetrics(scanvas.Handle, tm);

  if fAutoLineHeight then
    fLineHeight := tm.tmHeight + 1;
  if fParagraphs.fVisibleLineCount > 65535 then
    fLineHeight := pmMinOf(MaxInt div fParagraphs.fVisibleLineCount + 1, fLineHeight);
  if tm.tmInternalLeading < 0 then
    tm.tmInternalLeading := 0;

  fLineBase := fLineHeight - tm.tmDescent - (fLineHeight - tm.tmHeight + 1) div 2;

  if fLineBase < tm.tmHeight - tm.tmInternalLeading - tm.tmDescent then
  begin
    fLineBase := fLineHeight - tm.tmInternalLeading;
    if fLineBase < tm.tmHeight - tm.tmDescent - tm.tmInternalLeading then
      fLineBase := fLineHeight
  end;

  fLineDescent := fLineBase + tm.tmDescent;
  if fLineBmp <> nil then
  begin
    fDisplayLines := ClientHeight div fLineHeight + 1;
    fLineBmp.Height := fLineHeight
  end;

  fSpaceWidth := scanvas.TextWidth(' ');
  if tm.tmMaxCharWidth > 0 then
    fMaxOneShotChars := $4000 div tm.tmMaxCharWidth
  else
    fMaxOneShotChars := 256;
  fWavyLinePos := fLineDescent;
  fWavyLineAmplitude := 1 + (fSpecUnderlinePen.Width * 3) div 2;
  if fWavyLinePos >= fLineHeight - fWavyLineAmplitude then
    fWavyLinePos := fLineHeight - fWavyLineAmplitude - 1;
end;

function TPlusMemo.getFormatCompleted: Integer;
begin
  if fLoadingContent then
    Result := fParagraphs.fLoadPosition
  else if fSavingContent then
    Result := fParagraphs.fSavePosition
  else
    Result := fParagraphs.fUpdateStartPar
end;

procedure TPlusMemo.ETPenChange(Sender: TObject); { internal working methods }
begin
  Invalidate
end;

procedure TPlusMemo.SelectWords(ExtendRight: Boolean); { internal working methods }
begin
  { check whether fSelStart is at word boundary, if not go back there and refresh this line }
  ftmpnav1.Assign(fSelStart);
  ftmpnav1.ToStartOfWord(Delimiters);
  if ftmpnav1.Pos <> fSelStart.Pos then
  begin
    InvalidateLines(ftmpnav1.VisibleLineNumber, fSelStart.VisibleLineNumber, False);
    fSelStart.Assign(ftmpnav1)
  end;

  if ExtendRight then
  begin
    { check whether fSelStop is at word boundary, if not, go forward there and refresh this line }
    ftmpnav1.Assign(fSelStop);
    ftmpnav1.ToEndOfWord(Delimiters);
    if (pmoLargeWordSelect in Options) then
      while (ftmpnav1.ParOffset < GetParLength(ftmpnav1.fPar^)) and (pmChar(ftmpnav1.Text) in Delimiters) do
        ftmpnav1.Pos := ftmpnav1.Pos + 1;

    if ftmpnav1.Pos <> fSelStop.Pos then
    begin
      InvalidateLines(fSelStop.VisibleLineNumber, ftmpnav1.VisibleLineNumber, False);
      fSelStop.Assign(ftmpnav1)
    end
  end;

  { replace fSelLen according to new selection range }
  if CurrentPosNav = fSelStart then
    fSelLen := fSelStop.Pos - fSelStart.Pos
  else
    fSelLen := fSelStart.Pos - fSelStop.Pos;
end; { SelectWords }

procedure TPlusMemo.CleanUp; { internal working methods }
begin
  fParagraphs.CleanUp;
  fSelStart.Invalidate;
  fSelStop.Invalidate;
  ftmpnav1.Invalidate;
  ftmpnav2.Invalidate;
  if fUpText <> nil then
  begin
    StrDispose(fUptext);
    fUpText := nil;
    fUpParNb := -1
  end;
  ClearUndo
end;

procedure TPlusMemo.DoNotify(List: TList; Events: TpmEvents); { internal working methods }
var i: Integer; snotify: PChar; somenil: Boolean;
begin
  if List <> nil then
  begin
    somenil := False;
    for i := 0 to List.Count - 1 do
    begin
      snotify := List[i];
      if snotify <> nil then
        IpmsNotify(snotify).Notify(Self, Events)
      else
        somenil := True
    end;
    if somenil then
      List.Pack
  end
end;

procedure TPlusMemo.DoSelMove;
begin
  if fSelMoveUpdateCount > 0 then
    Exit;
  if fsPosDirty or fsSelLenDirty then
  begin
    fsSelLenDirty := False;
    fsPosDirty := False;
    if Assigned(fOnMove) then
      fOnMove(Self)
  end;
end;

procedure TPlusMemo.EndKeepBlock(n1, n2: TPlusNavigator; sBlockExtraCols: TPoint); { internal working methods }
begin
  if pmoPersistentBlocks in Options then
  begin
    fIndependantCpNav.Assign(fSelStart);
    fSelStart.Assign(n1);
    fSelStop.Assign(n2);
    n1.Free;
    n2.Free;
    if sBlockExtraCols.X <> Low(sBlockExtraCols.X) then
      SelectBlock(fSelStart.Col + sBlockExtraCols.X, fSelStart.TrueLineNumber,
        fSelStop.Col + sBlockExtraCols.Y, fSelStop.TrueLineNumber)
    else
      fSelLen := fSelStop.Pos - fSelStart.Pos;
    fExtraCols := '';
    fcp := fIndependantCpNav;
    EndUpdate;
    if fLockedCount = 0 then
      ScrollInView
  end
end;

procedure TPlusMemo.PrepareKeepBlock(var n1, n2: TPlusNavigator; var sBlockExtraCols: TPoint); { internal working methods }
begin
  if pmoPersistentBlocks in Options then
  begin
    if fBlockSelection then
    begin
      sBlockExtraCols.X := fBlockStartCol - fSelStart.Col;
      sBlockExtraCols.Y := fBlockStopCol - fSelStop.Col
    end else
      sBlockExtraCols.X := Low(sBlockExtraCols.X);
    // flag as not a column block
    fBlockSelection := False;
    n1 := TPlusNavigator.Create(Self);
    n2 := TPlusNavigator.Create(Self);
    n1.Assign(fSelStart);
    n2.Assign(fSelStop);
    fSelStart.Assign(fcp);
    fSelStop.Assign(fcp);
    fSelLen := 0;
    BeginUpdate
  end else
    SelLength := 0
end;

function TPlusMemo.SmartTabText: string; { internal working methods }
var scol, fcol, plen: Integer; spar: pParInfo;
begin
  Result := '';
  if WordWrap then
    Result := #9
  else if fcp.ParNumber > 0 then
  begin
    scol := OffsetToCol(fcp.Par, fcp.ParOffset, TabStops, StaticFormat);
    ftmpnav1.Assign(fcp);
    plen := 0;
    spar := ftmpnav1.Par;
    repeat
      if ftmpnav1.ParNumber > 0 then
      begin
        ftmpnav1.ParNumber := ftmpnav1.ParNumber - 1;
        spar := ftmpnav1.Par;
        plen := GetParLength(spar^);
        fcol := OffsetToCol(spar, plen, TabStops, StaticFormat)
      end else
        fcol := -1
    until (fcol < 0) or (fcol > scol);

    if fcol > scol then
    begin
      fcol := ColToOffset(spar, scol, TabStops, StaticFormat);
      while (fcol < plen) and (not(pmChar(spar.ParText[fcol]) in [' ', #9])) do
        Inc(fcol);
      while (fcol < plen) and (pmChar(spar.ParText[fcol]) in [' ', #9]) do
        Inc(fcol);
      Result := StringOfChar(Char(' '), OffsetToCol(spar, fcol, TabStops, StaticFormat) - scol)
    end
  end
end;

procedure TPlusMemo.ScrollEvent(Sender: TObject; ScrollCode: TScrollCode; var ScrollPos: Integer);
  { Used in Clx only: event handler for scrollbar.OnScroll }
begin
  fInternalScroll := True;
  if Sender = fVertScrollBar then
    TopOrigin := ScrollPos * fVScrollFact;
  if Sender = fHorzScrollbar then
    LeftOrigin := ScrollPos * fHScrollFact;
  fInternalScroll := False;
  SetFocus
end;

{ IpmEdit interface implementation }

function TPlusMemo.CanCut: Boolean;
begin
  Result := not(ReadOnly or DisplayOnly) and (SelLength <> 0)
end;

function TPlusMemo.CanCopy: Boolean;
begin
  Result := not DisplayOnly and (SelLength <> 0)
end;

function TPlusMemo.CanPaste: Boolean;
begin
  Result := not(ReadOnly or DisplayOnly)
end;

function TPlusMemo.CanSelectAll: Boolean;
begin
  Result := not DisplayOnly and (CharCount <> 0)
end;

function TPlusMemo.CanDelete: Boolean;
begin
  Result := not(ReadOnly or DisplayOnly) and (SelLength <> 0)
end;

procedure TPlusMemo.Finalize;
begin
  if Assigned(fFormatThread) then
  begin
    fFormatThread.PutToEnd(True);
    fFormatThread := nil
  end;
end;

initialization
MemoCount := 0;
ClipboardBlockFormat := 0;

finalization
  gDestroyedMemoList.Free;
  if PmRightArrowCur <> 0 then
    DestroyCursor(PmRightArrowCur);
end.


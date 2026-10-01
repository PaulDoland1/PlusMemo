unit PMSupport;

{ PlusMemo version 7.5 support unit
{ © Electro-Concept Mauricie, 1997-2026 }

{$I PMDefines.inc}

{$DEFINE PMSupport}

interface

{$IFDEF D7New}
  {$WARN UNSAFE_CAST OFF}
  {$WARN UNSAFE_CODE OFF}
  {$WARN UNSAFE_TYPE OFF}
{$ENDIF}

{$A+} { this unit requires word alignment of data }
{$B-} { not complete boolean evaluation }
{$T-} { not typed address operator }

{$H+} { long strings }
{$J+} { writeable typed constants }

uses
  Classes, Graphics, Controls, Windows, Messages, SysUtils, SyncObjs;

const
  fsHighlight = Ord(High(TFontStyle)) + 1;
  fsAltFont = fsHighlight + 1;

  {$IFDEF PMSupport}
  WM_User = 1024;
  {$ENDIF}
  pm_UpdateBkg = WM_User + 1;

{$IFDEF PMSupportA}

type pmChar = AnsiChar;
{$ELSE}
    {$IFDEF PMSupportU}

function  pmChar(c: Char): AnsiChar;
    {$ELSE}
        {$IFDEF D2009Up}

function  pmChar(c: Char): AnsiChar;
        {$ELSE}

type pmChar = AnsiChar;
        {$ENDIF}
    {$ENDIF}
{$ENDIF}

(*type pmNativeString = {$IFDEF D2009Up} string {$ELSE} AnsiString {$ENDIF};  // String and char types native to the development system
     pmNativeChar = {$IFDEF D2009Up} Char {$ELSE} AnsiChar {$ENDIF};
     pmNativePChar = {$IFDEF D2009Up} PChar {$ELSE} PAnsiChar {$ENDIF};
*)
{ UCONVERT }

type pmNativeString = string; // String and char types native to the development system
  pmNativeChar = Char;
  pmNativePChar = PChar;
{ /UCONVERT }

type
  TPlusFontStyle = 0..Ord(fsAltFont);
  TPlusFontStyles = set of TPlusFontStyle;

  TpmsLineBreak = (psbCRLF, psbLFCR, psbCR, psbLF);

  TpmUpperCase = (pmuAscii, pmuAnsi, pmuUserDefined);
  TpmUpperCaseProc = procedure(t: PChar);

  TMouseScrollType = (msNoScroll, msUp, msDown, msLeft, msRight);

  TpmEvent = (pmeChange, pmeSelMove, pmeStyleChange, pmeContext, pmeRightContext, pmeMessage, pmeAfterMessage,
    pmeVScroll, pmeHScroll, pmeFontChanged, pmeBeforeChange, pmeNewContent);
  TpmEvents = set of TpmEvent;

  { Standard edit interface, implemented by TPlusMemo and used by TpmEdit actions }
  IpmEditAction = interface
    ['{A82C7A71-A0E8-4EAD-9F97-3EE71E670BFC}']
    function CanCut: Boolean;
    function CanCopy: Boolean;
    function CanPaste: Boolean;
    function CanSelectAll: Boolean;
    function CanDelete: Boolean;
    function CanRedo: Boolean;
    function CanUndo: Boolean;
    procedure CutToClipboard;
    procedure CopyToClipboard;
    procedure PasteFromClipboard;
    procedure SelectAll;
    procedure ClearSelection;
    procedure ScrollInView;
    procedure Undo;
    procedure Redo;
  end;

  IpmsNotify = interface
    procedure Notify(Sender: TComponent; Events: TpmEvents);
  end;

  TUndoRecord = record UndoStart, UndoStop: Integer;
    LockCount: Integer;
    UndoText: PChar
  end;

  TDynArray2 = class(TPersistent) { Dynamic array of predefined element size (prop ElementSpace) with distributed memory layout.
                                      Array space is allocated in chuncks of 32K }
  private {  Used as ancestor of TParagraphsList and TStartStopKeyList }
  protected
    fElementSize,
    fElementSpace: SmallInt;
    fList: TList;
    fCount, fCapacity: LongInt;
    fElementsPerBuffer: SmallInt;
    procedure SetCapacity(cap: LongInt);
    procedure SetCount(NewCount: LongInt);
    function  GetPointer(i: LongInt): Pointer;
  protected
  public
    constructor Create;
    destructor Destroy; override;
    property Capacity: LongInt read fCapacity write SetCapacity;
    property Count: LongInt    read fCount    write SetCount;
    property Pointers[i: LongInt]: Pointer read GetPointer;
    property ElementSpace: SmallInt read fElementSpace;
    function Add(const Item): LongInt;
  end;

  LineInfo = packed record { each paragraph has one such record for every line except when it has only one line }
    Start, Stop: Integer; { offset in paragraph text buffer for this line }
    LineWidth, TotalWidth: Integer; { in pixels: LineWidth is without trailing spaces, TotalWidth includes them }
    TotalColumns: Integer; { this field only used in descendants for fixed column wrapping }
    Spaces, JustifyStart: Integer; { number of spaces in this line (used for justification purpose }
    StartAttrib: TFontStyles; { starting static format attribute for this line }
    StartDynNb: Cardinal; { index of starting DynInfoRec in paragraph DynCodes array }
    Hidden: Boolean; { used only in WordWrap mode }
  end;
  pLineInfo = ^LineInfo;

  dInfoCollpsState = (pmdCollapsible, pmdCollapsed);
  dInfoCollpsStates = set of dInfoCollpsState;

  DynInfoRec = packed record
    DynOffset: LongInt; { as a DynInfoRec of a starting paragraph, this is the ref count }
    DynStyle: Byte;
    Level: -128..127;
    CollpsLevel: -128..127;
    CollpsState: dInfoCollpsStates;
    Backgnd, Foregnd: TColor;
    Context: Integer;
    Cursor: TCursor;
    KeyIndex: array[0..15] of SmallInt;
    case Integer of
    0: (Klen: LongWord);
    1: (StartKlen, StopKLen: Word);
  end;
  pDynInfoRec = ^DynInfoRec;

  TParState = (pmpHasExtra, pmpOwnTextBuffer, pmpFormatted, pmpSSDone, pmpKeywDone, pmpParseAll, pmpNoWrap, pmpHidden);
  TParStates = set of TParState;
  TDynInfoArray = array of DynInfoRec;

  TBlockState = (pmbLevel1, pmbLevel2, pmbLevel4, pmbLevel8, pmbLevel16, pmbCollapsed, pmbEndBlock, pmbStartBlock);
  TBlockStates = set of TBlockState;
  TBlocksCollapsed = set of 0..31;

  pParExtraInfo = ^ParExtraInfo;
  ParExtraInfo = packed record { a paragraph has a ParExtraInfo record allocated only if there is a reason for it }
    Foregnd, Backgnd: TColor;
    ParLength: Integer; { overrides value of ParInfo }
    FirstLine: LineInfo;
    StartDynAttrib: pDynInfoRec; { starting dynamic format attribute }
    Lines: array of LineInfo;
    DynCodes: TDynInfoArray;
    BlocksCollapsed: TBlocksCollapsed;
    pObject: TObject;
    StartBlockCount, StopBlockCount: Byte;
    HiddenLinesBefore: Integer; { used only in WordWrap mode }
  end;

  ParInfo = packed record { paragraph information structure: one such record exists for each paragraph }
    ParText: PChar; { Pointer to paragraph text, ends with #0 unless ParText is nil }
    StartOffset: Integer; { offset in characters from start for this paragraph }
    StartLine: Integer; { Line number of the first line of this paragraph (visible lines) }
    ParState: TParStates;
    BlockState: TBlockStates; { Block level (0..31) + 1bit for start of block, end of block and collapsed }
    case Integer of 0: (ParLength: Word; LineWidth: Word); 1: (ParExtra: pParExtraInfo)
  end;
  pParInfo = ^ParInfo;

  TBufferRecord = packed record Buf: PChar; FreeSpace, StopIndex: Integer end;
  { TBufferRecord is used to hold paragraph text inside of TParagraphsList }

  TPlusNavigator = class;

  TParagraphsList = class(TDynArray2) { used to hold internal information on each paragraph in a TPlusMemo }
  private
    fBufferList: array of TBufferRecord;
    fStaticFormat: Boolean;
    function  GetItem(i: Integer): ParInfo;
    procedure SetItem(i: Integer; const Item: ParInfo);
    function  getParPointers(i: Integer): pParInfo;
  public
    fModified: Boolean;
    fTextLen, fTrueLineCount, fVisibleLineCount: Integer;
    fModStartLine,
    fModStartPar,
    fModStopPar,
    fModLinesOffset,
    fLastStartStopParsed,
    fUpdateStartPar,
    fUpdateStopPar: Integer;
    fNoCompleteFormat: Boolean;
    fLoadPosition, fSavePosition: Integer;
    constructor Create;
    property Items[i: Integer]: ParInfo read GetItem write SetItem; default;
    property ParPointers[i: Integer]: pParInfo read getParPointers;
    property StaticFormat: Boolean read fStaticFormat write fStaticFormat;
    procedure ExtendMods(startpar, startline, stoppar: Integer);
    function CollapseExpandBlock(StartingParNb, Level: Integer; Collapse: Boolean): Boolean;
    function CollapseExpandPar(ParNb, StartLevel, EndLevel: Integer; Collapse: Boolean): Boolean;
    procedure LoadFromStream(Stream: TStream; Ascii: Boolean; NullReplacement: Char; DiscardTrailingSpaces: Boolean;
      var LineBreak: TpmsLineBreak;
      OnProgress: TNotifyEvent; Interval: Cardinal);
    procedure InsertBuf(t: PChar; Nav1, Nav2: TPlusNavigator; TrimSpaces, CheckFormat: Boolean;
      var LengthChange, LinesChange: Integer; var RemovedDyn: Boolean);
    procedure SaveToStream(Stream: TStream; Ascii, StripCodes, DiscardTrailingSpaces: Boolean; LineBreak: TpmsLineBreak;
      OnProgress: TNotifyEvent; Interval: Cardinal);
    procedure MakeCollapsibleBlock(StartPar, StopPar: Integer);
    procedure MarkUnformatted;
    procedure RemoveCollapsibleBlock(ParNumber: Integer);
    procedure UpdateOffsets(FromPar, OffChange: Integer);
    procedure UpdateLines(FromPar, Change: Integer);
    procedure UpdateOffsetsLines(FromPar, OffChange, LineChange: Integer);
    procedure CleanUp;
  end;

  TLinesList = class { Used to manage the LineInfo records of a paragraph }
  private
    fFirstLine: LineInfo;
  protected
    function  GetCount: Integer;
    procedure SetCount(NewCount: Integer);
    function  GetItem(i: Integer): LineInfo;
    procedure SetItem(i: Integer; const Item: LineInfo);
    function  GetLinesPointer(i: Integer): pLineInfo;
  public
    LLPar: pParInfo; { paragraph to which this TLinesList is attached }
    function Add(const Item: LineInfo): Integer;
    property Count: Integer read GetCount write SetCount;
    property Items[i: Integer]: LineInfo read GetItem write SetItem; default;
    property LinePointers[i: Integer]: pLineInfo read GetLinesPointer;
  end;

  TPlusMemoStrings = class(TStrings) { used as base class for TPlusMemo.Paragraphs and .Lines properties }
    { UCONVERT }
  private
    procedure ReadData(Reader: TReader);
    procedure WriteData(Writer: TWriter);
  protected
    procedure DefineProperties(Filer: TFiler); override;
    procedure SetUpdateState(StringsUpdating: Boolean); override;
    procedure SetTextStr(const Value: string); override;
    function GetTextStr: string; override;
    {$IFNDEF D2009Up}
    function GetItemsW(Index: Integer): WideString; virtual; abstract;
    procedure SetItemsW(Index: Integer; Value: WideString); virtual; abstract;
    {$ENDIF}
    {$IFDEF PMSUPPORTA}
    function GetItemsA(Index: Integer): AnsiString; virtual; abstract;
    procedure SetItemsA(Index: Integer; Value: AnsiString); virtual; abstract;
    {$ENDIF}
  public
    Memo: TComponent;
    procedure Assign(Source: TPersistent); override;
    procedure Clear; override;
    procedure LoadFromStream(Stream: TStream {$IFDEF D2009Up}; Encoding: TEncoding {$ENDIF}); override;
    procedure SaveToStream(Stream: TStream {$IFDEF D2009Up}; Encoding: TEncoding {$ENDIF}); override;

    {$IFDEF D2009Up}
    procedure SaveToFile(const FileName: string); override; // We want them to use owner TPlusMemo encoding, not Lines.Encoding
    procedure SaveToStream(Stream: TStream); override;
    {$ENDIF}

    {$IFNDEF D2009Up}
    property ItemsW[I: Integer]: WideString read getItemsW write setItemsW;
    function AddW(S: WideString): Integer;
    procedure InsertW(Index: Integer; S: WideString); virtual; abstract;
    procedure LoadFromStreamW(Stream: TStream);
    procedure SaveToStreamW(Stream: TStream);
    procedure LoadFromFileW(FileName: AnsiString);
    procedure SaveToFileW(FileName: AnsiString);
    procedure LoadFromFileAuto(FileName: AnsiString); // automatically detects if Unicode or Ansi file
    procedure SaveToFileWithSig(FileName: AnsiString); // writes the Unicode signature at the start of file
    {$ENDIF}
    {$IFDEF PMSUPPORTA}
    property ItemsA[I: Integer]: AnsiString read getItemsA write setItemsA;
    function AddA(S: AnsiString): Integer;
    procedure InsertA(Index: Integer; S: AnsiString); virtual; abstract;
    {$ENDIF}
  end;
  { /UCONVERT }

  TPlusParaStrings = class(TPlusMemoStrings) { property TPlusMemo.Paragraphs }
    { UCONVERT }
  protected
    function Get(Index: Integer): string; override;
    function GetCount: Integer; override;
    procedure Put(Index: Integer; const s: string); override;
    procedure PutObject(Index: Integer; AObject: TObject); override;
    function GetObject(Index: Integer): TObject; override;
    {$IFNDEF D2009Up}
    function GetItemsW(Index: Integer): WideString; override;
    procedure SetItemsW(Index: Integer; Value: WideString); override;
    {$ENDIF}
    {$IFDEF PMSUPPORTA}
    function GetItemsA(Index: Integer): AnsiString; override;
    procedure SetItemsA(Index: Integer; Value: AnsiString); override;
    {$ENDIF}
  public
    function  Add(const s: string): Integer; override;
    procedure Delete(Index: Integer); override;
    procedure Insert(Index: Integer; const s: string); override;
    {$IFNDEF D2009Up}
    procedure InsertW(Index: Integer; S: WideString); override;
    {$ENDIF}
    {$IFDEF PMSUPPORTA}
    procedure InsertA(Index: Integer; S: AnsiString); override;
    {$ENDIF}
  end;
  { /UCONVERT }

  TPlusLinesStrings = class(TPlusMemoStrings) { property TPlusMemo.Lines }
  protected
    { UCONVERT }
    fLinesStrings: TLinesList;
    function Get(Index: Integer): string; override;
    function GetCount: Integer; override;
    procedure Put(Index: Integer; const s: string); override;
    {$IFNDEF D2009Up}
    function GetItemsW(Index: Integer): WideString; override;
    procedure SetItemsW(Index: Integer; Value: WideString); override;
    {$ENDIF}
    {$IFDEF PMSUPPORTA}
    function GetItemsA(Index: Integer): AnsiString; override;
    procedure SetItemsA(Index: Integer; Value: AnsiString); override;
    {$ENDIF}
  public
    destructor Destroy; override;
    function  Add(const s: string): Integer; override;
    procedure Delete(Index: Integer); override;
    procedure Insert(Index: Integer; const s: string); override;
    {$IFNDEF D2009Up}
    procedure InsertW(Index: Integer; S: WideString); override;
    {$ENDIF}
    {$IFDEF PMSUPPORTA}
    procedure InsertA(Index: Integer; S: AnsiString); override;
    {$ENDIF}
  end;
  { /UCONVERT }

  TPlusNavigator = class { a class used to navigate in a TPlusMemo }
  private { internal fields computations are deferred as much as possible }
    fAdjustRight: Boolean; { with special values indicating yet undetermined.  The basic property is }
    fOnFree: TNotifyEvent; { Pos, from which all others are derived }
    function  GetOffset: Integer;
    procedure setParOffset(off: Integer);
    function  GetDynNb: Integer;
    procedure setDynNb(Value: Integer);
    procedure SetPos(p: Integer);
    function  GetParNb: Integer;
    procedure setParNb(pnb: Integer);
    function  GetLineNb: Integer;
    procedure SetLineNb(l: Integer);
    function  GetColNb: Integer;
    procedure SetColNb(c: Integer);
    function  GetParLine: Integer;
    procedure SetParLine(pl: Integer);
    function  GetPar: pParInfo;
    function  GetText: Char;
    function  GetAnsiText: AnsiChar;
    function  GetDynInfo: DynInfoRec;
    function  GetpDynInfo: pDynInfoRec;
    function  GetStyle: TFontStyles;
    function  GetNavLines: TLinesList;
    function  GetContext: Integer;
    function  GetDisplayPos: TPoint;
    function  GetWord: string;
    procedure SetDisplayPos(DispPos: TPoint);
    procedure SetDisplayX(X: Integer);
    function GetDisplayX: Integer;
    procedure setDisplayY(Y: Integer);
    function GetDisplayY: Integer;
    function GetLine: string;
    function getDisplayWidth: Integer;
    function getVisibleLineNumber: Integer;
    procedure setVisibleLineNumber(ln: Integer);
    function getIsVisible: Boolean;

  public
    fPMemo: TComponent; { the TPlusMemo this navigator is attached to }
    fPos: LongInt; { the position of this nav. (offset in chars from the start of text }
    fPar: pParInfo; { an unknown paragraph is indicated by both fPar=nil }
    fParNb: LongInt; { and fParNb<0 }
    fOffset, fDynNb: Integer; { unknown dynattributes indicated by fDynNb<0 }
    fParLine: Integer; { line number in current paragraph corresponding to position fPos, <0 if unknown }
    fNavLines: TLinesList; { a TLinesList is created and used internally whenever necessary }
    fFreeOnDelete: Boolean; // set to True to have this navigator destroyed when the range of text containing it is erased
    fExtra: Integer;

    constructor Create(APlusMemo: TComponent);
    destructor  Destroy; override;
    procedure AddDyn(const dyn: DynInfoRec);
    function AdvanceDyn: Boolean;
    procedure Assign(Source: TPlusNavigator);
    function  BackToDyn(Min: LongInt): Boolean;
    function Collapse(DoOuterSection: Boolean = False): Boolean; // dynamic section where we are
    function Expand(DoOuterSection: Boolean = False): Boolean; // dynamic section where we are
    function ExpandAllLevels: Boolean; // expand current dynamic section and all outers
    function  ForwardToDyn(Max: LongInt): Boolean;
    procedure GetTextBuf(Buffer: PChar; Len: Integer); { Buffer must be at least Len+1 long }
    function PreviousDyn: Boolean;
    function NextDyn: Boolean;
    function GetCollapseLevels(var StartLevel, EndLevel, BarLevel: Integer): Boolean; // returns True if collapsed
    procedure Invalidate;
    procedure RemoveDyn;
    procedure RightOfDyn;
    procedure ToEndOfWord(const Dels: TSysCharSet);
    procedure ToNextWord(const Dels: TSysCharSet);
    procedure ToPreviousWord(const Dels: TSysCharSet);
    procedure ToStartOfWord(const Dels: TSysCharSet);
    property AdjustRight: Boolean read fAdjustRight write fAdjustRight;
    property FreeOnDelete: Boolean read fFreeOnDelete write fFreeOnDelete;
    property DisplayPos: TPoint read getDisplayPos write setDisplayPos;
    property DisplayX: Integer read getDisplayX write setDisplayX;
    property DisplayY: Integer read getDisplayY write setDisplayY;
    property DisplayWidth: Integer read getDisplayWidth;
    property IsVisible: Boolean read getIsVisible;
    property Pos: LongInt read fPos write setPos;
    property ParNumber: LongInt read getParNb write setParNb;
    property TrueLineNumber: LongInt read getLineNb write setLineNb;
    property VisibleLineNumber: Integer read getVisibleLineNumber write setVisibleLineNumber;
    property Col: Integer read getColNb write setColNb;
    property ParOffset: Integer read getOffset write setParOffset;
    property ParLine: Integer read getParLine write setParLine;
    property Text: Char read getText;
    property AnsiText: AnsiChar read getAnsiText;
    property Line: string read GetLine;
    property Word: string read GetWord;
    property Style: TFontStyles read GetStyle;
    property DynNb: Integer read GetDynNb write setDynNb;
    property Par: pParInfo read GetPar;
    property DynAttr: DynInfoRec read GetDynInfo;
    property pDynAttr: pDynInfoRec read GetpDynInfo;
    property Context: Integer read GetContext;
    property NavLines: TLinesList read GetNavLines;
    property OnFree: TNotifyEvent read fOnFree write fOnFree;
  end;

  TPlusHighlighter = class(TComponent, IpmsNotify)
  private
  protected
    procedure ApplyKeywordsList(Start, Stop: TPlusNavigator; BaseIndex: Integer); virtual;
    function FindStart(Start, Stop: TPlusNavigator; BaseIndex: Integer): Boolean; virtual;
    function FindStop(Start, Stop: TPlusNavigator; BaseIndex: Integer): Boolean; virtual;
    procedure Notify(Sender: TComponent; Events: TpmEvents); virtual;
  public
    MemoList: TList;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function FixRange(Start, Stop: TPlusNavigator; KeywordBase, SSBase: Integer): Boolean; virtual;
  end;

  TWordOption = (woMatchCase, woWholeWordsOnly, woFirstParWord, woFirstNonBlank, woStartPar);
  TWordOptions = set of TWordOption;

  TKeywordInfo = packed record
    Options: TWordOptions;
    Style: TFontStyles;
    ContextNumber: Integer;
    Cursor: TCursor;
    Backgnd, Foregnd: TColor
  end;

  pKeyInfo = ^TKeywordInfo;
  pKeyInfoLen = ^TKeyInfoLen;
  TKeyInfoLen = record
    BasicPart: TKeywordInfo;
    KeywordOrg, KeywordTrans: string;
    KeyLen, Scope, Priority, Extra: Integer;
  end;

  TKeywordList = class(TStrings)
  private
    fKeyList: TList; // list of TKeyInfoLen records
    fGWOptions: TWordOptions;
    fUpdating: Boolean;
    fUpperCaseType: TpmUpperCase;
    fResetKeywords: Boolean;
    procedure setUpperCaseType(ut: TpmUpperCase);
    function getKeywords(Index: Integer): string;
    procedure setKeywords(Index: Integer; const Value: string);
    function getKeyList: TList;
  protected
    fLongestKeyword: Integer;
    procedure setKeyInfo(i: Integer; wi: TKeywordInfo);
    function  getKeyInfo(i: Integer): TKeywordInfo;
    procedure SetUpdateState(Updating: Boolean); override;
    procedure DefineProperties(Filer: TFiler); override;
    function Get(Index: Integer): { UCONVERT } string { /UCONVERT } ; override;
    function GetCount: Integer; override;
  public
    procedure ReadData(Reader: TReader);
    procedure WriteData(Writer: TWriter);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure Clear; override;
    procedure Delete(i: Integer); override;
    procedure Insert(Index: Integer; const S: { UCONVERT } string { /UCONVERT } ); override;
    function AddKeyWord(const KeyWord: string; Options: TWordOptions;
      Style: TFontStyles; ContextNumber: Integer;
      Cursor: TCursor;
      Backgnd, Foregnd: TColor): Integer;
    procedure LoadFromIniStrings(IniStrings: TStrings); virtual;
    procedure SaveToIniStrings(IniStrings: TStrings); virtual;
    property KeyList: TList read getKeyList;
    property KeyInfos[i: Integer]: TKeywordInfo read getKeyInfo write setKeyInfo;
    property UpperCaseType: TpmUpperCase read fUpperCaseType write setUpperCaseType;
    property Keywords[Index: Integer]: string read getKeywords write setKeywords;
    property GlobalWordOptions: TWordOptions read fGWOptions;
    property ResetKeywords: Boolean read fResetKeywords write fResetKeywords;
  end;

  TssOption = (ssoParStop, ssoDelStop, ssoCollapsible); // ssoDelStp and ssoCollapsible are
  TssOptions = set of TssOption; // effective only in TExtHighlighter or custom engines

  StartStopInfo = packed record
    Attributes: TKeywordInfo;
    StartKey, StopKey: PChar;
    StartLen, StopLen: SmallInt;
    StartCheckLen: SmallInt; // v6.5a
    StartKeyStr, StopKeyStr: string;
    Scope, Priority, Extra: Integer;
    Previous: SmallInt;
    ssOptions: TssOptions;
    StartRightCheck, StartLeftCheck,
    StopRightCheck, StopLeftCheck: Boolean;
  end;
  pStartStopInfo = ^StartStopInfo;

  TStartStopKeyList = class(TDynArray2)
  private
    fUpperCaseType: TpmUpperCase;
    fGWOpt: TWordOptions;
    procedure setUpperCaseType(ut: TpmUpperCase);
  protected
    fLongestStartKey, fLongestStopKey: SmallInt;
    fDelChecked: Boolean;
    procedure DefineProperties(Filer: TFiler); override;
  public
    procedure ReadData(Reader: TReader);
    procedure WriteData(Writer: TWriter);
    constructor Create;
    destructor  Destroy; override;
    property LongestStartKey: SmallInt read fLongestStartKey;
    property DelChecked: Boolean  read fDelChecked write fDelChecked;
    property GlobalWordOptions: TWordOptions read fGWOpt;
    property UpperCaseType: TpmUpperCase read fUpperCaseType write setUpperCaseType;

    procedure Clear;
    function  AddStartStopKey(const StartKey, StopKey: string;
      Options: TWordOptions;
      Style: TFontStyles;
      ContextNumber: Integer;
      Cursor: TCursor;
      Backgnd, Foregnd: TColor;
      EndAtPar: Boolean): Integer;
    procedure LoadFromIniStrings(IniStrings: TStrings); virtual;
    procedure SaveToIniStrings(IniStrings: TStrings); virtual;
  end;

  TpmFormatThread = class(TThread)
  private
    fMemo: TObject;
    fFormatEvent: TEvent;
    procedure UpdateChunck;
  protected
    procedure Execute; override;
  public
    constructor Create(AMemo: TObject);
    destructor Destroy; override;
    procedure PutToEnd(Final: Boolean = False);
    property FormatEvent: TEvent read fFormatEvent;
  end;

  pmHDC = HDC;

  IpmCollapseHandler = interface
      {$IFDEF PMSupportU}
    ['{CB8BC1F3-8502-4AEB-9465-150E97B9F730}']
      {$ELSE}
        {$IFDEF PMSUPPORTA}
    ['{EB78EFEC-06AC-4C68-A99D-8DECE442A6FB}']
        {$ELSE}
    ['{DF25A9E7-E02B-4763-99B0-0341F0DE3D74}']
        {$ENDIF}
      {$ENDIF}
    procedure LinkMemo(Sender: TComponent; Attach: Boolean);
    procedure PaintLine(Sender: TComponent; Canvas: pmHDC; Xpos, Height: Integer; const par: ParInfo; const line: LineInfo);
  end;

  TpmsCollapseHandler = class(TComponent);

    { Paragraph operation routines }

function  ColToOffset(par: pParInfo; Col, Tabs: Integer; Static: Boolean): Integer;

function  OffsetToCol(par: pParInfo; Offset, Tabs: Integer; Static: Boolean): Integer;

function  ColToExtra(par: pParInfo; Col, Tabs: Integer; Static: Boolean): Integer;

procedure MakeOwnTextBuffer(parlist: TParagraphsList; parindex: Integer; par: pParInfo);

procedure SetParExtras(var par: ParInfo);

function  GetParLength(const par: ParInfo): Integer;

procedure SetParLength(var par: ParInfo; Len: Integer);

procedure SetDynCount(var par: ParInfo; Count: Integer);

function  GetDynCount(const par: ParInfo): Integer;

function  GetDynArray(const par: ParInfo): TDynInfoArray;

function  GetStartDynAttrib(const par: ParInfo): pDynInfoRec;

procedure SetStartDynAttrib(var par: ParInfo; DynAttrib: pDynInfoRec; UniqueRef: Boolean);

function  GetLineCount(const par: ParInfo): Integer;

function  GetStartAttrib(const par: ParInfo): TFontStyles;

procedure SetStartAttrib(var par: ParInfo; attrib: TFontStyles);

function  pmsGetParBackgnd(const par: ParInfo): TColor;

procedure pmsSetParBackgnd(var par: ParInfo; Color: TColor);

function  pmsGetParForegnd(const par: ParInfo): TColor;

procedure pmsSetParForegnd(var par: ParInfo; Color: TColor);

function  pmsGetParCollapsed(const par: ParInfo; Level: Integer): Boolean;

function  pmsGetParBlockStartLevel(const par: ParInfo): Integer;

function  pmsGetParBlockEndLevel(const par: ParInfo): Integer;

procedure pmsGetParLevels(const Par: ParInfo; const Line: LineInfo; var StartLevel, EndLevel, BarLevel: Integer;
  var Collapsed: Boolean);

procedure SetParDyns(var par: ParInfo; Dyns: TDynInfoArray);

function  GetFirstLine(const par: ParInfo): LineInfo;

procedure SetFirstLine(var par: ParInfo; const Line: LineInfo);

procedure ReformatParP(APMemo: TObject;
  DC: TCanvas;
  InitDC: Boolean; FormWidth: Integer;
  Par: pParInfo;
  ParNum: LongInt;
  var FirstLine, LastChanged: Integer;
  CompleteReformat: Boolean;
  var OldFontH: THandle;
  var RunningSpaceWidth, SpaceKern, LinesChange, LinesCount: Integer);

{ Parser helper routines }

procedure ApplyKeywordsListP(Start, Stop: TPlusNavigator);

procedure ApplyStartStopKeyListP(Start, Stop: TPlusNavigator; var FinalDyn: DynInfoRec);

function  FindStop(Start, Stop: TPlusNavigator): Boolean; { Start and Stop must be in the same par. }

function  FindStart(Start, Stop: TPlusNavigator): Boolean; { Start and Stop must be in the same par. }

procedure SetDynStyleP(PList: TParagraphsList; Start, Stop: TPlusNavigator; dinfo: DynInfoRec;
  AddDInfo, ExtendModFields: Boolean);

{$IFNDEF D2009Up}
{ PWideChar helper routines }

function  WideStrAlloc(Len: Integer): PWideChar;

procedure WideStrDispose(Buf: PWideChar);

function  WideStrBufSize(Buf: PWideChar): Integer;

function  WideStrLen(t: PWideChar): Integer;

function  WideStrNew(Buf: PWideChar): PWideChar;

function  WideStringOfChar(Ch: WideChar; Len: Integer): WideString;

function  WideStrPCopy(Dest: PWideChar; const Source: WideString): PWideChar;

function  WideStrComp(Str1, Str2: PWideChar): Integer;

function  WideStrPos(const Str1, Str2: PWideChar): PWideChar;

function  WideStrScan(t: PWideChar; c: WideChar): PWideChar;

function  WideStrUpper(t: PWideChar): PWideChar;
{$ENDIF}

{ Dynrecord helper routines }

procedure RemoveRef(d: pDynInfoRec);

function  DynToLevel(const dyn: DynInfoRec): SmallInt;

function  DynToContext(const drec: DynInfoRec): Integer;

function  DynToCollapseLevel(const dyn: DynInfoRec): Integer;

{ Painting helper routines }

procedure WavyLine(dc: pmHDC; XStart, XStop, Y, Amplitude: Integer);

function GetTextWidth(hdc: pmHDC; T: PChar; nChars, MaxOneShotChars: Integer): Integer;

procedure PutText(dc: pmHDC;
  var pos: TPoint; T: PChar; nChars, MaxOneShot, RLimit: Integer; ShowSpaces: Boolean; SpcWidth: Integer; UpCase: Boolean);

{ Misc. helpers }

function pmMaxOf(i1, i2: LongInt): LongInt;

function pmMinOf(l1, l2: LongInt): LongInt;

procedure pmRect16(var R: TRect);

function  pmStrScan(t: PChar; c: Char): PChar; { replacement for SysUtils, much faster for long PChars }

procedure pmCharUpper(t: PChar);

function pmStrBufSize(t: PChar): Cardinal; { replacement for StrBufSize, which does not return the number of chars in D2009 }

procedure XORStyleCode(var Style: TFontStyles; Code: Char);

procedure InvalidateNavs(NavList: TList; startpos, lastpar: LongInt);

function  StripCodes(const s: string): string;

function  FindTextP(APlusMemo: TObject; const fText: string; GoForward, MatchCase, WholeWordsOnly, Global: Boolean): Boolean;

const pmsCBlockLevel = [pmbLevel1, pmbLevel2, pmbLevel4, pmbLevel8, pmbLevel16];

implementation

uses
  PlusMemo7, Forms {$IFDEF D7New}, StrUtils {$ENDIF} {$IFDEF DXE3Up}, System.Types {$ENDIF};

  {$IFNDEF PMDEBUG}
    {$R-}
    {$Q-}
  {$ENDIF}

  {$IFNDEF D2009Up}
{ PWideChar helper routines }

function  WideStrAlloc(Len: Integer): PWideChar;
begin
  { UCONVERT }
  Result := PWideChar(StrAlloc(Len * 2))
  { /UCONVERT }
end;

procedure WideStrDispose(Buf: PWideChar);
begin
  { UCONVERT }
  StrDispose(PChar(Buf))
  { /UCONVERT }
end;

function WideStrBufSize(Buf: PWideChar): Integer;
begin
  { UCONVERT }
  Result := StrBufSize(PChar(Buf)) div 2
  { /UCONVERT }
end;

function WideStrNew(Buf: PWideChar): PWideChar;
var slen: Integer;
begin
  slen := WideStrLen(Buf);
  Result := WideStrAlloc(slen + 1);
  if Buf <> nil then
    Move(Buf^, Result^, (slen + 1) * SizeOf(WideChar))
  else
    Result^ := #0
end;

function WideStringOfChar(Ch: WideChar; Len: Integer): WideString;
var i: Integer;
begin
  SetLength(Result, Len);
  for i := 1 to Len do
    Result[i] := Ch
end;

function WideStrLen(t: PWideChar): Integer;
var tscan: PWideChar;
begin
  Result := 0;
  if t <> nil then
  begin
    tscan := t;
    while tscan^ <> #0 do
      Inc(tscan);
    Result := tscan - t
  end
end;

function WideStrPCopy(Dest: PWideChar; const Source: WideString): PWideChar;
var scan: PWideChar;
begin
  Result := Dest;
  if Source <> '' then
  begin
    scan := PWideChar(Source);
    while scan^ <> #0 do
    begin
      Dest^ := scan^;
      Inc(Dest);
      Inc(scan)
    end
  end;
  Dest^ := #0
end;

function WideStrComp(Str1, Str2: PWideChar): Integer;
begin
  Result := 1;
  while (Str1^ <> #0) do
    if Str1^ <> Str2^ then
      Exit
    else
    begin
      Inc(Str1);
      Inc(Str2)
    end;
  if Str2^ = #0 then
    Result := 0
end;

function WideStrScan(t: PWideChar; c: WideChar): PWideChar;
begin
  Result := t;
  if Result <> nil then
  begin
    while (Result^ <> #0) and (Result^ <> c) do
      Inc(Result);
    if Result^ = #0 then
      Result := nil
  end
end;

function WideStrUpper(t: PWideChar): PWideChar;
begin
  Result := t;
  if t <> nil then
    while t^ <> #0 do
    begin
      if (t^ >= 'a') and (t^ <= 'z') then
        t^ := WideChar(Ord(t^) - 32);
      Inc(t)
    end
end;

function CompareWideChars(s1, s2: PWideChar; len: Integer): Boolean;
begin
  Result := True;
  while len > 0 do
    if s1^ <> s2^ then
    begin
      Result := False;
      Break
    end else
    begin
      Inc(s1);
      Inc(s2);
      Dec(len)
    end
end;

function WideStrPos(const Str1, Str2: PWideChar): PWideChar;
var found: Boolean; str2len: Integer;
begin
  found := False;
  Result := str1;
  str2len := WideStrLen(str2);
  repeat
    Result := WideStrScan(Result, str2^);
    if Result <> nil then
    begin
      found := CompareWideChars(Result, str2, str2len);
      if not found then
        Inc(Result)
    end;
  until (Result = nil) or found
end;
  {$ENDIF}  // D2009 and up

const
  DefaultDyn: DynInfoRec = (// used for StartDynAttr of paragraphs that don't start with a dyn style
    DynOffset: 0;
    DynStyle: 0;
    Level: 0;
    CollpsLevel: 0;
    CollpsState: [];
    Backgnd: -1;
    Foregnd: -1;
    Context: 0;
    Cursor: 0;
    KeyIndex: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
    Klen: 0);

function XORStyle(style: TFontStyles; element: TFontStyle): TFontStyles;
begin
  if element in style then
    Result := style - [element]
  else
    Result := style + [element]
end;

procedure XORStyleCode(var Style: TFontStyles; Code: Char);
var element: TFontStyle; isformatchar: Boolean;
begin
  isformatchar := True;
  element := fsBold;
  { to avoid a warning }
  case Code of
    ctrlUnderline: element := fsUnderline;
    ctrlItalic: element := fsItalic;
    ctrlBold: element := fsBold;
    ctrlHighlight: TPlusFontStyle(element) := TPlusFontStyle(fsHighlight);
    ctrlAltFont: TPlusFontStyle(element) := TPlusFontStyle(fsAltFont)
    else
      isformatchar := False
  end;
  if isformatchar then
    Style := XORStyle(Style, element)
end;

function StripCodes(const s: string): string;
var i, j, len: Integer;
begin
  len := Length(s);
  SetLength(Result, len);
  i := 1;
  j := 1;
  while i <= len do
  begin
    if (s[i] >= #26) or (not(AnsiChar(s[i]) in CtrlCodesSet)) then
    begin
      Result[j] := s[i];
      Inc(j)
    end;
    Inc(i)
  end;
  if i <> j then
    SetLength(Result, j - 1)
end;

{ DynInfoRec managements }

procedure RemoveRef(d: pDynInfoRec);
begin
  if d = nil then
    Exit;
  if d <> @DefaultDyn then
  begin
    Dec(d^.DynOffset);
    if d^.DynOffset = 0 then
      Dispose(d)
  end
end;

function CreateRef(const d: DynInfoRec): pDynInfoRec;
begin
  New(Result);
  Result^ := d;
  Result^.DynOffset := 1
end;

{ Painting helper routines }

procedure WavyLine(dc: {$IFDEF pmClx} TCanvas {$ELSE} HDC {$ENDIF}; XStart, XStop, Y, Amplitude: Integer);
begin
  if XStart < -32768 then
    XStart := -32768;
  if XStop > 32767 then
    XStop := 32767;
      {$IFDEF pmClx}
  dc.MoveTo(XStart, Y + Amplitude);
      {$ELSE}
  MoveToEx(dc, XStart, Y + Amplitude, nil);
      {$ENDIF}
  while XStart < XStop do
  begin
    Inc(Xstart, Amplitude);
    if XStart >= XStop then
      {$IFDEF pmClx}
      dc.LineTo(XStop, Y + Amplitude - (XStart - XStop))
      {$ELSE}
      LineTo(dc, XStop, Y + Amplitude - (XStart - XStop))
      {$ENDIF}
    else
    begin
      {$IFDEF pmClx}
      dc.LineTo(XStart, Y);
      {$ELSE}
      LineTo(dc, XStart, Y);
      {$ENDIF}
      Inc(XStart, Amplitude);
      {$IFDEF pmClx}
      if XStart >= XStop then
        dc.LineTo(XStop, Y + (XStart - XStop))
      else
        dc.LineTo(XStart, Y + Amplitude)
      {$ELSE}
      if XStart >= XStop then
        LineTo(dc, XStop, Y + (XStart - XStop))
      else
        LineTo(dc, XStart, Y + Amplitude)
      {$ENDIF}
    end
  end
end;

function GetTextWidth(hdc: pmHDC; T: PChar; nChars, MaxOneShotChars: Integer): Integer;
  { essentially GetTextExtentPoint, but able to handle more than 32K pixels wide }
var s: TSize; todo: Integer;
begin
  Result := 0;
  while nChars > 0 do
  begin
    if nChars > MaxOneShotChars then
      todo := MaxOneShotChars
    else
      todo := nChars;
    GetTextExtentPoint32(hdc, T, todo, s);
    Inc(T, todo);
    Inc(Result, s.cX);
    Dec(nChars, todo)
  end
end;

procedure PutText(dc: pmHDC;
  var pos: TPoint; T: PChar; nChars, MaxOneShot, RLimit: Integer; ShowSpaces: Boolean; SpcWidth: Integer; UpCase: Boolean);
{ essentially ExtTextOut, but works around 16bit GDI limitation }
var tscan: PChar; todo: Integer; s: TSize; supper: string; i: Integer;
begin
  if UpCase then
  begin
    SetLength(supper, nChars);
    Move(T^, supper[1], nChars * SizeOf(supper[1]));
    //supper:= UpperCase(supper);
    T := PChar(supper);
    for i := 0 to Length(supper) - 1 do
    begin
      case T^ of
        'a'..'z': T^ := Char(Ord(T^) xor $20)
      end;
      Inc(T)
    end;
    T := PChar(supper)
  end;

  while (nChars > 0) and (pos.X <= Low(SmallInt) div 2) do
  begin
    if nChars > MaxOneShot then
      todo := MaxOneShot
    else
      todo := nChars;
    GetTextExtentPoint32(dc, T, todo, s);
    Inc(pos.X, s.cX);
    Inc(T, todo);
    Dec(nChars, todo)
  end;

  while (nChars > 0) and (pos.X < RLimit) do
  begin
    if nChars > MaxOneShot then
      todo := MaxOneShot
    else
      todo := nChars;
    if ShowSpaces then
    begin
      tscan := T;
      while tscan - T < todo do
        if tscan^ = ' ' then
        begin
          todo := tscan - T;
          Break
        end else
          Inc(tscan);
    end;

    MoveToEx(dc, pos.X, pos.Y, nil);
    ExtTextOut(dc, 0, 0, 0, nil, T, todo, nil);
    GetCurrentPositionEx(dc, @pos);

    if ShowSpaces and (todo < nChars) and (T[todo] = ' ') then
    begin
      ExtTextOut(dc, 0, 0, 0, nil, #183, 1, nil);
      Inc(pos.X, SpcWidth);
      Inc(todo)
    end;
    Inc(T, todo);
    Dec(nChars, todo);
  end
end;

{ Misc. helpers }

function pmStrScan(t: PChar; c: Char): PChar; { better than the one supplied in SysUtils for long strings }
begin
  if t = nil then
    Result := nil
  else
  begin
    while (t^ <> #0) and (t^ <> c) do
      Inc(t);
    if t^ = #0 then
      Result := nil
    else
      Result := t
  end
end;

{$IFDEF PMSupportU}

function pmChar(c: Char): AnsiChar;
begin
  if c < #255 then
    Result := AnsiChar(c)
  else
    Result := #255
end;
{$ENDIF}
{$IFDEF D2009Up}
{$IFNDEF PMSUPPORTA}

function pmChar(c: Char): AnsiChar;
begin
  if c < #255 then
    Result := AnsiChar(c)
  else
    Result := #255
end;
    {$ENDIF}
{$ENDIF}

function pmStrBufSize(t: PChar): Cardinal; { replacement for StrBufSize, which does not return the number of chars in D2009 }
begin
  Result := StrBufSize(t);
  {$IFNDEF PMSUPPORTA}
    {$IFDEF D2009Up}
      {$IFNDEF DXEUp}
  Result := Result div 2;
  // DelphiXE does not need this
      {$ENDIF}
    {$ENDIF}
  {$ENDIF}
end;

procedure pmCharUpper(t: PChar);
begin
  if t <> nil then
    CharUpper(t)
end;

procedure pmRect16(var R: TRect);
begin
  if R.Left < Low(SmallInt) then
    R.Left := Low(SmallInt);
  if R.Right < Low(SmallInt) then
    R.Right := Low(SmallInt);
  if R.Left > High(SmallInt) then
    R.Left := High(SmallInt);
  if R.Right > High(SmallInt) then
    R.Right := High(SmallInt)
end;

function pmMaxOf(i1, i2: LongInt): LongInt;
begin
  if i1 < i2 then
    Result := i2
  else
    Result := i1
end;

function pmMinOf(l1, l2: LongInt): LongInt;
begin
  if l1 < l2 then
    Result := l1
  else
    Result := l2
end;

function DynToLevel(const dyn: DynInfoRec): SmallInt;
begin
  if dyn.DynStyle and $C0 <> $C0 then
    Result := -1
  else
    Result := dyn.Level
end;

function DynToContext(const drec: DynInfoRec): Integer;
begin
  if drec.DynStyle and $80 = 0 then
    Result := 0
  else
    Result := drec.Context
end;

function DynToCollapseLevel(const dyn: DynInfoRec): Integer;
begin
  if dyn.DynStyle and $80 <> 0 then
    Result := dyn.CollpsLevel
  else
    Result := 0
end;

{ Paragraph helper routines }

function ColToOffset(par: pParInfo; Col, Tabs: Integer; Static: Boolean): Integer;
var i, plen: Integer;
begin
  Result := 0;
  i := 0;
  plen := GetParLength(par^);
  if Static then
    while (Result < plen) and (i < Col) do
    begin
      if (par.ParText[Result] < #26) and (AnsiChar(par.ParText[Result]) in (CtrlCodesSet + [#9])) then
      begin
        if par.ParText[Result] = #9 then
          if Tabs > 0 then
            i := Tabs * (i div Tabs + 1)
          else
            Inc(i)
      end else
        Inc(i);
      if i <= Col then
        Inc(Result)
    end else
      while (Result < plen) and (i < Col) do
      begin
        if (par.ParText[Result] <> #9) or (Tabs <= 0) then
          Inc(i)
        else
          i := Tabs * (i div Tabs + 1);
        if i <= Col then
          Inc(Result)
      end;
end;

function OffsetToCol(par: pParInfo; Offset, Tabs: Integer; Static: Boolean): Integer;
var i: Integer;
begin
  Result := 0;
  i := 0;
  if Tabs = 0 then
    Tabs := 1;
  if Static then
    while i < Offset do
    begin
      if (par.ParText[i] < #26) and (AnsiChar(par.ParText[i]) in (CtrlCodesSet + [#9])) then
      begin
        if par.ParText[i] = #9 then
          if Tabs > 0 then
            Result := Tabs * (Result div Tabs + 1)
          else
            Inc(Result)
      end else
        Inc(Result);
      Inc(i)
    end else
      while i < Offset do
      begin
        if par.ParText[i] = #9 then
          Result := Tabs * (Result div Tabs + 1)
        else
          Inc(Result);
        Inc(i)
      end;
end;

function ColToExtra(par: pParInfo; Col, Tabs: Integer; Static: Boolean): Integer;
var i, scol, off, plen: Integer;
begin
  off := ColToOffset(par, Col, Tabs, Static);
  i := 0;
  scol := 0;
  plen := GetParLength(par^);
  if Static then
    while (i < plen) and (i < off) do
    begin
      if (Par.ParText[i] < #26) and (AnsiChar(par.ParText[i]) in (CtrlCodesSet + [#9])) then
      begin
        if (par.ParText[i] = #9) and (Tabs > 0) then
          scol := Tabs * (scol div Tabs + 1)
      end else
        Inc(scol);
      Inc(i);
    end else
      while (i < plen) and (i < off) do
      begin
        if (par.ParText[i] <> #9) or (Tabs = 0) then
          Inc(scol)
        else
          scol := Tabs * (scol div Tabs + 1);
        Inc(i);
      end;
  Result := Col - scol
end;

procedure MakeOwnTextBuffer(parlist: TParagraphsList; parindex: Integer; par: pParInfo);
var st: PChar; plen: Integer;
begin
  if par = nil then
    par := parlist.Pointers[parindex];
  if not(pmpOwnTextBuffer in par.ParState) then
  begin
    plen := GetParLength(par^);
    if plen > 0 then
    begin
      st := StrAlloc(plen + 1);
      Move(par.ParText^, st^, (plen + 1) * SizeOf(par.ParText^))
    end else
      st := nil;
    Include(par.ParState, pmpOwnTextBuffer);
    par.ParText := st
  end
end;

procedure SetParExtras(var par: ParInfo);
var spextra: pParExtraInfo;
begin
  if not(pmpHasExtra in par.ParState) then
  begin
    New(spextra);
    spextra.Foregnd := -1;
    spextra.Backgnd := -1;
    spextra.pObject := nil;
    spextra.ParLength := par.ParLength;
    spextra.FirstLine.Start := 0;
    spextra.FirstLine.Stop := par.ParLength;
    spextra.FirstLine.LineWidth := par.LineWidth;
    spextra.FirstLine.TotalWidth := par.LineWidth;
    spextra.FirstLine.Spaces := 0;
    spextra.FirstLine.JustifyStart := par.ParLength;
    spextra.FirstLine.StartAttrib := [];
    spextra.FirstLine.StartDynNb := 0;
    spextra.StartDynAttrib := @DefaultDyn;
    spextra.BlocksCollapsed := [];
    if pmbStartBlock in par.BlockState then
      spextra.StartBlockCount := 1
    else
      spextra.StartBlockCount := 0;
    if pmbEndBlock in par.BlockState then
      spextra.StopBlockCount := 1
    else
      spextra.StopBlockCount := 0;
    par.ParExtra := spextra;
    Include(par.ParState, pmpHasExtra)
  end
end;

function GetParLength(const par: ParInfo): Integer;
begin
  if pmpHasExtra in par.ParState then
    Result := par.ParExtra.ParLength
  else
    Result := par.ParLength
end;

procedure SetParLength(var par: ParInfo; Len: Integer);
begin
  if pmpHasExtra in par.ParState then
    par.ParExtra.ParLength := Len
  else if Len < High(Word) then
    par.ParLength := Len
  else
  begin
    SetParExtras(par);
    par.ParExtra.ParLength := Len
  end
end;

procedure SetDynCount(var par: ParInfo; Count: Integer);
begin
  if not(pmpHasExtra in par.ParState) and (Count > 0) then
    SetParExtras(par);
  if pmpHasExtra in par.ParState then
    SetLength(par.ParExtra.DynCodes, Count)
end;

function GetDynCount(const par: ParInfo): Integer;
begin
  if pmpHasExtra in par.ParState then
    Result := Length(par.ParExtra.DynCodes)
  else
    Result := 0
end;

function GetDynArray(const par: ParInfo): TDynInfoArray;
begin
  if pmpHasExtra in par.ParState then
    Result := par.ParExtra.DynCodes
  else
    Result := nil
end;

function GetStartDynAttrib(const par: ParInfo): pDynInfoRec;
begin
  if pmpHasExtra in par.ParState then
    Result := par.ParExtra.StartDynAttrib
  else
    Result := @DefaultDyn
end;

procedure SetStartDynAttrib(var par: ParInfo; DynAttrib: pDynInfoRec; UniqueRef: Boolean);
var isdyn: Boolean;
begin
  if pmpHasExtra in par.ParState then
    RemoveRef(par.ParExtra.StartDynAttrib);
  if DynAttrib = nil then
    DynAttrib := @DefaultDyn;
  isdyn := DynAttrib.DynStyle and $80 <> 0;
  if not(pmpHasExtra in par.ParState) and isdyn then
    SetParExtras(par);
  if not isdyn then
  begin
    if pmpHasExtra in par.ParState then
      par.ParExtra.StartDynAttrib := @DefaultDyn
  end else
  begin
    if UniqueRef then
      par.ParExtra.StartDynAttrib := CreateRef(DynAttrib^)
    else
    begin
      par.ParExtra.StartDynAttrib := DynAttrib;
      Inc(DynAttrib.DynOffset)
    end
  end
end;

function GetLineCount(const par: ParInfo): Integer;
begin
  if pmpHasExtra in par.ParState then
    Result := Length(par.ParExtra.Lines) + 1
  else
    Result := 1
end;

function GetStartAttrib(const par: ParInfo): TFontStyles;
begin
  if pmpHasExtra in par.ParState then
    Result := par.ParExtra.FirstLine.StartAttrib
  else
    Result := []
end;

procedure SetStartAttrib(var par: ParInfo; attrib: TFontStyles);
begin
  if pmpHasExtra in par.ParState then
    par.ParExtra.FirstLine.StartAttrib := attrib
  else if attrib <> [] then
  begin
    SetParExtras(par);
    par.ParExtra.FirstLine.StartAttrib := attrib
  end
end;

function pmsGetParBackgnd(const par: ParInfo): TColor;
begin
  if pmpHasExtra in par.ParState then
    Result := par.ParExtra.Backgnd
  else
    Result := -1
end;

procedure pmsSetParBackgnd(var par: ParInfo; Color: TColor);
begin
  if pmpHasExtra in par.ParState then
    par.ParExtra.Backgnd := Color
  else if (Color <> -1) and (Color <> clNone) then
  begin
    SetParExtras(par);
    par.ParExtra.Backgnd := Color
  end
end;

function pmsGetParForegnd(const par: ParInfo): TColor;
begin
  if pmpHasExtra in par.ParState then
    Result := par.ParExtra.Foregnd
  else
    Result := -1
end;

procedure pmsSetParForegnd(var par: ParInfo; Color: TColor);
begin
  if pmpHasExtra in par.ParState then
    par.ParExtra.Foregnd := Color
  else if (Color <> -1) and (Color <> clNone) then
  begin
    SetParExtras(par);
    par.ParExtra.Foregnd := Color
  end
end;

function pmsGetParCollapsed(const par: ParInfo; Level: Integer): Boolean;
begin
  case Level of
    0: Result := False;
    1: Result := pmbCollapsed in par.BlockState
    else
      Result := (Level - 2) in par.ParExtra.BlocksCollapsed
  end
end;

function pmsGetParBlockStartLevel(const par: ParInfo): Integer;
var slevel: Integer;
begin
  slevel := Byte(par.BlockState * pmsCBlockLevel);
  Result := slevel;
  if pmbStartBlock in par.BlockState then
    if slevel = 1 then
      Result := 0
    else
      Result := Result - par.ParExtra.StartBlockCount
end;

function pmsGetParBlockEndLevel(const par: ParInfo): Integer;
var slevel: Integer;
begin
  slevel := Byte(par.BlockState * pmsCBlockLevel);
  Result := slevel;
  if pmbEndBlock in par.BlockState then
    if slevel = 1 then
      Result := 0
    else
      Result := Result - par.ParExtra.StopBlockCount
end;

procedure pmsGetParLevels(const Par: ParInfo; const Line: LineInfo; var StartLevel, EndLevel, BarLevel: Integer;
  var Collapsed: Boolean);
var sdnb: Integer;
begin
  BarLevel := Byte(Par.BlockState * pmsCBlockLevel);
  if BarLevel <> 0 then
  begin
    // static blocks take precedence over dynamic ones
    StartLevel := pmsGetParBlockStartLevel(Par);
    EndLevel := pmsGetParBlockEndLevel(Par);
    // find the first collapsed level, set BarLevel equal to this
    Collapsed := False;
    for sdnb := 1 to BarLevel do
      if pmsGetParCollapsed(Par, sdnb) then
      begin
        BarLevel := sdnb;
        Collapsed := True;
        if EndLevel > BarLevel then
          EndLevel := BarLevel;
        Break
      end
  end else
  begin
    // process dynamic block section
    sdnb := Line.StartDynNb;
    if sdnb > 0 then
      BarLevel := DynToCollapseLevel(Par.ParExtra.DynCodes[sdnb - 1])
    else if pmpHasExtra in Par.ParState then
      BarLevel := DynToCollapseLevel(Par.ParExtra.StartDynAttrib^)
    else
      BarLevel := 0;
    StartLevel := BarLevel;
    EndLevel := BarLevel;
    Collapsed := False;

    if pmpHasExtra in Par.ParState then
      while (sdnb < Length(Par.ParExtra.DynCodes)) and (Par.ParExtra.DynCodes[sdnb].DynOffset <= Line.Stop) do
      begin
        EndLevel := DynToCollapseLevel(Par.ParExtra.DynCodes[sdnb]);
        if EndLevel > BarLevel then
        begin
          BarLevel := EndLevel;
          if pmdCollapsed in Par.ParExtra.DynCodes[sdnb].CollpsState then
          begin
            Collapsed := True;
            Break
          end
        end;
        Inc(sdnb)
      end;
    if EndLevel <= StartLevel then
      BarLevel := StartLevel
  end
end;

procedure SetParDyns(var par: ParInfo; Dyns: TDynInfoArray);
begin
  if pmpHasExtra in par.ParState then
    par.ParExtra.DynCodes := Dyns
  else if Length(Dyns) > 0 then
  begin
    SetParExtras(par);
    par.ParExtra.DynCodes := Dyns
  end
end;

function GetFirstLine(const par: ParInfo): LineInfo;
begin
  if pmpHasExtra in par.ParState then
    Result := par.ParExtra.FirstLine
  else
  begin
    Result.Start := 0;
    Result.Stop := par.ParLength;
    Result.LineWidth := par.LineWidth;
    Result.TotalWidth := par.LineWidth;
    Result.TotalColumns := par.ParLength;
    Result.Spaces := 0;
    Result.JustifyStart := par.ParLength;
    Result.StartAttrib := [];
    Result.StartDynNb := 0
  end
end;

procedure SetFirstLine(var par: ParInfo; const Line: LineInfo);
begin
  if pmpHasExtra in par.ParState then
    par.ParExtra.FirstLine := Line
  else if (Line.Stop <> par.ParLength) or (Line.LineWidth > High(Word)) or
  (Line.JustifyStart < par.ParLength) or (Line.StartAttrib <> []) then
  begin
    SetParExtras(par);
    par.ParExtra.FirstLine := Line
  end else
    par.LineWidth := Line.LineWidth;
end;

procedure SetParCollapsed(var Par: ParInfo; Level: Integer; Collapsed: Boolean);
begin
  if Level > 1 then
  begin
    if not(pmpHasExtra in Par.ParState) then
      SetParExtras(Par);
    if Collapsed then
      Include(Par.ParExtra.BlocksCollapsed, Level - 2)
    else
      Exclude(Par.ParExtra.BlocksCollapsed, Level - 2)
  end else if Level = 1 then
    if Collapsed then
      Include(Par.BlockState, pmbCollapsed)
    else
      Exclude(Par.BlockState, pmbCollapsed)
end;

procedure SetParBlockStartLevel(var Par: ParInfo; Level: Integer);
var sclevel: Integer;
begin
  sclevel := Byte(Par.BlockState * pmsCBlockLevel);
  if Level < sclevel then
  begin
    Include(Par.BlockState, pmbStartBlock);
    if pmpHasExtra in Par.ParState then
      Par.ParExtra.StartBlockCount := sclevel - Level
  end else
  begin
    Exclude(Par.BlockState, pmbStartBlock);
    if pmpHasExtra in Par.ParState then
      Par.ParExtra.StartBlockCount := 0
  end
end;

procedure SetParBlockEndLevel(var Par: ParInfo; Level: Integer);
var sclevel: Integer;
begin
  sclevel := Byte(Par.BlockState * pmsCBlockLevel);
  if Level < sclevel then
  begin
    Include(Par.BlockState, pmbEndBlock);
    if pmpHasExtra in Par.ParState then
      Par.ParExtra.StopBlockCount := sclevel - Level
  end else
  begin
    Exclude(Par.BlockState, pmbEndBlock);
    if pmpHasExtra in Par.ParState then
      Par.ParExtra.StopBlockCount := 0
  end
end;

function IsBlockCollapsed(Par: ParInfo; Level: Integer): Boolean;
begin
  case Level of
    0: Result := False;
    1: Result := pmbCollapsed in Par.BlockState
    else
      Result := ((Level - 2) in Par.ParExtra.BlocksCollapsed) or IsBlockCollapsed(Par, Level - 1)
  end
end;

{$IFDEF pmClx}
  {$IFDEF MSWindows}

function GetTickCount; external 'kernel32.dll' name 'GetTickCount';
  {$ELSE}

function GetTickCount: Cardinal;
var st: timespec;
begin
  clock_gettime(CLOCK_REALTIME, st);
  Result := st.tv_sec * 1000 + st.tv_nsec div 1000000
end;
  {$ENDIF}
{$ENDIF}

{ ******* TPlusNavigator ********* }

procedure InvalidateNavs(NavList: TList; startpos, lastpar: LongInt);
var i: Integer;
begin
  for i := 0 to NavList.Count - 1 do
    with TPlusNavigator(NavList[i]) do
      if (fPar <> nil) and (Pos >= StartPos) and (fParNb <= lastpar) then
      begin
        fParLine := -1;
        fDynNb := -1
      end
end;

constructor TPlusNavigator.Create(APlusMemo: TComponent);
begin
  inherited  Create;
  if APlusMemo <> nil then
  begin
    if not(APlusMemo is TPlusMemo) then
      raise Exception.Create('Internal error: component is not a TPlusMemo');
    fPMemo := APlusMemo;
    TPlusMemo(fPMemo).INavigators.Add(Self)
  end;
  fParNb := -1;
  fDynNb := -1;
  { flag as non valid }
  fParLine := -1
end;

destructor TPlusNavigator.Destroy;
begin
  if fPMemo <> nil then
    TPlusMemo(fPMemo).INavigators.Remove(Self);
  fNavLines.Free;
  if Assigned(fOnFree) then
    fOnFree(Self);
  inherited Destroy
end;

procedure TPlusNavigator.AddDyn(const dyn: DynInfoRec);
var  needed: Integer; i: Integer;
begin
  if fDynNb < 0 then
    GetDynNb;
  needed := GetDynCount(Par^) + 1;
  SetDynCount(fPar^, needed);
  for i := needed - 1 downto fDynNb + 1 do
    fPar.ParExtra.DynCodes[i] := fPar.ParExtra.DynCodes[i - 1];
  fPar.ParExtra.DynCodes[fDynNb] := dyn;
  fPar.ParExtra.DynCodes[fDynNb].DynOffset := fOffset;
  Inc(fDynNb);
end; { procedure adddyn }

procedure TPlusNavigator.RemoveDyn;
var i, dcount: Integer;
begin
  if fDynNb < 0 then
    GetDynNb;
  if fPar^.ParExtra.DynCodes[fDynNb].DynOffset <> fOffset then
    raise Exception.Create('Internal PlusMemo error');
  dcount := GetDynCount(fPar^) - 1;
  for i := fDynNb to dcount - 1 do
    fPar.ParExtra.DynCodes[i] := fPar.ParExtra.DynCodes[i + 1];
  SetDynCount(fPar^, dcount);
  fParLine := -1
end;

function TPlusNavigator.GetParNb: LongInt;
var pcount, factp, fact: LongInt; spars: TParagraphsList;
begin
  if fPar = nil then
  begin
    spars := TPlusMemo(fPMemo).IParList;
    fParLine := -1;
    fDynNb := -1;
    pcount := spars.Count - 1;
    if TPlusMemo(fPMemo).CharCount = 0 then
      fParNb := 0
    else if (fPos >= $8000) or (pcount >= $8000) then
    begin
      fact := fPos div $8000 + 1;
      factp := pcount div $8000 + 1;
      fParNb := ((((pcount - 1) div factp) * (fPos div fact)) div TPlusMemo(fPMemo).CharCount) * fact * factp
    end else
      fParNb := ((pcount - 1) * fPos) div TPlusMemo(fPMemo).CharCount;

    if fParNb < 0 then
      fParNb := 0;
    if fParNb > pcount then
      fParNb := pcount;
    fPar := spars.Pointers[fParNb];
    if fPos < fPar^.StartOffset then
    begin
      repeat
        Dec(fParNb);
        fPar := spars.Pointers[fParNb]
      until fPos >= fPar^.StartOffset
    end else
      while fPos > fPar^.StartOffset + GetParLength(fPar^) + 1 do
      begin
        Inc(fParNb);
        fPar := spars.Pointers[fParNb]
      end;

    if fNavLines <> nil then
      fNavLines.LLPar := fPar;
    fOffset := fPos - fPar^.StartOffset
  end;
  { fPar = nil }
  Result := fParNb
end; { method getParNb }

procedure TPlusNavigator.SetParNb(pnb: LongInt);
begin
  fPar := TPlusMemo(fPMemo).IParList.Pointers[pnb];
  fParNb := pnb;
  fPos := fPar^.StartOffset;
  fOffset := 0;
  fDynNb := 0;
  fParLine := 0;
  if fNavLines <> nil then
    fNavLines.LLPar := fPar
end;

function TPlusNavigator.GetNavLines: TLinesList;
begin
  if fNavLines = nil then
    fNavLines := TLinesList.Create;
  Result := fNavLines;
  fNavLines.LLPar := Par
end;

function TPlusNavigator.GetContext: Integer;
var pdyn: pDynInfoRec;
begin
  pdyn := pDynAttr;
  if pdyn^.DynStyle <> 0 then
    Result := pdyn^.Context
  else
    Result := 0
end;

function TPlusNavigator.GetPar: pParInfo;
begin
  if fPar = nil then
    GetParNb;
  Result := fPar
end;

function TPlusNavigator.GetOffset: Integer;
begin
  if fPar = nil then
    GetParNb;
  Result := fOffset
end;

procedure TPlusNavigator.setParOffset(off: Integer);
var plen, dcount: Integer;
begin
  plen := GetParLength(Par^);
  if off > plen then
    off := plen;
  fOffset := off;
  fPos := fPar^.StartOffset + off;
  if (fDynNb >= 0) and (pmpHasExtra in fPar.ParState) then
  begin
    dcount := Length(fPar.ParExtra.DynCodes);
    fDynNb := 0;
    while (fDynNb < dcount) and (fPar.ParExtra.DynCodes[fDynNb].DynOffset < off) do
      Inc(fDynNb)
  end;
  if (fParLine >= 0) and (pmpHasExtra in fPar.ParState) then
  begin
    fParLine := 0;
    dcount := Length(fPar.ParExtra.Lines);
    while (fParLine < dcount) and (off > fPar.ParExtra.Lines[fParLine].Start) do
      Inc(fParLine)
  end
end;

function TPlusNavigator.GetDynNb: Integer;
var illoff: Integer; dcount: Integer;
begin
  if fDynNb < 0 then
  begin
    illoff := ParOffset;
    fDynNb := 0;
    dcount := GetDynCount(fPar^);
    while (fDynNb < dcount) and (fPar^.ParExtra.DynCodes[fDynNb].DynOffset < illoff) do
      Inc(fDynNb);
  end;
  Result := fDynNb
end;

procedure TPlusNavigator.setDynNb(Value: Integer);
begin
  if Value = 0 then
    ParOffset := 0
  else if Value <= GetDynCount(Par^) then
  begin
    ParOffset := Par.ParExtra.DynCodes[Value - 1].DynOffset;
    fDynNb := Value  // if many dyn codes are consecutive at a position, ensure we select the proper one
  end
end;

function TPlusNavigator.GetWord: string;
var founddel: Boolean; t: PChar; stopword, cp, wlen, plen: Integer;
begin
  plen := GetParLength(Par^);
  t := fPar^.ParText;
  cp := ParOffset;
  while (cp < plen) and (not(pmChar(t[cp]) in TPlusMemo(fPMemo).Delimiters)) do
    Inc(cp);
  stopword := cp;
  founddel := False;
  while (cp > 0) and (not founddel) do
  begin
    Dec(cp);
    founddel := pmChar(t[cp]) in TPlusMemo(fPMemo).Delimiters;
    if founddel then
      Inc(cp)
  end;
  wlen := stopword - cp;
  SetLength(Result, wlen);
  Move(t[cp], Result[1], wlen * SizeOf(t^));
end;

function TPlusNavigator.GetLine: string;
var l: Integer;
begin
  with NavLines.LinePointers[ParLine]^ do
  begin
    l := Stop - Start;
    SetLength(Result, l);
    if l > 0 then
      Move(fPar^.ParText[Start], Result[1], l * SizeOf(Result[1]))
  end
end;

function TPlusNavigator.GetLineNb: LongInt;
begin
  if not(TPlusMemo(fPMemo).WordWrap) then
    Result := ParNumber
  else
    Result := ParLine + Par^.StartLine;
  // does not work with hidden parts
end;

procedure TPlusNavigator.SetLineNb(l: LongInt);
var pcount, lcount, pnb: LongInt;
  pmemo: TPlusMemo;
  parp: pParInfo;
  factl, factp: LongInt;
  spars: TParagraphsList;
begin
  pmemo := TPlusMemo(fPMemo);
  if not(pmemo.WordWrap or (pmemo.Alignment in [taCenter, taRightJustify])) then
    if l < pmemo.IParList.Count then
      ParNumber := l
    else
      ParNumber := pmemo.IParList.Count - 1

  else
  begin
    // does not work with hidden parts
    spars := pmemo.IParList;
    pcount := spars.Count;
    lcount := spars.fTrueLineCount;
    if l >= lcount then
      l := lcount - 1;
    if (l >= $8000) or (pcount > $8000) then
    begin
      factl := l div $8000 + 1;
      factp := pcount div $8000 + 1;
      pnb := (((l div factl) * (pcount div factp)) div lcount) * factl * factp
    end else
      pnb := (l * pcount) div lcount;
    if pnb < 0 then
      pnb := 0;
    if pnb >= pcount then
      pnb := pcount - 1;

    parp := spars.Pointers[pnb];
    while parp^.StartLine > l do
    begin
      Dec(pnb);
      parp := spars.Pointers[pnb];
    end;
    while parp^.StartLine + GetLineCount(parp^) <= l do
    begin
      Inc(pnb);
      parp := spars.Pointers[pnb];
    end;

    fPar := parp;
    if fNavLines <> nil then
      fNavLines.LLPar := fPar;
    fParNb := pnb;
    fParLine := l - parp^.StartLine;

    with NavLines.LinePointers[fParLine]^ do
    begin
      fOffset := Start;
      fDynNb := StartDynNb
    end;
    fPos := parp^.StartOffset + fOffset;
  end { Wordwrap }
end; { method setLineNb }

function TPlusNavigator.getIsVisible: Boolean;
begin
  Result := not(pmpHidden in Par.ParState)
end;

function TPlusNavigator.getVisibleLineNumber: Integer;
begin
  Result := Par.StartLine;
  if not(pmpHidden in Par.ParState) then
    Inc(Result, ParLine)
end;

procedure TPlusNavigator.setVisibleLineNumber(ln: Integer);
var pcount, pnb, lv: LongInt;
  pmemo: TPlusMemo;
  parp: pParInfo;
  factl, factp: LongInt;
  done: Boolean;
  spars: TParagraphsList;
begin
  pmemo := TPlusMemo(fPMemo);
  spars := pmemo.IParList;
  done := False;
  if not(pmemo.WordWrap or (pmemo.Alignment in [taCenter, taRightJustify])) then
  begin
    if ln >= spars.Count then
      ln := spars.Count - 1;
    with pParInfo(spars.Pointers[ln])^ do
      if not(pmpHidden in ParState) and (StartLine = ln) then
      begin
        ParNumber := ln;
        done := true
      end
  end;

  if not done then
  begin
    // does not work with partly hidden pars
    lv := VisibleLineNumber;
    pcount := spars.Count;
    pnb := spars.Count - fParNb;
    if ln >= spars.fVisibleLineCount then
      ln := spars.fVisibleLineCount - 1;
    if lv >= spars.fVisibleLineCount then
      lv := spars.fVisibleLineCount - 1;
    if (ln - lv >= $8000) or (pnb > $8000) then
    begin
      factl := Abs(ln - lv) div $8000 + 1;
      factp := pnb div $8000 + 1;
      pnb := fParNb + ((((ln - lv) div factl) * (pnb div factp)) div (spars.fVisibleLineCount - lv)) * factl * factp
    end else
      pnb := fParNb + ((ln - lv) * pnb) div (spars.fVisibleLineCount - lv);
    if pnb < 0 then
      pnb := 0;
    if pnb >= pcount then
      pnb := pcount - 1;

    parp := spars.Pointers[pnb];
    while (pnb < pcount - 1) and (parp^.StartLine { +GetLineCount(parp^) } <= ln) do
    begin
      Inc(pnb);
      parp := spars.Pointers[pnb];
    end;
    while parp^.StartLine > ln do
    begin
      Dec(pnb);
      parp := spars.Pointers[pnb];
    end;

    fPar := parp;
    if fNavLines <> nil then
      fNavLines.LLPar := fPar;
    fParNb := pnb;
    fParLine := ln - parp^.StartLine;

    with NavLines.LinePointers[fParLine]^ do
    begin
      fOffset := Start;
      fDynNb := StartDynNb
    end;
    fPos := parp^.StartOffset + fOffset;
  end { not done }
end; // TPlusNavigator.SetVisibleLineNumber

function TPlusNavigator.GetColNb: Integer;
begin
  Result := ParOffset - NavLines.LinePointers[ParLine]^.Start;
end;

procedure TPlusNavigator.SetColNb(c: Integer);
begin
  with NavLines.LinePointers[ParLine]^ do
  begin
    if c > Stop - Start then
      c := Stop - Start;
    fOffset := Start + c
  end;
  fPos := fPar^.StartOffset + fOffset;
  fDynNb := -1;
end;

procedure TPlusNavigator.SetPos(p: LongInt);
var dcount: Integer;
begin
  if (fParNb <> -1) and (fPar <> nil) then
    if (p < fPos) or (p > fPar.StartOffset + GetParLength(fPar^) + 1) then
    begin
      { change of paragraph or going backward : mark as invalid }
      fDynNb := -1;
      fParLine := -1;
      if (p < fPar.StartOffset) or (p > fPar.StartOffset + GetParLength(fPar^) + 1) then
      begin
        fPar := nil;
        if fNavLines <> nil then
          fNavLines.LLPar := nil;
        fOffset := -1
      end else
        fOffset := p - fPar.StartOffset
    end else
    begin
      { same paragraph and going forward: update internal fields }
      fOffset := p - fPar.StartOffset;
      if fDynNb >= 0 then
      begin
        dcount := GetDynCount(fPar^);
        while (fDynNb < dcount) and (fPar.ParExtra.DynCodes[fDynNb].DynOffset < fOffset) do
          Inc(fDynNb)
      end;
      if fParLine >= 0 then
        while (fParLine < NavLines.Count - 1) and (fOffset >= fNavLines.LinePointers[fParLine]^.Stop) do
          Inc(fParLine)
    end;
  { same paragraph }

  fPos := p
end;

function TPlusNavigator.GetParLine: Integer;
var linecount: Integer;
begin
  if fParLine < 0 then
  begin
    linecount := NavLines.Count - 1;
    fParLine := 0;
    while (fParLine < linecount) and (fOffset >= fNavLines.LinePointers[fParLine]^.Stop) do
      Inc(fParLine);
  end;
  Result := fParLine
end;

procedure TPlusNavigator.SetParLine(pl: Integer);
begin
  if pl >= NavLines.Count then
    pl := NavLines.Count - 1;
  ParOffset := NavLines.LinePointers[pl].Start
end;

function TPlusNavigator.GetAnsiText: AnsiChar;
begin
  Result := pmChar(Text)
end;

function TPlusNavigator.GetText: Char;
var plen: Integer;
begin
  plen := GetParLength(Par^);
  if fOffset >= plen then
    if fOffset = plen then
      Result := #13
    else
      Result := #10
  else
    Result := fPar.ParText[fOffset]
end;

function TPlusNavigator.BackToDyn(Min: LongInt): Boolean;
var cdyn: Integer;
  pn: Integer;
  pp: pParInfo;
  pmemo: TPlusMemo;
begin
  pmemo := TPlusMemo(fPMemo);
  pn := ParNumber;
  pp := fPar;
  Result := False;
  cdyn := DynNb;
  repeat
    if cdyn = 0 then
    begin
      if (pn = 0) or (pp^.StartOffset <= Min) then
        Exit;
      Dec(pn);
      pp := PMemo.IParList.Pointers[pn];
      cdyn := GetDynCount(pp^)
    end else
      Result := True
  until Result;

  if pp^.StartOffset + pp^.ParExtra.DynCodes[cdyn - 1].DynOffset < Min then
  begin
    Result := False;
    Exit
  end;

  Result := True;
  fPar := pp;
  fParNb := pn;
  if fNavLines <> nil then
    fNavLines.LLPar := pp;
  fDynNb := cdyn - 1;
  fOffset := pp^.ParExtra.DynCodes[fDynNb].DynOffset;
  fPos := pp^.StartOffset + fOffset;
  fParLine := -1;
end; { method BackToDyn }

function TPlusNavigator.PreviousDyn: Boolean;
begin
  Result := True;
  if DynNb > 0 then
    DynNb := fDynNb - 1
  else
  begin
    Result := BackToDyn(0);
    if Result then
    begin
      RightOfDyn;
      DynNb := fDynNb - 1
    end
  end
end;

function TPlusNavigator.NextDyn: Boolean;
begin
  Result := True;
  if DynNb < GetDynCount(Par^) then
    DynNb := fDynNb + 1
  else
  begin
    Result := ForwardToDyn(High(Integer));
    if Result then
      DynNb := fDynNb + 1
  end
end;

function TPlusNavigator.GetCollapseLevels(var StartLevel, EndLevel, BarLevel: Integer): Boolean; // returns True if collapsed
begin
  pmsGetParLevels(Par^, NavLines.LinePointers[ParLine]^, StartLevel, EndLevel, BarLevel, Result)
end;

function TPlusNavigator.Collapse(DoOuterSection: Boolean = False): Boolean;
var sp: pDynInfoRec; spar: pParInfo; spars: TParagraphsList;
  tmpnav: TPlusNavigator;
  i, spnb, sdnb, sclevel, shidden, sstartline: Integer;
  sfound: Boolean;
  smemo: TPlusMemo;
begin
  sp := pDynAttr;
  Result := False;
  smemo := TPlusMemo(fPMemo);
  spars := smemo.IParList;

  if smemo.WordWrap or (smemo.Alignment <> taLeftJustify) then
    Exit;
  smemo.DoDynParse(fParNb, fParNb, True);

  if (sp.DynStyle and $80 = 0) or (sp^.CollpsLevel = 0) or (not DoOuterSection and (sp.CollpsState <> [pmdCollapsible])) then
    Exit;
  Result := True;

  tmpnav := TPlusNavigator.Create(nil);
  tmpnav.fPMemo := fPMemo;
  tmpnav.Assign(Self);

  // Go back to start of this dynamic collapsible section
  sclevel := sp.CollpsLevel;
  if sclevel <= 0 then
    Exit;
  repeat
    if not tmpnav.PreviousDyn then
    begin
      tmpnav.Pos := 0;
      Break
    end
  until DynToCollapseLevel(tmpnav.pDynAttr^) < sclevel;
  //if tmpnav.Pos<Pos then
  while DynToCollapseLevel(tmpnav.pDynAttr^) < sclevel do
    tmpnav.DynNb := tmpnav.DynNb + 1;
  //  tmpnav.RightOfDyn
  //else tmpnav.DynNb:= DynNb;

  // record data for the starting paragraph (spnb, sstartline, pmdCollapsed)
  sp := tmpnav.pDynAttr;
  Include(sp.CollpsState, pmdCollapsed);
  for sdnb := tmpnav.fDynNb to High(tmpnav.fPar.ParExtra.DynCodes) do
    if DynToCollapseLevel(tmpnav.fPar.ParExtra.DynCodes[sdnb]) = sclevel then
      Include(tmpnav.fPar.ParExtra.DynCodes[sdnb].CollpsState, pmdCollapsed);

  spnb := tmpnav.fParNb;
  sstartline := tmpnav.VisibleLineNumber;
  if not(pmpHidden in tmpnav.fPar.ParState) then
    Inc(sstartline);

  // reach the end of this section
  repeat
    if not tmpnav.NextDyn then
    begin
      sfound := True;
      tmpnav.Pos := TPlusMemo(fPMemo).CharCount
    end else
      sfound := DynToCollapseLevel(tmpnav.fPar.ParExtra.DynCodes[tmpnav.fDynNb - 1]) < sclevel;

    // ensure sections are parsed at least up to tmpnav
    if sfound and (tmpnav.fParNb > spars.fLastStartStopParsed) then
    begin
      sfound := False;
      smemo.DoDynParse(tmpnav.fParNb, tmpnav.fParNb, True);
      tmpnav.Assign(Self)
    end;
  until sfound;

  // hide lines
  shidden := 0;
  smemo.BeginUpdate;
  spars.ExtendMods(spnb, 0, tmpnav.fParNb);
  for i := spnb + 1 to tmpnav.fParNb do
  begin
    spar := spars.Pointers[i];
    if DynToCollapseLevel(spar.ParExtra.StartDynAttrib^) = sclevel then
      Include(spar.ParExtra.StartDynAttrib.CollpsState, pmdCollapsed);
    for sdnb := 0 to High(spar.ParExtra.DynCodes) do
      if DynToCollapseLevel(spar.ParExtra.DynCodes[sdnb]) = sclevel then
        Include(spar.parExtra.DynCodes[sdnb].CollpsState, pmdCollapsed);
    spar.StartLine := sstartline;
    if not(pmpHidden in spar.ParState) then
    begin
      Inc(shidden);
      Include(spar.ParState, pmpHidden)
    end
  end;

  if shidden > 0 then
  begin
    spars.UpdateLines(tmpnav.fParNb + 1, -shidden);
    Dec(spars.fVisibleLineCount, shidden);
    Dec(spars.fModLinesOffset, shidden)
  end;

  tmpnav.fPMemo := nil;
  tmpnav.Free;
  smemo.EndUpdate;
  {$IFDEF PMDEBUG}
  TPlusMemo(fPMemo).CheckIntegrity
  {$ENDIF}
end;

function TPlusNavigator.Expand(DoOuterSection: Boolean = False): Boolean;
var sp: pDynInfoRec; spar: pParInfo; spars: TParagraphsList;
  tmpnav: TPlusNavigator;
  spnb, sdnb, startparnb, sclevel, sdcount, shidden: Integer;
  sfound, sruncollapsed: Boolean;
begin
  sp := pDynAttr;
  Result := False;
  if (sp^.DynStyle and $80 = 0) or (sp.CollpsLevel <= 0) or not(DoOuterSection or (pmdCollapsible in sp.CollpsState)) then
    Exit;

  tmpnav := TPlusNavigator.Create(nil);
  tmpnav.fPMemo := fPMemo;
  tmpnav.Assign(Self);
  spars := TPlusMemo(fPMemo).IParList;

  // Go back to start of this collapsible section
  sclevel := sp.CollpsLevel;
  repeat
    if not tmpnav.PreviousDyn then
    begin
      tmpnav.Pos := 0;
      Break
    end
  until DynToCollapseLevel(tmpnav.pDynAttr^) < sclevel;
  { if tmpnav.Pos<Pos then tmpnav.RightOfDyn
                    else tmpnav.DynNb:= DynNb; }
  while DynToCollapseLevel(tmpnav.pDynAttr^) < sclevel do
    tmpnav.DynNb := tmpnav.DynNb + 1;
  //  tmpnav.RightOfDyn
  //tmpnav.NextDyn;
  if not(pmdCollapsed in tmpnav.pDynAttr.CollpsState) then
  begin
    tmpnav.fPMemo := nil;
    tmpnav.Free;
    Exit
  end;

  Result := True;
  startparnb := tmpnav.fParNb;
  TPlusMemo(fPMemo).BeginUpdate;

  sp := tmpnav.pDynAttr;
  Exclude(sp.CollpsState, pmdCollapsed);
  sfound := False;
  sruncollapsed := False;
  shidden := 0;
  for sdnb := tmpnav.fDynNb to High(tmpnav.fPar.ParExtra.DynCodes) do
  begin
    sdcount := DynToCollapseLevel(tmpnav.fPar.ParExtra.DynCodes[sdnb]);
    if sdcount = sclevel then
    begin
      Exclude(tmpnav.fPar.ParExtra.DynCodes[sdnb].CollpsState, pmdCollapsed);
      sruncollapsed := False
    end else if sdcount < sclevel then
    begin
      sfound := True;
      Break
    end else
      sruncollapsed := sruncollapsed or (tmpnav.fPar.ParExtra.DynCodes[sdnb].CollpsState = [pmdCollapsible, pmdCollapsed])
  end;

  spnb := tmpnav.fParNb + 1;
  while not sfound do
  begin
    spar := spars.Pointers[spnb];
    Inc(spar.StartLine, shidden);
    if DynToCollapseLevel(spar.ParExtra.StartDynAttrib^) = sclevel then
      Exclude(spar.ParExtra.StartDynAttrib.CollpsState, pmdCollapsed);
    if (pmpHidden in spar.ParState) and (not sruncollapsed) then
    begin
      Exclude(spar.ParState, pmpHidden);
      Inc(shidden, GetLineCount(spar^))
    end;

    for sdnb := 0 to High(spar.ParExtra.DynCodes) do
    begin
      sdcount := DynToCollapseLevel(spar.ParExtra.DynCodes[sdnb]);
      if sdcount = sclevel then
      begin
        Exclude(spar.ParExtra.DynCodes[sdnb].CollpsState, pmdCollapsed);
        sruncollapsed := False
      end else if sdcount < sclevel then
      begin
        sfound := True;
        Break
      end else
        sruncollapsed := sruncollapsed or (spar.ParExtra.DynCodes[sdnb].CollpsState = [pmdCollapsible, pmdCollapsed])
    end;
    Inc(spnb);
    if spnb >= spars.Count then
      sfound := True
  end;

  TPlusMemo(fPMemo).IParList.ExtendMods(startparnb, 0, spnb - 1);
  if shidden > 0 then
  begin
    spars.UpdateLines(spnb, shidden);
    Inc(TPlusMemo(fPMemo).IParList.fModLinesOffset, shidden);
    Inc(spars.fVisibleLineCount, shidden);
  end;

  tmpnav.fPMemo := nil;
  tmpnav.Free;
  TPlusMemo(fPMemo).EndUpdate
end;

function TPlusNavigator.ExpandAllLevels: Boolean; // expand current dynamic section and all outers
var sclevel: Integer; tmpnav: TPlusNavigator; found: Boolean;
begin
  sclevel := DynToCollapseLevel(pDynAttr^);
  Result := False;
  if sclevel > 0 then
  begin
    TPlusMemo(fPMemo).BeginUpdate;
    tmpnav := TPlusNavigator.Create(nil);
    tmpnav.fPMemo := fPMemo;
    tmpnav.Assign(Self);
    while not(pmdCollapsible in tmpnav.pDynAttr^.CollpsState) do
      if (not tmpnav.PreviousDyn) or (DynToCollapseLevel(tmpnav.pDynAttr^) < sclevel) then
        Break;
    Result := tmpnav.Expand;

    found := False;
    while not found and tmpnav.PreviousDyn do
      found := DynToCollapseLevel(tmpnav.pDynAttr^) < sclevel;
    if found then
      Result := tmpnav.ExpandAllLevels or Result;
    tmpnav.fPMemo := nil;
    tmpnav.Free;
    TPlusMemo(fPMemo).EndUpdate
  end;
end;

function TPlusNavigator.ForwardToDyn(Max: LongInt): Boolean;
var cdyn: Integer;
  pn: Integer;
  pp: pParInfo;
  pmemo: TPlusMemo;
begin
  pmemo := TPlusMemo(fPMemo);
  Result := False;
  pn := ParNumber;
  pp := fPar;
  cdyn := DynNb;
  repeat
    if cdyn < GetDynCount(pp^) then
      Result := True
    else
    begin
      if (pn < PMemo.IParList.Count - 1) and (pp^.StartOffset + GetParLength(pp^) < Max) then
      begin
        Inc(pn);
        pp := PMemo.IParList.Pointers[pn];
        cdyn := 0
      end else
        Exit
    end
  until Result;

  if pp^.ParExtra.DynCodes[cdyn].DynOffset + pp^.StartOffset <= Max then
  begin
    fPar := pp;
    if fNavLines <> nil then
      fNavLines.LLPar := pp;
    fDynNb := cdyn;
    fParNb := pn;
    fOffset := pp^.ParExtra.DynCodes[cdyn].DynOffset;
    fPos := pp^.StartOffset + fOffset;
    fParLine := -1
  end else
    Result := False
end; { method ForwardToDyn }

procedure TPlusNavigator.RightOfDyn;
var dcount: Integer;
begin
  dcount := GetDynCount(Par^);
  while (DynNb < dcount) and (fOffset = fPar^.ParExtra.DynCodes[fDynNb].DynOffset) do
    Inc(fDynNb)
end;

function TPlusNavigator.AdvanceDyn: Boolean;
begin
  Result := (DynNb < GetDynCount(Par^)) and (fOffset = fPar^.ParExtra.DynCodes[fDynNb].DynOffset);
  if Result then
    Inc(fDynNb)
end;

function TPlusNavigator.GetpDynInfo: pDynInfoRec;
begin
  if DynNb = 0 then
    Result := GetStartDynAttrib(fPar^)
  else
    Result := @fPar^.ParExtra.DynCodes[fDynNb - 1]
end;

function TPlusNavigator.GetDynInfo: DynInfoRec;
begin
  Result := pDynAttr^
end;

function TPlusNavigator.GetStyle: TFontStyles;
var off: Integer; t: PChar;
begin
  if not TPlusMemo(fPMemo).StaticFormat then
  begin
    Result := [];
    Exit
  end;
  with NavLines.LinePointers[ParLine]^ do
  begin
    Result := StartAttrib;
    off := Start
  end;
  t := fPar^.ParText + off;
  while off < fOffset do
  begin
    if t^ < #26 then
      XORStyleCode(Result, t^);
    Inc(off);
    Inc(t)
  end
end;

procedure TPlusNavigator.Assign(Source: TPlusNavigator);
begin
  fPos := Source.fPos;
  fPar := Source.fPar;
  if fNavLines <> nil then
    fNavLines.LLPar := fPar;
  fParNb := Source.fParNb;
  fParLine := Source.fParLine;
  fOffset := Source.fOffset;
  fDynNb := Source.fDynNb;
end;

procedure TPlusNavigator.ToPreviousWord(const Dels: TSysCharSet);
var founddel: Boolean;
begin
  { back to first non delimiter char. }
  founddel := True;
  while (Pos > 0) and founddel do
  begin
    Pos := Pos - 1;
    founddel := AnsiText in Dels;
  end;
  { back to next delimiter char }
  founddel := False;
  while (Pos > 0) and (not founddel) do
  begin
    Pos := Pos - 1;
    founddel := AnsiText in Dels;
  end;
  if founddel then
    Pos := Pos + 1
end;

procedure TPlusNavigator.ToNextWord(const Dels: TSysCharSet);
var scount, spos: Integer;
begin
  scount := TPlusMemo(fPMemo).CharCount;
  spos := Pos;
  if (Pos < scount) and (Text = #13) then
    Pos := Pos + 2
  else
  begin
    while (Pos < scount) and (not(AnsiText in Dels)) do
      Pos := Pos + 1;
    if (Pos < scount) and (Pos = spos) and (Text = #13) then
      Pos := Pos + 2;
    while (Pos < scount) and (AnsiText in Dels) do
      Pos := Pos + 1
  end
end;

procedure TPlusNavigator.ToEndOfWord(const Dels: TSysCharSet);
var plen: Integer;
begin
  plen := GetParLength(Par^);
  while (ParOffset < plen) and (not(AnsiText in Dels)) do
    Pos := Pos + 1;
end;

procedure TPlusNavigator.ToStartOfWord(const Dels: TSysCharSet);
var founddel: Boolean;
begin
  while (ParOffset > 0) and (AnsiText in Dels) do
    Pos := Pos - 1;
  founddel := False;
  while (Pos > 0) and (not founddel) do
  begin
    Pos := Pos - 1;
    founddel := AnsiText in Dels;
    if founddel then
      Pos := Pos + 1
  end
end;

procedure TPlusNavigator.GetTextBuf(Buffer: PChar; Len: Integer);
var moved, count,
  startoff: Integer;
  parnb: Integer;
  spar: pParInfo;
  tb: PChar;
begin
  moved := 0;
  parnb := ParNumber;
  spar := fPar;
  startoff := ParOffset;
  tb := Buffer;

  if startoff >= GetParLength(spar^) then
  begin
    if (startoff = GetParLength(spar^)) and (Len > 0) then
    begin
      tb^ := #13;
      moved := 1;
      Inc(tb)
    end;
    if Len > moved then
    begin
      tb^ := #10;
      Inc(tb);
      Inc(moved);
      Inc(parnb);
      spar := TPlusMemo(fPMemo).IParList.Pointers[parnb];
      startoff := 0
    end
  end;

  while moved < Len do
  begin
    if Len - moved > GetParLength(spar^) - startoff then
      count := GetParLength(spar^) - startoff
    else
      count := Len - moved;
    if count > 0 then
      System.Move(spar^.ParText[startoff], tb^, count * SizeOf(tb^));
    Inc(moved, count);
    Inc(tb, count);

    if moved < Len then
    begin
      tb^ := #13;
      Inc(moved);
      Inc(tb)
    end;
    if moved < Len then
    begin
      tb^ := #10;
      Inc(moved);
      Inc(tb);
      Inc(parnb);
      spar := TPlusMemo(fPMemo).IParList.Pointers[parnb];
      startoff := 0;
    end
  end;
  Buffer[moved] := #0;
end; { method GetTextBufP }

procedure TPlusNavigator.Invalidate;
begin
  fPar := nil;
  fParNb := -1;
  fParLine := -1;
  fOffset := -1;
  if fNavLines <> nil then
    fNavLines.LLPar := nil;
  fDynNb := -1
end;

function  TPlusNavigator.GetDisplayPos;
begin
  Result.X := GetDisplayX;
  Result.Y := GetDisplayY
end;

procedure TPlusNavigator.SetDisplayPos(DispPos: TPoint);
var sline: LongInt;
begin
  sline := (DispPos.Y + TPlusMemo(fPMemo).TopOrigin) div TPlusMemo(fPMemo).LineHeightRT;
  if sline >= TPlusMemo(fPMemo).IParList.fVisibleLineCount then
    Pos := TPlusMemo(fPMemo).CharCount
  else
  begin
    if sline < 0 then
      sline := 0;
    VisibleLineNumber := sline;
    DisplayX := DispPos.X
  end
end;

procedure TPlusNavigator.SetDisplayX(X: Integer);
var
  i, ilim: Integer;
  lin: LineInfo;
  xpos: Integer;
  w: Integer;
  dc: {$IFDEF pmClx} TCanvas {$ELSE} hdc {$ENDIF};
  changed: Boolean;
  t: PChar;
  r: Integer;
  breakadd,
  breakerror,
  runerror: Integer;
  currentattr: TFontStyles;
  currentdyn: pDynInfoRec;
  curdynnb: Integer;
  ss, newss: TFontStyles;
  nbchars: Integer;
  extraspace: Integer;
  smemo: TPlusMemo;
  spar: pParInfo;
  sdcount: Integer;

begin
  smemo := TPlusMemo(fPMemo);
  spar := Par;
  lin := NavLines[ParLine];
  t := spar.ParText;
  currentattr := lin.StartAttrib;
  curdynnb := 0;
  sdcount := GetDynCount(spar^);
  while (curdynnb < sdcount) and (spar.ParExtra.DynCodes[curdynnb].DynOffset <= lin.Start) do
    Inc(curdynnb);
  if curdynnb = 0 then
    currentdyn := GetStartDynAttrib(spar^)
  else
    currentdyn := @spar.ParExtra.DynCodes[curdynnb - 1];
  if curdynnb < sdcount then
    ilim := spar.ParExtra.DynCodes[curdynnb].DynOffset
  else
    ilim := High(ilim);
  TPlusFontStyles(ss) := [TPlusFontStyle(fsHighlight)];
  ss := smemo.AttrToExtFontStyles(currentattr, currentdyn^.DynStyle) - ss;

  smemo.SetupFont(smemo.Canvas.Font, ss);
  {$IFDEF pmClx}
  dc := smemo.Canvas;
  {$ELSE}
  dc := smemo.Canvas.Handle;
  {$ENDIF}
  nbchars := 1;
  extraspace := smemo.ClientWidth - smemo.RightMargin - lin.LineWidth - smemo.LeftMargin;

  if lin.Spaces > 0 then
  begin
    breakadd := extraspace div lin.Spaces;
    breakerror := extraspace mod lin.Spaces
  end else
  begin
    breakadd := 0;
    breakerror := 0
  end;

  runerror := breakerror div 2;
  r := -1;
  w := 0;
  xpos := 0;

  if smemo.Justified and (lin.JustifyStart < lin.Stop) then
    xpos := smemo.LeftMargin
  else
  begin
    case smemo.Alignment of
      taLeftJustify: xpos := smemo.LeftMargin;
      taRightJustify: xpos := extraspace + smemo.LeftMargin;
      taCenter: xpos := smemo.LeftMargin + extraspace div 2
    end
  end;

  i := lin.Start;

  repeat
    xpos := xpos + w;
    changed := False;
    while (i < lin.Stop) and ((t[i] <= #26) and smemo.StaticFormat and (AnsiChar(t[i]) in ctrlCodesSet)) do
    begin
      changed := True;
      XORStyleCode(currentattr, t[i]);
      inc(i);
      Inc(r)
    end;

    if changed or (i >= ilim) then
    begin
      nbchars := 1;
      if i >= ilim then
      begin
        Inc(curdynnb);
        while (curdynnb < sdcount) and (spar.ParExtra.DynCodes[curdynnb].DynOffset <= i) do
          Inc(curdynnb);
        currentdyn := @spar.ParExtra.DynCodes[curdynnb - 1];
        if curdynnb < sdcount then
          ilim := spar.ParExtra.DynCodes[curdynnb].DynOffset
        else
          ilim := High(ilim)
      end;

      TPlusFontStyles(newss) := [TPlusFontStyle(fsHighlight)];
      newss := smemo.AttrToExtFontStyles(currentattr, currentdyn^.DynStyle) - newss;
      if newss <> ss then
      begin
        smemo.SetupFont(smemo.Canvas.Font, newss);
        ss := newss;
        {$IFNDEF pmClx} dc := smemo.Canvas.Handle;
{$ENDIF}
      end;
    end;

    if i < lin.Stop then
    begin
      if t[i] <> #9 then
      begin
        w := GetTextWidth(dc, t + i - nbchars + 1, nbchars, smemo.MaxOneShotChars);
        if nbchars > 1 then
          Dec(w, GetTextWidth(dc, t + i - 1, 1, 1000));
        nbchars := 2
      end else
      begin
        w := smemo.LeftMargin - xpos;
        if smemo.TabStops > 0 then
          w := w + ((xpos - smemo.LeftMargin) div
            (smemo.TabStops * smemo.SpaceWidth) + 1) * (smemo.TabStops * smemo.SpaceWidth)
        else if smemo.TabStops < 0 then
          w := w + ((xpos - smemo.LeftMargin) div (-smemo.TabStops) + 1) * (-smemo.TabStops)
      end;
      if (smemo.Justified) and (t[i] = ' ') and (i >= lin.JustifyStart) then
      begin
        w := w + breakadd;
        runerror := runerror + breakerror;
        if runerror > lin.Spaces then
        begin
          Inc(w);
          runerror := runerror - lin.Spaces
        end
      end;
      Inc(i);
    end;

    Inc(r)
  until (i >= lin.Stop) or (xpos + w div 2 > X + smemo.LeftOrigin);

  if (xpos + w div 2 <= X + smemo.LeftOrigin) then
    Inc(r);
  //if NoTabRounding and (r>0) and (xpos>X+fDisplayLeft) and (t[lin.Start+r-1]=#9) then Dec(r);
  Col := r;
end; { method ColNb }

function TPlusNavigator.GetDisplayX: Integer;
var j, jlim,
  lastcar: Integer;
  dc: {$IFDEF pmClx} TCanvas {$ELSE} hdc {$ENDIF};
  lin: LineInfo;
  t: PChar;
  c: Char;
  changed: Boolean;
  breakadd,
  breakerror,
  runningerror: Integer;
  ss, newss: TFontStyles;
  currentattr: TFontStyles;
  currentdyn: pDynInfoRec;
  Extra,
  curdynnb: Integer;
  spar: pParInfo;
  smemo: TPlusMemo;
  splen: Integer;
begin
  spar := Par;
  splen := GetParLength(spar^);
  smemo := TPlusMemo(fPMemo);
  lin := NavLines.Items[ParLine];
  t := spar^.ParText;
  currentattr := lin.StartAttrib;
  curdynnb := 0;
  while (curdynnb < GetDynCount(spar^)) and (spar^.ParExtra.DynCodes[curdynnb].DynOffset <= lin.Start) do
    Inc(curdynnb);
  if curdynnb = 0 then
    currentdyn := GetStartDynAttrib(spar^)
  else
    currentdyn := @spar^.ParExtra.DynCodes[curdynnb - 1];
  if curdynnb < GetDynCount(spar^) then
    jlim := spar^.ParExtra.DynCodes[curdynnb].DynOffset
  else
    jlim := High(jlim);

  TPlusFontStyles(ss) := [TPlusFontStyle(fsHighlight)];
  ss := smemo.AttrToExtFontStyles(currentattr, currentdyn^.DynStyle) - ss;

  smemo.SetupFont(smemo.Canvas.Font, ss);
  {$IFDEF pmClx} dc := smemo.Canvas;
{$ELSE}  dc := smemo.Canvas.Handle;
{$ENDIF}

  j := lin.Start;
  lastcar := j;
  if Col <= lin.Stop - lin.Start then
    lin.Stop := lin.Start + Col;

  if lin.Spaces > 0 then
  begin
    runningerror := smemo.ClientWidth - smemo.LeftMargin - smemo.RightMargin - lin.LineWidth;
    breakadd := runningerror div lin.Spaces;
    breakerror := runningerror mod lin.Spaces
  end else
  begin
    breakadd := 0;
    breakerror := 0
  end;
  runningerror := breakerror div 2;
  Extra := 0;
  Result := 0;
  changed := False;

  while j < lin.Stop do
  begin
    if (j >= jlim) and (j > lastcar) then
    begin
      Result := Result + GetTextWidth(dc, t + lastcar, j - lastcar, smemo.MaxOneShotChars);
      lastcar := j
    end;

    c := t[j];
    if ((c > #26) and ((c <> ' ') or (not smemo.Justified) or (j < lin.JustifyStart))) or
      ((c <= #26) and (c <> #9) and (not(smemo.StaticFormat and (AnsiChar(c) in ctrlCodesSet)))) then

    begin
      Inc(j);
    end else
    begin
      if c = ' ' then
      begin
        Inc(Extra, breakadd);
        runningerror := runningerror + breakerror;
        if runningerror >= lin.Spaces then
        begin
          Inc(Extra);
          runningerror := runningerror - lin.Spaces
        end;
        Inc(j);
      end else
      begin
        if j > lastcar then
          Result := Result + GetTextWidth(dc, t + lastcar, j - lastcar, smemo.MaxOneShotChars);

        while (j < lin.Stop) and ((t[j] = #9) or (smemo.StaticFormat and (t[j] < #26) and (AnsiChar(t[j]) in CtrlCodesSet))) do
        begin
          case t[j] of
            ctrlItalic, ctrlBold, ctrlAltFont, ctrlUnderline:
              begin
                changed := True;
                XORStyleCode(currentattr, t[j])
              end;
            #9: if smemo.TabStops > 0 then
              Result := (Result div (smemo.TabStops * smemo.SpaceWidth) + 1) * (smemo.TabStops * smemo.SpaceWidth)
            else if smemo.TabStops < 0 then
              Result := (Result div (-smemo.TabStops) + 1) * (-smemo.TabStops);
          end;
          Inc(j);
        end;
        { while t[j]<=#26 }
        lastcar := j
      end;
      { t[j]<>' ' }
    end;
    { t[j]=' ' or control code }

    if (changed or (j > jlim)) and ((j < lin.Stop) or (j > lastcar)) then
    begin
      if j > jlim then
      begin
        Inc(curdynnb);
        while (curdynnb < GetDynCount(spar^)) and (spar^.ParExtra.DynCodes[curdynnb].DynOffset < j) do
          Inc(curdynnb);
        currentdyn := @spar^.ParExtra.DynCodes[curdynnb - 1];
        if curdynnb < GetDynCount(spar^) then
          jlim := spar^.ParExtra.DynCodes[curdynnb].DynOffset
        else
          jlim := High(jlim)
      end;

      TPlusFontStyles(newss) := [TPlusFontStyle(fsHighlight)];
      newss := smemo.AttrToExtFontStyles(currentattr, currentdyn^.DynStyle) - newss;
      if newss <> ss then
      begin
        smemo.SetupFont(smemo.Canvas.Font, newss);
        ss := newss;
        {$IFNDEF pmClx}
        dc := smemo.Canvas.Handle
        {$ENDIF}
      end;
    end;
  end;
  { while j<stop }

  Result := Result - smemo.LeftOrigin + GetTextWidth(dc, t + lastcar, j - lastcar, smemo.MaxOneShotChars) + Extra;
  { if (lin.Stop<splen) and ((t[lin.Stop]>#26) or (not (pmChar(t[lin.Stop]) in CtrlCodesSet))) then
      fLastPosWidth:= GetTextWidth(dc, t+lin.Stop, 1, 1000); }

  if smemo.Justified and (lin.JustifyStart < splen) then
    Result := Result + smemo.LeftMargin
  else
    case smemo.Alignment of
      taLeftJustify: Result := Result + smemo.LeftMargin;
      taRightJustify: Result := Result + smemo.ClientWidth - smemo.RightMargin - lin.LineWidth;
      taCenter: Result := Result + smemo.LeftMargin + (smemo.ClientWidth - smemo.LeftMargin - smemo.RightMargin - lin.LineWidth) div 2
    end
end; { method GetDisplayX }

function TPlusNavigator.GetDisplayY: Integer;
begin
  Result := VisibleLineNumber * TPlusMemo(fPMemo).LineHeightRT - TPlusMemo(fPMemo).TopOrigin + TPlusMemo(fPMemo).LineBase
end;

function TPlusNavigator.getDisplayWidth: Integer;
var smemo: TPlusMemo; s: string;
begin
  if ParOffset = GetParLength(Par^) then
    Result := 0
  else
  begin
    smemo := TPlusMemo(fPMemo);
    RightOfDyn;
    // RightOfStyle;
    smemo.SetupFont(smemo.Canvas.Font, smemo.AttrToExtFontStyles(Style, DynAttr.DynStyle));
    SetLength(s, 1);
    s[1] := Text;
    Result := smemo.Canvas.TextWidth(pmNativeString(s))
  end
end;

procedure TPlusNavigator.setDisplayY(Y: Integer);
begin
  if Y + TPlusMemo(fPMemo).TopOrigin < TPlusMemo(fPMemo).IParList.fVisibleLineCount * TPlusMemo(fPMemo).LineHeightRT then
    VisibleLineNumber := (Y + TPlusMemo(fPMemo).TopOrigin) div TPlusMemo(fPMemo).LineHeightRT
  else
    Pos := TPlusMemo(fPMemo).CharCount
end;

{ ****** TDynArray2 (the base class for TParagraphsList and TStartStopKeyList) ************* }

constructor TDynArray2.Create;
begin
  fList := TList.Create
end;

destructor TDynArray2.Destroy;
var i: Integer;
begin
  for i := 0 to fList.Count - 1 do
    FreeMem(fList[i], $08000);
  fList.Free;
  inherited Destroy;
end;

function TDynArray2.getPointer(i: LongInt): Pointer;

type ByteArray = array[0..32767] of Byte;
  pByteArray = ^ByteArray;
var listnum: Integer;
begin
  if (i < 0) or (i >= fCount) then
    raise ERangeError.Create('List index out of bounds');
  listnum := i div fElementsPerBuffer;
  Result := @pByteArray(fList[listnum])^[(i mod fElementsPerBuffer) * fElementSpace]
end;

procedure TDynArray2.SetCapacity(cap: LongInt);
var newbufs, i: Integer; newbufp: Pointer;
begin
  newbufs := (cap - 1) div fElementsPerBuffer + 1;
  if newbufs < fList.Count then
  begin
    for i := newbufs to fList.Count - 1 do
      FreeMem(fList[i], $8000);
    fList.Count := newbufs
  end else if newbufs > fList.Count then
    for i := fList.Count to newbufs - 1 do
    begin
      GetMem(newbufp, $8000);
      fList.Add(newbufp)
    end;
  fCapacity := newbufs * fElementsPerBuffer
end;

procedure TDynArray2.SetCount(NewCount: LongInt);
begin
  if NewCount < 0 then
    NewCount := 0;
  if NewCount <> fCount then
  begin
    if NewCount > Capacity then
      Capacity := NewCount;
    fCount := NewCount
  end
end;

function TDynArray2.Add(const Item): LongInt;
begin
  Count := Count + 1;
  Result := Count - 1;
  System.Move(Item, getPointer(Result)^, fElementSize);
end;

{ *************** TParagraphsList **************** }

constructor TParagraphsList.Create;
begin
  inherited Create;
  fElementSize := SizeOf(ParInfo);
  fElementSpace := ((fElementSize - 1) div 2 + 1) * 2;
  fElementsPerBuffer := $8000 div fElementSpace;
  fUpdateStopPar := -1;
  fLastStartStopParsed := -1
end;

function TParagraphsList.GetItem(i: LongInt): ParInfo;
begin
  System.Move(pParInfo(getPointer(i))^, Result, fElementSize)
end;

procedure TParagraphsList.SetItem(i: LongInt; const Item: ParInfo);
begin
  System.Move(Item, ParPointers[i]^, fElementSize)
end;

function TParagraphsList.GetParPointers(i: LongInt): pParInfo;
begin
  Result := Pointers[i]
end;

procedure TParagraphsList.LoadFromStream(Stream: TStream; Ascii: Boolean; NullReplacement: Char; DiscardTrailingSpaces: Boolean;
  var LineBreak: TpmsLineBreak;
  OnProgress: TNotifyEvent; Interval: Cardinal);

  procedure ReadStream(Buf: PChar; Count: Integer);
  var sbuf: array[0..63] of AnsiChar; i, j: Integer;
  begin
    if Ascii then
    begin
      while Count > 0 do
      begin
        if Count >= 64 then
          i := 64
        else
          i := Count;
        Stream.Read(sbuf[0], i);
        for j := 0 to i - 1 do
        begin
          Buf^ := Char(sbuf[j]);
          Inc(Buf)
        end;
        Dec(Count, i)
      end;
    end else
      Stream.Read(Buf[0], Count * SizeOf(Char))
  end;

const nominalbuflen = 65500;
const maxtextlen = maxint - 100;
var i, j, ssize, toread, curbuflen: Integer;
  c, previousc: Char;
  t, t0, t1: PChar;
  par: ParInfo;
  lin: LineInfo;
  parstart, parlen, toff: Integer;
  currattr: TFontStyles;
  whentoprogress: Cardinal;
  sblen: Integer;
  startbufpar: Integer;
begin
  try
    ssize := Stream.Size - Stream.Position;
    if not Ascii then
      ssize := ssize div SizeOf(Char);
    t := StrAlloc(nominalbuflen + 1);
    curbuflen := nominalbuflen;
    SetLength(fBufferList, 1);
    fBufferList[0].Buf := t;
    fBufferList[0].StopIndex := 0;
    startbufpar := 0;

    { build starting paragraph }
    with par do
    begin
      StartOffset := 0;
      StartLine := 0;
      ParState := [];
      BlockState := []
    end;
    with lin do
    begin
      Start := 0;
      StartAttrib := [];
      StartDynNb := 0
    end;
    lin.LineWidth := 0;
    lin.TotalWidth := 0;
    lin.Spaces := 0;
    lin.JustifyStart := 0;

    { initialize local vars }
    currattr := [];
    j := 0;
    toff := 0;
    parstart := 0;
    if Assigned(OnProgress) then
      whentoprogress := GetTickCount + Interval
    else
      whentoprogress := 0;

    { Initial reading in the stream }
    if ssize > curbuflen then
      toread := curbuflen
    else
      toread := ssize;
    if toread > 0 then
      ReadStream(t, toread);
    if toread > 0 then
      c := t[0]
    else
      c := #0;
    previousc := #0;

    while j < ssize do
      // c<>#0 do
    begin
      if c < #26 then
        case c of
          #0: if NullReplacement <> #0 then
            t[toff] := NullReplacement
          else
            Break;

          ctrlItalic, ctrlBold, ctrlHighlight, ctrlAltFont, ctrlUnderline: if StaticFormat then
            XORStyleCode(currattr, c);

          #10, #13:
            if (toff - parstart = 0) and (((c = #10) and (previousc = #13)) or
              ((c = #13) and (previousc = #10))) then
            begin
              { they follow each other so don't take it as text }
              Inc(parstart);
              previousc := #0;
              t[toff] := #0;
              if c = #10 then
                LineBreak := psbCRLF
              else
                LineBreak := psbLFCR
            end else
            begin
              if c = #10 then
                LineBreak := psbLF
              else
                LineBreak := psbCR;
              parlen := toff - parstart;
              previousc := c;
              par.ParText := t + parstart;
              if DiscardTrailingSpaces then
                while (parlen > 0) and (pmChar(par.ParText[parlen - 1]) in [' ', #9]) do
                  Dec(parlen);
              par.ParText[parlen] := #0;
              fTextLen := fTextLen + parlen + 2;
              SetParLength(par, parlen);
              lin.Stop := parlen;
              lin.JustifyStart := parlen;
              SetFirstLine(par, lin);

              i := Add(par) + 1;
              lin.Start := 0;
              lin.StartAttrib := currattr;
              par.ParState := [];
              // remove pmpHasExtra that is possibly added above
              par.StartLine := i;
              par.StartOffset := fTextLen;
              parstart := toff + 1;
              if Assigned(OnProgress) and (i and $0F = 0) and (GetTickCount > whentoprogress) then
              begin
                fLoadPosition := Stream.Position;
                whentoprogress := GetTickCount + Interval;
                OnProgress(Self);
              end;
            end;
        { case #10, #13 }

          else
            previousc := #0

        end { case c of }
      else
        previousc := #0;

      Inc(j);
      Inc(toff);
      if j < ssize then
        if toff < curbuflen then
          c := t[toff]
        else
        begin
          { read from stream }
          parlen := toff - parstart;
          curbuflen := nominalbuflen + parlen;
          t1 := StrAlloc(curbuflen + 1);
          Move(t[parstart], t1^, parlen * SizeOf(t1^));
          if parstart = 0 then
          begin
            StrDispose(t);
            sblen := High(fBufferList);
            fBufferList[sblen].Buf := t1
          end else
          begin
            sblen := Length(fBufferList);
            SetLength(fBufferList, sblen + 1);
            fBufferList[sblen].Buf := t1;
            if parstart < nominalbuflen - (nominalbuflen div 8) then
            begin
              { reallocate this buffer to avoid so much wasted space }
              t0 := StrAlloc(parstart + 1);
              Move(t^, t0^, (parstart + 1) * SizeOf(t0^));
              for i := startbufpar to Count - 1 do
                with pParInfo(Pointers[i])^ do
                  ParText := t0 + (ParText - t);
              fBufferList[sblen - 1].Buf := t0;
              StrDispose(t)
            end
          end;

          if ssize - j > curbuflen - parlen then
            toread := curbuflen - parlen
          else
            toread := ssize - j;
          ReadStream(@t1[parlen], toread);
          //Stream.Read(t1[parlen], toread*SizeOf(t1^));
          //if NullReplacement<>#0 then replacenulls(t1+parlen, toread);
          t := t1;
          parstart := 0;
          toff := parlen;
          startbufpar := Count;
          c := t[toff]
          // note: does not handle FreeSpace and MaxIndex
        end

          { else
            c:= #0;   { we've read to end of stream }
    end;
    // while j < ssize

    par.ParText := t + parstart;
    parlen := toff - parstart;
    if DiscardTrailingSpaces then
      while (parlen > 0) and (pmChar(par.ParText[parlen - 1]) in [' ', #9]) do
        Dec(parlen);
    lin.Stop := parlen;
    lin.JustifyStart := parlen;
    SetParLength(par, parlen);
    par.ParText[parlen] := #0;
    SetFirstLine(par, lin);

    Add(par);
    fTextLen := fTextLen + parlen;
    if j < ssize then
      Stream.Seek(j * SizeOf(Char), 0);

  finally
    fModified := False;
    fModStartPar := 0;
    fModStartLine := 0;
    fModStopPar := Count - 1;
    fModLinesOffset := 0;
    fLastStartStopParsed := -1;
    fUpdateStartPar := 0;
    fUpdateStopPar := Count;
    fTrueLineCount := Count;
    fVisibleLineCount := fTrueLineCount
  end;

end; { procedure LoadFromStream }

procedure TParagraphsList.ExtendMods(startpar, startline, stoppar: Integer);
var newstartline: LongInt; spar: pParInfo;
begin
  if (fModStopPar < fModStartPar) { =-1 } then
  begin
    fModStartPar := Count;
    spar := Pointers[fModStartPar - 1];
    fModStartLine := spar.StartLine + GetLineCount(spar^)
  end;
  if startpar <= fModStartPar then
  begin
    fModStartPar := startpar;
    newstartline := pParInfo(Pointers[startpar]).StartLine + startline;
    if newstartline < fModStartLine then
      fModStartLine := newstartline
  end;
  if stoppar > fModStopPar then
    fModStopPar := stoppar;
  if fLastStartStopParsed >= startpar then
    fLastStartStopParsed := startpar - 1;
  fNoCompleteFormat := False
end;

function TParagraphsList.CollapseExpandBlock(StartingParNb, Level: Integer; Collapse: Boolean): Boolean;
var spar: pParInfo;
  spnb, sclevel, splevel, shidden, sstartline, splines: Integer;
  smakevis: Boolean;
begin
  Result := False;
  spar := Pointers[StartingParNb];
  splevel := pmsGetParBlockStartLevel(spar^);
  if splevel >= Level then
    Exit;
  sclevel := Byte(spar.BlockState * pmsCBlockLevel);
  if Level < sclevel then
    sclevel := Level;
  // we assume this paragraph is also a starting block at this level
  shidden := 0;
  sstartline := spar.StartLine;

  if Collapse then
  begin
    if not(pmpHidden in spar.ParState) then
    begin
      Inc(sstartline);
      shidden := GetLineCount(spar^) - 1
    end
  end else
  begin
    smakevis := not IsBlockCollapsed(spar^, sclevel - 1);
    if smakevis then
    begin
      spnb := GetLineCount(spar^);
      if pmpHidden in spar.ParState then
      begin
        shidden := -spnb;
        Result := True end else
          Inc(sstartline, spnb)
    end
  end;

  SetParCollapsed(spar^, sclevel, Collapse);

  spnb := StartingParNb + 1;
  if (spnb < fCount) and (pmsGetParBlockEndLevel(spar^) >= sclevel) then
    repeat
      spar := Pointers[spnb];
      spar.StartLine := sstartline;
      SetParCollapsed(spar^, sclevel, Collapse);
      if Collapse then
      begin
        if not(pmpHidden in spar.ParState) then
        begin
          Inc(shidden, GetLineCount(spar^));
          Result := True;
          Include(spar.ParState, pmpHidden)
        end
      end else
      begin
        smakevis := not IsBlockCollapsed(spar^, pmsGetParBlockStartLevel(spar^));
        if smakevis and (pmpHidden in spar.ParState) then
        begin
          Result := True;
          splines := GetLineCount(spar^);
          Dec(shidden, splines);
          Exclude(spar.ParState, pmpHidden);
          Inc(sstartline, splines)
        end
      end;
      Inc(spnb);
    until (spnb >= fCount) or (pmsGetParBlockEndLevel(spar^) < sclevel);

  ExtendMods(StartingParNb, 0, spnb - 1);
  if shidden <> 0 then
  begin
    UpdateLines(spnb, -shidden);
    Dec(fVisibleLineCount, shidden);
    Dec(fModLinesOffset, shidden)
  end;
end;

function TParagraphsList.CollapseExpandPar(ParNb, StartLevel, EndLevel: Integer; Collapse: Boolean): Boolean;
var i, spnb: Integer; sclevel: Integer; spar: pParInfo;
begin
  Result := False;
  spar := Pointers[ParNb];
  sclevel := Byte(spar.BlockState * pmsCBlockLevel);
  if StartLevel > sclevel then
    StartLevel := sclevel;
  if StartLevel <= 0 then
    StartLevel := 1;
  if EndLevel > sclevel then
    EndLevel := sclevel;
  for i := StartLevel to EndLevel do
  begin
    spnb := ParNb;
    while (spnb > 0) and (pmsGetParBlockStartLevel(pParInfo(Pointers[spnb])^) >= i) do
      Dec(spnb);
    Result := CollapseExpandBlock(spnb, i, Collapse) or Result
  end
end;

procedure TParagraphsList.MakeCollapsibleBlock(StartPar, StopPar: Integer);
var i: Integer; spar: pParInfo; slevel, snextlevel: Byte;
  spstate: TBlockStates; sbc: TBlocksCollapsed; scp: Boolean;
  lchange: Integer;
  slinenum: Integer;
begin
  if StartPar >= StopPar then
    Exit;
  spar := Pointers[StartPar];
  slevel := Byte(spar.BlockState * pmsCBlockLevel) + 1;
  if slevel > 31 then
    Exit;
  SetParCollapsed(spar^, slevel, False);
  spstate := spar.BlockState * [pmbCollapsed..pmbStartBlock] + TBlockStates(slevel);
  spar.BlockState := spstate + [pmbStartBlock] - [pmbEndBlock];

  if pmpHasExtra in spar.ParState then
  begin
    sbc := spar.ParExtra.BlocksCollapsed;
    Inc(spar.ParExtra.StartBlockCount)
  end else
    sbc := [];

  scp := IsBlockCollapsed(spar^, slevel);
  slinenum := spar.StartLine;
  if not scp then
    Inc(slinenum, GetLineCount(spar^));
  lchange := 0;
  snextlevel := 0;

  for i := StartPar + 1 to StopPar do
  begin
    spar := Pointers[i];
    spar.StartLine := slinenum;
    if not scp then
      Inc(slinenum, GetLineCount(spar^));
    if i = StopPar then
      snextlevel := pmsGetParBlockEndLevel(spar^);
    if snextlevel >= slevel then
      snextlevel := slevel - 1;
    spar.BlockState := spstate;
    SetParCollapsed(spar^, slevel, False);

    if pmpHasExtra in spar.ParState then
    begin
      spar.ParExtra.BlocksCollapsed := sbc;
      spar.ParExtra.StartBlockCount := 0
    end;

    if pmpHidden in spar.ParState <> scp then
      if scp then
      begin
        Dec(lchange, GetLineCount(spar^));
        Include(spar.ParState, pmpHidden)
      end else
      begin
        Inc(lchange, GetLineCount(spar^));
        Exclude(spar.ParState, pmpHidden)
      end
  end;

  // spar is now the last paragraph
  Include(spar.BlockState, pmbEndBlock);
  if pmpHasExtra in spar.ParState then
    spar.ParExtra.StopBlockCount := slevel - snextlevel;
  ExtendMods(StartPar, 0, StopPar);

  if lchange <> 0 then
  begin
    UpdateLines(StopPar + 1, lchange);
    Inc(fVisibleLineCount, lchange);
    Inc(fModLinesOffset, lchange)
  end;

  if StopPar < Count - 1 then
  begin
    // fix next paragraph StartBlockCount, get our StopBlockCount
    spar := Pointers[StopPar + 1];
    if pmsGetParBlockStartLevel(spar^) <> snextlevel then
    begin
      SetParBlockStartLevel(spar^, snextlevel);
      ExtendMods(StopPar, 0, StopPar + 1)
    end
  end
end;

procedure TParagraphsList.RemoveCollapsibleBlock(ParNumber: Integer);
var spar: pParInfo; i, slevel, sbefore, safter: Integer; spstate: TBlockStates; sbc: TBlocksCollapsed;
begin
  spar := Pointers[ParNumber];
  slevel := Byte(spar.BlockState * pmsCBlockLevel);
  if slevel = 0 then
    Exit;
  while (ParNumber > 0) and (pmsGetParBlockStartLevel(spar^) >= slevel) do
  begin
    Dec(ParNumber);
    spar := Pointers[ParNumber]
  end;

  ExtendMods(ParNumber, 0, ParNumber);

  if pmsGetParCollapsed(spar^, slevel) then
    CollapseExpandBlock(ParNumber, slevel, False);
  sbefore := pmsGetParBlockStartLevel(spar^);
  safter := pmsGetParBlockEndLevel(spar^);
  Dec(slevel);

  spstate := spar.BlockState * [pmbCollapsed] + TBlockStates(Byte(slevel));
  spar.BlockState := spstate;
  if sbefore < slevel then
    Include(spar.BlockState, pmbStartBlock);

  if pmpHasExtra in spar.ParState then
  begin
    sbc := spar.ParExtra.BlocksCollapsed;
    Dec(spar.ParExtra.StartBlockCount)
  end else
    sbc := [];

  sbefore := slevel + 1;

  while (ParNumber < fCount - 1) and (safter > slevel) do
  begin
    Inc(ParNumber);
    spar := Pointers[ParNumber];
    safter := pmsGetParBlockEndLevel(spar^);
    if sbefore < Byte(spar.BlockState * pmsCBlockLevel) then
    begin
      sbefore := Byte(spar.BlockState * pmsCBlockLevel);
      for i := slevel + 2 to sbefore do
        CollapseExpandBlock(ParNumber, i, False)
    end;

    spar.BlockState := spstate;
    if pmpHasExtra in spar.ParState then
    begin
      spar.ParExtra.BlocksCollapsed := sbc;
      spar.ParExtra.StartBlockCount := 0;
      spar.ParExtra.StopBlockCount := 0
    end
  end;

  // spar is now the last paragraph
  ExtendMods(ParNumber, 0, ParNumber);
  if safter < slevel then
  begin
    Include(spar.BlockState, pmbEndBlock);
    if pmpHasExtra in spar.ParState then
      spar.ParExtra.StopBlockCount := slevel - safter
  end;
end;

procedure TParagraphsList.MarkUnformatted;
var i: Integer;
begin
  for i := 0 to Count - 1 do
    Exclude(pParInfo(Pointers[i])^.ParState, pmpFormatted);
  fUpdateStartPar := 0;
  fUpdateStopPar := Count - 1;
end;

procedure TParagraphsList.CleanUp;
var i: LongInt; spar: pParInfo;
begin
  for i := 0 to Count - 1 do
  begin
    spar := Pointers[i];
    if (pmpOwnTextBuffer in spar^.ParState) and (spar^.ParText <> nil) then
      StrDispose(spar^.ParText);
    if pmpHasExtra in spar^.ParState then
    begin
      RemoveRef(spar.ParExtra.StartDynAttrib);
      Dispose(spar.ParExtra)
    end;
    spar.BlockState := []
  end;

  fTextlen := 0;
  fVisibleLineCount := 0;
  fTrueLineCount := 0;
  Count := 0;
  Capacity := 4;
  for i := 0 to High(fBufferList) do
    StrDispose(fBufferList[i].Buf);
  fBufferList := nil;
  fUpdateStopPar := -1;
end;

procedure TParagraphsList.InsertBuf(t: PChar; Nav1, Nav2: TPlusNavigator; TrimSpaces, CheckFormat: Boolean;
  var LengthChange, LinesChange: Integer;
  var RemovedDyn: Boolean);

  procedure SetTextError;
  begin
    raise Exception.Create('Text too long')
  end;

  function ScanCRLF(Txt: PChar): PChar;
  var c: Char; found: Boolean;
  begin
    Result := Txt;
    if Txt <> nil then
    begin
      repeat
        c := Result^;
        found := (c = #13) or (c = #10) or (c = #0);
        if not found then
          Inc(Result)
      until found;
      if c = #0 then
        Result := nil
    end
  end;

  procedure MakeTextRoom(txt: PChar; startremove, stopremove, replacelen, tlen: Integer);
  begin
    if stopremove - startremove <> replacelen then
      System.Move(txt[stopremove], txt[startremove + replacelen], (tlen - stopremove + 1) * SizeOf(Char))
  end;

var
  oldcount: Integer; { paragraph count before making text modifications }
  unbalformat: TFontStyles; { unbalanced static styles in selection and new text combined }
  tscan, ntxt: PChar; { general locally used pchars }
  a0, al, { a0: Length of t; al: a0+number of ctrlcodes to add to not affect existing text }
  nblen, nlen: Integer; { new length of paragraph, new buffer length }
  np: Integer; { number of new paragraphs in t }
  vlinechange: Integer; { number of visual lines added or removed }
  newpar: ParInfo; { used to build new ParInfo }
  sometext: Boolean; { used to discard trailing spaces if TrimSpaces is True }
  spar: pParInfo;
  splen: Integer;
  linp: pLineInfo;
  firstnewparbuffer: PChar; { temporary text buffer for first paragraph contained in t }
  lastnewlen, { new length of last paragraph being modified }
  nextoffset, { running start offset of paragraphs following modified ones }
  poffset,
  nextstartline, { running StartLine for new paragraphs }
  linesrem: Integer; { number of lines removed, multiparagraph modification case }
  attr: TFontStyles; { running static style }
  i, j: Integer; { general indexes }
  abssellen, startl, stopl,
  startp, stopp, { paragraph number of start of selection, of stop of selection }
  startoff, stopoff, buflen: Integer;
  startdynattr: DynInfoRec; { dyn attributes at start of selection }
  rundynattr: pDynInfoRec;
  s: string; { control codes to add following t to not affect existing text static format }
  sclevel, sendlevel: Integer; { collapse level of old paragraphs }
  sbstate: TBlockStates;
  sbcollapsed: TBlocksCollapsed;
  sobj: TObject;

begin
  fModified := True;
  ExtendMods(Nav1.ParNumber, Nav1.ParLine, Nav2.ParNumber);
  Nav1.ExpandAllLevels;
  Nav2.ExpandAllLevels;

  oldcount := Count;
  // temporary built paragraphs are added after the present list
  lastnewlen := 0;
  // to avoid a warning

  { test wether new text has paired formatting codes }
  { at the same time, compute length of new text }
  unbalformat := [];
  if t <> nil then
    if StaticFormat then
    begin
      tscan := t;
      while tscan^ <> #0 do
      begin
        if tscan^ < #26 then
          XorStyleCode(unbalformat, tscan^);
        Inc(tscan)
      end;
      a0 := tscan - t
    end else
      a0 := StrLen(t)
    else
      a0 := 0;

  with newpar do
  begin
    StartOffset := 0;
    ParText := t;
    ParState := [pmpOwnTextBuffer] + Nav1.fPar.ParState * [pmpNoWrap, pmpHidden];
  end;

  { break down the new text into individual paragraphs }
  np := 0;
  tscan := ScanCRLF(t);
  if tscan <> nil then
  begin
    SetParLength(newpar, tscan - t);
    if ((tscan^ = #13) and (tscan[1] = #10)) or ((tscan^ = #10) and (tscan[1] = #13)) then
      Inc(tscan, 2)
    else
      Inc(tscan)
  end else
    SetParLength(newpar, a0);
  Add(newpar);

  while tscan <> nil do
  begin
    Inc(np);
    newpar.ParText := tscan;
    newpar.ParState := [pmpOwnTextBuffer] + newpar.ParState * [pmpHidden];
    // preserve the hidden state

    tscan := ScanCRLF(tscan);
    if tscan <> nil then
    begin
      nlen := tscan - newpar.ParText;
      if ((tscan^ = #13) and (tscan[1] = #10)) or ((tscan^ = #10) and (tscan[1] = #13)) then
        Inc(tscan, 2)
      else
        Inc(tscan)
    end else
      nlen := t + a0 - newpar.ParText;
    SetParLength(newpar, nlen);
    Add(newpar);
  end;

  if TrimSpaces then
  begin
    { get back with Nav1 }
    if (Count > oldcount + 1) or ((Count = oldcount) and (Nav2.fOffset = GetParLength(Nav2.fPar^))) then
    begin
      sometext := False;
      j := 0;
      spar := Pointers[oldcount];
      nlen := GetParLength(spar^);
      while (j < nlen) and (not sometext) do
      begin
        sometext := not((spar.ParText[j] = ' ') or (spar.ParText[j] = #9));
        Inc(j)
      end;
      if not sometext then
      begin
        sometext := False;
        while (Nav1.ParOffset > 0) and (pmChar(Nav1.fPar^.ParText[Nav1.fOffset - 1]) in [' ', #9]) do
          Nav1.ParOffset := Nav1.fOffset - 1
      end
    end;
    { getback with Nav1 }

    { trim trailing spaces in new text }
    for i := oldcount to Count - 1 do
    begin
      spar := Pointers[i];
      j := GetParLength(spar^);
      while (j > 0) and (pmChar(spar.ParText[j - 1]) in [' ', #9]) do
        Dec(j);
      if (i < Count - 1) or (Nav2.fOffset = GetParLength(Nav2.fPar^)) then
      begin
        Dec(a0, GetParLength(spar^) - j);
        SetParLength(spar^, j);
        if i = Count - 1 then
          SetParLength(newpar, j);
        { we could get by newpar altogether }
      end
    end
  end;

  { set initial values for local stack vars }
  al := a0;
  abssellen := Nav2.Pos - Nav1.Pos;
  // -startpos;
  startl := Nav1.ParLine;
  stopl := Nav2.ParLine;
  startp := Nav1.fParNb;
  startoff := Nav1.fOffset;
  stopoff := Nav2.fOffset;
  startdynattr := Nav1.DynAttr;
  Nav2.RightOfDyn;

  { test whether the selection has paired formatting codes
    also record whether we encompass some DynInfoRec }
  spar := Nav1.fPar;
  RemovedDyn := False;
  stopp := startp;
  // stopp is used as a running paragraph number
  tscan := spar^.ParText;
  j := startoff;
  nlen := GetParLength(spar^);
  if not StaticFormat then
    j := nlen;
  while (j < stopoff) or (stopp < Nav2.fParNb) do
  begin
    if j < nlen then
    begin
      if tscan[j] < #26 then
        XORStyleCode(unbalformat, tscan[j]);
      Inc(j)
    end else
    begin
      if stopp > startp then
      begin
        if GetDynCount(spar^) > 0 then
          RemovedDyn := True
      end else if Nav1.DynNb < GetDynCount(spar^) then
        RemovedDyn := True;
      Inc(stopp);
      spar := Pointers[stopp];
      tscan := spar^.ParText;
      nlen := GetParLength(spar^);
      if StaticFormat then
        j := 0
      else
        j := nlen
    end
  end;

  RemovedDyn := RemovedDyn or ((stopp > startp) and (Nav2.fDynNb > 0)) or
    ((stopp = startp) and (Nav2.fDynNb > Nav1.fDynNb));

  { put in s the necessary formatting codes to not affect existing text }
  s := '';
  if (CheckFormat) and (unbalformat <> []) then
  begin
    if fsUnderline in unbalformat then
      s := s + ctrlUnderline;
    if fsItalic in unbalformat then
      s := s + ctrlItalic;
    if fsBold in unbalformat then
      s := s + ctrlBold;
    if TPlusFontStyle(fsHighlight) in TPlusFontStyles(unbalformat) then
      s := s + ctrlHighlight;
    if TPlusFontStyle(fsAltFont) in TPlusFontStyles(unbalformat) then
      s := s + ctrlAltFont
  end;
  Inc(al, Length(s));

  { go on with text modification }
  if (stopp = startp) and (np = 0) then
  begin
    LinesChange := 0;
    vlinechange := 0;
    nlen := GetParLength(spar^) - (stopoff - startoff) + GetParLength(newpar) + System.Length(s);
    LengthChange := al - (stopoff - startoff);
    MakeOwnTextBuffer(nil, 0, spar);

    { update subsequent DynCodes offset }
    if pmpHasExtra in spar.ParState then
    begin
      for j := Nav2.fDynNb to High(spar.ParExtra.DynCodes) do
        Inc(spar.ParExtra.DynCodes[j].DynOffset, LengthChange);
      if Nav2.fDynNb > Nav1.fDynNb then
      begin
        for j := Nav2.fDynNb to High(spar.ParExtra.DynCodes) do
          spar.ParExtra.DynCodes[Nav1.fDynNb + (j - Nav2.fDynNb)] := spar.ParExtra.DynCodes[j];
        SetDynCount(spar^, Length(spar.ParExtra.DynCodes) - (Nav2.fDynNb - Nav1.fDynNb))
      end
    end;

    if spar.ParText <> nil then
      buflen := pmStrBufSize(spar.ParText)
    else
      buflen := 0;
    splen := GetParLength(spar^);
    if nlen >= buflen then
    begin
      if nlen > 0 then
      begin
        nblen := nlen + nlen div 64 + 1;
        if nblen < nlen then
          SetTextError;
        { an overflow condition }
        ntxt := StrAlloc(nblen);
        if spar.ParText <> nil then
        begin
          System.Move(spar.ParText^, ntxt^, (splen + 1) * SizeOf(Char));
          StrDispose(spar.ParText)
        end else
          ntxt^ := #0;
        spar.ParText := ntxt;
        MakeTextRoom(ntxt, startoff, stopoff, al, splen)
      end
    end else if nlen + nlen div 8 <= buflen then
    begin
      if nlen > 0 then
        nblen := nlen + nlen div 64 + 1
      else
        nblen := 0;
      if nblen < nlen then
        SetTextError;
      { an overflow condition }
      if nblen > 0 then
        ntxt := StrAlloc(nblen)
      else
        ntxt := nil;
      if ntxt <> nil then
      begin
        MakeTextRoom(spar.ParText, startoff, stopoff, al, splen);
        System.Move(spar.ParText^, ntxt^, (nlen + 1) * SizeOf(Char))
      end;
      StrDispose(spar.ParText);
      spar.ParText := ntxt
    end else
      MakeTextRoom(spar.ParText, startoff, stopoff, al, splen);

    if nlen > 0 then
    begin
      System.Move(t^, spar.ParText[startoff], a0 * SizeOf(Char));
      if Length(s) > 0 then
        System.Move(s[1], spar.ParText[startoff + a0], Length(s) * SizeOf(Char))
    end;
    SetParLength(spar^, nlen);

    { update subsequent lines start and stop info }
    if pmpHasExtra in spar.ParState then
    begin
      linp := Nav1.NavLines.LinePointers[startl];
      if stopl > startl then
        linp^.Stop := startoff + al
      else
        Inc(linp^.Stop, LengthChange);

      for j := startl + 1 to stopl - 1 do
        with Nav1.fNavLines.LinePointers[j]^ do
        begin
          Stop := linp^.Stop;
          Start := linp^.Stop
        end;

      if stopl > startl then
        with Nav1.fNavLines.LinePointers[stopl]^ do
        begin
          Start := linp^.Stop;
          Inc(Stop, LengthChange)
        end;

      for j := stopl + 1 to Nav1.fNavLines.Count - 1 do
        with Nav1.fNavLines.LinePointers[j]^ do
        begin
          Inc(Start, LengthChange);
          Inc(Stop, LengthChange);
          Inc(JustifyStart, LengthChange)
        end;

      { if fLockedCount=0 then } fNoCompleteFormat := True;
      if RemovedDyn then
      begin
        LinesChange := startl - Nav1.fNavLines.Count + 1;
        if not(pmpHidden in spar.ParState) then
          vlinechange := LinesChange;
        Nav1.fNavLines.Count := startl + 1;
        Nav1.fNavLines.LinePointers[startl].Stop := nlen;
        fNoCompleteFormat := False;
      end
    end
  end { if startp=stopp and np=0 }

  else
    { we have destroyed one or more paragraph, or added one or more }
  begin
    LinesChange := np + 1;
    vlinechange := LinesChange;
    { arrange the first modified paragraph }
    spar := Pointers[oldcount];
    nlen := startoff + GetParLength(spar^);
    SetDynCount(spar^, Nav1.fDynNb);
    SetStartDynAttrib(spar^, GetStartDynAttrib(Nav1.fPar^), False);
    if StaticFormat then
      SetStartAttrib(spar^, GetStartAttrib(Nav1.fPar^));
    for i := 0 to Nav1.fDynNb - 1 do
      spar^.ParExtra.DynCodes[i] := Nav1.fPar^.ParExtra.DynCodes[i];

    nblen := nlen + nlen div 64;
    if nblen < nlen then
      SetTextError;
    { an overflow condition  }
    if nblen > 0 then
    begin
      spar^.ParText := StrAlloc(nblen + 1);
      if startoff > 0 then
        System.Move(Nav1.fPar^.ParText^, spar^.ParText^, startoff * SizeOf(Char));
      if nlen > startoff then
        System.Move(t^, spar^.ParText[startoff], (nlen - startoff) * SizeOf(Char));
      spar^.ParText[nlen] := #0
    end else
      spar^.ParText := nil;

    firstnewparbuffer := spar^.ParText;

    SetParLength(spar^, nlen);
    if pmpHasExtra in spar^.ParState then
      spar^.ParExtra.FirstLine.Stop := nlen;
    spar^.ParState := spar^.ParState + Nav1.fpar.ParState * [pmpKeywDone, pmpSSDone];
    LengthChange := nlen - startoff;

    for i := 1 to np - 1 do
    begin
      spar := Pointers[oldcount + i];
      nlen := GetParLength(spar^);
      nblen := nlen + nlen div 64;
      if (nblen < nlen) then
        SetTextError;
      if nblen > 0 then
        ntxt := StrAlloc(nblen + 1)
      else
        ntxt := nil;
      if nlen > 0 then
      begin
        System.Move(spar^.ParText[0], ntxt[0], nlen * SizeOf(Char));
        ntxt[nlen] := #0
      end;
      spar^.ParText := ntxt;
      Inc(LengthChange, nlen + 2)
    end;

    { set last modified paragraph }
    spar := Pointers[Count - 1];
    lastnewlen := GetParLength(spar^);

    { update subsequent dyn codes offset }
    if np = 0 then
      nextoffset := startoff - stopoff + LengthChange
    else if stopp = startp then
      nextoffset := lastnewlen - stopoff
    else
      nextoffset := lastnewlen - (GetParLength(Nav2.fpar^) - stopoff);
    SetDynCount(spar^, GetDynCount(Nav2.fpar^) + GetDynCount(spar^) - Nav2.fDynNb);
    for j := Nav2.fDynNb to GetDynCount(Nav2.fpar^) - 1 do
    begin
      i := GetDynCount(spar^) + j - GetDynCount(Nav2.fpar^);
      spar^.ParExtra.DynCodes[i] := Nav2.par^.ParExtra.DynCodes[j];
      Inc(spar^.ParExtra.DynCodes[i].DynOffset, nextoffset);
    end;

    nlen := GetParLength(Nav2.fpar^) - stopoff + LongInt(Length(s)) + lastnewlen;
    SetParLength(spar^, nlen);
    if pmpHasExtra in spar.ParState then
      spar.ParExtra.FirstLine.Stop := nlen;

    nblen := nlen + nlen div 64;
    if nblen > 0 then
      ntxt := StrAlloc(nblen + 1)
    else
      ntxt := nil;

    if lastnewlen > 0 then
      System.Move(spar^.ParText^, ntxt^, lastnewlen * SizeOf(Char));
    if Length(s) > 0 then
      System.Move(s[1], ntxt[lastnewlen], Length(s) * SizeOf(Char));

    if GetParLength(Nav2.fPar^) > stopoff then
      System.Move(Nav2.fpar^.ParText[stopoff], ntxt[lastnewlen + System.Length(s)], (GetParLength(Nav2.fpar^) - stopoff) * SizeOf(Char));
    if nblen > 0 then
      ntxt[nlen] := #0;
    if np > 0 then
      Inc(LengthChange, lastnewlen { nlen } + 2)
    else if firstnewparbuffer <> nil then
      StrDispose(firstnewparbuffer);
    Inc(LengthChange, Length(s));
    Dec(LengthChange, absSelLen);
    spar^.ParText := ntxt
  end;
  { startp<>stopp or np<>0 }

  { replace paragraph info }
  poffset := np - (stopp - startp);
  if (poffset = 0) and (np = 0) then
    Count := Count - 1
  else
  begin
    if fUpdateStartPar > startp then
      if fUpdateStartPar > stopp then
        Inc(fUpdateStartPar, poffset)
      else
        fUpdateStartPar := startp;
    if fUpdateStopPar > startp then
      if fUpdateStopPar > stopp then
        Inc(fUpdateStopPar, poffset)
      else
        fUpdateStopPar := startp + np
    else
      fUpdateStopPar := startp + np;

    // Collect information for new paragraph adjustments
    with Nav1.fPar^ do
    begin
      // if this paragraph is visible but it starts blocks that are collapsed, uncollapse them
      // reminder: hidden state for new paragraphs is set when parsing the text content
      if not(pmpHidden in ParState) then
        for i := pmsGetParBlockStartLevel(Nav1.fPar^) + 1 to Byte(BlockState * pmsCBlockLevel) do
          SetParCollapsed(Nav1.fPar^, i, False);
      //SetParBlockEndLevel(Nav1.fPar^, Byte(BlockState*pmsCBlockLevel));

      // record interesting values for new paragraphs
      nextoffset := StartOffset;
      nextstartline := StartLine;
      // keep existing blocks definitions for new paragraphs (except the last one, will be set after)
      sbstate := BlockState - [pmbEndBlock];
      if pmpHasExtra in ParState then
      begin
        sbcollapsed := ParExtra.BlocksCollapsed;
        sobj := ParExtra.pObject
      end else
      begin
        sbcollapsed := [];
        sobj := nil
      end;
    end;

    // Adjust new paragraphs offsets, block state, adjust removed lines
    for i := 0 to np do
    begin
      spar := Pointers[oldcount + i];
      with spar^ do
      begin
        BlockState := sbstate;
        StartLine := nextstartline;
        StartOffset := nextoffset;
        nextoffset := nextoffset + GetParLength(spar^) + 2;
        if pmpHidden in ParState then
          Dec(vlinechange)
        else
          Inc(nextstartline);
        if Byte(sbstate * pmsCBlockLevel) > 1 then
        begin
          if not(pmpHasExtra in ParState) then
            SetParExtras(spar^);
          ParExtra.BlocksCollapsed := sbcollapsed;
        end;
        if sobj <> nil then
        begin
          if not(pmpHasExtra in ParState) then
            SetParExtras(spar^);
          spar.ParExtra.pObject := sobj;
          sobj := nil  // no propagation of this value to added paragrahs
        end;

        if i > 0 then
          SetParBlockStartLevel(spar^, Byte(sbstate * pmsCBlockLevel))
        else
          SetParBlockStartLevel(spar^, pmsGetParBlockStartLevel(Nav1.fPar^))
      end
    end;

    spar := Nav1.fPar;
    sclevel := Byte(spar.BlockState * pmsCBlockLevel);
    sendlevel := sclevel;
    // to avoid a warning

    // Clean up dynamic parts of old ParInfos, count removed lines, track lowest block level
    for i := startp to stopp do
    begin
      if i > startp then
        spar := Pointers[i];
      if Byte(spar.BlockState * pmsCBlockLevel) < sclevel then
        sclevel := Byte(spar.BlockState * pmsCBlockLevel);

      if i = stopp then
      begin
        sendlevel := pmsGetParBlockEndLevel(spar^);
        if sclevel > sendlevel then
          sclevel := sendlevel
      end;

      //SetDynCount(spar^, 0); cleaned up by Dispose
      SetStartDynAttrib(spar^, nil, False);
      if (pmpOwnTextBuffer in spar.ParState) and (spar^.ParText <> nil) then
        StrDispose(spar^.ParText);
      if pmpHasExtra in spar.ParState then
      begin
        linesrem := Length(spar.ParExtra.Lines) + 1;
        Dispose(spar.ParExtra)
      end else
        linesrem := 1;
      Dec(LinesChange, linesrem);
      if not(pmpHidden in spar.ParState) then
        Dec(vlinechange, linesrem)
    end;

    // Take care of next paragraph start block level and visibility possibly being modified
    if (sclevel < sendlevel) and (stopp < oldcount - 1) then
    begin
      spar := Pointers[stopp + 1];
      SetParBlockStartLevel(spar^, sclevel);
      if not(pmpHidden in spar.ParState) then
        Inc(fModStopPar)  // have this line refreshed to show the collapse sign
      else if not pmsGetParCollapsed(spar^, sclevel) then
      begin
        Exclude(spar.ParState, pmpHidden);
        Inc(fModStopPar);
        Inc(vlinechange);
        Dec(spar.StartLine)   // cancel the vlinechange increment for this paragraph
      end
    end;

    // finish blocks
    SetParBlockEndLevel(pParInfo(Pointers[oldcount + np])^, sclevel);

    // Move the new ParInfo to their place
    if pOffset <= 0 then
    begin
      for i := startp + np + 1 to oldcount + poffset - 1 do
      begin
        spar := Pointers[i - poffset];
        Items[i] := spar^
      end;
      for i := 0 to np do
        Items[i + startp] := Items[oldcount + i];
    end else
    begin
      Count := Count + poffset;
      // make room for data movement
      for i := Count - 1 downto Count - np - 1 do
        Items[i] := Items[i - poffset];
      for i := oldcount + poffset - 1 downto stopp + poffset + 1 do
      begin
        spar := Pointers[i - poffset];
        Items[i] := spar^
      end;
      for i := 0 to np do
        Items[i + startp] := Items[oldcount + poffset + i]
    end;

    // final step: adjust Capacity if it's too large, keeping some room
    Count := oldcount + pOffset;
    if Capacity > Count + Count div 16 + 8 then
      Capacity := Count + Count div 32 + 4;
  end;
  { replace paragraphs, case poffset<>0 or np<>0 }

  { enter the new lines }
  if (startp <> stopp) or (np <> 0) then
  begin
    Nav1.fParLine := -1;
    if Nav1.fDynNb = 0 then
      rundynattr := GetStartDynAttrib(Nav1.fPar^)
    else if (np > 0) and (startdynattr.DynStyle and $80 <> 0) then
    begin
      New(rundynattr);
      rundynattr^ := startdynattr;
      rundynattr^.DynOffset := 0 { its reference count }
    end else
      rundynattr := nil;

    if StaticFormat then
    begin
      attr := GetStartAttrib(Nav1.fPar^);
      for j := 0 to GetParLength(Nav1.fPar^) - 1 do
        if Nav1.fPar.ParText[j] < #26 then
          XORStyleCode(attr, Nav1.fPar.ParText[j])
    end else
      attr := [];

    for i := 1 to np do
    begin
      spar := ParPointers[startp + i];
      SetStartAttrib(spar^, attr);
      SetStartDynAttrib(spar^, rundynattr, False);
      if StaticFormat then
        for j := 0 to GetParLength(spar^) - 1 do
          if spar.ParText[j] <= #26 then
            XORStyleCode(attr, spar.ParText[j]);
    end
  end;

  if (LengthChange <> 0) or (vlinechange <> 0) then
    if vlinechange = 0 then
      UpdateOffsets(startp + np + 1, LengthChange)
    else
      UpdateOffsetsLines(startp + np + 1, LengthChange, vlinechange);

  Inc(fModLinesOffset, vLineChange);
  Inc(fModStopPar, poffset);
  al := abssellen + LengthChange;
  Inc(fTextLen, LengthChange);
  Inc(fTrueLineCount, LinesChange);
  Inc(fVisibleLineCount, vlinechange);

  if np = 0 then
  begin
    Nav2.Assign(Nav1);
    Nav2.fPos := Nav1.fPos + al;
    Nav2.fOffset := Nav1.fOffset + al;
    Nav2.fParLine := -1
  end else
  begin
    Nav2.fOffset := lastnewlen + Length(s);
    Nav2.fDynNb := 0;
    Nav2.fParNb := startp + np;
    Nav2.fPos := Nav1.fPos + al;
    Nav2.fPar := Pointers[Nav2.fParNb];
    if Nav2.fNavLines <> nil then
      Nav2.fNavLines.LLPar := Nav2.fPar;
    Nav2.fParLine := 0
  end
end;

procedure TParagraphsList.SaveToStream(Stream: TStream; Ascii, StripCodes, DiscardTrailingSpaces: Boolean;
  LineBreak: TpmsLineBreak; OnProgress: TNotifyEvent; Interval: Cardinal);
const BreakKindToString: array[TpmsLineBreak] of string = (#13#10, #10#13, #13, #10);

  procedure WriteStream(C: PChar; Count: Integer);
  var i, n: Integer; car: array[0..64] of AnsiChar; p: PAnsiChar;
  begin
    if Ascii then
    begin
      while Count > 0 do
      begin
        //Stream.Write(C^, 1);
        if Count > 64 then
          n := 64
        else
          n := Count;
        p := @car[0];
        for i := 0 to n - 1 do
        begin
          p^ := AnsiChar(C^);
          Inc(p);
          Inc(C)
        end;
        Dec(Count, n);
        Stream.Write(car, n)
      end;
    end else
      Stream.WriteBuffer(C^, Count * SizeOf(Char));
  end;

var i: Integer;
  lastnotify: Cardinal;
  par: PChar;
  j, k, parlen: Integer;
  newpar: Boolean;
  sparp: pParInfo;
  lbreak: string;
begin
  if Assigned(OnProgress) then
    lastnotify := GetTickCount
  else
    lastnotify := 0;
  lbreak := BreakKindToString[LineBreak];

  for i := 0 to Count - 1 do
  begin
    sparp := Pointers[i];
    par := sparp^.ParText;
    parlen := GetParLength(sparp^);

    newpar := False;
    if StaticFormat and StripCodes then
    begin
      j := 0;
      while j < parlen do
        if (par[j] < #26) and (AnsiChar(par[j]) in CtrlCodesSet) then
        begin
          k := j + 1;
          while (k < parlen) and (par[k] < #26) and (AnsiChar(par[k]) in CtrlCodesSet) and (par[k] <> par[j]) do
            Inc(k);

          if (k < parlen) and (par[k] = par[j]) then
            { flush redondant ctrl codes }
          begin
            if not newpar then
            begin
              par := StrNew(par);
              newpar := True
            end;
            System.Move(par[j + 1], par[j], (k - j - 1) * SizeOf(par[j]));
            System.Move(par[k + 1], par[k - 1], (parlen - k - 1) * SizeOf(par[k]));
            Dec(parlen, 2)
          end else
            Inc(j)
        end else
          Inc(j);
    end;
    { if StripCodes }

    if DiscardTrailingSpaces then
      while (parlen > 0) and (pmChar(par[parlen - 1]) in [' ', #9]) do
        Dec(parlen);

    WriteStream(par, parlen);
    //  Stream.WriteBuffer(par[0], parlen*SizeOf(Char));
    if i < Count - 1 then
      WriteStream(PChar(lbreak), Length(lbreak));
    // Stream.WriteBuffer(BreakKindToString[LineBreak][1], Length(BreakKindToString[LineBreak])*SizeOf(Char));
    if StaticFormat and StripCodes and newpar then
      StrDispose(par);
    if Assigned(OnProgress) then
      if GetTickCount - lastnotify > Interval then
      begin
        fSavePosition := i;
        OnProgress(Self);
        lastnotify := GetTickCount
      end
  end;
  fSavePosition := Count;
  if Assigned(OnProgress) then
    OnProgress(Self)
end;

const p1add = ((SizeOf(ParInfo) - 1) div 2 + 1) * 2; imodmax = 32768 div p1add;
procedure TParagraphsList.UpdateOffsets(FromPar, OffChange: Integer);
var spar: pParInfo;
  i, imod: Integer;
begin
  if FromPar >= Count then
    Exit;
  spar := Pointers[FromPar];
  imod := imodmax - FromPar mod imodmax;
  for i := FromPar to fCount - 1 do
  begin
    Inc(spar^.StartOffset, OffChange);
    Dec(imod);
    if imod > 0 then
      Inc(pbyte(spar), p1add)
    else if i < fCount - 1 then
    begin
      spar := Pointers[i + 1];
      imod := imodmax
    end
  end;
end;

procedure TParagraphsList.UpdateLines(FromPar, Change: Integer);
var spar: pParInfo;
  i, imod: Integer;
begin
  if FromPar >= Count then
    Exit;
  spar := Pointers[FromPar];
  imod := imodmax - FromPar mod imodmax;
  for i := FromPar to fCount - 1 do
  begin
    Inc(spar^.StartLine, Change);
    Dec(imod);
    if imod > 0 then
      Inc(pbyte(spar), p1add)
    else if i < fCount - 1 then
    begin
      spar := Pointers[i + 1];
      imod := imodmax
    end
  end;
end;

procedure TParagraphsList.UpdateOffsetsLines(FromPar, OffChange, LineChange: Integer);
var spar: pParInfo;
  i, imod: Integer;
begin
  if FromPar >= Count then
    Exit;
  spar := Pointers[FromPar];
  imod := imodmax - FromPar mod imodmax;
  for i := FromPar to fCount - 1 do
  begin
    Inc(spar^.StartOffset, OffChange);
    Inc(spar^.StartLine, LineChange);
    Dec(imod);
    if imod > 0 then
      Inc(pbyte(spar), p1add)
    else if i < fCount - 1 then
    begin
      spar := Pointers[i + 1];
      imod := imodmax
    end
  end;
end;

{ ************ TPlusMemoStrings ***************** }

procedure TPlusMemoStrings.Assign(Source: TPersistent);
var tmpstream: TMemoryStream;
begin
  if Source is TPlusMemoStrings then
  begin
    tmpstream := TMemoryStream.Create;
    TPlusMemo(TPlusMemoStrings(Source).Memo).SaveToStream(tmpstream);
    tmpstream.Position := 0;
    TPlusMemo(Memo).LoadFromStream(tmpstream);
    tmpstream.Free
  end else if Source is TStrings then
  begin
    tmpstream := TMemoryStream.Create;
    TStrings(Source).SaveToStream(tmpstream);
    tmpstream.Position := 0;
    LoadFromStream(tmpstream);
    tmpstream.Free
  end else
    inherited Assign(Source)
end;

procedure TPlusMemoStrings.DefineProperties(Filer: TFiler);
begin
  Filer.DefineProperty('Strings', ReadData, WriteData, TPlusMemo(Memo).CharCount > 0)
end;

procedure TPlusMemoStrings.ReadData(Reader: TReader);
var rdstr: string; rdpchar: PChar;
begin
  Reader.ReadListBegin;
  BeginUpdate;
  try
    Clear;
    while not Reader.EndOfList do
      with TPlusMemo(Memo) do
      begin
        rdstr := string(Reader.ReadString);
        rdpchar := PChar(rdstr);

        if CharCount > 0 then
          PargrphBuf[ParagraphCount] := rdpchar
        else
          PargrphBuf[0] := rdpchar;
      end
  finally
    EndUpdate;
  end;
  Reader.ReadListEnd
end;

procedure TPlusMemoStrings.SetUpdateState(StringsUpdating: Boolean);
begin
  if StringsUpdating then
    TPlusMemo(Memo).BeginUpdate
  else
    TPlusMemo(Memo).EndUpdate
end;

procedure TPlusMemoStrings.SetTextStr(const Value: { UCONVERT } string { /UCONVERT } );
begin
  with TPlusMemo(Memo) do
    SetTextBuf(PChar(string(Value)))
end;

function TPlusMemoStrings.GetTextStr: { UCONVERT } string { /UCONVERT } ;
begin
  Result := pmNativeString(TPlusMemo(Memo).GetTextPart(0, TPlusMemo(Memo).CharCount))
end;

procedure TPlusMemoStrings.Clear;
begin
  TPlusMemo(Memo).Clear
end;

{$IFDEF D2009Up}
procedure TPlusMemoStrings.LoadFromStream(Stream: TStream; Encoding: TEncoding);
var
  SSize, PSize, i: Integer;
  Buffer: TBytes;
  tmpstream: TStream;
  sc: TCharArray;
begin
  //  Load enough to determine the encoding to use
  SSize := Stream.Size - Stream.Position;
  if SSize > 16 then
    i := 16
  else
    i := SSize;
  SetLength(Buffer, i);
  Stream.Read(Buffer[0], i);
  PSize := TEncoding.GetBufferEncoding(Buffer, Encoding);
  TPlusMemo(Memo).Encoding := Encoding;

  if {$IFNDEF PMSUPPORTA} (Encoding = TEncoding.Unicode) or {$ENDIF} (Encoding = TEncoding.ASCII) then
    // for Ansi, don't take this branch with Unicode
  begin
    // Use TPlusMemo.LoadFromStream right from stream passed in (avoid temporary stream)
    Stream.Position := Stream.Position - i + PSize;
    TPlusMemo(Memo).LoadFromStream(Stream {$IFNDEF PMSUPPORTA}, Encoding <> TEncoding.Unicode {$ENDIF})
  end else
  begin
    // Handle through the generic way (requires three times the stream size in terms of memory)
    SetLength(Buffer, SSize);
    Stream.Read(Buffer[i], SSize - i);
    sc := Encoding.GetChars(Buffer, PSize, SSize - PSize);
    tmpstream := TMemoryStream.Create;
    try
      if Length(sc) > 0 then
        tmpstream.WriteBuffer(sc[0], Length(sc) * SizeOf(sc[0]));
      tmpstream.Position := 0;
      TPlusMemo(Memo).LoadFromStream(tmpstream, False)
    finally
      tmpstream.Free
    end
  end
end;

{$ELSE}
procedure TPlusMemoStrings.LoadFromStream(Stream: TStream);
{$IFDEF PMSUPPORTU}
var tmpstr: AnsiString; wtmpstr: WideString; tmpstream: TStream;
begin
  SetLength(tmpstr, Stream.Size - Stream.Position);
  Stream.ReadBuffer(tmpstr[1], Length(tmpstr));
  wtmpstr := tmpstr;
  tmpstream := TMemoryStream.Create;
  try
    tmpstream.WriteBuffer(wtmpstr[1], Length(wtmpstr) * SizeOf(WideChar));
    tmpstream.Position := 0;
    TPlusMemo(Memo).LoadFromStream(tmpstream)
  finally
    tmpstream.Free
  end
end;

{$ELSE}
begin
  TPlusMemo(Memo).LoadFromStream(Stream)
end;
{$ENDIF}
{$ENDIF}

{$IFDEF D2009Up}
procedure TPlusMemoStrings.SaveToStream(Stream: TStream; Encoding: TEncoding);
var
  Buffer, Preamble: TBytes; tmpstream: TMemoryStream; Chars: TCharArray;
begin
  if Encoding = nil then
    Encoding := TEncoding.Default;
  Preamble := Encoding.GetPreamble;
  if (Length(Preamble) > 0) {$IFDEF DXEUp} and WriteBOM {$ENDIF} then
    Stream.WriteBuffer(Preamble[0], Length(Preamble));

  if {$IFNDEF PMSUPPORTA} (Encoding = TEncoding.Unicode) or {$ENDIF} (Encoding = TEncoding.ASCII) then
    // for Ansi, don't take this branch with Unicode
    TPlusMemo(Memo).SaveToStream(Stream {$IFNDEF PMSUPPORTA}, Encoding <> TEncoding.Unicode {$ENDIF})
  else
  begin
    tmpstream := TMemoryStream.Create;
    try
      TPlusMemo(Memo).SaveToStream(tmpstream, False);
      SetLength(Chars, tmpstream.Size div SizeOf(Char));
      tmpstream.Position := 0;
      if Length(Chars) > 0 then
        tmpstream.ReadBuffer(Chars[0], Length(Chars) * SizeOf(Chars[0]));
    finally
      tmpstream.Free
    end;
    Buffer := Encoding.GetBytes(Chars);
    if Length(Buffer) > 0 then
      Stream.WriteBuffer(Buffer[0], Length(Buffer))
  end;
  TPlusMemo(Memo).Encoding := Encoding;
end;

procedure TPlusMemoStrings.SaveToFile(const FileName: { UCONVERT } string { /UCONVERT } );
begin
  SaveToFile(FileName, TPlusMemo(Memo).Encoding)
end;

procedure TPlusMemoStrings.SaveToStream(Stream: TStream);
begin
  SaveToStream(Stream, TPlusMemo(Memo).Encoding)
end;

{$ELSE}
procedure TPlusMemoStrings.SaveToStream(Stream: TStream);
begin
  TPlusMemo(Memo).SaveToStream(Stream);
end;
{$ENDIF}

{$IFDEF PMSUPPORTA}
function TPlusMemoStrings.AddA(S: AnsiString): Integer;
begin
  Result := Count;
  InsertA(Result, S)
end;
{$ENDIF}

{$IFNDEF D2009Up}
function TPlusMemoStrings.AddW(S: WideString): Integer;
begin
  Result := Count;
  InsertW(Result, S)
end;

procedure TPlusMemoStrings.LoadFromStreamW(Stream: TStream);
{$IFDEF PMSupportU}
begin
  TPlusMemoU(Memo).LoadFromStream(Stream)
end;
{$ELSE}
var tmpstr: WideString; wtmpstr: AnsiString; tmpstream: TStream;
begin
  SetLength(tmpstr, (Stream.Size - Stream.Position) div 2);
  Stream.ReadBuffer(tmpstr[1], Length(tmpstr) * SizeOf(tmpstr[1]));
  wtmpstr := tmpstr;
  tmpstream := TMemoryStream.Create;
  try
    tmpstream.WriteBuffer(wtmpstr[1], Length(wtmpstr) * SizeOf(wtmpstr[1]));
    tmpstream.Position := 0;
    TPlusMemo(Memo).LoadFromStream(tmpstream)
  finally
    tmpstream.Free
  end
end;
{$ENDIF}

procedure TPlusMemoStrings.SaveToStreamW(Stream: TStream);
var tmpstr: WideString;
begin
  tmpstr := TPlusMemo(Memo).Text;
  Stream.WriteBuffer(tmpstr[1], Length(tmpstr) * SizeOf(tmpstr[1]));
end;

procedure TPlusMemoStrings.LoadFromFileW(FileName: AnsiString);
var tmpstream: TStream;
begin
  tmpstream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStreamW(tmpstream);
  finally
    tmpstream.Free
  end
end;

procedure TPlusMemoStrings.SaveToFileW(FileName: AnsiString);
var stream: TStream;
begin
  stream := TFileStream.Create(FileName, fmCreate);
  try
    SaveToStreamW(stream);
  finally
    stream.Free
  end
end;

procedure TPlusMemoStrings.LoadFromFileAuto(FileName: AnsiString); // automatically detects if Unicode or Ansi file
var tmpstream: TStream; sig: Word; unicode: Boolean;
begin
  tmpstream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    unicode := False;
    if tmpstream.Size > 2 then
    begin
      tmpstream.Read(sig, 2);
      if (sig = $FFFE) or (sig = $FEFF) then
        unicode := True
      else
        tmpstream.Position := 0
    end;
    if unicode then
      LoadFromStreamW(tmpstream)
    else
      LoadFromStream(tmpstream)
  finally
    tmpstream.Free
  end
end;

procedure TPlusMemoStrings.SaveToFileWithSig(FileName: AnsiString); // writes the Unicode signature at the start of file
var tmpstream: TStream; sig: Word;
begin
  tmpstream := TFileStream.Create(FileName, fmCreate);
  try
    sig := $FEFF;
    tmpstream.Write(sig, 2);
    SaveToStreamW(tmpstream);
  finally
    tmpstream.Free
  end
end;
{$ENDIF}  // not D2009 and up

procedure TPlusMemoStrings.WriteData(Writer: TWriter);
var i: Integer;
begin
  Writer.WriteListBegin;
  for i := 0 to TPlusMemo(Memo).ParagraphCount - 1 do
      {$IFDEF PMSupportU}
    Writer.WriteWideString(TPlusMemo(Memo).ParsArray[i]);
      {$ELSE}
    Writer.WriteString(pmNativeString(TPlusMemo(Memo).ParsArray[i]));
      {$ENDIF}

  Writer.WriteListEnd
end;

function TPlusParaStrings.Get(Index: Integer): { UCONVERT } string { /UCONVERT } ;
begin
  Result := pmNativeString(TPlusMemo(Memo).ParsArray[Index])
end;

function TPlusParaStrings.GetCount: Integer;
begin
  Result := TPlusMemo(Memo).ParagraphCount;
  if GetParLength(TPlusMemo(Memo).IParList.ParPointers[Result - 1]^) = 0 then
    Dec(Result)
end;

procedure TPlusParaStrings.Put(Index: Integer; const s: { UCONVERT } string { /UCONVERT } );
begin
  TPlusMemo(Memo).ParsArray[Index] := string(s)
end;

procedure TPlusParaStrings.PutObject(Index: Integer; AObject: TObject);
var par: pParInfo;
begin
  par := TPlusMemo(Memo).IParList.ParPointers[Index];
  if not(pmpHasExtra in par.ParState) then
    SetParExtras(par^);
  par.ParExtra.pObject := AObject
end;

// Version 7.5 update. Now much faster!
function TPlusParaStrings.Add(const s: { UCONVERT } string { /UCONVERT } ): Integer;
var
  splist: TParagraphsList; snewp: ParInfo;
  pmemo: TPlusMemo;
begin
  pmemo := TPlusMemo(Memo);
  pmemo.BeginUpdate;
  splist := pmemo.IParList;
  splist.fModified := True;
  Result := splist.Count;
  splist.fModStopPar := Result;

  splist.fUpdateStopPar := Result;
  snewp.ParState := [pmpOwnTextBuffer];
  snewp.ParLength := Length(s);
  if snewp.ParLength > 0 then
  begin
    snewp.ParText := StrAlloc(Length(s) + 1);
    System.Move(s[1], snewp.ParText^, SizeOf(s[1]) * snewp.ParLength);
    snewp.ParText[snewp.ParLength] := #0
  end else
    snewp.ParText := nil;
  snewp.BlockState := [];
  snewp.StartOffset := splist.fTextLen + 2;
  snewp.StartLine := splist.fVisibleLineCount;
  Inc(splist.fTextLen, snewp.ParLength + 2);
  Inc(splist.fVisibleLineCount);
  Inc(splist.fTrueLineCount);
  Inc(splist.fModLinesOffset);
  splist.Add(snewp);
  PMemo.EndUpdate;
end;

procedure TPlusParaStrings.Delete(Index: Integer);
begin
  with TPlusMemo(Memo) do
  begin
    SelLength := 0;
    SelPar := Index;
    if Index < IParList.Count - 1 then
      SelLength := GetParLength(IParList.ParPointers[Index]^) + 2
    else
      SelLength := GetParLength(IParList.ParPointers[Index]^);
    ClearSelection
  end
end;

procedure TPlusParaStrings.Insert(Index: Integer; const s: { UCONVERT } string { /UCONVERT } );
begin
  {$IFDEF PMSupportU}
  InsertW(Index, s)
  {$ELSE}
  with TPlusMemo(Memo) do
  begin
    SelLength := 0;
    if Index < ParagraphCount then
    begin
      SelPar := Index;
      SelText := string(s + #13#10)
    end else
    begin
      SelStart := CharCount;
      SelText := string(#13#10 + s)
    end
  end
  {$ENDIF}
end;

{$IFDEF PMSUPPORTA}
function TPlusParaStrings.GetItemsA(Index: Integer): AnsiString;
begin
  Result := TPlusMemo(Memo).ParsArray[Index]
end;

procedure TPlusParaStrings.SetItemsA(Index: Integer; Value: AnsiString);
begin
  TPlusMemo(Memo).ParsArray[Index] := Value
end;

procedure TPlusParaStrings.InsertA(Index: Integer; S: AnsiString);
begin
  with TPlusMemo(Memo) do
  begin
    SelLength := 0;
    if Index < ParagraphCount then
    begin
      SelPar := Index;
      SelText := s + #13#10
    end else
    begin
      SelStart := CharCount;
      SelText := #13#10 + s
    end
  end
end;
{$ENDIF}

function TPlusParaStrings.GetObject(Index: Integer): TObject;
var par: pParInfo;
begin
  par := TPlusMemo(Memo).IParList.ParPointers[Index];
  if pmpHasExtra in par.ParState then
    Result := par.ParExtra.pObject
  else
    Result := nil
end;

{$IFNDEF D2009Up}
function TPlusParaStrings.GetItemsW(Index: Integer): WideString;
begin
  Result := TPlusMemo(Memo).ParsArray[Index]
end;

procedure TPlusParaStrings.SetItemsW(Index: Integer; Value: WideString);
begin
  TPlusMemo(Memo).ParsArray[Index] := Value
end;

procedure TPlusParaStrings.InsertW(Index: Integer; S: WideString);
begin
  {$IFDEF PMSupportU}
  with TPlusMemo(Memo) do
  begin
    SelLength := 0;
    if Index < ParagraphCount then
    begin
      SelPar := Index;
      SelText := s + #13#10
    end else
    begin
      SelStart := CharCount;
      SelText := #13#10 + s
    end
  end
  {$ELSE}
  Insert(Index, S)
  {$ENDIF}
end;
{$ENDIF}  // D2009 Up

destructor TPlusLinesStrings.Destroy;
begin
  fLinesStrings.Free;
  inherited Destroy
end;

function TPlusLinesStrings.Get(Index: Integer): { UCONVERT } string { /UCONVERT } ;
begin
  Result := pmNativeString(TPlusMemo(Memo).LinesArray[Index]);
end;

function TPlusLinesStrings.GetCount: Integer;
var smemo: TPlusMemo;
begin
  smemo := TPlusMemo(Memo);
  Result := smemo.LineCount;
  if fLinesStrings = nil then
    fLinesStrings := TLinesList.Create;
  fLinesStrings.LLPar := smemo.IParList.Pointers[smemo.IParList.Count - 1];
  with fLinesStrings.LinePointers[fLinesStrings.Count - 1]^ do
    if Stop = Start then
      Dec(Result)
end;

procedure TPlusLinesStrings.Put(Index: Integer; const s: { UCONVERT } string { /UCONVERT } );
var smemo: TPlusMemo;
begin
  smemo := TPlusMemo(Memo);
  if Index < smemo.LineCount then
  begin
    smemo.SelLength := 0;
    smemo.SelLine := Index;
    smemo.SelLength := Length(smemo.LinesArray[Index]);
    smemo.SelText := string(s);
    smemo.ScrollInView
  end
end;

procedure TPlusLinesStrings.Delete(Index: Integer);
var smemo: TPlusMemo;
begin
  smemo := TPlusMemo(Memo);
  if Index < Count then
  begin
    smemo.SelLength := 0;
    smemo.SelLine := Index;
    smemo.SelLength := Length(smemo.LinesArray[Index]);
    if (Index < smemo.LineCount) and (smemo.SelStopNav.ParOffset = GetParLength(smemo.SelStopNav.Par^)) then
      smemo.SelLength := smemo.SelLength + 2;
    smemo.ClearSelection;
    smemo.ScrollInView
  end
end;

function TPlusLinesStrings.Add(const s: { UCONVERT } string { /UCONVERT } ): Integer;
var smemo: TPlusMemo;
begin
  smemo := TPlusMemo(Memo);
  smemo.SelLength := 0;
  if GetParLength(smemo.IParList.ParPointers[smemo.IParList.Count - 1]^) = 0 then
    smemo.ParsArray[smemo.IParList.Count - 1] := string(s + #13#10)
  else
    smemo.ParsArray[smemo.IParList.Count] := string(s);
  smemo.SelStart := smemo.CharCount;
  smemo.ScrollInView;
  Result := smemo.LineCount - 1;
end;

procedure TPlusLinesStrings.Insert(Index: Integer; const s: { UCONVERT } string { /UCONVERT } );
begin
  {$IFDEF PMSupportU}
  InsertW(Index, s)
  {$ELSE}
  with TPlusMemo(Memo) do
    if Index <= LineCount then
    begin
      SelLength := 0;
      if Index < LineCount then
      begin
        SelLine := Index;
        SelText := string(s + #13#10)
      end else
      begin
        SelStart := CharCount;
        SelText := string(#13#10 + s)
      end;
      ScrollInView
    end
  {$ENDIF}
end;

{$IFDEF PMSUPPORTA}
function TPlusLinesStrings.GetItemsA(Index: Integer): AnsiString;
begin
  Result := TPlusMemo(Memo).LinesArray[Index];
end;

procedure TPlusLinesStrings.SetItemsA(Index: Integer; Value: AnsiString);
var smemo: TPlusMemo;
begin
  smemo := TPlusMemo(Memo);
  if Index < smemo.LineCount then
  begin
    smemo.SelLength := 0;
    smemo.SelLine := Index;
    smemo.SelLength := Length(smemo.LinesArray[Index]);
    smemo.SelText := Value;
    smemo.ScrollInView
  end
end;

procedure TPlusLinesStrings.InsertA(Index: Integer; S: AnsiString);
begin
  with TPlusMemo(Memo) do
    if Index <= LineCount then
    begin
      SelLength := 0;
      if Index < LineCount then
      begin
        SelLine := Index;
        SelText := s + #13#10
      end else
      begin
        SelStart := CharCount;
        SelText := #13#10 + s
      end;
      ScrollInView
    end
end;
{$ENDIF}

{$IFNDEF D2009Up}
function TPlusLinesStrings.GetItemsW(Index: Integer): WideString;
begin
  Result := TPlusMemo(Memo).LinesArray[Index];
end;

procedure TPlusLinesStrings.SetItemsW(Index: Integer; Value: WideString);
var smemo: TPlusMemo;
begin
  smemo := TPlusMemo(Memo);
  if Index < smemo.LineCount then
  begin
    smemo.SelLength := 0;
    smemo.SelLine := Index;
    smemo.SelLength := Length(smemo.LinesArray[Index]);
    smemo.SelText := Value;
    smemo.ScrollInView
  end
end;

procedure TPlusLinesStrings.InsertW(Index: Integer; S: WideString);
begin
  {$IFDEF PMSupportU}
  Insert(Index, s)
  {$ELSE}
  with TPlusMemo(Memo) do
    if Index <= LineCount then
    begin
      SelLength := 0;
      if Index < LineCount then
      begin
        SelLine := Index;
        SelText := s + #13#10
      end else
      begin
        SelStart := CharCount;
        SelText := #13#10 + s
      end;
      ScrollInView
    end
  {$ENDIF}
end;
{$ENDIF}  // D2009 and up

{ *********** TLinesList ************** }

function TLinesList.GetLinesPointer(i: Integer): pLineInfo;
begin
  if (i < 0) or (i >= GetLineCount(LLPar^)) then
    raise ERangeError.Create('List index out of bounds');
  if i = 0 then
  begin
    if pmpHasExtra in LLPar^.ParState then
      Result := @LLPar^.ParExtra.FirstLine
    else
    begin
      fFirstLine.Stop := LLPar.ParLength;
      fFirstLine.LineWidth := LLPar.LineWidth;
      fFirstLine.Start := 0;
      fFirstLine.TotalWidth := fFirstLine.LineWidth;
      fFirstLine.Spaces := 0;
      fFirstLine.JustifyStart := LLPar.ParLength;
      fFirstLine.StartAttrib := [];
      fFirstLine.StartDynNb := 0;
      Result := @fFirstLine
    end
  end else
    Result := @LLPar^.ParExtra.Lines[i - 1]
end;

function TLinesList.GetCount: Integer;
begin
  Result := GetLineCount(LLPar^)
end;

function TLinesList.GetItem(i: Integer): LineInfo;
begin
  Result := LinePointers[i]^
end;

procedure TLinesList.SetItem(i: Integer; const Item: LineInfo);
begin
  LinePointers[i]^ := Item
end;

procedure TLinesList.SetCount(NewCount: Integer);
var newbuffercount: Integer;
begin
  if NewCount < 1 then
    NewCount := 1;
  newbuffercount := NewCount - 1;

  if pmpHasExtra in LLPar.ParState then
    System.SetLength(LLPar.ParExtra.Lines, newbuffercount)
  else if newbuffercount > 0 then
  begin
    SetParExtras(LLPar^);
    System.SetLength(LLPar.ParExtra.Lines, newbuffercount)
  end
end;

function TLinesList.Add(const Item: LineInfo): Integer;
begin
  Result := GetLineCount(LLPar^);
  Count := Result + 1;
  LinePointers[Result]^ := Item
end;

{ ******* TPlusHighlighter ************** }

constructor TPlusHighlighter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  MemoList := TList.Create
end;

destructor TPlusHighlighter.Destroy;
var i: Integer;
begin
  for i := 0 to MemoList.Count - 1 do
    TPlusMemo(MemoList[i]).Highlighter := nil;
  MemoList.Destroy;
  inherited Destroy
end;

procedure TPlusHighlighter.ApplyKeywordsList(Start, Stop: TPlusNavigator; BaseIndex: Integer);
begin
end;

function TPlusHighlighter.FindStop(Start, Stop: TPlusNavigator; BaseIndex: Integer): Boolean;
begin
  Result := False
end;

function TPlusHighlighter.FindStart(Start, Stop: TPlusNavigator; BaseIndex: Integer): Boolean;
begin
  Result := False
end;

function TPlusHighlighter.FixRange(Start, Stop: TPlusNavigator; KeywordBase, SSBase: Integer): Boolean;
begin
  Result := False
end;

procedure TPlusHighlighter.Notify(Sender: TComponent; Events: TpmEvents);
begin
  // for support of extended highlighting only
end;

{ UCONVERT }
function ScanInt(var t: pmNativePChar): Integer;
var tstop: PChar; intstr: string;
begin
  tstop := StrScan(t, ',');
  if tstop = nil then
    tstop := StrEnd(t);
  SetLength(intstr, tstop - t);
  Move(t^, intstr[1], (tstop - t) * SizeOf(intstr[1]));
  Result := StrToInt(intstr);
  t := tstop;
  if t^ = ',' then
    Inc(t)
end;
{ /UCONVERT }

{ ****************** TKeywordList ***************** }

destructor TKeywordList.Destroy;
var i: Integer;
begin
  if fKeyList <> nil then
    for i := 0 to fKeyList.Count - 1 do
      Dispose(pKeyInfoLen(fKeyList[i]));
  fKeyList.Free;
  fKeyList := nil;
  inherited Destroy
end;

procedure TKeywordList.DefineProperties(Filer: TFiler);
begin
  Filer.DefineProperty('Strings', ReadData, WriteData, Count > 0)
end;

procedure TKeywordList.Assign(Source: TPersistent);
var i: Integer; pk: pKeyInfoLen;
begin
  if Source is TKeywordList then
  begin
    BeginUpdate;
    Clear;
    for i := 0 to TKeywordList(Source).Count - 1 do
    begin
      if fKeyList = nil then
        fKeyList := TList.Create;
      New(pk);
      pk^ := pKeyInfoLen(TKeywordList(Source).fKeyList[i])^;
      fKeyList.Add(pk)
    end;
    EndUpdate
  end else
    inherited Assign(Source)
end;

function TKeywordList.getKeywords(Index: Integer): string;
begin
  Result := pKeyInfoLen(fKeyList[Index]).KeywordOrg
end;

procedure TKeywordList.setKeywords(Index: Integer; const Value: string);
begin
  pKeyInfoLen(fKeyList[Index]).KeywordOrg := Value;
  SetUpdateState(fUpdating)
end;

procedure TKeywordList.Delete(i: Integer);
begin
  Dispose(pKeyInfoLen(fKeyList[i]));
  fKeyList.Delete(i);
  SetUpdateState(fUpdating)
end;

procedure TKeywordList.Clear;
var i: Integer;
begin
  for i := 0 to Count - 1 do
    Dispose(pKeyInfoLen(fKeyList[i]));
  if fKeyList <> nil then
    fKeyList.Clear;
  SetUpdateState(fUpdating)
end;

procedure TKeywordList.ReadData(Reader: TReader);
var pk: pKeyInfoLen; sopt: Byte;
begin
  if fKeyList = nil then
    fKeyList := TList.Create;
  Reader.ReadListBegin;
  BeginUpdate;
  Clear;
  while not Reader.EndOfList do
  begin
    new(pk);
    if fKeyList = nil then
      fKeyList := TList.Create;
    fKeyList.Add(pk);
    pk.KeywordOrg := string(Reader.ReadString);
    with pk^.BasicPart do
    begin
      sopt := Reader.ReadInteger;
      Byte(Options) := sopt and $7F;
      Byte(Style) := Reader.ReadInteger;
      ContextNumber := Reader.ReadInteger;
      Cursor := Reader.ReadInteger;
      Backgnd := Reader.ReadInteger;
      Foregnd := Reader.ReadInteger;
      if sopt and $80 <> 0 then
      begin
        pk^.Scope := Reader.ReadInteger;
        pk^.Priority := Reader.ReadInteger;
        pk^.Extra := Reader.ReadInteger
      end else
      begin
        pk^.Scope := 0;
        pk^.Priority := 0;
        pk^.Extra := 0;
        { read version 5 ext keywords scope and priority }
        if Reader.NextValue in [vaInt8, vaInt16, vaInt32] then
        begin
          pk^.Scope := Reader.ReadInteger;
          pk^.Priority := Reader.ReadInteger
        end
      end
    end
  end;
  Reader.ReadListEnd;
  EndUpdate
end;

procedure TKeywordList.WriteData(Writer: TWriter);
var i: Integer; pk: pKeyInfoLen;
begin
  Writer.WriteListBegin;
  for i := 0 to Count - 1 do
  begin
    pk := pKeyInfoLen(fKeyList[i]);
    {$IFDEF PMSupportU}
    Writer.WriteWideString(pk.KeywordOrg);
    {$ELSE}
    Writer.WriteString(pmNativeString(pk.KeywordOrg));
    {$ENDIF}
    with pk^.BasicPart do
    begin
      Writer.WriteInteger(Byte(Options) or $80);
      Writer.WriteInteger(Byte(Style));
      Writer.WriteInteger(ContextNumber);
      Writer.WriteInteger(Cursor);
      Writer.WriteInteger(Backgnd);
      Writer.WriteInteger(Foregnd);
      Writer.WriteInteger(pk^.Scope);
      Writer.WriteInteger(pk^.Priority);
      Writer.WriteInteger(pk^.Extra)
    end
  end;
  Writer.WriteListEnd
end;

function TKeywordList.Get(Index: Integer): { UCONVERT } string { /UCONVERT } ;
begin
  Result := pmNativeString(pKeyInfoLen(fKeyList[Index]).KeywordOrg)
end;

function TKeywordList.GetCount: Integer;
begin
  if fKeyList = nil then
    Result := 0
  else
    Result := fKeyList.Count
end;

procedure TKeywordList.Insert(Index: Integer; const S: { UCONVERT } string { /UCONVERT } );
var pk: pKeyInfoLen;
begin
  if fKeyList = nil then
    fKeyList := TList.Create;
  New(pk);
  fKeyList.Insert(Index, pk);
  pk^.KeywordOrg := string(s);
  pk^.Scope := 0;
  pk^.Priority := 0;
  pk^.Extra := 0;
  pk^.BasicPart.Options := [];
  pk^.BasicPart.Style := [];
  pk^.BasicPart.ContextNumber := 0;
  pk^.BasicPart.Cursor := crDefault;
  pk^.BasicPart.Backgnd := clNone;
  pk^.BasicPart.Foregnd := clNone;
  SetUpdateState(fUpdating)
end;

function pmStrUpper(t: PChar): PChar;
begin
  Result := StrUpper(t)
end;

function UpCaseTypeToProc(ut: TpmUpperCase): TpmUpperCaseProc;
begin
  case ut of
    pmuAscii: Result := @pmStrUpper;
    pmuAnsi: Result := @pmCharUpper
    else if Assigned(UserUpperCaseProc) then
      Result := @UserUpperCaseProc
    else
      Result := @pmStrUpper
  end
end;

procedure TKeywordList.SetUpdateState(Updating: Boolean);
var i: Integer; len: Integer; kinfop: pKeyInfoLen;
  upproc: TpmUpperCaseProc;
  supstr: string;
begin
  fUpdating := Updating;
  if Updating then
    Exit;
  fGWOptions := [woMatchCase];
  upproc := UpCaseTypeToProc(fUpperCaseType);

  fLongestKeyword := 0;
  for i := 0 to Count - 1 do
  begin
    kinfop := fKeyList[i];
    len := Length(kinfop.KeywordOrg);
    if len > fLongestKeyword then
      fLongestKeyword := len;
    kinfop.KeywordTrans := kinfop.KeywordOrg;
    kinfop^.KeyLen := len;
    fGWOptions := fGWOptions + kinfop.BasicPart.Options * [woFirstParWord, woFirstNonBlank];
    if not(woMatchCase in kinfop^.BasicPart.Options) then
    begin
      Exclude(fGWOptions, woMatchCase);
      supstr := kinfop.KeywordOrg;
      SetLength(supstr, Length(supstr));
      // make it unique (ref count = 1)
      upproc(PChar(supstr));
      if supstr <> kinfop.KeywordOrg then
        kinfop.KeywordTrans := supstr
    end
  end
end;

procedure TKeywordList.setUpperCaseType(ut: TpmUpperCase);
begin
  if ut <> fUpperCaseType then
  begin
    fUpperCaseType := ut;
    SetUpdateState(fUpdating)
  end
end;

function TKeywordList.getKeyList: TList;
begin
  if fKeyList = nil then
    fKeyList := TList.Create;
  Result := fKeyList
end;

procedure TKeywordList.setKeyInfo(i: Integer; wi: TKeywordInfo);
var pk: pKeyInfoLen;
begin
  pk := pKeyInfoLen(KeyList[i]);
  pk.Scope := 0;
  pk.Priority := 0;
  pk.Extra := 0;
  pk^.BasicPart := wi;
  SetUpdateState(fUpdating)
end;

function TKeywordList.getKeyInfo(i: Integer): TKeywordInfo;
begin
  Result := pKeyInfoLen(fKeyList[i])^.BasicPart;
end;

function TKeywordList.AddKeyWord(const KeyWord: string;
  Options: TWordOptions;
  Style: TFontStyles;
  ContextNumber: Integer;
  Cursor: TCursor;
  Backgnd, Foregnd: TColor): Integer;
var pk: pKeyInfoLen;
begin
  if fKeyList = nil then
    fKeyList := TList.Create;
  New(pk);
  Result := fKeyList.Add(pk);
  pk.BasicPart.Options := Options;
  pk.BasicPart.Style := Style;
  pk.BasicPart.ContextNumber := ContextNumber;
  pk.BasicPart.Cursor := Cursor;
  pk.BasicPart.Backgnd := Backgnd;
  pk.BasicPart.Foregnd := Foregnd;
  pk.KeywordOrg := Keyword;
  pk.Scope := 0;
  pk.Priority := 0;
  pk.Extra := 0;
  SetUpdateState(fUpdating)
end;

procedure TKeywordList.LoadFromIniStrings(IniStrings: TStrings);
var ms: pmNativeString;
  i: Integer;
  Opt: TWordOptions;
  St: TFontStyles;
  Cn: Integer;
  Cr: TCursor;
  Bg, Fg: TColor;
  msp, tscan: pmNativePChar;
  eqpos: Integer;
begin
  BeginUpdate;
  Clear;

  try
    for i := 0 to IniStrings.Count - 1 do
    begin
      ms := IniStrings[i];
      eqpos := Pos('=', ms);
      {$IFDEF D7New}
      if eqpos = 1 then
        eqpos := PosEx('=', ms, 2);
      {$ENDIF}
      if eqpos > 0 then
      begin
        msp := pmNativePChar(ms);
        tscan := msp + eqpos;
        Byte(Opt) := ScanInt(tscan);
        Byte(St) := ScanInt(tscan);
        Cn := ScanInt(tscan);
        Cr := ScanInt(tscan);
        Bg := ScanInt(tscan);
        Fg := ScanInt(tscan);
        AddKeyword(string(Copy(ms, 1, eqpos - 1)), Opt, St, Cn, Cr, Bg, Fg);
      end
    end

  finally
    EndUpdate;
  end
end;

procedure TKeywordList.SaveToIniStrings(IniStrings: TStrings);
var ms: pmNativeString; i: Integer; spkey: pKeyInfoLen;
begin
  if IniStrings = nil then
    Exit;
  IniStrings.Clear;
  for i := 0 to Count - 1 do
  begin
    spkey := pKeyInfoLen(KeyList[i]);
    if spkey <> nil then
    begin
      ms := IntToStr(Byte(spkey^.BasicPart.Options)) + ',' +
        IntToStr(Byte(spkey^.BasicPart.Style)) + ',' +
        IntToStr(spkey^.BasicPart.ContextNumber) + ',' +
        IntToStr(spkey^.BasicPart.Cursor) + ',' +
        IntToStr(spkey^.BasicPart.Backgnd) + ',' +
        IntToStr(spkey^.BasicPart.Foregnd) + ',' +
        IntToStr(spkey^.Scope) + ',' +
        IntToStr(spkey^.Priority) + ',';
      IniStrings.Add(Strings[i] + '=' + ms)
    end
  end
end;

{ ****************** TStartStopKeyList ***************** }

constructor TStartStopKeyList.Create;
begin
  inherited Create;
  fElementSize := SizeOf(StartStopInfo);
  fElementSpace := ((fElementSize - 1) div 16 + 1) * 16;
  fElementsPerBuffer := $8000 div fElementSpace
end;

destructor TStartStopKeyList.Destroy;
begin
  Clear;
  inherited Destroy
end;

procedure TStartStopKeyList.Clear;
var i: Integer;
begin
  fGWOpt := [woMatchCase];
  for i := 0 to Count - 1 do
    with pStartStopInfo(Pointers[i])^ do
    begin
      StrDispose(StartKey);
      StrDispose(StopKey);
      StartKeyStr := '';
      StopKeyStr := ''
    end;
  Count := 0;
  Capacity := 2;
end;

function TStartStopKeyList.AddStartStopKey(const StartKey, StopKey: string;
  Options: TWordOptions;
  Style: TFontStyles;
  ContextNumber: Integer;
  Cursor: TCursor;
  Backgnd, Foregnd: TColor;
  EndAtPar: Boolean): Integer;
var cs: StartStopInfo; i: Integer; pprevious: pStartStopInfo;
  upproc: TpmUpperCaseProc;
begin
  cs.StartLen := Length(StartKey);
  cs.StopLen := Length(StopKey);
  cs.StartCheckLen := cs.StartLen;
  // v6.5a
  if cs.StartLen > fLongestStartKey then
    fLongestStartKey := cs.StartLen;
  if cs.StopLen > fLongestStopKey then
    fLongestStopKey := cs.StopLen;
  if EndAtPar and (fLongestStopKey < 2) then
    fLongestStopKey := 2;

  cs.StartKey := StrAlloc(cs.StartLen + 1);
  cs.StopKey := StrAlloc(cs.StopLen + 1);
  StrPCopy(cs.StartKey, StartKey);
  StrPCopy(cs.StopKey, StopKey);

  cs.Attributes.Style := Style;
  cs.Attributes.Options := Options;
  cs.Attributes.ContextNumber := ContextNumber;
  cs.Attributes.Cursor := Cursor;
  cs.ssOptions := [];
  if EndAtPar then
    Include(cs.ssOptions, ssoParStop);
  cs.Attributes.Backgnd := Backgnd;
  cs.Attributes.Foregnd := Foregnd;
  cs.Scope := 0;
  cs.Priority := 0;
  cs.Extra := 0;

  fGWOpt := fGWOpt + cs.Attributes.Options * [woFirstNonBlank, woFirstParWord];
  upproc := UpCaseTypeToProc(fUpperCaseType);

  with cs do
  begin
    if not(woMatchCase in Options) then
    begin
      upproc(StartKey);
      upproc(StopKey);
      Exclude(fGWOpt, woMatchCase);
    end;

    Previous := -1;
    for i := 0 to Count - 1 do
    begin
      pprevious := pStartStopInfo(Pointers[i]);
      if (Previous < 0) and (pprevious^.Attributes.Options = Options) and (StrComp(pprevious^.StartKey, StartKey) = 0) then
      begin
        Previous := i;
        //Break    6.5a
      end;
      // Check if a previous longer start key exists with same beginning, if so adjust StartCheckLen (6.5a)
      if (pprevious.StartLen > StartCheckLen) and (CompareMem(pprevious.StartKey, StartKey, StartLen * SizeOf(StartKey[0]))) then
        StartCheckLen := pprevious.StartLen
    end
  end;

  Result := Add(cs);
  pprevious := Pointers[Result];
  //Initialize(pprevious^);
  pprevious.StartKeyStr := StartKey;
  pprevious.StopKeyStr := StopKey;
  fDelChecked := False
end; { TStartStopKeyList.AddStartStopKey }

procedure TStartStopKeyList.setUpperCaseType(ut: TpmUpperCase);
var i: Integer; ss: pStartStopInfo; upproc: TpmUpperCaseProc; p: PChar;
begin
  if ut <> fUpperCaseType then
  begin
    upproc := UpCaseTypeToProc(ut);
    fUpperCaseType := ut;
    for i := 0 to Count - 1 do
    begin
      ss := pStartStopInfo(Pointers[i]);
      if ss.StartKeyStr <> '' then
      begin
        p := ss.StartKey;
        Move(ss.StartKeyStr[1], p^, Length(ss.StartKeyStr) * SizeOf(p^));
        upproc(p)
      end;
      if ss.StopKeyStr <> '' then
      begin
        p := ss.StopKey;
        Move(ss.StopKeyStr[1], p^, Length(ss.StopKeyStr) * SizeOf(p^));
        upproc(p)
      end
    end
  end
end;

procedure TStartStopKeyList.DefineProperties(Filer: TFiler);
begin
  Filer.DefineProperty('Keys', ReadData, WriteData, Count > 0)
end;

procedure TStartStopKeyList.ReadData(Reader: TReader);
var pk: TKeywordInfo; ps: Boolean; start, stop: string; sopt: Byte; pp: pStartStopInfo; sscope, spriority, sextra: Integer; extss: Boolean;
begin
  Reader.ReadListBegin;
  Clear;
  sscope := 0;
  // to avoid warnings
  spriority := 0;
  sextra := 0;
  while not Reader.EndOfList do
  begin
    start := string(Reader.ReadString);
    stop := string(Reader.ReadString);
    extss := False;
    with pk do
    begin
      sopt := Reader.ReadInteger;
      Byte(Options) := sopt and $7F;
      Byte(Style) := Reader.ReadInteger;
      ContextNumber := Reader.ReadInteger;
      Cursor := Reader.ReadInteger;
      Backgnd := Reader.ReadInteger;
      Foregnd := Reader.ReadInteger;
      if Reader.NextValue in [vaInt8, vaInt16, vaInt32] then
      begin
        // read version 5 extended keys
        sscope := Reader.ReadInteger;
        spriority := Reader.ReadInteger;
        extss := True
      end
    end;
    ps := Reader.ReadBoolean;
    if sopt and $80 <> 0 then
    begin
      sscope := Reader.ReadInteger;
      spriority := Reader.ReadInteger;
      sextra := Reader.ReadInteger;
      extss := True
    end;

    AddStartStopKey(start, stop, pk.Options, pk.Style, pk.ContextNumber, pk.Cursor, pk.Backgnd, pk.Foregnd, ps);
    if extss then
    begin
      pp := Pointers[Count - 1];
      pp^.Scope := sscope;
      pp^.Priority := spriority;
      pp^.Extra := (sextra shr 2);
      Byte(pp^.ssOptions) := sextra and $0F;
      if ps then
        Include(pp.ssOptions, ssoParStop)
    end

  end;
  Reader.ReadListEnd;
  fDelChecked := False;
end;

procedure TStartStopKeyList.WriteData(Writer: TWriter);
var i: Integer;
begin
  Writer.WriteListBegin;
  for i := 0 to Count - 1 do
    with pStartStopInfo(Pointers[i])^ do
    begin
      {$IFDEF PMSupportU}
      Writer.WriteWideString(StartKeyStr);
      Writer.WriteWideString(StopKeyStr);
      {$ELSE}
      Writer.WriteString(pmNativeString(StartKeyStr));
      Writer.WriteString(pmNativeString(StopKeyStr));
      {$ENDIF}
      Writer.WriteInteger(Byte(Attributes.Options) or $80);
      // $80 is a flag that Scope, Priority, Extra are there
      Writer.WriteInteger(Byte(Attributes.Style));
      Writer.WriteInteger(Attributes.ContextNumber);
      Writer.WriteInteger(Attributes.Cursor);
      Writer.WriteInteger(Attributes.Backgnd);
      Writer.WriteInteger(Attributes.Foregnd);
      Writer.WriteBoolean(ssoParStop in ssOptions);
      // redundant, kept for compatibility with v6.1 and before
      Writer.WriteInteger(Scope);
      Writer.WriteInteger(Priority);
      Writer.WriteInteger(Byte(ssOptions) or (Extra shl 4))
    end;

  Writer.WriteListEnd
end;

procedure TStartStopKeyList.LoadFromIniStrings(IniStrings: TStrings);
var ms: pmNativeString;
  ks: TStrings;
  i: Integer;
  Opt: TWordOptions;
  St: TFontStyles;
  Cn: Integer;
  Cr: TCursor;
  Bg, Fg: TColor;
  sOpt: TssOptions;
  msp, tscan: pmNativePChar;
  eqpos: Integer;
begin
  if IniStrings <> nil then
    ks := IniStrings
  else
    ks := TStringList.Create;

  Count := 0;
  for i := 0 to ks.Count - 1 do
  begin
    ms := ks[i];
    eqpos := Pos('=', ms);
    {$IFDEF D7New}
    if eqpos = 1 then
      eqpos := PosEx('=', ms, 2);
    {$ENDIF}
    if eqpos > 0 then
    begin
      msp := pmNativePChar(ms);
      tscan := msp + eqpos;
      Byte(Opt) := ScanInt(tscan);
      Byte(St) := ScanInt(tscan);
      Cn := ScanInt(tscan);
      Cr := ScanInt(tscan);
      Bg := ScanInt(tscan);
      Fg := ScanInt(tscan);
      Byte(sOpt) := ScanInt(tscan);
      ms := Copy(ms, 1, eqpos - 1);
      eqpos := Pos('|', ms);
      if eqpos < 1 then
        eqpos := Length(ms);
      AddStartStopKey(string(Copy(ms, 1, eqpos - 1)), string(Copy(ms, eqpos + 1, Length(ms) - eqpos)),
        Opt, St, Cn, Cr, Bg, Fg, ssoParStop in sOpt);
    end
  end
end;

procedure TStartStopKeyList.SaveToIniStrings(IniStrings: TStrings);
var ms, skey: pmNativeString; i: Integer; pss: pStartStopInfo;
begin
  if IniStrings = nil then
    Exit;
  IniStrings.Clear;
  for i := 0 to Count - 1 do
  begin
    pss := Pointers[i];
    ms := IntToStr(Byte(pss.Attributes.Options)) + ',' +
      IntToStr(Byte(pss.Attributes.Style)) + ',' +
      IntToStr(pss.Attributes.ContextNumber) + ',' +
      IntToStr(pss.Attributes.Cursor) + ',' +
      IntToStr(pss.Attributes.Backgnd) + ',' +
      IntToStr(pss.Attributes.Foregnd) + ',' +
      IntToStr(Byte(pss.ssOptions)) + ',' +
      IntToStr(pss.Scope) + ',' +
      IntToStr(pss.Priority) + ',';

    skey := pmNativeString(pss.StartKeyStr + '|' + pss.StopKeyStr);
    IniStrings.Add(skey + '=' + ms)
  end
end;

function FindTextP(APlusMemo: TObject; const fText: string; GoForward, MatchCase, WholeWordsOnly, Global: Boolean): Boolean;

  function strposdel(source, str1, str2: PChar; str2len: Integer; const dels: TSysCharSet): PChar;
  var found: Boolean;
  begin
    Result := nil;
    if (str1 = nil) or (str2 = nil) then
      Exit;
    if not WholeWordsOnly then
      Result := StrPos(str1, str2)
    else
    begin
      Result := str1 - 1;
      repeat
        Inc(Result);
        Result := StrPos(Result, str2);
        found := (Result <> nil) and
          ((Result = source) or (pmChar(source[(Result - source) - 1]) in dels)) and
          ((source[(Result - source) + str2len] = #0) or (pmChar(source[(Result - source) + str2len]) in dels))
      until (Result = nil) or found
    end
  end;

var ut, up, sp, found: PChar;
  pos: LongInt;
  len: Integer;
  parnb: LongInt;
  parp: pParInfo;
  upproc: TpmUpperCaseProc;

begin
  with TPlusMemo(APlusMemo) do
  begin
    upproc := UpCaseTypeToProc(UpperCaseType);
    len := Length(fText);
    ut := StrAlloc(len + 1);
    StrPCopy(ut, fText);
    Result := False;
    pos := -1;

    if Global then
      if GoForward then
        parnb := 0
      else
        parnb := IParList.Count - 1
    else
      parnb := SelPar;
    parp := IParList.Pointers[parnb];
    if MatchCase then
      up := IParList.ParPointers[parnb]^.ParText
    else
    begin
      up := GetUpText(parp, parnb, 0, GetParLength(parp^));
      upproc(ut)
    end;

    if Global then
      if GoForward then
        sp := up
      else
        sp := up + GetParLength(parp^)
    else
      sp := up + (SelStart - parp^.StartOffset);

    if GoForward then
    begin
      while (not Result) and (parnb < ParagraphCount) do
      begin
        found := StrPosdel(up, sp, ut, len, Delimiters);
        if found <> nil then
        begin
          Result := True;
          pos := (found - up) + parp^.StartOffset
        end else
        begin
          Inc(parnb);
          if parnb < ParagraphCount then
          begin
            parp := IParList.Pointers[parnb];
            if MatchCase then
              up := parp^.ParText
            else
              up := GetUpText(parp, parnb, 0, GetParLength(parp^));
            sp := up
          end
        end
      end;

      if Result then
      begin
        SelLength := 0;
        SelStart := pos + len;
        SelLength := -len;
      end
    end { if GoForward }

    else
    begin
      while (not Result) and (parnb >= 0) do
      begin
        found := strposdel(up, up, ut, len, Delimiters);
        if (found <> nil) and ((sp = nil) or (found - up < sp - up)) then
        begin
          Result := True;
          pos := found - up + parp^.StartOffset;
          Inc(found);
          found := StrPosdel(up, found, ut, len, Delimiters);
          while (found <> nil) and ((sp = nil) or (found - up < sp - up)) do
          begin
            pos := found - up + parp^.StartOffset;
            Inc(found);
            found := StrPosdel(up, found, ut, len, Delimiters)
          end
        end else
        begin
          Dec(parnb);
          if parnb >= 0 then
          begin
            parp := IParList.Pointers[parnb];
            if MatchCase then
              up := parp^.ParText
            else
              up := GetUpText(parp, parnb, 0, GetParLength(parp^));
            sp := nil
          end
        end
      end;

      if Result then
      begin
        SelStart := pos;
        SelLength := len;
      end
    end;
    { if not GoForward }
    StrDispose(ut)
  end { with APlusMemo }
end; { method FindText }

var tmpnav1: TPlusNavigator = nil;
  tmpnav2, tmpnav3: TPlusNavigator; { temporary TPlusNavigators used in ApplyStartStopkeys and ApplyKeywords }
  { they are kept created for efficiency whenever MemoCount>0 }
  fssk1, fssk2: TPlusNavigator; { idem, used in FindStart, FindStop }

procedure BuildTmpNavs;
begin
  tmpnav1 := TPlusNavigator.Create(nil);
  tmpnav2 := TPlusNavigator.Create(nil);
  tmpnav3 := TPlusNavigator.Create(nil);
  fssk1 := TPlusNavigator.Create(nil);
  fssk2 := TPlusNavigator.Create(nil)
end;

function FindStop(Start, Stop: TPlusNavigator): Boolean; { search for a stop key between Start and Stop, if found then
                                                                   add a DynInfoRec, and Stop.Pos:= end of stopkey }
var
  skeyindex: SmallInt;
  slen: Integer;
  t, keyfound: PChar;
  backstart,
  backend,
  eoff: Integer;
  i: Integer;
  tlen: Integer;
  dinfo: DynInfoRec;
  leveltofind: SmallInt;

  rightchar, endchar: Char;
  leftdelcheck, rightdelcheck: Boolean;

  schecklen: Integer;
  otherindex: Integer;
  otherssinfo,
  pssinfo: pStartStopInfo;

  slevel: SmallInt;
  scount: Integer;
  spstartdyn: pDynInfoRec;
  smemo: TPlusMemo;
  sparlen: Integer;

begin
  Result := False;
  spstartdyn := Start.pDynAttr;
  slevel := DynToLevel(spstartdyn^);
  if slevel < 0 then
    Exit;
  skeyindex := spstartdyn^.KeyIndex[slevel];
  if tmpnav1 = nil then
    BuildTmpNavs;

  smemo := TPlusMemo(Start.fPMemo);
  with smemo do
  begin
    if (skeyindex > 0) or (StartStopKeys = nil) or (skeyindex and $7FFF >= StartStopKeys.Count) then
    begin
      if StartStopKeys = nil then
        scount := 0
      else
        scount := StartStopKeys.Count;
      if Highlighter <> nil then
        Result := Highlighter.FindStop(Start, Stop, scount);
      Exit
    end;

    pSSInfo := StartStopKeys.Pointers[skeyindex and $7FFF];
  end;

  slen := pSSInfo^.StopLen;
  leftdelcheck := pSSInfo^.StopLeftCheck;
  rightdelcheck := pSSInfo^.StopRightCheck;
  schecklen := slen;
  if leftdelcheck then
    Inc(schecklen);
  if Start.fOffset >= schecklen then
    backstart := schecklen
  else
  begin
    backstart := Start.fOffset;
    leftdelcheck := False
  end;

  { go past the start key }
  if Start.fDynNb > 0 then
    with spstartdyn^ do
      if Start.fOffset <= DynOffset + pSSInfo.StartLen { StartKLen } then
        // v6.5a
      begin
        backstart := DynOffset + pSSInfo.StartLen { StartKLen } - Start.fOffset;
        // v6.5a
        if leftdelcheck and (backstart < Start.fOffset) then
          Inc(backstart)
      end;

  sparlen := GetParLength(Stop.fPar^);
  schecklen := slen;
  if rightdelcheck then
    Inc(schecklen);
  if Stop.ParOffset + schecklen > sparlen then
  begin
    eoff := GetParLength(Start.fPar^);
    backend := 0;
    rightdelcheck := False;
  end else
  begin
    eoff := Stop.fOffset;
    backend := schecklen
  end;

  tlen := eoff - Start.ParOffset + backstart + backend;
  if not(woMatchCase in pssinfo^.Attributes.Options) then
    t := smemo.GetUpText(Start.fPar, Start.fParNb, Start.fOffset - backstart, tlen)
  else
    t := Start.fPar^.ParText + (Start.fOffset - backstart);

  if t = nil then
    endchar := #0 { avoid a warning }
  else
  begin
    endchar := t[tlen];
    t[tlen] := #0
  end;
  rightchar := #0;
  { to avoid a warning }

  { t is ready; look for a stop key in it }
  keyfound := t;
  if leftdelcheck then
    Inc(keyfound);
  while (not Result) and (keyfound <> nil) do
  begin
    if rightdelcheck then
    begin
      rightchar := t[tlen - 1];
      t[tlen - 1] := #5
    end;
    keyfound := StrPos(keyfound, pSSInfo^.StopKey);
    if rightdelcheck then
      t[tlen - 1] := rightchar;

    if keyfound <> nil then
      with smemo do
        if (leftdelcheck and (not(pmChar(t[keyfound - t - 1]) in Delimiters))) or
          (rightdelcheck and (not(pmChar(t[keyfound - t + slen]) in Delimiters))) then
          keyfound := keyfound + 1
        else
          Result := True
  end;

  if Result or ((ssoParStop in PSSInfo^.ssOptions) and (Stop.ParOffset = GetParLength(Stop.fPar^))) then
  begin
    if keyfound <> nil then
    begin
      eoff := Start.Pos - backstart + (keyfound - t) + slen;
      Stop.Pos := eoff - slen;
      while Stop.ForwardToDyn(eoff) do
        Stop.RemoveDyn;
      Stop.Pos := eoff
    end;
    Result := True
  end;

  if t <> nil then
    t[tlen] := endchar;

  if Result then
  begin
    fssk1.fPMemo := Start.fPMemo;
    fssk1.Assign(Start);
    fssk1.BackToDyn(0);
    if pSSInfo^.StopLeftCheck then
      Inc(slen);
    fssk1.Par^.ParExtra.DynCodes[fssk1.fDynNb].StopKLen := slen;

    { check whether another identical start key exists }
    otherindex := -1;
    with smemo.StartStopKeys do
      for i := (skeyindex and $7FFF) + 1 to Count - 1 do
        if pStartStopInfo(Pointers[i])^.Previous = skeyindex and $7FFF then
        begin
          otherindex := i;
          Break
        end;

    if otherindex = -1 then
    begin
      leveltofind := Start.DynAttr.Level - 1;
      fssk1.Assign(Start);
      while DynToLevel(fssk1.DynAttr) > leveltofind do
        fssk1.BackToDyn(0);
      dinfo := fssk1.DynAttr
    end else
      with dinfo, TPlusMemo(Start.fPMemo).StartStopKeys do
      begin
        otherssinfo := Pointers[otherindex];
        KeyIndex := Start.DynAttr.KeyIndex;
        Level := Start.DynAttr.Level;
        DynStyle := Byte(otherssinfo^.Attributes.Style) or $C0;
        CollpsLevel := 0;
        CollpsState := [];
        KeyIndex[Level] := -32768 + otherindex;
        Cursor := otherssinfo^.Attributes.Cursor;
        Backgnd := otherssinfo^.Attributes.Backgnd;
        Foregnd := otherssinfo^.Attributes.Foregnd
      end;

    dinfo.StartKLen := 0;
    Stop.AddDyn(dinfo);
    fssk1.fPMemo := nil
  end;
end; { FindStop }

function FindStart(Start, Stop: TPlusNavigator): Boolean; { they must be in the same par. }

  function getok(const dyn: DynInfoRec): Boolean;
  begin
    Result := True;
    if (dyn.DynStyle and $C0 = $C0) and (dyn.Level >= 0) then
      Result := dyn.KeyIndex[dyn.Level] >= -1
  end;

var
  slen, tlen: Integer;
  t, tup: PChar;
  tcomp1, tcomp2: PChar;
  backstart,
  backend, eoff: LongInt;
  i, ilim, idynlim: Integer;
  j, jlim, jadd: SmallInt;
  jssinfo: pStartStopInfo;
  m, mlim: Integer;
  dinfo: DynInfoRec;

  ok: Boolean;
  checklen: Integer;
  smemo: TPlusMemo;
  scount: Integer;
  sdynbuf: TDynInfoArray;
  sss: TStartStopKeyList;
  sparlen: Integer;

label jContinue, FindHStart;

begin
  sdynbuf := nil;
  Start.RightOfDyn;
  Result := False;

  if DynToLevel(Start.pDynAttr^) >= 15 then
    Exit;

  smemo := TPlusMemo(Start.fPMemo);
  sss := smemo.StartStopKeys;

  if sss = nil then
    scount := 0
  else
    scount := sss.Count;

  if (not smemo.ApplyStartStopKeys) or (scount = 0) then
    goto FindHStart;

  fssk1.fPMemo := Start.fPMemo;
  fssk1.Assign(Start);

  if Start.fOffset >= sss.fLongestStartKey + 1 then
    backstart := sss.fLongestStartKey + 1
  else
    backstart := Start.ParOffset;
  fssk1.Pos := Start.Pos - backstart;

  eoff := Stop.ParOffset;
  sparlen := GetParLength(Stop.fPar^);
  if eoff + sss.fLongestStartKey + 1 > sparlen then
    backend := sparlen - eoff
  else
    backend := sss.fLongestStartKey + 1;
  tlen := eoff - Start.fOffset + backstart + backend;
  if tlen <= 0 then
    goto FindHStart;

  t := Start.fPar^.ParText + fssk1.fOffset;
  tup := nil;

  ok := getok(fssk1.pDynAttr^);
  if (not ok) and (fssk1.fDynNb >= GetDynCount(Start.fPar^)) then
    goto FindHStart;

  m := fssk1.fDynNb;
  mlim := GetDynCount(fssk1.fPar^);

  i := 0;
  jadd := sss.fElementSpace;
  jlim := sss.Count;
  if pmpHasExtra in Start.fPar^.ParState then
    sdynbuf := Start.fPar^.ParExtra.DynCodes;
  ilim := tlen - backend;
  if m < mlim then
    idynlim := sdynbuf[m].DynOffset - fssk1.fOffset
  else
    idynlim := High(idynlim);
  slen := 0;
  if not ok then
    i := idynlim;

  while i <= ilim do
  begin
    if i >= idynlim then
    begin
      while (m < mlim) and (sdynbuf[m].DynOffset <= i + fssk1.fOffset) do
      begin
        ok := getok(sdynbuf[m]);
        Inc(m)
      end;
      if m < mlim then
        idynlim := sdynbuf[m].DynOffset - fssk1.fOffset
      else
        idynlim := High(idynlim)
    end;

    if not ok then
    begin
      i := idynlim;
      Continue end;

    jssinfo := sss.Pointers[0];
    j := 0;
    while j < jlim do
    begin
      slen := jssinfo^.StartLen;
      if jssinfo^.StartRightCheck then
        checklen := slen + 1
      else
        checklen := slen;
      if (i + checklen > backstart) and (i + slen <= tlen) then
      begin
        tcomp1 := jssinfo^.StartKey;
        if not(woMatchCase in jssinfo^.Attributes.Options) then
        begin
          if tup = nil then
            tup := smemo.GetUpText(Start.fPar, Start.fParNb, fssk1.fOffset, tlen);
          tcomp2 := tup + i
        end else
          tcomp2 := t + i;

        while (slen > 0) and (tcomp1^ = tcomp2^) do
        begin
          Dec(slen);
          Inc(tcomp1);
          Inc(tcomp2)
        end;

        if slen = 0 then
        begin
          slen := jssinfo^.StartLen;
          if not(jssinfo^.StartLeftCheck and (i > 0) and (not(pmChar(t[i - 1]) in smemo.Delimiters))) and
            not(jssinfo^.StartRightCheck and (i + slen < tlen) and (not(pmChar(t[i + slen]) in smemo.Delimiters))) then
          begin
            Result := True;
            Break
          end
        end
      end;
      jContinue:
      Inc(PAnsiChar(jSSInfo), jadd);
      Inc(j)
    end;

    if not Result then
      Inc(i)
    else
    begin
      fssk1.Pos := fssk1.Pos + i;
      Stop.Assign(fssk1);
      Stop.RightOfDyn;
      dinfo.Level := DynToLevel(Stop.DynAttr) + 1;

      { check whether we are nesting within the same kind of start-stop key,
             which must be avoided if stopkey=startkey }
      { if dinfo.Level-1>=0 then
             if (skey1.DynAttr.KeyIndex[dinfo.Level-1]=j or SmallInt($8000)) and
                 ((jssinfo^.StartLen=jssinfo^.StopLen) and
                  (StrComp(jssinfo^.StartKey, jssinfo^.StopKey)=0)) then
               begin
               Inc(i);
               Continue
               end; }
      if dinfo.Level > 0 then
        with Stop do
        begin
          if BackToDyn(0) then
            Par^.ParExtra.DynCodes[DynNb].StopKLen := 0;
          Assign(fssk1);
          RightOfDyn
        end;

      { remove stray dyn codes }
      while Stop.ForwardToDyn(fssk1.Pos + slen) do
        Stop.RemoveDyn;

      with dinfo do
      begin
        DynOffset := fssk1.ParOffset;
        KeyIndex := Stop.DynAttr.KeyIndex;
        DynStyle := Byte(jssinfo^.Attributes.Style) or $C0;
        CollpsLevel := 0;
        CollpsState := [];
        KeyIndex[Level] := -32768 + j;
        Cursor := jssinfo^.Attributes.Cursor;
        Backgnd := jssinfo^.Attributes.Backgnd;
        Foregnd := jssinfo^.Attributes.Foregnd;
        Context := jssinfo^.Attributes.ContextNumber;
        StartKlen := jssinfo^.StartCheckLen;
        //slen;  v6.5a
        StopKLen := jssinfo^.StopLen;
        if jssinfo^.StartRightCheck then
          Inc(StartKLen)
      end;
      with fssk1 do
        if (fDynNb < GetDynCount(fPar^)) and (fPar^.ParExtra.DynCodes[fDynNb].DynOffset = fOffset) then
          fPar^.ParExtra.DynCodes[fDynNb] := dinfo
        else
          AddDyn(dinfo);
      Stop.Pos := fssk1.Pos + slen;
      Stop.RightOfDyn;
      Break
    end { found start key }

  end;
  { iloop in text buffer }

  fssk1.fPMemo := nil;

  FindHStart:
  if smemo.Highlighter <> nil then
    Result := Result or smemo.Highlighter.FindStart(Start, Stop, scount)
end; { FindStart }

procedure ApplyKeywordsListP(Start, Stop: TPlusNavigator);

type keywfound = record keyw: Integer; Offset: Integer; keylen: Integer end;
var
  i: LongInt; j: Integer;
  tlow, tup, tfound, tsearch, s, torg: PChar;
  { torg: the original text;
    tlow, tup:  initial case text, uppercase text }

  tlen, bflen, slen: Integer;
  dinfop: pKeyInfoLen;
  pp: pParInfo;
  scar: Char;
  startoff, stopoff, illoff, illlim: Integer;
  tstartoffset: Integer; { offset of tlow, tup in par.Text }
  attr: DynInfoRec;

  startp, stopp: LongInt;

  nbkeywtodo: SmallInt;
  keywtodo: array[0..15] of keywfound;
  over, sresetkeywords: Boolean;
  curdynnb: Integer;
  endword: Integer;

  function overridable(const drec: DynInfoRec): Boolean;
    { return false if drec indicates cannot be overriden by keyword }
  begin
    with drec do
      if (DynStyle and $80 = 0) or (Context = 0) then
        Result := True
      else
        Result := sresetkeywords and (DynStyle and $C0 = $C0) and (KeyIndex[Level] >= 0);

  end;

  procedure applykwfound;
  var firstkpos: LongInt;
    drec: DynInfoRec;
    kinfo: TKeywordInfo;
    k: SmallInt;
    currentlevel: SmallInt;
  begin
    tmpnav1.fPMemo := Start.fPMemo;
    tmpnav2.fPMemo := Start.fPMemo;
    firstkpos := High(firstkpos);
    with tmpnav1 do
    begin
      fPar := pp;
      fPos := pp^.StartOffset;
      fDynNb := 0;
      fOffset := 0;
      fParLine := 0;
      fParNb := i;
      if fNavLines <> nil then
        fNavLines.LLPar := pp
    end;

    for k := 0 to nbkeywtodo - 1 do
      with keywtodo[k] do
      begin
        tmpnav1.Pos := pp^.StartOffset + offset;
        if tmpnav1.Pos < firstkpos then
          firstkpos := tmpnav1.Pos;
        tmpnav1.RightOfDyn;
        currentlevel := DynToLevel(tmpnav1.DynAttr);
        if currentlevel < 15 then
        begin
          if currentlevel >= 0 then
          begin
            tmpnav2.Assign(tmpnav1);
            with tmpnav2 do
              if BackToDyn(0) then
                Par^.ParExtra.DynCodes[fDynNb].StopKLen := 0
          end;
          tmpnav2.Assign(tmpnav1);
          tmpnav2.Pos := tmpnav2.Pos + keylen;
          kinfo := TPlusMemo(tmpnav1.fPMemo).Keywords.KeyInfos[keyw];
          with drec do
          begin
            KeyIndex := tmpnav1.DynAttr.KeyIndex;
            DynStyle := Byte(kinfo.Style) or $C0;
            CollpsLevel := 0;
            CollpsState := [];
            Backgnd := kinfo.Backgnd;
            Foregnd := kinfo.Foregnd;
            Context := kinfo.ContextNumber;
            Cursor := kinfo.Cursor;
            StartKLen := keylen;
            StopKLen := keylen;
            Level := CurrentLevel + 1;
            KeyIndex[Level] := keyw
          end;

          SetDynStyleP(TPlusMemo(tmpnav1.fPMemo).IParList, tmpnav1, tmpnav2, drec, True, False);
          if Start.Pos < tmpnav2.Pos then
            Start.Pos := tmpnav2.Pos;
          if Stop.Pos < tmpnav2.Pos then
            Stop.Assign(tmpnav2);
          Start.RightOfDyn;
          Stop.RightOfDyn
        end
      end;
    InvalidateNavs(TPlusMemo(Start.fPMemo).INavigators, firstkpos, tmpnav1.fParNb);

    tmpnav1.fPMemo := nil;
    tmpnav2.fPMemo := nil;
    nbkeywtodo := 0;
  end; { local proc. applykwfound }

begin
  { ApplyKeywordsList }
  with TPlusMemo(Start.fPMemo) do
  begin
    if Highlighter <> nil then
    begin
      if Keywords <> nil then
        j := Keywords.Count
      else
        j := 0;
      Highlighter.ApplyKeywordsList(Start, Stop, j)
    end;

    if ApplyKeywords and (Keywords <> nil) and (Keywords.Count > 0) then
    begin
      if tmpnav1 = nil then
        BuildTmpNavs;
      sresetkeywords := Keywords.ResetKeywords;
      pp := Start.Par;
      tlow := nil;
      tup := nil;
      bflen := 0;
      startp := start.fParNb;
      stopp := Stop.ParNumber;

      for i := startp to stopp do
      begin
        if pp = nil then
          pp := IParList.Pointers[i];
        Start.RightOfDyn;
        attr := Start.DynAttr;
        over := overridable(attr);
        if not over and ((Start.fDynNb >= GetDynCount(pp^)) or ((startp = stopp) and (Start.fDynNb = Stop.DynNb))) then
        begin
          { this whole section is under start-stop key, so }
          pp := nil;
          { nothing to do }
          Continue
        end;

        if i = startp then
        begin
          startoff := Start.fOffset;
          with Keywords do
            if startoff > fLongestKeyword + 1 then
              tstartoffset := startoff - fLongestKeyword - 1
            else
              tstartoffset := 0
        end else
        begin
          startoff := 0;
          tstartoffset := 0 end;

        if i = stopp then
        begin
          stopoff := Stop.fOffset;
          with Keywords do
            if stopoff + fLongestKeyword < GetParLength(pp^) then
              tlen := stopoff + fLongestKeyword - tstartoffset
            else
              tlen := GetParLength(pp^) - tstartoffset
        end else
        begin
          stopoff := GetParLength(pp^);
          tlen := stopoff - tstartoffset end;

        if tlen = 0 then
        begin
          pp := nil;
          Continue end;
        if tlen >= bflen then
        begin
          if tlow <> nil then
          begin
            StrDispose(tlow);
            tlow := nil end;
          if tup <> nil then
          begin
            StrDispose(tup);
            tup := nil end;
          bflen := tlen + 1
        end;

        { prepare torg, tlow, tup }
        torg := pp^.ParText + tstartoffset;
        if tlow = nil then
          tlow := StrAlloc(bflen);
        if (tup = nil) and not(woMatchCase in Keywords.GlobalWordOptions) then
          tup := StrAlloc(bflen);
        System.Move(torg^, tlow^, tlen * SizeOf(tlow^));
        if tup <> nil then
          System.Move(GetUpText(pp, i, tstartoffset, tlen)^, tup^, tlen * SizeOf(tup^));

        curdynnb := Start.DynNb;
        while (curdynnb > 0) and (pp^.ParExtra.DynCodes[curdynnb - 1].DynOffset > tstartoffset) do
          Dec(curdynnb);
        if curdynnb < GetDynCount(pp^) then
          illlim := pp^.ParExtra.DynCodes[curdynnb].DynOffset - tstartoffset
        else
          illlim := High(illlim);
        illoff := 0;
        if curdynnb > 0 then
          over := overridable(pp^.ParExtra.DynCodes[curdynnb - 1])
        else
          over := overridable(GetStartDynAttrib(pp^)^);
        while illoff < tlen do
        begin
          if not over then
          begin
            tlow[illoff] := #5;
            if tup <> nil then
              tup[illoff] := #5
          end;
          Inc(illoff);
          while illoff >= illlim do
          begin
            Inc(curdynnb);
            if curdynnb < GetDynCount(pp^) then
              illlim := pp^.ParExtra.DynCodes[curdynnb].DynOffset - tstartoffset
            else
              illlim := High(illlim);
            over := overridable(pp^.ParExtra.DynCodes[curdynnb - 1])
          end

        end;

        tlow[tlen] := #0;
        if tup <> nil then
          tup[tlen] := #0;

        { tlow, tup are ready, now iterate over keywords }
        nbkeywtodo := 0;
        for j := 0 to Keywords.Count - 1 do
        begin
          dinfop := pKeyInfoLen(Keywords.fKeyList[j]);
          if dinfop^.BasicPart.ContextNumber <> 0 then
          begin
            if woMatchCase in dinfop^.BasicPart.Options then
              tsearch := tlow
            else
              tsearch := tup;
            slen := dinfop^.KeyLen;

            if (not sresetkeywords) and (startoff - tstartoffset > slen) then
              tfound := tsearch + (startoff - tstartoffset - slen)
            else
              tfound := tsearch;

            endword := stopoff - tstartoffset + slen;
            if endword < tlen then
            begin
              scar := tsearch[endword];
              tsearch[endword] := #0
            end else
              scar := #0;

            s := PChar(pKeyInfoLen(keywords.fkeylist[j]).KeywordTrans);

            while tfound <> nil do
            begin
              tfound := StrPos(tfound, s);
              if tfound <> nil then
              begin
                if not(woWholeWordsOnly in dinfop^.BasicPart.Options) or
                  (((tfound = tsearch) or (pmChar(torg[tfound - tsearch - 1]) in Delimiters)) and
                    (((tfound - tsearch + slen = tlen) or
                      (pmChar(torg[tfound - tsearch + slen]) in Delimiters)))) then
                begin
                  { add to keywtodo array }
                  if nbkeywtodo = 16 then
                    applykwfound;
                  with keywtodo[nbkeywtodo] do
                  begin
                    Offset := tfound - tsearch + tstartoffset;
                    keyw := j;
                    keylen := slen
                  end;
                  Inc(nbkeywtodo);

                  for illoff := tfound - tsearch to tfound - tsearch + slen - 1 do
                    tlow[illoff] := #5;
                  if tup <> nil then
                    for illoff := tfound - tsearch to tfound - tsearch + slen - 1 do
                      tup[illoff] := #5;
                end;
                { boundaries are ok }

                tfound := tfound + slen
              end { if tfound<>nil }

            end;
            { while tfound<>nil }

            if endword < tlen then
              tsearch[endword] := scar
          end { valid word options }

        end;
        { j loop over Keyword list }
        if nbkeywtodo > 0 then
          applykwfound;
        pp := nil;
      end;
      { i loop over paragraphs }

      if tlow <> nil then
        StrDispose(tlow);
      if tup <> nil then
        StrDispose(tup);
    end;
    { keyword list not empty }

  end
end; { method ApplyKeywords }

procedure ApplyStartStopKeyListP(Start, Stop: TPlusNavigator; var FinalDyn: DynInfoRec);
  { N.B: Untested with paragraph span }
  function samedyn(const dyn1, dyn2: DynInfoRec): Boolean;
  var i: Integer;
  begin
    if dyn1.DynStyle and $C0 <> dyn2.DynStyle and $C0 then
      Result := False
    else if dyn1.DynStyle and $80 = 0 then
      Result := True
    else
    begin
      Result := False;
      if dyn1.Level <> dyn2.Level then
        Exit;
      if dyn1.Context <> dyn2.Context then
        Exit;
      for i := 0 to dyn1.Level do
        if dyn1.KeyIndex[i] <> dyn2.KeyIndex[i] then
          Exit;
      Result := True
    end
  end;

var
  startpar, stoppar, i, splen: Integer;
  dynreconf, inmandyn, rangedone: Boolean;
  sdattr: pDynInfoRec;
  spar: pParInfo;
label reparse;

begin
  with TPlusMemo(Start.fPMemo) do
  begin
    if StartStopKeys <> nil then
      with StartStopKeys do
      begin
        if not DelChecked then
          { arrange internal StartStopKey fields according to delimiters }
          for i := 0 to Count - 1 do
            with pStartStopInfo(Pointers[i])^ do
            begin
              StartLeftCheck := (woWholeWordsOnly in Attributes.Options) and (not(pmChar(StartKey[0]) in Delimiters));
              StartRightCheck := (woWholeWordsOnly in Attributes.Options) and (not(pmChar(StartKey[StartLen - 1]) in Delimiters));
              StopLeftCheck := (StopLen > 0) and (woWholeWordsOnly in Attributes.Options) and (not(pmChar(StopKey[0]) in Delimiters));
              StopRightCheck := (StopLen > 0) and (woWholeWordsOnly in Attributes.Options) and
                (not(pmChar(StopKey[StopLen - 1]) in Delimiters))
            end;
        DelChecked := True
      end;

    { initialize working TPlusNavigators }
    if tmpnav1 = nil then
      BuildTmpNavs;
    tmpnav1.fPMemo := Start.fPMemo;
    tmpnav2.fPMemo := Start.fPMemo;
    tmpnav3.fPMemo := Start.fPMemo;
    startpar := Start.ParNumber;
    stoppar := Stop.ParNumber;

    dynreconf := False;

    reparse: with Stop do
      if (ParOffset = GetParLength(fPar^)) and (fParNb < IParList.Count - 1) then
        FinalDyn := GetStartDynAttrib(pParInfo(IParList.Pointers[fParNb + 1])^)^;

    tmpnav1.Assign(Start);

    for i := startpar to stoppar do
    begin
      if i <> startpar then
        tmpnav1.ParNumber := i;
      splen := GetParLength(tmpnav1.Par^);
      tmpnav2.Assign(tmpnav1);
      if i = stoppar then
        tmpnav2.Assign(Stop)
      else
      begin
        tmpnav2.Assign(tmpnav1);
        tmpnav2.ParOffset := splen
      end;
      tmpnav2.RightOfDyn;
      if (i = stoppar) and (tmpnav2.fDynNb > Stop.fDynNb) and (tmpnav2.fOffset < splen) then
        FinalDyn := tmpnav2.fPar^.ParExtra.DynCodes[tmpnav2.fDynNb - 1];

      repeat

        { go past manually set dyn parts }
        repeat
          with tmpnav1.pDynAttr^ do
            inmandyn := (DynStyle and $80 <> 0) and (Level = -1);
          if inmandyn then
          begin
            if not tmpnav1.ForwardToDyn(tmpnav2.Pos) then
              tmpnav1.Pos := tmpnav2.Pos;
            { this range is all under manually set Dyn style }
            tmpnav1.RightOfDyn
          end;
        until (not inmandyn) or (tmpnav1.Pos = tmpnav2.Pos);

        tmpnav3.Assign(tmpnav2);
        rangedone := True;

        if tmpnav3.fDynNb > tmpnav1.fDynNb then
          { clean up dyn codes in  range }
        begin
          { go back before manually set dyn parts }
          tmpnav3.Assign(tmpnav1);
          repeat
            if tmpnav3.ForwardToDyn(tmpnav2.Pos) then
              with tmpnav3.fPar^.ParExtra.DynCodes[tmpnav3.fDynNb] do
                if (DynStyle and $80 = 0) or (Level <> -1) then
                begin
                  if (DynStyle and $80 <> 0) and (pmdCollapsed in CollpsState) then
                  begin
                    tmpnav3.DynNb := tmpnav3.DynNb + 1;
                    tmpnav3.Expand;
                    tmpnav3.DynNb := tmpnav3.DynNb - 1;
                  end;
                  tmpnav3.RemoveDyn;
                  dynreconf := True;
                  if tmpnav2.fDynNb > tmpnav3.fDynNb then
                    Dec(tmpnav2.fDynNb);
                  inmandyn := False
                end else
                  inmandyn := True
                else
                begin
                  tmpnav3.Assign(tmpnav2);
                  inmandyn := True
                end
          until inmandyn
        end;

        { search for a stop key between tmpnav1 and tmpnav3, if found mark further text as unparsed
        and tmpnav3.Pos:= pos of stopkey + its length }
        if findstop(tmpnav1, tmpnav3) then
        begin
          { if tmpnav1.ParOffset<splen then } rangedone := False;
          dynreconf := True
        end;

        { search for a start key from tmpnav1 to tmpnav3, if found mark further text as unparsed
        and tmpnav3.Pos:= pos of startkey + its length }
        if findstart(tmpnav1, tmpnav3) then
        begin
          dynreconf := True;
          rangedone := False
        end;

        tmpnav1.Assign(tmpnav3);
        tmpnav1.RightOfDyn;
        if tmpnav3.Pos > tmpnav2.Pos then
          with tmpnav2 do
          begin
            ParOffset := splen;
            RightOfDyn;
            if (fParNb >= stoppar) and (fParNb < IParList.Count - 1) then
              FinalDyn := GetStartDynAttrib(pParInfo(IParList.Pointers[fParNb + 1])^)^;
          end else if dynreconf then
            { replace tmpnav2.fDynNb, which is not valid anymore }
          begin
            tmpnav2.fDynNb := -1;
            tmpnav2.RightOfDyn
          end

      until (tmpnav1.Pos >= tmpnav2.Pos) and rangedone;

      Include(tmpnav2.fPar^.ParState, pmpSSDone);
      if i < stoppar then
        { adjust StartDynAttrib for next paragraph }
      begin
        spar := IParList.Pointers[i + 1];
        if tmpnav1.DynNb = 0 then
        begin
          sdattr := GetStartDynAttrib(tmpnav1.fPar^);
          SetStartDynAttrib(spar^, sdattr, False);
        end else
        begin
          SetStartDynAttrib(spar^, tmpnav1.pDynAttr, True)
        end
      end
    end;

    { done parsing the requested range: check whether the range should be extended }
    IParList.fLastStartStopParsed := stoppar;
    tmpnav2.RightOfDyn;
    Stop.Pos := tmpnav2.Pos;
    if not samedyn(tmpnav2.DynAttr, FinalDyn) then
      { extend the range }
    begin
      if tmpnav2.fOffset < GetParLength(tmpnav2.fPar^) then
        { if the range did not go up to the paragraph end, extend it there }
      begin
        { and parse it right now }
        tmpnav1.Assign(tmpnav2);
        tmpnav2.Pos := tmpnav2.fPar^.StartOffset + GetParLength(tmpnav2.fPar^);
        tmpnav2.RightOfDyn;
        Stop.Assign(tmpnav2);
        startpar := tmpnav2.fParNb;
        stoppar := startpar;
        goto reparse;
      end else
        { mark succeeding paragraph as unparsed }
        if stoppar < IParList.Count - 1 then
        begin
          spar := IParList.Pointers[stoppar + 1];
          spar.ParState := spar.ParState - [pmpFormatted, pmpSSDone, pmpKeywDone];
          if tmpnav2.fDynNb = 0 then
          begin
            sdattr := GetStartDynAttrib(tmpnav2.fPar^);
            SetStartDynAttrib(spar^, sdattr, False);
          end else
          begin
            SetStartDynAttrib(spar^, tmpnav2.pDynAttr, True) //sdattr)
          end;
          if IParList.fUpdateStopPar < stoppar + 1 then
            IParList.fUpdateStopPar := stoppar + 1;
          if (IParList.fModStopPar >= 0) and (IParList.fModStopPar < stoppar + 1) then
            IParList.fModStopPar := stoppar + 1  // v5.3a
        end
    end;

    { return tmp navigators to their unused state }
    tmpnav1.fPMemo := nil;
    tmpnav2.fPMemo := nil;
    tmpnav3.fPMemo := nil;

    if dynreconf then
      { invalidate the TPlusNavigators that point in the range }
    begin
      IParList.fNoCompleteFormat := False;
      InvalidateNavs(INavigators, Start.Pos, Stop.fParNb)
    end

  end

end;

procedure ReformatParP(APMemo: TObject;
  DC: TCanvas;
  InitDC: Boolean; FormWidth: Integer;
  Par: pParInfo;
  ParNum: LongInt;
  var FirstLine, LastChanged: Integer;
  CompleteReformat: Boolean;
  var OldFontH: THandle;
  var RunningSpaceWidth, SpaceKern, LinesChange, LinesCount: Integer);
  { reformat a paragraph starting from FirstLine;
    Lines are given start/stop values here, as well as width and start attrib.;
    return in LastLineChanged the number of last line whose start/stop values
    have changed, to help determine which lines need update on the display;

    If CompleteReformat is false, the method returns as soon as start/stop
    values appear in sync with values before beginning formatting.  If True,
    the method completes the paragraph until its end.

    FirstLine may be decremented by one if the first word encountered
    happens to fit on the previous line }

var olinecount,
  newlinecount,
  lOffset,
  curline,
  endoflastwordpos: Integer;

  linestart,
  startword,
  nextcar,
  stopoflastword,
  spacescounted,
  afterwordspaces,
  juststart,
  startwordpos: Integer;

  c: Char;
  t: PChar;
  j, sj, jlim: Integer;

  w, xpos, wi, k: Integer;

  currentattr, wordstartattr, linestartattr: TFontStyles;
  currentdyn, linestartdyn, wordstartdyn: DynInfoRec;
  curdynnb, wordstartdynnb, linestartdynnb: Integer;

  newline: LineInfo;
  sizeinfo: TSize;
  cstyle, sstyle: TFontStyles;
  linebeforetouched: Boolean;
  pline: pLineInfo;
  stmplines: array of LineInfo;
  plen, dcount: Integer;
  scolwrap: Boolean;
  smemo: TPlusMemo; // a local copy of AMemo with proper type for convenience
  sdc: THandle;

  procedure SetDC(style: TFontStyles; save: Boolean);
  var spcw, spck: Integer;
    Extent: TSize;
  begin
    smemo.SetupFont(dc.Font, style);
    {$IFNDEF pmClx}
    sdc := dc.Handle;
    if GetTextExtentPoint(sdc, '  ', 2, Extent) then
    begin
      spcw := Extent.cX;
      GetTextExtentPoint(sdc, ' ', 1, Extent);
      spck := 2 * Extent.cX - spcw;
      spcw := Extent.cX - spck
    end else
    begin
      spcw := 1;
      spck := 0
    end;
    {$ELSE}
    spcw := dc.TextWidth(' ');
    spck := 0;
    sdc := dc;
    {$ENDIF}

    RunningSpaceWidth := spcw;
    SpaceKern := spck
  end;

  function AdvanceDyn(offset: Integer; var dynnb: Integer; var dyninfo: DynInfoRec): Integer;
     { returns the new offset limit before the next dyn code }
  begin
    Inc(dynnb);
    while (dynnb < dcount) and (Par^.ParExtra.DynCodes[dynnb].DynOffset <= offset) do
      Inc(dynnb);
    if dynnb < dcount then
      Result := Par^.ParExtra.DynCodes[curdynnb].DynOffset
    else
      Result := High(Result);
    dyninfo := Par^.ParExtra.DynCodes[dynnb - 1];
    sstyle := cstyle;
    cstyle := smemo.AttrToExtFontStyles(currentattr, dyninfo.DynStyle);
    if TPlusFontStyles(cstyle) - [TPlusFontStyle(fsHighlight)] <>
      TPlusFontStyles(sstyle) - [TPlusFontStyle(fsHighlight)] then
      SetDC(cstyle, False)
  end;

label reloop;

var
  spc, swwchar: Char;
  susewwset: Boolean;
  swwchars: string;
  xcol: Integer;
begin
  smemo := TPlusMemo(APMemo);
  //{$IFDEF PMDEBUG} OutputDebugString(PAnsiChar(smemo.Name + ': Formatting par ' + IntToStr(ParNum))); {$ENDIF}
  swwchars := smemo.WordWrapChars;
  if swwchars <> '' then
  begin
    swwchar := smemo.WordWrapChars[1];
    susewwset := Length(swwchars) > 1
  end else
  begin
    swwchar := #0;
    susewwset := False
  end;

  if tmpnav1 = nil then
    BuildTmpNavs;
  if Par = nil then
    Par := smemo.IParList.Pointers[ParNum];
  plen := GetParLength(Par^);
  fssk1.fPMemo := smemo;
  fssk2.fPMemo := smemo;
  fssk1.fPar := Par;
  with fssk1 do
  begin
    if fNavLines <> nil then
      fNavLines.LLPar := fPar;
    fPos := fPar^.StartOffset;
    fParNb := ParNum;
    fOffset := 0;
    fDynNb := 0;
    fParLine := 0
  end;

  if (not(pmpKeywDone in Par^.ParState)) and (smemo.ApplyKeywords or (smemo.Highlighter <> nil)) then
  begin
    fssk2.Assign(fssk1);
    fssk2.Pos := Par^.StartOffset + plen;
    ApplyKeywordsListP(fssk1, fssk2);
  end;

  Par^.ParState := Par^.ParState + [pmpKeywDone, pmpFormatted];
  t := Par^.ParText;
  if dc = nil then
  begin
    FirstLine := 0;
    LinesChange := 0;
    if pmpHasExtra in Par^.ParState then
      with Par^.ParExtra.FirstLine do
      begin
        Stop := plen;
        LineWidth := 0;
        TotalWidth := 0;
        Spaces := 0;
        JustifyStart := 0;
        LinesChange := -Length(Par^.ParExtra.Lines);
        SetLength(Par^.ParExtra.Lines, 0)
      end;
    LastChanged := 0;
    LinesCount := 1;
    fssk1.fPMemo := nil;
    fssk2.fPMemo := nil;
    Exit
  end;

  olinecount := GetLineCount(Par^);
  if FirstLine > olinecount - 1 then
    FirstLine := olinecount - 1;
  curline := FirstLine;
  with fssk1.NavLines.LinePointers[curline]^ do
  begin
    currentattr := StartAttrib;
    if StartDynNb > 0 then
      currentdyn := Par^.ParExtra.DynCodes[StartDynNb - 1]
    else
      currentdyn := GetStartDynAttrib(Par^)^;
    curdynnb := StartDynNb;
    j := Start
  end;
  cstyle := smemo.AttrToExtFontStyles(currentattr, currentdyn.DynStyle);
  if InitDC then
    SetDC(cstyle, True)
  else
    sdc := dc.Handle;
  lastchanged := curline;

  { place the new lines }
  scolwrap := smemo.ColumnWrap > 0;
  if pmpNoWrap in Par^.ParState then
    w := High(w)
  else
    with smemo do
      if WordWrap or (Alignment in [taRightJustify, taCenter]) then
        if ColumnWrap > 0 then
          w := ColumnWrap
        else if ColumnWrap < 0 then
          w := -ColumnWrap
        else
          w := FormWidth - LeftMargin - RightMargin
      else
        w := High(w) - RightMargin;
  if w <= 0 then
    w := 1;

  xpos := 0;
  endoflastwordpos := 0;
  linestart := j;
  xcol := 0;
  if j < plen then
    c := t[j]
  else
    c := #0;
  linestartattr := currentattr;
  linestartdyn := currentdyn;
  linestartdynnb := curdynnb;

  spacescounted := 0;
  juststart := j;
  linebeforetouched := False;
  dcount := GetDynCount(Par^);
  if curdynnb < dcount then
    jlim := Par^.ParExtra.DynCodes[curdynnb].DynOffset
  else
    jlim := High(jlim);

  if j >= jlim then
    jlim := AdvanceDyn(j, curdynnb, currentdyn);

  while c <> #0 do
  begin
    { go to beginning of next word }
    reloop: endoflastwordpos := xpos;
    stopoflastword := j;
    afterwordspaces := 0;

    while True do
    begin
      case c of
        ' ':
          begin
            if scolwrap then
              Inc(xpos)
            else
              Inc(xpos, RunningSpaceWidth);
            Inc(afterwordspaces)
          end;

        #9:
          with smemo do
          begin
            if TabStops > 0 then
            begin
              if scolwrap then
                xpos := ((xpos div TabStops) + 1) * TabStops
              else
                xpos := ((xpos div (TabStops * SpaceWidth)) + 1) * TabStops * SpaceWidth;

            end else if (not scolwrap) and (TabStops < 0) then
              xpos := (xpos div (-TabStops) + 1) * (-TabStops);
            spacescounted := 0;
            stopoflastword := j;
            afterwordspaces := 0;
            juststart := j;
          end;

        ctrlBold, ctrlItalic, ctrlUnderline, ctrlHighlight, ctrlAltFont:
          if not smemo.IParList.StaticFormat then
            Break
          else
          begin
            XORStyleCode(currentattr, c);
            sstyle := cstyle;
            cstyle := smemo.AttrToExtFontStyles(currentattr, currentdyn.DynStyle);
            if TPlusFontStyles(cstyle) - [TPlusFontStyle(fsHighlight)] <>
              TPlusFontStyles(sstyle) - [TPlusFontStyle(fsHighlight)] then
              SetDC(cstyle, False)
          end else
            Break { found start of word }
      end;

      Inc(j);
      c := t[j];
      if j >= jlim then
        jlim := AdvanceDyn(j, curdynnb, currentdyn)
    end;

    Inc(spacescounted, afterwordspaces);

    { possibly wrap the beginning spaces to the end of previous line }
    if (curline > 0) and (stopoflastword = linestart) and (j > stopoflastword) then
    begin
      if curline = FirstLine then
        pline := fssk1.NavLines.LinePointers[curline - 1]
      else
        pline := @stmplines[curline - FirstLine - 1];
      linestartattr := currentattr;
      linestartdyn := currentdyn;
      with pline^ do
      begin
        Stop := j;
        Inc(TotalWidth, xpos)
      end;
      linestart := j;
      xpos := 0;
      juststart := j;
      spacescounted := 0;
      afterwordspaces := 0;
      linebeforetouched := True
    end;

    startwordpos := xpos;
    startword := j;
    wordstartattr := currentattr;
    wordstartdyn := currentdyn;
    wordstartdynnb := curdynnb;
    wi := 0;
    nextcar := j;

    { go to end of word }
    spc := High(spc);
    while not((c <= ' ') and (AnsiChar(c) in [#0, ' ', #9])) and (spc <> swwchar) and
      not(susewwset and (pmStrScan(PChar(swwchars), spc) <> nil)) do
    begin
      spc := c;
      if (c <= #26) and smemo.IParList.StaticFormat and (AnsiChar(c) in CtrlCodesSet) then
      begin
        if j > nextcar then
        begin
          if  scolwrap then
            SizeInfo.cx := j - nextcar
          else
            sizeinfo.cx := GetTextWidth(sdc, t + nextcar, j - nextcar, smemo.MaxOneShotChars);
          wi := wi + sizeinfo.cX
        end;
        sstyle := cstyle;
        repeat
          XORStyleCode(currentattr, c);
          Inc(j);
          c := t[j]
        until (c > #26) or (not(AnsiChar(c) in CtrlCodesSet));
        nextcar := j;

        if j >= jlim then
          jlim := AdvanceDyn(j, curdynnb, currentdyn)
        else
        begin
          cstyle := smemo.AttrToExtFontStyles(currentattr, currentdyn.DynStyle);
          if TPlusFontStyles(cstyle) - [TPlusFontStyle(fsHighlight)] <>
            TPlusFontStyles(sstyle) - [TPlusFontStyle(fsHighlight)] then
            SetDC(cstyle, False)
        end
      end { if c in CtrlCodesSet }

      else
      begin
        Inc(j);
        c := t[j];
        if j >= jlim then
        begin
          if j > nextcar then
          begin
            if scolwrap then
              SizeInfo.cx := j - nextcar
            else
              sizeinfo.cx := GetTextWidth(sdc, t + nextcar, j - nextcar, smemo.MaxOneShotChars);
            wi := wi + sizeinfo.cX;
            nextcar := j
          end;
          jlim := AdvanceDyn(j, curdynnb, currentdyn);
        end
      end { not c in CtrlCodesSet }
    end;
    { while not end of word }

    if j > nextcar then
      if scolwrap then
        wi := j - nextcar
      else
      begin
        sizeinfo.cX := GetTextWidth(sdc, t + nextcar, j - nextcar, smemo.MaxOneShotChars);
        wi := wi + SizeInfo.cX - SpaceKern
      end;
    xpos := xpos + wi;

    { if this is the first word of the first line we format, check if it should be moved to previous line }
    if (curline > 0) and (curline = FirstLine) and (startword = linestart) and (j > startword) then
    begin
      pline := fssk1.fNavLines.LinePointers[curline - 1];
      if pline^.TotalWidth + wi <= w then
      begin
        { move this word on the previous line }
        linebeforetouched := True;
        for sj := pline.Stop - 1 downto pline.Start do
          if t[sj] = ' ' then
            Inc(pline.Spaces)
          else
            Break;
        pline.Stop := j;
        Inc(pline.TotalWidth, wi);
        pline.LineWidth := pline.TotalWidth;

        linestart := j;
        linestartattr := cstyle;
        linestartdyn := currentdyn;
        xpos := 0;
        juststart := j;
        spacescounted := 0;
        goto reloop
      end
    end;

    //if (scolwrap and (j-linestart > w)) or (not scolwrap and ((xpos > w) and (startword < plen))) then
    if (xpos > w) and (startword < plen) then
    begin
      // the last word does not fit on this line
      with newline do
      begin
        Start := linestart;
        StartAttrib := linestartattr;
        LineWidth := endoflastwordpos;
        TotalWidth := startwordpos;
        StartDynNb := linestartdynnb;
        while (StartDynNb > 0) and (Par^.ParExtra.DynCodes[StartDynNb - 1].DynOffset = linestart) do
          Dec(StartDynNb);

        if startword > linestart then
        begin
          { wrap last word to next line }
          xpos := wi;
          Stop := startword;
          Spaces := spacescounted - afterwordspaces;
          JustifyStart := juststart;
          linestart := startword;
          linestartattr := wordstartattr;
          linestartdyn := wordstartdyn;
          linestartdynnb := wordstartdynnb;
          if (scolwrap and (j - linestart > w)) or (not scolwrap and (xpos > w)) then
          begin
            { restart the next line with the start of the last word }
            j := startword;
            currentattr := wordstartattr;
            currentdyn := wordstartdyn;
            curdynnb := wordstartdynnb;
            if curdynnb < dcount then
              jlim := Par^.ParExtra.DynCodes[curdynnb].DynOffset
            else
              jlim := High(jlim);
            sstyle := smemo.AttrToExtFontStyles(currentattr, currentdyn.DynStyle);
            if TPlusFontStyles(cstyle) - [TPlusFontStyle(fsHighlight)] <>
              TPlusFontStyles(sstyle) - [TPlusFontStyle(fsHighlight)] then
              SetDC(sstyle, False);
            cstyle := sstyle;
            xpos := 0;
            c := t[j]
          end;
        end else
        begin
          { this word does not fit on a line, so break it }
          j := startword;
          c := t[j];
          currentattr := wordstartattr;
          currentdyn := wordstartdyn;
          curdynnb := wordstartdynnb;
          wi := 0;
          sstyle := smemo.AttrToExtFontStyles(currentattr, currentdyn.DynStyle);
          if TPlusFontStyles(cstyle) - [TPlusFontStyle(fsHighlight)] <>
            TPlusFontStyles(sstyle) - [TPlusFontStyle(fsHighlight)] then
            SetDC(sstyle, False);
          cstyle := sstyle;

          while (c <> #0) and (wi <= w) do
          begin
            if (c > #26) or (not(smemo.StaticFormat and (AnsiChar(c) in CtrlCodesSet)) and (c <> #9)) then
            begin
              if scolwrap then
                SizeInfo.cx := 1
              else
                SizeInfo.cx := GetTextWidth(sdc, t + j, 1, smemo.MaxOneShotChars);
              wi := wi + SizeInfo.cX;
              Inc(j);
              c := t[j];
              if j >= jlim then
                jlim := AdvanceDyn(j, curdynnb, currentdyn);
            end else
            begin
              SizeInfo.cX := 0;
              sstyle := cstyle;
              while c < #26 do
              begin
                case AnsiChar(c) of
                  #0: Break;
                  #9: with smemo do
                    if TabStops > 0 then
                      if scolwrap then
                        wi := ((wi div TabStops) + 1) * TabStops
                      else
                        wi := ((wi div (TabStops * SpaceWidth)) + 1) * TabStops * SpaceWidth
                    else if (TabStops < 0) and (not scolwrap) then
                      wi := (wi div (-TabStops) + 1) * (-TabStops);
                  ctrlItalic, ctrlBold, ctrlHighlight, ctrlAltFont, ctrlUnderline:
                    if smemo.StaticFormat then
                      XORStyleCode(currentattr, c);
                end;
                if j >= jlim then
                  jlim := AdvanceDyn(j, curdynnb, currentdyn);
                Inc(j);
                c := t[j]
              end;
              cstyle := smemo.AttrToExtFontStyles(currentattr, currentdyn.DynStyle);

              if TPlusFontStyles(cstyle) - [TPlusFontStyle(fsHighlight)] <>
                TPlusFontStyles(sstyle) - [TPlusFontStyle(fsHighlight)] then
                SetDC(cstyle, False)
            end
          end;

          if (j > startword + 1) and (not(smemo.StaticFormat and (c < #26) and (AnsiChar(c) in CtrlCodesSet))) and
            (not((curdynnb > 0) and (Par^.ParExtra.DynCodes[curdynnb - 1].DynOffset >= j))) then
          begin
            Dec(j);
            Dec(wi, SizeInfo.cX);
            c := t[j]
          end;
          Stop := j;
          linestart := j;
          Spaces := 0;
          JustifyStart := Stop;
          linestartattr := currentattr;
          linestartdyn := currentdyn;
          linestartdynnb := curdynnb;
          LineWidth := wi;
          TotalWidth := LineWidth;
          xpos := 0;
        end;
        // word does not fit

        spacescounted := 0;
        juststart := linestart;
        if LineWidth > smemo.fMaxLineWidth then
        begin
          smemo.fMaxLineWidth := LineWidth;
          if (not smemo.WordWrap) or (smemo.ColumnWrap > 0) then
            smemo.fMaxLineNumber := Par^.StartLine
        end
      end;
      { with newline }

      SetLength(stmpLines, Length(stmplines) + 1);
      stmpLines[High(stmplines)] := newline;
      Inc(curline);
      if not CompleteReformat then
      begin
        while (lastchanged < olinecount) and
          (fssk1.fNavLines.LinePointers[lastchanged]^.Stop < newline.Stop) do
          Inc(lastchanged);
        if (lastchanged < olinecount - 1) and
          (fssk1.fNavLines.LinePointers[lastchanged]^.Stop = newline.Stop) and
          (fssk1.fNavLines.LinePointers[lastchanged + 1]^.StartAttrib = currentattr) then
          Break { exit j loop }
      end

    end { if xpos > w }

  end;
  { while c<>#0 }

  { add the last line }
  if (c = #0) and ((j > linestart) or ((Length(stmplines) = 0) and (FirstLine = 0))) then
  begin
    with newline do
    begin
      Stop := j;
      Start := linestart;
      StartAttrib := linestartattr;
      StartDynNb := linestartdynnb;
      while (StartDynNb > 0) and (Par^.ParExtra.DynCodes[StartDynNb - 1].DynOffset = linestart) do
        Dec(StartDynNb);
      if c = ' ' then
        LineWidth := endoflastwordpos
      else
        LineWidth := xpos;
      TotalWidth := xpos;
      Spaces := 0;
      JustifyStart := j;
      if LineWidth > smemo.fMaxLineWidth then
      begin
        smemo.fMaxLineWidth := LineWidth;
        if (not smemo.WordWrap) or (smemo.ColumnWrap > 0) then
          smemo.fMaxLineNumber := Par^.StartLine
      end
    end;
    SetLength(stmplines, Length(stmplines) + 1);
    stmplines[High(stmplines)] := newline
  end;

  { replace old lines with new lines }
  newlinecount := Length(stmplines);
  if c = #0 then
    lastchanged := olinecount - 1;
  lOffset := newlinecount - (lastchanged - FirstLine + 1);
  if (not(pmpHasExtra in Par^.ParState)) and (newlinecount = 1) then
    Par^.LineWidth := stmplines[0].LineWidth
  else
  begin
    SetParExtras(Par^);
    if lOffset > 0 then
    begin
      fssk1.fNavLines.Count := olinecount + lOffset;
      for k := olinecount - 1 downto lastchanged + 1 do
        fssk1.fNavLines[k + lOffset] := fssk1.fNavLines[k]
    end;
    if lOffset < 0 then
    begin
      for k := lastchanged + lOffset + 1 to olinecount - 1 + lOffset do
        fssk1.fNavLines[k] := fssk1.fNavLines[k - lOffset];
      fssk1.fNavLines.Count := olinecount + lOffset
    end;
    for k := 0 to newlinecount - 1 do
      fssk1.fNavLines[FirstLine + k] := stmpLines[k]
  end;

  Inc(lastchanged, lOffset);
  LinesChange := loffset;
  LinesCount := olinecount + loffset;

  if linebeforetouched then
    Dec(FirstLine);
  fssk1.fPMemo := nil;
  fssk2.fPMemo := nil
end;

procedure SetDynStyleP(PList: TParagraphsList; Start, Stop: TPlusNavigator; dinfo: DynInfoRec;
  AddDInfo, ExtendModFields: Boolean);
var startpar, stoppar: LongInt;
  i: LongInt;
  d: TPlusNavigator;
  stopdyninfo: DynInfoRec;
  stoppos, lim: LongInt;
  currentpar: pParInfo;
  rundyn: pDynInfoRec;
begin
  if Start.Pos > Stop.Pos then
  begin
    d := Stop;
    Stop := Start;
    Start := d end;
  startpar := Start.ParNumber;
  stoppar := Stop.ParNumber;

  if ExtendModFields then
    PList.ExtendMods(startpar, Start.ParLine, stoppar);

  stoppos := Stop.Pos;

  stopdyninfo := Start.DynAttr;
  dinfo.CollpsLevel := DynToCollapseLevel(stopdyninfo);
  if AddDInfo then
    dinfo.DynStyle := dinfo.DynStyle or $80
  else
    dinfo.DynStyle := 0;
  if (dinfo.DynStyle and $80 <> 0) and (pmdCollapsible in dinfo.CollpsState) then
    Inc(dinfo.CollpsLevel);
  Exclude(dinfo.CollpsState, pmdCollapsed);

  if AddDInfo or (stopdyninfo.DynStyle and $80 <> 0) then
    Start.AddDyn(dinfo);

  Stop.Assign(Start);
  currentpar := Start.fPar;
  rundyn := nil;

  for i := startpar to stoppar do
  begin
    if i > startpar then
      currentpar := PList.Pointers[i];
    with currentpar^ do
    begin
      Exclude(ParState, pmpFormatted);
      if i <> startpar then
        with Stop do
        begin
          Stop.fParNb := i;
          Stop.fPar := currentpar;
          Stop.fPos := StartOffset;
          Stop.fDynNb := 0;
          Stop.fOffset := 0;
          Stop.fParLine := -1
        end;

      if i = stoppar then
        lim := stoppos
      else
        lim := StartOffset + GetParLength(currentpar^);

      while Stop.ForwardToDyn(lim) do
      begin
        stopdynInfo := ParExtra.DynCodes[Stop.fDynNb];
        Stop.RemoveDyn
      end;

      if i <> startpar then
      begin
        if (rundyn = nil) and (dinfo.DynStyle and $80 <> 0) then
        begin
          New(rundyn);
          rundyn^ := dinfo;
          rundyn.DynOffset := 0
        end;
        SetStartDynAttrib(currentpar^, rundyn, False);
      end { i<>startpar }
    end { with currentpar^ }
  end;
  { i loop over paragraphs }

  dinfo.DynStyle := dinfo.DynStyle and $7F;
  stopdyninfo.StartKlen := pmMaxOf(0, stopdyninfo.StartKLen - (stoppos - Stop.Pos));
  Stop.Pos := stoppos;
  if (stoppos < TPlusMemo(Stop.fPMemo).CharCount) and (AddDInfo or (stopdyninfo.DynStyle and $80 <> 0)) then
    Stop.AddDyn(stopdyninfo);
end; { procedure SetDynStyleP }

{ TpmFormatThread }

constructor TpmFormatThread.Create(AMemo: TObject);
begin
  fFormatEvent := TEvent.Create(nil, False, False, '');
  fMemo := AMemo;
  inherited Create(False);
  Priority := tpIdle;
end;

destructor TpmFormatThread.Destroy;
begin
  {$IFDEF PMDEBUG} OutputDebugString('Destroying formatting thread');
{$ENDIF}
  fFormatEvent.Free;
  inherited
end;

procedure TpmFormatThread.Execute;
var waitresult: TWaitResult;
begin
  repeat
    waitresult := fFormatEvent.WaitFor(High(Cardinal));
    if (waitresult = wrSignaled) and (not Terminated) then
      Synchronize(UpdateChunck);
  until Terminated or (waitresult <> wrSignaled)
end;

procedure TpmFormatThread.PutToEnd(Final: Boolean = False);
begin
  {$IFDEF PMDEBUG} OutputDebugString('Terminating formatting thread');
{$ENDIF}
  fMemo := nil;
  Final := Final or Application.Terminated;
  if not Final then
    FreeOnTerminate := True;
  Terminate;
  fFormatEvent.SetEvent;
  if Final then
  begin
    WaitFor;
    Free
  end
end;

procedure TpmFormatThread.UpdateChunck;
begin
  //if not Application.Terminated then Application.ProcessMessages; commented out v6.5c
  if Assigned(fMemo) and TPlusMemo(fMemo).HandleAllocated then
    TPlusMemo(fMemo).Perform(pm_UpdateBkg, 0, 0)
end;

initialization
  GroupDescendentsWith(TPlusHighlighter, TControl);
  GroupDescendentsWith(TpmsCollapseHandler, TControl);

finalization
  if tmpnav1 <> nil then
  begin
    tmpnav1.Free;
    tmpnav2.Free;
    tmpnav3.Free;
    fssk1.Free;
    fssk2.Free
  end;
end.


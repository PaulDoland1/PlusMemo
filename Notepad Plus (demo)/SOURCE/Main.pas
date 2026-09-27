unit Main;

interface

uses
  WinTypes, WinProcs, SysUtils, Messages, Classes, Graphics, Controls,
  Plusmemo, URLHighlight, Dialogs, Menus, StdCtrls, ExtCtrls, Buttons,
  PlusGutter, Forms, ExtHilit, OOPHilit, pmprint, HtmlHighlight, ExtDlgs,
  PlusToFormat, ComCtrls, SQLHilit, CPPHilit, pmCollapseHandler, PMSupport;

type
  TFrmMain = class(TForm)
    MainMenu1: TMainMenu;
    Cut1: TMenuItem;
    Copy1: TMenuItem;
    Paste1: TMenuItem;
    Save1: TMenuItem;
    PanToolbar: TPanel;
    SpeedBtnUnderline: TSpeedButton;
    SpeedBtnItalic: TSpeedButton;
    SpeedBtnBold: TSpeedButton;
    SpeedBtnPaste: TSpeedButton;
    SpeedBtnCopy: TSpeedButton;
    SpeedBtnCut: TSpeedButton;
    SpeedBtnPrint: TSpeedButton;
    SpeedBtnSearch: TSpeedButton;
    SpeedBtnSave: TSpeedButton;
    SpeedBtnOpen: TSpeedButton;
    Edit1: TMenuItem;
    File1: TMenuItem;
    New1: TMenuItem;
    Open1: TMenuItem;
    SaveAs1: TMenuItem;
    N1: TMenuItem;
    Exit1: TMenuItem;
    OpenDialog1: TOpenDialog;
    SaveDialog2: TSaveDialog;
    N2: TMenuItem;
    SelectAll1: TMenuItem;
    Help1: TMenuItem;
    AboutNotepadPlus1: TMenuItem;
    Setup1: TMenuItem;
    Font1: TMenuItem;
    FontDialog1: TFontDialog;
    BackgroundColor1: TMenuItem;
    HighlightText1: TMenuItem;
    ColorDialog1: TColorDialog;
    HighlightBackgroundColor1: TMenuItem;
    SpeedBtnHighlight: TSpeedButton;
    N3: TMenuItem;
    N4: TMenuItem;
    Statusbar1: TMenuItem;
    N5: TMenuItem;
    TextFormat1: TMenuItem;
    SpeedBtnAltFont: TSpeedButton;
    AlternateFont1: TMenuItem;
    N6: TMenuItem;
    Print1: TMenuItem;
    CaretWidth1: TMenuItem;
    N7: TMenuItem;
    Undo1: TMenuItem;
    N8: TMenuItem;
    BtnUndo: TSpeedButton;
    PlusMemo1: TPlusMemo;
    Syntax1: TMenuItem;
    CustomKeywords1: TMenuItem;
    CustomStartstopkeys1: TMenuItem;
    Customdelimiters1: TMenuItem;
    Insert1: TMenuItem;
    Overwrite1: TMenuItem;
    N10: TMenuItem;
    BtnCodeEditor: TSpeedButton;
    BtnTextEditor: TSpeedButton;
    DisplayIntroonStartup1: TMenuItem;
    N11: TMenuItem;
    Redo1: TMenuItem;
    BtnRedo: TSpeedButton;
    AutoIndent1: TMenuItem;
    BackIndent1: TMenuItem;
    URLHighlighter1: TURLHighlighter;
    PlusGutter1: TPlusGutter;
    Gutter1: TMenuItem;
    OOPHighlighter1: TOOPHighlighter;
    PlusMemoPrinter1: TPlusMemoPrinter;
    BtnPrintPreview: TSpeedButton;
    MnuPrintPreview1: TMenuItem;
    HtmlHighlighter1: THtmlHighlighter;
    LblBreak: TLabel;
    Toolbar1: TMenuItem;
    rgBackground: TRadioGroup;
    BtnCustomPic: TSpeedButton;
    OpenPictureDialog1: TOpenPictureDialog;
    ReplaceDialog1: TReplaceDialog;
    N15: TMenuItem;
    FindReplace1: TMenuItem;
    FindReplacenext1: TMenuItem;
    PlusToRTF1: TPlusToRTF;
    PlusToHTML1: TPlusToHTML;
    GenerateHtmlfile1: TMenuItem;
    GenerateRtffile1: TMenuItem;
    N14: TMenuItem;
    sbStatus: TStatusBar;
    btnSmoothScroll: TSpeedButton;
    CPPHighlighter1: TCPPHighlighter;
    SQLHighlighter1: TSQLHighlighter;
    rgSyntax: TRadioGroup;
    cbInternetUrls: TCheckBox;
    BtnCenter: TSpeedButton;
    BtnLeft: TSpeedButton;
    BtnRight: TSpeedButton;
    BtnJustified: TSpeedButton;
    BtnWordWrap: TSpeedButton;
    mnuSmartTabs: TMenuItem;
    btnNonPrintChars: TSpeedButton;
    pmCollapseHandler1: TpmCollapseHandler;
    btnCollapseAll: TSpeedButton;
    btnExpandAll: TSpeedButton;
    FileSaveDialog1: TFileSaveDialog;
    SaveDialog1: TSaveTextFileDialog;
    procedure FormCreate(Sender: TObject);
    procedure Cut1Click(Sender: TObject);
    procedure Paste1Click(Sender: TObject);
    procedure Copy1Click(Sender: TObject);
    procedure Save1Click(Sender: TObject);
    procedure New1Click(Sender: TObject);
    procedure Open1Click(Sender: TObject);
    procedure SpeedBtnBoldClick(Sender: TObject);
    procedure SpeedBtnItalicClick(Sender: TObject);
    procedure SpeedBtnUnderlineClick(Sender: TObject);
    procedure SaveAs1Click(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure SelectAll1Click(Sender: TObject);
    procedure Font1Click(Sender: TObject);
    procedure BackgroundColor1Click(Sender: TObject);
    procedure HighlightText1Click(Sender: TObject);
    procedure HighlightBackgroundColor1Click(Sender: TObject);
    procedure SpeedBtnHighlightClick(Sender: TObject);
    procedure PlusMemo1Progress(Sender: TObject);
    procedure PlusMemo1StyleChange(Sender: TObject);
    procedure PlusMemo1SelMove(Sender: TObject);
    procedure AboutNotepadPlus1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Toolbar1Click(Sender: TObject);
    procedure Statusbar1Click(Sender: TObject);
    procedure TextFormat1Click(Sender: TObject);
    procedure SpeedBtnAltFontClick(Sender: TObject);
    procedure AlternateFont1Click(Sender: TObject);
    procedure CaretWidth1Click(Sender: TObject);
    procedure Undo1Click(Sender: TObject);
    procedure Edit1Click(Sender: TObject);
    procedure CustomKeywordsClick(Sender: TObject);
    procedure CustomStartstopkeys1Click(Sender: TObject);
    procedure LblOverwriteClick(Sender: TObject);
    procedure Insert1Click(Sender: TObject);
    procedure Overwrite1Click(Sender: TObject);
    procedure LblUpdateClick(Sender: TObject);
    procedure BtnCodeEditorClick(Sender: TObject);
    procedure BtnTextEditorClick(Sender: TObject);
    procedure DisplayIntroonStartup1Click(Sender: TObject);
    procedure Redo1Click(Sender: TObject);
    procedure PlusMemo1Change(Sender: TObject);
    procedure PlusMemo1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure AutoIndent1Click(Sender: TObject);
    procedure BackIndent1Click(Sender: TObject);
    procedure Gutter1Click(Sender: TObject);
    procedure Customdelimiters1Click(Sender: TObject);
    procedure LblSelModeClick(Sender: TObject);
    procedure BtnPrintPreviewClick(Sender: TObject);
    procedure SpeedBtnPrintClick(Sender: TObject);
    procedure LblBreakClick(Sender: TObject);
    procedure rgBackgroundClick(Sender: TObject);
    procedure BtnCustomPicClick(Sender: TObject);
    procedure FindReplace1Click(Sender: TObject);
    procedure ReplaceDialog1Find(Sender: TObject);
    procedure ReplaceDialog1Replace(Sender: TObject);
    procedure FindReplacenext1Click(Sender: TObject);
    procedure GenerateHtmlfile1Click(Sender: TObject);
    procedure GenerateRtffile1Click(Sender: TObject);
    procedure btnSmoothScrollClick(Sender: TObject);
    procedure sbStatusClick(Sender: TObject);
    procedure sbStatusMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure rgSyntaxClick(Sender: TObject);
    procedure BtnParAlignClick(Sender: TObject);
    procedure BtnWordWrapClick(Sender: TObject);
    procedure BtnJustifiedClick(Sender: TObject);
    procedure mnuSmartTabsClick(Sender: TObject);
    procedure btnNonPrintCharsClick(Sender: TObject);
    procedure PlusGutter1DblClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure btnCollapseAllClick(Sender: TObject);
    procedure btnExpandAllClick(Sender: TObject);
 private
    fEditFile: string;
    fSavedECMBmp: TBitmap;   { to keep a reference to the ECM background bitmap }
    fCustomBmp  : TBitmap;   { to contain a custom, user selected background bitmap }
    fMouseStatus: Integer;   { the panel index pointed to by the mouse when it is over the status bar }
    fSomeCollapsibleBlocks: Boolean;  { set to True when defining collapsible blocks for Ini files }
    fLoadingContent, fSavingContent: Boolean;  { Set to True when loading a file or saving a file, used in the OnProgress event handler }
    procedure setEditFile(const name: string);
    procedure ParseIniFile;  { apply collapsible blocks to sections in an ini file }
    procedure CleanupCollapsibleBlocks;  { remove collapsible blocks when changing highlighting from ini file to other }
 public
    AppPath, TextEditorFont, TextEditorSeparators: string;
    CustomBmpFile  : string;

    property EditFile: string read fEditFile write setEditFile;

    procedure LoadFile(const fname: string);  { loads a file and set PlusMemo1 properties
                                                according to the type of file }

    function LanguageFromExtension(const Ext: string; var SourceCode, TxtFile: Boolean): string;
      { Returns the language name (ex: None, Delphi, C++, ... that is normally applied for
        files having extension Ext.  It also sets SourceCode to True if such file is a source code file,
        or TxtFile if this is a plain text file.
        Parameter Ext must be uppercased }
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.DFM}
uses About, Clipbrd, IniFiles, Printers, PlusKeys, ShellAPI, ShlObj;

const MainSection = 'Window';  { Various sections of notepadp.ini }
      ViewSection = 'View';
      FontSection = 'Font';
      ColorsSection='Colors';
      EditionSection='Edition';
      SetupSection  ='Setup';

      sbcProgress = 0;    { panel indexes for status bar elements }
      sbcPosition = 0;
      sbcParagraph = 1;
      sbcLine = 2;
      sbcCol  = 3;
      sbcInsert = 5;
      sbcUpdate = 7;
      sbcSelection = 8;

function ShGetFolderPath(hWndOwner: HWnd; csidl: Integer; hToken: THandle; dwReserved: DWord; lpszPath: PChar): HResult; stdcall;
         external 'ShFolder.dll' name 'SHGetFolderPathW';

function GetAppDataPath: string;
var DataPath: array[0..MAX_PATH] of Char; success: Boolean;
begin
  success:= ShGetFolderPath(0, CSIDL_APPDATA or $8000{CSIDL_FLAG_CREATE}, 0, {SHGFP_TYPE_CURRENT} 0, DataPath) = S_OK;
  if success then Result:= DataPath
             else Result:= ExtractFilePath(ParamStr(0));
end;

procedure TFrmMain.FormCreate(Sender: TObject);
var
  Inif : TCustomIniFile;
  DisplayIntroCode: Integer;
  CustomStream: TFileStream;
  CustomReader: TReader;
begin
  AppPath:= GetAppDataPath;

  { keep a reference to the background loaded with the project, in order to restore it at user will }
  fSavedECMBmp:= TBitmap.Create;
  fSavedECMBmp.Assign(PlusMemo1.BackgroundBmp.Bitmap);

  { create a bitmap to hold the user selected one (custom) }
  fCustomBmp:= TBitmap.Create;

  Inif:= TMemIniFile.Create(AppPath + 'notepadp.ini');   // note: a TMemIniFile is believed to be more efficient than TIniFile

  { load general settings }
  Width:= Inif.ReadInteger(MainSection, 'Width', Width);
  Height:= Inif.ReadInteger(MainSection, 'Height', Height);
  Top:= Inif.ReadInteger(MainSection, 'Top', (Screen.Height-Height) div 2);
  Left:= Inif.ReadInteger(MainSection, 'Left', (Screen.Width - Width) div 2);
  WindowState:= TWindowState(Inif.ReadInteger(MainSection, 'State', ord(wsNormal)));

  PanToolbar.Visible:= Inif.ReadBool(ViewSection, 'ToolBar', True);
  sbStatus.Visible:=  Inif.ReadBool(ViewSection, 'Status', True);
  PlusGutter1.Visible:= Inif.ReadBool(ViewSection, 'Gutter', True);
  CustomBmpFile:= Inif.ReadString(ViewSection, 'CustomBmp', '');
  rgBackground.ItemIndex:= Inif.ReadInteger(ViewSection, 'BackgroundPic', 1);

  DisplayIntroCode:= Inif.ReadInteger(ViewSection, 'Intro', -1);
  if ParamCount=0 then
    begin
      EditFile:='';
      if DisplayIntroCode=0 then PlusMemo1.Clear
      else
        if DisplayIntroCode>0 then DisplayIntroOnStartup1.Checked:= True;
      PlusMemo1.Modified:= False;
      SpeedBtnSave.Enabled:= False
    end;

  Toolbar1.Checked:= PanToolbar.Visible;
  Statusbar1.Checked:= sbStatus.Visible;
  PlusMemo1.Separators:= Inif.ReadString(MainSection, 'Custom delimiters', '.,;:[]{}()/')+' '#9;
  TextEditorSeparators:= PlusMemo1.Separators;


  { here is how to read keywords and start-stop keys from a stream!! }
  CustomStream:= nil;
  try
    CustomStream:= TFileStream.Create(AppPath+'CustKeys.bin', fmOpenRead);
    CustomReader:= TReader.Create(CustomStream, 1024);
    PlusMemo1.Keywords.ReadData(CustomReader);
    PlusMemo1.StartStopKeys.ReadData(CustomReader);
    CustomReader.Free;
  except  // ignore failed attempts at reading custon keywords and start-stop keys
    end;
  CustomStream.Free;

  { read from ini file which syntax highlighting to apply }
  cbInternetUrls.Checked:= Inif.ReadBool(MainSection, 'Urls', True);
  if DisplayIntroCode=-1 then // don't apply language highlighting with intro text
      rgSyntax.ItemIndex:= 0
  else
    try
      rgSyntax.ItemIndex:= rgSyntax.Items.IndexOf(Inif.ReadString(MainSection, 'Syntax', 'None'))
    except
      rgSyntax.ItemIndex:= 0
    end;

  { load PlusMemo settings }
  TextEditorFont:= Inif.ReadString(FontSection, 'Type', 'Arial');
  if DisplayIntroCode<>-1 then  { -1 is a flag for not having found notepadp.ini }
    with PlusMemo1 do
      begin
        Font.Name:= TextEditorFont;
        Font.Style:= [];

        Font.Size:= Inif.ReadInteger(FontSection, 'Size', Font.Size);
        Font.Color:= Inif.ReadInteger(FontSection, 'Color', Font.Color);
        AltFont.Name:= Inif.ReadString(FontSection, 'AlternateType', AltFont.Name);
        AltFont.Size:= Inif.ReadInteger(FontSection, 'AlternateSize', AltFont.Size);
        SpeedBtnAltFont.Font.Name:= PlusMemo1.AltFont.Name;

        Color:=  Inif.ReadInteger(ColorsSection, 'Background', clWindow);
        HighlightColor:= Inif.ReadInteger(ColorsSection, 'Highlight text', HighlightColor);
        HighlightBackgnd:= Inif.ReadInteger(ColorsSection, 'Highlight backgrnd', HighlightBackgnd);

        EnableHotKeys:= Inif.ReadBool(EditionSection, 'Text formatting', EnableHotKeys);
        TextFormat1.Checked:= EnableHotKeys;

        CaretWidth:= Inif.ReadInteger(SetupSection, 'Caret width', CaretWidth);

        case TAlignment(Inif.ReadInteger(SetupSection, 'Alignment', ord(taLeftJustify))) of
            taLeftJustify  : btnLeft.Down:= True;
            taRightJustify : btnRight.Down:= True;
            taCenter       : btnCenter.Down:= True
          end;

        btnWordWrap.Down:= Inif.ReadBool(SetupSection, 'Word wrap', WordWrap);
        btnWordWrapClick(Self);  // apply the setting

        Justified:= Inif.ReadBool(SetupSection, 'Justified', Justified);
        btnJustified.Down:= Justified;

        ScrollTime:= Inif.ReadInteger(SetupSection, 'ScrollTime', 0);
        if ScrollTime<>0 then btnSmoothScroll.Down:= True
      end;  { with PlusMemo1 }

  Inif.Free;

  if ParamCount>0 then LoadFile(ParamStr(1))
                  else PlusMemo1SelMove(Self)   // update status bar
end;    { FormCreate }

procedure TFrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
  procedure TrimCar(var s: string; Car: Char);
    var cpos: Integer;
    begin
      repeat
        cpos:= Pos(Car, s);
        if cpos>0 then Delete(s, cpos, 1)
      until cpos<=0
    end;

var
  Inif        : TCustomIniFile;
  fsint       : Byte;
  CustomStream: TFileStream;
  CustomWriter: TWriter;
begin
  Inif:= TMemIniFile.Create(AppPath+'notepadp.ini');

  { save general settings }
  Inif.WriteInteger(MainSection, 'Width', Width);
  Inif.WriteInteger(MainSection, 'Height', Height);
  Inif.WriteInteger(MainSection, 'Top', Top);
  Inif.WriteInteger(MainSection, 'Left', Left);
  Inif.WriteInteger(MainSection, 'State', ord(WindowState));

  Inif.WriteBool(ViewSection, 'ToolBar', PanToolbar.Visible);
  Inif.WriteBool(ViewSection, 'Status', sbStatus.Visible);
  Inif.WriteInteger(ViewSection, 'Intro', Ord(DisplayIntroOnStartup1.Checked));
  Inif.WriteBool(ViewSection, 'Gutter', PlusGutter1.Visible);
  Inif.WriteString(ViewSection, 'CustomBmp', CustomBmpFile);
  Inif.WriteInteger(ViewSection, 'BackgroundPic', rgBackground.ItemIndex);

  if rgSyntax.ItemIndex>=0 then
      Inif.WriteString(MainSection, 'Syntax', rgSyntax.Items[rgSyntax.ItemIndex]);

  Inif.WriteBool(MainSection, 'Urls', cbInternetUrls.Checked);
  TrimCar(TextEditorSeparators, #13);
  TrimCar(TextEditorSeparators, #10);
  TrimCar(TextEditorSeparators, #9);
  TrimCar(TextEditorSeparators, ' ');
  Inif.WriteString(MainSection, 'Custom delimiters', TextEditorSeparators);

  { here is how to save keywords and start-stopkeys in a stream!! }
  CustomStream:= TFileStream.Create(AppPath+'CustKeys.bin', fmCreate);
  CustomWriter:= TWriter.Create(CustomStream, 1024);
  PlusMemo1.Keywords.WriteData(CustomWriter);
  PlusMemo1.StartStopKeys.WriteData(CustomWriter);
  CustomWriter.Free;
  CustomStream.Free;

  { save PlusMemo settings }
  with PlusMemo1 do
    begin
      Inif.WriteString(FontSection, 'Type', TextEditorFont);
      Inif.WriteInteger(FontSection, 'Size', Font.Size);
      fsint:= 0;
      TFontStyles(fsint):= Font.Style;
      Inif.WriteInteger(FontSection, 'Style', fsint);
      Inif.WriteInteger(FontSection, 'Color', Font.Color);
      Inif.WriteString(FontSection, 'AlternateType', AltFont.Name);
      Inif.WriteInteger(FontSection, 'AlternateSize', AltFont.Size);

      Inif.WriteInteger(ColorsSection, 'Background', Color);
      Inif.WriteInteger(ColorsSection, 'Highlight text', HighlightColor);
      Inif.WriteInteger(ColorsSection, 'Highlight backgrnd', HighlightBackgnd);
      Inif.WriteBool(EditionSection, 'Text formatting', EnableHotKeys);
      Inif.WriteBool(SetupSection, 'Word wrap', WordWrap);
      Inif.WriteInteger(SetupSection, 'Caret width', CaretWidth);
      Inif.WriteInteger(SetupSection, 'Alignment', ord(Alignment));
      Inif.WriteBool(SetupSection, 'Justified', Justified);
      Inif.WriteInteger(SetupSection, 'ScrollTime', ScrollTime)
    end;  { with PlusMemo1 }

  Inif.UpdateFile;
  Inif.Free;

  fSavedECMBmp.Free;
  fCustomBmp.Free
end;  { FormClose }

procedure TFrmMain.setEditFile(const Name: string);
  { write access method for EditFile public property:
        set the Notepad Plus caption, and settings (language highlighting, editing options)
        according to the type of file just loaded }
var Extension, LanguageName : string; IsSourceCode, IsTextFile: Boolean; synindex: Integer;
begin
  fEditFile:= Name;
  if name<>'' then Caption:= Format('Notepad Plus - %s <%s>', [ExtractFileName(name), PlusMemo1.Encoding.EncodingName])
              else Caption:= 'Notepad Plus - Untitled';
  Application.Title:= Caption;
  Extension:= UpperCase(ExtractFileExt(Name));

  LanguageName:= LanguageFromExtension(Extension, IsSourceCode, IsTextFile);
  if LanguageName<>'' then
    try
      synindex:= rgSyntax.ItemIndex;
      rgSyntax.ItemIndex:= rgSyntax.Items.IndexOf(LanguageName);
      if (synindex = rgSyntax.ItemIndex) and (synindex = 5 {Ini files}) then ParseIniFile;  // if it was not already at ini files, that ParseIniFile method is called right above

      if IsSourceCode then
        begin
          BtnCodeEditor.Down:= True;
          BtnCodeEditorClick(Self)  { set code editor settings }
        end
      else
        if IsTextFile then
          begin
            BtnTextEditor.Down:= True;
            BtnTextEditorClick(Self)  { set text editor settings }
          end
    except
      rgSyntax.ItemIndex:= 0    // None
    end
end;

procedure TFrmMain.LoadFile(const FName: string);
begin
  fSomeCollapsibleBlocks:= False;
  fLoadingContent:= True;  // Signal for the OnProgress handler
  try
     PlusMemo1.Lines.LoadFromFile(FName);
     PlusMemo1.Modified:= False;
     SpeedBtnSave.Enabled:= False

  finally
      fLoadingContent:= False
    end;

  PlusMemo1SelMove(Self);
  PlusMemo1StyleChange(Self);
  EditFile:= FName;  // this will also select the proper highlighter
end;

procedure TFrmMain.Cut1Click(Sender: TObject);
  { event handler for Edit/Cut menu item .OnClick }
  {          also for Cut speed button .OnClick }
begin
  Clipboard.Open;     { not necessary if you just do PlusMemo.CutToClipboard }
  PlusToHtml1.CopyToClipboard;
  PlusToRtf1.CopyToClipboard;
  PlusMemo1.CutToClipboard;
  Clipboard.Close
end;

procedure TFrmMain.Paste1Click(Sender: TObject);
  { event handler for Edit/Paste menu item .OnClick
             also for Paste speed button   .OnClick }
begin
  PlusMemo1.PasteFromClipboard
end;

procedure TFrmMain.Copy1Click(Sender: TObject);
   { event handler for Edit/Copy menu item .OnClick
              also for Copy speed button   .OnClick }
begin
  Clipboard.Open;       { not necessary if you just do PlusMemo.CopyToClipboard }
  PlusMemo1.CopyToClipboard;
  PlusToHtml1.CopyToClipboard;
  PlusToRtf1.CopyToClipboard;
  Clipboard.Close
end;

procedure TFrmMain.Save1Click(Sender: TObject);
   { event handler for File/Save menu item .OnClick }
   {          also for Save speed button   .OnClick }
begin
  if EditFile='' then SaveAs1Click(Save1)
  else
    if EditFile <> '' then
      begin
        fSavingContent:= True;  // signal for the OnProgress handler
        try
          PlusMemo1.Lines.SaveToFile(EditFile);  // This will use the same encoding that was loaded in
          PlusMemo1.Modified:= False;
          SpeedBtnSave.Enabled:= False

        finally
            fSavingContent:= False
          end
      end;
end;

procedure TFrmMain.SaveAs1Click(Sender: TObject);
   { event handler for File/Save As menu item .OnClick }
   { also called by Save function if no file name is present }
var sname, ext: string;   { the file extension }
begin
  SaveDialog1.Filter:= 'Text files (*.TXT)|*.TXT|All files (*.*)|*.*';
  if SaveDialog1.Execute then
    begin
      sname:= SaveDialog1.FileName;
      ext:= UpperCase(ExtractFileExt(sname));
      if (ext='') and (sname[Length(sname)]<>'.') then sname:= sname + '.TXT';
      fSavingContent:= True;
      try
        PlusMemo1.Lines.SaveToFile(sname, StandardEncodingFromName(SaveDialog1.Encodings[SaveDialog1.EncodingIndex]));
        PlusMemo1.Modified:= False;
        EditFile:= sname;
        SpeedBtnSave.Enabled:= False
      finally
        fSavingContent:= False
      end;
    end
end;

procedure TFrmMain.New1Click(Sender: TObject);
   { event handler for File/New menu item  .OnClick }
var canDiscard: Boolean;
begin
  FormCloseQuery(New1, canDiscard); { can we discard the current file ? }
  if canDiscard then
    begin
      PlusMemo1.Clear;
      EditFile:= '';
      PlusMemo1.Modified:= False;
      SpeedBtnSave.Enabled:= False
    end
end;

procedure TFrmMain.Open1Click(Sender: TObject);
   { event handler for File/Open menu item  .OnClick }
             {also for Open speed button    .OnClick }
var canDiscard: Boolean;
begin
  FormCloseQuery(Open1, canDiscard); { can we discard the current file? }
  if canDiscard then
    if OpenDialog1.Execute then LoadFile(OpenDialog1.FileName);
end;

procedure TFrmMain.SpeedBtnBoldClick(Sender: TObject);
   { event handler for Bold speed button }
begin
  PlusMemo1.SetBold;
  SpeedBtnBold.Down:= fsBold in PlusMemo1.SelStyle;
end;

procedure TFrmMain.SpeedBtnItalicClick(Sender: TObject);
   { event handler for Italic speed button }
begin
  PlusMemo1.SetItalic;
  SpeedBtnItalic.Down:= fsItalic in PlusMemo1.SelStyle;
end;

procedure TFrmMain.SpeedBtnUnderlineClick(Sender: TObject);
   { event handler for Underline speed button }
begin
  PlusMemo1.SetUnderline;
  SpeedBtnUnderline.Down:= fsUnderline in PlusMemo1.SelStyle;
end;

procedure TFrmMain.SpeedBtnHighlightClick(Sender: TObject);
   { event handler for Highlight speed button }
begin
  PlusMemo1.SetHighlight;
  SpeedBtnHighlight.Down:= fsHighlight in TPlusFontStyles(PlusMemo1.SelStyle)
end;

procedure TFrmMain.SpeedBtnAltFontClick(Sender: TObject);
   { event handler for Alternate font speed button }
begin
  PlusMemo1.SetAltFont;
  SpeedBtnAltFont.Down:= fsAltFont in TPlusFontStyles(PlusMemo1.SelStyle)
end;

procedure TFrmMain.Exit1Click(Sender: TObject);
   { event handler for File/Exit menu item }
begin
  Close
end;

procedure TFrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
   { event handler for Main.OnCloseQuery }
begin
  CanClose:= True;
  if PlusMemo1.Modified then
    case MessageDlg('Save changes to "' + ExtractFileName(EditFile) + '"?',
                         mtConfirmation, mbYesNoCancel, 0) of
        mrYes   : Save1Click(Self);
        mrCancel: CanClose:= False
        end
end;

procedure TFrmMain.SelectAll1Click(Sender: TObject);
   { event handler for Edit/Select All menu item }
begin
  PlusMemo1.SelectAll
end;

procedure TFrmMain.Font1Click(Sender: TObject);
   { event handler for Setup/Font menu item }
begin
  FontDialog1.Font:= PlusMemo1.Font;
  if FontDialog1.Execute then
    begin
      PlusMemo1.Font:= FontDialog1.Font;
      if BtnTextEditor.Down then TextEditorFont:= PlusMemo1.Font.Name
    end
end;

procedure TFrmMain.AlternateFont1Click(Sender: TObject);
   { event handler for Setup/Alternate Font menu item }
begin
  FontDialog1.Font:= PlusMemo1.AltFont;
  if FontDialog1.Execute then
    begin
      PlusMemo1.AltFont:= FontDialog1.Font;
      SpeedBtnAltFont.Font.Name:= FontDialog1.Font.Name
    end
end;


procedure TFrmMain.BackgroundColor1Click(Sender: TObject);
   { event handler for Setup/Background Color menu item }
begin
  ColorDialog1.Color:= PlusMemo1.Color;
  if ColorDialog1.Execute then PlusMemo1.Color:= ColorDialog1.Color
end;

procedure TFrmMain.HighlightText1Click(Sender: TObject);
   { event handler for Setup/Highlight Text Color menu item }
begin
  ColorDialog1.Color:= PlusMemo1.HighlightColor;
  if ColorDialog1.Execute then PlusMemo1.HighlightColor:= ColorDialog1.Color
end;

procedure TFrmMain.HighlightBackgroundColor1Click(Sender: TObject);
   { event handler for Setup/Highlight Background Color menu item }
begin
  ColorDialog1.Color:= PlusMemo1.HighlightBackgnd;
  if ColorDialog1.Execute then PlusMemo1.HighlightBackgnd:= ColorDialog1.Color
end;

procedure TFrmMain.PlusMemo1Progress(Sender: TObject);
   { PlusMemo1.OnProgress event handler }
var done: Integer;
begin
  done:= PlusMemo1.FormatCompleted;
  if fLoadingContent then
    begin
      if (PlusMemo1.LoadStreamSize > 0) and (done < PlusMemo1.LoadStreamSize) then
        begin
          sbStatus.Panels[sbcProgress].Text:= ' loading ' + IntToStr(Round(done/PlusMemo1.LoadStreamSize * 100)) + '%';
          sbStatus.Update
        end
      else PlusMemo1SelMove(PlusMemo1);  // refresh status bar caption with current position
      Exit
    end;

  if fSavingContent then
    begin
      if done < PlusMemo1.ParagraphCount then
        begin
          sbStatus.Panels[sbcProgress].Text:= ' saving ' + IntToStr(Round(done/PlusMemo1.ParagraphCount * 100)) + '%';
          sbStatus.Update
        end
      else PlusMemo1SelMove(PlusMemo1);
      Exit
    end;

  // Not loading nor saving, thus this OnProgress event was from formatting progress
  if done < PlusMemo1.ParagraphCount then
    begin
      sbStatus.Panels[sbcProgress].Text:= ' formatting ' + IntToStr(Round(done / PlusMemo1.ParagraphCount * 100)) +'%';
      sbStatus.Update
    end
  else
      PlusMemo1SelMove(PlusMemo1);  // refresh the status bar caption with current position
end;

procedure TFrmMain.PlusMemo1StyleChange(Sender: TObject);
   { PlusMemo1.OnStyleChange event handler }
var fs: TFontStyles;
begin
  fs:= PlusMemo1.SelStyle;
  SpeedBtnBold.Down:= fsBold in fs;
  SpeedBtnItalic.Down:= fsItalic in fs;
  SpeedBtnUnderline.Down:= fsUnderline in fs;
  SpeedBtnHighlight.Down:= fsHighlight in TPlusFontStyles(fs);
  SpeedBtnAltFont.Down:= fsAltFont in TPlusFontStyles(fs)
end;

procedure TFrmMain.PlusMemo1SelMove(Sender: TObject);
   { PlusMemo1.OnSelMove event handler }
begin
  with PlusMemo1 do
    begin
      sbStatus.Panels[sbcPosition].Text:= ' Pos: ' + IntToStr(SelStart);
      sbStatus.Panels[sbcParagraph].Text:= ' parg: ' + IntToStr(SelPar+1);
      sbStatus.Panels[sbcLine].Text:= ' line: ' + IntToStr(SelLine+1);
      sbStatus.Panels[sbcCol].Text:= 'col: ' + IntToStr(SelCol+1)
    end
end;

procedure TFrmMain.AboutNotepadPlus1Click(Sender: TObject);
   { event handler for Help/About menu item }
begin
  TAboutBox.Create(nil).ShowModal
end;

procedure TFrmMain.Toolbar1Click(Sender: TObject);
   { event handler for Setup/Toolbar menu item }
begin
  with PanToolbar do
    begin
      Visible:= not Visible;
      Toolbar1.Checked:= Visible
    end
end;

procedure TFrmMain.Statusbar1Click(Sender: TObject);
   { event handler for Setup/Status bar menu item }
begin
  sbStatus.Visible:= not sbStatus.Visible;
  Statusbar1.Checked:= sbStatus.Visible
end;

procedure TFrmMain.TextFormat1Click(Sender: TObject);
   { event handler for Setup/Text formatting edition menu item }
begin
  with PlusMemo1 do
    begin
      EnableHotKeys:= not EnableHotKeys;
      TextFormat1.Checked:= EnableHotKeys
    end
end;


procedure TFrmMain.CaretWidth1Click(Sender: TObject);
  { event handler for Setup/CaretWidth... menu item }

var cwstr: string;
begin
  cwstr:= IntToStr(PlusMemo1.CaretWidth);
  if InputQuery('Setting caret width', 'Enter the new value (0 means auto width)', cwstr) then
      PlusMemo1.CaretWidth:= StrToInt(cwstr)
end;

procedure TFrmMain.Undo1Click(Sender: TObject);
   { event handler for Edit/Undo menu item }
begin
  PlusMemo1.Undo
end;

procedure TFrmMain.Edit1Click(Sender: TObject);
   { event handler for Edit menu item }
begin
  { set the enable property of Undo and Redo menu items
    according to the current state of PlusMemo1 }
  Undo1.Enabled:= PlusMemo1.CanUndo;
  Redo1.Enabled:= PlusMemo1.CanRedo
end;

procedure TFrmMain.CustomKeywordsClick(Sender: TObject);
   { event handler for Keywords/Custom Keywords... menu item }
begin
  if EditKeywordList(PlusMemo1.Keywords, False, True) and (rgSyntax.ItemIndex = 6) then
    PlusMemo1.ReApplyKeywords
end;

procedure TFrmMain.CustomStartstopkeys1Click(Sender: TObject);
   { event handler for Keywords/CustomStartStopKeys... menu item }
begin
  if EditStartStopList(PlusMemo1.StartStopKeys, False) and (rgSyntax.ItemIndex = 6) then
    PlusMemo1.ReApplyKeywords
end;


procedure TFrmMain.LblOverwriteClick(Sender: TObject);
   { event handler for INSERT status .OnClick
              also called by Edit/Insert and Edit/Overwrite menu item handlers }
begin
  PlusMemo1.OverWrite:= not PlusMemo1.OverWrite;
  if PlusMemo1.OverWrite then
    begin
      sbStatus.Panels[sbcInsert].Text:= 'OVERWRITE';
      Overwrite1.Checked:= True;
      Insert1.Checked:= False
    end
  else
      begin
        sbStatus.Panels[sbcInsert].Text:= 'INSERT';
        Overwrite1.Checked:= False;
        Insert1.Checked:= True
      end
end;

procedure TFrmMain.Insert1Click(Sender: TObject);
   { event handler for Edit/Insert menu item }
begin
  if not Insert1.Checked then LblOverwriteClick(Insert1)
end;

procedure TFrmMain.Overwrite1Click(Sender: TObject);
   { event handler for Edit/Overwrite menu item }
begin
  if not Overwrite1.Checked then LblOverwriteClick(Overwrite1)
end;

procedure TFrmMain.LblUpdateClick(Sender: TObject);
   { event handler for update status label;
        this is the label at the rightmost position
        on the status bar; it indicates the current value
        of PlusMemo1.UpdateMode.
        Clicking on this label will make UpdateMode cycle through
        its possible values.  This way, one can appreciate what is
        the effect of the various settings }
begin
  with PlusMemo1 do
    begin
      if UpdateMode<High(UpdateMode) then UpdateMode:= Succ(UpdateMode)
                                     else UpdateMode:= Low(UpdateMode);
      with sbStatus.Panels[sbcUpdate] do
        case UpdateMode of
          umImmediate : Text:= 'Update mode: immediate';
          umBackground: Text:= 'Update mode: background';
          umOnNeed    : Text:= 'Update mode: on need'
          end
    end;
end;


procedure TFrmMain.BtnCodeEditorClick(Sender: TObject);
   { event handler for Code Editor setup speed button
      also called by setEditFile method when loading a .PAS file }
begin
  BtnCodeEditor.AllowAllUp:= False;
  with PlusMemo1 do
    begin
      Lines.BeginUpdate;  { avoid unnecessary formatting and refresh while changing
                            various properties }
      Options:= [pmoKeepColumnPos, pmoPutExtraSpaces, pmoWrapCaret,
                 pmoInsertKeyActive, pmoWideOverwriteCaret, pmoAutoScrollBars,
                 pmoAutoIndent, pmoBackIndent, pmoBlockSelection, pmoSmartTabs];
      WordWrap:= False;
      Font.Name:= 'Courier New';
      Delimiters:= OOPDelimiters;
      Lines.EndUpdate;
    end;

  btnWordWrap.Down:= False;
  btnWordWrapClick(Self);    // apply the change

  { Update menu items }
  AutoIndent1.Checked:= True;
  BackIndent1.Checked:= True;
  mnuSmartTabs.Checked:= True;

  { Update buttons }
  SpeedBtnBold.Hide;
  SpeedBtnItalic.Hide;
  SpeedBtnUnderline.Hide;
  SpeedBtnHighlight.Hide;
  SpeedBtnAltFont.Hide
end;

procedure TFrmMain.BtnTextEditorClick(Sender: TObject);
   { event handler for Text Editor setup speed button
      also called by setEditFile method when loading a .TXT file }
begin
  BtnTextEditor.AllowAllUp:= False;
  with PlusMemo1 do
    begin
      Lines.BeginUpdate;  { avoid unnecessary formatting and refresh while changing
                            various properties }
      Options:= [pmoInsertKeyActive, pmoWideOverwriteCaret, pmoLargeWordSelect,
                 pmoAutoScrollBars];
      WordWrap:= True;
      Font.Name:= TextEditorFont;
      Separators:= TextEditorSeparators;
      Lines.EndUpdate
    end;

  btnWordWrap.Down:= True;
  btnWordWrapClick(Self);

  { Update menu items }
  AutoIndent1.Checked:= False;
  BackIndent1.Checked:= False;
  mnuSmartTabs.Checked:= False;

  { Update buttons }
  SpeedBtnBold.Show;
  SpeedBtnItalic.Show;
  SpeedBtnUnderline.Show;
  SpeedBtnHighlight.Show;
  SpeedBtnAltFont.Show
end;

procedure TFrmMain.DisplayIntroonStartup1Click(Sender: TObject);
   { event handler for File/Display Intro on Start up menu item }
begin
  with DisplayIntroOnStartup1 do Checked:= not Checked
end;

procedure TFrmMain.Redo1Click(Sender: TObject);
   { event handler for Edit/Redo menu item
              also for Redo speed button  }
begin
  PlusMemo1.Redo
end;

procedure TFrmMain.PlusMemo1Change(Sender: TObject);
   { PlusMemo1.OnChange event handler:
     Update the Undo and Redo speed button state }
begin
  if not (csLoading in ComponentState) then
    begin
      BtnUndo.Enabled:= PlusMemo1.CanUndo;
      BtnRedo.Enabled:= PlusMemo1.CanRedo;
      SpeedBtnSave.Enabled:= True
    end
end;

procedure TFrmMain.PlusMemo1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
   { PlusMemo1.OnKeyDown event handler:
         Update the INSERT status label if Insert key is pressed }
begin
  if Key=VK_Insert then
    begin
      LblOverwriteClick(PlusMemo1);
      Key:= 0
    end
end;

procedure TFrmMain.AutoIndent1Click(Sender: TObject);
   { event handler for Setup/Auto Indent menu item }
begin
  with AutoIndent1 do
    begin
      Checked:= not Checked;
      if Checked then PlusMemo1.Options:= PlusMemo1.Options + [pmoAutoIndent]
                 else PlusMemo1.Options:= PlusMemo1.Options - [pmoAutoIndent]
    end
end;

procedure TFrmMain.BackIndent1Click(Sender: TObject);
   { event handler for Setup/Back indent menu item }
begin
  with BackIndent1 do
    begin
      Checked:= not Checked;
      if Checked then PlusMemo1.Options:= PlusMemo1.Options + [pmoBackIndent]
                 else PlusMemo1.Options:= PlusMemo1.Options - [pmoBackIndent]
    end
end;

procedure TFrmMain.mnuSmartTabsClick(Sender: TObject);
   { event handler for Setup/Smart tabs menu item }
begin
  with mnuSmartTabs do
    begin
      Checked:= not Checked;
      if Checked then PlusMemo1.Options:= PlusMemo1.Options + [pmoSmartTabs]
                 else PlusMemo1.Options:= PlusMemo1.Options - [pmoSmartTabs]
    end
end;


procedure TFrmMain.Gutter1Click(Sender: TObject);
  { event handler for Setup/Gutter menu item }
begin
  Gutter1.Checked:= not Gutter1.Checked;
  PlusGutter1.Visible:= Gutter1.Checked
end;

procedure TFrmMain.Customdelimiters1Click(Sender: TObject);
  { event handler for Keywords/Custom delimiters menu item }
begin
  if InputQuery('', 'Enter the delimiters to use when in text mode', TextEditorSeparators) then
    begin
      if not BtnCodeEditor.Down then PlusMemo1.Separators:= TextEditorSeparators;
      if rgSyntax.ItemIndex = 6 then PlusMemo1.ReApplyKeywords
    end
end;


procedure TFrmMain.LblSelModeClick(Sender: TObject);
    { Event handler for Selection mode panel Click }
var s: string;
begin
  s:= 'Selection: ';
  with PlusMemo1 do
    begin
      // toggle color inversion and full line select
      if pmoWindowsSelColors in Options then
        begin
          Options:= Options - [pmoWindowsSelColors];
          if pmoFullLineSelect in Options then Options:= Options - [pmoFullLineSelect]
                                          else Options:= Options + [pmoFullLineSelect]

        end
      else
          Options:= Options + [pmoWindowsSelColors];

      // update the status panels
      if pmoWindowsSelColors in Options then s:= s + 'win colors, '
                                        else s:= s + 'invert, ';
      if pmoFullLineSelect in Options then s:= s + 'long'
                                      else s:= s + 'short';
      sbStatus.Panels[sbcSelection].Text:= s
    end;
end;

procedure TFrmMain.BtnPrintPreviewClick(Sender: TObject);
    { Event handler for File/Print preview menu item and print preview speed button }
begin
  PlusMemoPrinter1.Preview;
end;

procedure TFrmMain.SpeedBtnPrintClick(Sender: TObject);
    { Event handler for File/Print menu item and print speed button }
begin
  PlusMemoPrinter1.Print
end;

procedure TFrmMain.LblBreakClick(Sender: TObject);
    { Event handler for LblBreak OnClick: changes the kind of line break in output files }
const BreakKindToString: array[TPlusLineBreak] of string = ('CRLF', 'LFCR', 'CR', 'LF');
begin
  with PlusMemo1 do
    begin
      if LineBreak<High(LineBreak) then LineBreak:= Succ(LineBreak)
                                   else LineBreak:= Low(LineBreak);
      LblBreak.Caption:= BreakKindToString[LineBreak]
    end
end;

procedure TFrmMain.rgBackgroundClick(Sender: TObject);
    { Event handler for Background radio group OnClick }
begin
  case rgBackground.ItemIndex of
    0: PlusMemo1.BackgroundBmp.Bitmap.Width:= 0;  { Empty }
    1: PlusMemo1.BackgroundBmp.Bitmap.Assign(fSavedECMBmp);
    2: begin
       if fCustomBmp.Empty then
         if CustomBmpFile='' then BtnCustomPicClick(rgBackground)
                             else fCustomBmp.LoadFromFile(CustomBmpFIle);
       PlusMemo1.BackgroundBmp.Bitmap.Assign(fCustomBmp)
       end
    end;
end;

procedure TFrmMain.BtnCustomPicClick(Sender: TObject);
    { Event handler for custom background speed button }
begin
  OpenPictureDialog1.FileName:= CustomBmpFile;
  if OpenPictureDialog1.Execute then
    begin
      CustomBmpFile:= OpenPictureDialog1.FileName;
      if Sender=rgBackground then PlusMemo1.BackgroundBmp.Bitmap.Assign(fCustomBmp)
                             else rgBackground.ItemIndex:= 2;
      fCustomBmp.LoadFromFile(CustomBmpFile)
    end
end;

procedure TFrmMain.FindReplace1Click(Sender: TObject);
   { event handler for Edit\Find/Replace... menu item and speed button }
begin
  if PlusMemo1.SelLength=0 then ReplaceDialog1.FindText:= PlusMemo1.CurrentWord
  else
    if Abs(PlusMemo1.SelLength)<64 then ReplaceDialog1.FindText:= PlusMemo1.SelText;
  ReplaceDialog1.Execute
end;

procedure TFrmMain.ReplaceDialog1Find(Sender: TObject);
  { ReplaceDialog1.OnFind event handler }
begin
  with ReplaceDialog1 do
    if PlusMemo1.FindTxt(FindText, frDown in Options, frMatchCase in Options, frWholeWord in Options, False) then
        PlusMemo1.ScrollInView
    else ShowMessage('Search string not found');

  FindReplaceNext1.Enabled:= True;
  FindReplaceNext1.Caption:= 'Find &Next';
  ReplaceDialog1.CloseDialog
end;

procedure TFrmMain.ReplaceDialog1Replace(Sender: TObject);
  { ReplaceDialog1.OnReplace event handler }
begin
  with ReplaceDialog1 do
    if PlusMemo1.FindTxt(FindText, frDown in Options, frMatchCase in Options, frWholeWord in Options, False) then
      begin
        PlusMemo1.SelText:= ReplaceText;
        if frReplaceAll in Options then
          while PlusMemo1.FindTxt(FindText, frDown in Options, frMatchCase in Options, frWholeWord in Options, False) do
            PlusMemo1.SelText:= ReplaceText
      end
    else ShowMessage('Search string not found');

  FindReplaceNext1.Enabled:= True;
  FindReplaceNext1.Caption:= 'Replace &Next';
  ReplaceDialog1.CloseDialog
end;

procedure TFrmMain.FindReplacenext1Click(Sender: TObject);
  { Event handler for Edit\Find/Replace Next menu item }
begin
  if FindReplaceNext1.Caption[1]='F' then ReplaceDialog1Find(Self)
                                     else ReplaceDialog1Replace(Self)
end;

procedure TFrmMain.GenerateHtmlfile1Click(Sender: TObject);
  { Event handler for Generate Html file menu item }
begin
  SaveDialog1.FileName:= '';
  SaveDialog1.Filter:= 'Html files|*.htm;*.html|All files|*.*';
  if SaveDialog1.Execute then PlusToHtml1.SaveToFile(SaveDialog1.FileName)
end;

procedure TFrmMain.GenerateRtffile1Click(Sender: TObject);
  { Event handler for Generate Rtf file menu item }
begin
  SaveDialog1.FileName:= '';
  SaveDialog1.Filter:= 'Rtf files|*.rtf|All files|*.*';
  if SaveDialog1.Execute then PlusToRtf1.SaveToFile(SaveDialog1.FileName)
end;

procedure TFrmMain.btnSmoothScrollClick(Sender: TObject);
begin
  if btnSmoothScroll.Down then PlusMemo1.ScrollTime:= 300
                          else PlusMemo1.ScrollTime:= 0
end;

procedure TFrmMain.sbStatusClick(Sender: TObject);
  { Event handler for status bar mouse click:
    change PlusMemo1 settings depending on which panel has been clicked }
begin
  case fMouseStatus of
    sbcInsert: lblOverwriteClick(sbStatus);
    sbcUpdate: lblUpdateClick(sbStatus);
    sbcSelection: lblSelModeClick(sbStatus)
    end
end;

procedure TFrmMain.sbStatusMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
  { Event handler for status bar mouse move, used to set fMouseStatus for OnClick event above }
var sright: Integer;
begin
  fMouseStatus:= 0;
  sright:= sbStatus.Panels[0].Width;
  while (fMouseStatus<sbStatus.Panels.Count-1) and (X>sright) do
    begin
      Inc(fMouseStatus);
      Inc(sright, sbStatus.Panels[fMouseStatus].Width)
    end
end;

procedure TFrmMain.rgSyntaxClick(Sender: TObject);
  {Event handler for Syntax radiogroup change, and for Internet urls check box }
var newhilit: TCustomExtHighlighter;
begin
  CleanupCollapsibleBlocks;   // we may have put some for Ini file highlighting
  if rgSyntax.ItemIndex in [0, 6] then  // None, Custom
    begin
      UrlHighlighter1.Scope:= 0;
      if cbInternetUrls.Checked then PlusMemo1.Highlighter:= UrlHighlighter1
                                else PlusMemo1.Highlighter:= nil;
      PlusMemo1.ApplyKeywords:= rgSyntax.ItemIndex = 6;
      PlusMemo1.ApplyStartStopKeys:= PlusMemo1.ApplyKeywords
    end

  else     // one of the language highlighters have been selected
    begin
      PlusMemo1.ApplyKeywords:= False;
      PlusMemo1.ApplyStartStopKeys:= False;
      newhilit:= nil;
      case rgSyntax.ItemIndex of
          1:  // Delphi
            begin
              newhilit:= OOPHighlighter1;
              UrlHighlighter1.Scope:= OOPCommentContext
            end;
          2:  // C++
            begin
              newhilit:= CPPHighlighter1;
              UrlHighlighter1.Scope:= CPPCommentContext
            end;
          3:  // Html
            begin
              newhilit:= HtmlHighlighter1;
              UrlHighlighter1.Scope:= HtmlCommentScope
            end;
          4: // SQL
            begin
              newhilit:= SQLHighlighter1;
              UrlHighlighter1.Scope:= SQLCommentContext
            end;
          5: //Ini
            begin
              PlusMemo1.Highlighter:= nil;
              ParseIniFile
            end
        end;
      PlusMemo1.Highlighter:= newhilit;
      if newhilit <> nil then
        if cbInternetUrls.Checked then TExtHighlighter(newhilit).SubHighlighter:= UrlHighlighter1
                                  else TExtHighlighter(newhilit).SubHighlighter:= nil
                                     { Note: we make a typecast to TExtHighlighter here because it exposes
                                       the SubHighlighter property (protected in TCustomExtHighlighter).  We
                                       could also have set each individual highlighter's SubHighlighter }
    end;

  PlusMemo1.ReApplyKeywords  // necessary if we want the change to apply immediately to existing text
end;

function TFrmMain.LanguageFromExtension(const Ext: string; var SourceCode, TxtFile: Boolean): string;
      { Returns the language name (ex: None, Delphi, C++, ... that is normally applied for
        files having extension Ext.  It also sets SourceCode to True if such file is a source code file,
        or TxtFile if this is a plain text file.

        Parameter Ext must be uppercased }
begin
  SourceCode:= False;
  TxtFile:= False;
  Result:= '';

  if (Ext='.PAS') or (Ext='.DPR') then
    begin
      SourceCode:= True;
      Result:= 'Delphi'
    end

  else
    if (Ext='.CPP') or (Ext='.HPP') or (Ext = '.C') then
      begin
        SourceCode:= True;
        Result:= 'C++'
      end

    else
      if (Ext='.HTM') or (Ext='.HTML') then Result:= 'Html'

      else
        if Ext='.SQL' then
          begin
            SourceCode:= True;
            Result:= 'Sql'
          end

        else
          if Ext = '.INI' then Result:= 'Ini'

          else
            if Ext='.TXT' then
              begin
                TxtFile:= True;
                Result:= 'None'
              end
end;

procedure TFrmMain.BtnParAlignClick(Sender: TObject);
  { Event handler for paragraph alignment buttons }
begin
  if Sender=BtnLeft then PlusMemo1.Alignment:= taLeftJustify;
  if Sender=BtnRight then PlusMemo1.Alignment:= taRightJustify;
  if Sender=BtnCenter then PlusMemo1.Alignment:= taCenter
end;

procedure TFrmMain.BtnWordWrapClick(Sender: TObject);
  { Event handler for Word wrap speed button }
begin
  PlusMemo1.WordWrap:= btnWordWrap.Down;
  if PlusMemo1.WordWrap then
    begin
      { ensure that KeepColumnPos is not there if word wrap is off, otherwise navigation behavior will look strange }
      PlusMemo1.Options:= PlusMemo1.Options - [pmoKeepColumnPos];
      BtnLeft.Enabled:= True;
      BtnRight.Enabled:= True;
      BtnCenter.Enabled:= True;
      if BtnLeft.Down then PlusMemo1.Alignment:= taLeftJustify;
      if BtnRight.Down then PlusMemo1.Alignment:= taRightJustify;
      if BtnCenter.Down then PlusMemo1.Alignment:= taCenter
    end

  else
    begin
      BtnLeft.Enabled:= False;
      BtnRight.Enabled:= False;
      BtnCenter.Enabled:= False;
      PlusMemo1.Alignment:= taLeftJustify
    end
end;

procedure TFrmMain.BtnJustifiedClick(Sender: TObject);
  { Event handler for Justified speed button }
begin
  PlusMemo1.Justified:= btnJustified.Down
end;

procedure TFrmMain.btnNonPrintCharsClick(Sender: TObject);
  { Event handler for Show/Hide non printing characters speed button }
begin
  if btnNonPrintChars.Down then
    begin
      PlusMemo1.ShowNonPrintChars:= [pmNPSpace, pmNPTab, pmNPReturn];
      PlusMemo1.Justified:= False   // Justification is not possible with pmHCSpace
    end
  else
    begin
      PlusMemo1.ShowNonPrintChars:= [];
      PlusMemo1.Justified:= btnJustified.Down
    end
end;

procedure TFrmMain.PlusGutter1DblClick(Sender: TObject);
  { Event handler for gutter OnDblClick: toggle property ParagraphNumbers }
begin
  PlusGutter1.ParagraphNumbers:= not PlusGutter1.ParagraphNumbers
end;

procedure TFrmMain.ParseIniFile;
var secstart, i: Integer; spar: string;
begin
  secstart:= -1;   // no section started
  for i:= 0 to PlusMemo1.Paragraphs.Count-1 do
    begin
      spar:= PlusMemo1.Paragraphs[i];
      if (Length(spar)>2) and (spar[1]='[') and (spar[Length(spar)]=']') then
        begin     // this is the start of a section
          if secstart>=0 then
            begin
              PlusMemo1.MakeCollapsibleBlock(secstart, i-1);
              fSomeCollapsibleBlocks:= True
            end;
          secstart:= i
        end
    end;

  // Make the last section collapsible
  if (secstart>=0) and (secstart<PlusMemo1.Paragraphs.Count-1) then
    begin
      PlusMemo1.MakeCollapsibleBlock(secstart, PlusMemo1.Paragraphs.Count-1);
      fSomeCollapsibleBlocks:= True
    end;

  if fSomeCollapsibleBlocks then
    begin
      btnCollapseAll.Enabled:= True;
      btnExpandAll.Enabled:= True
    end
end;

procedure TFrmMain.FormResize(Sender: TObject);
begin
  //sbStatus.Panels[sbcInsert].Text:= IntToStr(Width) + 'x' + IntToStr(Height)
end;

procedure TFrmMain.CleanupCollapsibleBlocks;
var i: Integer;
begin
  if fSomeCollapsibleBlocks then
    begin
      for i:= 0 to PlusMemo1.Paragraphs.Count-1 do
          PlusMemo1.RemoveCollapsibleBlock(i);
      fSomeCollapsibleBlocks:= False
    end;
  btnCollapseAll.Enabled:= False;
  btnExpandAll.Enabled:= False
end;

procedure TFrmMain.btnCollapseAllClick(Sender: TObject);
  { Event handler for Collapse All speed button }
begin
  PlusMemo1.CollapseAll;
end;

procedure TFrmMain.btnExpandAllClick(Sender: TObject);
  { Event handler for Expand All speed button }
begin
  PlusMemo1.ExpandAll;
end;

end.


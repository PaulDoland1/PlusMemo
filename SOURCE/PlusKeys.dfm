object DlgExtKeysEditor: TDlgExtKeysEditor
  Left = 188
  Top = 181
  ActiveControl = lvKeys
  BorderIcons = [biMinimize]
  BorderStyle = bsSingle
  Caption = 'Keywords editor'
  ClientHeight = 522
  ClientWidth = 464
  Color = 14146969
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBlack
  Font.Height = 14
  Font.Name = 'Arial'
  Font.Style = []
  Menu = MainMenu1
  Position = poScreenCenter
  Scaled = False
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 14
  object LblHint: TLabel
    Left = 8
    Top = 240
    Width = 345
    Height = 17
    Alignment = taCenter
    AutoSize = False
    Caption = 
      'Click on a selected item to edit it, or press F2 to edit the foc' +
      'used one'
    Color = clInfoBk
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = 12
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentColor = False
    ParentFont = False
  end
  object btnMoveUp: TSpeedButton
    Left = 368
    Top = 184
    Width = 81
    Height = 25
    Caption = 'Move up'
    Glyph.Data = {
      76010000424D7601000000000000760000002800000020000000100000000100
      04000000000000010000120B0000120B00001000000000000000000000000000
      800000800000008080008000000080008000808000007F7F7F00BFBFBF000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00333333000333
      3333333333777F33333333333309033333333333337F7F333333333333090333
      33333333337F7F33333333333309033333333333337F7F333333333333090333
      33333333337F7F33333333333309033333333333FF7F7FFFF333333000090000
      3333333777737777F333333099999990333333373F3333373333333309999903
      333333337F33337F33333333099999033333333373F333733333333330999033
      3333333337F337F3333333333099903333333333373F37333333333333090333
      33333333337F7F33333333333309033333333333337373333333333333303333
      333333333337F333333333333330333333333333333733333333}
    NumGlyphs = 2
    OnClick = btnMoveClick
  end
  object btnMoveDown: TSpeedButton
    Left = 368
    Top = 208
    Width = 81
    Height = 25
    Caption = 'Move down'
    Glyph.Data = {
      76010000424D7601000000000000760000002800000020000000100000000100
      04000000000000010000120B0000120B00001000000000000000000000000000
      800000800000008080008000000080008000808000007F7F7F00BFBFBF000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00333333303333
      333333333337F33333333333333033333333333333373F333333333333090333
      33333333337F7F33333333333309033333333333337373F33333333330999033
      3333333337F337F33333333330999033333333333733373F3333333309999903
      333333337F33337F33333333099999033333333373333373F333333099999990
      33333337FFFF3FF7F33333300009000033333337777F77773333333333090333
      33333333337F7F33333333333309033333333333337F7F333333333333090333
      33333333337F7F33333333333309033333333333337F7F333333333333090333
      33333333337F7F33333333333300033333333333337773333333}
    NumGlyphs = 2
    OnClick = btnMoveClick
  end
  object OKBtn: TBitBtn
    Left = 368
    Top = 8
    Width = 81
    Height = 27
    Caption = 'OK'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = 11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    Glyph.Data = {
      DE010000424DDE01000000000000760000002800000024000000120000000100
      0400000000006801000000000000000000001000000010000000000000000000
      80000080000000808000800000008000800080800000C0C0C000808080000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00333333333333
      3333333333333333333333330000333333333333333333333333F33333333333
      00003333344333333333333333388F3333333333000033334224333333333333
      338338F3333333330000333422224333333333333833338F3333333300003342
      222224333333333383333338F3333333000034222A22224333333338F338F333
      8F33333300003222A3A2224333333338F3838F338F33333300003A2A333A2224
      33333338F83338F338F33333000033A33333A222433333338333338F338F3333
      0000333333333A222433333333333338F338F33300003333333333A222433333
      333333338F338F33000033333333333A222433333333333338F338F300003333
      33333333A222433333333333338F338F00003333333333333A22433333333333
      3338F38F000033333333333333A223333333333333338F830000333333333333
      333A333333333333333338330000333333333333333333333333333333333333
      0000}
    Margin = 2
    ModalResult = 1
    NumGlyphs = 2
    ParentFont = False
    Spacing = -1
    TabOrder = 0
    IsControl = True
  end
  object CancelBtn: TBitBtn
    Left = 368
    Top = 40
    Width = 81
    Height = 27
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = 11
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    Kind = bkCancel
    Margin = 2
    NumGlyphs = 2
    ParentFont = False
    Spacing = -1
    TabOrder = 1
    IsControl = True
  end
  object gbTitle: TGroupBox
    Left = 8
    Top = 4
    Width = 345
    Height = 229
    Caption = 'Keywords'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = 12
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 2
    object lblSelCount: TLabel
      Left = 80
      Top = 8
      Width = 257
      Height = 17
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = 12
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
    end
    object lvKeys: TListView
      Left = 8
      Top = 24
      Width = 329
      Height = 201
      Columns = <
        item
          Width = 5
        end
        item
          Alignment = taCenter
          Caption = 'Start'
          Width = 150
        end
        item
          Alignment = taCenter
          Caption = 'Stop'
          Width = 150
        end>
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = 14
      Font.Name = 'Arial'
      Font.Style = []
      HideSelection = False
      MultiSelect = True
      RowSelect = True
      ParentFont = False
      TabOrder = 0
      ViewStyle = vsList
      OnChange = lvKeysChange
      OnEdited = lvKeysEdited
      OnEditing = lvKeysEditing
      OnEnter = lvKeysEnter
      OnExit = lvKeysExit
      OnKeyDown = lvKeysKeyDown
    end
  end
  object gbOptions: TGroupBox
    Left = 8
    Top = 264
    Width = 448
    Height = 249
    Caption = 'Options for selected keywords'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = 15
    Font.Name = 'Arial'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 3
    object ShpForegnd: TShape
      Left = 352
      Top = 104
      Width = 17
      Height = 17
      Brush.Style = bsDiagCross
    end
    object ShpBackgnd: TShape
      Left = 352
      Top = 128
      Width = 17
      Height = 17
    end
    object Label1: TLabel
      Left = 16
      Top = 100
      Width = 87
      Height = 15
      Caption = 'Context &number'
      FocusControl = EdContext
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = 15
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
    end
    object LblMouse: TLabel
      Left = 128
      Top = 100
      Width = 78
      Height = 15
      Caption = 'Mouse &pointer'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = 15
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
    end
    object ChkBMatchCase: TCheckBox
      Left = 16
      Top = 24
      Width = 89
      Height = 17
      Caption = ' &Match case'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = 15
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = ChkBxClick
    end
    object ChkBWholeWords: TCheckBox
      Left = 16
      Top = 48
      Width = 121
      Height = 17
      Caption = ' &Whole words only'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = 15
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      OnClick = ChkBxClick
    end
    object ChkBHighlight: TCheckBox
      Left = 320
      Top = 72
      Width = 81
      Height = 17
      Caption = ' &Highlight'
      Color = clYellow
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = 15
      Font.Name = 'Arial'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      TabOrder = 2
      OnClick = ChkBxClick
    end
    object ChkBAltFont: TCheckBox
      Left = 168
      Top = 72
      Width = 121
      Height = 17
      Caption = ' &Alternate font'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = 15
      Font.Name = 'Courier New'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      OnClick = ChkBxClick
    end
    object ChkBItalic: TCheckBox
      Left = 168
      Top = 48
      Width = 57
      Height = 17
      Caption = ' &Italic'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = 15
      Font.Name = 'Arial'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 4
      OnClick = ChkBxClick
    end
    object ChkBBold: TCheckBox
      Left = 168
      Top = 24
      Width = 73
      Height = 17
      Caption = ' &Bold'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = 15
      Font.Name = 'Arial'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
      OnClick = ChkBxClick
    end
    object ChkBUnderline: TCheckBox
      Left = 320
      Top = 24
      Width = 81
      Height = 17
      Caption = ' &Underline'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = 15
      Font.Name = 'Arial'
      Font.Style = [fsUnderline]
      ParentFont = False
      TabOrder = 6
      OnClick = ChkBxClick
    end
    object ChkBStrikeOut: TCheckBox
      Left = 320
      Top = 48
      Width = 81
      Height = 17
      Caption = ' &Strike out'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = 15
      Font.Name = 'Arial'
      Font.Style = [fsStrikeOut]
      ParentFont = False
      TabOrder = 7
      OnClick = ChkBxClick
    end
    object BtnForegnd: TButton
      Left = 260
      Top = 104
      Width = 84
      Height = 18
      Caption = 'For&eground...'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = 15
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 8
      OnClick = BtnForegndClick
    end
    object BtnBackgnd: TButton
      Left = 260
      Top = 128
      Width = 84
      Height = 18
      Caption = 'Back&ground...'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = 15
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 9
      OnClick = BtnForegndClick
    end
    object EdContext: TEdit
      Left = 16
      Top = 120
      Width = 73
      Height = 23
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = 15
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 10
      OnExit = EdContextExit
    end
    object cbCursors: TComboBox
      Left = 128
      Top = 120
      Width = 97
      Height = 22
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = 14
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 11
      OnChange = cbCursorsChange
    end
    object ChkBCrossPar: TCheckBox
      Left = 16
      Top = 72
      Width = 121
      Height = 17
      Caption = '&Cross paragraphs'
      Checked = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = 15
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      State = cbChecked
      TabOrder = 12
      Visible = False
      OnClick = ChkBxClick
    end
    object btnClearForeground: TButton
      Left = 384
      Top = 104
      Width = 41
      Height = 17
      Caption = 'Clear'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = 15
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 13
      OnClick = BtnResetColorsClick
    end
    object btnClearBackground: TButton
      Left = 384
      Top = 128
      Width = 41
      Height = 17
      Caption = 'Clear'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = 15
      Font.Name = 'Arial'
      Font.Style = []
      ParentFont = False
      TabOrder = 14
      OnClick = BtnResetColorsClick
    end
    object panExtended: TPanel
      Left = 16
      Top = 146
      Width = 425
      Height = 98
      BevelOuter = bvNone
      Color = 14146969
      TabOrder = 15
      object Label2: TLabel
        Left = 3
        Top = 10
        Width = 38
        Height = 15
        Caption = 'S&cope '
        FocusControl = EdScope
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = 15
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
      end
      object Label3: TLabel
        Left = 112
        Top = 10
        Width = 65
        Height = 15
        Caption = 'Priority &level'
        FocusControl = EdPriority
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = 15
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
      end
      object EdScope: TEdit
        Left = 0
        Top = 26
        Width = 73
        Height = 23
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = 15
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnExit = EdContextExit
      end
      object EdPriority: TEdit
        Left = 112
        Top = 26
        Width = 73
        Height = 23
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = 15
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnExit = EdContextExit
      end
      object rgPosInfo: TRadioGroup
        Left = 240
        Top = 8
        Width = 177
        Height = 89
        Caption = ' Positional dependency '
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = 15
        Font.Name = 'Arial'
        Font.Style = []
        Items.Strings = (
          'None'
          'First word of paragraph'
          'First non blank item'
          'Start of paragraph')
        ParentFont = False
        TabOrder = 2
        OnClick = rgPosInfoClick
      end
      object cbEndAtDel: TCheckBox
        Left = 112
        Top = 64
        Width = 113
        Height = 17
        Caption = 'End at delimiter'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = 15
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
        TabOrder = 3
        Visible = False
        OnClick = ChkBxClick
      end
      object cbCollapsible: TCheckBox
        Left = 0
        Top = 64
        Width = 97
        Height = 17
        Caption = 'Collapsible'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = 15
        Font.Name = 'Arial'
        Font.Style = []
        ParentFont = False
        TabOrder = 4
        Visible = False
        OnClick = ChkBxClick
      end
    end
  end
  object BtnDelete: TButton
    Left = 368
    Top = 144
    Width = 81
    Height = 25
    Caption = 'Delete'
    Enabled = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = 15
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 4
    OnClick = BtnDeleteClick
  end
  object btnAdd: TButton
    Left = 368
    Top = 115
    Width = 81
    Height = 25
    Caption = 'Add'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = 15
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 5
    OnClick = btnInsertClick
  end
  object btnInsert: TButton
    Left = 368
    Top = 86
    Width = 81
    Height = 25
    Caption = 'Insert'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clBlack
    Font.Height = 15
    Font.Name = 'Arial'
    Font.Style = []
    ParentFont = False
    TabOrder = 6
    OnClick = btnInsertClick
  end
  object btnHelp: TBitBtn
    Left = 368
    Top = 236
    Width = 81
    Height = 25
    Hint = 
      'Click on this button for help with this window.\nWorks only if P' +
      'lusMemo help is installed in your environment\n  (see Installati' +
      'on topic in help file)'
    Kind = bkHelp
    NumGlyphs = 2
    ParentShowHint = False
    ShowHint = True
    TabOrder = 7
    OnClick = btnHelpClick
  end
  object ColorDialog1: TColorDialog
    Left = 368
    Top = 232
  end
  object MainMenu1: TMainMenu
    Left = 400
    Top = 232
    object mnuFile: TMenuItem
      Caption = '&File'
      object mnuLoadList: TMenuItem
        Caption = '&Load list (text)...'
        OnClick = mnuLoadListClick
      end
      object mnuLoadListDefText: TMenuItem
        Caption = 'Load list and attributes (text)...'
        OnClick = mnuLoadListDefClick
      end
      object mnuLoadListDefBin: TMenuItem
        Caption = 'Load list and attributes (binary)...'
        OnClick = mnuLoadListDefClick
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object mnuSaveList: TMenuItem
        Caption = 'Save list (text)...'
        OnClick = mnuSaveListClick
      end
      object mnuSaveListDefText: TMenuItem
        Caption = 'Save list and attributes (text)...'
        OnClick = mnuSaveListDefClick
      end
      object mnuSaveListDefBin: TMenuItem
        Caption = 'Save list and attributes (binary)...'
        OnClick = mnuSaveListDefClick
      end
    end
  end
  object OpenDialog1: TOpenDialog
    Filter = 'Ini files (*.ini)|*.ini|Text files (*.txt)|*.txt|All files|*.*'
    Options = [ofHideReadOnly, ofFileMustExist]
    Left = 376
    Top = 264
  end
  object SaveDialog1: TSaveDialog
    Filter = 'Ini files (*.ini)|*.ini|Text files (*.txt)|*.txt|All files|*.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofPathMustExist]
    Left = 408
    Top = 264
  end
end

object FrmPMPrintPreview: TFrmPMPrintPreview
  Left = 195
  Top = 141
  ClientHeight = 463
  ClientWidth = 627
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = 14
  Font.Name = 'Arial'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  Scaled = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnMouseWheel = FormMouseWheel
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 14
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 627
    Height = 41
    Align = alTop
    TabOrder = 0
    object LblPage: TLabel
      Left = 254
      Top = 16
      Width = 89
      Height = 17
      Alignment = taCenter
      AutoSize = False
      Caption = 'Page 100 of 1000'
      Color = clBtnHighlight
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = 14
      Font.Name = 'Arial'
      Font.Style = []
      ParentColor = False
      ParentFont = False
    end
    object btnPrinterSetup: TSpeedButton
      Left = 69
      Top = 5
      Width = 61
      Height = 28
      Hint = 'Printer Setup'
      Caption = '&Setup'
      ParentShowHint = False
      ShowHint = True
      OnClick = BtnPrinterClick
    end
    object btnPrint: TSpeedButton
      Left = 8
      Top = 5
      Width = 61
      Height = 28
      Hint = 'Print Document(s)'
      Caption = '&Print'
      Glyph.Data = {
        F6000000424DF600000000000000760000002800000010000000100000000100
        0400000000008000000000000000000000001000000010000000000000000000
        8000008000000080800080000000800080008080000080808000C0C0C0000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00222222222222
        22222200000000000222208888888880802200000000000008020888888BBB88
        0002088888877788080200000000000008800888888888808080200000000008
        0800220FFFFFFFF080802220F00000F000022220FFFFFFFF022222220F00000F
        022222220FFFFFFFF02222222000000000222222222222222222}
      ParentShowHint = False
      ShowHint = True
      OnClick = BtnPrinterClick
    end
    object btnMargins: TSpeedButton
      Left = 130
      Top = 5
      Width = 63
      Height = 28
      Hint = 'Show/hide margins'
      AllowAllUp = True
      GroupIndex = 1
      Caption = '&Margins'
      Glyph.Data = {
        F6000000424DF600000000000000760000002800000010000000100000000100
        0400000000008000000000000000000000001000000010000000000000000000
        80000080000000808000800000008000800080800000C0C0C000808080000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00222222222222
        2222220000000000002222077577777570222205555555555022220775777775
        7022220775777775702222077577777570222207757777757022220775777775
        7022220775777775702222077577777570222207757777757022220775777700
        0022220555555507022222077577770022222200000000022222}
      ParentShowHint = False
      ShowHint = True
      OnClick = BtnMarginsClick
    end
    object btnNextPage: TSpeedButton
      Left = 224
      Top = 5
      Width = 28
      Height = 28
      Hint = 'Next Page'
      Glyph.Data = {
        F6000000424DF600000000000000760000002800000010000000100000000100
        0400000000008000000000000000000000001000000010000000000000000000
        80000080000000808000800000008000800080800000C0C0C000808080000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00777777777777
        7777777777777777777777777777777777777777707777777777777770077777
        7777777770607777777777777706077777777777770660777777777777706607
        7777777777066077777777777706077777777777706077777777777770077777
        7777777770777777777777777777777777777777777777777777}
      ParentShowHint = False
      ShowHint = True
      OnClick = BtnNextPageClick
    end
    object btnPrevious: TSpeedButton
      Left = 198
      Top = 5
      Width = 28
      Height = 28
      Hint = 'Previous Page'
      Enabled = False
      Glyph.Data = {
        F6000000424DF600000000000000760000002800000010000000100000000100
        0400000000008000000000000000000000001000000010000000000000000000
        80000080000000808000800000008000800080800000C0C0C000808080000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00777777777777
        7777777777777777777777777777777777777777777777077777777777777007
        7777777777770607777777777770607777777777770660777777777770660777
        7777777777066077777777777770607777777777777706077777777777777007
        7777777777777707777777777777777777777777777777777777}
      ParentShowHint = False
      ShowHint = True
      OnClick = BtnPreviousClick
    end
    object btnNumbers: TSpeedButton
      Left = 352
      Top = 6
      Width = 28
      Height = 28
      Hint = 'Show/Hide line numbers'
      AllowAllUp = True
      GroupIndex = 2
      Flat = True
      Glyph.Data = {
        AE010000424DAE010000000000007600000028000000140000001A0000000100
        0400000000003801000000000000000000001000000010000000000000000000
        8000008000000080800080000000800080008080000080808000C0C0C0000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00FFFFFFFFFFFF
        FFFFFFFF0000FFFFFFFF000FFF0FFFFF0000FFFFFFFFFF0FFFFFFFFF0000FFFF
        FFFFF0FFFFFFFFFF0000FFFFFFFFFF0FFFFFFFFF0000FFFFFFFF000FFFFFFFFF
        0000FFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFF
        FFFFFFFF0000FFFFFFFFFFFFFFFFFFFF0000FFFFFFFF000FFF0FFFFF0000FFFF
        FFFF00FFFFFFFFFF0000FFFFFFFFFF0FFFFFFFFF0000FFFFFFFFFF0FFFFFFFFF
        0000FFFFFFFF000FFFFFFFFF0000FFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFF
        FFFFFFFF0000FFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFF0000FFFF
        FFFF000FFF0FFFFF0000FFFFFFFFF0FFFFFFFFFF0000FFFFFFFFF0FFFFFFFFFF
        0000FFFFFFFFF0FFFFFFFFFF0000FFFFFFFF00FFFFFFFFFF0000FFFFFFFFFFFF
        FFFFFFFF0000FFFFFFFFFFFFFFFFFFFF0000}
      ParentShowHint = False
      ShowHint = True
      OnClick = btnNumbersClick
    end
    object Label1: TLabel
      Left = 393
      Top = 28
      Width = 41
      Height = 14
      Caption = 'Columns'
    end
    object Label2: TLabel
      Left = 470
      Top = 28
      Width = 27
      Height = 14
      Caption = 'Zoom'
    end
    object BtnClose: TBitBtn
      Left = 544
      Top = 5
      Width = 81
      Height = 28
      Caption = '&Close'
      Glyph.Data = {
        DE010000424DDE01000000000000760000002800000024000000120000000100
        0400000000006801000000000000000000001000000010000000000000000000
        80000080000000808000800000008000800080800000C0C0C000808080000000
        FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00388888888877
        F7F787F8888888888333333F00004444400888FFF444448888888888F333FF8F
        000033334D5007FFF4333388888888883338888F0000333345D50FFFF4333333
        338F888F3338F33F000033334D5D0FFFF43333333388788F3338F33F00003333
        45D50FEFE4333333338F878F3338F33F000033334D5D0FFFF43333333388788F
        3338F33F0000333345D50FEFE4333333338F878F3338F33F000033334D5D0FFF
        F43333333388788F3338F33F0000333345D50FEFE4333333338F878F3338F33F
        000033334D5D0EFEF43333333388788F3338F33F0000333345D50FEFE4333333
        338F878F3338F33F000033334D5D0EFEF43333333388788F3338F33F00003333
        4444444444333333338F8F8FFFF8F33F00003333333333333333333333888888
        8888333F00003333330000003333333333333FFFFFF3333F00003333330AAAA0
        333333333333888888F3333F00003333330000003333333333338FFFF8F3333F
        0000}
      ModalResult = 2
      NumGlyphs = 2
      TabOrder = 0
    end
    object cbZoom: TComboBox
      Left = 440
      Top = 6
      Width = 97
      Height = 22
      Style = csDropDownList
      TabOrder = 1
      OnChange = cbZoomChange
      OnClick = cbZoomChange
      Items.Strings = (
        '500%'
        '200%'
        '150%'
        '100%'
        '75%'
        '50%'
        'Page width'
        'Whole page')
    end
    object udColumns: TUpDown
      Left = 385
      Top = 6
      Width = 20
      Height = 22
      Hint = 'Change number of columns'
      AlignButton = udLeft
      Associate = edColumns
      Min = 1
      Max = 10
      ParentShowHint = False
      Position = 1
      ShowHint = True
      TabOrder = 2
      OnClick = udColumnsClick
    end
    object edColumns: TEdit
      Left = 401
      Top = 6
      Width = 39
      Height = 22
      ReadOnly = True
      TabOrder = 3
      Text = '1'
    end
  end
  object sbPreview: TScrollBox
    Left = 0
    Top = 41
    Width = 627
    Height = 422
    HorzScrollBar.Margin = 10
    HorzScrollBar.Tracking = True
    VertScrollBar.Margin = 10
    VertScrollBar.Tracking = True
    Align = alClient
    Color = clGray
    ParentColor = False
    TabOrder = 1
    OnResize = sbPreviewResize
    object PBPreview: TPaintBox
      Left = 188
      Top = 16
      Width = 321
      Height = 345
      Color = clWhite
      ParentColor = False
      OnMouseDown = PBPreviewMouseDown
      OnMouseMove = PBPreviewMouseMove
      OnMouseUp = PBPreviewMouseUp
      OnPaint = PBPreviewPaint
    end
  end
  object PrinterSetupDialog1: TPrinterSetupDialog
    Left = 104
    Top = 81
  end
  object PrintDialog1: TPrintDialog
    Options = [poPageNums, poWarning]
    Left = 64
    Top = 81
  end
end

object EditMatForm: TEditMatForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'EditMatForm'
  ClientHeight = 322
  ClientWidth = 526
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 120
  TextHeight = 16
  object Label1: TLabel
    Left = 224
    Top = 14
    Width = 80
    Height = 16
    Hint = 'mats can have up to 16 cells'
    Caption = 'Cells (LOD 0):'
    ParentShowHint = False
    ShowHint = True
  end
  object Label2: TLabel
    Left = 368
    Top = 14
    Width = 120
    Height = 16
    Hint = 'mats can have up to 3 mips for each cell'
    Caption = 'MIP chain (LOD 1-3):'
    ParentShowHint = False
    ShowHint = True
  end
  object Label3: TLabel
    Left = 8
    Top = 14
    Width = 75
    Height = 16
    Caption = 'Mat Preview:'
  end
  object CellsListBox: TListBox
    Left = 224
    Top = 36
    Width = 113
    Height = 153
    TabOrder = 0
    OnClick = CellsListBoxClick
  end
  object MipsListBox: TListBox
    Left = 368
    Top = 36
    Width = 113
    Height = 153
    TabOrder = 1
    OnClick = MipsListBoxClick
  end
  object Panel1: TPanel
    Left = 8
    Top = 36
    Width = 128
    Height = 128
    BevelInner = bvLowered
    TabOrder = 2
    object Image1: TImage
      Left = 2
      Top = 2
      Width = 124
      Height = 124
      Align = alClient
      Proportional = True
      Stretch = True
      ExplicitLeft = 0
      ExplicitTop = 28
    end
  end
  object OKButton: TButton
    Left = 229
    Top = 283
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 3
    OnClick = OKButtonClick
  end
  object Options: TGroupBox
    Left = 10
    Top = 195
    Width = 503
    Height = 82
    Caption = 'Options'
    TabOrder = 4
    object Label4: TLabel
      Left = 14
      Top = 21
      Width = 134
      Height = 16
      Caption = 'Internal bitmap format:'
    end
    object MipRadioGroup: TRadioGroup
      Left = 214
      Top = 23
      Width = 161
      Height = 46
      Caption = 'MIP maps to Auto-create'
      Columns = 4
      ItemIndex = 0
      Items.Strings = (
        '0'
        '1'
        '2'
        '3')
      TabOrder = 0
    end
    object AddCellButton: TButton
      Left = 396
      Top = 28
      Width = 75
      Height = 25
      Caption = 'Add Cell'
      TabOrder = 1
      OnClick = AddCellButtonClick
    end
    object FormatComboBox: TComboBox
      Left = 14
      Top = 43
      Width = 185
      Height = 24
      TabOrder = 2
      Text = 'Select Internal Format'
      OnClick = FormatComboBoxClick
      Items.Strings = (
        '8-bit '
        '8-bit Transparent'
        '16-bit 565'
        '16-bit 1555 Transparent'
        '16-bit 4444'
        '32-bit')
    end
  end
  object OpenPic: TOpenPictureDialog
    Left = 176
    Top = 112
  end
end

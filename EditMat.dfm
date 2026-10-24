object EditMatForm: TEditMatForm
  Left = 0
  Top = 0
  Margins.Left = 2
  Margins.Top = 2
  Margins.Right = 2
  Margins.Bottom = 2
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'EditMatForm'
  ClientHeight = 288
  ClientWidth = 419
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -10
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poMainFormCenter
  OnClose = FormClose
  OnShow = FormShow
  TextHeight = 12
  object Label1: TLabel
    Left = 179
    Top = 11
    Width = 63
    Height = 12
    Hint = 'mats can have up to 16 cells'
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Cells (LOD 0):'
    ParentShowHint = False
    ShowHint = True
  end
  object Label2: TLabel
    Left = 294
    Top = 11
    Width = 97
    Height = 12
    Hint = 'mats can have up to 3 mips for each cell'
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'MIP chain (LOD 1-3):'
    ParentShowHint = False
    ShowHint = True
  end
  object Label3: TLabel
    Left = 6
    Top = 11
    Width = 59
    Height = 12
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Mat Preview:'
  end
  object CellsListBox: TListBox
    Left = 179
    Top = 29
    Width = 91
    Height = 122
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    ItemHeight = 12
    TabOrder = 0
    OnClick = CellsListBoxClick
  end
  object MipsListBox: TListBox
    Left = 294
    Top = 29
    Width = 91
    Height = 122
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    ItemHeight = 12
    TabOrder = 1
    OnClick = MipsListBoxClick
  end
  object Panel1: TPanel
    Left = 6
    Top = 29
    Width = 103
    Height = 102
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    BevelInner = bvLowered
    TabOrder = 2
    object Image1: TImage
      Left = 2
      Top = 2
      Width = 99
      Height = 98
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Align = alClient
      Proportional = True
      Stretch = True
      ExplicitHeight = 99
    end
  end
  object OKButton: TButton
    Left = 182
    Top = 261
    Width = 60
    Height = 20
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 3
    OnClick = OKButtonClick
  end
  object Options: TGroupBox
    Left = 8
    Top = 156
    Width = 402
    Height = 93
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Caption = 'Options'
    TabOrder = 4
    object Label4: TLabel
      Left = 11
      Top = 17
      Width = 104
      Height = 12
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Caption = 'Internal bitmap format:'
    end
    object Label_Color: TLabel
      Left = 18
      Top = 67
      Width = 52
      Height = 12
      Caption = 'Solid color:'
    end
    object MipRadioGroup: TRadioGroup
      Left = 171
      Top = 18
      Width = 129
      Height = 37
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
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
      Left = 318
      Top = 14
      Width = 73
      Height = 20
      Hint = 'bmp must match internal format'
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Caption = 'Add Cell'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      OnClick = AddCellButtonClick
    end
    object FormatComboBox: TComboBox
      Left = 11
      Top = 34
      Width = 148
      Height = 20
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      TabOrder = 2
      Text = 'Select Internal Format'
      OnClick = FormatComboBoxClick
      Items.Strings = (
        '8-bit '
        '8-bit Transparent'
        '16-bit 565'
        '16-bit 1555 Transparent'
        '16-bit 4444 (custom engine)'
        '24-bit 888 (custom engine)'
        '32-bit 8888 (custom engine)'
        '16-bit 1555 Emissive (custom engine)'
        '16-bit 4444 Emissive (custom engine)'
        '16-bit 5551 Emissive (custom engine)')
    end
    object RemoveCellButton: TButton
      Left = 318
      Top = 38
      Width = 73
      Height = 20
      Hint = 'Removes selected cell'
      Margins.Left = 2
      Margins.Top = 2
      Margins.Right = 2
      Margins.Bottom = 2
      Caption = 'Remove Cell'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
      OnClick = RemoveCellButtonClick
    end
    object Edit_color: TEdit
      Left = 72
      Top = 60
      Width = 121
      Height = 20
      TabOrder = 4
      Text = '0'
    end
  end
  object OpenPic: TOpenPictureDialog
    Left = 176
    Top = 112
  end
end

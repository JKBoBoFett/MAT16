object Set8bitFormatForm: TSet8bitFormatForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Set 8bit Internal Format'
  ClientHeight = 259
  ClientWidth = 609
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 120
  TextHeight = 16
  object Save_OptionsRadioGroup: TRadioGroup
    Left = 24
    Top = 16
    Width = 545
    Height = 137
    Caption = 'Format Options'
    ItemIndex = 0
    Items.Strings = (
      '8 bit texture'
      '8 bit texture transparent'
      
        '8 bit texture with internal CMP  (experimental, not supported in' +
        ' Jedi Knight)'
      
        '8 bit texture transparent with internal CMP  (experimental, not ' +
        'supported in Jedi Knight)')
    TabOrder = 0
  end
  object OKBtn: TButton
    Left = 192
    Top = 174
    Width = 161
    Height = 53
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
    OnClick = OKBtnClick
  end
end

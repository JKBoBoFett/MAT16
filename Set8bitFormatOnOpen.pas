unit Set8bitFormatOnOpen;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, MATImage;

type
  TSet8bitFormatForm = class(TForm)
    Save_OptionsRadioGroup: TRadioGroup;
    OKBtn: TButton;
    procedure OKBtnClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    MatFormat:TFormat;
    fmt:string;
  end;

var
  Set8bitFormatForm: TSet8bitFormatForm;

implementation

{$R *.dfm}

procedure TSet8bitFormatForm.OKBtnClick(Sender: TObject);
begin
 if Save_OptionsRadioGroup.ItemIndex = 0 then
      begin
       MatFormat:=Tformat.INDEX;
       fmt:='8-bit INDEXED';
      end;
  if Save_OptionsRadioGroup.ItemIndex = 1 then
      begin
       MatFormat:=Tformat.INDEXT;
       fmt:='8-bit trans INDEXED';
      end;
  if Save_OptionsRadioGroup.ItemIndex = 2 then
      begin
       MatFormat:=Tformat.INDEXCMP;
       fmt:='8-bit INDEXED int CMP';
      end;
  if Save_OptionsRadioGroup.ItemIndex = 3 then
      begin
       MatFormat:=Tformat.INDEXTCMP;
       fmt:='8-bit INDEXED trans int CMP';
      end;
end;

end.

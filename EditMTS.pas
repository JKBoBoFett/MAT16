unit EditMTS;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtDlgs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TEditMTSForm = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    CellsListBox: TListBox;
    MipsListBox: TListBox;
    Panel1: TPanel;
    Image1: TImage;
    OKButton: TButton;
    Options: TGroupBox;
    Label4: TLabel;
    MipRadioGroup: TRadioGroup;
    AddCellButton: TButton;
    FormatComboBox: TComboBox;
    OpenPic: TOpenPictureDialog;
    LoadButton: TButton;
    procedure LoadButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  EditMTSForm: TEditMTSForm;

implementation

{$R *.dfm}

procedure TEditMTSForm.LoadButtonClick(Sender: TObject);
var
 Txt: TextFile;
 s,gpath:string;
 Splitted: TArray<String>;
begin
  OpenPic.Filter:='mat16 script|*.mat16s;';

if Openpic.Execute then
  begin
   gpath := ExtractFilePath(OpenPic.filename);
  AssignFile(Txt, OpenPic.filename);
  Reset(Txt);

  while not Eof(Txt) do
  begin
   Readln(Txt, s);

  end;

  CloseFile(Txt);
  end;

end;

end.

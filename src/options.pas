 unit options;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Registry, ComCtrls;

type
  TOptionsForm = class(TForm)
    OKBUT: TButton;
    Edit_Container: TEdit;
    Label_Container: TLabel;
    Button_ContainerBrowse: TButton;
    OpenDialog1: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    function SetOptions: boolean;
    procedure FormShow(Sender: TObject);
    procedure OKBUTClick(Sender: TObject);
    procedure readoptions;
    procedure Button_ContainerBrowseClick(Sender: TObject);
    function  GetContainerPath:string;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

const
  RegBase = '\Software\Jedi Dreams\Mat16';

var
  OptionsForm: TOptionsForm;
  NoRegEntry: boolean;
  Reg: TRegistry;

implementation

uses Main;

{$R *.DFM}


function TOptionsForm.SetOptions: boolean;
var
  reg: TRegistry;
begin
  Result := False;

  Reg := TRegistry.Create;
  Reg.OpenKey(RegBase, True);

   reg.WriteString('CON_PATH', Edit_Container.Text);

  Reg.Free;
  Result := True;
end;

procedure TOptionsForm.FormCreate(Sender: TObject);
begin

  if NoRegEntry then
  begin
    if SetOptions then exit;
  end;
    readoptions;

end;

procedure TOptionsForm.readoptions;
var
  reg: TRegistry;
begin
  Reg := TRegistry.Create;
  Reg.OpenKey(RegBase, True);

  Edit_Container.Text:= Reg.ReadString('CON_PATH');

  Reg.Free;
end;

function TOptionsForm.GetContainerPath:string;
var
  reg: TRegistry;
begin
  Reg := TRegistry.Create;
  Reg.OpenKey(RegBase, True);

  Result:= Reg.ReadString('CON_PATH');

  Reg.Free;
end;

procedure TOptionsForm.FormShow(Sender: TObject);
begin
  readoptions;
end;


procedure TOptionsForm.OKBUTClick(Sender: TObject);
begin
  SetOptions;
  hide;
end;

procedure TOptionsForm.Button_ContainerBrowseClick(Sender: TObject);
begin
 if OpenDialog1.Execute then
  begin

    if UpperCase(ExtractFileExt(OpenDialog1.FileName)) = '.GOB' then
    begin
    Edit_Container.Text:= OpenDialog1.FileName

    end;

    if UpperCase(ExtractFileExt(OpenDialog1.FileName)) = '.GOO' then
    begin
      Edit_Container.Text:= OpenDialog1.FileName
    end;

     if UpperCase(ExtractFileExt(OpenDialog1.FileName)) = '.BAF' then
    begin
      Edit_Container.Text:= OpenDialog1.FileName
    end;
  end;
end;

end.

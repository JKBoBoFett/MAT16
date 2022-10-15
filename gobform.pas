unit gobform;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls,  main, util, gobgoo,ColorMap,CMPHeaders,MATImage,BMParrays,StrUtils;

type
  Tbafinfo = array[0..50] of record
    mat:    string;
    offset: integer;
  end;

  Tgobview = class(TForm)
    ListBox1:  TListBox;
    Label_FileName: TLabel;
    GroupBox1: TGroupBox;
    Label_SelectedFile: TLabel;
    Label_Offset: TLabel;
    Label7:    TLabel;
    Label8:    TLabel;
    Label10:   TLabel;
    Label11:   TLabel;
    Label12:   TLabel;
    Label13:   TLabel;
    Panel1:    TPanel;
    Image1:    TImage;
    Label14:   TLabel;
    Button1:   TButton;
    Label15:   TLabel;
    Label16:   TLabel;
    Label17:   TLabel;
    Button2:   TButton;
    Label18:   TLabel;
    Label_CMP: TLabel;
    procedure ListBox1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure opengob(filename: string);
    procedure openbaf(filename: string);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  gobview: Tgobview;
  bafinfo: Tbafinfo;
  FileOffsets: TFileOffsets;
  CMPOffsets: TFileOffsets;

implementation

uses Batch;

{$R *.DFM}

procedure Tgobview.ListBox1Click(Sender: TObject);
var
  i,pos: integer;
  Mat: TMAT;
  BMPArray: TBMPARRAY;
  bestcmp:string;
  gobname:string;
  tempA:TBMPArray;
  gobCMP:TCMP;
begin
  gobCMP:=TCMP.create;

  if (UpperCase(ExtractFileExt(Label_FileName.Caption)) = '.GOB') or
     (UpperCase(ExtractFileExt(Label_FileName.Caption)) = '.GOO') or
     (UpperCase(ExtractFileExt(Label_FileName.Caption)) = '.BAF') then
  begin

  for i := 0 to (ListBox1.Items.Count - 1) do
    begin
      if ListBox1.Selected[i] then
      begin
        Label_SelectedFile.Caption := ListBox1.Items.Strings[i];
      end;
    end;

   //load jk or mots cmp
   if (UpperCase(ExtractFileExt(Label_FileName.Caption)) = '.GOB') or
     (UpperCase(ExtractFileExt(Label_FileName.Caption)) = '.GOO') then
     begin
     bestcmp    := GetbestCMP(Label_SelectedFile.Caption, JKPath);
     Label_CMP.Caption:= bestcmp;
     pos:=GetGOBArrayOffset(CMPOffsets, bestcmp);
     gobCMP.LoadCMPFromFile(jkpath, pos);
     end;

   if (UpperCase(ExtractFileExt(Label_FileName.Caption)) = '.BAF') then
     begin
     gobCMP.LoadCMPFromBAFFile(Label_FileName.Caption, 336);
     end;

   Mat:=TMAT.Create(TFormat.BMP);
   Mat.SetCMP(gobCMP.GetRGB);

  // pos:=GetGOBFileOffset(Label_FileName.Caption,Label_SelectedFile.Caption);
   pos:=GetGOBArrayOffset(FileOffsets, Label_SelectedFile.Caption);
   Label_Offset.Caption := IntToStr(pos);
   tempA:= Mat.LoadFromFile(Label_FileName.Caption,pos);

  // image1.Picture.Bitmap.Assign(BMPArray.GetCell(0));

   label16.Caption := IntToStr(tempA.GetX);
   label17.Caption := IntToStr(tempA.GetY);

   label15.Caption:=tempA.fmt;

   main.MainForm.BMPArrayDisplay(tempA, Mat);
   gobCMP.Free;
   //Mat.free;
   //BMPArray.Free;
  end;

end;

procedure Tgobview.FormShow(Sender: TObject);
//var i:integer;
begin
  if not image1.Picture.bitmap.Empty then
    image1.Picture.Bitmap := nil;

  label14.Caption := IntToStr(ListBox1.Items.Count);
end;

 procedure Tgobview.openbaf(filename: string);
 var
 tempList:Tstringlist;
 begin
 FileOffsets:=bafFilesToArray(filename, '.MAT');
 tempList:=gobFileArrayToList(FileOffsets);
 ListBox1.Items.Assign(tempList);
tempList.Free;

 end;

procedure Tgobview.opengob(filename: string);
var
tempList:Tstringlist;
//FileOffsets: TFileOffsets;
begin
//tempList:=gobFilesToList(filename, '.MAT');
FileOffsets:=gobFilesToArray(filename, '.MAT');
CMPOffsets:=gobFilesToArray(jkpath, '.CMP');
tempList:=gobFileArrayToList(FileOffsets);
ListBox1.Items.Assign(tempList);
tempList.Free;
end;

procedure Tgobview.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  listbox1.Clear;
end;

procedure Tgobview.Button1Click(Sender: TObject);
begin
  main.MainForm.Image1.Picture.Bitmap.Assign(image1.Picture.Bitmap);
 // main.MainForm.LabelWidth.Caption := Label6.Caption;
  main.MainForm.LabelHeight.Caption := Label17.Caption;
  main.MainForm.LabelFormat.Caption := label15.Caption;
  main.MainForm.Label3.Caption := '1';
  image1.Picture.Bitmap.FreeImage;
  listbox1.Clear;
  gobview.Close;
end;

procedure Tgobview.Button2Click(Sender: TObject);
var
  i: integer;
  savebitmap: Tbitmap;
  bestcmp, gpath, mpath, fext, mname: string;
begin
 // savebitmap := Tbitmap.Create;
  gpath := ExtractFilePath(Label_FileName.Caption);
  fext  := ExtractName(Label_FileName.Caption);
  fext  := ChangeFileExt(fext, '');
  gpath := gpath + fext;
  Screen.Cursor := crHourGlass;
  CreateDir(gpath);
  BatchForm.Show;

  BatchForm.ProgressBar1.Max := ListBox1.Items.Count;


  for i := 0 to (ListBox1.Items.Count - 1) do
  begin
    BatchForm.ProgressBar1.Position := i;
    //savebitmap := Tbitmap.Create;
    //savebitmap:=nil;
    bestcmp    := GetbestCMP(listBox1.Items.Strings[i], Label_FileName.Caption);
 //   ReadCMPfromGOB(Label_FileName.Caption, bestcmp);
    mainform.gridPalette.Repaint;

 //   saveBitmap:=ReadMatfromGOB(Label_FileName.Caption, listBox1.Items.Strings[i]);
    mname      := ExtractName(listBox1.Items.Strings[i]);
    mname      := ChangeFileExt(mname, '.BMP');
    mpath      := gpath + '\' + mname;
    saveBitmap.SaveToFile(mpath);

    BatchForm.Memo1.Lines.Add('Saved ' + mpath + ' cmp:' + bestcmp);
    application.ProcessMessages;

    saveBitmap.Free;

  end;

  BatchForm.Memo1.Lines.Add('-Done-');
  Screen.Cursor := crDefault;

  //if Assigned(saveBitmap) then saveBitmap.Free;
end;

end.

unit SaveDLGUnit;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, mat_read, MATImage;

type
  TMATSaveDlg = class(TForm)
    OKBtn:  TButton;
    GroupBox1: TGroupBox;
    Save_OptionsRadioGroup: TRadioGroup;
    mipCheckBox1: TCheckBox;
    DitherRadioGroup1: TRadioGroup;
    procedure OKBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure mipCheckBox1Click(Sender: TObject);
    procedure Save_OptionsRadioGroupClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MATSaveDlg:  TMATSaveDlg;
  MatFileName: string;
// SaveChild: TMDIChild;

implementation

uses MAIN;

{$R *.dfm}

procedure TMATSaveDlg.OKBtnClick(Sender: TObject);
var
Mat: TMAT;
I: Integer;
bmap:Tbitmap;
begin
bmap:=Tbitmap.Create;
  if isbatch then
  begin
    MainForm.DoBatchConvert();
  end;

  if not isbatch then
  begin
    if main.MainForm.Cell_ImageList.Count > 1 then
      begin
     // ImageListtoMat16(main.MainForm.image1.Picture.Bitmap, main.MainForm.Cell_ImageList,
     //   main.MainForm.SaveDialog.FileName, DitherRadioGroup1.ItemIndex);
      end;




      if Save_OptionsRadioGroup.ItemIndex = 1 then
      begin
        Mat:=TMAT.Create(TFormat.INDEX);

        for I:= 0 to main.MainForm.Cell_ImageList.Count - 1 do
          begin
          bmap.PixelFormat:=pf8bit;
          bmap.HandleType :=   bmDIB;
          main.MainForm.Cell_ImageList.GetBitmap(I,bmap);
          Mat.AddCellFromBMP(BMParray.GetCell(0));
          end;
        Mat.SaveMat(main.MainForm.SaveDialog.FileName);
        Mat.Free;
        bmap.Free;
      end;


      if Save_OptionsRadioGroup.ItemIndex = 5 then
      begin
        Mat:=TMAT.Create(TFormat.RGB565);

        for I:= 0 to main.MainForm.Cell_ImageList.Count - 1 do
          begin
          main.MainForm.Cell_ImageList.GetBitmap(I,bmap);
          Mat.AddCellFromBMP(bmap);
          end;
        Mat.SaveMat(main.MainForm.SaveDialog.FileName);
        Mat.Free;
        bmap.Free;
      end;
//    if not CheckBox_32bit.Checked then
//       begin
//      BmptoMat16(main.MainForm.Image1.Picture.Bitmap, main.MainForm.SaveDialog.FileName,
//        Save_OptionsRadioGroup.ItemIndex, DitherRadioGroup1.ItemIndex);
//        end;
//    if CheckBox_32bit.Checked then
//       begin
//        BmptoMat16(main.MainForm.Image1.Picture.Bitmap, main.MainForm.SaveDialog.FileName,
//         4, DitherRadioGroup1.ItemIndex);
//        end;



    MATSaveDlg.Hide;
  end;
  isbatch := False;
end;

procedure TMATSaveDlg.FormShow(Sender: TObject);
begin
 // mipCheckBox1.Checked := Optionsform.CheckBox1.Checked;
end;

procedure TMATSaveDlg.mipCheckBox1Click(Sender: TObject);
begin
//  if mipCheckBox1.Checked then
//    Optionsform.CheckBox1.Checked := True
//
//  else
//    Optionsform.CheckBox1.Checked := False;
//
//
//  if mipCheckBox1.Checked then
//    Save_OptionsRadioGroup.ItemIndex := 1;

end;

procedure TMATSaveDlg.Save_OptionsRadioGroupClick(Sender: TObject);
begin
  if Save_OptionsRadioGroup.ItemIndex = 0 then
    mipCheckBox1.Checked := False;
end;

end.
unit Main;

interface

uses
  SysUtils, Windows, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, ImgList, Menus, Grids, ComCtrls, ExtCtrls,
  Buttons, ToolWin, ExtDlgs, Util, clipbrd, ShellAPI,
   gobgoo, Registry, SaveDLGUnit, adpMRU,
  System.ImageList,MATImage,BMParrays,ColorMap,MATHeaders,CMPHeaders, System.IOUtils,StrUtils,Set8bitFormatOnOpen,BMP_IO;

type
  TMainForm = class(TForm)
    MainMenu: TMainMenu;
    FileOpenItem: TMenuItem;
    FileSaveItem: TMenuItem;
    FileExitItem: TMenuItem;
    HelpAboutItem: TMenuItem;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    StatusBar1: TStatusBar;
    ToolBar1: TToolBar;
    Panel1:  TPanel;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    N1:      TMenuItem;
    BatchConvertBMPs1: TMenuItem;
    OpenDialogBatch: TOpenDialog;
    SpeedButton4: TSpeedButton;
    PopupMenu1: TPopupMenu;
    GroupBox2: TGroupBox;
    Label1:  TLabel;
    Label4:  TLabel;
    LabelHeight: TLabel;
    LabelWidth: TLabel;
    Label7:  TLabel;
    LabelFormat: TLabel;
    Label2:  TLabel;
    Label3:  TLabel;
    Cell_TrackBar: TTrackBar;
    N5:      TMenuItem;
    Label16: TLabel;
    Label17: TLabel;
    OpenDialogcmp: TOpenDialog;
    PopupMenu2: TPopupMenu;
    LoadCMP1: TMenuItem;
    N7:      TMenuItem;
    BackGroundColor1: TMenuItem;
    ColorDialog1: TColorDialog;
    N8:      TMenuItem;
    LoadColorMapCMP1: TMenuItem;
    Tools1:  TMenuItem;
    AddCell1: TMenuItem;
    OpenGOBGOO1: TMenuItem;
    OpenDialog1: TOpenDialog;
    Label18: TLabel;
    ScrollBox1: TScrollBox;
    Image1:  TImage;
    SaveCMPas1: TMenuItem;
    SaveCMP: TSaveDialog;
    ViewTiled1: TMenuItem;
    GroupBox1: TGroupBox;
    ViewasTransparent1: TMenuItem;
    ViewTiled2: TMenuItem;
    CloseImage1: TMenuItem;
    N3:      TMenuItem;
    Panel2:  TPanel;
    Zoom1:   TMenuItem;
    In1:     TMenuItem;
    Out1:    TMenuItem;
    Home1:   TMenuItem;
    ViewMessages1: TMenuItem;
    OpenPic: TOpenPictureDialog;
    Reopen: TMenuItem;
    BatchConvertMATBMP1: TMenuItem;
    Button1: TButton;
    ToolButton1: TToolButton;
    Mip_TrackBar: TTrackBar;
    LabelIndex: TLabel;
    Shape1: TShape;
    LabelRGB: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Options1: TMenuItem;
    gridPalette: TDrawGrid;
    GroupBox3: TGroupBox;
    Edit_LightLevel: TEdit;
    UpDown_LightLevel: TUpDown;
    GroupBox4: TGroupBox;
    ComboBox1: TComboBox;
    N2: TMenuItem;
    N6: TMenuItem;
    N9: TMenuItem;
    Createnewmatfrombmps1: TMenuItem;  { Save &As... }
    procedure FileOpen(Sender: TObject);
    procedure FileSaveAs(Sender: TObject);
    procedure FileExit(Sender: TObject);
    procedure HelpAbout(Sender: TObject);
    procedure matopen(filename: string);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
    procedure BatchConvertBMPs1Click(Sender: TObject);
    procedure SaveDialogTypeChange(Sender: TObject);
    procedure Options1Click(Sender: TObject);
    procedure Cell_TrackBarChange(Sender: TObject);
    procedure Color16BitMat1Click(Sender: TObject);
    procedure ColorMat1Click(Sender: TObject);
    procedure AddCellClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure gridPaletteDrawCell(Sender: TObject; Col, Row: integer;
      Rect: TRect; State: TGridDrawState);
    procedure FormShow(Sender: TObject);
    procedure LoadCMP1Click(Sender: TObject);
    procedure BackGroundColor1Click(Sender: TObject);
    procedure formresetinfo;
    procedure OpenGOBGOO1Click(Sender: TObject);
    procedure SaveCMPas1Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure ViewTiled1Click(Sender: TObject);
    procedure ViewasTransparent1Click(Sender: TObject);
    procedure CloseImage1Click(Sender: TObject);
    procedure FormShortCut(var Msg: TWMKey; var Handled: boolean);
    procedure In1Click(Sender: TObject);
    procedure Out1Click(Sender: TObject);
    procedure Home1Click(Sender: TObject);
    procedure DoBatchConvert;
    procedure ViewMessages1Click(Sender: TObject);
    procedure adpMRUClick(Sender: TObject; const Filename: String);
    procedure OpenImage(Filename: String);
    procedure BatchConvertMATBMP1Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Mip_TrackBarChange(Sender: TObject);
    procedure UpDown_LightLevelClick(Sender: TObject; Button: TUDBtnType);
    procedure SetLightLevel(level:integer);
    procedure BMPArrayDisplay(BMPA:TBMPArray; Mat:TMAT);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Draw8bitImageOnGrid(bmp:Tbitmap);
    procedure Draw16bitImageOnGrid(bmp:Tbitmap);
    procedure Draw32bitImageOnGrid(bmp:Tbitmap);
    procedure updateCMPcomboBox(container:string);
    procedure TrackBarChange;
    procedure Createnewmatfrombmps1Click(Sender: TObject);
  end;

var
  MainForm:  TMainForm;
  Bitmap:    TBitmap;
  animcnt:   integer;
  numframes: integer;
  savefname: string;
  addcell:   boolean;
  jkpath:    string;
  motspath:  string;
  isbatch:   boolean;
   adpMRU: TadpMRU;
  BMPArray: TBMPARRAY;
  MainCMP:TCMP;
  CMPOffsets: TFileOffsets;
implementation

uses about_unit, Batch,
   gobform, ViewtileUnit, mess_frm,options, EditMat;

{$R *.DFM}


procedure TMainForm.FileOpen(Sender: TObject);
begin
  OpenPic.Filter     :=
    'mat files |*.MAT;*.MAT16S;|mat texture (*.mat)|*.MAT|mat16 script with bitmaps|*mat16s';

  if OpenPic.Execute then
       OpenImage(OpenPic.FileName);

end;


procedure TmainForm.matopen(filename: string);
var
  Mat: TMAT;
  tempA:TBMPArray;

begin
  Cell_TrackBar.Position := 0;
  image1.Repaint;

  Mat:=TMAT.Create(TFormat.BMP);
  Mat.SetCMP(MainCMP.GetRGB);
  tempA:= Mat.LoadFromFile(filename);

  BMPArrayDisplay(tempA,Mat); //function frees resources

end;

procedure TMainForm.BMPArrayDisplay(BMPA:TBMPArray; Mat:TMAT);
var
tempBMP:TBitmap;
MatInfoList:Tstringlist;
 //gridBMP:tbitmap;
begin
  Cell_TrackBar.Position := 0;
  Mip_TrackBar.Position := 0;
  if Assigned(image1.Picture.Bitmap) then image1.Picture.Bitmap.Assign(nil);
  Image1.Picture:=nil;
  image1.Repaint;

  BMPArray.Assign(BMPA);
    tempBMP:=(BMPArray.GetCell(0));

    if (Mat.GetMatFormat=(TFormat.RGBA4444)) or (Mat.GetMatFormat=(TFormat.RGBA5551))  then
    begin
    tempBMP:=(BMPArray.GetAlphaCellForDisplay(0));
    Draw32bitImageOnGrid(tempBMP);
    end;

  if Mat.GetMatFormat=(TFormat.ARGB1555) then
    begin
    Draw16bitImageOnGrid(tempBMP);
    if tempBMP.PixelFormat =pf8bit then
    begin
      Image1.Picture:=nil;
    end;

    end;

  if Mat.GetMatFormat=(TFormat.RGB565) then
     begin
     Image1.Picture.Bitmap.Assign(tempBMP);
     if tempBMP.PixelFormat =pf8bit then
    begin
      Image1.Picture:=nil;
    end;
     end;

  if Mat.GetMatFormat=(TFormat.INDEXT) then
     begin
     MainCMP.SetRGB(BMPArray.GetCMP);
     MainCMP.HasLightTable:=true;
     gridPalette.Repaint;
     Draw8bitImageOnGrid(tempBMP);
     end;

  if Mat.GetMatFormat=(TFormat.INDEX) then
     begin
     MainCMP.SetRGB(BMPArray.GetCMP);
     MainCMP.HasLightTable:=true;
     gridPalette.Repaint;
     Image1.Picture.Bitmap.Assign(tempBMP);
     end;


  if Mat.GetMatFormat=(TFormat.COLOR8) then
     Image1.Picture.Bitmap.Assign(tempBMP);

  if Mat.GetMatFormat=(TFormat.INDEXTCMP) then
      begin
      MainCMP.SetRGB(BMPArray.GetCMP);
      MainCMP.HasLightTable:=false;
      gridPalette.Repaint;
      Draw8bitImageOnGrid(tempBMP);
      end;
  if Mat.GetMatFormat=(TFormat.INDEXCMP) then
     begin
     MainCMP.SetRGB(BMPArray.GetCMP);
     MainCMP.HasLightTable:=false;
     gridPalette.Repaint;
     Image1.Picture.Bitmap.Assign(tempBMP);
     end;

    bitmap.Assign(tempBMP);


 //  gridBMP.SaveToFile('D:\TestBMP\lastgrid.bmp');

//    Image1.Picture.Bitmap:= tempBMP;




  Panel2.Width:=Image1.Picture.Bitmap.Width;
  Panel2.Height:=Image1.Picture.Bitmap.Height;
  Label3.Caption:=Inttostr(BMPArray.GetCellCount);
  Label17.Caption:=Inttostr(BMPArray.GetMipCount);

 //  mess.Memo1.lines.Add(filename);
   MatInfoList:= Mat.HeadersToJSON;
   mess.Memo1.lines.AddStrings(MatInfoList);

   Cell_TrackBar.max := BMParray.GetCellCount-1;
   Mip_TrackBar.Max := BMParray.GetMipCount;

   LabelHeight.Caption := IntToStr(BMParray.GetY);
   LabelWidth.Caption := IntToStr(BMParray.GetX);

   LabelFormat.Caption:=BMParray.fmt;

   BMPA.Free;
   MatInfoList.Free;
   Mat.Free;
   tempBMP.Free;

end;
 procedure TMainForm.TrackBarChange;
 var
tmpBMP:Tbitmap;
begin
 if BMPArray.GetCellCount <> 0 then
 begin
   tmpBMP:=(BMPArray.GetBMP(Cell_TrackBar.Position,Mip_TrackBar.Position));

   if (tmpBMP.PixelFormat = pf32bit)  then
       Draw32bitImageOnGrid(tmpBMP);

   if (tmpBMP.PixelFormat = pf16bit)  then
       image1.picture.Bitmap.Assign(tmpBMP);

   if (bitmap.PixelFormat = pfCustom)  then //ARGB1555
       Draw16bitImageOnGrid(tmpBMP);

   if (tmpBMP.PixelFormat = pf8bit)  then
      begin
       if BMPArray.isTransparent then
         Draw8bitImageOnGrid(tmpBMP)
       else
       image1.picture.Bitmap.Assign(tmpBMP);
      end;

   bitmap.Assign(tmpBMP);
   tmpBMP.Free;
    tmpBMP:=nil;
   end;
end;

procedure TMainForm.Mip_TrackBarChange(Sender: TObject);
//var
//tmpBMP:Tbitmap;
begin
 if label17.Caption <> '0'  then
  begin
    SetLightLevel(63);
    Image1.Picture:=nil;
    TrackBarChange;
  end;

  image1.Repaint;

end;

procedure TMainForm.FileSaveAs(Sender: TObject);
 var
Mat: TMAT;
begin
  Screen.Cursor := crHourGlass;
  SaveDialog.FileName := ChangeExt(OpenDialog.FileName, '');
  if SaveDialog.Execute then
  begin
    if UpperCase(ExtractFileExt(SaveDialog.FileName)) = '.MAT' then
    begin
       // MATSaveDlg.Show;
       Mat:=TMAT.CreateFromBMPArray(BMPArray);
       Mat.SaveMat(main.MainForm.SaveDialog.FileName);
       Mat.free;
    end;

    if UpperCase(ExtractFileExt(SaveDialog.FileName)) = '.BMP' then
    begin
      image1.picture.bitmap.SaveToFile(SaveDialog.FileName);
    end;

    if UpperCase(ExtractFileExt(SaveDialog.FileName)) = '.MAT16S' then
    begin
      BMPArray.SaveMTS(SaveDialog.FileName);
    end;

  end;
  StatusBar1.Panels[1].Text := '';
  StatusBar1.Panels[1].Text := 'Saved ' + ExtractFileName(SaveDialog.FileName);
  Screen.Cursor := crDefault;

end;


procedure TMainForm.FileExit(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.HelpAbout(Sender: TObject);
begin
  AboutBox.ShowModal;
end;

procedure TMainForm.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if [ssLeft] = Shift then
  begin
//    image1.Picture.Bitmap.TransparentMode:=
//    image1.Repaint;
  end;
end;

procedure TMainForm.Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
const
  PixelCountMax = 65536;  // 2048 MAX WIDTH
type
PWordArray = ^TWordArray;
  TWordArray = packed array[0..16383] of Word;

  TRGBQuadArray = packed array[0..PixelCountMax - 1] of TRGBQuad;
  pRGBQuadArray = ^TRGBQuadArray;
var
  TargetColor: TColor;
  xActual:     double;
  yActual:     double;
  index,scaledX,scaledY: integer;
  Row: pByteArray;
  row16:PWordArray;
  inrow32: pRGBQuadArray;
  R,G,B,A:Integer;
  src16:word;
  PalEntry:  TPaletteEntry;

begin
  xActual := X;
  yActual := Y;
   R:=0;
   G:=0;
   B:=0;
   A:=-1;
   index:=-1;
   TargetColor:=0;

  if Image1.Picture.Bitmap.Height <> 0 then
   begin
  //xy semms to be fliped from bitmap xy
   scaledY:=Trunc(yActual / (((Image1.Height)*1.0) / ((Image1.Picture.Bitmap.Height)*1.0)));
   scaledX:=Trunc(xActual / (((Image1.Width)*1.0) / ((Image1.Picture.Bitmap.Width)*1.0)));

   if Image1.Picture.Bitmap.PixelFormat = pf8bit then
    begin
     Row := bitmap.ScanLine[scaledY];
     index:=Row[scaledX];

     GetPaletteEntries(bitmap.Palette, index, 1,PalEntry);
     R:= PalEntry.peRed;
     G:= PalEntry.peGreen;
     B:= PalEntry.peBlue;

     TargetColor:=rgb(PalEntry.peRed,PalEntry.peGreen,PalEntry.peBlue);
    end;

    labelindex.Caption :=IntToStr(index);

   if Image1.Picture.Bitmap.PixelFormat = pf16bit then
   begin
    TargetColor := Image1.Picture.Bitmap.Canvas.Pixels[scaledX, scaledY];
    Shape1.Brush.Color := TargetColor;

    if imageformat =   TFormat.RGB565 then
    begin
      Row16 := Image1.Picture.Bitmap.ScanLine[scaledY];
      src16:=Row16[scaledX];

      R:= ((src16 and 63488) shr 11);
      G:= ((src16 and 2016) shr 5);
      B:= ((src16 and 31) shr 0);
    end;

   end;

   if Image1.Picture.Bitmap.PixelFormat = pfCustom then
    begin
      TargetColor := bitmap.Canvas.Pixels[scaledX, scaledY];
      Shape1.Brush.Color := TargetColor;

      if imageformat =   TFormat.ARGB1555 then
      begin
        Row16 := bitmap.ScanLine[scaledY];
        src16:=Row16[scaledX];

        A:= ((src16 and 32768) shr 15);
        R:= ((src16 and 31744) shr 10);
        G:= ((src16 and 992) shr 5);
        B:= ((src16 and 31) shr 0);
      end;

    end;

   if bitmap.PixelFormat = pf32bit then
    begin

    if imageformat =   TFormat.RGBA4444 then
    begin
      inrow32 := bitmap.ScanLine[scaledY];

      R := inrow32[scaledX].rgbRed shr 4;
      G := inrow32[scaledX].rgbGreen shr 4;
      B := inrow32[scaledX].rgbBlue shr 4;
      A := inrow32[scaledX].rgbReserved shr 4;

      TargetColor:=rgb(inrow32[scaledX].rgbRed,
      inrow32[scaledX].rgbGreen,
      inrow32[scaledX].rgbBlue);
    end;

    if imageformat =   TFormat.RGBA5551 then
    begin
      inrow32 := bitmap.ScanLine[scaledY];

      R := inrow32[scaledX].rgbRed shr 5;
      G := inrow32[scaledX].rgbGreen shr 5;
      B := inrow32[scaledX].rgbBlue shr 5;
      A := inrow32[scaledX].rgbReserved shr 7;

      TargetColor:=rgb(inrow32[scaledX].rgbRed,
      inrow32[scaledX].rgbGreen,
      inrow32[scaledX].rgbBlue);
    end;
  end;

    Shape1.Brush.Color := TargetColor;

    labelRGB.Caption    := IntToStr(R) +', '+
                           IntToStr(G) +', '+
                           IntToStr(B) +', '+
                           IntToStr(A);

    StatusBar1.Panels[0].Text :=
    '(' + IntToStr(scaledX) + ', ' + IntToStr(scaledY) + ')';
   end;
end;

procedure TMainForm.DoBatchConvert;
var
  I:    integer;
  BatchBitmap: TBitmap;
  savename: string;
  StartTime, EndTime: DWORD;
begin
  MATSaveDlg.hide;
 // optionsform.readoptions;

  if OpenDialogBatch.Execute then
  begin
    Screen.Cursor := crHourGlass;

    BatchForm.ProgressBar1.Position := 0;
    BatchForm.Show;

    BatchForm.Memo1.Lines.Clear;
    BatchForm.Memo1.Lines.Add(IntToStr(OpenDialogBatch.Files.Count) +
      ' File(s) selected to convert');


    BatchForm.ProgressBar1.Max := OpenDialogBatch.Files.Count;
    starttime := GetTickCount;
    for I := 0 to OpenDialogBatch.Files.Count - 1 do
    begin
      if UpperCase(ExtractFileExt(OpenDialogBatch.Files[I])) = '.BMP' then
      begin
        //MATSaveDlg.Show;
         BatchBitmap := TBitmap.Create;
        application.ProcessMessages;


       // if optionsform.checkbox4.Checked then
        //         BatchBitmap:=BMP_Open(OpenDialogBatch.Files[I])

     // else

     // BatchBitmap.LoadFromFile(OpenDialogBatch.Files[I]);


      //  BatchBitmap.Assign(BMP_Open(OpenDialogBatch.Files[I]));
       //  BatchBitmap.LoadFromFile(OpenDialogBatch.Files[I]);
        BatchBitmap.PixelFormat := pf24bit;

        savename := ChangeExt(OpenDialogBatch.Files[I], '.mat');


//       // if optionsform.checkbox2.Checked = True then
//          BmptoMat16(checkBMPsize(BatchBitmap), savename,
//            SaveDLGUnit.MATSaveDlg.Save_OptionsRadioGroup.ItemIndex,
//            SaveDLGUnit.MATSaveDlg.DitherRadioGroup1.ItemIndex);
//
//       // if optionsform.checkbox2.Checked = False then
//          BmptoMat16(BatchBitmap, savename,
//            SaveDLGUnit.MATSaveDlg.Save_OptionsRadioGroup.ItemIndex,
//            SaveDLGUnit.MATSaveDlg.DitherRadioGroup1.ItemIndex);


        BatchForm.Memo1.Lines.Add('Saved ' + ExtractFileName(savename));
        BatchForm.ProgressBar1.Position := I + 1;


         BatchBitmap.Free;

      end;
    end;
    endtime := GetTickCount;
    //BatchForm.Memo1.Lines.Add('-Done-');
    BatchForm.Memo1.Lines.Add('-Done- ' + IntToStr(EndTime - StartTime) + ' mS');
    Screen.Cursor := crDefault;
  end;

end;

procedure TMainForm.BatchConvertBMPs1Click(Sender: TObject);
//var
//  I, Count:    integer;
//  BatchBitmap: TBitmap;
//  savename, mcfname: string;
//  StartTime, EndTime: DWORD;
begin
  // isbatch:=TRUE;

  MATSaveDlg.Show;
  isbatch := True;

end;


procedure TMainForm.BatchConvertMATBMP1Click(Sender: TObject);

 var
  i,j,k: integer;
  savebitmap: Tbitmap;
  bestcmp, gpath, mpath, fext, mname: string;
//  f: file;
  Mat: TMAT;
 //  matFormatHeader:TMatHeader;
   pos:longint;
   tempA:TBMPArray;
   MatInfoList:Tstringlist;
begin

OpenDialogBatch.Filter     :=
    'mat texture (*.mat)|*.MAT';
 // savebitmap := Tbitmap.Create;
  gpath := ExtractFilePath(label1.Caption);
  fext  := ExtractName(label1.Caption);
  fext  := ChangeFileExt(fext, '');
  gpath := gpath + fext;
  Screen.Cursor := crHourGlass;
  CreateDir(gpath);
  //BatchForm.Show;

  i:=0;
  if OpenDialogBatch.Execute then
  begin
    gpath := ExtractFilePath(OpenDialogBatch.Files[I]);
    Screen.Cursor := crHourGlass;

    BatchForm.ProgressBar1.Position := 0;
    BatchForm.Show;

    BatchForm.Memo1.Lines.Clear;
    BatchForm.Memo1.Lines.Add(IntToStr(OpenDialogBatch.Files.Count) +
      ' File(s) selected to convert');


    BatchForm.ProgressBar1.Max := OpenDialogBatch.Files.Count-1;
   // starttime := GetTickCount;
    for I := 0 to OpenDialogBatch.Files.Count - 1 do
    begin
    BatchForm.ProgressBar1.Position := i;

    bestcmp    := GetbestCMP(OpenDialogBatch.Files[I], jkpath);

    pos:=GetGOBFileOffset(jkpath,bestcmp);
    MainCMP.LoadCMPFromFile(jkpath, pos);

   // mainform.gridPalette.Repaint;

    Mat:=TMAT.Create(TFormat.BMP);
    Mat.SetCMP(defCmppal);
    tempA:= Mat.LoadFromFile(OpenDialogBatch.Files[I]);

     mess.Memo1.lines.Add(OpenDialogBatch.Files[I]);
     MatInfoList:=Mat.HeadersToJSON;
     mess.Memo1.lines.AddStrings(MatInfoList);

     tempA.SaveMTS(OpenDialogBatch.Files[I]);
     BatchForm.Memo1.Lines.Add('Saved: '
      + TPath.GetFileNameWithoutExtension(OpenDialogBatch.Files[I])
      + ' cmp: ' + bestcmp);


    Mat.Free;
    tempA.Free;
    MatInfoList.Free;
  end;
  end;
  BatchForm.Memo1.Lines.Add('-Done-');
  Screen.Cursor := crDefault;

end;

procedure TMainForm.Button1Click(Sender: TObject);
var
 Mat: TMAT;
 Test:Tbitmap;
begin
   Test:=Tbitmap.Create;
//   Test.PixelFormat := pf32bit;
//  Test.HandleType :=   bmDIB;
   Mat:=TMAT.Create(TFormat.COLOR8);
   Mat.AddColorCell(255);
  // Mat.AddCellFromBMP(main.MainForm.Image1.Picture.Bitmap);

 //  test.LoadFromFile('D:\TestBMP\red.bmp');
 //  Mat.AddCellFromBMP(main.MainForm.Image1.Picture.Bitmap);
//   test.LoadFromFile('D:\TestBMP\green.bmp');
//test.LoadFromFile('D:\TestBMP\blue_mip1.bmp');
//Mat.AddSubMipMapFromBMP(test);

//test.LoadFromFile('D:\TestBMP\blue_mip2.bmp');
//Mat.AddSubMipMapFromBMP(test);

//test.LoadFromFile('D:\TestBMP\blue_mip3.bmp');
//Mat.AddSubMipMapFromBMP(test);
//   Mat.AddCellFromBMP(test);
//   test.LoadFromFile('D:\TestBMP\blue.bmp');
//   Mat.AddCellFromBMP(test);

   Mat.SaveMat('D:\TestBMP\test.mat');
  // Mat.matFormat:=TFormat.RGB565;
   Mat.Free;
   Test.Free;

end;

procedure TMainForm.SaveDialogTypeChange(Sender: TObject);
begin
  if SaveDialog.filterindex = 1 then
        SaveDialog.DefaultEXt := '.mat';


  if SaveDialog.filterindex = 2 then
        SaveDialog.DefaultEXt := '.bmp';

end;



procedure TMainForm.UpDown_LightLevelClick(Sender: TObject; Button: TUDBtnType);
begin
 SetLightLevel(UpDown_LightLevel.Position);
end;

procedure TmainForm.SetLightLevel(level:integer);
var
 tmpbmp,remap:tbitmap;
begin
//   if ContainsText(BMPArray.fmt, 'CMP') then
//   level:=63;

   edit_LightLevel.Text:=inttostr(level);

  // if not ContainsText(BMPArray.fmt, 'CMP') then
 //  LightLevelRemap(level);
   MainCMP.LightLevelRemap(level);

 if bitmap.PixelFormat = pf8bit then
   begin
   BMPArray.RemapArrayfromCMP(MainCMP);
   TrackBarChange;
   end;

   gridPalette.Repaint;

//   if image1.Picture.Bitmap.PixelFormat = pf8bit then
//       begin
//         tmpBMP:=(BMPArray.GetCell(0));
//         remap:=MainCMP.WriteCMPtoBMP(tmpBMP);
//         if ContainsText(BMPArray.fmt, 'trans') then
//           Draw8bitImageOnGrid(remap)
//         else
//           Image1.Picture.Bitmap.Assign(remap);
//         image1.Repaint;
//         tmpbmp.Free;
//         remap.Free;
//       end;

 // TrackBarChange;
end;


procedure TMainForm.Draw8bitImageOnGrid(bmp:Tbitmap);
var
gridBMP,remap:tbitmap;
begin
 gridBMP:=Tbitmap.create;
 if bmp.PixelFormat = pfCustom then
  gridBMP.PixelFormat:=pf15bit
  else
 gridBMP.PixelFormat:=pf8bit;
 gridBMP.HandleType :=  bmDIB;
 try
 Image1.Picture.Bitmap:=nil;
 RenderGrid(gridBMP,bmp.Height,bmp.Width,1,clGray,clLtGray);
   //remap:=MainCMP.WriteCMPtoBMP(bmp);
   TransBlt(gridBMP,bmp,BMPArray.transparentColorValue);
   Image1.Picture.Bitmap.Assign(gridBMP);
   image1.Repaint;


 finally
 //remap.Free;
 gridBMP.Free;
 end;
end;


procedure TMainForm.Draw16bitImageOnGrid(bmp:Tbitmap);
var
gridBMP,remap:tbitmap;
begin
 gridBMP:=Tbitmap.create;
 if bmp.PixelFormat = pfCustom then
  gridBMP.PixelFormat:=pf15bit
  else
 gridBMP.PixelFormat:=bmp.PixelFormat;
 gridBMP.HandleType :=  bmDIB;
 try
 RenderGrid(gridBMP,bmp.Height,bmp.Width,4,clGray,clLtGray);
 TransBlt(gridBMP,bmp,BMPArray.transparentColorValue);
 Image1.Picture.Bitmap.Assign(gridBMP);
 image1.Repaint;
 finally
  gridBMP.Free;
 end;
end;

procedure TMainForm.Draw32bitImageOnGrid(bmp:Tbitmap);
 var
gridBMP,remap:tbitmap;
begin
 gridBMP:=Tbitmap.create;
 try
 RenderGrid(gridBMP,bmp.Height,bmp.Width,1,clGray,clLtGray);
 Blend(gridBMP,bmp);
 Image1.Picture.Bitmap.Assign(gridBMP);
 image1.Repaint;
 finally
 gridBMP.free;
 end;

end;

procedure TMainForm.Options1Click(Sender: TObject);
begin
  Optionsform.Show;
 end;


procedure TMainForm.Cell_TrackBarChange(Sender: TObject);
//var
//tmpBMP,gridBMP:Tbitmap;
begin
Mip_TrackBar.Position:=0;

 if Cell_TrackBar.Max <> 0 then
  begin
    SetLightLevel(63);
    Image1.Picture:=nil;
    TrackBarChange;
    image1.Repaint;
  end;
end;

procedure TMainForm.Color16BitMat1Click(Sender: TObject);
begin
  //if ColorDialog1.Execute then
  // begin
  // Image1.Canvas.Brush.Color:=ColorDialog1.Color;
  // Image1.Canvas.FillRect(Rect(0,0,100,100));

  //Image1.Repaint;
  //end;
end;

procedure TMainForm.ColorMat1Click(Sender: TObject);
begin
  //Createnewimage.show;
end;

procedure TMainForm.AddCellClick(Sender: TObject);
var
 LoadMat:TMat;

begin

  EditMatForm.editA:=TBMPArray.Create;
  EditMatForm.editA.Assign(BMPArray);

   if EditMatForm.ShowModal = mrOk then
        begin
         LoadMat:=TMAT.Create(TFORMAT.BMP);
         LoadMat.matFormat:=LoadMat.StrToFormat(EditMatForm.editA.fmt);
         BMPArrayDisplay(EditMatForm.editA,LoadMat);  //function frees resources
        end
    else
      EditMatForm.editA.free;

end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
//if Assigned(BMPArray) then
   BMPArray.Free;
   MainCMP.Free;

   if Assigned(bitmap) then
   bitmap.free;

   image1.Picture.Bitmap:=nil;

end;

procedure TMainForm.FormCreate(Sender: TObject);
var
 // i:  integer;
 // ge: TGob2Entry;
 // gh: TGOB2Header;
// dir, Name: string;
 cmpList:Tstringlist;
//  Reg:      TRegistry;


begin
   BMParray:=TBMPARRAY.Create;
   bitmap:=Tbitmap.create;
   MainCMP:=TCMP.create;

  adpMRU:=TadpMRU.Create(mainform);
  adpMRU.ParentMenuItem:=reopen;
  adpMRU.OnClick:= adpMRUClick;
  adpmru.RegistryPath:='\Software\Jedi Dreams\Mat16\mru';
  adpmru.MaxItems := 10;


  isbatch := False;

 JKPath:= Optionsform.GetContainerPath;
  updateCMPcomboBox(JKPath);

  n5.Enabled := False;
 // AddCell1.Enabled := False;
  addcell    := False;
   orgCMPPAL:= defCmppal;

 RenderGrid(image1.Picture.Bitmap,256,256,4,clGray,clLtGray);
 // cmpList.Free;
end;

procedure TMainForm.updateCMPcomboBox(container:string);
var
cmpList:Tstringlist;
begin
  groupbox4.Caption:= 'CMP from '+ExtractFileName(container);
  CMPOffsets:=gobFilesToArray(container, '.CMP');
  cmpList:=gobFileArrayToList(CMPOffsets);
  combobox1.Items.SetStrings(cmpList);
  cmpList.Free;
end;

procedure TMainForm.gridPaletteDrawCell(Sender: TObject; Col, Row: integer;
  Rect: TRect; State: TGridDrawState);
var
  i, rowi, coli: integer;
  CMPRGB:TCMPPal;
begin
  CMPRGB:=MainCMP.GetRGB;
  rowi := -1;
  coli := 0;

  for i := 0 to 255 do
  begin
    Inc(rowi);

    if rowi = 16 then
    begin
      rowi := 0;
      Inc(coli);
    end;



    if (row = coli) and (col = rowi) then
    begin
      gridPalette.canvas.Brush.Color :=
        (2 shl 24) + rgb(CMPRGB[i].r, CMPRGB[i].g, CMPRGB[i].b);
      gridPalette.canvas.FillRect(Rect);
    end;
  end;

     if (gdFocused in State) then
  begin
   i := Row * gridPalette.ColCount + Col;
    LabelIndex.Caption:= 'Cell ' + InttoStr(i);

    Shape1.Brush.Color := (2 shl 24) + rgb(CMPRGB[i].r, CMPRGB[i].g, CMPRGB[i].b);

    labelRGB.Caption    := IntToStr(CMPRGB[i].r) +', '+
                         IntToStr(CMPRGB[i].g) +', '+
                         IntToStr(CMPRGB[i].b) +', '+
                         IntToStr(-1);
  end;
    // gridPalette.ogoDrawFocusSelected = True
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  //optionsform.readoptions;
end;

procedure TMainForm.LoadCMP1Click(Sender: TObject);
begin
 // CMPPanelVisible1.Checked := True;
  //mainform.Width    := 438;
  groupbox1.Visible := True;
  groupbox2.Visible := True;
  if OpenDialogCMP.Execute then
  begin
    // Label11.caption:='n/a';
    Screen.Cursor := crHourGlass;

    if UpperCase(ExtractFileExt(OpenDialogcmp.FileName)) = '.CMP' then
    begin
      MainCMP.LoadCMPFromFile(OpenDialogcmp.FileName,0);
      //loadcmp(OpenDialogcmp.FileName,0);
      gridPalette.Repaint;

//      if image1.picture.bitmap.PixelFormat = pf8bit then
//      begin
//        if UpperCase(ExtractFileExt(OpenDialog.FileName)) = '.MAT' then
//          matopen(OpenDialog.FileName);
//        //  Label11.caption:=ExtractFileName(OpenDialogcmp.FileName);
//        //image1.picture.bitmap.loadfromfile(opendialog.filename);
//      end;
    end;

   if (UpperCase(ExtractFileExt(OpenDialogcmp.FileName)) = '.GOB') or
      (UpperCase(ExtractFileExt(OpenDialogcmp.FileName)) = '.GOO') then
    begin
       updateCMPcomboBox(OpenDialogcmp.FileName);
    end;


    Screen.Cursor := crDefault;
  end;
end;

procedure TMainForm.BackGroundColor1Click(Sender: TObject);
begin
  if ColorDialog1.Execute then
  begin
    Panel1.color := ColorDialog1.Color;
    Panel1.Repaint;
  end;
end;

procedure TMainForm.formresetinfo;
begin
  //Cell_ImageList.Clear;
  // Cell_TrackBar.Visible := False;
  //label15.Caption := '';
 // Edit_LightLevel.Text:='63';
 // UpDown_LightLevel.Position:=63;
 MainCMP.SetDefault;
 SetLightLevel(63);
  // UpDown_LightLevelClick;
  label17.Caption := '0';
end;

procedure TMainForm.OpenGOBGOO1Click(Sender: TObject);
begin

  //SaveAlphaChannel1.Enabled := False;
//  optionsform.readoptions;
  image1.Transparent := False;
  VIewasTransparent1.Checked := False;
  image1.Picture.Bitmap.Width := 32;
  image1.Picture.Bitmap.Height := 32;
  image1.Picture.Bitmap.Assign(nil);
  //Cell_ImageList.Clear;
  // Cell_TrackBar.Visible:=False;


  image1.Transparent := False;
  VIewasTransparent1.Checked := False;
  if OpenDialog1.Execute then
  begin
    //Screen.Cursor := crHourGlass;

    if UpperCase(ExtractFileExt(OpenDialog1.FileName)) = '.GOB' then
    begin
      gobview.opengob(OpenDialog1.FileName);
      gobview.Show;
      gobview.Label_FileName.Caption := OpenDialog1.Filename;
    end;

    if UpperCase(ExtractFileExt(OpenDialog1.FileName)) = '.GOO' then
    begin
      gobview.opengob(OpenDialog1.FileName);
      gobview.Show;
      gobview.Label_FileName.Caption := OpenDialog1.Filename;
    end;

     if UpperCase(ExtractFileExt(OpenDialog1.FileName)) = '.BAF' then
    begin
      gobview.openbaf(OpenDialog1.FileName);
      gobview.Show;
      gobview.Label_FileName.Caption := OpenDialog1.Filename;
    end;
  end;
end;

procedure TMainForm.SaveCMPas1Click(Sender: TObject);
begin
  Screen.Cursor    := crHourGlass;
  SaveCMP.FileName := ChangeExt(OpenDialog.FileName, '');
  if SaveCMP.Execute then
  begin
    //filter1=pal
    if SaveCMP.FilterIndex = 1 then
    begin
      SaveCMP.DefaultEXt := '.pal';
      MainCMP.savepal(SaveCMP.FileName);
    end;

    //filter2=act
    if SaveCMP.FilterIndex = 2 then
    begin
      SaveCMP.DefaultEXt := '.act';
      MainCMP.saveact(SaveCMP.FileName);
    end;
    //filter2=gpl
    if SaveCMP.FilterIndex = 3 then
    begin
      SaveCMP.DefaultEXt := '.gpl';
      MainCMP.savegpl(SaveCMP.FileName);
    end;
  end;
  Screen.Cursor := crDefault;
end;

procedure TMainForm.ComboBox1Change(Sender: TObject);
var
  pos:longint;
begin

  //  pos:=GetGOBFileOffset( jkpath, Extractname(ComboBox1.Items.Strings[comboBox1.ItemIndex]));
    pos:=GetGOBArrayOffset(CMPOffsets, Extractname(ComboBox1.Items.Strings[comboBox1.ItemIndex]) );
    MainCMP.LoadCMPFromFile(CMPOffsets[comboBox1.ItemIndex].container,pos);
  //  loadcmp(jkpath,pos);


 //  LightLevelRemap(63);
 SetLightLevel(63);
   BMPArray.RemapArrayfromCMP(MainCMP);
  TrackBarChange;

  gridPalette.Repaint;
end;

procedure TMainForm.Createnewmatfrombmps1Click(Sender: TObject);
var
 LoadMat:TMat;

begin

  EditMatForm.editA:=TBMPArray.Create;
  //EditMatForm.editA.Assign(BMPArray);

   if EditMatForm.ShowModal = mrOk then
        begin
         LoadMat:=TMAT.Create(TFORMAT.BMP);
         LoadMat.matFormat:=LoadMat.StrToFormat(EditMatForm.editA.fmt);
         BMPArrayDisplay(EditMatForm.editA,LoadMat);  //function frees resources
        end
    else
      EditMatForm.editA.free;

end;

procedure TMainForm.ViewTiled1Click(Sender: TObject);
begin
  if not image1.picture.Bitmap.Empty then
    viewtiled.Show;
end;

procedure TMainForm.ViewasTransparent1Click(Sender: TObject);
begin

  if VIewasTransparent1.Checked = False then
    VIewasTransparent1.Checked := True

  else
    VIewasTransparent1.Checked := False;

  image1.Transparent := VIewasTransparent1.Checked;
  image1.Picture.Bitmap.Transparent:=True;
 //  image1.Picture.Bitmap.HandleType :=  bmDIB;
 //  image1.Picture.Bitmap.alphaformat := afDefined;
 // image1.Picture.Bitmap.TransparentColor:= image1.Picture.BitMap.canvas.pixels[0,0];
 // image1.Picture.Bitmap.TransparentMode:= tmAuto;
  image1.Repaint;

end;

procedure TMainForm.CloseImage1Click(Sender: TObject);
begin
 // LoadAlpha1.Enabled := False;
  //SaveAlphaChannel1.Enabled := False;
 // optionsform.readoptions;
  image1.Transparent := False;
  VIewasTransparent1.Checked := False;
  image1.Picture.Bitmap.Width := 32;
  image1.Picture.Bitmap.Height := 32;
  image1.Picture.Bitmap.Assign(nil);
 // Cell_ImageList.Clear;


end;

procedure TMainForm.FormShortCut(var Msg: TWMKey; var Handled: boolean);
begin
  if msg.charcode = Ord('T') then
  begin

    handled := True;
//    if optionsform.checkbox3.Checked = False then
//      optionsform.checkbox3.Checked := True
//
//
//    else
//      optionsform.checkbox3.Checked := False;

  end;

end;

procedure TMainForm.In1Click(Sender: TObject);
 var
  AspectRatio:double;
begin
  AspectRatio:=panel2.Height/panel2.Width;

  panel2.Width  := panel2.Width + 10;
  panel2.Height:=round(AspectRatio*panel2.Width);

end;

procedure TMainForm.Out1Click(Sender: TObject);
 var
  AspectRatio:double;
begin
   AspectRatio:=panel2.Height/panel2.Width;

  if panel2.Width - 10 >= image1.Picture.Bitmap.Width  then
   begin
  panel2.Width  := panel2.Width - 10;
  panel2.Height:=round(AspectRatio*panel2.Width);
   end;
end;

procedure TMainForm.Home1Click(Sender: TObject);
begin
  panel2.Width  := image1.Picture.Bitmap.Width;
  panel2.Height := image1.Picture.Bitmap.Height;
end;

procedure TMainForm.ViewMessages1Click(Sender: TObject);
begin
  mess.Show;
end;



procedure TMainForm.adpMRUClick(Sender: TObject; const Filename: String);
begin
 OpenImage(filename);

end;


procedure TMainForm.OpenImage(Filename: String);
var
  loadbmp: Tbitmap;
  StartTime, EndTime: DWORD;
  LoadMat: TMAT;
 LoadBMParray:TBMParray;
begin
  image1.Transparent := False;
  VIewasTransparent1.Checked := False;

    Screen.Cursor := crHourGlass;

    if UpperCase(ExtractFileExt(FileName)) = '.MAT' then
    begin
      formresetinfo;
      addcell   := False;
      starttime := GetTickCount;
      matopen(FileName);
      endtime := GetTickCount;
      StatusBar1.Panels[1].Text :=
        'mat loaded in ' + IntToStr(EndTime - StartTime) + 'mS';
    end;

    if UpperCase(ExtractFileExt(FileName)) = '.BMP' then
    begin
      AddCell1.Enabled := True;
      n5.Enabled := True;
     // loadbmp    := Tbitmap.Create;
      starttime  := GetTickCount;

      //loadbmp.LoadFromFile(FileName);
       loadbmp:=BMP_Open(FileName); //function creates bmp
      formresetinfo;

      LoadBMParray:=TBMPARRAY.Create;
      LoadBMParray.AddCellFromBMP(loadbmp);

      Cell_TrackBar.Position := 0;
      image1.Repaint;

      if loadbmp.PixelFormat = pf8bit then
        begin

        if Set8bitFormatForm.ShowModal = mrOk then
        begin
          LoadMat:=TMAT.Create(Set8bitFormatForm.MatFormat);
          LoadBMParray.fmt:=Set8bitFormatForm.fmt;
          LoadBMParray.ConvertBMPPal;
        end;

        end;


      BMPArrayDisplay(LoadBMParray,LoadMat);  //frees bmpA and Tmat

      endtime := GetTickCount;
      StatusBar1.Panels[1].Text :=
      'bmp loaded in ' + IntToStr(EndTime - StartTime) + 'mS';
      loadbmp.Free;
    end;

   if UpperCase(ExtractFileExt(FileName)) = '.MAT16S' then
    begin

      LoadBMParray:=TBMPARRAY.Create;
      LoadBMParray.OpenMTS(FileName);

      Cell_TrackBar.Position := 0;
      image1.Repaint;

      LoadMat:=TMAT.Create(TFORMAT.BMP);
      LoadMat.matFormat:=LoadMat.StrToFormat(LoadBMParray.fmt);

      BMPArrayDisplay(LoadBMParray,LoadMat);  //frees bmpA and Tmat


     end;

    MainForm.Caption := 'Mat16 - ' + extractfilename(FileName);
    adpMRU.AddItem(OpenPic.FileName);
    Screen.Cursor := crDefault;

end;


 end.

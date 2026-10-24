unit Main;

interface

uses
  SysUtils, Windows, Messages, Classes, Graphics, Controls,
  Forms, vcl.Dialogs, StdCtrls, ImgList, Menus, Grids, ComCtrls, ExtCtrls,
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
    Createnewmatfrombmps1: TMenuItem;
    Browsematsinfolder1: TMenuItem;  { Save &As... }
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
    procedure EditMTS1Click(Sender: TObject);
    procedure Browsematsinfolder1Click(Sender: TObject);
  private
    BatchConvertBMPsTo565Item: TMenuItem; {created in FormCreate}
    MatHeaderEditorItem: TMenuItem;     {created in FormCreate}
    FLightLevel: Integer;               {light level kept while the program runs (63 at start)}
    FZoomFactor: Double;                {zoom kept between images}
    EmissiveSearchItem: TMenuItem;      {created in FormCreate}
    AutoPaletteItem: TMenuItem;         {Tools: pick the colour map automatically}
    FAutoPalNote: string;               {shown in the status bar after the load time}
    FCandNames: TStringList;            {candidate colour maps (names + palettes)}
    FCandPals: array of TCMPPal;
    FCandOffsets: TFileOffsets;         {CMPOffsets the cache was built from}
    adpMRUContainer: TadpMRU;           {recent containers}
    adpMRUFolder: TadpMRU;              {recent folders of the folder view}
    RecentFolderItem: TMenuItem;
    RecentContainerItem: TMenuItem;     {created in FormCreate}
    procedure OpenFolderView(const dir: string);
    procedure adpMRUFolderClick(Sender: TObject; const Filename: String);
    procedure AutoPaletteClick(Sender: TObject);
    procedure BuildPaletteCandidates;
    procedure AutoPickPalette(const filename: string);
    procedure OpenContainer(const FileName: string);
    procedure adpMRUContainerClick(Sender: TObject; const Filename: String);
    procedure EmissiveSearchClick(Sender: TObject);
    procedure BatchConvertBMPsTo565Click(Sender: TObject);
    procedure MatHeaderEditorClick(Sender: TObject);
  end;

var
  MainForm:  TMainForm;
  Bitmap:    TBitmap;
  animcnt:   integer;
  numframes: integer;
  savefname: string;
  addcell:   boolean;
  motspath:  string;
  isbatch:   boolean;
   adpMRU: TadpMRU;
  BMPArray: TBMPARRAY;
  MainCMP:TCMP;
  CMPOffsets: TFileOffsets;
implementation

uses about_unit, Batch, MatHeaderForm, MatSearch, AutoPalette,
   gobform, ViewtileUnit, mess_frm,options, EditMat,EditMTS,GloabalVars;

{$R *.DFM}


procedure TMainForm.FileOpen(Sender: TObject);
begin
  OpenPic.Filter     :=
    'mat files |*.MAT;*.MAT16S;|mat texture (*.mat)|*.MAT|mat16 script with bitmaps|*mat16s';

  if OpenPic.Execute then
       OpenImage(OpenPic.FileName);

end;


procedure TMainForm.AutoPaletteClick(Sender: TObject);
var
  reg: TRegistry;
begin
  AutoPaletteItem.Checked := not AutoPaletteItem.Checked;
  AutoPaletteEnabled := AutoPaletteItem.Checked;
  reg := TRegistry.Create;
  try
    if reg.OpenKey('\Software\Jedi Dreams\Mat16', True) then
      reg.WriteBool('AutoPalette', AutoPaletteItem.Checked);
  finally
    reg.Free;
  end;
end;

{loads every colour map of the current CMP source once so mats can be tried against all of them}
procedure TMainForm.BuildPaletteCandidates;
var
  i, n: Integer;
  cmp: TCMP;
begin
  if (FCandNames <> nil) and (Length(FCandOffsets) = Length(CMPOffsets)) and (Length(CMPOffsets) > 0) then
    if (Length(CMPOffsets) = 0) or (FCandOffsets[0].container = CMPOffsets[0].container) then Exit;
  if FCandNames = nil then FCandNames := TStringList.Create;
  FCandNames.Clear;
  SetLength(FCandPals, 0);
  FCandOffsets := CMPOffsets;
  n := 0;
  cmp := TCMP.Create;
  try
    for i := 0 to High(CMPOffsets) do
    begin
      try
        cmp.LoadCMPFromFile(CMPOffsets[i].container, CMPOffsets[i].offset);
        SetLength(FCandPals, n + 1);
        FCandPals[n] := cmp.GetRGB;
        FCandNames.Add(CMPOffsets[i].filename);
        Inc(n);
      except
      end;
    end;
  finally
    cmp.Free;
  end;
end;

{a wrong colour map shows as lots of magenta: when that happens try the other colour maps
 (those of the game resources plus any .cmp next to the mat) and keep the best one}
procedure TMainForm.AutoPickPalette(const filename: string);
var
  px: TBytes;
  w, h, i, best, k: Integer;
  trans: Boolean;
  curMag, curScore, mag, sc, bestScore, bestMag: Double;
  cmp: TCMP;
  files: TArray<string>;
  bestName: string;
  bestPal: TCMPPal;
  bestFile: string;
  cidx: Integer;
  fromList: Boolean;
  prefix, nm: string;
  pIdx, c: Integer;
  usedPrefix, curOK: Boolean;
  pMag, pSc: Double;
begin
  FAutoPalNote := '';
  bestFile := '';
  if (AutoPaletteItem = nil) or (not AutoPaletteItem.Checked) then Exit;
  if not ReadMatIndices(filename, w, h, trans, px) then Exit;

  ScorePalette(px, w, h, trans, MainCMP.GetBaseRGB, curMag, curScore);
  usedPrefix := False;
  prefix := '';
  nm := ExtractFileName(filename);
  c := 1;
  while (c <= Length(nm)) and CharInSet(nm[c], ['0'..'9']) do
  begin
    prefix := prefix + nm[c];
    Inc(c);
  end;
  {the palette already in use is fine when it has little magenta and, for a stock level
   texture, is also the colour map of that level}
  curOK := (prefix = '') or StartsText(prefix, ExtractFileName(StringReplace(ComboBox1.Text, '/', '\', [rfReplaceAll])));
  if (curMag < 0.02) and curOK then Exit;

  BuildPaletteCandidates;
  bestScore := curScore;
  bestMag := curMag;
  best := -1;
  for i := 0 to High(FCandPals) do
  begin
    ScorePalette(px, w, h, trans, FCandPals[i], mag, sc);
    if sc < bestScore then
    begin
      bestScore := sc;
      bestMag := mag;
      best := i;
    end;
  end;

  {stock levels name mats and colour maps with the same level prefix (19tstn.mat -> 19xxxx.cmp):
   when such a map is about as good as the best one, prefer it}
  if prefix <> '' then
  begin
    pIdx := -1;
    for i := 0 to High(FCandPals) do
      if StartsText(prefix, ExtractFileName(StringReplace(FCandNames[i], '/', '\', [rfReplaceAll]))) then
      begin
        ScorePalette(px, w, h, trans, FCandPals[i], pMag, pSc);
        if (pMag <= curMag + 0.01) and (pMag <= bestMag + 0.01) and ((pIdx < 0) or (pSc < bestScore)) then
        begin
          pIdx := i;
          bestScore := pSc;
          bestMag := pMag;
        end;
      end;
    if pIdx >= 0 then
    begin
      best := pIdx;
      usedPrefix := True;
    end;
  end;

  fromList := best >= 0;
  if fromList then
  begin
    bestName := FCandNames[best];
    bestPal := FCandPals[best];
  end;

  {colour maps stored beside the mat (custom levels)}
  try
    files := TDirectory.GetFiles(ExtractFilePath(filename), '*.cmp');
  except
    SetLength(files, 0);
  end;
  cmp := TCMP.Create;
  try
    for k := 0 to High(files) do
    begin
      try
        cmp.LoadCMPFromFile(files[k], 0);
        ScorePalette(px, w, h, trans, cmp.GetRGB, mag, sc);
        if sc < bestScore then
        begin
          bestScore := sc;
          bestMag := mag;
          bestName := ExtractFileName(files[k]);
          bestPal := cmp.GetRGB;
          bestFile := files[k];
          fromList := False;
          best := -2;
        end;
      except
      end;
    end;
  finally
    cmp.Free;
  end;

  {only switch when it is clearly better}
  if (best = -1) or ((not usedPrefix) and (bestMag > curMag * 0.5)) then Exit;

  {load the colour map the same way the colour map drop down does (palette + light table)}
  cidx := -1;
  if fromList then cidx := ComboBox1.Items.IndexOf(bestName);
  if (cidx >= 0) and (cidx <= High(CMPOffsets)) then
  begin
    MainCMP.LoadCMPFromFile(CMPOffsets[cidx].container, CMPOffsets[cidx].offset);
    ComboBox1.ItemIndex := cidx;
    SetLightLevel(FLightLevel);
  end
  else if (not fromList) and (bestFile <> '') then
  begin
    MainCMP.LoadCMPFromFile(bestFile, 0);
    SetLightLevel(FLightLevel);
  end
  else
    MainCMP.SetRGB(bestPal);
  FAutoPalNote := ' - palette: ' + bestName + ' (auto)';
end;

procedure TmainForm.matopen(filename: string);
var
  Mat: TMAT;
  tempA:TBMPArray;

begin
  Cell_TrackBar.Position := 0;
  image1.Repaint;

  AutoPickPalette(filename);
  Mat:=TMAT.Create(TFormat.BMP);
  {the mat must get the palette without the light level applied, otherwise the light gets applied twice}
  Mat.SetCMP(MainCMP.GetBaseRGB);
  tempA:= Mat.LoadFromFile(filename);

  BMPArrayDisplay(tempA,Mat); //function frees resources

end;

procedure TMainForm.BMPArrayDisplay(BMPA:TBMPArray; Mat:TMAT);
var
tempBMP:TBitmap;
MatInfoList:Tstringlist;
glowBMP:TBitmap;
emis:Boolean;
 //gridBMP:tbitmap;
begin
  Cell_TrackBar.Position := 0;
  Mip_TrackBar.Position := 0;
  if Assigned(image1.Picture.Bitmap) then image1.Picture.Bitmap.Assign(nil);
  Image1.Picture:=nil;
  image1.Repaint;

  BMPArray.Assign(BMPA);
    tempBMP:=(BMPArray.GetCell(0));

    {emissive mats: show the cell as it looks in the dark, the alpha channel (glow) brightens it}
    emis := IsEmissiveFmt(BMPA.fmt);
    if emis then
    begin
      glowBMP := BuildGlowPreview(tempBMP);
      try
        Image1.Picture.Bitmap.Assign(glowBMP);
      finally
        glowBMP.Free;
      end;
    end;

    if (not emis) and ((Mat.GetMatFormat=(TFormat.RGBA4444)) or (Mat.GetMatFormat=(TFormat.RGBA5551)) or (Mat.GetMatFormat=(TFormat.RGBA8888))) then
    begin
    PremultiplyAlpha(tempBMP);
    Draw32bitImageOnGrid(tempBMP);
    end;

  if Mat.GetMatFormat=(TFormat.RGB888) then
     begin
     Image1.Picture.Bitmap.Assign(tempBMP);
     if tempBMP.PixelFormat =pf8bit then
    begin
      Image1.Picture:=nil;
    end;
     end;

  if (not emis) and (Mat.GetMatFormat=(TFormat.ARGB1555)) then
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




  if FLightLevel <> 63 then SetLightLevel(FLightLevel);   {keep the light level chosen earlier}
  if FZoomFactor < 0.02 then FZoomFactor := 1;
  Panel2.Width:=Round(Image1.Picture.Bitmap.Width * FZoomFactor);
  Panel2.Height:=Round(Image1.Picture.Bitmap.Height * FZoomFactor);
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
 procedure TMainForm.EmissiveSearchClick(Sender: TObject);
begin
  ShowMatSearch('',
    procedure(const fn: string)
    begin
      OpenImage(fn);
    end);
end;

procedure TMainForm.OpenFolderView(const dir: string);
begin
  gobview.openfolder(dir);
  gobview.Show;
  adpMRUFolder.AddItem(dir);
end;

procedure TMainForm.adpMRUFolderClick(Sender: TObject; const Filename: String);
begin
  if not TDirectory.Exists(Filename) then
  begin
    ShowMessage('Folder not found: ' + Filename);
    Exit;
  end;
  image1.Transparent := False;
  VIewasTransparent1.Checked := True;
  OpenFolderView(Filename);
end;

procedure TMainForm.Browsematsinfolder1Click(Sender: TObject);
begin
   //SaveAlphaChannel1.Enabled := False;
//  optionsform.readoptions;
  image1.Transparent := False;   {transparency is composed onto a grid, not keyed from the corner pixel}
  VIewasTransparent1.Checked := True;
  image1.Picture.Bitmap.Width := 32;
  image1.Picture.Bitmap.Height := 32;
  image1.Picture.Bitmap.Assign(nil);
  //Cell_ImageList.Clear;
  // Cell_TrackBar.Visible:=False;


  image1.Transparent := False;   {transparency is composed onto a grid, not keyed from the corner pixel}
  VIewasTransparent1.Checked := True;

  with TFileOpenDialog.Create(nil) do
  try
    Options := [fdoPickFolders];
    if Execute then
      OpenFolderView(FileName);
  finally
    Free;
  end;



//  if OpenDialog1.Execute then
//  begin
//
//  end;
end;

procedure TMainForm.TrackBarChange;
 var
tmpBMP:Tbitmap;
glowBMP:Tbitmap;
begin
 if BMPArray.GetCellCount <> 0 then
 begin
   tmpBMP:=(BMPArray.GetBMP(Cell_TrackBar.Position,Mip_TrackBar.Position));

   if IsEmissiveFmt(BMPArray.fmt) then
     begin
      glowBMP := BuildGlowPreview(tmpBMP);
      try
        image1.picture.Bitmap.Assign(glowBMP);
      finally
        glowBMP.Free;
      end;
      bitmap.Assign(tmpBMP);   {raw cell, used by the pixel readout}
      tmpBMP.Free;
      exit;
     end;

   if (tmpBMP.PixelFormat = pf32bit)  then
       begin
        PremultiplyAlpha(tmpBMP);
        Draw32bitImageOnGrid(tmpBMP);
       end;

   if (tmpBMP.PixelFormat = pf16bit)  then
       image1.picture.Bitmap.Assign(tmpBMP);

  if (tmpBMP.PixelFormat = pf24bit)  then
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
    SetLightLevel(FLightLevel);
    Image1.Picture:=nil;
    TrackBarChange;
  end;

  image1.Repaint;

end;

procedure TMainForm.FileSaveAs(Sender: TObject);
 var
Mat: TMAT;
MatName:string;
rawBMP:TBitmap;
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
      if IsEmissiveFmt(BMPArray.fmt) then
      begin
        {save the raw cell with its glow alpha, not the darkened preview}
        rawBMP := BMPArray.GetBMP(Cell_TrackBar.Position,Mip_TrackBar.Position);
        try
          BMP_Save(rawBMP, SaveDialog.FileName);
        finally
          rawBMP.Free;
        end;
      end
      else
        image1.picture.bitmap.SaveToFile(SaveDialog.FileName);
    end;

    if UpperCase(ExtractFileExt(SaveDialog.FileName)) = '.MAT16S' then
    begin
      MatName:=ChangeFileExt(SaveDialog.FileName, '.mat');
      BMPArray.SaveMTS(MatName);
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

   if (Image1.Picture.Bitmap.PixelFormat = pfCustom) or ((imageformat = TFormat.ARGB1555) and IsEmissiveFmt(BMPArray.fmt)) then
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
var
  I:    integer;
  LoadBMParray:TBMParray;
  LoadMat: TMAT;
  gpath, mpath: string;

begin
 OpenDialogBatch.Filter     :=
    'mat16 script with bitmaps|*mat16s';
Screen.Cursor := crHourGlass;

  if OpenDialogBatch.Execute then
  begin
    Screen.Cursor := crHourGlass;

    BatchForm.ProgressBar1.Position := 0;
    BatchForm.Show;

    BatchForm.Memo1.Lines.Clear;
    BatchForm.Memo1.Lines.Add(IntToStr(OpenDialogBatch.Files.Count) +
      ' File(s) selected to convert');

    BatchForm.ProgressBar1.Max := OpenDialogBatch.Files.Count-1;

    for I := 0 to OpenDialogBatch.Files.Count - 1 do
     begin
      BatchForm.ProgressBar1.Position := i;

      if UpperCase(ExtractFileExt(OpenDialogBatch.Files[I])) = '.MAT16S' then
        begin
        LoadBMParray:=TBMPARRAY.Create;
         try
          LoadBMParray.OpenMTS(OpenDialogBatch.Files[I]);
          LoadMat:=TMAT.CreateFromBMPArray(LoadBMParray);
          mpath:=ExtractFilePath(OpenDialogBatch.Files[I])+LoadBMParray.name;
          if  (UpperCase(ExtractFileExt(mpath)) <> '.MAT') then
                begin
                 raise Exception.Create('Save MAT wrong file type '+mpath);
                end;
          LoadMat.SaveMat(ExtractFilePath(OpenDialogBatch.Files[I])+LoadBMParray.name);
         except
          On e:exception do
           begin
            ShowMessage(E.ClassName+' error raised, with message : '+E.Message);
            LoadBMParray.Free;
            LoadMat.Free;
            Screen.Cursor := crDefault;
            exit;
           end;
         end;
        BatchForm.Memo1.Lines.Add('Saved MAT: '+ExtractFilePath(OpenDialogBatch.Files[I])+LoadBMParray.name );
        LoadBMParray.Free;
        LoadMat.Free;
        end;
     end;
  end;
  BatchForm.Memo1.Lines.Add('-Done-');
  Screen.Cursor := crDefault;
end;

{ Batch converts 8/16/24/32-bit bmps to 16-bit RGB565 mats (no mip-maps), saved next to each bmp }
procedure TMainForm.BatchConvertBMPsTo565Click(Sender: TObject);
var
  i, nOK, nFail, nSkip, nExist: Integer;
  src, bmp565: TBitmap;
  A: TBMPArray;
  Mat: TMAT;
  srcName, saveName: string;
  overwrite: Boolean;
begin
  OpenDialogBatch.Filter := 'bmp files (*.bmp)|*.bmp';
  OpenDialogBatch.FilterIndex := 1;
  OpenDialogBatch.Options := OpenDialogBatch.Options + [ofAllowMultiSelect];
  if not OpenDialogBatch.Execute then
    exit;

  nExist := 0;
  for i := 0 to OpenDialogBatch.Files.Count - 1 do
    if FileExists(ChangeFileExt(OpenDialogBatch.Files[i], '.mat')) then
      Inc(nExist);

  overwrite := True;
  if nExist > 0 then
    overwrite := MessageDlg(IntToStr(nExist) + ' of the selected bitmaps already have a .mat file.' +
                 sLineBreak + sLineBreak + 'Overwrite them?  (No skips those files)',
                 mtConfirmation, [mbYes, mbNo], 0) = mrYes;

  nOK := 0; nFail := 0; nSkip := 0;
  Screen.Cursor := crHourGlass;
  try
    BatchForm.Memo1.Lines.Clear;
    BatchForm.Memo1.Lines.Add(IntToStr(OpenDialogBatch.Files.Count) +
      ' File(s) selected to convert to 16-bit RGB565 mat');
    BatchForm.ProgressBar1.Position := 0;
    BatchForm.ProgressBar1.Max := OpenDialogBatch.Files.Count;
    BatchForm.Show;

    for i := 0 to OpenDialogBatch.Files.Count - 1 do
    begin
      srcName  := OpenDialogBatch.Files[i];
      saveName := ChangeFileExt(srcName, '.mat');
      BatchForm.ProgressBar1.Position := i + 1;
      Application.ProcessMessages;

      if UpperCase(ExtractFileExt(srcName)) <> '.BMP' then
        Continue;

      if FileExists(saveName) and (not overwrite) then
      begin
        BatchForm.Memo1.Lines.Add('Skipped (mat exists): ' + ExtractFileName(saveName));
        Inc(nSkip);
        Continue;
      end;

      src := nil; bmp565 := nil; A := nil; Mat := nil;
      try
        try
          src := BMP_Open(srcName);

          case inputBMPFormat of
            bf16bit565:
              begin
                bmp565 := src;   {already 565, use as is}
                src := nil;
              end;
            bf8bit, bf24bit, bf32bit, bf16bitA444, bf16bitX444, bf16bitA1555, bf16bitX1555:
              bmp565 := ConvertToRGB565(src);  {handles paletted, 1555 and 4444 (loaded as 32-bit) too}
          else
            raise Exception.Create('unsupported bitmap format (' + BMPFMTtoStr(inputBMPFormat) + ')');
          end;

          A := TBMPArray.Create;
          A.AddCellFromBMP(bmp565);
          A.fmt := '16-bit RGB565';
          A.transparentColorValue := CalcSolidColorIndex(A);  {solid color = closest CMP index to the average color}
          Mat := TMAT.CreateFromBMPArray(A);
          Mat.SaveMat(saveName);

          BatchForm.Memo1.Lines.Add('Saved ' + ExtractFileName(saveName) +
            ' (solid color index ' + IntToStr(A.transparentColorValue) + ')');
          Inc(nOK);
        except
          on E: Exception do
          begin
            BatchForm.Memo1.Lines.Add('FAILED ' + ExtractFileName(srcName) + ': ' + E.Message);
            Inc(nFail);
          end;
        end;
      finally
        Mat.Free;
        A.Free;
        bmp565.Free;
        src.Free;
      end;
    end;

    BatchForm.Memo1.Lines.Add('-Done- ' + IntToStr(nOK) + ' saved, ' +
      IntToStr(nSkip) + ' skipped, ' + IntToStr(nFail) + ' failed');
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TMainForm.BatchConvertMATBMP1Click(Sender: TObject);
var
  i,j,k: integer;
  Mat: TMAT;
  pos:longint;
  tempA:TBMPArray;
begin

OpenDialogBatch.Filter     :=
    'mat texture (*.mat)|*.MAT';
Screen.Cursor := crHourGlass;

  if OpenDialogBatch.Execute then
  begin
    Screen.Cursor := crHourGlass;

    BatchForm.ProgressBar1.Position := 0;
    BatchForm.Show;

    BatchForm.Memo1.Lines.Clear;
    BatchForm.Memo1.Lines.Add(IntToStr(OpenDialogBatch.Files.Count) +
      ' File(s) selected to convert');

    BatchForm.ProgressBar1.Max := OpenDialogBatch.Files.Count-1;

    for I := 0 to OpenDialogBatch.Files.Count - 1 do
     begin
      BatchForm.ProgressBar1.Position := i;
      BatchForm.Memo1.Lines.Add(GobMatSavetoBMP('', OpenDialogBatch.Files[I],FileOffsets,CMPOffsets,false));
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
var
  lvl: Integer;
begin
 {the control may not have moved its Position yet when this event fires, so step from our own value}
 if Button = btNext then lvl := FLightLevel + 1 else lvl := FLightLevel - 1;
 if lvl > 63 then lvl := 63;
 if lvl < 0 then lvl := 0;
 SetLightLevel(lvl);
end;

procedure TmainForm.SetLightLevel(level:integer);
var
 tmpbmp,remap:tbitmap;
begin
//   if ContainsText(BMPArray.fmt, 'CMP') then
//   level:=63;

   FLightLevel := level;
   edit_LightLevel.Text:=inttostr(level);
   if UpDown_LightLevel.Position <> level then UpDown_LightLevel.Position := level;

  // if not ContainsText(BMPArray.fmt, 'CMP') then
 //  LightLevelRemap(level);
   MainCMP.LightLevelRemap(level);

 if (bitmap.PixelFormat = pf8bit) or StartsText('8-bit', BMPArray.fmt) then
   begin
   BMPArray.RemapArrayfromCMP(MainCMP);
   TrackBarChange;
   image1.Invalidate;
   image1.Repaint;
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
gridBMP:tbitmap;
pe: array[0..255] of TPaletteEntry;
x, y: Integer;
srow: PByteArray;
drow: PByteArray;
begin
 gridBMP:=Tbitmap.create;
 try
 Image1.Picture.Bitmap:=nil;
 if (bmp.PixelFormat = pf8bit) and (not ViewasTransparent1.Checked) then
  begin
   {transparency switched off: show index 0 as an ordinary colour}
   gridBMP.Assign(bmp);
  end
 else if (bmp.PixelFormat = pf8bit) and (bmp.Palette <> 0) then
  begin
   {the game treats palette index 0 as the transparent pixel (the header colour is only the
    'solid colour' used for distant mips), so key on the index and not on a colour}
   gridBMP.PixelFormat:=pf24bit;
   gridBMP.HandleType :=  bmDIB;
   RenderGrid(gridBMP,bmp.Height,bmp.Width,1,clGray,clLtGray);
   gridBMP.PixelFormat:=pf24bit;
   GetPaletteEntries(bmp.Palette, 0, 256, pe);
   for y := 0 to bmp.Height - 1 do
    begin
     srow := bmp.ScanLine[y];
     drow := gridBMP.ScanLine[y];
     for x := 0 to bmp.Width - 1 do
      if srow^[x] <> 0 then
       begin
        drow^[x * 3]     := pe[srow^[x]].peBlue;
        drow^[x * 3 + 1] := pe[srow^[x]].peGreen;
        drow^[x * 3 + 2] := pe[srow^[x]].peRed;
       end;
    end;
  end
 else
  begin
   if bmp.PixelFormat = pfCustom then
    gridBMP.PixelFormat:=pf15bit
   else
    gridBMP.PixelFormat:=pf8bit;
   gridBMP.HandleType :=  bmDIB;
   RenderGrid(gridBMP,bmp.Height,bmp.Width,1,clGray,clLtGray);
   TransBlt(gridBMP,bmp,BMPArray.transparentColorValue);
  end;
 Image1.Picture.Bitmap.Assign(gridBMP);
 image1.Repaint;
 finally
 gridBMP.Free;
 end;
end;


procedure TMainForm.EditMTS1Click(Sender: TObject);
begin
  EditMTSForm.Show;

end;

procedure TMainForm.Draw16bitImageOnGrid(bmp:Tbitmap);
type
  TWordRow = array[0..32767] of Word;
  PWordRow = ^TWordRow;
var
gridBMP,remap:tbitmap;
x,y:integer;
srcRow,dstRow:PWordRow;
begin
 gridBMP:=Tbitmap.create;
 if bmp.PixelFormat = pfCustom then
  gridBMP.PixelFormat:=pf15bit
  else
 gridBMP.PixelFormat:=bmp.PixelFormat;
 gridBMP.HandleType :=  bmDIB;
 try
 RenderGrid(gridBMP,bmp.Height,bmp.Width,4,clGray,clLtGray);
 if (bmp.PixelFormat = pfCustom) or (bmp.PixelFormat = pf15bit) then
  begin
   {1555: only a word of 0 (black with the alpha bit clear) is transparent, so an opaque black pixel
    (alpha bit set) is drawn as black}
   for y := 0 to bmp.Height - 1 do
    begin
     srcRow := bmp.ScanLine[y];
     dstRow := gridBMP.ScanLine[y];
     for x := 0 to bmp.Width - 1 do
       if srcRow^[x] <> 0 then
         dstRow^[x] := srcRow^[x];
    end;
  end
 else
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
 gridBMP.PixelFormat:=pf32bit;
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
    SetLightLevel(FLightLevel);
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

procedure TMainForm.MatHeaderEditorClick(Sender: TObject);
begin
  ShowMatHeaderEditor;
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
   FLightLevel := 63;
   BMParray:=TBMPARRAY.Create;
   bitmap:=Tbitmap.create;
   MainCMP:=TCMP.create;

  adpMRU:=TadpMRU.Create(mainform);
  adpMRU.ParentMenuItem:=reopen;
  adpMRU.OnClick:= adpMRUClick;
  adpmru.RegistryPath:='\Software\Jedi Dreams\Mat16\mru';
  adpmru.MaxItems := 10;


  {File menu: Open recent container (submenu kept in the registry like the recent files list)}
  RecentContainerItem := TMenuItem.Create(Self);
  RecentContainerItem.Caption := 'Open recent &container';
  OpenGOBGOO1.Parent.Insert(OpenGOBGOO1.MenuIndex + 1, RecentContainerItem);
  adpMRUContainer := TadpMRU.Create(mainform);
  adpMRUContainer.ParentMenuItem := RecentContainerItem;
  adpMRUContainer.OnClick := adpMRUContainerClick;
  adpMRUContainer.RegistryPath := '\Software\Jedi Dreams\Mat16\mru_containers';
  adpMRUContainer.MaxItems := 10;

  {File menu: Open recent folder (for the folder view)}
  RecentFolderItem := TMenuItem.Create(Self);
  RecentFolderItem.Caption := 'Open recent &folder';
  Browsematsinfolder1.Parent.Insert(Browsematsinfolder1.MenuIndex + 1, RecentFolderItem);
  adpMRUFolder := TadpMRU.Create(mainform);
  adpMRUFolder.ParentMenuItem := RecentFolderItem;
  adpMRUFolder.OnClick := adpMRUFolderClick;
  adpMRUFolder.RegistryPath := '\Software\Jedi Dreams\Mat16\mru_folders';
  adpMRUFolder.MaxItems := 10;

  isbatch := False;

  {File menu: batch convert bmps to 16-bit 565 mats (added in code, right after the mat16s batch item)}
  BatchConvertBMPsTo565Item := TMenuItem.Create(Self);
  BatchConvertBMPsTo565Item.Caption := 'Batch Convert (bmp''s to 16-bit 565 mat)';
  BatchConvertBMPsTo565Item.OnClick := BatchConvertBMPsTo565Click;
  BatchConvertBMPs1.Parent.Insert(BatchConvertBMPs1.MenuIndex + 1, BatchConvertBMPsTo565Item);

 {Tools menu: MAT header editor (added in code)}
  MatHeaderEditorItem := TMenuItem.Create(Self);
  MatHeaderEditorItem.Caption := 'MAT &Header Editor...';
  MatHeaderEditorItem.OnClick := MatHeaderEditorClick;
  Tools1.Add(MatHeaderEditorItem);

 {Tools menu: find mats by format, transparency flag, cells or palette colours}
  EmissiveSearchItem := TMenuItem.Create(Self);
  EmissiveSearchItem.Caption := 'Find &mats...';
  EmissiveSearchItem.OnClick := EmissiveSearchClick;
  Tools1.Add(EmissiveSearchItem);

  FZoomFactor := 1;
  {View as Transparent is on by default}
  ViewasTransparent1.Checked := True;
  image1.Transparent := False;   {transparency is composed onto a grid, not keyed from the corner pixel}

  {Tools menu: automatic colour map selection (remembered in the registry)}
  AutoPaletteItem := TMenuItem.Create(Self);
  AutoPaletteItem.Caption := 'Auto-select &palette';
  AutoPaletteItem.OnClick := AutoPaletteClick;
  AutoPaletteItem.Checked := True;
  Tools1.Add(AutoPaletteItem);
  with TRegistry.Create do
  try
    if OpenKeyReadOnly('\Software\Jedi Dreams\Mat16') and ValueExists('AutoPalette') then
      AutoPaletteItem.Checked := ReadBool('AutoPalette');
  finally
    Free;
  end;
  AutoPaletteEnabled := AutoPaletteItem.Checked;
  AutoPaletteHook := procedure(const fn: string)
    begin
      AutoPickPalette(fn);
    end;

  {standard keyboard shortcuts (set in code so the form file does not change)}
  FileOpenItem.ShortCut            := ShortCut(Ord('O'), [ssCtrl]);
  Createnewmatfrombmps1.ShortCut   := ShortCut(Ord('N'), [ssCtrl]);
  FileSaveItem.ShortCut            := ShortCut(Ord('S'), [ssCtrl]);
  SaveCMPas1.ShortCut              := ShortCut(Ord('S'), [ssCtrl, ssShift]);
  Browsematsinfolder1.ShortCut     := ShortCut(Ord('O'), [ssCtrl, ssShift]);
  OpenGOBGOO1.ShortCut             := ShortCut(Ord('G'), [ssCtrl]);
  LoadColorMapCMP1.ShortCut        := ShortCut(Ord('L'), [ssCtrl]);
  BatchConvertMATBMP1.ShortCut     := ShortCut(Ord('B'), [ssCtrl]);
  BatchConvertBMPs1.ShortCut       := ShortCut(Ord('B'), [ssCtrl, ssShift]);
  FileExitItem.ShortCut            := ShortCut(Ord('Q'), [ssCtrl]);
  Options1.ShortCut                := ShortCut(Ord('P'), [ssCtrl]);
  AddCell1.ShortCut                := ShortCut(Ord('E'), [ssCtrl]);
  ViewasTransparent1.ShortCut      := ShortCut(Ord('T'), [ssCtrl]);
  ViewMessages1.ShortCut           := ShortCut(Ord('M'), [ssCtrl]);
  MatHeaderEditorItem.ShortCut     := ShortCut(Ord('H'), [ssCtrl]);
  EmissiveSearchItem.ShortCut      := ShortCut(Ord('F'), [ssCtrl]);
  HelpAboutItem.ShortCut           := ShortCut(VK_F1, []);

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
       SetLightLevel(FLightLevel);
   BMPArray.RemapArrayfromCMP(MainCMP);
  TrackBarChange;

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
 SetLightLevel(FLightLevel);
  // UpDown_LightLevelClick;
  label17.Caption := '0';
end;

procedure TMainForm.OpenContainer(const FileName: string);
var
  ext: string;
begin
  ext := UpperCase(ExtractFileExt(FileName));
  if (ext = '.GOB') or (ext = '.GOO') then gobview.opengob(FileName)
  else if ext = '.CND' then gobview.opencnd(FileName)
  else if ext = '.B3D' then gobview.openb3d(FileName)
  else if (ext = '.DLL') or (ext = '.EXE') then gobview.opensote(FileName)
  else if ext = '.BAF' then gobview.openbaf(FileName)
  else Exit;
  gobview.Show;
  gobview.Label_FileName.Caption := FileName;
  adpMRUContainer.AddItem(FileName);
end;

procedure TMainForm.adpMRUContainerClick(Sender: TObject; const Filename: String);
begin
  if not FileExists(Filename) then
  begin
    ShowMessage('File not found: ' + Filename);
    Exit;
  end;
  image1.Transparent := False;   {transparency is composed onto a grid, not keyed from the corner pixel}
  VIewasTransparent1.Checked := True;
  OpenContainer(Filename);
end;

procedure TMainForm.OpenGOBGOO1Click(Sender: TObject);
begin

  //SaveAlphaChannel1.Enabled := False;
//  optionsform.readoptions;
  image1.Transparent := False;   {transparency is composed onto a grid, not keyed from the corner pixel}
  VIewasTransparent1.Checked := True;
  image1.Picture.Bitmap.Width := 32;
  image1.Picture.Bitmap.Height := 32;
  image1.Picture.Bitmap.Assign(nil);
  //Cell_ImageList.Clear;
  // Cell_TrackBar.Visible:=False;


  image1.Transparent := False;   {transparency is composed onto a grid, not keyed from the corner pixel}
  VIewasTransparent1.Checked := True;
  OpenDialog1.Filter := 'gob/goo/baf/cnd/b3d/sote dll/exe|*.gob;*.goo;*.baf;*.cnd;*.b3d;*.dll;*.exe';
  if OpenDialog1.Execute then
    OpenContainer(OpenDialog1.FileName);
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
 SetLightLevel(FLightLevel);
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

  image1.Transparent := False;
  if (not image1.Picture.Bitmap.Empty) and (BMPArray.GetCellCount > 0) then
    TrackBarChange;   {redraw the current cell with / without transparency}
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
  image1.Transparent := False;   {transparency is composed onto a grid, not keyed from the corner pixel}
  VIewasTransparent1.Checked := True;
  image1.Picture.Bitmap.Width := 32;
  image1.Picture.Bitmap.Height := 32;
  image1.Picture.Bitmap.Assign(nil);
 // Cell_ImageList.Clear;


end;

procedure TMainForm.FormShortCut(var Msg: TWMKey; var Handled: boolean);
begin
  {plain T is swallowed; Ctrl+T is the shortcut of View as Transparent}
  if (msg.charcode = Ord('T')) and (GetKeyState(VK_CONTROL) >= 0) then
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

{zoom step in pixels: 10, or an eighth of the current width for big images}
function ZoomStep(w: Integer): Integer;
begin
  Result := w div 8;
  if Result < 10 then Result := 10;
end;

procedure TMainForm.In1Click(Sender: TObject);
 var
  AspectRatio:double;
begin
  AspectRatio:=panel2.Height/panel2.Width;

  panel2.Width  := panel2.Width + ZoomStep(panel2.Width);    {steps grow with the image size}
  panel2.Height:=round(AspectRatio*panel2.Width);
  if image1.Picture.Bitmap.Width > 0 then
    FZoomFactor := panel2.Width / image1.Picture.Bitmap.Width;

end;

procedure TMainForm.Out1Click(Sender: TObject);
 var
  AspectRatio:double;
begin
   AspectRatio:=panel2.Height/panel2.Width;

  {zooming out is allowed below 100% so big textures (1024x1024...) fit in the window}
  if panel2.Width - ZoomStep(panel2.Width) >= 16  then
   begin
  panel2.Width  := panel2.Width - ZoomStep(panel2.Width);
  panel2.Height:=round(AspectRatio*panel2.Width);
  if image1.Picture.Bitmap.Width > 0 then
    FZoomFactor := panel2.Width / image1.Picture.Bitmap.Width;
   end;
end;

procedure TMainForm.Home1Click(Sender: TObject);
begin
  panel2.Width  := image1.Picture.Bitmap.Width;
  panel2.Height := image1.Picture.Bitmap.Height;
  FZoomFactor := 1;
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
  image1.Transparent := False;   {transparency is composed onto a grid, not keyed from the corner pixel}
  VIewasTransparent1.Checked := True;

    Screen.Cursor := crHourGlass;

    if UpperCase(ExtractFileExt(FileName)) = '.MAT' then
    begin
      formresetinfo;
      addcell   := False;
      starttime := GetTickCount;
      matopen(FileName);
      endtime := GetTickCount;
      StatusBar1.Panels[1].Text :=
        'mat loaded in ' + IntToStr(EndTime - StartTime) + 'mS' + FAutoPalNote;
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
      try
      LoadBMParray.OpenMTS(FileName);

      except
       On e:exception do
       begin
         ShowMessage(E.ClassName+' error raised, with message : '+E.Message);
         LoadBMParray.Free;
         Screen.Cursor := crDefault;
         exit;
       end;

     end;

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

unit gobform;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Grids, Math, System.Generics.Collections,
  main, util, gobgoo,ColorMap,CMPHeaders,MATImage,BMParrays,StrUtils;

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
    ConvertToBmp: TButton;
    Label18:   TLabel;
    Label_CMP: TLabel;
    procedure ListBox1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure opengob(filename: string);
    procedure openbaf(filename: string);
    procedure opencnd(filename: string);
    procedure openb3d(filename: string);
    procedure opensote(filename: string);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ConvertToBmpClick(Sender: TObject);
    procedure openfolder(foldername: string);
  private
    { Thumbnail view (replaces the plain list) }
    FGrid:      TDrawGrid;
    FBottom:    TPanel;
    FSelLabel:  TLabel;
    FStatus:    TLabel;
    FTimer:     TTimer;
    FThumbs:    TObjectList<TBitmap>;
    FCmpCache:  TDictionary<string, TCMPPal>;
    FBafPal:    TCMPPal;
    FBafLoaded: Boolean;
    FFolder:    Boolean;
    FKey:       string;
    FCols:      Integer;
    procedure EnsureUI;
    procedure ResetThumbs;
    procedure UpdateGridSize;
    function  BuildThumb(idx: Integer): TBitmap;
    procedure GridDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure GridSelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
    procedure TimerTick(Sender: TObject);
    procedure FormResizeEvt(Sender: TObject);
  public
    { Public declarations }
    destructor Destroy; override;
  end;

var
  gobview: Tgobview;
  bafinfo: Tbafinfo;
  FileOffsets: TFileOffsets;
  CMPOffsets: TFileOffsets;

implementation

uses Batch,GloabalVars,IOUtils,types;

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
  try
  if (UpperCase(ExtractFileExt(Label_FileName.Caption)) = '.GOB') or
     (UpperCase(ExtractFileExt(Label_FileName.Caption)) = '.GOO') or
     (UpperCase(ExtractFileExt(Label_FileName.Caption)) = '.MAT') or
     (UpperCase(ExtractFileExt(Label_FileName.Caption)) = '.CND') or
     (UpperCase(ExtractFileExt(Label_FileName.Caption)) = '.B3D') or
     (UpperCase(ExtractFileExt(Label_FileName.Caption)) = '.DLL') or
     (UpperCase(ExtractFileExt(Label_FileName.Caption)) = '.EXE') or
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
   if ((UpperCase(ExtractFileExt(Label_FileName.Caption)) = '.GOB') or
     (UpperCase(ExtractFileExt(Label_FileName.Caption)) = '.GOO')) and
     (not IsEmbeddedContainer(Label_FileName.Caption)) then
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

  if (UpperCase(ExtractFileExt(Label_FileName.Caption)) = '.MAT') then
     begin
     pos:=0;
     Label_FileName.Caption:=Label_SelectedFile.Caption;
      Mat.SetCMP(MainCMP.GetRGB);
     end;

  // pos:=GetGOBFileOffset(Label_FileName.Caption,Label_SelectedFile.Caption);
  if (UpperCase(ExtractFileExt(Label_FileName.Caption)) <> '.MAT') then
   begin
   pos:=GetGOBArrayOffset(FileOffsets, Label_SelectedFile.Caption);
   Mat.SetCMP(gobCMP.GetRGB);
   end;

   Label_Offset.Caption := IntToStr(pos);
   if IsEmbeddedContainer(Label_FileName.Caption) then
     tempA:= EmbeddedMatToArray(Label_FileName.Caption, pos, Mat)   {pos = material / texture page index}
   else
     tempA:= Mat.LoadFromFile(Label_FileName.Caption,pos);

  // image1.Picture.Bitmap.Assign(BMPArray.GetCell(0));

   label16.Caption := IntToStr(tempA.GetX);
   label17.Caption := IntToStr(tempA.GetY);

   label15.Caption:=tempA.fmt;

   main.MainForm.BMPArrayDisplay(tempA, Mat);  //function frees resources
   //Mat.free;
   //BMPArray.Free;
  end;
  finally
    gobCMP.Free;   {always freed, also for container types not listed above}
  end;
end;

procedure Tgobview.FormShow(Sender: TObject);
//var i:integer;
begin
  if not image1.Picture.bitmap.Empty then
    image1.Picture.Bitmap := nil;

  label14.Caption := IntToStr(ListBox1.Items.Count);

  EnsureUI;
  ResetThumbs;
  FTimer.Enabled := True;
end;

 procedure Tgobview.openbaf(filename: string);
 var
 tempList:Tstringlist;
 begin
 FFolder:=False;
 FileOffsets:=bafFilesToArray(filename, '.MAT');
 tempList:=gobFileArrayToList(FileOffsets);
 ListBox1.Items.Assign(tempList);
 tempList.Free;

 end;

 procedure Tgobview.opencnd(filename: string);
 var
 tempList:Tstringlist;
 begin
 FFolder:=False;
 FileOffsets:=cndFilesToArray(filename);
 SetLength(CMPOffsets,0);
 tempList:=gobFileArrayToList(FileOffsets);
 ListBox1.Items.Assign(tempList);
 tempList.Free;
 end;

 procedure Tgobview.openb3d(filename: string);
 var
 tempList:Tstringlist;
 begin
 FFolder:=False;
 if not AskB3DMode then Abort;
 FileOffsets:=b3dFilesToArray(filename);
 SetLength(CMPOffsets,0);
 tempList:=gobFileArrayToList(FileOffsets);
 ListBox1.Items.Assign(tempList);
 tempList.Free;
 end;

 procedure Tgobview.opensote(filename: string);
 var
 tempList:Tstringlist;
 begin
 FFolder:=False;
 if SameText(ExtractFileExt(filename), '.EXE') then FileOffsets:=soteExeFilesToArray(filename) else FileOffsets:=soteFilesToArray(filename);
 SetLength(CMPOffsets,0);
 tempList:=gobFileArrayToList(FileOffsets);
 ListBox1.Items.Assign(tempList);
 tempList.Free;
 end;

 procedure Tgobview.openfolder(foldername: string);
 var
  aFiles: TStringDynArray;
  sFile: String;
 begin
  FFolder:=True;
  Label_FileName.Caption:='folder.mat';

  aFiles := TDirectory.GetFiles(foldername, '*.mat');

  ListBox1.Items.BeginUpdate;
  try
    for sFile in aFiles do
      ListBox1.Items.Add(sFile);
  finally
    ListBox1.Items.EndUpdate;
  end;

  CMPOffsets:=gobFilesToArray(jkpath, '.CMP');
 end;

procedure Tgobview.opengob(filename: string);
var
tempList:Tstringlist;
//FileOffsets: TFileOffsets;
begin
FFolder:=False;
if IsDFGob(filename) then
begin
  FileOffsets:=dfFilesToArray(filename);   {Dark Forces GOB: BM textures}
  SetLength(CMPOffsets,0);
end
else
begin
//tempList:=gobFilesToList(filename, '.MAT');
FileOffsets:=gobFilesToArray(filename, '.MAT');
CMPOffsets:=gobFilesToArray(jkpath, '.CMP');
end;
tempList:=gobFileArrayToList(FileOffsets);
ListBox1.Items.Assign(tempList);
tempList.Free;
end;

procedure Tgobview.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if FTimer <> nil then FTimer.Enabled := False;
  if FThumbs <> nil then FThumbs.Clear;
  listbox1.Clear;
  SetLength(FileOffsets,0);
  SetLength(CMPOffsets,0);

end;

procedure Tgobview.ConvertToBmpClick(Sender: TObject);
var
  i: integer;
begin
  Screen.Cursor := crHourGlass;
  BatchForm.Show;
  BatchForm.ProgressBar1.Max := ListBox1.Items.Count;

  for i := 0 to (ListBox1.Items.Count - 1) do
  begin
    BatchForm.ProgressBar1.Position := i;
    if (UpperCase(ExtractFileExt(Label_FileName.Caption)) <> '.MAT') then
     BatchForm.Memo1.Lines.Add(GobMatSavetoBMP(Label_FileName.Caption, listBox1.Items.Strings[i],FileOffsets,CMPOffsets,true))
    else
     BatchForm.Memo1.Lines.Add(GobMatSavetoBMP('', listBox1.Items.Strings[i],FileOffsets,CMPOffsets,false));
    application.ProcessMessages;
  end;

  BatchForm.Memo1.Lines.Add('-Done-');
  Screen.Cursor := crDefault;
end;

{ ---------------------------------------------------------------------------
  Thumbnail view
  --------------------------------------------------------------------------- }

const
  THUMB_SIZE = 120;
  CELL_W     = 128;
  CELL_H     = 146;

function MakeThumb(Src: TBitmap; Is1555: Boolean): TBitmap;
var
  x, y, sx, sy, dw, dh, ox, oy, r, g, b, v: Integer;
  sc: Double;
  row: PWordArray;
  dst: PByteArray;
  w: Word;
  c: TColor;
  is16: Boolean;
  is8: Boolean;
  pe: array[0..255] of TPaletteEntry;
  row8: PByteArray;
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf24bit;
  Result.SetSize(THUMB_SIZE, THUMB_SIZE);
  { checkerboard background shows transparency }
  for y := 0 to THUMB_SIZE - 1 do
  begin
    dst := Result.ScanLine[y];
    for x := 0 to THUMB_SIZE - 1 do
    begin
      if (((x div 8) + (y div 8)) and 1) = 0 then v := $C8 else v := $96;
      dst^[x * 3] := v;
      dst^[x * 3 + 1] := v;
      dst^[x * 3 + 2] := v;
    end;
  end;
  if (Src.Width < 1) or (Src.Height < 1) then Exit;

  sc := Min(THUMB_SIZE / Src.Width, THUMB_SIZE / Src.Height);
  dw := Max(1, Min(THUMB_SIZE, Round(Src.Width * sc)));
  dh := Max(1, Min(THUMB_SIZE, Round(Src.Height * sc)));
  ox := (THUMB_SIZE - dw) div 2;
  oy := (THUMB_SIZE - dh) div 2;
  is16 := Src.PixelFormat in [pf15bit, pf16bit, pfCustom];
  if Src.PixelFormat = pf15bit then Is1555 := True;
  row := nil;
  row8 := nil;
  {8-bit: read indices and palette entries directly (Canvas.Pixels maps through the system palette)}
  is8 := (Src.PixelFormat = pf8bit) and (Src.Palette <> 0);
  if is8 then GetPaletteEntries(Src.Palette, 0, 256, pe);

  for y := 0 to dh - 1 do
  begin
    sy := y * Src.Height div dh;
    dst := Result.ScanLine[oy + y];
    if is16 then row := Src.ScanLine[sy];
    if is8 then row8 := Src.ScanLine[sy];
    for x := 0 to dw - 1 do
    begin
      sx := x * Src.Width div dw;
      if is16 then
      begin
        w := row^[sx];
        if Is1555 then
        begin
          if w = 0 then Continue;           { transparent }
          r := ((w shr 10) and 31) * 255 div 31;
          g := ((w shr 5) and 31) * 255 div 31;
          b := (w and 31) * 255 div 31;
        end
        else
        begin
          r := ((w shr 11) and 31) * 255 div 31;
          g := ((w shr 5) and 63) * 255 div 63;
          b := (w and 31) * 255 div 31;
        end;
      end
      else if is8 then
      begin
        r := pe[row8^[sx]].peRed;
        g := pe[row8^[sx]].peGreen;
        b := pe[row8^[sx]].peBlue;
      end
      else
      begin
        c := ColorToRGB(Src.Canvas.Pixels[sx, sy]);
        r := GetRValue(c);
        g := GetGValue(c);
        b := GetBValue(c);
      end;
      dst^[(ox + x) * 3]     := b;
      dst^[(ox + x) * 3 + 1] := g;
      dst^[(ox + x) * 3 + 2] := r;
    end;
  end;
end;

function MakeErrorThumb: TBitmap;
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf24bit;
  Result.SetSize(THUMB_SIZE, THUMB_SIZE);
  Result.Canvas.Brush.Color := clWhite;
  Result.Canvas.FillRect(Rect(0, 0, THUMB_SIZE, THUMB_SIZE));
  Result.Canvas.Pen.Color := clRed;
  Result.Canvas.Pen.Width := 3;
  Result.Canvas.MoveTo(20, 20);
  Result.Canvas.LineTo(THUMB_SIZE - 20, THUMB_SIZE - 20);
  Result.Canvas.MoveTo(THUMB_SIZE - 20, 20);
  Result.Canvas.LineTo(20, THUMB_SIZE - 20);
end;

destructor Tgobview.Destroy;
begin
  FThumbs.Free;
  FCmpCache.Free;
  inherited;
end;

procedure Tgobview.EnsureUI;
begin
  if FGrid <> nil then Exit;

  FThumbs   := TObjectList<TBitmap>.Create(True);
  FCmpCache := TDictionary<string, TCMPPal>.Create;

  ListBox1.Visible := False;        { still used as the item store }
  Label_FileName.Visible := False;
  ClientWidth  := 3 * (CELL_W + 1) + GetSystemMetrics(SM_CXVSCROLL) + 12;
  ClientHeight := 600;

  FBottom := TPanel.Create(Self);
  FBottom.Parent := Self;
  FBottom.Align := alBottom;
  FBottom.Height := 70;
  FBottom.BevelOuter := bvNone;

  FSelLabel := TLabel.Create(Self);
  FSelLabel.Parent := FBottom;
  FSelLabel.SetBounds(8, 4, 380, 15);
  FSelLabel.AutoSize := False;
  FSelLabel.Anchors := [akLeft, akTop, akRight];
  FSelLabel.EllipsisPosition := epPathEllipsis;

  FStatus := TLabel.Create(Self);
  FStatus.Parent := FBottom;
  FStatus.SetBounds(8, 22, 380, 15);
  FStatus.AutoSize := False;
  FStatus.Anchors := [akLeft, akTop, akRight];

  ConvertToBmp.Parent := FBottom;
  ConvertToBmp.SetBounds(8, 40, 121, 25);

  FGrid := TDrawGrid.Create(Self);
  FGrid.Parent := Self;
  FGrid.Align := alClient;
  FGrid.BorderStyle := bsNone;
  FGrid.FixedCols := 0;
  FGrid.FixedRows := 0;
  FGrid.ColCount := 3;
  FGrid.RowCount := 1;
  FGrid.DefaultColWidth := CELL_W;
  FGrid.DefaultRowHeight := CELL_H;
  FGrid.GridLineWidth := 1;
  FGrid.Options := [goVertLine, goHorzLine, goThumbTracking];
  FGrid.ScrollBars := ssVertical;
  FGrid.DoubleBuffered := True;
  FGrid.OnDrawCell := GridDrawCell;
  FGrid.OnSelectCell := GridSelectCell;
  FCols := 3;

  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := 10;
  FTimer.OnTimer := TimerTick;

  OnResize := FormResizeEvt;
end;

procedure Tgobview.UpdateGridSize;
var
  n: Integer;
begin
  if FGrid = nil then Exit;
  FCols := Max(1, (FGrid.ClientWidth - GetSystemMetrics(SM_CXVSCROLL)) div (CELL_W + 1));
  n := ListBox1.Items.Count;
  FGrid.ColCount := FCols;
  FGrid.RowCount := Max(1, (n + FCols - 1) div FCols);
  FGrid.Invalidate;
end;

procedure Tgobview.FormResizeEvt(Sender: TObject);
begin
  UpdateGridSize;
end;

procedure Tgobview.ResetThumbs;
var
  i: Integer;
  oldSel: TSelectCellEvent;
begin
  {a new file can have fewer rows than the old selection / scroll position: move to the top first
   (OnSelectCell is detached so this does not load a mat)}
  if FGrid <> nil then
  begin
    oldSel := FGrid.OnSelectCell;
    FGrid.OnSelectCell := nil;
    try
      try
        FGrid.TopRow := 0;
        FGrid.LeftCol := 0;
        FGrid.Row := 0;
        FGrid.Col := 0;
      except
      end;
    finally
      FGrid.OnSelectCell := oldSel;
    end;
  end;
  FThumbs.Clear;
  for i := 0 to ListBox1.Items.Count - 1 do
    FThumbs.Add(nil);
  FCmpCache.Clear;
  FBafLoaded := False;
  FStatus.Caption := '';
  UpdateGridSize;
  FTimer.Enabled := True;
end;

function Tgobview.BuildThumb(idx: Integer): TBitmap;
var
  itemName, ext, best: string;
  Mat: TMAT;
  arr: TBMPArray;
  pal: TCMPPal;
  cmp: TCMP;
  cell: TBitmap;
  p: Integer;
begin
  Result := nil;
  Mat := nil;
  arr := nil;
  itemName := ListBox1.Items[idx];
  try
    try
      Mat := TMAT.Create(TFormat.BMP);
      if FFolder then
      begin
        Mat.SetCMP(MainCMP.GetRGB);
        arr := Mat.LoadFromFile(itemName, 0);
      end
      else
      begin
        ext := UpperCase(ExtractFileExt(FKey));
        pal := MainCMP.GetRGB;
        if ((ext = '.GOB') or (ext = '.GOO')) and (not IsEmbeddedContainer(FKey)) then
        begin
          best := GetbestCMP(itemName, JKPath);
          if not FCmpCache.TryGetValue(best, pal) then
          begin
            cmp := TCMP.Create;
            try
              p := GetGOBArrayOffset(CMPOffsets, best);
              cmp.LoadCMPFromFile(jkpath, p);
              pal := cmp.GetRGB;
            finally
              cmp.Free;
            end;
            FCmpCache.Add(best, pal);
          end;
        end
        else if ext = '.BAF' then
        begin
          if not FBafLoaded then
          begin
            cmp := TCMP.Create;
            try
              cmp.LoadCMPFromBAFFile(FKey, 336);
              FBafPal := cmp.GetRGB;
            finally
              cmp.Free;
            end;
            FBafLoaded := True;
          end;
          pal := FBafPal;
        end;
        Mat.SetCMP(pal);
        if IsEmbeddedContainer(FKey) then
          arr := EmbeddedMatToArray(FKey, GetGOBArrayOffset(FileOffsets, itemName), Mat)
        else
          arr := Mat.LoadFromFile(FKey, GetGOBArrayOffset(FileOffsets, itemName));
      end;

      if (arr <> nil) and (arr.GetCellCount > 0) then
      begin
        cell := arr.GetCell(0);
        try
          Result := MakeThumb(cell, ContainsText(arr.fmt, '1555'));
        finally
          cell.Free;
        end;
      end;
    except
      on E: Exception do
      begin
        FreeAndNil(Result);
        try
          TFile.AppendAllText(TPath.Combine(TPath.GetTempPath, 'mat16_thumb_errors.log'),
            itemName + ' : ' + E.ClassName + ' : ' + E.Message + sLineBreak);
        except
        end;
      end;
    end;
  finally
    arr.Free;
    Mat.Free;
  end;
  if Result = nil then Result := MakeErrorThumb;
end;

procedure Tgobview.TimerTick(Sender: TObject);
var
  n, i, first, last, found, done: Integer;
begin
  if FGrid = nil then Exit;

  if (not FFolder) and (Label_FileName.Caption <> FKey) then
  begin
    FKey := Label_FileName.Caption;
    ResetThumbs;
    Exit;
  end;
  if FThumbs.Count <> ListBox1.Items.Count then
  begin
    ResetThumbs;
    Exit;
  end;

  n := FThumbs.Count;
  found := -1;
  first := Max(0, FGrid.TopRow * FCols);
  last  := Min(n - 1, (FGrid.TopRow + FGrid.VisibleRowCount + 1) * FCols - 1);
  for i := first to last do
    if FThumbs[i] = nil then begin found := i; Break; end;
  if found < 0 then
    for i := 0 to n - 1 do
      if FThumbs[i] = nil then begin found := i; Break; end;

  if found < 0 then
  begin
    FTimer.Enabled := False;
    if n > 0 then FStatus.Caption := IntToStr(n) + ' mats';
    Exit;
  end;

  FTimer.Enabled := False;      { no re-entry while loading }
  try
    FThumbs[found] := BuildThumb(found);
  finally
    FTimer.Enabled := True;
  end;

  done := 0;
  for i := 0 to n - 1 do
    if FThumbs[i] <> nil then Inc(done);
  FStatus.Caption := 'Building thumbnails ' + IntToStr(done) + ' / ' + IntToStr(n);
  FGrid.Invalidate;
end;

procedure Tgobview.GridDrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  idx: Integer;
  s: string;
  cv: TCanvas;
begin
  cv := FGrid.Canvas;
  idx := ARow * FCols + ACol;
  if gdSelected in State then
    cv.Brush.Color := clHighlight
  else
    cv.Brush.Color := clWindow;
  cv.FillRect(Rect);
  if (idx < 0) or (idx >= ListBox1.Items.Count) then Exit;

  if (idx < FThumbs.Count) and (FThumbs[idx] <> nil) then
    cv.Draw(Rect.Left + 4, Rect.Top + 4, FThumbs[idx])
  else
  begin
    cv.Brush.Color := clBtnFace;
    cv.FillRect(System.Types.Rect(Rect.Left + 4, Rect.Top + 4,
      Rect.Left + 4 + THUMB_SIZE, Rect.Top + 4 + THUMB_SIZE));
  end;

  s := ExtractName(ListBox1.Items[idx]);
  if gdSelected in State then
  begin
    cv.Brush.Color := clHighlight;
    cv.Font.Color := clHighlightText;
  end
  else
  begin
    cv.Brush.Color := clWindow;
    cv.Font.Color := clWindowText;
  end;
  cv.TextRect(System.Types.Rect(Rect.Left + 2, Rect.Top + THUMB_SIZE + 6,
    Rect.Right - 2, Rect.Bottom - 2), Rect.Left + 4, Rect.Top + THUMB_SIZE + 8, s);
end;

procedure Tgobview.GridSelectCell(Sender: TObject; ACol, ARow: Integer;
  var CanSelect: Boolean);
var
  idx: Integer;
begin
  idx := ARow * FCols + ACol;
  CanSelect := (idx >= 0) and (idx < ListBox1.Items.Count);
  if CanSelect then
  begin
    ListBox1.ItemIndex := idx;
    FSelLabel.Caption := ListBox1.Items[idx];
    ListBox1Click(ListBox1);
  end;
end;

end.

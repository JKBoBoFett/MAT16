unit MatSearch;
{Find mats in a folder by format, by the transparency / emissive flag in the mat header, by the number of cells
 and (8-bit mats) by the palette indices they use, e.g. the first two palette rows which JK draws full bright.
 Only the headers are read (pixels only when the palette check is on), so large folders are quick.}

interface

uses
  System.Classes, System.SysUtils, Vcl.Controls, Vcl.Forms, CMPHeaders, ColorMap;

type
  TOpenMatProc = reference to procedure(const filename: string);

{non-modal search window; OnOpen opens a mat in the main window}
procedure ShowMatSearch(const startFolder: string; OnOpen: TOpenMatProc);

implementation

uses
  System.IOUtils, System.Types, System.StrUtils, System.UITypes, System.Math, System.Generics.Collections,
  System.Generics.Defaults, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.CheckLst, Vcl.Dialogs, Vcl.Graphics,
  MATHeaders, System.Win.Registry;

const
  SEARCH_REG_KEY = '\Software\Jedi Dreams\Mat16';

{last used folder and sub folder option are kept in the registry}
procedure SaveSearchSettings(const folder: string; subs: Boolean);
var
  reg: TRegistry;
begin
  reg := TRegistry.Create;
  try
    if reg.OpenKey(SEARCH_REG_KEY, True) then
    begin
      reg.WriteString('FindFolder', folder);
      reg.WriteBool('FindSubFolders', subs);
    end;
  except
  end;
  reg.Free;
end;

procedure LoadSearchSettings(var folder: string; var subs: Boolean);
var
  reg: TRegistry;
begin
  reg := TRegistry.Create;
  try
    if reg.OpenKeyReadOnly(SEARCH_REG_KEY) then
    begin
      if reg.ValueExists('FindFolder') then folder := reg.ReadString('FindFolder');
      if reg.ValueExists('FindSubFolders') then subs := reg.ReadBool('FindSubFolders');
    end;
  except
  end;
  reg.Free;
end;

const
  FormatNames: array[0..13] of string = (
    '8-bit INDEXED', '8-bit trans INDEXED', '8-bit INDEXED int CMP', '8-bit trans INDEXED int CMP', '8-bit COLOR',
    '16-bit RGB565', '16-bit ARGB1555', '16-bit RGBA4444', '16-bit RGBA5551',
    '16-bit ARGB1555 emissive', '16-bit RGBA4444 emissive', '16-bit RGBA5551 emissive',
    '24-bit RGB', '32-bit RGBA');

type
  TMatInfo = record
    fmt: string;
    w, h, cells: Integer;
    anyTrans, anyEmis: Boolean;   {TransparentBool = 1 / = 2 in any cell}
    px, total: Integer;           {palette index hits / pixels (8-bit, when asked for)}
  end;

  TFound = record
    path: string;
    inf: TMatInfo;
  end;

  TMatSearchForm = class(TForm)
  private
    FOpen: TOpenMatProc;
    FFolder: TEdit;
    FSub: TCheckBox;
    FFormats: TCheckListBox;
    FTrans: TComboBox;
    FCellsBox: TComboBox;
    FPalOn: TCheckBox;
    FMaxIdx, FMinPx: TEdit;
    FScan, FStop, FExport: TButton;
    FStatus: TLabel;
    FView: TListView;
    FResults: TList<TFound>;
    FCancel: Boolean;
    FRoot: string;
    procedure BrowseClick(Sender: TObject);
    procedure ScanClick(Sender: TObject);
    procedure StopClick(Sender: TObject);
    procedure ExportClick(Sender: TObject);
    procedure ListDblClick(Sender: TObject);
    procedure AllNoneClick(Sender: TObject);
    procedure FormCloseEvt(Sender: TObject; var Action: TCloseAction);
    function Matches(const inf: TMatInfo; maxIdx, minPx: Integer): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  SearchForm: TMatSearchForm = nil;

function ClassifyFmt(const h: TMatHeader; tb: Integer): string;
begin
  Result := 'Unknown';
  case h.bits of
    8:
      if h.ColorMode = 0 then
      begin
        if h.mat_Type = 3 then
          Result := IfThen(tb = 1, '8-bit trans INDEXED int CMP', '8-bit INDEXED int CMP')
        else
          Result := IfThen(tb = 1, '8-bit trans INDEXED', '8-bit INDEXED');
      end;
    16:
      if h.ColorMode = 1 then
      begin
        if tb = 1 then Result := '16-bit ARGB1555'
        else if (tb = 2) and (h.alpha_bpp = 1) and (h.greenbits = 5) then Result := '16-bit ARGB1555 emissive'
        else Result := '16-bit RGB565';
      end
      else if h.ColorMode = 2 then
      begin
        if h.alpha_bpp = 1 then Result := '16-bit RGBA5551'
        else if h.alpha_bpp = 4 then Result := '16-bit RGBA4444';
        if (tb = 2) and (Result <> 'Unknown') then Result := Result + ' emissive';
      end;
    24: Result := '24-bit RGB';
    32: if (h.ColorMode = 2) and (h.alpha_bpp = 8) then Result := '32-bit RGBA';
  end;
end;

{reads the headers of a mat; wantIdx: also count pixels using palette indices <= maxIdx (8-bit mats)}
function ScanMat(const fname: string; wantIdx: Boolean; maxIdx: Integer; var inf: TMatInfo): Boolean;
var
  fs: TFileStream;
  h: TMatHeader;
  mh: TTextureMipmapHeader;
  i, k, bpp, nm, mx, my, tb0, n, got, c, skip0: Integer;
  buf: TBytes;
  isIdx: Boolean;
begin
  Result := False;
  FillChar(inf, SizeOf(inf), 0);
  inf.fmt := '';
  fs := TFileStream.Create(fname, fmOpenRead or fmShareDenyNone);
  try
    if fs.Size < SizeOf(h) then Exit;
    fs.ReadBuffer(h, SizeOf(h));
    if h.tag <> 'MAT ' then Exit;
    if (h.ver <> 10) and (h.ver <> 50) then Exit;
    if h.ver = 10 then
    begin
      h.mat_Type := 2;
      h.bits := 8;
    end;
    if (h.record_count < 0) or (h.record_count > 10000) or (h.cel_count < 0) or (h.cel_count > 10000) then Exit;
    if h.mat_Type = 0 then
    begin
      inf.fmt := '8-bit COLOR';
      inf.cells := h.record_count;
      Result := True;
      Exit;
    end;
    fs.Seek(Int64(h.record_count) * SizeOf(TTextureHeader), soCurrent);
    bpp := h.bits div 8;
    if bpp < 1 then Exit;
    inf.cells := h.cel_count;
    tb0 := 0;
    isIdx := False;
    SetLength(buf, 65536);
    for i := 0 to h.cel_count - 1 do
    begin
      if fs.Position + SizeOf(mh) > fs.Size then Break;
      fs.ReadBuffer(mh, SizeOf(mh));
      if (mh.SizeX <= 0) or (mh.SizeX > 8000) or (mh.SizeY <= 0) or (mh.SizeY > 8000) then Break;
      if i = 0 then
      begin
        tb0 := mh.TransparentBool;
        inf.w := mh.SizeX;
        inf.h := mh.SizeY;
        inf.fmt := ClassifyFmt(h, tb0);
        isIdx := StartsText('8-bit', inf.fmt) and (h.bits = 8);
      end;
      if mh.TransparentBool = 1 then inf.anyTrans := True;
      if mh.TransparentBool = 2 then inf.anyEmis := True;
      mx := mh.SizeX;
      my := mh.SizeY;
      n := mx * my * bpp;
      if wantIdx and isIdx then
      begin
        {index 0 is the transparent colour of a transparent mat, not an emissive one}
        if mh.TransparentBool = 1 then skip0 := 1 else skip0 := 0;
        while n > 0 do
        begin
          got := Min(n, Length(buf));
          if fs.Position + got > fs.Size then Break;
          fs.ReadBuffer(buf[0], got);
          for c := 0 to got - 1 do
            if (buf[c] <= maxIdx) and (buf[c] >= skip0) then Inc(inf.px);
          Inc(inf.total, got);
          Dec(n, got);
        end;
        if n > 0 then Break;
      end
      else
        fs.Seek(n, soCurrent);
      nm := mh.NumMipMaps;
      if (nm > 3) or (nm < 1) then nm := 1;
      for k := 1 to nm - 1 do
      begin
        mx := mx div 2;
        my := my div 2;
        fs.Seek(Int64(mx) * my * bpp, soCurrent);
      end;
    end;
    if inf.fmt = '' then inf.fmt := ClassifyFmt(h, 0);
    Result := True;
  finally
    fs.Free;
  end;
end;

constructor TMatSearchForm.Create(AOwner: TComponent);
var
  lbl: TLabel;
  btn: TButton;
  gb: TGroupBox;
  i: Integer;
begin
  inherited CreateNew(AOwner);
  Caption := 'Find mats';
  Position := poScreenCenter;
  ClientWidth := 800;
  ClientHeight := 600;
  BorderStyle := bsSizeable;
  OnClose := FormCloseEvt;
  FResults := TList<TFound>.Create;

  lbl := TLabel.Create(Self); lbl.Parent := Self; lbl.Left := 12; lbl.Top := 16; lbl.Caption := 'Folder:';
  FFolder := TEdit.Create(Self); FFolder.Parent := Self; FFolder.SetBounds(60, 12, 600, 23);
  FFolder.Anchors := [akLeft, akTop, akRight];
  btn := TButton.Create(Self); btn.Parent := Self; btn.SetBounds(668, 11, 120, 25);
  btn.Anchors := [akTop, akRight]; btn.Caption := 'Browse...'; btn.OnClick := BrowseClick;
  FSub := TCheckBox.Create(Self); FSub.Parent := Self; FSub.SetBounds(60, 40, 200, 19);
  FSub.Caption := 'Include sub folders'; FSub.Checked := True;

  {format list}
  gb := TGroupBox.Create(Self); gb.Parent := Self; gb.SetBounds(12, 66, 300, 270);
  gb.Caption := 'Mat format (none checked = any)';
  FFormats := TCheckListBox.Create(Self); FFormats.Parent := gb;
  FFormats.SetBounds(10, 20, 280, 212);
  for i := Low(FormatNames) to High(FormatNames) do FFormats.Items.Add(FormatNames[i]);
  btn := TButton.Create(Self); btn.Parent := gb; btn.SetBounds(10, 237, 70, 24); btn.Caption := 'All';
  btn.Tag := 1; btn.OnClick := AllNoneClick;
  btn := TButton.Create(Self); btn.Parent := gb; btn.SetBounds(86, 237, 70, 24); btn.Caption := 'None';
  btn.Tag := 0; btn.OnClick := AllNoneClick;

  {flags}
  gb := TGroupBox.Create(Self); gb.Parent := Self; gb.SetBounds(324, 66, 464, 130);
  gb.Caption := 'Header flags';
  lbl := TLabel.Create(Self); lbl.Parent := gb; lbl.Left := 12; lbl.Top := 30; lbl.Caption := 'Transparency bit:';
  FTrans := TComboBox.Create(Self); FTrans.Parent := gb; FTrans.Style := csDropDownList;
  FTrans.SetBounds(130, 26, 320, 23);
  FTrans.Items.Add('Any');
  FTrans.Items.Add('Transparent bit enabled');
  FTrans.Items.Add('Transparent bit not set');
  FTrans.Items.Add('Emissive flag (2)');
  FTrans.ItemIndex := 0;
  lbl := TLabel.Create(Self); lbl.Parent := gb; lbl.Left := 12; lbl.Top := 66; lbl.Caption := 'Cells:';
  FCellsBox := TComboBox.Create(Self); FCellsBox.Parent := gb; FCellsBox.Style := csDropDownList;
  FCellsBox.SetBounds(130, 62, 320, 23);
  FCellsBox.Items.Add('Any');
  FCellsBox.Items.Add('Single cell');
  FCellsBox.Items.Add('Multi cell (animated)');
  FCellsBox.ItemIndex := 0;
  lbl := TLabel.Create(Self); lbl.Parent := gb; lbl.Left := 12; lbl.Top := 98;
  lbl.Caption := 'The transparency bit is the flag in the mat header that turns transparency on.';
  lbl.Font.Size := 8;

  {palette check}
  gb := TGroupBox.Create(Self); gb.Parent := Self; gb.SetBounds(324, 204, 464, 132);
  gb.Caption := 'Palette colours (8-bit mats)';
  FPalOn := TCheckBox.Create(Self); FPalOn.Parent := gb; FPalOn.SetBounds(12, 24, 320, 19);
  FPalOn.Caption := 'Only mats that use palette indices';
  lbl := TLabel.Create(Self); lbl.Parent := gb; lbl.Left := 30; lbl.Top := 54; lbl.Caption := 'From 0 to';
  FMaxIdx := TEdit.Create(Self); FMaxIdx.Parent := gb; FMaxIdx.SetBounds(92, 50, 46, 23);
  FMaxIdx.Text := '31'; FMaxIdx.NumbersOnly := True;
  lbl := TLabel.Create(Self); lbl.Parent := gb; lbl.Left := 146; lbl.Top := 54;
  lbl.Caption := '(31 = first two rows, drawn full bright by JK)';
  lbl := TLabel.Create(Self); lbl.Parent := gb; lbl.Left := 30; lbl.Top := 88; lbl.Caption := 'At least';
  FMinPx := TEdit.Create(Self); FMinPx.Parent := gb; FMinPx.SetBounds(92, 84, 60, 23);
  FMinPx.Text := '1'; FMinPx.NumbersOnly := True;
  lbl := TLabel.Create(Self); lbl.Parent := gb; lbl.Left := 160; lbl.Top := 88; lbl.Caption := 'pixels';

  FScan := TButton.Create(Self); FScan.Parent := Self; FScan.SetBounds(12, 346, 90, 27);
  FScan.Caption := 'Scan'; FScan.Default := True; FScan.OnClick := ScanClick;
  FStop := TButton.Create(Self); FStop.Parent := Self; FStop.SetBounds(110, 346, 90, 27);
  FStop.Caption := 'Stop'; FStop.Enabled := False; FStop.OnClick := StopClick;
  FExport := TButton.Create(Self); FExport.Parent := Self; FExport.SetBounds(208, 346, 110, 27);
  FExport.Caption := 'Save list...'; FExport.Enabled := False; FExport.OnClick := ExportClick;
  FStatus := TLabel.Create(Self); FStatus.Parent := Self; FStatus.Left := 330; FStatus.Top := 352;
  FStatus.Caption := 'Double click a result to open it.';

  FView := TListView.Create(Self); FView.Parent := Self; FView.SetBounds(12, 384, 776, 206);
  FView.Anchors := [akLeft, akTop, akRight, akBottom];
  FView.ViewStyle := vsReport; FView.ReadOnly := True; FView.RowSelect := True;
  with FView.Columns.Add do begin Caption := 'Mat'; Width := 300; end;
  with FView.Columns.Add do begin Caption := 'Format'; Width := 190; end;
  with FView.Columns.Add do begin Caption := 'Size'; Width := 70; end;
  with FView.Columns.Add do begin Caption := 'Cells'; Width := 45; Alignment := taRightJustify; end;
  with FView.Columns.Add do begin Caption := 'Flag'; Width := 80; end;
  with FView.Columns.Add do begin Caption := 'Palette px'; Width := 75; Alignment := taRightJustify; end;
  FView.OnDblClick := ListDblClick;
end;

destructor TMatSearchForm.Destroy;
begin
  FResults.Free;
  inherited;
end;

procedure TMatSearchForm.FormCloseEvt(Sender: TObject; var Action: TCloseAction);
begin
  SaveSearchSettings(FFolder.Text, FSub.Checked);
  FCancel := True;      {stops a running scan; the window is only hidden so a running scan never loses its form}
  Action := caHide;
end;

procedure TMatSearchForm.AllNoneClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to FFormats.Count - 1 do FFormats.Checked[i] := TComponent(Sender).Tag = 1;
end;

procedure TMatSearchForm.BrowseClick(Sender: TObject);
begin
  with TFileOpenDialog.Create(nil) do
  try
    Options := [fdoPickFolders];
    if FFolder.Text <> '' then DefaultFolder := FFolder.Text;
    if Execute then FFolder.Text := FileName;
  finally
    Free;
  end;
end;

procedure TMatSearchForm.StopClick(Sender: TObject);
begin
  FCancel := True;
end;

function TMatSearchForm.Matches(const inf: TMatInfo; maxIdx, minPx: Integer): Boolean;
var
  i: Integer;
  anyFmt, fmtOk: Boolean;
begin
  Result := False;
  {format}
  anyFmt := False;
  fmtOk := False;
  for i := 0 to FFormats.Count - 1 do
    if FFormats.Checked[i] then
    begin
      anyFmt := True;
      if SameText(FFormats.Items[i], inf.fmt) then fmtOk := True;
    end;
  if anyFmt and not fmtOk then Exit;
  {transparency bit}
  case FTrans.ItemIndex of
    1: if not inf.anyTrans then Exit;
    2: if inf.anyTrans or inf.anyEmis then Exit;
    3: if not inf.anyEmis then Exit;
  end;
  {cells}
  case FCellsBox.ItemIndex of
    1: if inf.cells <> 1 then Exit;
    2: if inf.cells < 2 then Exit;
  end;
  {palette}
  if FPalOn.Checked then
  begin
    if not StartsText('8-bit', inf.fmt) or SameText(inf.fmt, '8-bit COLOR') then Exit;
    if inf.px < minPx then Exit;
  end;
  Result := True;
end;

procedure TMatSearchForm.ScanClick(Sender: TObject);
var
  files: TStringDynArray;
  i, maxIdx, minPx, errors, scanned: Integer;
  so: TSearchOption;
  it: TListItem;
  f: TFound;
  inf: TMatInfo;
  flag: string;
begin
  if not TDirectory.Exists(FFolder.Text) then
  begin
    ShowMessage('Pick a folder first.');
    Exit;
  end;
  maxIdx := EnsureRange(StrToIntDef(FMaxIdx.Text, 31), 0, 255);
  minPx := Max(1, StrToIntDef(FMinPx.Text, 1));
  if FSub.Checked then so := TSearchOption.soAllDirectories else so := TSearchOption.soTopDirectoryOnly;
  FRoot := IncludeTrailingPathDelimiter(FFolder.Text);
  SaveSearchSettings(FFolder.Text, FSub.Checked);
  try
    files := TDirectory.GetFiles(FFolder.Text, '*.mat', so);
  except
    on E: Exception do
    begin
      ShowMessage('Cannot list the folder: ' + E.Message);
      Exit;
    end;
  end;
  FResults.Clear;
  FView.Items.Clear;
  FCancel := False;
  FScan.Enabled := False; FStop.Enabled := True; FExport.Enabled := False;
  errors := 0;
  scanned := 0;
  try
    for i := 0 to High(files) do
    begin
      if FCancel or (csDestroying in ComponentState) then Break;
      if (i mod 20) = 0 then
      begin
        FStatus.Caption := Format('Scanning %d / %d   found %d', [i + 1, Length(files), FResults.Count]);
        Application.ProcessMessages;
        if FCancel then Break;
      end;
      try
        if ScanMat(files[i], FPalOn.Checked, maxIdx, inf) then
        begin
          Inc(scanned);
          if Matches(inf, maxIdx, minPx) then
          begin
            f.path := files[i];
            f.inf := inf;
            FResults.Add(f);
          end;
        end
        else
          Inc(errors);
      except
        Inc(errors);
      end;
    end;
  finally
    if not (csDestroying in ComponentState) then
    begin
      FResults.Sort(TComparer<TFound>.Construct(
        function(const A, B: TFound): Integer
        begin
          Result := CompareText(A.path, B.path);
        end));
      FView.Items.BeginUpdate;
      try
        for f in FResults do
        begin
          it := FView.Items.Add;
          if StartsText(FRoot, f.path) then it.Caption := Copy(f.path, Length(FRoot) + 1, MaxInt)
          else it.Caption := f.path;
          it.SubItems.Add(f.inf.fmt);
          it.SubItems.Add(IfThen(f.inf.w > 0, IntToStr(f.inf.w) + 'x' + IntToStr(f.inf.h), ''));
          it.SubItems.Add(IntToStr(f.inf.cells));
          if f.inf.anyEmis then flag := 'emissive'
          else if f.inf.anyTrans then flag := 'transparent'
          else flag := '-';
          it.SubItems.Add(flag);
          it.SubItems.Add(IfThen(FPalOn.Checked, IntToStr(f.inf.px), ''));
        end;
      finally
        FView.Items.EndUpdate;
      end;
      FStatus.Caption := Format('%d mats scanned, %d match%s. Double click a result to open it.',
        [scanned, FResults.Count, IfThen(errors > 0, ', ' + IntToStr(errors) + ' could not be read', '')]);
      FScan.Enabled := True; FStop.Enabled := False;
      FExport.Enabled := FResults.Count > 0;
    end;
  end;
end;

procedure TMatSearchForm.ListDblClick(Sender: TObject);
begin
  if (FView.Selected <> nil) and Assigned(FOpen) and (FView.Selected.Index < FResults.Count) then
    FOpen(FResults[FView.Selected.Index].path);
end;

procedure TMatSearchForm.ExportClick(Sender: TObject);
var
  sl: TStringList;
  f: TFound;
begin
  with TSaveDialog.Create(nil) do
  try
    Filter := 'Text file|*.txt';
    DefaultExt := 'txt';
    FileName := 'found_mats.txt';
    if not Execute then Exit;
    sl := TStringList.Create;
    try
      for f in FResults do
        sl.Add(f.path + #9 + f.inf.fmt + #9 + IntToStr(f.inf.w) + 'x' + IntToStr(f.inf.h) + #9 +
          IntToStr(f.inf.cells) + ' cell(s)');
      sl.SaveToFile(FileName);
    finally
      sl.Free;
    end;
  finally
    Free;
  end;
end;

procedure ShowMatSearch(const startFolder: string; OnOpen: TOpenMatProc);
var
  saved: string;
  subs: Boolean;
begin
  if SearchForm = nil then
  begin
    SearchForm := TMatSearchForm.Create(Application);
    SearchForm.FFolder.Text := startFolder;
    if startFolder = '' then
    begin
      saved := '';
      subs := SearchForm.FSub.Checked;
      LoadSearchSettings(saved, subs);
      if (saved <> '') and TDirectory.Exists(saved) then SearchForm.FFolder.Text := saved;
      SearchForm.FSub.Checked := subs;
    end;
  end;
  SearchForm.FOpen := OnOpen;
  SearchForm.Show;
  SearchForm.BringToFront;
end;

end.

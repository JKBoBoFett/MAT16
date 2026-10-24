unit AutoPalette;

{ Finds the colour map (palette) that suits an 8-bit mat best.

  A wrong palette shows up as a lot of magenta (and a noisy, unrelated looking picture),
  so every candidate palette is scored on the first cell of the mat:
    - the share of pixels that map to magenta
    - how rough the picture is (average colour step between neighbouring pixels)
  and the candidate with the lowest score wins. }

interface

uses
  System.Classes, System.SysUtils, System.Math, System.StrUtils, MATHeaders, CMPHeaders, ColorMap, gobgoo;

type
  TPalHook = reference to procedure(const filename: string);

type
  {colour maps that can be tried against a mat}
  TPalCandidates = class
  public
    Names: TStringList;
    Pals: array of TCMPPal;
    Containers: array of string;
    Offsets: array of Integer;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure AddFrom(const Offs: TFileOffsets);
  end;

var
  {Tools > Auto-select palette}
  AutoPaletteEnabled: Boolean = True;
  {set by the main form; the folder browser calls it before it loads a mat}
  AutoPaletteHook: TPalHook = nil;

{reads the palette indices of cell 0 / mip 0 of an 8-bit mat that uses an external colour map}
function ReadMatIndices(const fname: string; out w, h: Integer; out trans: Boolean;
  out px: TBytes): Boolean;

{same as ReadMatIndices for a mat that lives inside a container (gob) at the given offset}
function ReadMatIndicesAt(const fname: string; offset: Int64; out w, h: Integer; out trans: Boolean;
  out px: TBytes): Boolean;

{chooses the colour map for a mat: returns the index into Cands or -1 to keep the current one.
 curName is the name of the colour map in use, matName the mat's file name (stock levels use the
 same number prefix on mats and colour maps)}
function ChoosePalette(Cands: TPalCandidates; const px: TBytes; w, h: Integer; trans: Boolean;
  const cur: TCMPPal; const curName, matName: string): Integer;

{share of pixels that map to magenta, and the combined score (lower = better)}
procedure ScorePalette(const px: TBytes; w, h: Integer; trans: Boolean; const pal: TCMPPal;
  out magenta, score: Double);

implementation

function ReadMatIndices(const fname: string; out w, h: Integer; out trans: Boolean;
  out px: TBytes): Boolean;
begin
  Result := ReadMatIndicesAt(fname, 0, w, h, trans, px);
end;

function ReadMatIndicesAt(const fname: string; offset: Int64; out w, h: Integer; out trans: Boolean;
  out px: TBytes): Boolean;
var
  fs: TFileStream;
  hd: TMatHeader;
  mh: TTextureMipmapHeader;
begin
  Result := False;
  w := 0;
  h := 0;
  trans := False;
  SetLength(px, 0);
  try
    fs := TFileStream.Create(fname, fmOpenRead or fmShareDenyNone);
  except
    Exit;
  end;
  try
    if fs.Size < offset + SizeOf(hd) then Exit;
    fs.Position := offset;
    fs.ReadBuffer(hd, SizeOf(hd));
    if hd.tag <> 'MAT ' then Exit;
    if (hd.ver <> 10) and (hd.ver <> 50) then Exit;
    if hd.ver = 10 then
    begin
      hd.mat_Type := 2;
      hd.bits := 8;
    end;
    if (hd.mat_Type <> 2) or (hd.bits <> 8) or (hd.cel_count < 1) then Exit;
    if (hd.record_count < 0) or (hd.record_count > 10000) then Exit;
    fs.Seek(Int64(hd.record_count) * SizeOf(TTextureHeader), soCurrent);
    if fs.Position + SizeOf(mh) > fs.Size then Exit;
    fs.ReadBuffer(mh, SizeOf(mh));
    if (mh.SizeX <= 0) or (mh.SizeX > 4096) or (mh.SizeY <= 0) or (mh.SizeY > 4096) then Exit;
    if fs.Position + Int64(mh.SizeX) * mh.SizeY > fs.Size then Exit;
    w := mh.SizeX;
    h := mh.SizeY;
    trans := mh.TransparentBool = 1;
    SetLength(px, w * h);
    fs.ReadBuffer(px[0], w * h);
    Result := True;
  finally
    fs.Free;
  end;
end;

procedure ScorePalette(const px: TBytes; w, h: Integer; trans: Boolean; const pal: TCMPPal;
  out magenta, score: Double);
var
  x, y, step, n, nm, np, i0, i1, d: Integer;
  skip0: Integer;
  rough: Double;
begin
  magenta := 0;
  score := 0;
  if (w < 1) or (h < 1) or (Length(px) < w * h) then Exit;
  if trans then skip0 := 1 else skip0 := 0;
  step := Max(1, Max(w, h) div 128);     {large mats are sampled}
  n := 0;
  nm := 0;
  np := 0;
  rough := 0;
  y := 0;
  while y < h do
  begin
    x := 0;
    while x < w do
    begin
      i0 := px[y * w + x];
      if i0 >= skip0 then
      begin
        Inc(n);
        if (pal[i0].r >= 192) and (pal[i0].b >= 192) and (pal[i0].g <= 96) then Inc(nm);
        if x + step < w then
        begin
          i1 := px[y * w + x + step];
          if i1 >= skip0 then
          begin
            d := Abs(pal[i0].r - pal[i1].r) + Abs(pal[i0].g - pal[i1].g) + Abs(pal[i0].b - pal[i1].b);
            rough := rough + d / 765.0;
            Inc(np);
          end;
        end;
      end;
      Inc(x, step);
    end;
    Inc(y, step);
  end;
  if n > 0 then magenta := nm / n;
  if np > 0 then rough := rough / np else rough := 0;
  score := magenta * 20 + rough;
end;

constructor TPalCandidates.Create;
begin
  inherited;
  Names := TStringList.Create;
end;

destructor TPalCandidates.Destroy;
begin
  Names.Free;
  inherited;
end;

procedure TPalCandidates.Clear;
begin
  Names.Clear;
  SetLength(Pals, 0);
  SetLength(Containers, 0);
  SetLength(Offsets, 0);
end;

procedure TPalCandidates.AddFrom(const Offs: TFileOffsets);
var
  i, n: Integer;
  cmp: TCMP;
begin
  cmp := TCMP.Create;
  try
    for i := 0 to High(Offs) do
    begin
      try
        cmp.LoadCMPFromFile(Offs[i].container, Offs[i].offset);
        n := Names.Count;
        SetLength(Pals, n + 1);
        SetLength(Containers, n + 1);
        SetLength(Offsets, n + 1);
        Pals[n] := cmp.GetRGB;
        Containers[n] := Offs[i].container;
        Offsets[n] := Offs[i].offset;
        Names.Add(Offs[i].filename);
      except
      end;
    end;
  finally
    cmp.Free;
  end;
end;

function PlainName(const s: string): string;
begin
  Result := ExtractFileName(StringReplace(s, '/', '\', [rfReplaceAll]));
end;

function ChoosePalette(Cands: TPalCandidates; const px: TBytes; w, h: Integer; trans: Boolean;
  const cur: TCMPPal; const curName, matName: string): Integer;
var
  i, c, pIdx: Integer;
  curMag, curScore, mag, sc, bestScore, bestMag, pMag, pSc: Double;
  prefix, nm: string;
  curOK, usedPrefix: Boolean;
begin
  Result := -1;
  if (Cands = nil) or (Cands.Names.Count = 0) then Exit;
  ScorePalette(px, w, h, trans, cur, curMag, curScore);
  prefix := '';
  nm := ExtractFileName(matName);
  c := 1;
  while (c <= Length(nm)) and CharInSet(nm[c], ['0'..'9']) do
  begin
    prefix := prefix + nm[c];
    Inc(c);
  end;
  curOK := (prefix = '') or StartsText(prefix, PlainName(curName));
  if (curMag < 0.02) and curOK then Exit;

  bestScore := curScore;
  bestMag := curMag;
  for i := 0 to Cands.Names.Count - 1 do
  begin
    ScorePalette(px, w, h, trans, Cands.Pals[i], mag, sc);
    if sc < bestScore then
    begin
      bestScore := sc;
      bestMag := mag;
      Result := i;
    end;
  end;

  usedPrefix := False;
  if prefix <> '' then
  begin
    pIdx := -1;
    for i := 0 to Cands.Names.Count - 1 do
      if StartsText(prefix, PlainName(Cands.Names[i])) then
      begin
        ScorePalette(px, w, h, trans, Cands.Pals[i], pMag, pSc);
        if (pMag <= curMag + 0.01) and (pMag <= bestMag + 0.01) and ((pIdx < 0) or (pSc < bestScore)) then
        begin
          pIdx := i;
          bestScore := pSc;
          bestMag := pMag;
        end;
      end;
    if pIdx >= 0 then
    begin
      Result := pIdx;
      usedPrefix := True;
    end;
  end;
  if (Result >= 0) and (not usedPrefix) and (bestMag > curMag * 0.5) then Result := -1;
end;

end.

unit gobgoo;

interface

uses  Classes, SysUtils, System.IOUtils,Vcl.Dialogs,Vcl.Forms,Vcl.Controls,Vcl.StdCtrls,Vcl.ExtCtrls,System.UITypes,Vcl.Graphics,CMPHeaders,colormap,GloabalVars,MATImage,BMParrays,util,System.StrUtils,System.Math;

type

  //TFInfo=TFileInfo;
  TFileOffsets = array of record
    container: string;
    filename:    string;
    offset: integer;
    end;

  {GOB2 declarations}
  TGOB2Header = record
    Magic:    array[0..3] of ANSIchar; {='GOB'#20}
    Long1, long2: longint; { $14, $C}
    NEntries: longint;
  end;

  TGOB2Entry = record
    Pos, size: longint;
    Name:      array[0..127] of ANSIchar;
  end;


   Tgob = class
    private
    gh:  TGOB2Header;
    ge:  TGob2Entry;
    MATfiles: TStringList;
    CMPfiles: TStringList;
    f: file;
    public
    constructor Create;
    procedure LoadFromFile(filename: string);
   end;


procedure opengob(filename: string);
procedure getmat(matname: string);
function GetGOBFileOffset(gobfile: string; fileinGobName: string):longint;
function GetGOBArrayOffset(FileOffsets: TFileOffsets; fileinGobName: string):longint;
function gobFilesToList(gobfilename: string; filetype:string):TstringList;
function gobFilesToArray(gobfilename: string; filetype:string):TFileOffsets;
function bafFilesToArray(gobfilename: string; filetype:string):TFileOffsets;
function bafFilesToList(gobfilename: string; filetype:string):TstringList;
function gobFileArrayToList(FileOffsets: TFileOffsets):TstringList;
{Indiana Jones 3D (Infernal Machine) .CND level files: the materials are stored inside the level.
 cndFilesToArray lists them, the offset field holds the material index.}
function cndFilesToArray(const cndname: string):TFileOffsets;
function CNDMatToArray(const cndname: string; matIndex: Integer; Mat: TMAT):TBMPArray;
{Obi-Wan .B3D levels (compressed or not): the level texture pages (B3D_TEX chunk, 8-bit indexed with the
 B3D_PALS palettes) are listed as <level>_tex00.mat ...  The offset field holds the page index.}
var
  {How B3D sub-textures are delivered:  0 = 8-bit indexed, padded to a power of 2 by tiling
                                         1 = 16-bit RGB565, smoothly (bilinear) resized to a power of 2}
  B3DMode: Integer = 1;
  {palette index 0 as transparent in sub-textures: 0 = off, 1 = auto (textures where it covers >= 10% of the pixels)}
  B3DTransparent: Integer = 1;
  {trim rows/columns that are entirely palette index 0 from the edges of sub-textures: 0 = off, 1 = on}
  B3DTrim: Integer = 0;

{asks how B3D sub-textures should be delivered (sets B3DMode); False = cancelled}
function AskB3DMode: Boolean;

function b3dFilesToArray(const b3dname: string):TFileOffsets;
function B3DPageToArray(const b3dname: string; pageIndex: Integer; Mat: TMAT):TBMPArray;
{Shadows of the Empire demo DATAxx.DLL: tiled textures stitched to full images (16-bit)}
function soteFilesToArray(const dllname: string):TFileOffsets;
{Shadows of the Empire demo shadows.exe level texture pool}
function soteExeFilesToArray(const exename: string):TFileOffsets;
{containers whose mats are not real .MAT files (CND, B3D) and are loaded by index}
{Dark Forces GOB files ('GOB' + LF): BM textures with the VGA palette from SECBASE.PAL}
function IsDFGob(const fname: string): Boolean;
function dfFilesToArray(const gobname: string):TFileOffsets;
function IsEmbeddedContainer(const fname: string): Boolean;
function EmbeddedMatToArray(const fname: string; idx: Integer; Mat: TMAT):TBMPArray;
function GobMatSavetoBMP(gobfile: string; fileinGobName: string;FileOffsets: TFileOffsets;CMPOffsets: TFileOffsets;MatInGob:boolean):String;
function GobMatToArray(gobfile: string; fileinGobName: string;
           FileOffsets: TFileOffsets;CMPOffsets: TFileOffsets):TBMPArray;
 //procedure gobview.ListBox1Click(Sender: TObject);
 //TGOB2Directory=class(TContainerFile)
 //gh:TGob2Header;
 //Procedure Refresh;override;
 //end;
var
  gobfiles: TStringList;
  transp:   boolean;

implementation

 constructor Tgob.Create;
 begin

 end;

procedure Tgob.LoadFromFile(filename: string);
 begin

 end;



function GetGOBFileOffset(gobfile: string; fileinGobName: string):longint;
var
  j:      integer;
  ge:     TGob2Entry;
  gh:     TGOB2Header;
  f: file;
  found:boolean;
begin

  found:=false;

  AssignFile(f, gobfile);
  try
    Reset(f, 1);

    BlockRead(f, gh, SizeOf(gh));


    if gh.magic <> 'GOB ' then
      raise Exception.Create('not a GOB 2.0 file');

    for j := 0 to gh.NEntries - 1 do
    begin
      BlockRead(f, ge, SizeOf(ge));

      //find the mat
      if extractfilename(ge.Name) = extractfilename(fileinGobName) then
      begin
      result:=ge.Pos;
      found:=true;
       break;
      end;
    end;


    if not found then
    raise Exception.Create('File not found in container');

  finally
    CloseFile(f);
  end;
end;

function GetGOBArrayOffset(FileOffsets: TFileOffsets; fileinGobName: string):longint;
var
  j:      integer;
  found:boolean;
begin
found:=false;

 for j := 0 to Length(FileOffsets) - 1 do
    begin
      //find the mat
      if extractfilename(FileOffsets[j].filename) = extractfilename(fileinGobName) then
      begin
        result:=FileOffsets[j].offset;
        found:=true;
        break;
      end;
    end;

 if not found then
   raise Exception.CreateFmt('File offset for %s not found',[fileinGobName]);

end;


{ ---------------------------------------------------------------------------
  Indiana Jones 3D .CND materials
  Layout (see OpenJones3D sithWorld.c / sithMaterial.c):
    uint32 fileSize
    CndWorld header, 1564 bytes (version 3)
    sounds section: uint32 numSounds, uint32 dataSize, SoundInfo[numSounds] (48 bytes each),
                    dataSize bytes, uint32 nextHandle
    materials section: uint32 pixelDataSize, CndMaterialInfo[numMaterials] (136 bytes each),
                    pixel data: for each material, for each cel, for each mip level
  --------------------------------------------------------------------------- }
type
  TCndColorInfo = packed record
    colorMode, bpp, redBPP, greenBPP, blueBPP: Integer;
    redShl, greenShl, blueShl: Integer;
    redShr, greenShr, blueShr: Integer;
    alphaBPP, alphaShl, alphaShr: Integer;
  end;

  TCndMatInfo = packed record
    name: array[0..63] of AnsiChar;
    width, height, numCels, numMips: Cardinal;
    ci: TCndColorInfo;
  end;

const
  CND_WORLD_SIZE      = 1564;
  CND_VERSION_POS     = 4 + 1284;  {file offset of the version field}
  CND_NUMMATS_POS     = 4 + 1364;  {file offset of numMaterials}
  CND_SOUNDINFO_SIZE  = 48;
  CND_MAX_SUBMIPS     = 3;         {Mat16 keeps the main image plus 3 mip maps}

{finds the materials section; infoPos = file position of the first CndMaterialInfo}
function CNDLocate(var f: file; var numMat: Cardinal; var infoPos: Integer): Boolean;
var
  ver, sndCount, sndData: Cardinal;
  p: Integer;
begin
  Result := False;
  numMat := 0;
  infoPos := 0;
  if FileSize(f) < 4 + CND_WORLD_SIZE + 12 then Exit;

  Seek(f, CND_VERSION_POS);
  BlockRead(f, ver, 4);
  if ver <> 3 then Exit;

  Seek(f, CND_NUMMATS_POS);
  BlockRead(f, numMat, 4);

  p := 4 + CND_WORLD_SIZE;
  Seek(f, p);
  BlockRead(f, sndCount, 4);
  BlockRead(f, sndData, 4);
  if (sndCount > 100000) or (Int64(sndData) > FileSize(f)) then Exit;
  p := p + 8 + Integer(sndCount) * CND_SOUNDINFO_SIZE + Integer(sndData) + 4;

  infoPos := p + 4;  {skip the pixel data size}
  Result := (numMat > 0) and (numMat <= 8192) and
            (Int64(infoPos) + Int64(numMat) * SizeOf(TCndMatInfo) <= FileSize(f));
end;

function cndFilesToArray(const cndname: string):TFileOffsets;
var
  f: file;
  numMat: Cardinal;
  infoPos: Integer;
  info: TCndMatInfo;
  i: Integer;
begin
  SetLength(Result, 0);
  if not SysUtils.FileExists(cndname) then
  begin
    ShowMessage('container file not found');
    Exit;
  end;

  AssignFile(f, cndname);
  Reset(f, 1);
  try
    if not CNDLocate(f, numMat, infoPos) then
      raise Exception.Create(cndname + ' is not a supported Indiana Jones 3D CND file (version 3)');

    SetLength(Result, numMat);
    Seek(f, infoPos);
    for i := 0 to Integer(numMat) - 1 do
    begin
      BlockRead(f, info, SizeOf(info));
      info.name[63] := #0;
      Result[i].container := cndname;
      Result[i].filename := String(AnsiString(PAnsiChar(@info.name[0])));
      Result[i].offset := i;
    end;
  finally
    CloseFile(f);
  end;
end;

{0 = RGB565, 1 = RGBA4444, 2 = RGBA5551, 3 = 24-bit RGB, 4 = 32-bit RGBA}
function CNDKind(const ci: TCndColorInfo): Integer;
begin
  if (ci.bpp = 16) and (ci.alphaBPP = 0) and (ci.redBPP = 5) and (ci.greenBPP = 6) and
     (ci.blueBPP = 5) and (ci.redShl = 11) and (ci.greenShl = 5) and (ci.blueShl = 0) then
    Result := 0
  else if (ci.bpp = 16) and (ci.alphaBPP = 4) then
    Result := 1
  else if (ci.bpp = 16) and (ci.alphaBPP = 1) then
    Result := 2
  else if ci.bpp = 32 then
    Result := 4
  else
    Result := 3;
end;

{extracts one channel and scales it to 0..255}
function CNDChan(px: Cardinal; sh, bits: Integer): Byte;
var
  m, v: Cardinal;
begin
  if (bits <= 0) or (bits > 8) then
  begin
    Result := 0;
    Exit;
  end;
  m := (Cardinal(1) shl bits) - 1;
  v := (px shr sh) and m;
  Result := (v * 255) div m;
end;

function CNDMakeBitmap(kind: Integer; const ci: TCndColorInfo; w, h: Integer; const buf: TBytes): TBitmap;
var
  x, y, bytes, k, o: Integer;
  px: Cardinal;
  dst: PByte;
begin
  Result := TBitmap.Create;
  case kind of
    0: Result.PixelFormat := pf16bit;
    1, 2, 4: Result.PixelFormat := pf32bit;
  else
    Result.PixelFormat := pf24bit;
  end;
  Result.HandleType := bmDIB;
  if kind in [1, 4] then Result.AlphaFormat := afIgnored;  {setting as defined pre multiplies after conversion}
  if kind = 2 then Result.AlphaFormat := afDefined;
  Result.SetSize(w, h);

  bytes := ci.bpp div 8;
  for y := 0 to h - 1 do
  begin
    dst := Result.ScanLine[y];
    if kind = 0 then
    begin
      Move(buf[y * w * 2], dst^, w * 2);
      Continue;
    end;
    for x := 0 to w - 1 do
    begin
      o := (y * w + x) * bytes;
      px := 0;
      for k := bytes - 1 downto 0 do
        px := (px shl 8) or buf[o + k];

      if kind = 3 then
      begin
        dst^ := CNDChan(px, ci.blueShl, ci.blueBPP);  Inc(dst);
        dst^ := CNDChan(px, ci.greenShl, ci.greenBPP); Inc(dst);
        dst^ := CNDChan(px, ci.redShl, ci.redBPP);    Inc(dst);
      end
      else
      begin
        dst^ := CNDChan(px, ci.blueShl, ci.blueBPP);  Inc(dst);
        dst^ := CNDChan(px, ci.greenShl, ci.greenBPP); Inc(dst);
        dst^ := CNDChan(px, ci.redShl, ci.redBPP);    Inc(dst);
        if ci.alphaBPP > 0 then
          dst^ := CNDChan(px, ci.alphaShl, ci.alphaBPP)
        else
          dst^ := 255;
        Inc(dst);
      end;
    end;
  end;
end;

function CNDMipPixels(w, h, mips: Cardinal): Int64;
var
  i: Cardinal;
  cur: Int64;
begin
  Result := 0;
  cur := Int64(w) * h;
  i := 0;
  while (i < mips) and (cur > 0) do
  begin
    Inc(Result, cur);
    cur := cur shr 2;
    Inc(i);
  end;
end;

function CNDMatToArray(const cndname: string; matIndex: Integer; Mat: TMAT):TBMPArray;
var
  f: file;
  numMat: Cardinal;
  infoPos: Integer;
  infos: array of TCndMatInfo;
  mi: TCndMatInfo;
  k, cel, mip, w, h, kind, bytes: Integer;
  pixPos: Int64;
  buf: TBytes;
  bmp: TBitmap;
begin
  Result := TBMPARRAY.Create;
  AssignFile(f, cndname);
  Reset(f, 1);
  try
    try
      if not CNDLocate(f, numMat, infoPos) then
        raise Exception.Create(cndname + ' is not a supported Indiana Jones 3D CND file (version 3)');
      if (matIndex < 0) or (matIndex >= Integer(numMat)) then
        raise Exception.Create('material index out of range');

      SetLength(infos, numMat);
      Seek(f, infoPos);
      BlockRead(f, infos[0], numMat * SizeOf(TCndMatInfo));

      {pixel data follows the info array, one block per material}
      pixPos := Int64(infoPos) + Int64(numMat) * SizeOf(TCndMatInfo);
      for k := 0 to matIndex - 1 do
        pixPos := pixPos + Int64(infos[k].ci.bpp div 8) *
                  CNDMipPixels(infos[k].width, infos[k].height, infos[k].numMips) * infos[k].numCels;

      mi := infos[matIndex];
      mi.name[63] := #0;
      if not (mi.ci.bpp in [16, 24, 32]) or (mi.width = 0) or (mi.height = 0) or
         (mi.numCels = 0) or (mi.numCels > 16) or (mi.numMips = 0) or (mi.width > 4096) or (mi.height > 4096) then
        raise Exception.Create('unsupported material in CND: ' + String(AnsiString(PAnsiChar(@mi.name[0]))));
      if pixPos + Int64(mi.ci.bpp div 8) * CNDMipPixels(mi.width, mi.height, mi.numMips) * mi.numCels > FileSize(f) then
        raise Exception.Create('CND material data is outside of the file');

      kind := CNDKind(mi.ci);
      bytes := mi.ci.bpp div 8;
      Seek(f, Integer(pixPos));

      for cel := 0 to Integer(mi.numCels) - 1 do
        for mip := 0 to Integer(mi.numMips) - 1 do
        begin
          w := Integer(mi.width) shr mip;
          h := Integer(mi.height) shr mip;
          if (w < 1) or (h < 1) then Break;

          SetLength(buf, w * h * bytes);
          BlockRead(f, buf[0], Length(buf));

          if mip <= CND_MAX_SUBMIPS then
          begin
            bmp := CNDMakeBitmap(kind, mi.ci, w, h, buf);
            try
              if mip = 0 then
                Result.AddCellFromBMP(bmp)
              else
                Result.AddSubMipMapFromBMP(bmp);
            finally
              bmp.Free;
            end;
          end;
        end;

      Result.name := AnsiString(PAnsiChar(@mi.name[0]));
      case kind of
        0: begin Result.fmt := '16-bit RGB565';  Mat.matFormat := TFormat.RGB565; end;
        1: begin Result.fmt := '16-bit RGBA4444'; Mat.matFormat := TFormat.RGBA4444; end;
        2: begin Result.fmt := '16-bit RGBA5551'; Mat.matFormat := TFormat.RGBA5551; end;
        4: begin Result.fmt := '32-bit RGBA';    Mat.matFormat := TFormat.RGBA8888; end;
      else
        begin Result.fmt := '24-bit RGB'; Mat.matFormat := TFormat.RGB888; end;
      end;
      imageformat := Mat.matFormat;
    except
      FreeAndNil(Result);
      raise;
    end;
  finally
    CloseFile(f);
  end;
end;

{ ---------------------------------------------------------------------------
  Obi-Wan .B3D levels
    chunk = 8 char tag, uint32 size, data.  First chunk is 'B3D FILE' (2200 bytes), the rest follow.
    B3D_PALS: n * 768 bytes (RGB palettes)
    B3D_TEX : pages, each = int32 width, int32 height, int32 palette index, int32 reserved,
              then width*height 8-bit pixels
    Compressed levels (flag at header byte 796 = 1) are LZSS expanded in memory first.
  --------------------------------------------------------------------------- }
type
  TB3DChunk = packed record
    tag: array[0..7] of AnsiChar;
    size: Cardinal;
  end;

  TB3DPage = record
    pos, w, h, palIdx: Integer;
  end;
  TB3DPages = array of TB3DPage;

  {sub-texture of a page: pixel rectangle taken from the B3D_MAT chunk}
  TB3DMat = record
    page, x0, y0, x1, y1: Integer;
  end;
  TB3DMats = array of TB3DMat;

{LZSS (12 bit window index, 4 bit length, MSB first bits) used by the compressed levels}
function B3DExpand(const src: TBytes; start: Integer): TBytes;
var
  win: array[0..4095] of Byte;
  inPos, mask, rack, i, outLen, cap, p, l, j, k: Integer;
  c: Byte;
  eof: Boolean;

  function GetBit: Integer;
  begin
    if mask = $80 then
    begin
      if inPos >= Length(src) then
      begin
        eof := True;
        Result := 0;
        Exit;
      end;
      rack := src[inPos];
      Inc(inPos);
    end;
    if (rack and mask) <> 0 then Result := 1 else Result := 0;
    mask := mask shr 1;
    if mask = 0 then mask := $80;
  end;

  function GetBits(cnt: Integer): Integer;
  var m: Integer;
  begin
    Result := 0;
    m := 1 shl (cnt - 1);
    while (m <> 0) and (not eof) do
    begin
      if GetBit = 1 then Result := Result or m;
      m := m shr 1;
    end;
  end;

  procedure Put(b: Byte);
  begin
    if outLen >= cap then
    begin
      cap := cap * 2;
      SetLength(Result, cap);
    end;
    Result[outLen] := b;
    Inc(outLen);
    win[i and $FFF] := b;
    Inc(i);
  end;

begin
  FillChar(win, SizeOf(win), 0);
  cap := Length(src) * 4 + 65536;
  SetLength(Result, cap);
  outLen := 0;
  inPos := start;
  mask := $80;
  rack := 0;
  i := 1;
  eof := False;
  while not eof do
  begin
    if GetBit = 1 then
    begin
      k := GetBits(8);
      if eof then Break;
      Put(Byte(k));
    end
    else
    begin
      p := GetBits(12);
      if eof or (p = 0) then Break;
      l := GetBits(4) + 1;
      if eof then Break;
      for j := 0 to l do
      begin
        c := win[(p + j) and $FFF];
        Put(c);
      end;
    end;
  end;
  SetLength(Result, outLen);
end;

var
  B3DCacheName: string = '';
  B3DCacheStamp: Integer = 0;
  B3DCacheBuf: TBytes;

{Returns the level as a flat chunk image (header + chunks), expanding it when it is compressed.}
function B3DLoad(const fname: string): TBytes;
var
  fs: TFileStream;
  raw, ex: TBytes;
  stamp, hsz: Integer;
begin
  stamp := FileAge(fname);
  if SameText(B3DCacheName, fname) and (B3DCacheStamp = stamp) and (Length(B3DCacheBuf) > 0) then
  begin
    Result := B3DCacheBuf;
    Exit;
  end;
  fs := TFileStream.Create(fname, fmOpenRead or fmShareDenyNone);
  try
    SetLength(raw, fs.Size);
    if fs.Size > 0 then fs.ReadBuffer(raw[0], fs.Size);
  finally
    fs.Free;
  end;
  if (Length(raw) < 2212) then
    raise Exception.Create(fname + ' is not a B3D file');
  if not ((raw[0] = Ord('B')) and (raw[1] = Ord('3')) and (raw[2] = Ord('D')) and (raw[3] = Ord(' ')) and
          (raw[4] = Ord('F')) and (raw[5] = Ord('I')) and (raw[6] = Ord('L')) and (raw[7] = Ord('E'))) then
    raise Exception.Create(fname + ' is not a B3D file');
  hsz := 12 + PInteger(@raw[8])^;
  if (hsz = 2212) and (PInteger(@raw[12 + 796])^ = 1) then
  begin
    ex := B3DExpand(raw, hsz);
    SetLength(Result, hsz + Length(ex));
    Move(raw[0], Result[0], hsz);
    if Length(ex) > 0 then Move(ex[0], Result[hsz], Length(ex));
  end
  else
    Result := raw;
  B3DCacheName := fname;
  B3DCacheStamp := stamp;
  B3DCacheBuf := Result;
end;

procedure B3DScan(const fname: string; var buf: TBytes; var pals: TBytes; var pages: TB3DPages;
  var mats: TB3DMats);
var
  p, fsz, texPos, texEnd, q, n, csz, w, h, matPos, matSize, i, pg, k: Integer;
  tag: AnsiString;
  fl: array[0..7] of Single;
  umin, umax, vmin, vmax: Single;
  m: TB3DMat;
begin
  SetLength(pals, 0);
  SetLength(pages, 0);
  SetLength(mats, 0);
  matPos := -1;
  matSize := 0;
  buf := B3DLoad(fname);
  fsz := Length(buf);
  p := 12 + PInteger(@buf[8])^;
  texPos := -1;
  texEnd := 0;
  while p + 12 <= fsz do
  begin
    SetString(tag, PAnsiChar(@buf[p]), 8);
    csz := PInteger(@buf[p + 8])^;
    if (Copy(tag, 1, 3) <> 'B3D') or (csz < 0) or (Int64(p) + 12 + csz > fsz) then
      raise Exception.Create('Unknown B3D layout in ' + ExtractFileName(fname) + ' (chunk at ' + IntToStr(p) + ')');
    if tag = 'B3D_PALS' then
    begin
      SetLength(pals, csz);
      if csz > 0 then Move(buf[p + 12], pals[0], csz);
    end
    else if tag = 'B3D_TEX ' then
    begin
      texPos := p + 12;
      texEnd := texPos + csz;
    end
    else if tag = 'B3D_MAT ' then
    begin
      matPos := p + 12;
      matSize := csz;
    end
    else if tag = 'B3D_END1' then
      Break;
    p := p + 12 + csz;
  end;

  if texPos < 0 then
    raise Exception.Create('No textures (B3D_TEX) found in ' + ExtractFileName(fname));

  q := texPos;
  n := 0;
  while q + 16 <= texEnd do
  begin
    w := PInteger(@buf[q])^;
    h := PInteger(@buf[q + 4])^;
    if (w < 1) or (w > 2048) or (h < 1) or (h > 2048) or (q + 16 + w * h > texEnd) then
      Break;
    SetLength(pages, n + 1);
    pages[n].pos := q + 16;
    pages[n].w := w;
    pages[n].h := h;
    pages[n].palIdx := PInteger(@buf[q + 8])^;
    Inc(n);
    q := q + 16 + w * h;
  end;

  {B3D_MAT: records of 40 bytes = 4 corner UV pairs (floats) + page index + flags}
  if matPos >= 0 then
    for i := 0 to matSize div 40 - 1 do
    begin
      Move(buf[matPos + i * 40], fl[0], 32);
      pg := PInteger(@buf[matPos + i * 40 + 32])^;
      if (pg < 0) or (pg >= Length(pages)) then Continue;
      umin := fl[0]; umax := fl[0]; vmin := fl[1]; vmax := fl[1];
      for k := 1 to 3 do
      begin
        if fl[k * 2] < umin then umin := fl[k * 2];
        if fl[k * 2] > umax then umax := fl[k * 2];
        if fl[k * 2 + 1] < vmin then vmin := fl[k * 2 + 1];
        if fl[k * 2 + 1] > vmax then vmax := fl[k * 2 + 1];
      end;
      m.page := pg;
      m.x0 := Round(umin * pages[pg].w);
      m.x1 := Round(umax * pages[pg].w);
      m.y0 := Round(vmin * pages[pg].h);
      m.y1 := Round(vmax * pages[pg].h);
      if m.x0 < 0 then m.x0 := 0;
      if m.y0 < 0 then m.y0 := 0;
      if m.x1 > pages[pg].w then m.x1 := pages[pg].w;
      if m.y1 > pages[pg].h then m.y1 := pages[pg].h;
      if (m.x1 - m.x0 < 1) or (m.y1 - m.y0 < 1) then Continue;
      SetLength(mats, Length(mats) + 1);
      mats[High(mats)] := m;
    end;
end;

function AskB3DMode: Boolean;
var
  f: TForm;
  lb: TLabel;
  rg: TRadioGroup;
  cbTrans, cbTrim: TCheckBox;
  bOk, bCancel: TButton;
begin
  f := TForm.CreateNew(nil);
  try
    f.Caption := 'Mat16 - B3D level';
    f.BorderStyle := bsDialog;
    f.Position := poScreenCenter;
    f.ClientWidth := 484;
    f.ClientHeight := 268;

    lb := TLabel.Create(f);
    lb.Parent := f;
    lb.SetBounds(12, 10, 460, 52);
    lb.AutoSize := False;
    lb.WordWrap := True;
    lb.Caption := 'Level textures are cut out of shared atlas pages and have odd sizes (for example 72 x 44), ' +
                  'but Mat16 needs power of 2 sizes. The full atlas pages (_page) are not affected.';

    rg := TRadioGroup.Create(f);
    rg.Parent := f;
    rg.SetBounds(12, 68, 460, 76);
    rg.Caption := 'Textures';
    rg.Items.Add('16-bit, smoothly resized to a power of 2 (best looking, no palette)');
    rg.Items.Add('8-bit indexed, exact pixels, extra area filled by tiling (keeps the palette)');
    if B3DMode = 1 then rg.ItemIndex := 0 else rg.ItemIndex := 1;

    cbTrans := TCheckBox.Create(f);
    cbTrans.Parent := f;
    cbTrans.SetBounds(16, 154, 456, 20);
    cbTrans.Caption := 'Treat palette index 0 as transparent (auto-detected per texture)';
    cbTrans.Checked := (B3DTransparent = 1);

    cbTrim := TCheckBox.Create(f);
    cbTrim.Parent := f;
    cbTrim.SetBounds(16, 182, 456, 20);
    cbTrim.Caption := 'Trim empty (index 0) rows and columns from the edges of each texture';
    cbTrim.Checked := (B3DTrim = 1);

    bOk := TButton.Create(f);
    bOk.Parent := f;
    bOk.Caption := 'OK';
    bOk.ModalResult := mrOk;
    bOk.Default := True;
    bOk.SetBounds(298, 226, 80, 28);

    bCancel := TButton.Create(f);
    bCancel.Parent := f;
    bCancel.Caption := 'Cancel';
    bCancel.ModalResult := mrCancel;
    bCancel.Cancel := True;
    bCancel.SetBounds(392, 226, 80, 28);

    Result := (f.ShowModal = mrOk);
    if Result then
    begin
      if rg.ItemIndex = 1 then B3DMode := 0 else B3DMode := 1;
      if cbTrans.Checked then B3DTransparent := 1 else B3DTransparent := 0;
      if cbTrim.Checked then B3DTrim := 1 else B3DTrim := 0;
    end;
  finally
    f.Free;
  end;
end;

function b3dFilesToArray(const b3dname: string):TFileOffsets;
var
  pals: TBytes;
  pages: TB3DPages;
  mats: TB3DMats;
  buf: TBytes;
  i: Integer;
begin
  SetLength(Result, 0);
  if not SysUtils.FileExists(b3dname) then
  begin
    ShowMessage('container file not found');
    Exit;
  end;
  B3DScan(b3dname, buf, pals, pages, mats);
  SetLength(Result, Length(pages) + Length(mats));
  for i := 0 to Length(pages) - 1 do
  begin
    Result[i].container := b3dname;
    Result[i].filename := ChangeFileExt(ExtractFileName(b3dname), '') + '_page' + Format('%.2d', [i]) + '.mat';
    Result[i].offset := i;
  end;
  {sub-textures: offset = 1000 + index}
  for i := 0 to Length(mats) - 1 do
  begin
    Result[Length(pages) + i].container := b3dname;
    Result[Length(pages) + i].filename := ChangeFileExt(ExtractFileName(b3dname), '') + '_tex' + Format('%.3d', [i]) + '.mat';
    Result[Length(pages) + i].offset := 1000 + i;
  end;
end;

function B3DPageToArray(const b3dname: string; pageIndex: Integer; Mat: TMAT):TBMPArray;
var
  pals: TBytes;
  pages: TB3DPages;
  mats: TB3DMats;
  buf: TBytes;
  bmp: TBitmap;
  isSub, use16, trans: Boolean;
  tx0, tx1, ty0, ty1: Integer;
  idx0cnt, k0, k1, k2, k3: Integer;
  a0, a1, a2, a3, wsum, cov: Double;
  rgbBuf, alphaBuf: array of Byte;
  fx, fy, wx, wy: Double;
  ix, iy, ix1, iy1, c: Integer;
  v: array[0..2] of Double;
  row16: PWordArray;
  r5, g6, b5: Integer;
  pg, x0, y0, bw, bh, nm, tw, th, x: Integer;
  src, dst: PByte;

  pal: TCMPPal;
  k, y: Integer;
  po: Integer;
  function NextPow2(v: Integer): Integer;
  begin
    Result := 1;
    while Result < v do Result := Result shl 1;
  end;

  function RowEmpty(ry, xa, xb: Integer): Boolean;
  var xi: Integer;
  begin
    Result := True;
    for xi := xa to xb do
      if buf[pages[pg].pos + (y0 + ry) * pages[pg].w + x0 + xi] <> 0 then
      begin
        Result := False;
        Exit;
      end;
  end;

  function ColEmpty(cx, ya, yb: Integer): Boolean;
  var yi: Integer;
  begin
    Result := True;
    for yi := ya to yb do
      if buf[pages[pg].pos + (y0 + yi) * pages[pg].w + x0 + cx] <> 0 then
      begin
        Result := False;
        Exit;
      end;
  end;
begin
  B3DScan(b3dname, buf, pals, pages, mats);
  isSub := pageIndex >= 1000;
  if isSub then
  begin
    nm := pageIndex - 1000;
    if (nm < 0) or (nm >= Length(mats)) then
      raise Exception.Create('texture index out of range');
    pg := mats[nm].page;
    x0 := mats[nm].x0;
    y0 := mats[nm].y0;
    bw := mats[nm].x1 - x0;
    bh := mats[nm].y1 - y0;
  end
  else
  begin
    if (pageIndex < 0) or (pageIndex >= Length(pages)) then
      raise Exception.Create('texture page index out of range');
    pg := pageIndex;
    x0 := 0;
    y0 := 0;
    bw := pages[pg].w;
    bh := pages[pg].h;
  end;

  {palette of this page; grey ramp when the level has none}
  for k := 0 to 255 do
  begin
    po := pages[pg].palIdx * 768 + k * 3;
    if (pages[pg].palIdx >= 0) and (po + 2 < Length(pals)) then
    begin
      {B3D palettes are stored B,G,R}
      pal[k].r := pals[po + 2];
      pal[k].g := pals[po + 1];
      pal[k].b := pals[po];
    end
    else
    begin
      pal[k].r := k;
      pal[k].g := k;
      pal[k].b := k;
    end;
  end;

  use16 := isSub and (B3DMode = 1);
  trans := False;
  if isSub and (B3DTransparent = 1) then
  begin
    idx0cnt := 0;
    for y := 0 to bh - 1 do
      for x := 0 to bw - 1 do
        if buf[pages[pg].pos + (y0 + y) * pages[pg].w + x0 + x] = 0 then Inc(idx0cnt);
    trans := idx0cnt * 10 >= bw * bh;   {>= 10% of the pixels use index 0}
  end;

  {trim edge rows/columns that are entirely index 0 (keeps the crop if everything is index 0)}
  if isSub and (B3DTrim = 1) then
  begin
    tx0 := 0; tx1 := bw - 1; ty0 := 0; ty1 := bh - 1;
    while (ty0 <= ty1) and RowEmpty(ty0, tx0, tx1) do Inc(ty0);
    if ty0 <= ty1 then
    begin
      while RowEmpty(ty1, tx0, tx1) do Dec(ty1);
      while ColEmpty(tx0, ty0, ty1) do Inc(tx0);
      while ColEmpty(tx1, ty0, ty1) do Dec(tx1);
      x0 := x0 + tx0;
      y0 := y0 + ty0;
      bw := tx1 - tx0 + 1;
      bh := ty1 - ty0 + 1;
    end;
  end;
  bmp := TBitmap.Create;
  try
    tw := NextPow2(bw);
    th := NextPow2(bh);
    if use16 then
    begin
      {RGB of the cropped area, then bilinear resize to tw x th, stored as RGB565}
      SetLength(rgbBuf, bw * bh * 3);
      SetLength(alphaBuf, bw * bh);
      for y := 0 to bh - 1 do
        for x := 0 to bw - 1 do
        begin
          k := buf[pages[pg].pos + (y0 + y) * pages[pg].w + x0 + x];
          alphaBuf[y * bw + x] := k;
          rgbBuf[(y * bw + x) * 3]     := pal[k].r;
          rgbBuf[(y * bw + x) * 3 + 1] := pal[k].g;
          rgbBuf[(y * bw + x) * 3 + 2] := pal[k].b;
        end;
      if trans then bmp.PixelFormat := pf15bit else bmp.PixelFormat := pf16bit;
      bmp.HandleType := bmDIB;
      bmp.SetSize(tw, th);
      for y := 0 to th - 1 do
      begin
        row16 := bmp.ScanLine[y];
        fy := (y + 0.5) * bh / th - 0.5;
        if fy < 0 then fy := 0;
        iy := Trunc(fy);
        iy1 := Min(iy + 1, bh - 1);
        wy := fy - iy;
        for x := 0 to tw - 1 do
        begin
          fx := (x + 0.5) * bw / tw - 0.5;
          if fx < 0 then fx := 0;
          ix := Trunc(fx);
          ix1 := Min(ix + 1, bw - 1);
          wx := fx - ix;
          if not trans then
          begin
            for c := 0 to 2 do
              v[c] := (rgbBuf[(iy * bw + ix) * 3 + c] * (1 - wx) + rgbBuf[(iy * bw + ix1) * 3 + c] * wx) * (1 - wy) +
                      (rgbBuf[(iy1 * bw + ix) * 3 + c] * (1 - wx) + rgbBuf[(iy1 * bw + ix1) * 3 + c] * wx) * wy;
            r5 := (Round(v[0]) * 31 + 127) div 255;
            g6 := (Round(v[1]) * 63 + 127) div 255;
            b5 := (Round(v[2]) * 31 + 127) div 255;
            row16^[x] := Word((r5 shl 11) or (g6 shl 5) or b5);
          end
          else
          begin
            {ARGB1555: index 0 pixels are transparent; colour is averaged from the opaque neighbours only}
            k0 := (iy * bw + ix);  k1 := (iy * bw + ix1);
            k2 := (iy1 * bw + ix); k3 := (iy1 * bw + ix1);
            a0 := (1 - wx) * (1 - wy) * Ord(alphaBuf[k0] <> 0);
            a1 := wx * (1 - wy) * Ord(alphaBuf[k1] <> 0);
            a2 := (1 - wx) * wy * Ord(alphaBuf[k2] <> 0);
            a3 := wx * wy * Ord(alphaBuf[k3] <> 0);
            wsum := a0 + a1 + a2 + a3;
            cov := wsum;   {weights add up to 1, so this is the opaque coverage}
            if cov < 0.5 then
              row16^[x] := 0
            else
            begin
              for c := 0 to 2 do
                v[c] := (rgbBuf[k0 * 3 + c] * a0 + rgbBuf[k1 * 3 + c] * a1 +
                         rgbBuf[k2 * 3 + c] * a2 + rgbBuf[k3 * 3 + c] * a3) / wsum;
              r5 := (Round(v[0]) * 31 + 127) div 255;
              g6 := (Round(v[1]) * 31 + 127) div 255;
              b5 := (Round(v[2]) * 31 + 127) div 255;
              row16^[x] := Word($8000 or (r5 shl 10) or (g6 shl 5) or b5);
              if row16^[x] = 0 then row16^[x] := 1;
            end;
          end;
        end;
      end;
    end
    else
    begin
      bmp.PixelFormat := pf8bit;
      bmp.HandleType := bmDIB;
      bmp.SetSize(tw, th);
      {palette first: setting it after the pixels are written remaps (scrambles) the indices}
      Mat.ApplyPalette(bmp, pal);

      {Mat16 needs power of 2 sizes: fill the extra area by tiling the texture (they wrap in the level)}
      for y := 0 to th - 1 do
      begin
        dst := PByte(bmp.ScanLine[y]);
        src := @buf[pages[pg].pos + (y0 + (y mod bh)) * pages[pg].w + x0];
        Move(src^, dst^, bw);
        for x := bw to tw - 1 do
          PByteArray(dst)^[x] := PByteArray(src)^[x mod bw];
      end;
    end;

    Result := TBMPARRAY.Create;
    try
      Result.AddCellFromBMP(bmp);
      Result.SetCMP := pal;
      Result.isTransparent := False;
      Result.transparentColorValue := 0;
      if isSub then
        Result.name := AnsiString(ChangeFileExt(ExtractFileName(b3dname), '') + '_tex' + Format('%.3d', [pageIndex - 1000]) + '.mat')
      else
        Result.name := AnsiString(ChangeFileExt(ExtractFileName(b3dname), '') + '_page' + Format('%.2d', [pageIndex]) + '.mat');
      if use16 then
      begin
        if trans then Result.fmt := '16-bit ARGB1555' else Result.fmt := '16-bit RGB565';
      end
      else
        Result.fmt := '8-bit INDEXED';
      if trans then
      begin
        Result.isTransparent := True;
        Result.transparentColorValue := 0;
      end;
    except
      FreeAndNil(Result);
      raise;
    end;
  finally
    bmp.Free;
  end;
  if use16 then
  begin
    if trans then Mat.matFormat := TFormat.ARGB1555 else Mat.matFormat := TFormat.RGB565;
    imageformat := Mat.matFormat;
  end
  else
  begin
    if trans then Mat.matFormat := TFormat.INDEXT else Mat.matFormat := TFormat.INDEX;
    imageformat := Mat.matFormat;
  end;
end;

(* ---- Shadows of the Empire (July 1997 demo): textures stored in the DATAxx.DLL data sections ----
   Tables of entries (dims = w or h shl 16, pointer); the tiles of one image are stored consecutively,
   and the table is closed by an entry (0, full width or full height shl 16).  CI4/CI8/RGBA5551 pixels,
   palette (RGBA5551) directly in front of the first tile, odd rows have 4-byte words swapped. *)
type
  TSoteTile = record w, h, p: Integer; end;
  TSoteTileArr = array of TSoteTile;
  TSoteTable = record
    tiles: TSoteTileArr;
    bpp2: Integer;      {1 = 4 bit, 2 = 8 bit, 4 = 16 bit (bytes per pixel * 2)}
    fw, fh: Integer;    {full (stitched) size}
  end;
  TSoteTables = array of TSoteTable;

var
  SoteCacheName: string = '';
  SoteCacheAge: Integer = -1;
  SoteImg: TBytes;
  SoteBase: Cardinal = $10000000;
  SoteTabs: TSoteTables;

function SoteU32(const b: TBytes; o: Integer): Cardinal;
begin
  Result := PCardinal(@b[o])^;
end;

procedure SoteMapPE(const fname: string; var img: TBytes; var base: Cardinal);
var
  fb: TBytes;
  lf, nsec, optsz, opt, sizeImg, i, sec, va, vs, rawsz, rawp: Integer;
begin
  fb := TFile.ReadAllBytes(fname);
  if (Length(fb) < 512) or (fb[0] <> Ord('M')) or (fb[1] <> Ord('Z')) then
    raise Exception.Create('not a PE file');
  lf := SoteU32(fb, $3C);
  if (lf + 24 > Length(fb)) or (SoteU32(fb, lf) <> $00004550) then
    raise Exception.Create('not a PE file');
  nsec := PWord(@fb[lf + 6])^;
  optsz := PWord(@fb[lf + 20])^;
  opt := lf + 24;
  base := SoteU32(fb, opt + 28);
  sizeImg := SoteU32(fb, opt + 56);
  if (sizeImg <= 0) or (sizeImg > 256 * 1024 * 1024) then raise Exception.Create('bad PE image size');
  SetLength(img, sizeImg);
  FillChar(img[0], sizeImg, 0);
  for sec := 0 to nsec - 1 do
  begin
    i := opt + optsz + sec * 40;
    vs := SoteU32(fb, i + 8);
    va := SoteU32(fb, i + 12);
    rawsz := SoteU32(fb, i + 16);
    rawp := SoteU32(fb, i + 20);
    if rawsz > vs then rawsz := vs;
    if (rawp >= 0) and (rawp + rawsz <= Length(fb)) and (va + rawsz <= sizeImg) and (rawsz > 0) then
      Move(fb[rawp], img[va], rawsz);
  end;
end;

procedure SoteLoad(const fname: string);
var
  fb: TBytes;
  lf, nsec, optsz, opt, sizeImg, i, sec, va, vs, rawsz, rawp, n: Integer;
  nv, i0, j, k, w, h, cand, dw, dh: Integer;
  d, pt, d2, p2: Cardinal;
  ents: TSoteTileArr;
  ok: Boolean;
  tb: TSoteTable;
begin
  if (SoteCacheName = fname) and (SoteCacheAge = FileAge(fname)) and (Length(SoteImg) > 0) then Exit;
  SoteCacheName := '';
  SetLength(SoteImg, 0);
  SetLength(SoteTabs, 0);
  SoteMapPE(fname, SoteImg, SoteBase);
  sizeImg := Length(SoteImg);
  n := sizeImg;
  nv := n div 4;
  i0 := 0;
  while i0 < nv - 3 do
  begin
    d := SoteU32(SoteImg, i0 * 4);
    pt := SoteU32(SoteImg, i0 * 4 + 4);
    w := d and $FFFF;
    h := d shr 16;
    if (w >= 1) and (w <= 256) and (h >= 1) and (h <= 256) and (pt >= SoteBase) and (pt < SoteBase + Cardinal(n)) then
    begin
      SetLength(ents, 0);
      j := i0;
      while j < nv - 1 do
      begin
        d := SoteU32(SoteImg, j * 4);
        pt := SoteU32(SoteImg, j * 4 + 4);
        w := d and $FFFF;
        h := d shr 16;
        if (w >= 1) and (w <= 256) and (h >= 1) and (h <= 256) and (pt >= SoteBase) and (pt < SoteBase + Cardinal(n)) then
        begin
          SetLength(ents, Length(ents) + 1);
          ents[High(ents)].w := w;
          ents[High(ents)].h := h;
          ents[High(ents)].p := Integer(pt - SoteBase);
          Inc(j, 2);
        end
        else Break;
      end;
      tb.bpp2 := 0;
      if Length(ents) >= 2 then
        for cand := 0 to 2 do
        begin
          ok := True;
          for k := 0 to Length(ents) - 2 do
            if ents[k + 1].p - ents[k].p <> (ents[k].w * ents[k].h * (1 shl cand)) div 2 then
            begin
              ok := False;
              Break;
            end;
          if ok then
          begin
            tb.bpp2 := 1 shl cand;
            Break;
          end;
        end;
      if tb.bpp2 > 0 then
      begin
        {closing entry: 0, full size; tiles must fill complete rows of that width}
        tb.fw := 0; tb.fh := 0;
        if j < nv - 1 then
        begin
          d2 := SoteU32(SoteImg, j * 4);
          p2 := SoteU32(SoteImg, j * 4 + 4);
          if d2 = 0 then
          begin
            tb.fw := p2 and $FFFF;
            tb.fh := p2 shr 16;
          end;
        end;
        ok := (tb.fw > 0) and (tb.fh > 0);
        if ok then
        begin
          {check the layout: rows of tiles of equal height whose widths add up to fw, heights add up to fh}
          k := 0; dw := 0; dh := 0;
          i := 0;
          while ok and (i < Length(ents)) do
          begin
            w := 0;
            h := ents[i].h;
            while (i < Length(ents)) and (w < tb.fw) do
            begin
              if ents[i].h <> h then ok := False;
              Inc(w, ents[i].w);
              Inc(i);
            end;
            if w <> tb.fw then ok := False;
            Inc(dh, h);
          end;
          if dh <> tb.fh then ok := False;
        end;
        if ok then
        begin
          tb.tiles := Copy(ents, 0, Length(ents));
          SetLength(SoteTabs, Length(SoteTabs) + 1);
          SoteTabs[High(SoteTabs)] := tb;
        end;
        i0 := j;
        Continue;
      end;
    end;
    Inc(i0);
  end;
  SoteCacheName := fname;
  SoteCacheAge := FileAge(fname);
end;

function soteFilesToArray(const dllname: string):TFileOffsets;
var
  i: Integer;
begin
  SetLength(Result, 0);
  if not SysUtils.FileExists(dllname) then
  begin
    ShowMessage('container file not found');
    Exit;
  end;
  try
    SoteLoad(dllname);
  except
    on E: Exception do
    begin
      ShowMessage('Cannot read ' + ExtractFileName(dllname) + ': ' + E.Message);
      Exit;
    end;
  end;
  SetLength(Result, Length(SoteTabs));
  for i := 0 to High(SoteTabs) do
  begin
    Result[i].container := dllname;
    Result[i].filename := ChangeFileExt(ExtractFileName(dllname), '') + '_img' + Format('%.2d', [i]) +
      '_' + IntToStr(SoteTabs[i].fw) + 'x' + IntToStr(SoteTabs[i].fh) + '.mat';
    Result[i].offset := i;
  end;
  if Length(Result) = 0 then
    ShowMessage('No Shadows of the Empire (demo) textures found in ' + ExtractFileName(dllname));
end;

function SoteMakeArray(const nm: string; const px: array of Word; fw, fh: Integer; hasAlpha: Boolean; Mat: TMAT):TBMPArray;
var
  tw, th, x, y, c, r5, g5: Integer;
  v: Word;
  bmp: TBitmap;
  row16: PWordArray;
  cmp: TCMPPal;
begin
  tw := 1; while tw < fw do tw := tw shl 1;
  th := 1; while th < fh do th := th shl 1;
  bmp := TBitmap.Create;
  try
    if hasAlpha then bmp.PixelFormat := pf15bit else bmp.PixelFormat := pf16bit;
    bmp.HandleType := bmDIB;
    bmp.SetSize(tw, th);
    for y := 0 to th - 1 do
    begin
      row16 := bmp.ScanLine[y];
      for x := 0 to tw - 1 do
      begin
        if (x >= fw) or (y >= fh) then
        begin
          row16^[x] := 0;   {padding: black / transparent}
          Continue;
        end;
        v := px[y * fw + x];
        r5 := (v shr 11) and 31;
        g5 := (v shr 6) and 31;
        c := (v shr 1) and 31;
        if hasAlpha then
        begin
          if (v and 1) = 0 then row16^[x] := 0
          else
          begin
            row16^[x] := Word($8000 or (r5 shl 10) or (g5 shl 5) or c);
            if row16^[x] = 0 then row16^[x] := 1;
          end;
        end
        else
          row16^[x] := Word((r5 shl 11) or (((g5 shl 1) or (g5 shr 4)) shl 5) or c);
      end;
    end;
    for c := 0 to 255 do
    begin
      cmp[c].r := c; cmp[c].g := c; cmp[c].b := c;
    end;
    Result := TBMPARRAY.Create;
    try
      Result.AddCellFromBMP(bmp);
      Result.SetCMP := cmp;
      Result.isTransparent := hasAlpha;
      Result.transparentColorValue := 0;
      Result.name := AnsiString(nm);
      if hasAlpha then Result.fmt := '16-bit ARGB1555' else Result.fmt := '16-bit RGB565';
    except
      FreeAndNil(Result);
      raise;
    end;
  finally
    bmp.Free;
  end;
  if hasAlpha then Mat.matFormat := TFormat.ARGB1555 else Mat.matFormat := TFormat.RGB565;
  imageformat := Mat.matFormat;
end;

function SoteToArray(const dllname: string; idx: Integer; Mat: TMAT):TBMPArray;
var
  tb: TSoteTable;
  px: array of Word;     {ARGB1555 of the stitched image}
  pal: array[0..255] of Word;
  hasAlpha: Boolean;
  i, x, y, w, h, tx, ty, o, bi, p0, c, pn: Integer;
  b: Byte;
  v: Word;
begin
  SoteLoad(dllname);
  if (idx < 0) or (idx > High(SoteTabs)) then raise Exception.Create('texture index out of range');
  tb := SoteTabs[idx];
  p0 := tb.tiles[0].p;
  FillChar(pal, SizeOf(pal), 0);
  if tb.bpp2 = 1 then
  begin
    pn := 16;
    if p0 - 32 < 0 then raise Exception.Create('palette out of range');
    for c := 0 to 15 do pal[c] := PWord(@SoteImg[p0 - 32 + c * 2])^;
  end
  else if tb.bpp2 = 2 then
  begin
    pn := 256;
    if p0 - 512 < 0 then raise Exception.Create('palette out of range');
    for c := 0 to 255 do pal[c] := PWord(@SoteImg[p0 - 512 + c * 2])^;
  end
  else pn := 0;

  SetLength(px, tb.fw * tb.fh);
  hasAlpha := False;
  tx := 0; ty := 0;
  i := 0;
  while i < Length(tb.tiles) do
  begin
    h := tb.tiles[i].h;
    tx := 0;
    while (i < Length(tb.tiles)) and (tx < tb.fw) do
    begin
      w := tb.tiles[i].w;
      o := tb.tiles[i].p;
      for y := 0 to h - 1 do
        for x := 0 to w - 1 do
        begin
          if tb.bpp2 = 1 then
          begin
            bi := y * (w div 2) + x div 2;
            if (y and 1) <> 0 then bi := bi xor 4;
            b := SoteImg[o + bi];
            if (x and 1) = 0 then v := pal[b shr 4] else v := pal[b and 15];
          end
          else if tb.bpp2 = 2 then
          begin
            bi := y * w + x;
            if (y and 1) <> 0 then bi := bi xor 4;
            v := pal[SoteImg[o + bi]];
          end
          else
          begin
            bi := (y * w + x) * 2;
            if (y and 1) <> 0 then bi := bi xor 4;
            v := PWord(@SoteImg[o + bi])^;
          end;
          if (v and 1) = 0 then hasAlpha := True;
          px[(ty + y) * tb.fw + tx + x] := v;
        end;
      Inc(tx, w);
      Inc(i);
    end;
    Inc(ty, h);
  end;

  Result := SoteMakeArray(ChangeFileExt(ExtractFileName(dllname), '') + '_img' + Format('%.2d', [idx]) + '_' +
    IntToStr(tb.fw) + 'x' + IntToStr(tb.fh) + '.mat', px, tb.fw, tb.fh, hasAlpha, Mat);
end;

{ ---- Shadows of the Empire demo, shadows.exe: level texture pool ----
  Table at VA $4C1040 indexed by texture id -> descriptor ($12 marker); +$20 = $10, +$28 format,
  +$2C width, +$30 height, +$34 pixel pointer, +$38 palette pointer (or 0).
  Formats: 0 = I4, 2 = CI4 (16 colour palette), 4 = CI8, 5 = RGBA5551, 6 = RGBA8888. }
type
  TSoteExeTex = record id, fmt, w, h, p1, p2: Integer; end;

const
  SOTE_EXE_TABLE = $4C1040;        {demo}
  SOTE_RETAIL_TABLE = $4CCC38;     {retail Shadows.exe}
  SOTE_EXE_IDS = 1257;

var
  SoteExeName: string = '';
  SoteExeAge: Integer = -1;
  SoteExeImg: TBytes;
  SoteExeBase: Cardinal = $400000;
  SoteExeList: array of TSoteExeTex;

procedure SoteExeLoad(const fname: string);
var
  id, o, fmt, w, h, p1, p2, need: Integer;
  pt: Cardinal;
  ok: Boolean;
  tx: TSoteExeTex;
begin
  if (SoteExeName = fname) and (SoteExeAge = FileAge(fname)) and (Length(SoteExeImg) > 0) then Exit;
  SoteExeName := '';
  SetLength(SoteExeList, 0);
  SoteMapPE(fname, SoteExeImg, SoteExeBase);
  if SoteExeBase <> $400000 then raise Exception.Create('not the Shadows of the Empire executable');
  for id := 0 to SOTE_EXE_IDS - 1 do
  begin
    if SOTE_EXE_TABLE - Integer(SoteExeBase) + id * 4 + 4 > Length(SoteExeImg) then Break;
    pt := SoteU32(SoteExeImg, SOTE_EXE_TABLE - Integer(SoteExeBase) + id * 4);
    if (pt < SoteExeBase) or (pt + $40 >= SoteExeBase + Cardinal(Length(SoteExeImg))) then Continue;
    o := Integer(pt - SoteExeBase);
    if (SoteU32(SoteExeImg, o) <> $12) or (SoteU32(SoteExeImg, o + $20) <> $10) then Continue;
    fmt := SoteU32(SoteExeImg, o + $28);
    w := SoteU32(SoteExeImg, o + $2C);
    h := SoteU32(SoteExeImg, o + $30);
    p1 := SoteU32(SoteExeImg, o + $34);
    p2 := SoteU32(SoteExeImg, o + $38);
    if (w < 1) or (w > 256) or (h < 1) or (h > 256) then Continue;
    case fmt of
      0: need := (w * h) div 2;
      2: need := (w * h) div 2;
      4: need := w * h;
      5: need := w * h * 2;
      6: need := w * h * 4;
    else
      Continue;
    end;
    ok := (p1 >= Integer(SoteExeBase)) and (p1 - Integer(SoteExeBase) + need <= Length(SoteExeImg));
    if ok and (fmt = 2) then ok := (p2 >= Integer(SoteExeBase)) and (p2 - Integer(SoteExeBase) + 32 <= Length(SoteExeImg));
    if ok and (fmt = 4) then ok := (p2 >= Integer(SoteExeBase)) and (p2 - Integer(SoteExeBase) + 512 <= Length(SoteExeImg));
    if not ok then Continue;
    tx.id := id; tx.fmt := fmt; tx.w := w; tx.h := h;
    tx.p1 := p1 - Integer(SoteExeBase);
    if p2 <> 0 then tx.p2 := p2 - Integer(SoteExeBase) else tx.p2 := 0;
    SetLength(SoteExeList, Length(SoteExeList) + 1);
    SoteExeList[High(SoteExeList)] := tx;
  end;
  {retail build: table at $4CCC38, descriptor marker $10 at +$14, dims (w shl 16 or h) at +$1C,
   pixel pointer +$20, palette pointer +$24 (0 = none).  Format follows from the data sizes.}
  if Length(SoteExeList) = 0 then
    for id := 0 to SOTE_EXE_IDS - 1 do
    begin
      if SOTE_RETAIL_TABLE - Integer(SoteExeBase) + id * 4 + 4 > Length(SoteExeImg) then Break;
      pt := SoteU32(SoteExeImg, SOTE_RETAIL_TABLE - Integer(SoteExeBase) + id * 4);
      if (pt < SoteExeBase) or (pt + $40 >= SoteExeBase + Cardinal(Length(SoteExeImg))) then Continue;
      o := Integer(pt - SoteExeBase);
      if (SoteU32(SoteExeImg, o) <> $12) or (SoteU32(SoteExeImg, o + $14) <> $10) then Continue;
      {retail packing: width in the high word, height in the low word (verified against the demo)}
      h := SoteU32(SoteExeImg, o + $1C) and $FFFF;
      w := SoteU32(SoteExeImg, o + $1C) shr 16;
      p1 := SoteU32(SoteExeImg, o + $20);
      p2 := SoteU32(SoteExeImg, o + $24);
      if (w < 1) or (w > 256) or (h < 1) or (h > 256) then Continue;
      if p1 < Integer(SoteExeBase) then Continue;
      if p2 <> 0 then need := p2 - p1 else need := Integer(pt) - p1;
      fmt := -1;
      if p2 <> 0 then
      begin
        if need = (w * h) div 2 then fmt := 2 else if need = w * h then fmt := 4;
      end
      else
      begin
        if need = (w * h) div 2 then fmt := 0
        else if need = w * h * 2 then fmt := 5
        else if need = w * h * 4 then fmt := 6;
      end;
      if fmt < 0 then Continue;
      if p1 - Integer(SoteExeBase) + need > Length(SoteExeImg) then Continue;
      if (p2 <> 0) and (p2 - Integer(SoteExeBase) + (32 + 480 * (fmt - 2) div 2) > Length(SoteExeImg)) then Continue;
      tx.id := id; tx.fmt := fmt; tx.w := w; tx.h := h;
      tx.p1 := p1 - Integer(SoteExeBase);
      if p2 <> 0 then tx.p2 := p2 - Integer(SoteExeBase) else tx.p2 := 0;
      SetLength(SoteExeList, Length(SoteExeList) + 1);
      SoteExeList[High(SoteExeList)] := tx;
    end;
  SoteExeName := fname;
  SoteExeAge := FileAge(fname);
end;

function SoteExeFmtName(fmt: Integer): string;
begin
  case fmt of
    0: Result := 'I4';
    2: Result := 'CI4';
    4: Result := 'CI8';
    5: Result := 'RGBA5551';
    6: Result := 'RGBA8888';
  else Result := 'fmt' + IntToStr(fmt);
  end;
end;

function SoteExeTexName(const t: TSoteExeTex): string;
begin
  Result := 'sote_tex' + Format('%.4d', [t.id]) + '_' + IntToStr(t.w) + 'x' + IntToStr(t.h) + '_' + SoteExeFmtName(t.fmt) + '.mat';
end;

function soteExeFilesToArray(const exename: string):TFileOffsets;
var
  i: Integer;
begin
  SetLength(Result, 0);
  if not SysUtils.FileExists(exename) then
  begin
    ShowMessage('container file not found');
    Exit;
  end;
  try
    SoteExeLoad(exename);
  except
    on E: Exception do
    begin
      ShowMessage('Cannot read ' + ExtractFileName(exename) + ': ' + E.Message);
      Exit;
    end;
  end;
  SetLength(Result, Length(SoteExeList));
  for i := 0 to High(SoteExeList) do
  begin
    Result[i].container := exename;
    Result[i].filename := SoteExeTexName(SoteExeList[i]);
    Result[i].offset := i;
  end;
  if Length(Result) = 0 then
    ShowMessage('No Shadows of the Empire (demo) level textures found in ' + ExtractFileName(exename));
end;

function SoteExeToArray(const exename: string; idx: Integer; Mat: TMAT):TBMPArray;
var
  t: TSoteExeTex;
  px: array of Word;
  pal: array[0..255] of Word;
  x, y, c, r, g, b, a, n: Integer;
  v: Word;
  hasAlpha: Boolean;
begin
  SoteExeLoad(exename);
  if (idx < 0) or (idx > High(SoteExeList)) then raise Exception.Create('texture index out of range');
  t := SoteExeList[idx];
  SetLength(px, t.w * t.h);
  hasAlpha := False;
  if t.fmt = 2 then for c := 0 to 15 do pal[c] := PWord(@SoteExeImg[t.p2 + c * 2])^;
  if t.fmt = 4 then for c := 0 to 255 do pal[c] := PWord(@SoteExeImg[t.p2 + c * 2])^;
  for y := 0 to t.h - 1 do
    for x := 0 to t.w - 1 do
    begin
      case t.fmt of
        0:
          begin
            n := SoteExeImg[t.p1 + (y * t.w + x) div 2];
            if (x and 1) = 0 then n := n shr 4 else n := n and 15;
            c := (n shl 1) or (n shr 3);     {0..15 -> 0..31}
            v := Word((c shl 11) or (c shl 6) or (c shl 1) or 1);
          end;
        2:
          begin
            n := SoteExeImg[t.p1 + (y * t.w + x) div 2];
            if (x and 1) = 0 then n := n shr 4 else n := n and 15;
            v := pal[n];
          end;
        4: v := pal[SoteExeImg[t.p1 + y * t.w + x]];
        5: v := PWord(@SoteExeImg[t.p1 + (y * t.w + x) * 2])^;
      else
        begin
          {RGBA8888}
          r := SoteExeImg[t.p1 + (y * t.w + x) * 4];
          g := SoteExeImg[t.p1 + (y * t.w + x) * 4 + 1];
          b := SoteExeImg[t.p1 + (y * t.w + x) * 4 + 2];
          a := SoteExeImg[t.p1 + (y * t.w + x) * 4 + 3];
          v := Word(((r shr 3) shl 11) or ((g shr 3) shl 6) or ((b shr 3) shl 1));
          if a >= 128 then v := v or 1;
        end;
      end;
      if (v and 1) = 0 then hasAlpha := True;
      px[(t.h - 1 - y) * t.w + x] := v;   {stored bottom-up: flip vertically}
    end;
  Result := SoteMakeArray(SoteExeTexName(t), px, t.w, t.h, hasAlpha, Mat);
end;

{ ---- Dark Forces GOB (magic 'GOB' + LF): index at the offset stored in the header ---- }
type
  TDFEntry = record
    pos, len: Integer;
    name: string;
  end;
  TDFEntries = array of TDFEntry;

var
  DFPalGob: string = '';
  DFPalCache: TCMPPal;

function DFReadIndex(const gobname: string): TDFEntries;
var
  fs: TFileStream;
  hdr: array[0..7] of Byte;
  idx, cnt, i, j: Integer;
  e: array[0..20] of Byte;
  nm: AnsiString;
begin
  SetLength(Result, 0);
  fs := TFileStream.Create(gobname, fmOpenRead or fmShareDenyNone);
  try
    if fs.Size < 12 then Exit;
    fs.ReadBuffer(hdr, 8);
    if (hdr[0] <> Ord('G')) or (hdr[1] <> Ord('O')) or (hdr[2] <> Ord('B')) or (hdr[3] <> 10) then Exit;
    idx := PInteger(@hdr[4])^;
    if (idx < 8) or (idx + 4 > fs.Size) then Exit;
    fs.Position := idx;
    fs.ReadBuffer(cnt, 4);
    if (cnt < 0) or (cnt > 200000) or (idx + 4 + Int64(cnt) * 21 > fs.Size) then Exit;
    SetLength(Result, cnt);
    for i := 0 to cnt - 1 do
    begin
      fs.ReadBuffer(e, 21);
      Result[i].pos := PInteger(@e[0])^;
      Result[i].len := PInteger(@e[4])^;
      SetLength(nm, 0);
      for j := 8 to 20 do
      begin
        if e[j] = 0 then Break;
        nm := nm + AnsiChar(e[j]);
      end;
      Result[i].name := string(nm);
    end;
  finally
    fs.Free;
  end;
end;

function IsDFGob(const fname: string): Boolean;
var
  fs: TFileStream;
  m: array[0..3] of Byte;
begin
  Result := False;
  if not SameText(ExtractFileExt(fname), '.GOB') then Exit;
  if not SysUtils.FileExists(fname) then Exit;
  try
    fs := TFileStream.Create(fname, fmOpenRead or fmShareDenyNone);
    try
      if fs.Size < 12 then Exit;
      fs.ReadBuffer(m, 4);
      Result := (m[0] = Ord('G')) and (m[1] = Ord('O')) and (m[2] = Ord('B')) and (m[3] = 10);
    finally
      fs.Free;
    end;
  except
    Result := False;
  end;
end;

function DFReadBytes(const gobname: string; pos, len: Integer): TBytes;
var
  fs: TFileStream;
begin
  SetLength(Result, 0);
  fs := TFileStream.Create(gobname, fmOpenRead or fmShareDenyNone);
  try
    if (pos < 0) or (len < 0) or (Int64(pos) + len > fs.Size) then Exit;
    SetLength(Result, len);
    if len > 0 then
    begin
      fs.Position := pos;
      fs.ReadBuffer(Result[0], len);
    end;
  finally
    fs.Free;
  end;
end;

{VGA palette (768 bytes, 6-bit values) from a .PAL file: SECBASE.PAL in this GOB, else in DARK.GOB next to it,
 else the first .PAL found, else a grey ramp}
function DFFindPal(const gobname: string; var raw: TBytes): Boolean;
var
  ents: TDFEntries;
  i, k: Integer;
  dark: string;
begin
  Result := False;
  for k := 0 to 1 do
  begin
    if k = 0 then dark := gobname else dark := ExtractFilePath(gobname) + 'DARK.GOB';
    if (k = 1) and ((SameText(dark, gobname)) or (not SysUtils.FileExists(dark))) then Continue;
    ents := DFReadIndex(dark);
    for i := 0 to High(ents) do
      if SameText(ents[i].name, 'SECBASE.PAL') and (ents[i].len >= 768) then
      begin
        raw := DFReadBytes(dark, ents[i].pos, 768);
        Result := Length(raw) = 768;
        if Result then Exit;
      end;
    for i := 0 to High(ents) do
      if SameText(ExtractFileExt(ents[i].name), '.PAL') and (ents[i].len >= 768) then
      begin
        raw := DFReadBytes(dark, ents[i].pos, 768);
        Result := Length(raw) = 768;
        if Result then Exit;
      end;
  end;
end;

procedure DFGetPalette(const gobname: string; var pal: TCMPPal);
var
  raw: TBytes;
  k: Integer;
begin
  if SameText(DFPalGob, gobname) then
  begin
    pal := DFPalCache;
    Exit;
  end;
  if DFFindPal(gobname, raw) then
    for k := 0 to 255 do
    begin
      pal[k].r := (raw[k * 3] shl 2) or (raw[k * 3] shr 4);
      pal[k].g := (raw[k * 3 + 1] shl 2) or (raw[k * 3 + 1] shr 4);
      pal[k].b := (raw[k * 3 + 2] shl 2) or (raw[k * 3 + 2] shr 4);
    end
  else
    for k := 0 to 255 do
    begin
      pal[k].r := k; pal[k].g := k; pal[k].b := k;
    end;
  DFPalCache := pal;
  DFPalGob := gobname;
end;

{BM header (32 bytes): 'BM ' $1E, SizeX, SizeY (words), idemX, idemY, flags (bit 3 = transparent),
 log2 SizeY, compressed (0 none, 1 RLE, 2 RLE0), data size.  Multi-frame BMs (SizeX = 1) are skipped.}
function DFBMHeader(const b: TBytes; var w, h, comp, flags: Integer): Boolean;
begin
  Result := False;
  if Length(b) < 32 then Exit;
  if (b[0] <> Ord('B')) or (b[1] <> Ord('M')) then Exit;
  w := PWord(@b[4])^;
  h := PWord(@b[6])^;
  flags := b[12];
  comp := PWord(@b[14])^;
  if (w < 1) or (h < 1) or (w > 1024) or (h > 1024) then Exit;
  if (w = 1) and (h > 1) then Exit;     {animated multi-BM}
  Result := True;
end;

function dfFilesToArray(const gobname: string):TFileOffsets;
var
  ents: TDFEntries;
  i, n, w, h, comp, fl: Integer;
  hd: TBytes;
begin
  SetLength(Result, 0);
  if not SysUtils.FileExists(gobname) then
  begin
    ShowMessage('container file not found');
    Exit;
  end;
  ents := DFReadIndex(gobname);
  n := 0;
  SetLength(Result, Length(ents));
  for i := 0 to High(ents) do
  begin
    if not SameText(ExtractFileExt(ents[i].name), '.BM') then Continue;
    hd := DFReadBytes(gobname, ents[i].pos, Min(32, ents[i].len));
    if not DFBMHeader(hd, w, h, comp, fl) then Continue;
    Result[n].container := gobname;
    Result[n].filename := ents[i].name;
    Result[n].offset := ents[i].pos;
    Inc(n);
  end;
  SetLength(Result, n);
  if n = 0 then ShowMessage('No Dark Forces BM textures found in ' + ExtractFileName(gobname));
end;

function DFBMToArray(const gobname: string; pos: Integer; Mat: TMAT):TBMPArray;
var
  ents: TDFEntries;
  i, len, w, h, comp, fl, x, y, k, p, c, n, tw, th: Integer;
  b: TBytes;
  pix: array of Byte;     {row major, top row first}
  col: array of Byte;
  start: Cardinal;
  v: Byte;
  pal: TCMPPal;
  bmp: TBitmap;
  trans: Boolean;
  dst: PByte;
  nm: string;
begin
  ents := DFReadIndex(gobname);
  len := -1;
  for i := 0 to High(ents) do
    if ents[i].pos = pos then
    begin
      len := ents[i].len;
      nm := ents[i].name;
      Break;
    end;
  if len < 32 then raise Exception.Create('texture not found in container');
  b := DFReadBytes(gobname, pos, len);
  if not DFBMHeader(b, w, h, comp, fl) then raise Exception.Create('unsupported BM (animated or invalid)');
  trans := (fl and 8) <> 0;
  SetLength(pix, w * h);
  FillChar(pix[0], w * h, 0);
  SetLength(col, h);
  for x := 0 to w - 1 do
  begin
    FillChar(col[0], h, 0);
    if comp = 0 then
    begin
      p := 32 + x * h;
      for y := 0 to h - 1 do
        if p + y < Length(b) then col[y] := b[p + y];
    end
    else
    begin
      if 32 + (x + 1) * 4 > Length(b) then Break;
      start := PCardinal(@b[32 + x * 4])^;
      p := 32 + Integer(start);
      k := 0;
      while (k < h) and (p >= 32) and (p < Length(b)) do
      begin
        c := b[p];
        Inc(p);
        if c <= 128 then
        begin
          for n := 1 to c do
          begin
            if (k < h) and (p < Length(b)) then col[k] := b[p];
            Inc(k);
            Inc(p);
          end;
        end
        else
        begin
          n := c - 128;
          if comp = 1 then
          begin
            if p < Length(b) then v := b[p] else v := 0;
            Inc(p);
          end
          else v := 0;
          while (n > 0) and (k < h) do
          begin
            col[k] := v;
            Inc(k);
            Dec(n);
          end;
        end;
      end;
    end;
    {columns are stored bottom to top}
    for y := 0 to h - 1 do pix[(h - 1 - y) * w + x] := col[y];
  end;

  DFGetPalette(gobname, pal);
  tw := 1; while tw < w do tw := tw shl 1;
  th := 1; while th < h do th := th shl 1;
  bmp := TBitmap.Create;
  try
    bmp.PixelFormat := pf8bit;
    bmp.HandleType := bmDIB;
    bmp.SetSize(tw, th);
    Mat.ApplyPalette(bmp, pal);      {palette first, then the pixels}
    for y := 0 to th - 1 do
    begin
      dst := PByte(bmp.ScanLine[y]);
      for x := 0 to tw - 1 do
        PByteArray(dst)^[x] := pix[(y mod h) * w + (x mod w)];   {pad to a power of 2 by tiling}
    end;
    Result := TBMPARRAY.Create;
    try
      Result.AddCellFromBMP(bmp);
      Result.SetCMP := pal;
      Result.isTransparent := trans;
      Result.transparentColorValue := 0;
      Result.name := AnsiString(nm);
      Result.fmt := '8-bit INDEXED';
    except
      FreeAndNil(Result);
      raise;
    end;
  finally
    bmp.Free;
  end;
  if trans then Mat.matFormat := TFormat.INDEXT else Mat.matFormat := TFormat.INDEX;
  imageformat := Mat.matFormat;
end;

function IsEmbeddedContainer(const fname: string): Boolean;
begin
  Result := SameText(ExtractFileExt(fname), '.CND') or SameText(ExtractFileExt(fname), '.B3D') or SameText(ExtractFileExt(fname), '.DLL') or SameText(ExtractFileExt(fname), '.EXE') or IsDFGob(fname);
end;

function EmbeddedMatToArray(const fname: string; idx: Integer; Mat: TMAT):TBMPArray;
begin
  if SameText(ExtractFileExt(fname), '.B3D') then
    Result := B3DPageToArray(fname, idx, Mat)
  else if SameText(ExtractFileExt(fname), '.DLL') then
    Result := SoteToArray(fname, idx, Mat)
  else if SameText(ExtractFileExt(fname), '.EXE') then
    Result := SoteExeToArray(fname, idx, Mat)
  else if SameText(ExtractFileExt(fname), '.GOB') then
    Result := DFBMToArray(fname, idx, Mat)
  else
    Result := CNDMatToArray(fname, idx, Mat);
end;

{GOB2}
function GobMatToArray(gobfile: string; fileinGobName: string;
           FileOffsets: TFileOffsets;CMPOffsets: TFileOffsets):TBMPArray;
var
bestcmp:string;
pos: integer;
gobCMP:TCMP;
Mat: TMAT;
begin
 if IsEmbeddedContainer(gobfile) then
  begin
   Mat:=TMAT.Create(TFormat.BMP);
   try
     Result:= EmbeddedMatToArray(gobfile, GetGOBArrayOffset(FileOffsets, fileinGobName), Mat);
   finally
     Mat.Free;
   end;
   Exit;
  end;

 gobCMP:=TCMP.create;
  {load jk or mots cmp}
   if (UpperCase(ExtractFileExt(gobfile)) = '.GOB') or
     (UpperCase(ExtractFileExt(gobfile)) = '.GOO') or
     (UpperCase(ExtractFileExt(gobfile)) = '') then
     begin
     bestcmp    := GetbestCMP(fileinGobName, JKPath);
     pos:=GetGOBArrayOffset(CMPOffsets, bestcmp);
     gobCMP.LoadCMPFromFile(jkpath, pos);
     end;
    {phantom menace cmp}
   if (UpperCase(ExtractFileExt(gobfile)) = '.BAF') then
     begin
     gobCMP.LoadCMPFromBAFFile(gobfile, 336);
     end;

    Mat:=TMAT.Create(TFormat.BMP);
    Mat.SetCMP(gobCMP.GetRGB);

     pos:=GetGOBArrayOffset(FileOffsets, fileinGobName);
     Result:= Mat.LoadFromFile(gobfile, pos);

 Mat.Free;
 gobCMP.Free;
 Mat:=nil;

end;


function GobMatSavetoBMP(gobfile: string; fileinGobName: string;FileOffsets: TFileOffsets;CMPOffsets: TFileOffsets;MatInGob:boolean):String;
var
bestcmp:string;
pos: integer;
gobCMP:TCMP;
Mat: TMAT;
tempA:TBMPArray;
gpath, mpath: string;
begin
  if IsEmbeddedContainer(gobfile) then
   begin
    Mat:=TMAT.Create(TFormat.BMP);
    try
      tempA:= EmbeddedMatToArray(gobfile, GetGOBArrayOffset(FileOffsets, fileinGobName), Mat);
      try
        mpath := ExtractFilePath(gobfile) + ExtractName(fileinGobName);
        tempA.SaveMTS(mpath);
        Result:='Saved MTS and bmp(s): ' + ExtractName(fileinGobName);
      finally
        tempA.Free;
      end;
    finally
      Mat.Free;
    end;
    Exit;
   end;

  gobCMP:=TCMP.create;
  {load jk or mots cmp}
   if (UpperCase(ExtractFileExt(gobfile)) = '.GOB') or
     (UpperCase(ExtractFileExt(gobfile)) = '.GOO') or
     (UpperCase(ExtractFileExt(gobfile)) = '') then
     begin
     bestcmp    := GetbestCMP(fileinGobName, JKPath);
     pos:=GetGOBArrayOffset(CMPOffsets, bestcmp);
     gobCMP.LoadCMPFromFile(jkpath, pos);
     end;
    {phantom menace cmp}
   if (UpperCase(ExtractFileExt(gobfile)) = '.BAF') then
     begin
     gobCMP.LoadCMPFromBAFFile(gobfile, 336);
     end;

    Mat:=TMAT.Create(TFormat.BMP);
    Mat.SetCMP(gobCMP.GetRGB);

    if MatInGob then
     begin
     pos:=GetGOBArrayOffset(FileOffsets, fileinGobName);
     tempA:= Mat.LoadFromFile(gobfile, pos);
     gpath := ExtractFilePath(gobfile);
     mpath := gpath + ExtractName(fileinGobName);
     end
    else
     begin
     tempA:= Mat.LoadFromFile(fileinGobName);
     mpath := fileinGobName;
     end;

    {8.3 filename bug workaround}
    if ContainsText(mpath,'~1') then
        mpath:= StringReplace(mpath, '~1', '_1', [rfReplaceAll, rfIgnoreCase]);

    tempA.SaveMTS(mpath);

    Result:='Saved MTS and bmp(s): '
      + ExtractName(fileinGobName)
      + ' cmp: ' + bestcmp;

    Mat.Free;
    tempA.Free;
    gobCMP.Free;
    Mat:=nil;
    tempA:=nil

 end;


procedure opengob(filename: string);
var //Fi:TFInfo;
  i:   integer;
  ge:  TGob2Entry;
  //f:TFile;
  gh:  TGOB2Header;
  dir: string;
  f:   file;
  gobfiles: TStringList;
begin
  gobfiles := TStringList.Create;
  //ClearIndex;
  //f:=OpenFileRead(name,0);
  try

    AssignFile(f, filename);
    Reset(f, 1);

    BlockRead(f, gh, SizeOf(gh));


    if gh.magic <> 'GOB ' then
      raise Exception.Create(filename + ' is not a GOB 2.0 file');
    //gobview.Label3.caption:=inttostr(gh.NEntries);
    for i := 0 to gh.NEntries - 1 do
    begin
      BlockRead(f, ge, SizeOf(ge));

      Dir := ExtractFileExt(ge.Name);
      if UpperCase(ExtractFileExt(Dir)) = '.MAT' then
      begin
        gobfiles.Add(ge.Name);
        //gobview.ListBox1.Items.Append(ge.name);
        //gobview.ListBox1.OnClick;
      end;
      // F.FRead(ge,sizeof(ge));
      // fi:=TFInfo.Create;
      // fi.offs:=ge.pos;
      //  fi.size:=ge.size;
      //  Files.AddObject(ge.name,fi);
      //  Dir:=ExtractFilePath(ge.name);
      //  if dir<>'' then
      //  begin
      //   If Dir[Length(Dir)]='\' then SetLength(Dir,Length(Dir)-1);
      //   if Dirs.IndexOf(Dir)=-1 then Dirs.Add(Dir);
      //  end;
    end;
  finally
    CloseFile(f);
  end;
end;

function gobFilesToArray(gobfilename: string; filetype:string):TFileOffsets;
var
  i,filecnt:  integer;
  ge: TGob2Entry;

  gh:  TGOB2Header;
  dir: string;
   f: file;
   FileOffsets: TFileOffsets;
begin
  filecnt:=0;

  if not SysUtils.FileExists(gobfilename) then
  begin
      ShowMessage('container file not found');
     exit;
  end;

  try

    AssignFile(f, gobfilename);
    Reset(f, 1);

    BlockRead(f, gh, SizeOf(gh));
    SetLength(Result,gh.NEntries - 1);

    if gh.magic <> 'GOB ' then
      raise Exception.Create(gobfilename + ' is not a GOB 2.0 file');

    for i := 0 to gh.NEntries - 1 do
    begin
      BlockRead(f, ge, SizeOf(ge));

      Dir := ExtractFileExt(ge.Name);
      if UpperCase(ExtractFileExt(Dir)) = filetype then
      begin
      Result[filecnt].filename:=ge.Name;
      Result[filecnt].offset:=ge.Pos;
      Result[filecnt].container:= gobfilename;
      inc(filecnt);
      end;
    end;
  finally
    CloseFile(f);
  end;
end;

function gobFileArrayToList(FileOffsets: TFileOffsets):TstringList;
var
  j:  integer;
  found:boolean;
begin
 result:=TstringList.Create;

 for j := 0 to Length(FileOffsets) - 1 do
    begin
      if FileOffsets[j].filename = '' then
        break;

      result.Add(FileOffsets[j].filename);
      found:=true;

    end;

  if not found then
     ShowMessage('No Files found in container array');


end;

function gobFilesToList(gobfilename: string; filetype:string):TstringList;
var
  i,filecnt:  integer;
  ge: TGob2Entry;

  gh:  TGOB2Header;
  dir: string;
   f: file;
   FileOffsets: TFileOffsets;
begin
  result:=TstringList.Create;
  filecnt:=0;
  try

    AssignFile(f, gobfilename);
    Reset(f, 1);

    BlockRead(f, gh, SizeOf(gh));
    //SetLength(FileOffsets,gh.NEntries - 1);

    if gh.magic <> 'GOB ' then
      raise Exception.Create(gobfilename + ' is not a GOB 2.0 file');
   // gobview.Label3.Caption := IntToStr(gh.NEntries);
    for i := 0 to gh.NEntries - 1 do
    begin
      BlockRead(f, ge, SizeOf(ge));

      Dir := ExtractFileExt(ge.Name);
      if UpperCase(ExtractFileExt(Dir)) = filetype then
      begin
      //SetLength(FileOffsets,Length(FileOffsets)+1);
     // FileOffsets[filecnt].filename:=ge.Name;
     // FileOffsets[filecnt].offset:=ge.Pos;
      //inc(filecnt);
      //  ListBox1.Items.Append(ge.Name);
      result.Add(ge.Name);
      end;
    end;
  finally
    CloseFile(f);
  end;
end;


function bafFilesToArray(gobfilename: string; filetype:string):TFileOffsets;
var
  i,filecnt,pos:  integer;
  ge: TGob2Entry;

  gh:  TGOB2Header;
  dir: string;
   f: file;
   FileOffsets: TFileOffsets;
   numtex: byte;
  pad:    array[0..27] of ANSIchar;
  pal:    TCMPPal;
  name:array[0..31] of ANSIchar;
  tag:array[0..3] of ANSIchar;
  InStream:TMemoryStream;
  Abytes: array of byte;

begin
  filecnt:=0;
  InStream := TMemoryStream.Create;
  InStream.LoadFromFile(gobfilename);

  SetLength(Abytes, InStream.Size);
  inStream.ReadBuffer(Abytes[0],InStream.Size);

  move(Abytes[196], numtex, SizeOf(numtex));
  SetLength(Result,numtex);
  move(Abytes[336], pal, SizeOf(pal));

  i:=336+SizeOf(pal);
  while not (i >= InStream.Size) and not (filecnt = numtex) do
        begin
          move(Abytes[i], tag, SizeOf(tag));
          i:=i+SizeOf(tag);
          if tag = 'MAT ' then
             begin
               move(Abytes[i-(4+(SizeOf(name)))], name, SizeOf(name));
               if UpperCase(ExtractFileExt(name)) = filetype then
                begin
                  Result[filecnt].filename:=name;
                  Result[filecnt].offset:=i-SizeOf(tag);
                  inc(filecnt);
                end;
             end;

        end;

  InStream.Free;
  InStream:=nil;

  if not filecnt =  numtex then
        raise Exception.Create('didnt read correct number of files')
  //InStream.Position:=336;
  //inStream.Read(pal,SizeOf(pal));
  //inStream.Read(pad, SizeOf(pad));
  //filecnt:=0;





//  try
//
//    AssignFile(f, gobfilename);
//    Reset(f, 1);
//
//        //get number of textures
//        seek(f, 196);
//
//
//        BlockRead(f, numtex, SizeOf(numtex));
//        SetLength(Result,numtex );
//
//        //read the cmp
//        seek(f, 336);
//        BlockRead(f, pal, SizeOf(pal));
//        //defCmppal := pal;
//
//        BlockRead(f, pad, SizeOf(pad));
//        pos:=filepos(f);
//
//        while not Eof(f) do
//        begin
//          BlockRead(f, tag, SizeOf(tag));
//
//            if tag = 'MAT ' then
//              begin
//              pos:=filepos(f);
//              seek(f, pos-(4+(SizeOf(name) )));
//              BlockRead(f, name, SizeOf(name));
//
//              if UpperCase(ExtractFileExt(name)) = filetype then
//              begin
//              Result[filecnt].filename:=name;
//              Result[filecnt].offset:=filepos(f);
//              inc(filecnt);
//              end;
//
//              seek(f, pos);
//              end;
//        end;
//
//        if not filecnt =  numtex then
//        raise Exception.Create('didnt read correct number of files');
//
//
//  finally
//    CloseFile(f);
//  end;
end;



function bafFilesToList(gobfilename: string; filetype:string):TstringList;
var
bafinfo: TFileOffsets;
numtex: byte;
begin
result:=TstringList.Create;
//SetLength(matColorHeaderA,(matFormatHeader.record_count));
end;

procedure getmat(matname: string);
begin
end;


end.

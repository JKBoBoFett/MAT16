unit Util;

interface

uses Windows, Classes, ComCtrls, StdCtrls, SysUtils,vcl.graphics,vcl.controls,Vcl.Dialogs;

function ExtractName(path: string): string;
function ChangeExt(path: string; const newExt: string): string;
function PowerOfTwo(x: integer): boolean;
//function GetWord(const s: string; p: integer; var w: string): integer;
//function PadRight(const s: string; tolen: integer): string;
procedure SaveTransparentBitmap(ABitmap: TBitmap; const AFileName: string);
procedure RenderGrid(Target: TBitmap; Height, Width: Integer; Size: Integer;
  Color1, Color2: TColor);
procedure Blend(First,second:Tbitmap);
procedure TransBlt(dst,src:Tbitmap; color:longint);
function IsBMPPowerOfTwo(x,y: integer): boolean;
function IsBMPmipsOK(Abitmap:tbitmap): boolean;
procedure PremultiplyAlpha(bmp:Tbitmap);
{emissive formats are stored as normal format strings plus the word 'emissive',
 e.g. '16-bit RGBA4444 emissive'}
function IsEmissiveFmt(const fmt: string): Boolean;
{24-bit preview of an emissive cell: colour as seen in the dark, the alpha channel (glow mask)
 brings it back to full brightness.  Accepts 32-bit RGBA and 15-bit ARGB1555 bitmaps.}
function BuildGlowPreview(Src: TBitmap): TBitmap;
implementation

function IsEmissiveFmt(const fmt: string): Boolean;
begin
  Result := Pos('emissive', LowerCase(fmt)) > 0;
end;

function BuildGlowPreview(Src: TBitmap): TBitmap;
type
  TGlowByteRow = array[0..262143] of Byte;
  PGlowByteRow = ^TGlowByteRow;
  TGlowWordRow = array[0..65535] of Word;
  PGlowWordRow = ^TGlowWordRow;
var
  x, y, r, g, b, m, k: Integer;
  bp, dp: PGlowByteRow;
  wp: PGlowWordRow;
  w: Word;
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf24bit;
  Result.SetSize(Src.Width, Src.Height);

  if (Src.PixelFormat <> pf32bit) and (Src.PixelFormat <> pf15bit) and (Src.PixelFormat <> pfCustom) then
  begin
    Result.Canvas.Draw(0, 0, Src);   {no glow mask available}
    exit;
  end;

  for y := 0 to Src.Height - 1 do
  begin
    dp := Result.ScanLine[y];
    if Src.PixelFormat = pf32bit then
    begin
      bp := Src.ScanLine[y];
      for x := 0 to Src.Width - 1 do
      begin
        b := bp^[x * 4];
        g := bp^[x * 4 + 1];
        r := bp^[x * 4 + 2];
        m := bp^[x * 4 + 3];
        k := 77 + (m * 178) div 255;      {about 30% brightness unlit, 100% fully glowing}
        dp^[x * 3]     := (b * k) div 255;
        dp^[x * 3 + 1] := (g * k) div 255;
        dp^[x * 3 + 2] := (r * k) div 255;
      end;
    end
    else
    begin
      wp := Src.ScanLine[y];
      for x := 0 to Src.Width - 1 do
      begin
        w := wp^[x];
        b := (w and 31) * 255 div 31;
        g := ((w shr 5) and 31) * 255 div 31;
        r := ((w shr 10) and 31) * 255 div 31;
        if (w and $8000) <> 0 then m := 255 else m := 0;
        k := 77 + (m * 178) div 255;
        dp^[x * 3]     := (b * k) div 255;
        dp^[x * 3 + 1] := (g * k) div 255;
        dp^[x * 3 + 2] := (r * k) div 255;
      end;
    end;
  end;
end;


function ExtractName(path: string): string;
var
  p: integer;
begin
  p := Pos('>', path);
  if p <> 0 then
    path[p] := '\';
  Result := ExtractFileName(Path);
end;

function ChangeExt(path: string; const newExt: string): string;
var
  p: integer;
begin
  p := Pos('>', path);
  if p <> 0 then
    path[p] := '\';
  Result := ChangeFileExt(Path, newExt);
  if p <> 0 then
    Result[p] := '>';
end;




//function GetWord(const s: string; p: integer; var w: string): integer;
//var
//  b, e: integer;
//begin
//  if s = '' then
//  begin
//    w      := '';
//    Result := 1;
//    exit;
//  end;
//  b := p;
//  while (s[b] in [' ', #9]) and (b <= length(s)) do
//    Inc(b);
//  e := b;
//  while (not (s[e] in [' ', #9])) and (e <= length(s)) do
//    Inc(e);
//  w := Copy(s, b, e - b);
//  GetWord := e;
//end;

//function PadRight(const s: string; tolen: integer): string;
//var
//  i, len: integer;
//begin
//  Result := s;
//  len    := length(Result);
//  if len < tolen then
//    SetLength(Result, toLen);
//  for i := len + 1 to tolen do
//    Result[i] := ' ';
//end;

// TBitmap doesn't support saving bitmaps with alpha channels. This is a workaround.
// https://stackoverflow.com/questions/64597831/how-to-use-correctly-tbitmap-object-to-save-a-file-with-transparency
 procedure SaveTransparentBitmap(ABitmap: TBitmap; const AFileName: string);
var
  FS: TFileStream;
  BFH: TBitmapFileHeader;
  BIH: TBitmapV5Header;
  y: Integer;
  sl: PUInt64;
begin

  // ABitmap MUST have the GIMP BGRA format.

  FS := TFileStream.Create(AFileName, fmCreate);
  try

    // Bitmap file header
    FillChar(BFH, SizeOf(BFH), 0);
    BFH.bfType := $4D42;  // BM
    BFH.bfSize := 4 * ABitmap.Width * ABitmap.Height + SizeOf(BFH) + SizeOf(BIH);
    BFH.bfOffBits := SizeOf(BFH) + SizeOf(BIH);
    FS.Write(BFH, SizeOf(BFH));

    // Bitmap info header
    FillChar(BIH, SizeOf(BIH), 0);
    BIH.bV5Size := SizeOf(BIH);
    BIH.bV5Width := ABitmap.Width;
    BIH.bV5Height := ABitmap.Height;
    BIH.bV5Planes := 1;
    BIH.bV5BitCount := 32;
    BIH.bV5Compression := BI_BITFIELDS;
    BIH.bV5SizeImage := 4 * ABitmap.Width * ABitmap.Height;
    BIH.bV5XPelsPerMeter := 11811;
    BIH.bV5YPelsPerMeter := 11811;
    BIH.bV5ClrUsed := 0;
    BIH.bV5ClrImportant := 0;
    BIH.bV5RedMask :=   $00FF0000;
    BIH.bV5GreenMask := $0000FF00;
    BIH.bV5BlueMask :=  $000000FF;
    BIH.bV5AlphaMask := $FF000000;
    BIH.bV5CSType := $73524742; // BGRs
    BIH.bV5Intent := LCS_GM_GRAPHICS;
    FS.Write(BIH, SizeOf(BIH));

    // Pixels
    for y := ABitmap.Height - 1 downto 0 do
    begin
      sl := ABitmap.ScanLine[y];
      FS.Write(sl^, 4 * ABitmap.Width);
    end;

  finally
    FS.Free;
  end;

end;

procedure RenderGrid(Target: TBitmap; Height, Width: Integer; Size: Integer;
  Color1, Color2: TColor);
var
  Tmp: TBitmap;
  Canvas:Tcanvas;
begin
  Tmp := TBitmap.Create;

  Canvas := TControlCanvas.Create;

  try
    Tmp.Canvas.Brush.Color := Color1;
    Tmp.Width := 2 * Size;
    Tmp.Height := 2 * Size;
    Tmp.Canvas.Brush.Color := Color2;
    Tmp.Canvas.FillRect(Rect(0, 0, Size, Size));
    Tmp.Canvas.FillRect(Bounds(Size, Size, Size, Size));
    Target.Canvas.Brush.Bitmap := Tmp;
    if Target.Width * Target.Height = 0 then
      Target.SetSize(Width, Height)
    else
    begin
      Target.SetSize(Width, Height);
      Target.Canvas.FillRect(Rect(0, 0, Width, Height));
    end;
  finally
    Tmp.Free;
    Canvas.Free;
  end;
end;

procedure Blend(First,second:Tbitmap);
var
   udtBlender: TBlendFunction;
begin
     //Specifies the action to take
     with udtBlender do
     begin
          BlendOp := AC_SRC_OVER;
          BlendFlags := 0;
          SourceConstantAlpha := 255;
          AlphaFormat := AC_SRC_ALPHA;
     end;

     //Draw the first image on destination canvas
 //    First.Canvas.Draw(First.Height,First.Width, First);

     //Blend the second image over the previous one
     AlphaBlend(First.Canvas.Handle,
                0, 0, First.Width, First.Height,
                second.Canvas.Handle,
                0, 0, second.Width, second.Height,
                udtBlender);
end;

 procedure TransBlt(dst,src:Tbitmap;color:longint);
begin
    // gridBMP.PixelFormat:=pf8bit;
     TransparentBlt(
      dst.Canvas.Handle,  // handle to destination DC
      0, 0,               // x, y-coord of destination upper-left corner
      dst.Width,          // width of destination rectangle
      dst.Height,         // height of destination rectangle
      src.Canvas.Handle,  // handle to source DC
      0, 0,               // x, y-coord of source upper-left corner
      src.Width,          // width of source rectangle
      src.Height,         // height of source rectangle
      color               // color to make transparent
     );
    end;


procedure PremultiplyAlpha(bmp:Tbitmap);
var
 inrow32: PRGBQuad;
 j,i:integer;
begin
 for j := 0 to bmp.Height - 1 do
    begin
      inrow32 := bmp.ScanLine[j];
      for i := 0 to bmp.Width - 1 do
      begin
        with inrow32^ do
        begin
            // must pre-multiply the pixel with its alpha channel before drawing
            rgbRed:=   (rgbRed * rgbReserved) div 255;
            rgbGreen:= (rgbGreen * rgbReserved) div 255;
            rgbBlue:=  (rgbBlue * rgbReserved) div 255;
            inc(inrow32);
            end;
       end;
      end;
end;


function IsBMPmipsOK(Abitmap:tbitmap): boolean;
begin
result:=false;
  if (Abitmap.Width >= 8) and (Abitmap.Height >=8) and
     (Abitmap.PixelFormat <> pf32bit) then
  result:=true;


end;

function IsBMPPowerOfTwo(x,y: integer): boolean;
begin
result:=false;
   if poweroftwo(x) and poweroftwo(y) then
   result:=true;
end;

function PowerOfTwo(x: integer): boolean;
begin
  Result := (x = 1) or (x = 2) or (x = 4) or (x = 8) or (x = 16) or
            (x = 32) or (x = 64) or (x = 128) or (x = 256) or (x = 512) or
            (x = 1024) or (x = 2048) or (x = 4096) or (x = 8192) or (x = 16384);
end;

end.

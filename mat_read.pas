unit mat_read;

interface

uses Windows, SysUtils, Graphics, Classes, Dialogs,
  Controls, gobgoo, util, Math,Color16,ColorMap,CMPHeaders;

type
  // Straight from the file specs:
  TMatHeader = record
    tag:      array[0..3] of ANSIchar;     {'MAT ' - notice space after MAT}
    ver:      longint;                 {Apparently - version = 0x32 ('2')}
    mat_Type: longint;
    {0 = colors(TColorHeader) , 1= ?, 2= texture(TTextureHeader)}
    record_count: longint;   {number of textures or colors}
    cel_count: longint;
    { In color MATs, it's 0, in TX ones, it's equal to record_count }
    ColorMode:     longint;                 { = 0 }
    bits:     longint;                 { = 8 } {bits/pixel}
    redbits: longint;
    greenbits: longint;
    bluebits:  longint;
    shiftR:   longint;
    shiftG:   longint;
    shiftB:   longint;
    RedBitDif: longint;    //=3
    GreenBitDif: longint;  //=2
    BlueBitDif: longint;   //=3

    alpha_bpp: longint;  //=0
    alpha_sh: longint;  //=0
    alpha_BitDif: longint;  //=0

  end;

  TColorHeader = record
    textype:  longint;         {0 = color, 8= texture}
    transparent_color: longint;         {Color index from the CMP palette}
    pads:     array[0..2] of longint;   {each = 0x3F800000 (check cmp header )}
  end;

  TTextureHeader = record
    textype:  longint;         {0 = color, 8= texture}
    transparent_color: longint;
    {With 8-bit images, is an index into the palette. With 16-bit images, Transparent is a 16-bit RGB value.}
    pads:     array[0..2] of longint;
    unk1tha:  word;
    unk1thb:  word;  //= 16256
    unk2th:   longint; //=0
    unk3th:   longint; //=4
    unk4th:   longint; //=4
    texnum:   longint; //=0
  end;

  TTextureData = record
    SizeX: longint;             {horizontal size of first MipMap, must be divisable by 2}
    SizeY: longint;             {Vertical size of first MipMap ,must be divisable by 2}
    Transparent: longint;  {1: transparent on, else 0: transparent off}
    Pad:   array[0..1] of longint;{padding = 0 }
    {padding = 0 }
    NumMipMaps: longint;        {Number of mipmaps in texture largest one first.}
  end;

//  TCMPHeader = record
//    sig:    array[0..3] of ANSIchar; {'CMP '}
//    twenty: longint;
//    HasTransparency: longint;
//    stuff:  array[1..52] of byte;
//  end;

type
  act = record
    red:   longint;
    green: longint;
    blue:  longint;
  end;

//type
//  TCMPPal = array[0..255] of record
//    r, g, b: byte;
//  end;


type
  TStoredAs = (ByLines, ByCols);

  TImageInfo = class
    StoredAs: TStoredAs;
    Width, Height: word;
    bpp:      integer;
    RedBits:  integer;
    GreenBits: integer;
    BlueBits: integer;
    RedBitDiff: integer;
    GreenBitDiff: integer;
    BlueBitDiff: integer;
    RedShift: integer;
    GreenShift: integer;
    BlueShift: integer;

  end;




procedure GetLine(var buf);
//procedure SetPal(cmppal: TCMPPal);
procedure WriteMatHeader(f: TStream);
procedure BmptoMat16(bmap: TBitmap; fname: string; mattype: integer; dither: integer);
function Mat8ToBmp(w, h: integer): TBitmap;
function Mat16ToBmp(w, h: integer; trans: boolean; rgba: boolean): TBitmap;
procedure WriteHeader(f: TStream);
function GetPixelFormatString(const PixelFormat: TPixelFormat): string;
function PowerOfTwo(x: integer): boolean;
function checkBMPsize(sbmp: TBitmap): TBitmap;
procedure ImageListtoMat16(bmap: Tbitmap; bmpList: TImageList;
  fname: string; dither: integer);
procedure WriteTextureData(f: TStream);
procedure WriteMHTH(f: TStream);
procedure GenMips(inbmp: TBitmap; dither: integer; f: TStream);
function calcnummips(w: integer; h: integer): integer;
//procedure loadcmp(filename: string);
//procedure savepal(filename: string);
//procedure saveact(filename: string);
procedure savemcf(filename: string);
procedure Writemat16data(bmap: TBitmap; dither: integer; f: TStream);
procedure Writemat32data(bmap: TBitmap;  f: TStream);
procedure ReadCMPfromGOB(gobfile: string; cmp: string);
function ReadMatfromGOB(gobfile: string; matname: string): TBitmap;
function GetbestCMP(matname: string; gobname: string): string;
function SaveAlphamap(bmap: TBitmap): Tbitmap;
function LoadAlphamap(src: TBitmap; abmap: TBitmap): Tbitmap;
procedure WriteEndTag(f: TStream);
function ReadMat(filename: string): Tbitmap;

const
  PixelCountMax = 32768;

type
  pRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..PixelCountMax - 1] of TRGBTriple;

    pRGBQuadArray = ^TRGBQuadArray;
  TRGBQuadArray = array[0..PixelCountMax - 1] of TRGBQuad;
var
  f, fcmp: file;
  FInfo:   TImageInfo;
 // Pal:     array[0..255] of TRGBQuad;

//  defCmppal: TCMPPal = ((r: 0; g: 0; b: 0), (r: 0; g: 255; b: 0), (r: 0;
//    g: 203; b: 0), (r: 0; g: 155; b: 0), (r: 0; g: 107; b: 0), (r: 0;
//    g: 59; b: 0), (r: 255; g: 0; b: 0), (r: 203; g: 0; b: 0), (r: 155;
//    g: 0; b: 0), (r: 107; g: 0; b: 0), (r: 59; g: 0; b: 0), (r: 247;
//    g: 255; b: 0), (r: 215; g: 163; b: 0), (r: 175; g: 87; b: 0), (r: 135;
//    g: 31; b: 0), (r: 95; g: 0; b: 0), (r: 255; g: 255; b: 255), (r: 223;
//    g: 231; b: 255), (r: 195; g: 215; b: 255), (r: 163; g: 195;
//    b: 255), (r: 135; g: 175; b: 255), (r: 255; g: 171; b: 0), (r: 255;
//    g: 159; b: 0), (r: 255; g: 147; b: 0), (r: 255; g: 131; b: 0), (r: 255;
//    g: 111; b: 0), (r: 255; g: 91; b: 0), (r: 255; g: 71; b: 0), (r: 255;
//    g: 51; b: 0), (r: 255; g: 35; b: 0), (r: 255; g: 15; b: 0), (r: 0;
//    g: 0; b: 255), (r: 253; g: 253; b: 253), (r: 247; g: 247; b: 247), (r: 239;
//    g: 239; b: 239), (r: 227; g: 227; b: 227), (r: 219; g: 219;
//    b: 219), (r: 211; g: 211; b: 211), (r: 203; g: 203; b: 203), (r: 195;
//    g: 195; b: 195), (r: 187; g: 187; b: 187), (r: 179; g: 179;
//    b: 179), (r: 171; g: 171; b: 171), (r: 163; g: 163; b: 163), (r: 155;
//    g: 155; b: 155), (r: 147; g: 147; b: 147), (r: 139; g: 139;
//    b: 139), (r: 131; g: 131; b: 131), (r: 123; g: 123; b: 123), (r: 115;
//    g: 115; b: 115), (r: 107; g: 107; b: 107), (r: 99; g: 99; b: 99), (r: 87;
//    g: 87; b: 87), (r: 79; g: 79; b: 79), (r: 71; g: 71; b: 71), (r: 63;
//    g: 63; b: 63), (r: 55; g: 55; b: 55), (r: 47; g: 47; b: 47), (r: 39;
//    g: 39; b: 39), (r: 31; g: 31; b: 31), (r: 23; g: 23; b: 23), (r: 15;
//    g: 15; b: 15), (r: 7; g: 7; b: 7), (r: 0; g: 0; b: 0), (r: 191;
//    g: 199; b: 223), (r: 183; g: 191; b: 215), (r: 179; g: 183;
//    b: 207), (r: 171; g: 179; b: 203), (r: 163; g: 171; b: 195), (r: 159;
//    g: 163; b: 187), (r: 151; g: 159; b: 183), (r: 147; g: 151;
//    b: 175), (r: 139; g: 143; b: 167), (r: 135; g: 139; b: 163), (r: 127;
//    g: 131; b: 155), (r: 119; g: 123; b: 147), (r: 115; g: 119;
//    b: 139), (r: 107; g: 111; b: 135), (r: 103; g: 107; b: 127), (r: 95;
//    g: 99; b: 119), (r: 91; g: 95; b: 115), (r: 87; g: 87; b: 107), (r: 79;
//    g: 83; b: 99), (r: 75; g: 75; b: 95), (r: 67; g: 71; b: 87), (r: 63;
//    g: 63; b: 79), (r: 55; g: 59; b: 75), (r: 51; g: 51; b: 67), (r: 47;
//    g: 47; b: 59), (r: 39; g: 43; b: 55), (r: 35; g: 35; b: 47), (r: 31;
//    g: 31; b: 39), (r: 23; g: 27; b: 35), (r: 19; g: 19; b: 27), (r: 15;
//    g: 15; b: 19), (r: 11; g: 11; b: 15), (r: 255; g: 207; b: 179), (r: 231;
//    g: 175; b: 143), (r: 207; g: 143; b: 111), (r: 183; g: 119;
//    b: 87), (r: 159; g: 91; b: 63), (r: 135; g: 71; b: 43), (r: 111;
//    g: 51; b: 27), (r: 87; g: 35; b: 15), (r: 255; g: 255; b: 0), (r: 227;
//    g: 195; b: 0), (r: 199; g: 143; b: 0), (r: 171; g: 99; b: 0), (r: 147;
//    g: 63; b: 0), (r: 119; g: 31; b: 0), (r: 91; g: 11; b: 0), (r: 67;
//    g: 0; b: 0), (r: 223; g: 255; b: 167), (r: 207; g: 239; b: 135), (r: 191;
//    g: 223; b: 103), (r: 179; g: 207; b: 75), (r: 167; g: 191;
//    b: 51), (r: 159; g: 175; b: 31), (r: 151; g: 159; b: 11), (r: 143;
//    g: 147; b: 0), (r: 199; g: 99; b: 31), (r: 183; g: 87; b: 23), (r: 171;
//    g: 75; b: 19), (r: 155; g: 63; b: 11), (r: 143; g: 55; b: 7), (r: 127;
//    g: 47; b: 7), (r: 115; g: 39; b: 0), (r: 103; g: 31; b: 0), (r: 251;
//    g: 0; b: 0), (r: 227; g: 0; b: 0), (r: 199; g: 0; b: 0), (r: 171;
//    g: 0; b: 0), (r: 143; g: 0; b: 0), (r: 115; g: 0; b: 0), (r: 87;
//    g: 0; b: 0), (r: 57; g: 0; b: 0), (r: 127; g: 163; b: 199), (r: 95;
//    g: 127; b: 171), (r: 67; g: 95; b: 147), (r: 43; g: 67; b: 123), (r: 23;
//    g: 39; b: 95), (r: 11; g: 19; b: 71), (r: 0; g: 7; b: 47), (r: 0;
//    g: 0; b: 23), (r: 195; g: 115; b: 71), (r: 183; g: 107; b: 63), (r: 175;
//    g: 99; b: 59), (r: 163; g: 91; b: 51), (r: 155; g: 87; b: 47), (r: 147;
//    g: 79; b: 43), (r: 135; g: 71; b: 35), (r: 127; g: 67; b: 31), (r: 115;
//    g: 59; b: 27), (r: 107; g: 55; b: 23), (r: 99; g: 47; b: 19), (r: 87;
//    g: 43; b: 15), (r: 79; g: 39; b: 15), (r: 67; g: 31; b: 11), (r: 59;
//    g: 27; b: 7), (r: 51; g: 23; b: 7), (r: 255; g: 231; b: 179), (r: 239;
//    g: 211; b: 155), (r: 223; g: 195; b: 135), (r: 211; g: 179;
//    b: 119), (r: 195; g: 163; b: 99), (r: 183; g: 147; b: 83), (r: 167;
//    g: 135; b: 71), (r: 151; g: 119; b: 55), (r: 139; g: 103; b: 43), (r: 123;
//    g: 91; b: 31), (r: 111; g: 79; b: 23), (r: 95; g: 67; b: 15), (r: 79;
//    g: 55; b: 11), (r: 67; g: 43; b: 7), (r: 51; g: 31; b: 0), (r: 39;
//    g: 23; b: 0), (r: 131; g: 231; b: 103), (r: 115; g: 207; b: 83), (r: 99;
//    g: 183; b: 67), (r: 83; g: 159; b: 55), (r: 71; g: 139; b: 43), (r: 59;
//    g: 115; b: 31), (r: 47; g: 91; b: 23), (r: 35; g: 71; b: 15), (r: 255;
//    g: 167; b: 255), (r: 223; g: 127; b: 231), (r: 195; g: 95;
//    b: 207), (r: 163; g: 67; b: 183), (r: 135; g: 43; b: 159), (r: 107;
//    g: 23; b: 135), (r: 79; g: 7; b: 111), (r: 55; g: 0; b: 91), (r: 255;
//    g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255;
//    g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255;
//    g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255;
//    g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255;
//    g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255;
//    g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255;
//    g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255;
//    g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255;
//    g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255;
//    g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255;
//    g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255;
//    g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255;
//    g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255;
//    g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255;
//    g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255;
//    g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255;
//    g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255;
//    g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255;
//    g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255;
//    g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255;
//    g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255; g: 0; b: 255), (r: 255;
//    g: 255; b: 255));

implementation



//procedure SetPal(cmppal: TCMPPal);
//var
//  i: integer;
//begin
//  for i := 0 to 255 do
//    with CmpPal[i], Pal[i] do
//    begin
//      rgbRed   := r;
//      rgbGreen := g;
//      rgbBlue  := b;
//    end;
//end;



procedure GetLine(var buf);
begin
  BlockRead(f, buf, FInfo.Width);
end;

procedure WriteHeader(f: TStream);
var
  Bi:  TBitmapInfoHeader;
  Bfh: TBitmapFileHeader;
  bw, bh, bw4: integer;
begin
  bw := FInfo.Width;
  bh := FInfo.Height;
  if bw and 3 = 0 then
    bw4 := bw
  else
    bw4 := bw and $FFFFFFFC + 4;

  with Bfh do
  begin
    bfType      := $4D42; {'BM'}
    bfOffBits   := sizeof(bfh) + sizeof(bi) + sizeof(TRGBQuad) * 256;
    bfReserved1 := 0;
    bfReserved2 := 0;
    bfSize      := bfOffBits + bh * bw4;
  end;

  FillChar(Bi, Sizeof(bi), 0);

  with BI do
  begin
    biSize     := sizeof(BI);
    biWidth    := bw;
    biHeight   := bh;
    biPlanes   := 1;
    biBitCount := 8;
  end;
  f.Write(bfh, sizeof(bfh));
  f.Write(bi, sizeof(bi));
  f.Write(Pal, sizeof(Pal));
end;


 ////////////////////////////////////////////////
 //   ImageListtoMat16
 //  converts any /2 bitmap to a 16bit mat
 ///////////////////////////////////////////////
procedure ImageListtoMat16(bmap: Tbitmap; bmplist: TimageList;
  fname: string; dither: integer);
var
  MH:  TMatHeader;
  TH:  TTextureHeader;
  cnt: integer;
  Ms:  TMemoryStream;
begin
  bmpList.GetBitmap(0, Bmap);

  Finfo := TImageInfo.Create;
  FInfo.Width := bmap.Width;
  FInfo.Height := bmap.Height;

  ms := TMemoryStream.Create;

  // set all the header info
  with MH do
  begin
    tag      := 'MAT ';      //array[0..3] of char;     {'MAT ' - notice space after MAT}
    ver      := 50;             //Longint;             {Apparently - version = 0x32 ('2')}
    mat_Type := 2;
    //Longint;            {0 = colors(TColorHeader) , 1= ?, 2= texture(TTextureHeader)}
    record_count := bmplist.Count;   //Longint;   {number of textures or colors}
    cel_count := bmplist.Count;
    // Longint; { In color MATs, it's 0, in TX ones, it's equal to record_count }
    ColorMode     := 1;            //Longint;                 { = 0 }
    bits     := 16;           //LongInt;                 { = 8 } {bits/pixel}
    bluebits := 5;
    greenbits := 6;
    redbits  := 5;

    //for transparent mats
  //  if optionsform.checkbox3.Checked = True then
    begin
      bluebits  := 5;
      greenbits := 5;
      redbits   := 5;
    end;

    shiftR := 11;
    shiftG := 5;
    shiftB := 0;

    //for transparent mats
  //  if optionsform.checkbox3.Checked = True then
    begin
      shiftR := 10;
      shiftG := 5;
      shiftB := 0;
    end;


    RedBitDif   := 3;
    GreenBitDif := 2;
    BlueBitDif  := 3;

    //for transparent mats
 //   if optionsform.checkbox3.Checked = True then
    begin
      RedBitDif   := 3;
      GreenBitDif := 3;
      BlueBitDif  := 3;
    end;

    alpha_bpp := 0;
    alpha_sh := 0;
    alpha_BitDif := 0;
  end;


  //write the mat header
  ms.Write(MH, sizeof(MH));

  // texture headers are repeated record_count * TTextureHeader times
  for cnt := 0 to bmplist.Count - 1 do
  begin
    //set all the texture header info
    with TH do
    begin
      textype  := 8;      //longint;         {0 = color, 8= texture}
      transparent_color := 0;
      pads[0]  := 0;
      pads[1]  := 0;
      pads[2]  := 0;
      unk1tha  := 0;
      unk1thb  := 0;
      unk2th   := 0;
      unk3th   := 4;
      unk4th   := 4;
      texnum   := cnt;
      ms.Write(TH, sizeof(TH));
    end;

    //write the texture header
    //ms.Write(TH,sizeof(TH));
  end;


  //loop through all the bitmaps in the image list
  //convert the texture data to Mat format
  for cnt := 0 to bmplist.Count - 1 do
  begin
    bmpList.GetBitmap(cnt, Bmap);
    WriteTextureData(ms);
    // ms.Write(TD,sizeof(TD));
    // WriteMat16Data(bmap, ms);

    //write to transparent mat ARGB if selected
 //   if optionsform.checkbox3.Checked = True then
    begin
      Finfo.bpp      := 16;
      Finfo.RedBits  := 5;
      Finfo.GreenBits := 5;
      Finfo.BlueBits := 5;
      Finfo.RedBitDiff := 3;
      Finfo.GreenBitDiff := 3;
      Finfo.BlueBitDiff := 3;
      Finfo.RedShift := 10;
      Finfo.GreenShift := 5;
      Finfo.BlueShift := 0;
      // WriteMatARGB16Data(bmap, ms);
      WriteMat16Data(bmap, dither, ms);
    end;


    //write normal RGB
 //   if optionsform.checkbox3.Checked = False then
    begin
      Finfo.bpp      := 16;
      Finfo.RedBits  := 5;
      Finfo.GreenBits := 6;
      Finfo.BlueBits := 5;
      Finfo.RedBitDiff := 3;
      Finfo.GreenBitDiff := 2;
      Finfo.BlueBitDiff := 3;
      Finfo.RedShift := 11;
      Finfo.GreenShift := 5;
      Finfo.BlueShift := 0;
      WriteMat16Data(bmap, dither, ms);
    end;

 //   if optionsform.checkbox1.Checked = True then
      genmips(bmap, 0, ms);

  end;

  ms.SaveToFile(fname);

  Ms.Free;
end;{end of imagelisttoMat16}



 ////////////////////////////////////////////////
 //   BmptoMat16
 //  converts any /2 bitmap to a 16bit mat
 ///////////////////////////////////////////////
procedure BmptoMat16(bmap: TBitmap; fname: string; mattype: integer; dither: integer);
var
  Ms: TMemoryStream;

begin

  Finfo := TImageInfo.Create;
  FInfo.Width := bmap.Width;
  FInfo.Height := bmap.Height;
  //mattype:=3;
  //16-bit ARGB 1555 format
  if (mattype = 0) then
  begin
    Finfo.bpp      := 16;
    Finfo.RedBits  := 5;
    Finfo.GreenBits := 5;
    Finfo.BlueBits := 5;
    Finfo.RedBitDiff := 3;
    Finfo.GreenBitDiff := 3;
    Finfo.BlueBitDiff := 3;
    Finfo.RedShift := 10;
    Finfo.GreenShift := 5;
    Finfo.BlueShift := 0;

    //optionsform.checkbox3.Checked := True;
  end;


  //16-bit RGB 565 format
  if (mattype = 1) then
  begin
    Finfo.bpp      := 16;
    Finfo.RedBits  := 5;
    Finfo.GreenBits := 6;
    Finfo.BlueBits := 5;
    Finfo.RedBitDiff := 3;
    Finfo.GreenBitDiff := 2;
    Finfo.BlueBitDiff := 3;
    Finfo.RedShift := 11;
    Finfo.GreenShift := 5;
    Finfo.BlueShift := 0;
    //optionsform.checkbox3.Checked := False;
  end;

  //16-bit ARGB 444 format
  if (mattype = 2) then
  begin
    Finfo.bpp      := 16;
    Finfo.RedBits  := 4;
    Finfo.GreenBits := 4;
    Finfo.BlueBits := 4;
    Finfo.RedBitDiff := 4;
    Finfo.GreenBitDiff := 4;
    Finfo.BlueBitDiff := 4;
    Finfo.RedShift := 8;
    Finfo.GreenShift := 4;
    Finfo.BlueShift := 0;
  end;

  //16-bit ARGB 444 format
  if (mattype = 3) then
  begin
    Finfo.bpp      := 24;
    Finfo.RedBits  := 8;
    Finfo.GreenBits := 8;
    Finfo.BlueBits := 8;
    Finfo.RedBitDiff := 0;
    Finfo.GreenBitDiff := 0;
    Finfo.BlueBitDiff := 0;
    Finfo.RedShift := 0;
    Finfo.GreenShift := 0;
    Finfo.BlueShift := 0;
  end;

   //32-bit RGBA 8888 format
  if (mattype = 4) then
  begin
    Finfo.bpp      := 32;
    Finfo.RedBits  := 8;
    Finfo.GreenBits := 8;
    Finfo.BlueBits := 8;
    Finfo.RedBitDiff := 0;
    Finfo.GreenBitDiff := 0;
    Finfo.BlueBitDiff := 0;
    Finfo.RedShift := 24;
    Finfo.GreenShift := 16;
    Finfo.BlueShift := 8;
  end;

  ms := TMemoryStream.Create;

  WriteMatHeader(ms);

  if (mattype < 4) then
  begin
  WriteMat16Data(bmap, dither, ms);

  //mip maps only work on non-transparent mats
 // if optionsform.checkbox1.Checked = True then
    genmips(bmap, dither, ms);
  end;

   if (mattype >= 4) then
  begin
    WriteMat32Data(bmap, ms);
  end;
  // WriteEndTag(ms);

  ms.SaveToFile(fname);

  Ms.Free;
   //memleak fix
   Finfo.Free;
end;{end of BmptoMat16}


//////////////////////////////////////////////////////

 //  Writes the 16 bit mat header info into the Stream
 //////////////////////////////////////////////////////
procedure WriteMHTH(f: TStream);
var
  MH: TMatHeader;
  TH: TTextureHeader;
begin
  with MH do
  begin
    tag      := 'MAT ';      //array[0..3] of char;     {'MAT ' - notice space after MAT}
    ver      := 50;             //Longint;             {Apparently - version = 0x32 ('2')}
    mat_Type := 2;
    //Longint;            {0 = colors(TColorHeader) , 1= ?, 2= texture(TTextureHeader)}
    record_count := 1;   //Longint;   {number of textures or colors}
    cel_count := 1;
    // Longint; { In color MATs, it's 0, in TX ones, it's equal to record_count }
    ColorMode     := 1;            //Longint;                 { = 0 }
    bits     := 16;           //LongInt;                 { = 8 } {bits/pixel}
    bluebits := 5;
    greenbits := 6;
    redbits  := 5;

    shiftR := 11;
    shiftG := 5;
    shiftB := 0;

    RedBitDif   := 3;
    GreenBitDif := 2;
    BlueBitDif  := 3;

    alpha_bpp := 0;
    alpha_sh := 0;
    alpha_BitDif := 0;
  end;

  with TH do
  begin
    textype  := 8;      //longint;         {0 = color, 8= texture}
    transparent_color := 0;
    pads[0]  := 0;
    pads[1]  := 0;
    pads[2]  := 0;
    unk1tha  := 0;
    unk1thb  := 0;
    unk2th   := 0;
    unk3th   := 4;
    unk4th   := 4;
    texnum   := 0;
  end;

  f.Write(MH, sizeof(MH));
  f.Write(TH, sizeof(TH));
end;

procedure WriteTextureData(f: TStream);
var
  TD: TTextureData;
begin
  with TD do
  begin
    SizeX := FInfo.Width;
    {horizontal size of first MipMap, must be divisable by 2}
    SizeY := FInfo.Height;
    Transparent := 0;
    //Longint;             {Vertical size of first MipMap ,must be divisable by 2}
  //  if optionsform.checkbox3.Checked = True then
      Transparent := 1;
    Pad[0] := 0;
    Pad[1]     := 0;
    NumMipMaps := 1;
    //LongInt;        {Number of mipmaps in texture largest one first.}


    // if optionsform.checkBox3.checked = false then
    // begin
 //   if OptionsForm.CheckBox1.Checked = True then
 //     TD.NumMipMaps := OptionsForm.Trackbar1.position;
    // end;
  end;

  f.Write(TD, sizeof(TD));
end;

procedure WriteEndTag(f: TStream);
var
  Tag: array[0..11] of char;
begin
  Tag := 'Mat16 112604';
  f.Write(Tag, sizeof(Tag));
end;
 //////////////////////////////////////////////////////
 //   WriteMatHeader
 //  Writes the 16 bit mat header info into the Stream
 //////////////////////////////////////////////////////
procedure WriteMatHeader(f: TStream);
var
  MH: TMatHeader;
  TH: TTextureHeader;
  TD: TTextureData;
begin
  with MH do
  begin
    tag      := 'MAT ';      //array[0..3] of char;     {'MAT ' - notice space after MAT}
    ver      := 50;             //Longint;             {Apparently - version = 0x32 ('2')}
    mat_Type := 2;
    //Longint;            {0 = colors(TColorHeader) , 1= ?, 2= texture(TTextureHeader)}
    record_count := 1;   //Longint;   {number of textures or colors}
    cel_count := 1;
    // Longint; { In color MATs, it's 0, in TX ones, it's equal to record_count }
    ColorMode     := 1;            //Longint;                 { = 0 }
    bits     := 16;           //LongInt;                 { = 8 } {bits/pixel}


    bluebits  := 5;
    greenbits := 6;
    redbits   := 5;

    //for transparent mats
 //   if optionsform.checkbox3.Checked = True then
    begin
      bluebits  := 5;
      greenbits := 5;
      redbits   := 5;
    end;



    shiftR := 11;
    shiftG := 5;
    shiftB := 0;

    //for transparent mats
  //  if optionsform.checkbox3.Checked = True then
    begin
      shiftR := 10;
      shiftG := 5;
      shiftB := 0;
    end;

    RedBitDif   := 3;
    GreenBitDif := 2;
    BlueBitDif  := 3;

    //for transparent mats
  //  if optionsform.checkbox3.Checked = True then
    begin
      RedBitDif   := 3;
      GreenBitDif := 3;
      BlueBitDif  := 3;
    end;

    alpha_bpp := 0;
    alpha_sh := 0;
    alpha_BitDif := 0;
  end;

  with TH do
  begin
    textype := 8;      //longint;         {0 = color, 8= texture}

    transparent_color := 0; //black is the transparent color

    //for transparent mats
 //   if optionsform.checkbox3.Checked = True then
      transparent_color := 1;

    pads[0] := 0;
    pads[1] := 0;
    pads[2] := 0;
    unk1tha := 0;
    unk1thb := 0;
    unk2th  := 0;
    unk3th  := 4;
    unk4th  := 4;
    texnum  := 0;
  end;

  with TD do
  begin
    SizeX := FInfo.Width;
    {horizontal size of first MipMap, must be divisable by 2}
    SizeY := FInfo.Height;
    //Longint;             {Vertical size of first MipMap ,must be divisable by 2}
    Transparent := 0;
  //  if optionsform.checkbox3.Checked = True then
      Transparent := 1;
    Pad[0] := 0;
    Pad[1] := 0;

    TD.NumMipMaps := 1;

    //mip maps are only generated if the mat is not transparent
  //  if optionsform.checkBox3.Checked = False then
    begin
    //  if OptionsForm.CheckBox1.Checked = True then
   //     TD.NumMipMaps := OptionsForm.Trackbar1.position;
    end;

    // if (sizeX <= 32) or (sizeY <= 32) then
    //  TD.NumMipMaps := 1;

    // if OptionsForm.CheckBox1.Checked = False then
    //   TD.NumMipMaps := 1;
  end;

  f.Write(MH, sizeof(MH));
  f.Write(TH, sizeof(TH));
  f.Write(TD, sizeof(TD));
end;



function Mat8ToBmp(w, h: integer): TBitmap;
var
  i:     integer;
  Ms:    TMemoryStream;
  pLine: PChar;
  pos:   longint;
  bw, bh, bw4: integer;
begin

  Finfo := TImageInfo.Create;
  FInfo.Width := w;
  FInfo.Height := h;
  bw    := w;
  bh    := h;
  if bw and 3 = 0 then
    bw4 := bw
  else
    bw4 := bw and $FFFFFFFC + 4;
  GetMem(Pline, bw4);

  ms := TMemoryStream.Create;
  WriteHeader(ms);
  try
    Pos := ms.Position;
    for i := Bh - 1 downto 0 do
    begin
      GetLine(Pline^);
      ms.Position := Pos + i * bw4;
      ms.Write(PLine^, bw4);
    end;
    ms.Position := 0;
    Result      := TBitmap.Create;
    Result.PixelFormat := pf8bit;
    Result.LoadFromStream(ms);
    Ms.Free;

  finally
    FreeMem(pLine);
  end;
  //mem leak fix
  Finfo.Free;
end;

function Mat16ToBmp(w, h: integer; trans: boolean; rgba: boolean): TBitmap;
var
  i, j:  integer;
  src:   word;
  inrow: pRGBTripleArray;
  alpha: byte;
begin
  Result := TBitmap.Create;

  Result.Width  := W;
  Result.Height := H;
  Result.PixelFormat := pf16bit;

  //support for rgba4444
  if rgba then
  begin
    Result.PixelFormat := pf24bit;

    for j := 0 to H - 1 do
    begin
      inrow := Result.ScanLine[j];
      for i := 0 to W - 1 do
      begin
        BlockRead(f, src, sizeof(src));

        inrow[i].rgbtRed := src and 61440 shr 12 shl 4;
        inrow[i].rgbtGreen := src and 3840 shr 8 shl 4;
        inrow[i].rgbtBlue := src and 240 shr 4 shl 4;
        alpha := src and 15 shr 0 shl 4;

      end;
    end;
  end; {end of support for rgba4444}

  //support for argb1555
  if trans then
    Result.PixelFormat := pf15bit;

  if not rgba then
  begin
    for i := 0 to H - 1 do
      BlockRead(f, Result.Scanline[i]^, w * 2);
  end;
end;

procedure GenMips(inbmp: TBitmap; dither: integer; f: TStream);
var
  mipi, Height, Width, cnt: integer;
  mipbmp: Tbitmap;
begin
  Height := inbmp.Height;
  Width  := inbmp.Width;

 // cnt := OptionsForm.Trackbar1.position - 1;

  for mipi := 0 to cnt - 1 do
  begin
    mipbmp := Tbitmap.Create;

    //bitmap is to small to resize
    //if height<32 then exit;
    //if width<32 then exit;



    Height := Height div 2;
    Width  := Width div 2;

    if Height < 2 then
      Height := 2;
    if Width < 2 then
      Width := 2;


    mipbmp.Height := Height;
    mipbmp.Width  := Width;

    if (inbmp.Width <= 32) or (inbmp.Height <= 32) then
    begin

      mipbmp.Canvas.CopyRect(Rect(0, 0, Width, Height),
        inbmp.Canvas,
        Rect(0, 0, inbmp.Width, inbmp.Height));
    end;

    if (inbmp.Width > 32) and (inbmp.Height > 32) then
      //resize the bmp
   //   Strecth(inbmp, mipbmp,
     //   ResampleFilters[2].Filter, ResampleFilters[2].Width);

    //write the resized BMP data into the file stream
    // WriteMat16Data(mipbmp, f);

    //write to transparent mat ARGB if selected
   // if optionsform.checkbox3.Checked = True then
      ShowMessage('Transparent Mats do not support Mip Maps');


    //write normal RGB
   // if optionsform.checkbox3.Checked = False then
      WriteMat16Data(mipbmp, dither, f);



    //debug use only
  //  if optionsForm.debugbox.Checked = True then
      mipbmp.savetofile('Mat16_debug_miptest' + IntToStr(mipi) + '.bmp');




    mipbmp.Free;
  end;
 // if optionsForm.debugbox.Checked = True then
    ShowMessage('Created ' + IntToStr(mipi) + 'Mip maps for main Image');
end; {GenMips}




function GetPixelFormatString(const PixelFormat: TPixelFormat): string;
var
  Format: string;
begin
  case PixelFormat of
    pfDevice: Format := 'Device';
    pf1bit: Format := '1 bit';
    pf4bit: Format := '4 bit';
    pf8bit: Format := '8 bit';
    pf15bit: Format := '15 bit';
    pf16bit: Format := '16 bit';
    pf24bit: Format := '24 bit';
    pf32bit: Format := '32 bit'
    else
      Format := 'Unknown';
  end;
  Result := Format;
end {GetPixelFormatString};


function PowerOfTwo(x: integer): boolean;
begin
  Result := (x = 1) or (x = 2) or (x = 4) or (x = 8) or (x = 16) or
    (x = 32) or (x = 64) or (x = 128) or (x = 256) or (x = 512) or
    (x = 1024) or (x = 2048) or (x = 4096) or (x = 8192) or (x = 16384);
end;

function checkBMPsize(sbmp: TBitmap): TBitmap;
var
  width_max, width_min, width_r, bal_max, bal_min: integer;
  height_max, height_min, height_r: integer;
begin
 // if optionsform.CheckBox2.Checked = True then
  begin
    //if bitmap size is not a power of 2 resize it
    if not poweroftwo(sbmp.Width) or not poweroftwo(sbmp.Height) then
    begin
      //find the nearest power of 2 for the width of bitmap
      width_max := sbmp.Width;
      width_min := sbmp.Width;

      while not poweroftwo(width_max) do
        Inc(width_max);
      while not poweroftwo(width_min) do
        Dec(width_min);

      bal_max := width_max - sbmp.Width;
      bal_min := sbmp.Width - width_min;

      if bal_max > bal_min then
        width_r := width_min;
      if bal_max < bal_min then
        width_r := width_max;


      //find the nearest power of 2 for the height of bitmap
      height_max := sbmp.Height;
      height_min := sbmp.Height;

      while not poweroftwo(height_max) do
        Inc(height_max);
      while not poweroftwo(height_min) do
        Dec(height_min);

      bal_max := height_max - sbmp.Height;
      bal_min := sbmp.Height - height_min;

      if bal_max > bal_min then
        height_r := height_min;
      if bal_max < bal_min then
        height_r := height_max;

      //  bal_MAX := 0;
      //  bal_max := height_max - sbmp.Height;

      Result := TBitmap.Create;
      Result.Width := width_r;
      Result.Height := height_r;

      //Strecth(sbmp, Result,
      //  ResampleFilters[optionsform.trackbar2.position].Filter,
       // ResampleFilters[optionsform.trackbar2.position].Width);
    end;

    // if bitmap size is a power of 2 no resize is needed
    if poweroftwo(sbmp.Width) or poweroftwo(sbmp.Height) then
    begin
      Result := sbmp;
    end;
  end;

 // if optionsform.CheckBox2.Checked = False then
  begin
    if not poweroftwo(sbmp.Width) or not poweroftwo(sbmp.Height) then
    begin
      ShowMessage('Warning : BitMap Size Must be a power of 2!');
    end;
    Result := sbmp;
  end;
end;


function calcnummips(w: integer; h: integer): integer;
var
  ans, divby, mipw, miph: integer;
begin
  divby := 16;

  ans := w div divby;
  if ans > 15 then
    mipw := 4;


  if ans < 16 then
  begin
    while ans <> 16 do
    begin
      divby := divby div 2;
      if divby = 0 then
        break;
      ans := w div divby;
    end;

    if divby = 8 then
      mipw := 3;
    if divby = 4 then
      mipw := 2;
    if divby = 2 then
      mipw := 1;
    if divby = 1 then
      mipw := 0;
    if divby = 0 then
      mipw := 0;
  end;


  divby := 16;

  ans := h div divby;
  if ans > 15 then
    miph := 4;


  if ans < 16 then
  begin
    while ans <> 16 do
    begin
      divby := divby div 2;
      if divby = 0 then
        break;
      ans := h div divby;
    end;

    if divby = 8 then
      miph := 3;
    if divby = 4 then
      miph := 2;
    if divby = 2 then
      miph := 1;
    if divby = 1 then
      miph := 0;
    if divby = 0 then
      miph := 0;
  end;

  if mipw < miph then
    Result := mipw;
  if mipw > miph then
    Result := miph;
  if mipw = miph then
    Result := miph;
end;

//procedure loadcmp(filename: string);
// // note: cmp pallete = 768 bytes
// // phantom menace cmp's start at 150h,336
//var
//
//  cmph: TCMPHeader;
//  pal:  TCMPPal;
//  fcmp: file;
//begin
//  AssignFile(fcmp, filename);
//  Reset(fcmp, 1);
//
//  BlockRead(fcmp, cmph, SizeOf(cmph));
//
//  if cmph.sig <> 'CMP ' then
//    Reset(fcmp, 1);    //phantom menace cmp's have no header
//
//
//  BlockRead(fcmp, pal, SizeOf(pal));
//
//  defCmppal := pal;
//
//  CloseFile(fcmp);
//end;

//procedure savepal(filename: string);
//var
//  OutFile: textfile;
//  i: integer;
//begin
//  AssignFile(OutFile, filename);
//  Rewrite(OutFile);
//
//  WriteLn(OutFile, 'JASC-PAL');
//  WriteLn(OutFile, '0100');
//  WriteLn(OutFile, '256');
//
//  for i := 0 to 255 do
//    with defCmppal[i] do
//    begin
//      WriteLn(OutFile, IntToStr(r) + ' ' + IntToStr(g) + ' ' + IntToStr(b));
//    end;
//  CloseFile(OutFile);
//end;


//procedure saveact(filename: string);
//var
//  i:     integer;
//  actfile: file;
//  color: longint;
//begin
//  assignfile(actfile, filename);
//  Rewrite(actfile, 1);
//  for i := 0 to 255 do
//    with defCmppal[i] do
//    begin
//      color := r;
//      Blockwrite(actfile, color, 1);
//
//      color := g;
//      Blockwrite(actfile, color, 1);
//
//      color := b;
//      Blockwrite(actfile, color, 1);
//    end;
//
//
//  CloseFile(actfile);
//end;



 ////////////////////////////////////////////////
 //  Bmp24toMat16Fs

///////////////////////////////////////////////
procedure Writemat16data(bmap: TBitmap; dither: integer; f: TStream);
var

  i, j, DestRed, DestGreen, DestBlue, GreenError, BlueError, RedError: integer;
  SrcRed, SrcGreen, SrcBlue: integer;
  RGB, alpha_W: word;
  // alpha:byte;
  //  x: integer;
  //  y: integer;
  inrow: pRGBTripleArray;
  // samp:Tbitmap;
  //  tolerance,red,green,blue:integer;


  data16 : Array of TColor16;
  pdata16 : ^TColor16;

begin
  // dither:=0;
  //  totalerror:=0;
  bmap.PixelFormat := pf24bit;

  // GBlur(bmap, 7);

  for j := 0 to Bmap.Height - 1 do

  begin

    //Reset the error after every Line because we don't want the error
    //of the last pixel to be used on the first pixel of this line
    RedError   := 0;
    GreenError := 0;
    BlueError  := 0;

     SetLength(data16,(Bmap.Width*Bmap.Height));
   // new (data.Create(0,1,0,0));
    inrow := bmap.ScanLine[j];
    //read one source row
    for i := 0 to Bmap.Width - 1 do
    begin

      //Get RGB source components
      SrcRed   := inrow[i].rgbtRed;
      SrcGreen := inrow[i].rgbtGreen;
      SrcBlue  := inrow[i].rgbtBlue;

      if (dither = 1) then
      begin

        // add the error while clamping to the max color value
        SrcRed   := min(255, SrcRed + (RedError));
        SrcGreen := min(255, SrcGreen + (GreenError));
        SrcBlue  := min(255, SrcBlue + (BlueError));


        //Calculate the resulting destination colors
        DestRed   := SrcRed shr Finfo.RedBitDiff;
        DestGreen := SrcGreen shr Finfo.GreenBitDiff;
        DestBlue  := SrcBlue shr Finfo.BlueBitDiff;

        //Calculate the error
        RedError   := SrcRed - (DestRed shl Finfo.RedBitDiff);
        GreenError := SrcGreen - (DestGreen shl Finfo.GreenBitDiff);
        BlueError  := SrcBlue - (DestBlue shl Finfo.BlueBitDiff);

      end;

      if (dither = 0) then
      begin
        DestRed   := SrcRed shr Finfo.RedBitDiff;
        DestGreen := SrcGreen shr Finfo.GreenBitDiff;
        DestBlue  := SrcBlue shr Finfo.BlueBitDiff;
      end;

      //Compose the destination pixel
      rgb := (DestRed) shl Finfo.RedShift or (DestGreen) shl
        Finfo.GreenShift or (DestBlue) shl Finfo.BlueShift;
      //data16[i].Create(0,1,0,0);

      //support for transparent 1555
      {note:  alpha := 0  //transparent}
      {alpha := 1; //not transparent}
      if (Finfo.GreenBits = 5) then
      begin

        //  DestRedA := DestRed shr 4;
        //  DestGreenA := DestGreen shr 4;
        //  DestBlueA := DestBlue shr 4;

        alpha_w :=
          (DestRed shr 4) shl 15 or (DestGreen shr 4) shl
          15 or (DestBlue shr 4) shl 15;

        rgb := rgb or alpha_w;

      end;//end of support of transparent 1555

      f.Write(rgb, 2);

    end;{width}
  end;{height}

end;{End of Writemat16data}



 ////////////////////////////////////////////////
 //  Bmp32toMat32Fs

///////////////////////////////////////////////
procedure Writemat32data(bmap: TBitmap; f: TStream);
var

  i, j, DestRed, DestGreen, DestBlue, DestAlpha, GreenError, BlueError, RedError: integer;
  SrcRed, SrcGreen, SrcBlue, SrcAlpha: byte;
   alpha_W: word;
   rgb:cardinal;
  // alpha:byte;
  //  x: integer;
  //  y: integer;
  inrow: pRGBQuadArray;
  // samp:Tbitmap;
  //  tolerance,red,green,blue:integer;
begin
  // dither:=0;
  //  totalerror:=0;
  bmap.PixelFormat := pf32bit;

  // GBlur(bmap, 7);

  for j := 0 to Bmap.Height - 1 do

  begin




    inrow := bmap.ScanLine[j];
    //read one source row
    for i := 0 to Bmap.Width - 1 do
    begin

      //Get RGB source components
      SrcRed   := inrow[i].rgbRed;
      SrcGreen := inrow[i].rgbGreen;
      SrcBlue  := inrow[i].rgbBlue;
      SrcAlpha  := inrow[i].rgbReserved;



     // no need to downconvert or shift bits for 32 bit to 32 bit!
        DestRed   := SrcRed;
        DestGreen := SrcGreen;
        DestBlue  := SrcBlue;
        DestAlpha := SrcAlpha;

      //Compose the destination pixel
      rgb := (DestRed) shl 16 or
           (DestGreen) shl 8 or
            (DestBlue) shl 0 or
           (DestAlpha) shl 24;

      f.Write(rgb, 4);     //size bytes

    end;{width}
  end;{height}

end;{End of Writemat16data}




procedure ReadCMPfromGOB(gobfile: string; cmp: string);
var
  j:      integer;
  ge:     TGob2Entry;
  gh:     TGOB2Header;
  cmppal: TCMPPal;
  cmpheader: TCMPHeader;
begin
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
      if extractfilename(ge.Name) = cmp then
      begin
        Seek(f, 0);
        Seek(f, ge.pos);
        BlockRead(f, cmpheader, SizeOf(cmpheader));

        if cmpheader.sig <> 'CMP ' then
          raise Exception.Create('Not a valid CMP file!');

        BlockRead(f, cmppal, SizeOf(cmppal));
        BlockRead(f, LightTable, SizeOf(LightTable));
        defCmppal := cmppal;
      end;
    end;



  finally
    CloseFile(f);
  end;
end;



function ReadMatfromGOB(gobfile: string; matname: string): Tbitmap;
var
  hdr:   TMatHeader;
  thdr:  TTextureHeader;
  tdata: TTextureData;
  // cmph: TCMPHeader;
  j,i:     integer;
  ge:    TGob2Entry;
  gh:    TGOB2Header;
  chdr:  Tcolorheader;
  tempbitmap: Tbitmap;
  FoundIt : boolean;
begin
 //Result := Tbitmap.Create;
 // tempbitmap := Tbitmap.Create;
  AssignFile(f, gobfile);
   foundIt:=false;
    Reset(f, 1);

    BlockRead(f, gh, SizeOf(gh));


    if gh.magic <> 'GOB ' then
      raise Exception.Create(gobfile + ' is not a GOB 2.0 file');

    for j := 0 to gh.NEntries - 1  do
    begin
       BlockRead(f, ge, SizeOf(ge));
                             //find the mat
      if ge.Name = matname then break;
    end;



     Seek(f, 0);
     Seek(f, ge.pos);
     BlockRead(f, hdr, SizeOf(hdr));

     if hdr.tag <> 'MAT ' then
     raise Exception.Create('Not a valid MAT file!');

    //This is a flat color texture
    if hdr.mat_Type = 0 then
        begin
        //colorbitmap := Tbitmap.Create;
        Result := Tbitmap.Create;
        result.Height := 64;
        result.Width  := 64;
        SetPal(defCMPPal);
         BlockRead(f, chdr, SizeOf(chdr));
        //if not Result.Empty then
        //  Result := nil;
        result.Canvas.Brush.Color :=
        (2 shl 24) + rgb(defCmppal[chdr.transparent_color].r, defCmppal[chdr.transparent_color].g,
        defcmppal[chdr.transparent_color].b);
        result.Canvas.FillRect(Rect(0, 0, 64, 64));
        //result:=colorbitmap;
        end;

    //This is a bitmap texture.  (mat_type = 2)
    if hdr.mat_Type <> 0 then
        begin
               // goto the start of the texture data
                Seek(f, sizeof(hdr) + hdr.record_count * sizeof(thdr) + ge.pos);

               //read in the texture data
               BlockRead(f, tdata, SizeOf(tdata));

              transp := False;

             if tdata.Transparent = 1 then
                    transp := True;

             if hdr.bits = 16 then
                 begin
                 result := Mat16ToBmp(tdata.SizeX, tdata.SizeY, False, False);
                 end;

             if hdr.bits <> 16 then
                 begin
                 SetPal(defCMPPal);
                result:=Mat8ToBmp(tdata.SizeX, tdata.SizeY);
                 end;

    CloseFile(f);


  end;



 end;

 function ReadMat(filename: string): Tbitmap;
var
  hdr:   TMatHeader;
  thdr:  TTextureHeader;
  tdata: TTextureData;
  // cmph: TCMPHeader;
  j,i:     integer;
  ge:    TGob2Entry;
  gh:    TGOB2Header;
  chdr:  Tcolorheader;
  tempbitmap: Tbitmap;
  FoundIt : boolean;
 // datalist : tstringlist;
begin
 //Result := Tbitmap.Create;
 // tempbitmap := Tbitmap.Create;
 // datalist := TStringList.Create;

  AssignFile(f, filename);
   foundIt:=false;
    Reset(f, 1);

     BlockRead(f, hdr, SizeOf(hdr));

     if hdr.tag <> 'MAT ' then
     raise Exception.Create('Not a valid MAT file!');

    //This is a flat color texture
    if hdr.mat_Type = 0 then
        begin
        //colorbitmap := Tbitmap.Create;
        Result := Tbitmap.Create;
        result.Height := 64;
        result.Width  := 64;
        SetPal(defCMPPal);
         BlockRead(f, chdr, SizeOf(chdr));
        //if not Result.Empty then
        //  Result := nil;
        result.Canvas.Brush.Color :=
        (2 shl 24) + rgb(defCmppal[chdr.transparent_color].r, defCmppal[chdr.transparent_color].g,
        defcmppal[chdr.transparent_color].b);
        result.Canvas.FillRect(Rect(0, 0, 64, 64));
        //result:=colorbitmap;
        end;

    //This is a bitmap texture.  (mat_type = 2)
    if hdr.mat_Type <> 0 then
        begin
               // goto the start of the texture data
                Seek(f, sizeof(hdr) + hdr.record_count * sizeof(thdr));

               //read in the texture data
               BlockRead(f, tdata, SizeOf(tdata));

              transp := False;

             if tdata.Transparent = 1 then
             begin
                    transp := True;
                   // datalist.Add(filename);
                  //  ShowMessage(filename);
             end;
             if hdr.bits = 16 then
                 begin
                 result := Mat16ToBmp(tdata.SizeX, tdata.SizeY, False, False);
                 end;

             if hdr.bits <> 16 then
                 begin
                 SetPal(defCMPPal);
                result:=Mat8ToBmp(tdata.SizeX, tdata.SizeY);
                 end;

    CloseFile(f);


  end;



 end;



function GetbestCMP(matname: string; gobname: string): string;
var
  cmp: string;
begin
  //get the first 2 charaters of the name of the mat for cmp use

  cmp    := Copy(ExtractFileName(matname), 0, 2);
  Result := 'dflt.cmp';

  if UpperCase(ExtractFileExt(gobname)) = '.GOB' then
  begin
    if cmp = '01' then
      Result := '01narsh.cmp';
    if cmp = '03' then
      Result := '03house.cmp';
    if cmp = '04' then
      Result := '04farm.cmp';
    if cmp = '06' then
      Result := '06baron.cmp';
    if cmp = '07' then
      Result := '01narsh.cmp';
    if cmp = '08' then
      Result := '06baron.cmp';
    if cmp = '09' then
      Result := '09fuel.cmp';
    if cmp = '10' then
      Result := '10cargo.cmp';
    if cmp = '12' then
      Result := '12escape.cmp';
    if cmp = '13' then
      Result := '12escape.cmp';
    if cmp = '14' then
      Result := '15maw.cmp';
    if cmp = '15' then
      Result := '15maw.cmp';
    if cmp = '16' then
      Result := '16fall.cmp';
    if cmp = '18' then
      Result := '15maw.cmp';
    if cmp = '19' then
      Result := '19descent.cmp';
    if cmp = '20' then
      Result := '20val.cmp';
    if cmp = '21' then
      Result := '20val.cmp';
    if cmp = '22' then
      Result := '06baron.cmp';
    if cmp = '41' then
      Result := '41escort.cmp';
    if cmp = '42' then
      Result := '10cargo.cmp';
    if cmp = '43' then
      Result := '09fuel.cmp';
    if cmp = '52' then
      Result := '01narsh.cmp';
    if cmp = '53' then
      Result := '54sith.cmp';
    if cmp = '54' then
      Result := '54sith.cmp';
    if cmp = 'm4' then
      Result := 'm4escape.cmp';
  end;


  if UpperCase(ExtractFileExt(gobname)) = '.GOO' then
  begin
    if cmp = '01' then
      Result := '01narsh.cmp';
    if cmp = '03' then
      Result := '03house.cmp';
    if cmp = '04' then
      Result := '04farm.cmp';
    if cmp = '05' then
      Result := '41escort.cmp';
    if cmp = '06' then
      Result := '06baron.cmp';
    if cmp = '07' then
      Result := '01narsh.cmp';
    if cmp = '08' then
      Result := '06baron.cmp';
    if cmp = '09' then
      Result := '09fuel.cmp';
    if cmp = '10' then
      Result := '10cargo.cmp';
    if cmp = '12' then
      Result := '12escape.cmp';
    if cmp = '13' then
      Result := '41escort.cmp';
    if cmp = '14' then
      Result := '54sith.cmp';
    if cmp = '15' then
      Result := '06baron.cmp';
    if cmp = '16' then
      Result := '41escort.cmp';
    if cmp = '18' then
      Result := '15maw.cmp';
    if cmp = '19' then
      Result := '19descent.cmp';
    if cmp = '20' then
      Result := '41escort.cmp';
    if cmp = '21' then
      Result := '06baron.cmp';
    if cmp = '22' then
      Result := '06baron.cmp';
    if cmp = '24' then
      Result := '06baron.cmp';
    if cmp = '41' then
      Result := '01narsh.cmp';
    if cmp = '42' then
      Result := '10cargo.cmp';
    if cmp = '43' then
      Result := '09fuel.cmp';
    if cmp = '52' then
      Result := '01narsh.cmp';
    if cmp = '53' then
      Result := '54sith.cmp';
    if cmp = '54' then
      Result := '54sith.cmp';
    if cmp = '61' then
      Result := 'm4escape.cmp';
    if cmp = 'm4' then
      Result := 'm4escape.cmp';
    if cmp = 'md' then
      Result := '01narsh.cmp';
  end;
end;

function LoadAlphamap(SRC: TBitmap; Abmap: TBitmap): Tbitmap;
var
  i, j: integer;
  SrcRow, AbmapRow, DstRow: pRGBTripleArray;
  red, green, blue: byte;
begin

  if (src.Height <> Abmap.Height) or (src.Width <> Abmap.Width) then
  begin
    ShowMessage('Bitmaps must be the same size');
    exit;
  end;

  //bmap.pixelFormat := pf24bit;
  Result := Tbitmap.Create;
  Result.PixelFormat := pf24bit;
  Result.Width := src.Width;
  Result.Height := src.Height;




  for j := 0 to src.Height - 1 do
  begin
    DstRow   := Result.Scanline[j];
    SrcRow   := src.Scanline[j];
    AbmapRow := Abmap.Scanline[j];
    for i := 0 to src.Width - 1 do
    begin

      DstRow[i].rgbtBlue  := SrcRow[i].rgbtBlue;
      DstRow[i].rgbtGreen := SrcRow[i].rgbtGreen;
      DstRow[i].rgbtRed   := SrcRow[i].rgbtRed;


      if ((AbmapRow[i].rgbtRed = 0) and (AbmapRow[i].rgbtGreen = 0) and
        (AbmapRow[i].rgbtBlue = 0)) then
      begin
        DstRow[i].rgbtBlue  := 0;
        DstRow[i].rgbtGreen := 0;
        DstRow[i].rgbtRed   := 0;
      end;

    end;
  end;

end;

function SaveAlphamap(bmap: TBitmap): Tbitmap;
var

  i, j: integer;
  //  Ms:TMemoryStream;
  // Row: pWordArray;   // from SysUtils
  // RGB:WORD;
  // x: integer;
  // y: integer;
  //Bitmap15: TBitmap;
  //Row15: pWordArray;
  Row24, Row15: pRGBTripleArray;
  //matdebug:word;
  red, green, blue: byte;
begin
  //rgb:=0;
  bmap.pixelFormat := pf24bit;
  Result := Tbitmap.Create;
  Result.PixelFormat := pf24bit;
  Result.Width := bmap.Width;
  Result.Height := bmap.Height;


  for j := 0 to Bmap.Height - 1 do
  begin
    Row15 := Result.Scanline[j];
    Row24 := Bmap.Scanline[j];
    for i := 0 to Bmap.Width - 1 do
    begin

      //get the transparent info from the options dialog
      //  red:=(strtoint(optionsform.Edit1.Text)) + tolerance;
      //  green:=(strtoint(optionsform.Edit2.Text)) + tolerance;
      //  blue:=(strtoint(optionsform.Edit3.Text)) + tolerance;


      //  red:=0;
      //   green:=0;
      //   blue:=0;

      row15[i].rgbtBlue  := 255;
      row15[i].rgbtGreen := 255;
      row15[i].rgbtRed   := 255;

      if ((Row24[i].rgbtRed = 0) and (Row24[i].rgbtGreen = 0) and
        (Row24[i].rgbtBlue = 0)) then
      begin
        row15[i].rgbtBlue  := 0;
        row15[i].rgbtGreen := 0;
        row15[i].rgbtRed   := 0;
      end;

    end;
  end;

end;


procedure savemcf(filename: string);
var
  OutFile: textfile;
  // i: integer;
begin
  AssignFile(OutFile, filename);
  Rewrite(OutFile);

  WriteLn(OutFile, 'MAT16 Control File');
  WriteLn(OutFile, 'Trans 1');

  CloseFile(OutFile);
end;

end.

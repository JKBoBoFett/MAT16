unit BMP_IO;
// hack to support more bitmap types then the VCL does

// pf15bit: when created pixelformat is set to BI_RGB, but internally it's really  BI_BITFIELDS
//          this causes pixelformat to return pfCustom because the format is incorrect
interface

uses Windows, SysUtils, Graphics, Classes, Dialogs, Controls,math,util,pngimage;

type
TBMPFormat = (bf8bit, bf16bitX1555, bf16bitA1555, bf16bitX444,bf16bitA444, bf16bit565, bf24bit, bf32bit, bfCustom);

type
  Image = record
    sizeX: longint;
    sizeY: longint;
    Data:  PChar;
  end {Image};

type
  TBMPHeader = packed record
    tag:      word;         {'BM'}
    filesize: longword;     {usually 0 for uncompressed images}
    Reserved1: word;        {0}
    Reserved2: word;        {0}
    BitmapOffset: longword; {offset to start of image data}
  end;

type
  TBMPInfo = packed record
    Size:   longword;  //size of info header ddetermines version
    Width:  longint;
    Height: longint;
    Planes: word;
    BitsPerPixel: word;
    Compression: longword; //Compression 3 = BI_BITFIELDS,for 565+4444, 0 = BI_RGB for 1555   //"compresion"
    SizeOfBitmap: longword;  // note : the size info in PhotoShop BMP's is wrong
    HorzResolution: longint;
    VertResolution: longint;
    ColorsUsed: longword;   // =0;
    ColorsImportant: longword; //=0;
  end;

type
  TBMPFieldMask = packed record
    //The 3 masks used in 16 bit files set which way the 16 bits
    //are split between the 3 colour channels. The 2 main formats you
    //will find are 565 (R=0xF8000000 G=0x07E00000 B=0x001F0000) and
    // 444 (R=0xF0000000 G=0x0F000000 B=0x00F00000). The NT 3.0 format
    // only allows for 3 channels so the Extended Bitmap is assuming that
    // the spare 4 bits with 444 are a transparency channel. 32 bit files
    // use the Masks in the same way to define the split between colour
    // channels.

    // 565 format:
    // 63488 = F800 = 1111100000000000
    // 2016  = 7E0  = 11111100000
    // 31    = 1F   = 11111

    // 4444 format:
    // 3840  = F00 =   111100000000
    // 240   = F0  =   11110000
    // 15    = F   =   1111

    // 1555 format:
    //  808932166

    RedMask:   longword;         // v1 WITH BI_BITFIELDS
    GreenMask: longword;
    BlueMask:  longword;
  end;

type
 TBMPInfoV2ext = packed record    //size 52: V2 Undocumented extended info header
    RedMask:   longword;
    GreenMask: longword;
    BlueMask:  longword;
  end;

type
  TBMPInfoV3ext = packed record    //size 56: V3 Not officially documented, Adobe extended info header
    RedMask:   longword;
    GreenMask: longword;
    BlueMask:  longword;
    AlphaMask:  longword;
  end;

type
  TBMPInfoV4ext = packed record    //size 108: V4 extended info header
    RedMask: longword;
    GreenMask: longword;
    BlueMask: longword;
    AlphaMask: longword;
    CSType: longword;
    Endpoints: TCIEXYZTriple;
    GammaRed: longword;
    GammaGreen: longword;
    GammaBlue: longword;
  end;

type
  TBMPInfoV5ext = packed record    //size 124: V5 Gimp extended info header
    RedMask: longword;
    GreenMask: longword;
    BlueMask: longword;
    AlphaMask: longword;
    CSType: longword;
    Endpoints: TCIEXYZTriple;
    GammaRed: longword;
    GammaGreen: longword;
    GammaBlue: longword;
    Intent: longword;
    ProfileData: longword;
    ProfileSize: longword;
    Reserved: longword;
  end;

function BMP_Open(filename: string): TBitmap;
procedure Save16bit565(ABitmap: TBitmap; const AFileName: string);
function GetBMPFormat(ABitmap: TBitmap):TBMPFORMAT;
function Conv24bitTo16(ABitmap:tbitmap;RedBitDiff,GreenBitDiff,BlueBitDiff:integer):Tbitmap;
function DitherTo16(ABitmap:tbitmap):Tbitmap;
procedure Save32bitA(ABitmap: TBitmap;Alpha:boolean; const AFileName: string);
procedure Save16bitA1555BMP(ABitmap: TBitmap; const AFileName: string);
function GetPaddedRowSize(bpp,width:integer):integer;
procedure BMP_Save(Abitmap:Tbitmap; filename: string);
var
inputBMPFormat:TBMPFORMAT;

implementation

function BMP_Open(filename: string): Tbitmap;
const
  PixelCountMax = 65536;  // 2048 MAX WIDTH
type
  TRGBQuadArray = packed array[0..PixelCountMax - 1] of TRGBQuad;
  pRGBQuadArray = ^TRGBQuadArray;
var
  f:      file;
  size,checksize,rowsize, i,j: integer;
  rin_bitmap: Tbitmap;
  bmhead: TBMPHeader;
  bminfo: TBMPInfo;
  bmfmask: TBMPFieldMask;
  formatgood: boolean;
  HasPalette: boolean;
  sizeError:boolean;
  hasAlpha: boolean;
  BFH: TBitmapFileHeader;
  bmInfoVer:integer;
  BMPInfoV2ext:TBMPInfoV2ext;
  BMPInfoV3ext:TBMPInfoV3ext;
  BMPInfoV4ext:TBMPInfoV4ext;
  BMPInfoV5ext:TBMPInfoV5ext;
  BMPFormat:TBMPFORMAT;
  inrow: pRGBQuadArray;
  src:   word;
  src32:Cardinal;
  PNG: TPngImage;
  RowAlpha: PByteArray;
  BMPInRow: pRGBQuadArray;
begin
  HasPalette:=false;
  sizeError:=true;
  hasAlpha:=false;
  formatgood := False;
  bmInfoVer := 0;
  rin_bitmap := Tbitmap.Create;
  result:=  Tbitmap.Create;

  AssignFile(f, filename);
  Reset(f, 1);

  // Read Bitmap Header
  BlockRead(f, bmhead, SizeOf(bmhead));
  BlockRead(f, bminfo, SizeOf(bminfo)); //(size) 40=BITMAPINFOHEADER //56=BITMAPV3INFOHEADER(adobe)   //124=BITMAPV5HEADER(gimp)

  if not IsBMPPowerOfTwo(bminfo.Width,bminfo.Width) then
         raise Exception.Create('Bitmap size is not a power of 2!');

  checksize:= bmhead.BitmapOffset -  SizeOf(bmhead);
  if (checksize > 200) and (bminfo.ColorsUsed >= 256) then
        HasPalette:=true;


  if bminfo.Size = 40 then
    bmInfoVer := 1;
  if bminfo.Size = 52 then
    bmInfoVer := 2;
  if bminfo.Size = 56 then
    bmInfoVer := 3;
  if bminfo.Size = 108 then
    bmInfoVer := 4;
  if bminfo.Size = 124 then
    bmInfoVer := 5;

  if bmInfoVer = 0 then
         raise Exception.Create('Unsupported BITMAPINFOHEADER');
   if (bmInfoVer = 1)  and (bminfo.Compression = BI_BITFIELDS) then
    BlockRead(f, bmfmask, SizeOf(bmfmask));
   if bmInfoVer = 2 then
    BlockRead(f, BMPInfoV2ext, SizeOf(BMPInfoV2ext));
   if bmInfoVer = 3 then
    BlockRead(f, BMPInfoV3ext, SizeOf(BMPInfoV3ext));
   if bmInfoVer = 4 then
    BlockRead(f, BMPInfoV4ext, SizeOf(BMPInfoV4ext));
   if bmInfoVer = 5 then
    BlockRead(f, BMPInfoV5ext, SizeOf(BMPInfoV5ext));

  if bmInfoVer = 2 then
        begin
        bmfmask.GreenMask:= BMPInfoV2ext.GreenMask;
        end;

   if bmInfoVer = 3 then
        begin
        bmfmask.GreenMask:= BMPInfoV3ext.GreenMask;
        if BMPInfoV3ext.AlphaMask <> 0 then hasAlpha:=true;
        end;

   if bmInfoVer = 4 then
        begin
        bmfmask.GreenMask:= BMPInfoV4ext.GreenMask;
        if BMPInfoV4ext.AlphaMask <> 0 then hasAlpha:=true;
        end;

   if bmInfoVer = 5 then
        begin
        bmfmask.GreenMask:= BMPInfoV5ext.GreenMask;
        if BMPInfoV5ext.AlphaMask <> 0 then hasAlpha:=true;
        end;


  //use Delphi VCL code to load 8-bit
  if (bminfo.BitsPerPixel = 8) then
  begin
    CloseFile(f);
    formatgood := True;
    Result.LoadFromFile(filename);
    inputBMPFormat:=bf8bit;
  end;


  // start of 16-bit support
  if (bminfo.BitsPerPixel = 16) then
  begin

   seek(f, bmhead.BitmapOffset); //warp to bitmap data

    if (bminfo.Compression = BI_BITFIELDS) then  // 565+4444 have a fieldmask header
    begin
      if (bmfmask.GreenMask = 2016) then  // 16-bit 565 format
      begin
        rin_bitmap.PixelFormat := pf16bit;  //allways define pf first
        rin_bitmap.Width := bminfo.Width;
        rin_bitmap.Height := bminfo.Height;
        formatgood := True;
        inputBMPFormat:=bf16bit565;
      end;

      if (bmfmask.GreenMask = 240) then  // 16-bit 4444 format
      begin
        rin_bitmap.PixelFormat := pf32bit;  //VCL doesn't support display of 4444 so we'll convert to 32bit
        rin_bitmap.SetSize(bminfo.Width,bminfo.Height);
        formatgood := true;
        if hasAlpha then inputBMPFormat:=bf16bitA444  //can read alpha format in header since we are loading an externally created bitmap
        else inputBMPFormat:=bf16bitX444;
      end;
    end;

    if (bminfo.Compression = BI_RGB) or (bmfmask.GreenMask = 992) then  //BI_RGB 1555 doesn't have a fieldmask header
    begin
      rin_bitmap.PixelFormat := pf15bit;  //allways define pf first
      rin_bitmap.Width := bminfo.Width;
      rin_bitmap.Height := bminfo.Height;
      formatgood := True;
      inputBMPFormat:=bf16bitA1555;
    end;

    if formatgood then
    begin
      //read in bitmap
     if rin_bitmap.PixelFormat <> pf32bit then
     begin
      for i := bminfo.Height - 1 downto 0 do
        BlockRead(f, rin_bitmap.Scanline[i]^, bminfo.Width * 2);
     end;

     if (rin_bitmap.PixelFormat = pf32bit) and (bmfmask.GreenMask = 240) then
     begin

       rin_bitmap.AlphaFormat:=afdefined;
       for j := rin_bitmap.Height - 1 downto 0 do
          begin
            inrow := rin_bitmap.ScanLine[j];
            for i := 0 to rin_bitmap.Width - 1 do
            begin
              BlockRead(f, src, sizeof(src));
              inrow[i].rgbReserved :=  ((src and $F000) shr 12) * 17;
              inrow[i].rgbRed :=       ((src and $F00)  shr 8) * 17;
              inrow[i].rgbGreen :=     ((src and $F0)   shr 4) * 17;
              inrow[i].rgbBlue :=      ((src and $F)    shr 0) * 17;
            end;

        end;

     end;

      Result.Assign(rin_bitmap);
      CloseFile(f);
    end;

     if not formatgood then
       showmessage('bitmap format not supported');

  end;  // end of 16-bit support

  if (bminfo.BitsPerPixel = 24) then
  begin
    seek(f, bmhead.BitmapOffset); //warp to bitmap data

    rin_bitmap.PixelFormat := pf24bit;  //allways define pf first
    rin_bitmap.Width := bminfo.Width;
    rin_bitmap.Height := bminfo.Height;
    formatgood := True; //FIX ME

    //read in bitmap
    for i := bminfo.Height - 1 downto 0 do
      BlockRead(f, rin_bitmap.Scanline[i]^, bminfo.Width * 3);

    Result := rin_bitmap;
    CloseFile(f);
  end; // end of 24-bit


  if (bminfo.BitsPerPixel = 32) then
  begin
   // PS saves ARGB as type 1  BI_RGB and XRGB as type 3 BI_BITFIELDS, why? seems it should be opposite

  //  size := bminfo.Width * bminfo.Height * 4;


   rowsize:= GetPaddedRowSize(32,bminfo.Width);
   size := rowsize * bminfo.Height;

    if size <> bminfo.SizeOfBitmap then
      sizeError:=true;

    seek(f, bmhead.BitmapOffset); //warp to bitmap data

    rin_bitmap.PixelFormat := pf32bit;  //allways define pf first
    rin_bitmap.Width := bminfo.Width;
    rin_bitmap.Height := bminfo.Height;
    formatgood := True; //FIX ME

    //read in bitmap
    if (bminfo.Compression = BI_RGB) or (bmfmask.GreenMask = $0000FF00) then
     begin
     hasAlpha:=true;
     //rin_bitmap.AlphaFormat:=afDefined;

      for i := bminfo.Height - 1 downto 0 do
      BlockRead(f, rin_bitmap.Scanline[i]^, rowsize);
     end;

  //photoshop XRGB
    if (rin_bitmap.PixelFormat = pf32bit) and (bmfmask.GreenMask = $00FF0000) then
     begin

       rin_bitmap.AlphaFormat:=afIgnored;
       for j := rin_bitmap.Height - 1 downto 0 do
          begin
            inrow := rin_bitmap.ScanLine[j];
            for i := 0 to rin_bitmap.Width - 1 do
            begin
              BlockRead(f, src32, sizeof(src32));
              inrow^[i].rgbReserved :=  0;
              inrow^[i].rgbRed :=       (src32 and $FF000000) shr 24;
              inrow^[i].rgbGreen :=     (src32 and $00FF0000) shr 16;
              inrow^[i].rgbBlue :=      (src32 and $0000FF00) shr 8;
            end;

        end;

     end;



    png := TPngImage.Create();


    Result.Assign(rin_bitmap);
    CloseFile(f);

    png.Assign(rin_bitmap);
    png.CreateAlpha;

    for J:=0 to rin_bitmap.Height - 1 do
      begin
      BMPInRow := rin_bitmap.ScanLine[J];
      RowAlpha := png.AlphaScanline[J];
        for i:=0 to rin_bitmap.Width - 1 do
          RowAlpha[i] := BMPInRow[i].rgbReserved;




      end;


    png.SaveToFile('D:\TestBMP\Test32Save.png');
   // Save32bitA(Result,hasAlpha,'D:\TestBMP\Test32Save.bmp');
   //Result.SaveToFile('D:\TestBMP\Test32Save.bmp');
  end; // end of 32-bit


  //result.SaveToFile('c:\test.bmp');
  if not formatgood then
  begin
    CloseFile(f);
    //result.SaveToFile('c:\test.bmp');
   // Result := nil;
    showmessage('bitmap format not supported');
  end;


  rin_bitmap.Free;
  rin_bitmap:=nil;
end;

//Floyd–Steinberg dithering
function DitherTo16(ABitmap:tbitmap):Tbitmap;
type
  TRGBTripleArray = array[0..32767] of TRGBTriple;
  PRGBTripleArray = ^TRGBTripleArray;
var
y,x:integer;
SL,SL2:PRGBTripleArray;
r,g,b,nr,ng,nb :integer;
r16,b16,g16:word;
color:integer;
GreenError, BlueError, RedError:integer;
row16:PWordArray;
begin
Result:=tbitmap.create;
Result.PixelFormat:=pf16bit;
Result.SetSize(Abitmap.width,Abitmap.height);

  for y := ABitmap.Height - 1 downto 0 do
          begin
           SL := ABitmap.ScanLine[y];
           row16 := Result.ScanLine[y];
           if y > 0 then SL2 :=ABitmap.ScanLine[y-1];
            for x := 0 to ABitmap.Width - 1 do
            begin
              //get original pixel
              r:=SL^[x].rgbtRed;
              g:=SL^[x].rgbtGreen;
              b:=SL^[x].rgbtBlue;

              //get nearest 16bit color then convert back to 24-bit
              nr:= min(255,r shr 3 shl 3);
              ng:= min(255,g shr 2 shl 2);
              nb:= min(255,b shr 3 shl 3);

              //assign new color
//              SL^[x].rgbtRed:=nr;
//              SL^[x].rgbtGreen:=ng;
//              SL^[x].rgbtBlue:=nb;

              //save 16-bit pixel to result
              r16:= nr shr 3;
              g16:= ng shr 2;
              b16:= nb shr 3;
              row16^[x]:=R16 shl 11 or G16 shl 5 or B16 shl 0;

              //get error
              RedError := r - nr;
              GreenError := g - ng;
              BlueError := b - nb;

              //spread the error to neighboring pixels
              //X+1 Y
              if x < ABitmap.Width - 2 then
              begin
                SL^[x+1].rgbtRed:= min(255,SL^[x+1].rgbtRed + (round(RedError *(7 / 16))));
                SL^[x+1].rgbtGreen:=min(255,SL^[x+1].rgbtGreen + (round(GreenError *(7 / 16))));
                SL^[x+1].rgbtBlue:=min(255,SL^[x+1].rgbtBlue + (round(BlueError *(7 / 16))));
              end;
              //X-1 Y+1
              if (x > 0) and (y > 0) then
              begin
                SL2^[x-1].rgbtRed:=min(255,SL2^[x-1].rgbtRed + (round(RedError *(3 / 16))));
                SL2^[x-1].rgbtGreen:=min(255,SL2^[x-1].rgbtGreen + (round(GreenError *(3 / 16))));
                SL2^[x-1].rgbtBlue:=min(255,SL2^[x-1].rgbtBlue + (round(BlueError *(3 / 16))));
              end;
               //X Y+1
              if y > 0 then
              begin
                SL2^[x].rgbtRed:=min(255,SL2^[x].rgbtRed + (round(RedError *(5 / 16))));
                SL2^[x].rgbtGreen:=min(255,SL2^[x].rgbtGreen + (round(GreenError *(5 / 16))));
                SL2^[x].rgbtBlue:=min(255,SL2^[x].rgbtBlue + (round(BlueError *(5 / 16))));
              end;
               //X+1 Y+1
              if (x < ABitmap.Width - 2) and (y > 0) then
              begin
                SL2^[x+1].rgbtRed:=min(255,SL2^[x+1].rgbtRed + (round(RedError *(1 / 16))));
                SL2^[x+1].rgbtGreen:=min(255,SL2^[x+1].rgbtGreen + (round(GreenError *(1 / 16))));
                SL2^[x+1].rgbtBlue:=min(255,SL2^[x+1].rgbtBlue + (round(BlueError *(1 / 16))));
              end;
            end;

        end;


   // Result.Assign(Abitmap);
    result.SaveToFile('D:\TestBMP\ddither.bmp');
end;

function Conv24bitTo16(ABitmap:tbitmap;RedBitDiff,GreenBitDiff,BlueBitDiff:integer):Tbitmap;
type
  TRGBTripleArray = array[0..32767] of TRGBTriple;
  PRGBTripleArray = ^TRGBTripleArray;

  PWordArray = ^TWordArray;
  TWordArray = packed array[0..16383] of Word;
var
i,j,GreenError, BlueError, RedError:integer;
inrow: PRGBTripleArray;
pixel16,R,G,B:word;
newbmp:tbitmap;
row16:PWordArray;
begin
newbmp:=tbitmap.create;
newbmp.PixelFormat:=pf16bit;
newbmp.SetSize(ABitmap.width,Abitmap.Height);

  for j := ABitmap.Height - 1 downto 0 do
          begin
            RedError:= 0; GreenError:= 0; BlueError:= 0;
            inrow := ABitmap.ScanLine[j];
            row16 := newbmp.ScanLine[j];
            for i := 0 to ABitmap.Width - 1 do
            begin
             R:= inrow^[i].rgbtRed shr RedBitDiff;// and
             G:= inrow^[i].rgbtGreen shr GreenBitDiff;
             B:= inrow^[i].rgbtBlue shr BlueBitDiff;

         //    RedError:= inrow^[i].rgbtRed shr 3 shl 3;


             //Calculate the error
              RedError   := inrow^[i].rgbtRed -   (R shl RedBitDiff);
              GreenError := inrow^[i].rgbtGreen - (G shl GreenBitDiff);
              BlueError  := inrow^[i].rgbtBlue -  (B shl BlueBitDiff);

              // add the error while clamping to the max color value
              inrow^[i].rgbtRed:= min(255, inrow^[i].rgbtRed + (RedError));
              inrow^[i].rgbtGreen:= min(255, inrow^[i].rgbtGreen + (GreenError));
              inrow^[i].rgbtBlue:= min(255, inrow^[i].rgbtBlue + (BlueError));

             R:= inrow^[i].rgbtRed shr RedBitDiff;// and
             G:= inrow^[i].rgbtGreen shr GreenBitDiff;
             B:= inrow^[i].rgbtBlue shr BlueBitDiff;

             row16^[i]:=R shl 11 or G shl 5 or B shl 0;

            end;

        end;
   Result:=tbitmap.create;
   result.Assign(newbmp);
   newbmp.free;
end;


function GetBMPFormat(ABitmap: TBitmap):TBMPFORMAT;
var
MS: TMemoryStream;
BFH: TBMPHeader;
BIH: TBMPInfo;
BIHEX:TBMPInfoV5ext;
row16:PWordArray;
i,j:integer;
R,G,B,A:Integer;
hasAlpha:Boolean;
begin
   hasAlpha:=false;
  MS := TMemoryStream.Create;

  ABitmap.SaveToStream(MS);
   MS.Position:= 0;
   MS.Read(BFH,SizeOf(BFH));
   MS.Read(BIH,SizeOf(BIH));
   MS.Read(BIHEX,SizeOf(BIHEX));

   case BIH.BitsPerPixel of
     16:
       begin
         case BIH.Compression of
           BI_BITFIELDS:
             begin
              case BIHEX.GreenMask of
                $F0: Result:= bf16bitX444;
                $7E0: Result:=bf16bit565;
                $3E0:
                 begin
                  Result:=bf16bitX1555;
                  if BIHEX.AlphaMask = $8000 then  Result:=bf16bitA1555;
                 end;
              end;
             end;
         end;
       end;
     32:
      begin
      Result:=bf32bit;
      end;
     8:
      begin
      Result:=bf8bit;
      end;
   end;

 //check for Alpha since VCL doesn't support Alpha field masks in dib header, but the data is still there
  if (BIH.BitsPerPixel = 16) and (BIHEX.GreenMask = $F0) then
    begin
       for i := 0 to ABitmap.Height - 1 do
          begin
            Row16 := ABitmap.ScanLine[i];
            for j := 0 to ABitmap.Width - 1 do
              begin
               A:= ((Row16[j] and $F000) shr 12);
               if A <> 0 then hasAlpha:=true;
              end;
          end;

      if hasAlpha then Result:=bf16bitA444;

    end;

 //check for Alpha since VCL doesn't support Alpha field masks in dib header, but the data is still there
  if (BIH.BitsPerPixel = 16) and (BIHEX.GreenMask = $3E0) then
    begin
       for i := 0 to ABitmap.Height - 1 do
          begin
            Row16 := ABitmap.ScanLine[i];
            for j := 0 to ABitmap.Width - 1 do
              begin
               A:= ((Row16[j] and 32768) shr 15);
               if A = 1 then hasAlpha:=true;
              end;
          end;

      if hasAlpha then Result:=bf16bitA1555;

    end;


 MS.Free;
end;


procedure Save16bitA1555BMP(ABitmap: TBitmap; const AFileName: string);
var
FS: TFileStream;
BFH: TBMPHeader;
BIH: TBMPInfo;
BIHEX:TBMPInfoV4ext;
data: array of word;
y:integer;
sl: PWordArray;
begin
 FS := TFileStream.Create(AFileName, fmCreate);
 try

    FillChar(BFH, SizeOf(BFH), 0);
    BFH.tag := $4D42;  // BM
    BFH.filesize := 2 * ABitmap.Width * ABitmap.Height + SizeOf(BFH) + SizeOf(BIH)+ SizeOf(BIHEX);
    BFH.BitmapOffset := SizeOf(BFH) + SizeOf(BIH) + SizeOf(BIHEX);
    FS.Write(BFH, SizeOf(BFH));

    // Bitmap info header
    FillChar(BIH, SizeOf(BIH), 0);
    BIH.Size := SizeOf(BIH)+SizeOf(BIHEX);
    BIH.Width := ABitmap.Width;
    BIH.Height := ABitmap.Height;
    BIH.Planes := 1;
    BIH.BitsPerPixel := 16;
    BIH.Compression := BI_BITFIELDS;
    BIH.SizeOfBitmap := 2 * (ABitmap.Width * ABitmap.Height);
    FS.Write(BIH, SizeOf(BIH));
     FillChar(BIHEX, SizeOf(BIHEX), 0);
     BIHEX.RedMask :=  $7C00;
     BIHEX.GreenMask :=  $3E0;
     BIHEX.BlueMask :=  $1F;
     BIHEX.AlphaMask :=  $8000;
     FS.Write(BIHEX, SizeOf(BIHEX));


//    SetLength(data, BIH.Width-1);
//    FillChar(data[0],Length(data) * SizeOf(data[0]),0);
   // FillChar(data^, BIH.SizeOfBitmap, 0);
   // MS.Write(data^, BIH.SizeOfBitmap);

    for y := BIH.Height - 1 downto 0 do
    begin
      sl := ABitmap.ScanLine[y];
      FS.Write(sl^, 2 * ABitmap.Width);
    end;

   finally
    FS.Free;
    end;
end;



procedure Save16bit565(ABitmap: TBitmap; const AFileName: string);
var
  FS: TFileStream;
  BFH: TBMPHeader;
  BIH: TBMPInfo;
  BIHEX:TBMPInfoV4ext;
  y: Integer;
  sl: PWordArray;
begin

  FS := TFileStream.Create(AFileName, fmCreate);
  try

    // Bitmap file header
    FillChar(BFH, SizeOf(BFH), 0);
    BFH.tag := $4D42;  // BM
    BFH.filesize := 2 * ABitmap.Width * ABitmap.Height + SizeOf(BFH) + SizeOf(BIH)+ SizeOf(BIHEX);
    BFH.BitmapOffset := SizeOf(BFH) + SizeOf(BIH) + SizeOf(BIHEX);
    FS.Write(BFH, SizeOf(BFH));

    // Bitmap info header
    FillChar(BIH, SizeOf(BIH), 0);
    BIH.Size := SizeOf(BIH)+SizeOf(BIHEX);
    BIH.Width := ABitmap.Width;
    BIH.Height := ABitmap.Height;
    BIH.Planes := 1;
    BIH.BitsPerPixel := 16;
    BIH.Compression := BI_BITFIELDS;
    BIH.SizeOfBitmap := 2 * (ABitmap.Width * ABitmap.Height);
    FillChar(BIHEX, SizeOf(BIHEX), 0);
    BIHEX.RedMask:=$F800;
    BIHEX.GreenMask:=$7E0;
    BIHEX.BlueMask:=$1F;
    FS.Write(BIH, SizeOf(BIH));
    FS.Write(BIHEX, SizeOf(BIHEX));

    // Pixels
    for y := ABitmap.Height - 1 downto 0 do
    begin
      sl := ABitmap.ScanLine[y];
      FS.Write(sl^, 2 * ABitmap.Width);
    end;

  finally
    FS.Free;
  end;

end;


procedure Save32bitA(ABitmap: TBitmap;Alpha:boolean; const AFileName: string);
var
  FS: TFileStream;
  BFH: TBMPHeader;
  BIH: TBMPInfo;
  BIHEX:TBMPInfoV4ext;
  y: Integer;
  sl: PUInt64;
begin

  FS := TFileStream.Create(AFileName, fmCreate);
  try

    // Bitmap file header
    FillChar(BFH, SizeOf(BFH), 0);
    BFH.tag := $4D42;  // BM
    BFH.filesize := 4 * ABitmap.Width * ABitmap.Height + SizeOf(BFH) + SizeOf(BIH)+ SizeOf(BIHEX);
    BFH.BitmapOffset := SizeOf(BFH) + SizeOf(BIH) + SizeOf(BIHEX);
    FS.Write(BFH, SizeOf(BFH));

    // Bitmap info header
    FillChar(BIH, SizeOf(BIH), 0);
    BIH.Size := SizeOf(BIH)+SizeOf(BIHEX);
    BIH.Width := ABitmap.Width;
    BIH.Height := ABitmap.Height;
    BIH.Planes := 1;
    BIH.BitsPerPixel := 32;
    BIH.Compression := BI_BITFIELDS;
    BIH.SizeOfBitmap := 4 * (ABitmap.Width * ABitmap.Height);
    FillChar(BIHEX, SizeOf(BIHEX), 0);
    BIHEX.AlphaMask:=$00000000;
      if Alpha then
        BIHEX.AlphaMask:=$FF000000;
    BIHEX.RedMask:=  $00FF0000;
    BIHEX.GreenMask:=$0000FF00;
    BIHEX.BlueMask:= $000000FF;
    BIHEX.CSType:=  $73524742;
    FS.Write(BIH, SizeOf(BIH));
    FS.Write(BIHEX, SizeOf(BIHEX));

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

function GetPaddedRowSize(bpp,width:integer):integer;
begin
result:= math.ceil(bpp * width / 32) * 4;
end;

procedure BMP_Save(Abitmap:Tbitmap; filename: string);
var
BMPFormat:TBMPFormat;
begin
  BMPFormat:= GetBMPFormat(Abitmap);
  //TBMPFormat = (bf8bit, bf16bitX1555, bf16bitA1555, bf16bitX444,bf16bitA444, bf16bit565, bf24bit, bf32bit, bfCustom);
  if BMPFormat = bf8bit then
    begin
    Abitmap.SaveToFile(filename);
    end;

    if BMPFormat = bf16bitA1555 then
    begin
     Save16bitA1555BMP(Abitmap, filename);
    end;

   if BMPFormat = bf16bit565 then
    begin
    Save16bit565(Abitmap, filename);
    end;

   if BMPFormat = bf32bit then
    begin
    Save32bitA(Abitmap,true, filename);
    end;





end;
end.

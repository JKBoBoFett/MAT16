unit MATImage;

interface
uses Windows,Graphics, SysUtils, Classes, MATHeaders, Color16,ColorMap,BMParrays,CMPHeaders,BMP_IO;

Type
    TFormat = (INDEX,INDEXT,INDEXCMP,INDEXTCMP,COLOR8,RGB565,ARGB1555, RGBA5551, RGBA4444,BMP);

  TMAT = class
    private
    BitStream:TMemoryStream;
    isTransparent:Boolean;
    transparentColor : longint;
    matFormatHeader:TMatHeader;
    matTextureHeaderA: Array of TTextureHeader;
    matColorHeaderA: Array of TColorHeader;
    matMipmapHeaderA: Array of TTextureMipmapHeader;
    ImageDataIndex: Array of Integer;

    bmap: TBitmap;
    ImageData16 : Array of Array of TColor16;
    ImageData8: Array of Array of byte;

    f: file;

    CMPData:TCMPPal;

    function SetSamplePerChannel(SourceRGBA:tagRGBQuad):tagRGBQuad;
    procedure Convert(IsSubMipMap: Boolean);
//    procedure SetTransparentColorValue(Value: longint );
    procedure ConvertPal;
    procedure WriteCMPtoPalette;
    procedure toBMP(w, h: integer);
    procedure ReadInternalCMP;

    public
     matFormat: TFormat;
     function StrToFormat(str:string):TFORMAT;
     procedure AddCellFromBMP(bmap: TBitmap);
     procedure AddColorCell(Value: longint);
     procedure AddSubMipMapFromBMP(cellIndex:Integer;bmap: TBitmap);
     procedure SaveMat(fname: string);
     function HeadersToJSON:TstringList;
     property transparentColorValue: Integer read transparentColor write transparentColor;
     property GetMatFormat:TFormat read matFormat;
     function LoadFromFile(filename: string;pos: longint=0): TBMPARRAY;
     procedure ReadMATfromPOS(filename: string; pos: longint);
     procedure SetCMP(CMP:TCMPPal);

     constructor Create(format:TFormat);
     constructor CreateFromBMPArray(ABMPARRAY:TBMPARRAY);
     published
     destructor Destroy();override;

  end;

 var
 imageformat:TFormat;

 implementation

constructor TMAT.Create(format:TFormat);
var
// i:integer;
test:string;
begin
   inherited Create();
  self.bmap:=TBitmap.Create;
  ImageDataIndex:=0;
  with matFormatHeader do
    begin
      tag:='MAT ';
      ver:=50;
      mat_Type:=2;
      record_count:=0;
      cel_count:=0;

  isTransparent:=False;

  matFormat:=format;

  if ( (matFormat = INDEX) or (matFormat = INDEXT) or
       (matFormat = INDEXCMP) or (matFormat = INDEXTCMP) or
       (matFormat = COLOR8) ) then
       begin

       if (matFormat = INDEXCMP) or (matFormat = INDEXTCMP)  then
       mat_Type:=3;

       if (matFormat = COLOR8) then
       mat_Type:=0;

       ColorMode:=0;

       bits:=8;
       redbits:=0;
       greenbits:=0;
       bluebits:=0;
       shiftR:=0;
       shiftG:=0;
       shiftB:=0;
       RedBitDif:=0;
       GreenBitDif:=0;
       BlueBitDif:=0;
       alpha_bpp:=0;
       alpha_sh:=0;
       alpha_BitDif:=0;
       end;

   if (matFormat = RGB565)  then
       begin

       ColorMode:=1;

       bits:=16;
       redbits:=5;
       greenbits:=6;
       bluebits:=5;
       shiftR:=11;
       shiftG:=5;
       shiftB:=0;
       RedBitDif:=3;
       GreenBitDif:=2;
       BlueBitDif:=3;
       alpha_bpp:=0;
       alpha_sh:=0;
       alpha_BitDif:=0;
       end;

   if (matFormat = ARGB1555) then
     begin
       ColorMode:=1;

       bits:=16;
       redbits:=5;
       greenbits:=5;
       bluebits:=5;
       shiftR:=10;
       shiftG:=5;
       shiftB:=0;
       RedBitDif:=3;
       GreenBitDif:=3;
       BlueBitDif:=3;
       alpha_bpp:=1;
       alpha_sh:=15;
       alpha_BitDif:=7;
     end;

   if (matFormat = RGBA5551) then
     begin
       ColorMode:=2;

       bits:=16;
       redbits:=5;
       greenbits:=5;
       bluebits:=5;
       shiftR:=11;
       shiftG:=6;
       shiftB:=1;
       RedBitDif:=3;
       GreenBitDif:=3;
       BlueBitDif:=3;
       alpha_bpp:=1;
       alpha_sh:=0;
       alpha_BitDif:=7;
     end;

    if (matFormat =  RGBA4444) then
     begin
       ColorMode:=2;

       bits:=16;
       redbits:=4;
       greenbits:=4;
       bluebits:=4;
       shiftR:=12;
       shiftG:=8;
       shiftB:=4;
       RedBitDif:=4;
       GreenBitDif:=4;
       BlueBitDif:=4;
       alpha_bpp:=4;
       alpha_sh:=0;
       alpha_BitDif:=4;
     end;

    end;
 end;
 constructor TMAT.CreateFromBMPArray(ABMPARRAY:TBMPARRAY);
 var
 i,j,k: integer;
  begin

  Bitstream := TMemoryStream.Create;
  Bitstream.Seek(0, soFromBeginning);

  Create(self.StrToFormat(ABMPARRAY.fmt));

   if matFormatHeader.mat_Type = 0 then
      begin

      for J := 0 to ABMPARRAY.GetCellCount - 1 do
        self.AddColorCell(ABMPARRAY.GetCellColorIndex(J));

      end;

  if matFormatHeader.mat_Type <> 0 then
      begin

      for J := 0 to ABMPARRAY.GetCellCount - 1 do
          begin

          self.AddCellFromBMP(ABMPARRAY.GetCell(J));

            for K := 0 to ABMPARRAY.GetMipCount - 1 do
            begin
             self.AddSubMipMapFromBMP(J,ABMPARRAY.GetMip(J,K));
            end;
          end;

      end;

 end;



//procedure TMAT.SetTransparentColorValue(Value: longint );
//begin
//
//end;
destructor TMAT.Destroy;
begin
 // self.bmap.Free;
  freeandnil(bmap);
  CMPData:=default(TCMPPal);

 inherited;
end;

procedure TMAT.SetCMP(CMP:TCMPPal);
begin
  CMPData:=CMP;
end;

procedure TMAT.AddColorCell(Value: longint);
begin
 matFormatHeader.record_count:=matFormatHeader.record_count+1;

 SetLength(matColorHeaderA,(matFormatHeader.record_count));

 with matColorHeaderA[matFormatHeader.record_count-1] do
    begin
     textype:=0;
     colornum:=Value;
    end;

end;

procedure TMAT.AddCellFromBMP(bmap: TBitmap);
var
i:Integer;
begin

  self.bmap.Assign(bmap);


  if matFormatHeader.bits = 16 then
   begin
  //  bmap.PixelFormat := pf32bit;
  //  bmap.HandleType :=   bmDIB;
   end;
 
  matFormatHeader.cel_count:=matFormatHeader.cel_count+1;
  matFormatHeader.record_count:=matFormatHeader.record_count+1;

  SetLength(matTextureHeaderA,(matFormatHeader.record_count));
  with matTextureHeaderA[matFormatHeader.record_count-1] do
    begin
      textype:=8;
      transparent_color:=0;
      for i := 0 to 2 do pads[i] := 0;
      unk1tha:=0;
      unk1thb:=0;
      unk2th:=0;
      unk3th:=0;
      unk4th:=0;
      cel_idx:=matFormatHeader.cel_count-1;
    end;

  SetLength(matMipmapHeaderA, matFormatHeader.cel_count );
  matMipmapHeaderA[matFormatHeader.cel_count-1].SizeX:=bmap.Width;
  matMipmapHeaderA[matFormatHeader.cel_count-1].SizeY:=bmap.Height;
  matMipmapHeaderA[matFormatHeader.cel_count-1].NumMipMaps:=1;

   if (matFormat = ARGB1555) or (matFormat = INDEXT) or  (matFormat = INDEXTCMP) then
  matMipmapHeaderA[matFormatHeader.cel_count-1].TransparentBool:=1;

  if matFormatHeader.bits = 16 then
  SetLength(Imagedata16, matFormatHeader.cel_count, bmap.Width*bmap.Height );

  if matFormatHeader.bits = 8 then
  SetLength(Imagedata8, matFormatHeader.cel_count, bmap.Width*bmap.Height );

  SetLength(ImageDataIndex, matFormatHeader.cel_count );
  Convert(FALSE);

  bmap.free;
 end;

 procedure TMAT.AddSubMipMapFromBMP(cellIndex:Integer;bmap: TBitmap);
begin
  self.bmap.Assign(bmap);

 matMipmapHeaderA[cellIndex].NumMipMaps:=matMipmapHeaderA[cellIndex].NumMipMaps+1;

 if matFormatHeader.bits = 16 then
  //SetLength(Imagedata16[cellIndex], (bmap.Width*bmap.Height)+Self.ImageDataIndex[cellIndex] );
  SetLength(Imagedata16[cellIndex], (bmap.Width*bmap.Height)+Length(Imagedata16[cellIndex]) );

 if matFormatHeader.bits = 8 then
  SetLength(Imagedata8[cellIndex], (bmap.Width*bmap.Height)+Self.ImageDataIndex[cellIndex] );

  Convert(TRUE);

  bmap.free;
end;
function TMAT.SetSamplePerChannel(SourceRGBA:tagRGBQuad):tagRGBQuad;
begin
   result.rgbRed:=SourceRGBA.rgbRed shr matFormatHeader.RedBitDif;
   result.rgbGreen:=SourceRGBA.rgbGreen shr matFormatHeader.GreenBitDif;
   result.rgbBlue:=SourceRGBA.rgbBlue shr matFormatHeader.BlueBitDif;
   result.rgbReserved:=SourceRGBA.rgbReserved shr matFormatHeader.alpha_BitDif;

    if (matFormat = ARGB1555) then
    result.rgbReserved:=SourceRGBA.rgbReserved and 1;
end;



//Adds pixel data to a Tcolor array
//each row is a cell that contains main image and any mips for that cell
procedure TMAT.Convert(IsSubMipMap: Boolean);
const
  PixelCountMax = 65536;  // 2048 MAX WIDTH
type
  TRGBQuadArray = array[0..PixelCountMax - 1] of TRGBQuad;
  pRGBQuadArray = ^TRGBQuadArray;

  TByteArray = array[0..32767] of Byte;
  PByteArray = ^TByteArray;

var
 i,h,w,cellInedx:integer;
 DestRGBA:tagRGBQuad;
 RGBQuadLineArray: pRGBQuadArray;
 IndexArray: PByteArray;
 row16:PWordArray;
  BMPFormat:TBMPFormat;
begin

//if IsSubMipMap then
//inc(Self.ImageDataIndex[cellInedx]);
//   cellInedx:=0
//else
   cellInedx:= matFormatHeader.cel_count-1;
// if IsSubMipMap then
//inc(Self.ImageDataIndex[cellInedx]);
//i:=0;

  BMPFormat:= GetBMPFormat(self.bmap);


   with matFormatHeader do
     begin

      if ( (bits = 8) and (bmap.PixelFormat = pf8bit) ) then
        begin
        ConvertPal();
        for h := 0 to bmap.Height - 1 do
            begin
             IndexArray:= bmap.ScanLine[h];
              for w := 0 to bmap.Width - 1 do
                begin
                //self.ImageData8[cellInedx][Self.ImageDataIndex[cellInedx]]:=IndexArray^[w];
                bitstream.Write(IndexArray^[w], sizeof(byte));
                inc(Self.ImageDataIndex[cellInedx]);
                end; //w
            end; //h

        end;

      if ( (bits = 16) and (bmap.PixelFormat = pf32bit) )then
        begin
          for h := 0 to bmap.Height - 1 do
            begin
             RGBQuadLineArray := bmap.ScanLine[h];
              for w := 0 to bmap.Width - 1 do
                begin
                 DestRGBA:=SetSamplePerChannel(RGBQuadLineArray[w]);
                 self.ImageData16[cellInedx][Self.ImageDataIndex[cellInedx]].Create(DestRGBA.rgbRed,DestRGBA.rgbGreen,DestRGBA.rgbBlue,DestRGBA.rgbReserved,matFormatHeader);
                 inc(Self.ImageDataIndex[cellInedx]);
                end; //w

          end; //h
      end;

     if ( (bits = 16) and ( (BMPFormat = bf16bitA1555) or (BMPFormat = bf16bit565) ) )then
        begin
          for h := 0 to bmap.Height - 1 do
            begin
             row16 := bmap.ScanLine[h];
              for w := 0 to bmap.Width - 1 do
                begin
                // DestRGBA:=SetSamplePerChannel(RGBQuadLineArray[w]);
                // self.ImageData16[cellInedx][Self.ImageDataIndex[cellInedx]].rgba:=row16^[w];
                 bitstream.Write(row16^[w], sizeof(word));

                 inc(Self.ImageDataIndex[cellInedx]);
                end; //w

          end; //h
      end;





   end;

 DestRGBA:=default(tagRGBQuad);
 RGBQuadLineArray:=nil;
 IndexArray:=nil;
end;

procedure TMAT.SaveMat(fname: string);
var
  Ms: TMemoryStream;
  I,N: Integer;
  Abytes: array of byte;
begin
 ms := TMemoryStream.Create;
 ms.Write(matFormatHeader, sizeof(matFormatHeader));

 Bitstream.Seek(0, soFromBeginning);
 SetLength(Abytes, bitstream.Size);

  //8 bit color type
  if matFormatHeader.mat_Type = 0 then
      begin
      for I:= 0 to Length(matColorHeaderA) - 1 do
      ms.Write( matColorHeaderA[I],  sizeof(matColorHeaderA[I]) );
      end;

 // textures
 if matFormatHeader.mat_Type <> 0 then
      begin
        for I:= 0 to Length(matTextureHeaderA) - 1 do
          ms.Write( matTextureHeaderA[I],  sizeof(matTextureHeaderA[I]) );

        for N:=0 to matFormatHeader.cel_count - 1 do
          begin
            ms.Write(matMipmapHeaderA[N], sizeof(matMipmapHeaderA[N]));

            if matFormatHeader.bits = 16 then
              begin
              //for I:= 0 to Length(ImageData16[N]) - 1 do
              //ms.Write(ImageData16[N][I].rgba, sizeof(ImageData16[N][I].rgba));
               SetLength(Abytes, ImageDataIndex[N]*2);
               bitstream.ReadBuffer(Abytes[0],ImageDataIndex[N]*2);

               ms.Write(Abytes[0], ImageDataIndex[N]*2);

              end;

           if matFormatHeader.bits = 8 then
              begin
              //for I:= 0 to Length(ImageData8[N]) - 1 do
              //ms.Write(ImageData8[N][I], sizeof(ImageData8[N][I]));

              SetLength(Abytes, ImageDataIndex[N]);
              bitstream.ReadBuffer(Abytes[0],ImageDataIndex[N]);

              ms.Write(Abytes[0], ImageDataIndex[N]);
              end;

          end;

        // type 3 internal cmp
        if (matFormat = INDEXCMP) or  (matFormat = INDEXTCMP) then
          begin
            ms.Write(CMPData, sizeof(CMPData) );
           end;

      end;

 Bitstream.Free;
 ms.SaveToFile(fname);
 Ms.Free;
end;

//convert bitmap pal to cmp
procedure TMAT.ConvertPal;
var
i:integer;
PalEntry: array [0..255] of TPaletteEntry;
begin
   if bmap.Palette <> 0 then
    begin
     GetPaletteEntries(bmap.Palette, 0, 256,PalEntry);

     for i:= 0 to 255 do
          begin
           CMPData[i].r:=PalEntry[i].peRed;
           CMPData[i].g:=PalEntry[i].peGreen;
           CMPData[i].b:=PalEntry[i].peBlue;
          end;

   end;
end;

procedure TMAT.WriteCMPtoPalette;
var
log_pal: TMaxLogPalette;
i:integer;
//PalEntry: array [0..255] of TPaletteEntry;
pal: HPalette;

begin
for i := 0 to 255 do
    begin
       log_pal.palPalEntry[i].peRed   := CMPData[i].r;
       log_pal.palPalEntry[i].peGreen := CMPData[i].g;
       log_pal.palPalEntry[i].peBlue  := CMPData[i].b;
       log_pal.palPalEntry[i].peFlags :=0;
    end;

 log_pal.palVersion := $300;
 log_pal.palNumEntries := 256;
 pal:=CreatePalette(PLogPalette(@log_pal)^);
 bmap.Palette:=pal;
 bmap.Modified:=true;

end;

procedure TMAT.ReadMATfromPOS(filename: string; pos: longint);
begin

end;


procedure TMAT.ReadInternalCMP;
var
 orgpos,pos,i,n,mipX,mipY,size:integer;
 tempdata: array of byte;
begin
 orgpos := filepos(f);

       //read over cells
       for i := 0 to matFormatHeader.cel_count - 1  do
          begin
            BlockRead(f, matMipmapHeaderA[i], SizeOf(matMipmapHeaderA[i]));

            size:= (matMipmapHeaderA[i].SizeX*matMipmapHeaderA[i].SizeY);
            SetLength(tempdata,size);
            BlockRead(f, tempdata[0], size);

            mipX:= matMipmapHeaderA[i].SizeX;
            mipY:= matMipmapHeaderA[i].SizeY;

            //read over sub mipmaps
            for n := 1 to matMipmapHeaderA[i].NumMipMaps - 1  do
               begin
                 mipX:=mipX div 2;
                 mipY:=mipY div 2;

                 size:= (mipX*mipY);
                 SetLength(tempdata,size);
                 BlockRead(f, tempdata[0], size);
               end;

          end;
 pos:=filepos(f);
 BlockRead(f, CMPData, SizeOf(CMPData));
 transparentColorValue:=rgb(CMPData[0].r,CMPData[0].g,CMPData[0].b);
 seek(f, orgpos);
end;

function TMAT.LoadFromFile(filename: string;pos: longint=0): TBMPARRAY;
var
  tempBMP:TBitmap;
  i,n,mipX,mipY:integer;
begin
    result:= TBMPARRAY.Create;
    tempBMP:=TBitmap.Create;
    AssignFile(f, filename);

    Reset(f, 1);
    Seek(f, 0);
    Seek(f, pos);

    BlockRead(f, matFormatHeader, SizeOf(matFormatHeader));
    if matFormatHeader.tag <> 'MAT ' then
     raise Exception.Create('Not a valid MAT file!');

     //flat color mat
     if matFormatHeader.mat_Type = 0 then
     begin
       SetLength(matColorHeaderA,(matFormatHeader.record_count));
       for i := 0 to matFormatHeader.record_count - 1 do
        begin
       BlockRead(f, matColorHeaderA[i], SizeOf(matColorHeaderA[i]));

       if Assigned(bmap) then self.bmap.Assign(nil);
         matformat:=TFormat.COLOR8;
         //bmap := TBitmap.Create;
         bmap.PixelFormat := pf8bit;
         bmap.Width  := 64;
         bmap.Height := 64;
         WriteCMPtoPalette;

         bmap.Canvas.Brush.Color :=
         rgb(CMPData[matColorHeaderA[i].colornum].r,
             CMPData[matColorHeaderA[i].colornum].g,
             CMPData[matColorHeaderA[i].colornum].b);

        bmap.Canvas.FillRect(Rect(0, 0, 64, 64));
        result.AddCellFromBMP(bmap);
        //bmap.free;
        end;

     end;

     if matFormatHeader.mat_Type <> 0 then
     begin
       SetLength(matTextureHeaderA,(matFormatHeader.record_count));
       for i := 0 to matFormatHeader.record_count - 1 do
          begin
          BlockRead(f, matTextureHeaderA[i], SizeOf(matTextureHeaderA[i]));
          end;

       SetLength(matMipmapHeaderA, matFormatHeader.cel_count );


       //read internal cmp
       if matFormatHeader.mat_Type = 3 then
         begin
          ReadInternalCMP;
         end;


       //add cells
       for i := 0 to matFormatHeader.cel_count - 1  do
          begin
            BlockRead(f, matMipmapHeaderA[i], SizeOf(matMipmapHeaderA[i]));

            if (matMipmapHeaderA[i].SizeX >8000) or (matMipmapHeaderA[i].SizeX <=0) then
              raise Exception.Create('Invalid Size in MipHeader!');

            toBMP(matMipmapHeaderA[i].SizeX,matMipmapHeaderA[i].SizeY);
            result.AddCellFromBMP(bmap);

            // set cmp of bmp array
            if bmap.PixelFormat = pf8bit then
            result.SetCMP:=self.CMPData;

            result.isTransparent:=self.isTransparent;
            result.transparentColorValue:=self.transparentColorValue;

            mipX:= matMipmapHeaderA[i].SizeX;
            mipY:= matMipmapHeaderA[i].SizeY;

            //add sub mipmaps
            for n := 1 to matMipmapHeaderA[i].NumMipMaps - 1  do
               begin
                 mipX:=mipX div 2;
                 mipY:=mipY div 2;

                 toBMP(mipX,mipY);
                 result.AddSubMipMapFromBMP(bmap);
               end;

          end;



      end;

      case matformat of
       RGB565:result.fmt:='16-bit RGB565';
       ARGB1555:result.fmt:='16-bit ARGB1555';
       RGBA4444:result.fmt:='16-bit RGBA4444';
       RGBA5551:result.fmt:='16-bit RGBA5551';
       INDEX:result.fmt:='8-bit INDEXED';
       INDEXT:result.fmt:='8-bit trans INDEXED';
       COLOR8:result.fmt:='8-bit COLOR';
       INDEXCMP:result.fmt:='8-bit INDEXED int CMP';
       INDEXTCMP:result.fmt:='8-bit INDEXED trans int CMP';
      end;


 //    bmap.SaveToFile('D:\TestBMP\lastcell.bmp');
  imageformat:=matformat;
  tempBMP.Free;
  CloseFile(f);
end;

function TMAT.StrToFormat(str:string):TFORMAT;
 begin
     result:= TFORMAT.BMP;

    // str:='16-bit RGB565';

    if str.Equals('16-bit RGB565') then
      result:= TFORMAT.RGB565;
    if str.Equals('16-bit ARGB1555') then
      result:= TFORMAT.ARGB1555;
    if str.Equals('16-bit RGBA4444') then
      result:= TFORMAT.RGBA4444;
    if str.Equals('16-bit RGBA5551') then
      result:= TFORMAT.RGBA5551;
    if str.Equals('8-bit INDEXED') then
      result:= TFORMAT.INDEX;
    if str.Equals('8-bit trans INDEXED') then
      result:= TFORMAT.INDEXT;
    if str.Equals('8-bit COLOR') then
      result:= TFORMAT.COLOR8;
    if str.Equals('8-bit INDEXED int CMP') then
      result:= TFORMAT.INDEXCMP;
    if str.Equals('8-bit INDEXED trans int CMP') then
      result:= TFORMAT.INDEXTCMP;
 end;

procedure TMAT.toBMP(w, h: integer);
const
  PixelCountMax = 65536;  // 2048 MAX WIDTH
type
  TRGBQuadArray = packed array[0..PixelCountMax - 1] of TRGBQuad;
  pRGBQuadArray = ^TRGBQuadArray;

  TByteArray = array[0..32767] of Byte;
  PByteArray = ^TByteArray;
var
  i,j,pos,orgpos,cmpsize:integer;
  inrow: pRGBQuadArray;
  src:   word;
  cmp:TCMPPal;
//  Bsrc:byte;
//  IndexArray: PByteArray;
begin

//   if Assigned(bmap) then self.bmap.Assign(nil);
//   bmap := TBitmap.Create;

//  Result:=Tbitmap.create;

   bmap.Width  := w;
   bmap.Height := h;

   //RBG565 and ARGB1555
   if (matFormatHeader.bits = 16) and (matFormatHeader.ColorMode = 1)  then
   begin
   bmap.PixelFormat := pf16bit;
   bmap.HandleType :=  bmDIB;
   matformat:=TFormat.RGB565;
   if matMipmapHeaderA[0].TransparentBool = 1 then
   begin
   matformat:=TFormat.ARGB1555;
    bmap.PixelFormat := pf15bit;
    bmap.TransparentColor:=clBlack;
   //bmap.TransparentMode:=  tmFixed;
   bmap.Transparent:=true;
   end;

    for i := 0 to bmap.Height - 1 do
      BlockRead(f, bmap.Scanline[i]^, bmap.Width * 2);
   end;


   //RGBA5551
    if (matFormatHeader.bits = 16) and (matFormatHeader.ColorMode = 2) and (matFormatHeader.alpha_bpp = 1)   then
   begin
   matformat:=TFormat.RGBA5551;
   bmap.PixelFormat := pf32bit;
   bmap.HandleType :=  bmDIB;
   bmap.Alphaformat := afDefined;
    for j := 0 to bmap.Height - 1 do
    begin
      inrow := bmap.ScanLine[j];
      for i := 0 to bmap.Width - 1 do
      begin
        BlockRead(f, src, sizeof(src));
        inrow[i].rgbRed := ((src and $F800) shr 11) shl 3;
        inrow[i].rgbGreen := ((src and $7C0) shr 6) shl 3;
        inrow[i].rgbBlue := ((src and $3E) shr 1) shl 3;
        inrow[i].rgbReserved := ((src and $1) shr 0) * 255;
      end;

    end;

    // bmap.TransparentColor:= clBlack;
     bmap.TransparentMode:= tmAuto;
   end;

   //RGBA4444
   if (matFormatHeader.bits = 16) and (matFormatHeader.ColorMode = 2) and (matFormatHeader.alpha_bpp = 4)   then
   begin
   matformat:=TFormat.RGBA4444;
   bmap.PixelFormat := pf32bit;
   bmap.HandleType :=  bmDIB;
   bmap.Alphaformat := afDefined;
    for j := 0 to bmap.Height - 1 do
    begin
      inrow := bmap.ScanLine[j];
      for i := 0 to bmap.Width - 1 do
      begin
        BlockRead(f, src, sizeof(src));
        inrow[i].rgbRed := ((src and 61440) shr 12) * 17;
        inrow[i].rgbGreen := ((src and 3840) shr 8) * 17;
        inrow[i].rgbBlue := ((src and 240) shr 4) * 17;
        inrow[i].rgbReserved := ((src and 15) shr 0) * 17;

//        inrow[i].rgbRed := ((src and 61440) shr 12) shl 4;
//        inrow[i].rgbGreen := ((src and 3840) shr 8) shl 4;
//        inrow[i].rgbBlue := ((src and 240) shr 4) shl 4;
//        inrow[i].rgbReserved := ((src and 15) shr 0) shl 4;
      end;

    end;

     //bmap.TransparentColor:= bmap.canvas.pixels[0,0];
     bmap.TransparentMode:= tmAuto;
   end;

   //indexed
   if (matFormatHeader.bits = 8) and (matFormatHeader.ColorMode = 0) and (matFormatHeader.mat_Type = 2) then
   begin
    matformat:=TFormat.INDEX;
    bmap.PixelFormat := pf8bit;
    bmap.HandleType :=  bmDIB;

    if matMipmapHeaderA[0].TransparentBool = 1 then
   begin
   matformat:=TFormat.INDEXT;
   //bmap.Transparent:=true;
   //bmap.TransparentColor:=clBlack;
   //bmap.TransparentMode:=  tmFixed;
   bmap.Transparent:=true;
   self.isTransparent:=True;
   end;

    //CMPData:=defCmppal;  //set default cmp
    transparentColorValue:=rgb(CMPData[0].r,CMPData[0].g,CMPData[0].b);
    WriteCMPtoPalette;

    for i := 0 to bmap.Height - 1 do
      BlockRead(f, bmap.Scanline[i]^, bmap.Width);

   end;

// indexed with internal CMP
   if (matFormatHeader.bits = 8) and (matFormatHeader.ColorMode = 0) and (matFormatHeader.mat_Type = 3) then
   begin
    matformat:=TFormat.INDEXCMP;
    bmap.PixelFormat := pf8bit;
    bmap.HandleType :=  bmDIB;

    if matMipmapHeaderA[0].TransparentBool = 1 then
   begin
   matformat:=TFormat.INDEXTCMP;
   bmap.TransparentColor:=clBlack;
   //bmap.TransparentMode:=  tmFixed;
   bmap.Transparent:=true;
   end;
     //read over the bitmap to get to the palette
     //and remember the file position
//     orgpos := filepos(f);
//     pos:=FileSize(f)-sizeof(cmp);
//     seek(f, pos);
//     BlockRead(f, cmp, SizeOf(cmp));
//     CMPData:=cmp;  //set default cmp
//     transparentColorValue:=rgb(cmp[0].r,cmp[0].g,cmp[0].b);
     WriteCMPtoPalette;
//
//     //go back and read the bitmap with the new palette
//     seek(f, orgpos);
     for i := 0 to bmap.Height - 1 do
      BlockRead(f, bmap.Scanline[i]^, bmap.Width);


   end;


end;

 function TMAT.HeadersToJSON:TstringList;
 var
 i:integer;
 begin
 result:=TstringList.Create;

    result.Add('HEADER');
    result.Add(matFormatHeader.tag);
    result.Add('ver: ' + IntToStr(matFormatHeader.ver));
    result.Add('mat_Type: ' + IntToStr(matFormatHeader.mat_Type));
    result.Add('record_count: ' + IntToStr(matFormatHeader.record_count));
    result.Add('cell_count: ' +   IntToStr(matFormatHeader.cel_count));
    result.Add('ColorMode: ' + IntToStr(matFormatHeader.ColorMode));
    result.Add('bits: ' + IntToStr(matFormatHeader.bits));
    result.Add('bluebits: ' + IntToStr(matFormatHeader.bluebits));
    result.Add('greenbits: ' + IntToStr(matFormatHeader.greenbits));
    result.Add('redbit: ' + IntToStr(matFormatHeader.redbits));
    result.Add('shiftR: ' + IntToStr(matFormatHeader.shiftR));
    result.Add('shiftG: ' + IntToStr(matFormatHeader.shiftG));
    result.Add('shiftB: ' + IntToStr(matFormatHeader.shiftB));
    result.Add('RedBitDif: ' + IntToStr(matFormatHeader.RedBitDif));
    result.Add('GreenBitDif: ' +   IntToStr(matFormatHeader.GreenBitDif));
    result.Add('BlueBitDif: ' + IntToStr(matFormatHeader.BlueBitDif));
    result.Add('Alpha_BPP: ' + IntToStr(matFormatHeader.alpha_bpp));
    result.Add('alpha_sh: ' + IntToStr(matFormatHeader.alpha_sh));
    result.Add('Alpha_BitDif: ' + IntToStr(matFormatHeader.alpha_BitDif));


    if  matFormatHeader.mat_Type <> 0 then
    begin

    for i := 0 to matFormatHeader.record_count - 1 do
      begin
        result.Add('');
        result.Add('TEXTURE HEADER');
        result.Add('textype: ' + IntToStr(matTextureHeaderA[i].textype));
        result.Add('transparent_color: ' + IntToStr(matTextureHeaderA[i].transparent_color));
        result.Add('pad[0]: ' + IntToStr(matTextureHeaderA[i].pads[0]));
        result.Add('pad[1]: ' + IntToStr(matTextureHeaderA[i].pads[1]));
        result.Add('pad[2]: ' + IntToStr(matTextureHeaderA[i].pads[2]));
        result.Add('unk1tha: ' + IntToStr(matTextureHeaderA[i].unk1tha));
        result.Add('unk1thb: ' + IntToStr(matTextureHeaderA[i].unk1thb));
        result.Add('unk2th: ' + IntToStr(matTextureHeaderA[i].unk2th));
        result.Add('unk3th: ' + IntToStr(matTextureHeaderA[i].unk3th));
        result.Add('unk4th: ' + IntToStr(matTextureHeaderA[i].unk4th));
        result.Add('texnum: ' + IntToStr(matTextureHeaderA[i].cel_idx));
      end;

   for i:=0 to matFormatHeader.cel_count - 1 do
      begin
        result.Add('');
        result.Add('MIP MAP HEADER');
        result.Add('SizeX: ' + IntToStr(matMipmapHeaderA[i].SizeX));
        result.Add('SizeY: ' + IntToStr(matMipmapHeaderA[i].SizeY));
        result.Add('Transparent: ' + IntToStr(matMipmapHeaderA[i].TransparentBool));
        result.Add('pad[0]: ' + IntToStr(matMipmapHeaderA[i].pad[0]));
        result.Add('pad[1]: ' + IntToStr(matMipmapHeaderA[i].pad[1]));
        result.Add('NumMipMaps: ' + IntToStr(matMipmapHeaderA[i].NumMipMaps));
      end;
 end;

    if  matFormatHeader.mat_Type = 0 then
    begin
     for i := 0 to matFormatHeader.record_count - 1 do
      begin
      result.Add('');
      result.Add('COLOR HEADER');
      result.Add('textype: ' + IntToStr(matColorHeaderA[i].textype));
      result.Add('colorNum: ' + IntToStr(matColorHeaderA[i].colornum));
      result.Add('pad[0]: ' + IntToStr(matColorHeaderA[i].pads[0]));
      result.Add('pad[1]: ' + IntToStr(matColorHeaderA[i].pads[1]));
      result.Add('pad[2]: ' + IntToStr(matColorHeaderA[i].pads[2]));
      result.Add('pad[3]: ' + IntToStr(matColorHeaderA[i].pads[3]));
      end;
    end;
   result.Add('');
 end;

end.

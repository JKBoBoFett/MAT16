unit BMParrays;
//because imagelist use will remap pallete
interface
uses Windows,Graphics, SysUtils, Classes,MATHeaders,ColorMap,CMPHeaders;

 Type


  TBMPARRAY = class
    private
     CellBitmaps: array[0..15] of TBitmap;
     SubMipMapBitmaps: array[0..2] of TBitmap;
      cel_count: integer;
      mip_count: integer;
      x,y:integer;
      format:string;
      CMPData:TCMPPal;
      procedure ConvertPal(bmap: TBitmap);
      procedure setformat(fmt:string);
    public
    constructor Create;
    destructor Destroy;
    procedure AddCellFromBMP(bmap: TBitmap);
    procedure AddSubMipMapFromBMP(bmap: TBitmap);
    function GetCell(index:Integer):Tbitmap;
    function GetAlphaCellForDisplay(index:Integer):Tbitmap;
    function GetMip(index:Integer):Tbitmap;
    property GetCellCount: Integer read cel_count;
    property GetMipCount: Integer read mip_count;
    property GetX: Integer read X;
    property GetY: Integer read Y;
    property fmt: String read format write setformat;
    property GetCMP:TCMPPal read CMPData;
  end;

implementation
constructor TBMPARRAY.Create;
var
i:integer;
begin
   for i:=0 to 15 do
   begin
    CellBitmaps[i]:= TBitmap.Create;
   end;

   for i:=0 to 2 do
   begin
    SubMipMapBitmaps[i]:= TBitmap.Create;
   end;
  cel_count:=0;
  mip_count:=0;
end;
 procedure TBMPARRAY.setformat(fmt:string);
 begin
   format:=fmt;
 end;
 procedure TBMPARRAY.AddCellFromBMP(bmap: TBitmap);
var
i:Integer;
begin
  X:=bmap.Width;
  Y:=bmap.Height;
  CellBitmaps[cel_count].Assign(bmap);
 //  CellBitmaps[cel_count]:=(bmap);
  cel_count:=cel_count+1;

  // ConvertPal(bmap);
end;
procedure TBMPARRAY.AddSubMipMapFromBMP(bmap: TBitmap);
var
i:Integer;
begin
  SubMipMapBitmaps[mip_count].Assign(bmap);
  mip_count:=mip_count+1;

end;
 function TBMPARRAY.GetCell(index:Integer):Tbitmap;
 begin
  Result:=Tbitmap.create;
  Result.Assign(CellBitmaps[index]);
 end;

 function TBMPARRAY.GetAlphaCellForDisplay(index:Integer):Tbitmap;

 var
 BMPAlpha:Tbitmap;
 inrow32: PRGBQuad;
 row16:PWordArray;
 j,i:integer;
 begin
  BMPAlpha:=Tbitmap.create;
  BMPAlpha.Assign(CellBitmaps[index]);
  Result:=Tbitmap.create;


  for j := 0 to BMPAlpha.Height - 1 do
    begin
      inrow32 := BMPAlpha.ScanLine[j];

      for i := 0 to BMPAlpha.Width - 1 do
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


   result.Assign(BMPAlpha);
   BMPAlpha.Free;
  end;





function TBMPARRAY.GetMip(index:Integer):Tbitmap;
 begin
  Result:=Tbitmap.create;
  Result.Assign(SubMipMapBitmaps[index]);
 end;

destructor TBMPARRAY.Destroy;
 var
i:integer;
begin
   for i:=0 to 15 do
   begin
    CellBitmaps[i].Free;
   end;

   for i:=0 to 2 do
   begin
    SubMipMapBitmaps[i].Free;
   end;

end;
 procedure TBMPARRAY.ConvertPal(bmap: TBitmap);
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
end.

unit BMParrays;
//because imagelist use will remap pallete
interface
uses Windows,Graphics, SysUtils, Classes,MATHeaders,ColorMap,CMPHeaders,util,System.IOUtils,Dialogs,BMP_IO,System.StrUtils;

 Type


  TBMPARRAY = class(TPersistent)
    private
     transparentColor : longint;

     CellBitmaps: array[0..15] of TBitmap;
     SubMipMapBitmaps: array[0..15] of array[0..2] of TBitmap;
      cel_count: integer;
      mip_count: array[0..15] of integer;
      x,y:integer;
      format:string;
      CMPData:TCMPPal;
  //    procedure ConvertPal(bmap: TBitmap);

      procedure setformat(fmt:string);
    public
    name:Ansistring;
    isTransparent:Boolean;
    procedure ConvertBMPPal;
    procedure RemapArrayfromCMP(cmp: TCMP);
    procedure Assign(Source: TPersistent); override;
    procedure AddCellFromBMP(bmap: TBitmap);
    procedure AddSubMipMapFromBMP(bmap: TBitmap);
    procedure SaveMTS(filename: string);
    procedure OpenMTS(filename: string);
    function GetCell(index:Integer):Tbitmap;
    function GetCellColorIndex(Cellindex:Integer):Integer;
    function GetAlphaCellForDisplay(index:Integer):Tbitmap;
    function GetMip(Cellindex,Mipindex:Integer):Tbitmap;
    function GetBMP(Cellindex,Mipindex:Integer):Tbitmap;
    property GetCellCount: Integer read cel_count;
    property GetMipCount: Integer read mip_count[0];
    property GetX: Integer read X;
    property GetY: Integer read Y;
    property fmt: String read format write setformat;
    property GetCMP:TCMPPal read CMPData;
    property SetCMP:TCMPPal write CMPData;
    property transparentColorValue: Integer read transparentColor write transparentColor;

    published
     constructor Create;
     destructor Destroy;override;
   Protected

  end;

implementation
constructor TBMPARRAY.Create;
var
i,j:integer;
begin
   for i:=0 to 15 do
   begin
    CellBitmaps[i]:= TBitmap.Create;
    CellBitmaps[i].HandleType :=  bmDIB;
   end;

 for j:=0 to 15 do
   begin
     for i:=0 to 2 do
     begin
      SubMipMapBitmaps[j][i]:= TBitmap.Create;
      SubMipMapBitmaps[j][i].HandleType :=  bmDIB;
     end;
   end;
  cel_count:=0;

  for j:=0 to 15 do
   mip_count[j]:=0;

 isTransparent:=False;
end;

procedure TBMPARRAY.Assign(Source:  TPersistent);
var
  LSource: TBMPARRAY;
  i,j:integer;
begin
   if Source is TBMPARRAY then
  begin
     LSource := TBMPARRAY(Source);
    // Ldest.cel_count := self.cel_count;

     cel_count := LSource.cel_count;

     for j:=0 to 15 do
     mip_count[j]:=LSource.mip_count[j];
   //  mip_count[0] := LSource.GetMipCount;

     x:= LSource.x;
     y:= LSource.y;
     format:= LSource.format;
     CMPData:= LSource.CMPData;
     transparentColor:=LSource.transparentColor;
     isTransparent:=LSource.isTransparent;

     for i:=0 to 15 do begin
     CellBitmaps[i].Assign(LSource.CellBitmaps[i]);
     // LSource.CellBitmaps[i].Free
     end;

     for j:=0 to 15 do
       begin
         for i:=0 to 2 do begin
         SubMipMapBitmaps[j][i].Assign(LSource.SubMipMapBitmaps[j][i]);
         //LSource.SubMipMapBitmaps[i].Free;
         end;
       end;


  end else
    inherited;
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

  if not poweroftwo(bmap.Width) then
      raise Exception.Create('BitMap Width Must be a power of 2');

  if cel_count > 0 then
  begin
      if (bmap.Height <> CellBitmaps[0].Height) or
         (bmap.Width <> CellBitmaps[0].Width) then
         raise Exception.Create('Bitmaps are not the same size!');

         if bmap.PixelFormat <> CellBitmaps[0].PixelFormat then
         raise Exception.Create('Bitmaps are not the same pixel format!');
  end;

  if cel_count > 15 then
     raise Exception.Create('Cell count greater then 16');

  CellBitmaps[cel_count].Assign(bmap);
 //  CellBitmaps[cel_count]:=(bmap);
  cel_count:=cel_count+1;

  // ConvertPal(bmap);
end;
procedure TBMPARRAY.AddSubMipMapFromBMP(bmap: TBitmap);
var
i:Integer;
begin
  if not poweroftwo(bmap.Width) then
      raise Exception.Create('BitMap Width Must be a power of 2');

 if mip_count[cel_count-1] = 0 then
     begin
       if (bmap.Width <> (CellBitmaps[cel_count-1].Width div 2)) or
          (bmap.Height <> (CellBitmaps[cel_count-1].Height div 2)) then
          raise Exception.Create('mip map is the wrong size!');
     end

     else
     if (bmap.Width <> (SubMipMapBitmaps[cel_count-1][mip_count[cel_count-1]-1].Width div 2)) or
        (bmap.Height <> (SubMipMapBitmaps[cel_count-1][mip_count[cel_count-1]-1].Height div 2)) then
          raise Exception.Create('mip map is the wrong size!');

  if mip_count[cel_count-1] > 2 then
     raise Exception.Create('Mip Map count greater then 3');

 if bmap.PixelFormat <> CellBitmaps[0].PixelFormat then
         raise Exception.Create('Bitmaps are not the same pixel format!');

  SubMipMapBitmaps[cel_count-1][mip_count[cel_count-1]].Assign(bmap);
  mip_count[cel_count-1]:=mip_count[cel_count-1]+1;

end;

 function TBMPARRAY.GetCell(index:Integer):Tbitmap;
 begin
  Result:=Tbitmap.create;
  Result.Assign(CellBitmaps[index]);
 end;

function TBMPARRAY.GetCellColorIndex(Cellindex:Integer):Integer;
var
Row: pByteArray;
 begin

 if CellBitmaps[Cellindex].PixelFormat = pf8bit then
    begin
      Row := CellBitmaps[Cellindex].ScanLine[0];
      Result:=Row[0];
    end;

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

function TBMPARRAY.GetMip(Cellindex,Mipindex:Integer):Tbitmap;
 begin
  Result:=Tbitmap.create;
  Result.Assign(SubMipMapBitmaps[Cellindex][Mipindex]);
 end;

function TBMPARRAY.GetBMP(Cellindex,Mipindex:Integer):Tbitmap;
 begin
  Result:=Tbitmap.create;

  if Mipindex = 0 then
  begin
    if self.format.Equals('16-bit RGBA4444') then
     Result.Assign(self.GetAlphaCellForDisplay(Cellindex))
    else
     Result.Assign(self.CellBitmaps[Cellindex]);
  end;

 if Mipindex <> 0 then
  begin
   Result.Assign(SubMipMapBitmaps[Cellindex][Mipindex-1]);
  end;
 end;

// procedure TBMPARRAY.ConvertPal;
//var
//i:integer;
//PalEntry: array [0..255] of TPaletteEntry;
//begin
//   if bmap.Palette <> 0 then
//    begin
//     GetPaletteEntries(bmap.Palette, 0, 256,PalEntry);
//
//     for i:= 0 to 255 do
//          begin
//           CMPData[i].r:=PalEntry[i].peRed;
//           CMPData[i].g:=PalEntry[i].peGreen;
//           CMPData[i].b:=PalEntry[i].peBlue;
//          end;
//
//   end;
//end;


destructor TBMPARRAY.Destroy;
 var
i,j:integer;
begin
   for i:=0 to 15 do
   begin
    CellBitmaps[i].Free;
    CellBitmaps[i]:=nil;
   end;

//   for i:=0 to 2 do
//   begin
//    SubMipMapBitmaps[i].Free;
//    SubMipMapBitmaps[i]:=nil;
//   end;

 for j:=0 to 15 do
   begin
     for i:=0 to 2 do
     begin
      SubMipMapBitmaps[j][i].Free;
      SubMipMapBitmaps[j][i]:=nil;
     end;
   end;


  CMPData:=default(TCMPPal);
  name:='';
  inherited;
end;

 procedure TBMPARRAY.ConvertBMPPal;
var
i:integer;
PalEntry: array [0..255] of TPaletteEntry;
begin
   if self.CellBitmaps[0].Palette <> 0 then
    begin
     GetPaletteEntries(self.CellBitmaps[0].Palette, 0, 256,PalEntry);

     for i:= 0 to 255 do
          begin
           CMPData[i].r:=PalEntry[i].peRed;
           CMPData[i].g:=PalEntry[i].peGreen;
           CMPData[i].b:=PalEntry[i].peBlue;
          end;

   end;
end;

 procedure TBMPARRAY.OpenMTS(filename: string);
 var
 Txt: TextFile;
 s,gpath:string;
 numTex,j,k:integer;
 Splitted: TArray<String>;
 tempBitmap:Tbitmap;
 begin

  gpath := ExtractFilePath(filename);
  AssignFile(Txt, filename);
  Reset(Txt);

  while not Eof(Txt) do
  begin
   Readln(Txt, s);
   Splitted := s.Split([':']);
    if Splitted[0] = 'FILENAME' then
     self.name:=trim(Splitted[1]);
   if Splitted[0] = 'FORMAT' then
    self.setformat(trim(Splitted[1]));
   if Splitted[0] = 'TRANSPARENT' then
     begin
      if trim(Splitted[1]) = '1' then
      self.isTransparent:=true;
     end;
   if Splitted[0] = 'TEXTURES' then
     begin
      numTex:=strtoint(Splitted[1]);
      for J := 1 to numTex do
      begin
       Readln(Txt, s);
       Splitted := s.Split(['|']);
       if fileexists(gpath+Splitted[0]) then
         begin
         //tempBitmap.LoadFromFile(gpath+Splitted[0]);
         tempBitmap:=(BMP_Open(gpath+Splitted[0])); //function creates bmp
         self.AddCellFromBMP(tempBitmap);
         //tempBitmap.Free;
         self.ConvertBMPPal;
         for K := 1 to length(Splitted)-1 do
           begin
            if fileexists(gpath+Splitted[K]) then
              begin
               //tempBitmap.LoadFromFile(gpath+Splitted[K]);
               tempBitmap:=(BMP_Open(gpath+Splitted[K])); //function creates bmp
               self.AddSubMipMapFromBMP(tempBitmap);
              // tempBitmap.Free;
              end;
           end;
         end
       else ShowMessage(Splitted[0]+' no longer exists');

      end;
     end;

  end;
  CloseFile(Txt);
  tempBitmap.Free;
  tempBitmap:=nil;
 end;

 procedure TBMPARRAY.SaveMTS(filename: string);
 var
 i,j,k: integer;
 OutFile: textfile;
 savebitmap: Tbitmap;
 mname,gpath,mpath: Ansistring;
 begin
 {filename needs to be the mat filename}
  if (UpperCase(ExtractFileExt(filename)) <> '.MAT') then
  begin
   raise Exception.Create('Save MTS wrong file type');
  end;


  AssignFile(OutFile, ChangeFileExt(filename, '.mat16s'));
  Rewrite(OutFile);

  WriteLn(OutFile, 'MAT16');
  WriteLn(OutFile, 'FILENAME: '+ExtractFileName(ChangeFileExt(filename, '.mat')));
  WriteLn(OutFile, 'FORMAT: '+self.format);

  if self.isTransparent then
    WriteLn(OutFile, 'TRANSPARENT: 1');

  gpath := ExtractFilePath(filename);

   WriteLn(OutFile, 'TEXTURES: '+inttostr(self.GetCellCount) );

   for J := 0 to self.GetCellCount - 1 do
      begin
      //savebitmap:=Tbitmap.Create;
      savebitmap:=(self.GetCell(J));
      //savebitmap.Assign(self.GetCell(J));
      mname      := ExtractName(filename);
      mname      := TPath.GetFileNameWithoutExtension(mname);
      mname      := mname+'_Cell'+inttostr(j);
      mname      := ChangeFileExt(mname, '.bmp');
      mpath      := gpath + mname;

      Write(OutFile,mname);

       if (UpperCase(ExtractFileExt(mpath)) <> '.BMP') then
        begin
         raise Exception.Create('Save MTS Cell wrong file type');
        end;

         if not ContainsText(mpath,'_Cell') then
          begin
           raise Exception.Create('Save MTS Cell wrong file type');
          end;

      BMP_Save(saveBitmap, mpath);


      saveBitmap.Free;
      saveBitmap:=nil;

       for K := 0 to self.GetMipCount - 1 do
        begin
          //savebitmap := Tbitmap.Create;
          savebitmap:=(self.GetMip(J,K));
          //savebitmap.Assign(self.GetCell(J));
          mname      := ExtractName(filename);
          mname      := TPath.GetFileNameWithoutExtension(mname);
          mname      := mname+'_Cell'+inttostr(j)+'_Mip'+inttostr(K);
          mname      := ChangeFileExt(mname, '.bmp');
          mpath      := gpath + mname;

          Write(OutFile,'|'+mname);

//          if saveBitmap.PixelFormat = pf32bit then
//             SaveTransparentBitmap(saveBitmap, mpath) //work around for saving Tbitmap with alpha
//
//          else
//         saveBitmap.SaveToFile(mpath);
        if  (UpperCase(ExtractFileExt(mpath)) <> '.BMP') then
                begin
                 raise Exception.Create('Save MTS MIP wrong file type');
                end;

         if not ContainsText(mpath,'_Mip') then
          begin
           raise Exception.Create('Save MTS Cell wrong file type');
          end;

          BMP_Save(saveBitmap, mpath);

          saveBitmap.Free;
          saveBitmap:=nil;
        end;

        WriteLn(OutFile,'');
     end;

  CloseFile(OutFile);
 end;

 procedure TBMPARRAY.RemapArrayfromCMP(cmp: TCMP);
 var
 j,i:integer;
 tmpBMP:TBitmap;
 begin
    for j:=0 to cel_count-1 do
   begin
    tmpBMP:=cmp.WriteCMPtoBMP(CellBitmaps[j]);
    CellBitmaps[j].Assign(tmpBMP);
    tmpBMP.Free;
   for i:=0 to mip_count[cel_count-1]-1 do
     begin
      tmpBMP:=cmp.WriteCMPtoBMP(SubMipMapBitmaps[j][i]);
      SubMipMapBitmaps[j][i].Assign(tmpBMP);
      tmpBMP.Free;
     end;

  end;


   end;





end.

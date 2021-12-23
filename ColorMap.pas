unit ColorMap;
interface
uses Windows,Graphics, SysUtils,CMPHeaders, classes;

procedure SetPal(cmppal: TCMPPal);
procedure loadcmp(filename: string; pos: longint);
procedure savepal(filename: string);
procedure saveact(filename: string);
procedure LightLevelRemap(LightLevel:integer);
function WriteCMPtoBMP(JKpal:TCMPPal;inputBMP:Tbitmap):Tbitmap;
 procedure ReadCMPfromPOS(gobfile: string; pos: longint);
var
   Pal:     array[0..255] of TRGBQuad;
//   LightTable: array[0..63] of TTable;
  // defCmppal: TCMPPal;


implementation


 procedure SetPal(cmppal: TCMPPal);
var
  i: integer;
begin
  for i := 0 to 255 do
    with CmpPal[i], Pal[i] do
    begin
      rgbRed   := r;
      rgbGreen := g;
      rgbBlue  := b;
    end;
end;




procedure loadcmp(filename: string; pos: longint);
 // note: cmp pallete = 768 bytes
 // phantom menace cmp's start at 150h,336
var

  cmph: TCMPHeader;
  JKpal:  TCMPPal;
  fcmp: file;
   datalines: TStringList;
  line:string;
  i,j:integer;
begin
datalines:=Tstringlist.create;
line:='';
  AssignFile(fcmp, filename);
  Reset(fcmp, 1);
   Seek(fcmp, pos);
  BlockRead(fcmp, cmph, SizeOf(cmph));

  if cmph.sig <> 'CMP ' then
    Reset(fcmp, 1);    //phantom menace cmp's have no header


  BlockRead(fcmp, JKpal, SizeOf(JKpal));
  BlockRead(fcmp, LightTable, SizeOf(LightTable));

  // SetString(AnsiStr, PAnsiChar(@LightTable), sizeof(LightTable));
     for i := 0 to 63 do
     begin
     line:='(';
        for j := 0 to 255 do
        begin
     line:=line+LightTable[i][j].ToString()+',';
        end;
        line:=line+'),';
        datalines.Add(line);
    end;

   datalines.SaveToFile('D:\ll.txt');



  defCmppal := JKpal;
  orgCmppal:=  JKpal;
  CloseFile(fcmp);
end;


procedure ReadCMPfromPOS(gobfile: string; pos: longint);
var
  j:      integer;
 // ge:     TGob2Entry;
//  gh:     TGOB2Header;
  cmppal: TCMPPal;
  cmpheader: TCMPHeader;
  f:file;
begin
  AssignFile(f, gobfile);
  try
    Reset(f, 1);

        Seek(f, 0);
        Seek(f, pos);
        BlockRead(f, cmpheader, SizeOf(cmpheader));

        if cmpheader.sig <> 'CMP ' then
          raise Exception.Create('Not a valid CMP file!');

        BlockRead(f, cmppal, SizeOf(cmppal));
        BlockRead(f, LightTable, SizeOf(LightTable));
        defCmppal := cmppal;
         orgCmppal:= cmppal;

  finally
    CloseFile(f);

  end;
  end;


procedure LightLevelRemap(LightLevel:integer);
var
i:Integer;
JKpal:  TCMPPal;
begin
  for i := 0 to 255 do
    with orgCmppal[i] do
    begin
    JKpal[i].r:= orgCmppal[LightTable[LightLevel][i]].r;
    JKpal[i].g:= orgCmppal[LightTable[LightLevel][i]].g;
    JKpal[i].b:= orgCmppal[LightTable[LightLevel][i]].b;
    end;

   defCmppal:=JKpal;
end;


function WriteCMPtoBMP(JKpal:TCMPPAL;inputBMP:Tbitmap):Tbitmap;

var
log_pal: TMaxLogPalette;
i,j:integer;
pal: HPalette;
Pinline,Poutline:PByteArray;
begin
 result:=TBitmap.Create();
 result.Width:=inputBMP.Width;
 result.Height:=inputBMP.Height;
 result.PixelFormat:=pf8bit;


  for i := 0 to 255 do
      begin
         log_pal.palPalEntry[i].peRed   := JKpal[i].r;
         log_pal.palPalEntry[i].peGreen := JKpal[i].g;
         log_pal.palPalEntry[i].peBlue  := JKpal[i].b;
         log_pal.palPalEntry[i].peFlags :=0;
      end;

 log_pal.palVersion := $300;
 log_pal.palNumEntries := 256;
 pal:=CreatePalette(PLogPalette(@log_pal)^);
 result.Palette:=pal;
 result.Modified:=true;

 if inputBMP.PixelFormat = pf8bit then
   begin
     for i := 0 to inputBMP.Height - 1 do
       begin
        Pinline:=inputBMP.ScanLine[i];
        Poutline:=result.ScanLine[i];
        for j := 0 to inputBMP.Width - 1 do
         Poutline[j]:= Pinline[j];
     end;
   end;
 inputBMP:=nil;

end;

 procedure savepal(filename: string);
var
  OutFile: textfile;
  i: integer;
begin
  AssignFile(OutFile, filename);
  Rewrite(OutFile);

  WriteLn(OutFile, 'JASC-PAL');
  WriteLn(OutFile, '0100');
  WriteLn(OutFile, '256');

  for i := 0 to 255 do
    with defCmppal[i] do
    begin
      WriteLn(OutFile, IntToStr(r) + ' ' + IntToStr(g) + ' ' + IntToStr(b));
    end;
  CloseFile(OutFile);
end;

procedure saveact(filename: string);
var
  i:     integer;
  actfile: file;
  color: longint;
begin
  assignfile(actfile, filename);
  Rewrite(actfile, 1);
  for i := 0 to 255 do
    with defCmppal[i] do
    begin
      color := r;
      Blockwrite(actfile, color, 1);

      color := g;
      Blockwrite(actfile, color, 1);

      color := b;
      Blockwrite(actfile, color, 1);
    end;


  CloseFile(actfile);
end;


end.

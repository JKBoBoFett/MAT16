unit ColorMap;
interface
uses Windows,Graphics, SysUtils,CMPHeaders, classes,util;

function GetbestCMP(matname: string; gobname: string): string;

type
  TCMP = class
   private
    CMPRGBData:TCMPPal;
    ModCMPRGBData:TCMPPal;
    CMPLightTTable: TLTable;
    IsRGBModified: Boolean;
   public
    HasLightTable: Boolean;
    procedure SetDefault;
    function GetRGB:TCMPPal;
    procedure SetRGB(CMPRGB:TCMPPal);
    procedure LightLevelRemap(LightLevel:integer);
    procedure LoadCMPFromFile(filename: string; pos: longint);
    procedure LoadCMPFromBAFFile(filename: string; pos: longint);
    function WriteCMPtoBMP(inputBMP:Tbitmap):Tbitmap;
    procedure savepal(filename: string);
    procedure saveact(filename: string);
    procedure savegpl(filename: string);
    procedure saveLTtoTXT(filename: string);
   published
    constructor Create;
  end;

implementation

constructor TCMP.Create;
begin
 CMPRGBData:=defCmppal;
 CMPLightTTable:=LightTable;
 IsRGBModified:=false;
 HasLightTable:=true;
end;

procedure TCMP.SetDefault;
begin
 CMPRGBData:=defCmppal;
 CMPLightTTable:=LightTable;
 IsRGBModified:=false;
 HasLightTable:=true;
end;

function TCMP.GetRGB:TCMPPal;
begin
  if IsRGBModified then
  Result:=ModCMPRGBData
  else
  Result:=CMPRGBData;
end;

procedure TCMP.SetRGB(CMPRGB:TCMPPal);
begin
  CMPRGBData:=CMPRGB;
  IsRGBModified:=false;
end;

procedure TCMP.LightLevelRemap(LightLevel:integer);
var
i:Integer;

begin
  if HasLightTable then
  begin

    if (LightLevel > 63) or (LightLevel < 0) then
       raise Exception.Create('Light Level Index out of range');

    begin
    for i := 0 to 255 do
      begin
      ModCMPRGBData[i].r:= CMPRGBData[CMPLightTTable[LightLevel][i]].r;
      ModCMPRGBData[i].g:= CMPRGBData[CMPLightTTable[LightLevel][i]].g;
      ModCMPRGBData[i].b:= CMPRGBData[CMPLightTTable[LightLevel][i]].b;
      end;

     IsRGBModified:=true;
    end;
  end;
end;

procedure TCMP.LoadCMPFromFile(filename: string; pos: longint);
 var
  cmph: TCMPHeader;
  fcmp: file;
begin
  AssignFile(fcmp, filename);
  Reset(fcmp, 1);
  Seek(fcmp, pos);
  BlockRead(fcmp, cmph, SizeOf(cmph));

  if cmph.sig <> 'CMP ' then
    raise Exception.Create('Not a valid CMP file');

  BlockRead(fcmp, CMPRGBData, SizeOf(TCMPPal));
  BlockRead(fcmp, CMPLightTTable, SizeOf(TLTable));
  //Doesn't read Transparency tables
  CloseFile(fcmp);

  IsRGBModified:=false;
  HasLightTable:=true;
end;

procedure TCMP.LoadCMPFromBAFFile(filename: string; pos: longint);
 var
  cmph: TCMPHeader;
  fcmp: file;
begin
  AssignFile(fcmp, filename);
  Reset(fcmp, 1);
  Seek(fcmp, pos);
  //BlockRead(fcmp, cmph, SizeOf(cmph));

  //if cmph.sig <> 'CMP ' then
  //  raise Exception.Create('Not a valid CMP file');

  BlockRead(fcmp, CMPRGBData, SizeOf(TCMPPal));
  //BlockRead(fcmp, CMPLightTTable, SizeOf(TLTable));
  //Doesn't read Transparency tables
  CloseFile(fcmp);

  IsRGBModified:=false;
  HasLightTable:=false;
end;


function TCMP.WriteCMPtoBMP(inputBMP:Tbitmap):Tbitmap;
var
log_pal: TMaxLogPalette;
i,j:integer;
pal: HPalette;
Pinline,Poutline:PByteArray;
JKpal:TCMPPal;
begin

  if inputBMP.PixelFormat <> pf8bit then
      raise Exception.Create('BitMap not 8-bit');


 result:=TBitmap.Create();
 result.PixelFormat:=pf8bit;
 result.HandleType :=  bmDIB;
 result.Width:=inputBMP.Width;
 result.Height:=inputBMP.Height;



 if IsRGBModified then
  JKpal:=ModCMPRGBData
  else
  JKpal:=CMPRGBData;

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
 //inputBMP:=nil;
 // result.PixelFormat:=pf8bit;
 //result.HandleType :=  bmDIB;
end;

//Save to Jasac Paint shop pro format
 procedure TCMP.savepal(filename: string);
var
  OutFile: textfile;
  i: integer;
  JKpal:TCMPPal;
begin
  if IsRGBModified then
  JKpal:=ModCMPRGBData
  else
  JKpal:=CMPRGBData;

  AssignFile(OutFile, filename);
  Rewrite(OutFile);

  WriteLn(OutFile, 'JASC-PAL');
  WriteLn(OutFile, '0100');
  WriteLn(OutFile, '256');

  for i := 0 to 255 do
    with JKpal[i] do
    begin
      WriteLn(OutFile, IntToStr(r) + ' ' + IntToStr(g) + ' ' + IntToStr(b));
    end;
  CloseFile(OutFile);
end;

//Save to Photoshop format
procedure TCMP.saveact(filename: string);
var
  i:     integer;
  actfile: file;
  color: longint;
  JKPal:TCMPPal;
begin
 if IsRGBModified then
  JKpal:=ModCMPRGBData
  else
  JKpal:=CMPRGBData;

  assignfile(actfile, filename);
  Rewrite(actfile, 1);
  for i := 0 to 255 do
    with JKpal[i] do
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

//Save to Gimp format
procedure TCMP.savegpl(filename: string);
var
JKPal:TCMPPal;
OutFile: textfile;
i: integer;
begin
 if IsRGBModified then
  JKpal:=ModCMPRGBData
  else
  JKpal:=CMPRGBData;

  AssignFile(OutFile, filename);
  Rewrite(OutFile);

  WriteLn(OutFile, 'GIMP Palette');
  WriteLn(OutFile, 'Name: ['+ExtractName(filename)+']');
  WriteLn(OutFile, 'Columns: 16');
  WriteLn(OutFile, '#');

  for i := 0 to 255 do
    with JKpal[i] do
    begin
      WriteLn(OutFile, IntToStr(r) + ' ' + IntToStr(g) + ' ' + IntToStr(b) + ' Index '+IntToStr(i));
    end;
   CloseFile(OutFile);
end;


//Used only for debug
procedure TCMP.saveLTtoTXT(filename: string);
var
datalines: TStringList;
line:string;
i,j:integer;
begin
  line:='';
    for i := 0 to 63 do
     begin
     line:='(';
        for j := 0 to 255 do
        begin
     line:=line+CMPLightTTable[i][j].ToString()+',';
        end;
        line:=line+'),';
        datalines.Add(line);
    end;

   datalines.SaveToFile(filename);
   datalines.free;
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
//    if cmp = '41' then
//      Result := '41escort.cmp';
    if cmp = '42' then
      Result := '10cargo.cmp';
    if cmp = '43' then
      Result := '09fuel.cmp';
    if cmp = '52' then
      Result := '01narsh.cmp';
//    if cmp = '53' then
//      Result := '54sith.cmp';
//    if cmp = '54' then
//      Result := '54sith.cmp';
    if cmp = 'm4' then
      Result := 'm4escape.cmp';
  end;


  if UpperCase(ExtractFileExt(gobname)) = '.GOO' then
  begin
    if cmp = '01' then
      Result := '01narsh.cmp';
    if cmp = '03' then
      Result := '03house.cmp';
//    if cmp = '04' then
//      Result := '04farm.cmp';
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
      Result := '10cargo.cmp';
    if cmp = '13' then
      Result := '41escort.cmp';
    if cmp = '14' then
      Result := '54sith.cmp';
    if cmp = '15' then
      Result := '06baron.cmp';
    if cmp = '16' then
      Result := '41escort.cmp';
//    if cmp = '18' then
//      Result := '15maw.cmp';
//    if cmp = '19' then
//      Result := '19descent.cmp';
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



end.

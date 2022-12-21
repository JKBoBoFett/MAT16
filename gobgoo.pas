unit gobgoo;

interface

uses  Classes, SysUtils,Vcl.Dialogs,CMPHeaders,colormap,GloabalVars,MATImage,BMParrays,util,System.StrUtils;

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


{GOB2}
function GobMatToArray(gobfile: string; fileinGobName: string;
           FileOffsets: TFileOffsets;CMPOffsets: TFileOffsets):TBMPArray;
var
bestcmp:string;
pos: integer;
gobCMP:TCMP;
Mat: TMAT;
begin
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

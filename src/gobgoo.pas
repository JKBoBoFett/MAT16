unit gobgoo;

interface

uses  Classes, SysUtils;

type

  //TFInfo=TFileInfo;

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
      if extractfilename(ge.Name) = fileinGobName then
      begin
      result:=ge.Pos;
       break;
      end;
    end;

  finally
    CloseFile(f);
  end;
end;



{GOB2}
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

procedure getmat(matname: string);
begin
end;


end.

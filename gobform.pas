unit gobform;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, mat_read, main, util, gobgoo,ColorMap,CMPHeaders;

type
  {GOB2 declarations}
  TGOB2Header = record
    Magic:    array[0..3] of ANSIchar; {='GOB'#20}
    Long1, long2: longint; { $14, $C}
    NEntries: longint;
  end;

type
  Tbafinfo = array[0..50] of record
    mat:    string;
    offset: integer;
  end;

  TGOB2Entry = record
    Pos, size: longint;
    Name:      array[0..127] of ANSIchar;
  end;

  Tgobview = class(TForm)
    ListBox1:  TListBox;
    Label1:    TLabel;
    GroupBox1: TGroupBox;
    Label2:    TLabel;
    Label3:    TLabel;
    Label4:    TLabel;
    Label5:    TLabel;
    Label6:    TLabel;
    Label7:    TLabel;
    Label8:    TLabel;
    Label9:    TLabel;
    Label10:   TLabel;
    Label11:   TLabel;
    Label12:   TLabel;
    Label13:   TLabel;
    Panel1:    TPanel;
    Image1:    TImage;
    Label14:   TLabel;
    Button1:   TButton;
    Label15:   TLabel;
    Label16:   TLabel;
    Label17:   TLabel;
    Button2:   TButton;
    Label18:   TLabel;
    Label19:   TLabel;
    procedure ListBox1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure opengob(filename: string);
    procedure openbaf(filename: string);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  gobview: Tgobview;
  bafinfo: Tbafinfo;

implementation

uses Batch;

{$R *.DFM}

procedure Tgobview.ListBox1Click(Sender: TObject);
var
  z, i, pos: integer;
  hdr:    TMatHeader;
  thdr:   TTextureHeader;
  tdata:  TTextureData;
  numtex: byte;
  pad:    array[0..27] of ANSIchar;
  cmph:   TCMPHeader;
  pal:    TCMPPal;
  j:      integer;
  ge:     TGob2Entry;
  gh:     TGOB2Header;
  chdr:   Tcolorheader;
  Bitmap: TBitmap;
  colorbitmap: Tbitmap;
  cmpname: string;
begin
  if (UpperCase(ExtractFileExt(label1.Caption)) = '.GOB') or
    (UpperCase(ExtractFileExt(label1.Caption)) = '.GOO') then
  begin
    colorbitmap := Tbitmap.Create;
    colorbitmap.Height := 64;
    colorbitmap.Width := 64;

    for i := 0 to (ListBox1.Items.Count - 1) do
    begin
      if ListBox1.Selected[i] then
      begin
        label4.Caption := ListBox1.Items.Strings[i];

        cmpname := getbestCMP(ListBox1.Items.Strings[i], label1.Caption);

        label19.Caption := cmpname;
        ReadCMPfromGOB(label1.Caption, cmpname);
        mainform.gridPalette.Repaint;
        try

          AssignFile(f, label1.Caption);
          Reset(f, 1);

          BlockRead(f, gh, SizeOf(gh));


          if gh.magic <> 'GOB ' then raise Exception.Create(label1.Caption +
              ' is not a GOB 2.0 file');

          for j := 0 to gh.NEntries - 1 do
          begin
            BlockRead(f, ge, SizeOf(ge));


            if ge.Name = ListBox1.Items.Strings[i] then
            begin
              label5.Caption := IntToStr(ge.Pos);
              label6.Caption := IntToStr(ge.size);


              Seek(f, 0);
              Seek(f, ge.pos);

              BlockRead(f, hdr, SizeOf(hdr));

              if hdr.tag <> 'MAT ' then raise Exception.Create('Not a valid MAT file!');


              label15.Caption := IntToStr(hdr.bits);


              //This is a flat color texture
              if hdr.mat_Type = 0 then
              begin
                SetPal(defCMPPal);{mat_read}
                BlockRead(f, chdr, SizeOf(chdr));

                if not image1.Picture.bitmap.Empty then
                  image1.Picture.Bitmap := nil;


                colorbitmap.Canvas.Brush.Color :=
                  (2 shl 24) + rgb(defCmppal[chdr.transparent_color].r,
                  defCmppal[chdr.transparent_color].g, defcmppal[chdr.transparent_color].b);
                colorbitmap.Canvas.FillRect(Rect(0, 0, 64, 64));
                image1.Picture.Bitmap := colorbitmap;
                Image1.Repaint;
              end;

              // This is a bitmap texture.  (mat_type = 2)
              if hdr.mat_Type <> 0 then
              begin
                // goto the start of the texture data
                Seek(f, sizeof(hdr) + hdr.record_count * sizeof(thdr) + ge.pos);

                //read in the texture data
                BlockRead(f, tdata, SizeOf(tdata));
                tdata := tdata;
                label16.Caption := IntToStr(tdata.SizeX);
                label17.Caption := IntToStr(tdata.SizeY);

                if hdr.bits = 16 then
                begin
                  bitmap := Mat16ToBmp(tdata.SizeX, tdata.SizeY,false,false);
                  image1.Picture.Bitmap := bitmap;
                end;

                if hdr.bits <> 16 then
                begin
                  SetPal(defCMPPal);{mat_read}
                  bitmap := Mat8ToBmp(tdata.SizeX, tdata.SizeY);
                  image1.Picture.Bitmap := bitmap;
                end;
              end;
            end;
          end;

        finally
          CloseFile(f);
        end;
      end;
    end;
	 //memleak fix
    if Assigned(Bitmap) then Bitmap.Free;
    if Assigned(colorbitmap) then colorbitmap.Free;
  end;


  if UpperCase(ExtractFileExt(label1.Caption)) = '.BAF' then
  begin
    for i := 0 to (ListBox1.Items.Count - 1) do
    begin
      if ListBox1.Selected[i] then
      begin
        label4.Caption := ListBox1.Items.Strings[i];




        Reset(f, 1);


        //get number of textures
        seek(f, 196);
        BlockRead(f, numtex, SizeOf(numtex));

        //read the cmp
        seek(f, 336);
        BlockRead(f, pal, SizeOf(pal));
        defCmppal := pal;

        //read over the pad
        BlockRead(f, pad, SizeOf(pad));

        for z := 0 to numtex - 1 do
        begin
          if ListBox1.Items.Strings[i] = bafinfo[i].mat then
          begin
            Seek(f, bafinfo[i].offset);
            BlockRead(f, hdr, SizeOf(hdr));

            if hdr.tag <> 'MAT ' then raise Exception.Create('Not a valid MAT file!');
            if hdr.mat_Type = 0 then raise Exception.Create
              ('flat color texture NOT supported!');

            // goto the start of the texture data
            Seek(f, sizeof(hdr) + hdr.record_count * sizeof(thdr) + bafinfo[i].offset);

            //read in the texture data
            BlockRead(f, tdata, SizeOf(tdata));

            //make sure it's a bitmap texture
            if hdr.mat_Type = 2 then
            begin
              //get the bitmap
              SetPal(defCMPPal);{mat_read}
              bitmap := Mat8ToBmp(tdata.SizeX, tdata.SizeY);
              image1.picture.Bitmap := bitmap;
              exit;
            end;


            //type 3 mat's contain there own palette
            if hdr.mat_Type = 3 then
            begin
              //read over the bitmap to get to the palette
              //and remember the file position
              pos := filepos(f);
              bitmap := Mat8ToBmp(tdata.SizeX, tdata.SizeY);

              //read the palette
              BlockRead(f, pal, SizeOf(pal));
              defCmppal := pal;

              //go back and read the bitmap with the new palette
              seek(f, pos);
              SetPal(defCMPPal);{mat_read}
              bitmap := Mat8ToBmp(tdata.SizeX, tdata.SizeY);
              image1.picture.Bitmap := bitmap;
              exit;
            end;
          end;
        end;
      end;
    end;
  end;
end;




procedure Tgobview.FormShow(Sender: TObject);
//var i:integer;
begin
  if not image1.Picture.bitmap.Empty then
    image1.Picture.Bitmap := nil;

  label14.Caption := IntToStr(ListBox1.Items.Count);
end;


 procedure Tgobview.openbaf(filename: string);
 var
  z, i, pos: integer;
  hdr:    TMatHeader;
  thdr:   TTextureHeader;
  tdata:  TTextureData;
  numtex: byte;
  pad:    array[0..27] of ANSIchar;
  cmph:   TCMPHeader;
  pal:    TCMPPal;
  j:      integer;
  ge:     TGob2Entry;
  gh:     TGOB2Header;
  chdr:   Tcolorheader;
  Bitmap: TBitmap;
  colorbitmap: Tbitmap;
  cmpname: string;
 begin
 AssignFile(f, filename);
    Reset(f, 1);


        //get number of textures
        seek(f, 196);
        BlockRead(f, numtex, SizeOf(numtex));

        //read the cmp
        seek(f, 336);
        BlockRead(f, pal, SizeOf(pal));
        defCmppal := pal;

        //read over the pad
        BlockRead(f, pad, SizeOf(pad));

        for z := 0 to numtex - 1 do
        begin
          if ListBox1.Items.Strings[i] = bafinfo[i].mat then
          begin
            Seek(f, bafinfo[i].offset);
            BlockRead(f, hdr, SizeOf(hdr));

            if hdr.tag <> 'MAT ' then raise Exception.Create('Not a valid MAT file!');
            if hdr.mat_Type = 0 then raise Exception.Create
              ('flat color texture NOT supported!');

            // goto the start of the texture data
            Seek(f, sizeof(hdr) + hdr.record_count * sizeof(thdr) + bafinfo[i].offset);

            //read in the texture data
            BlockRead(f, tdata, SizeOf(tdata));

            //make sure it's a bitmap texture
            if hdr.mat_Type = 2 then
            begin
              //get the bitmap
              SetPal(defCMPPal);{mat_read}
              bitmap := Mat8ToBmp(tdata.SizeX, tdata.SizeY);
              image1.picture.Bitmap := bitmap;
              exit;
            end;


            //type 3 mat's contain there own palette
            if hdr.mat_Type = 3 then
            begin
              //read over the bitmap to get to the palette
              //and remember the file position
              pos := filepos(f);
              bitmap := Mat8ToBmp(tdata.SizeX, tdata.SizeY);

              //read the palette
              BlockRead(f, pal, SizeOf(pal));
              defCmppal := pal;

              //go back and read the bitmap with the new palette
              seek(f, pos);
              SetPal(defCMPPal);{mat_read}
              bitmap := Mat8ToBmp(tdata.SizeX, tdata.SizeY);
              image1.picture.Bitmap := bitmap;
              exit;
            end;
          end;
        end;
 end;

procedure Tgobview.opengob(filename: string);
var
  i:  integer;
  ge: TGob2Entry;

  gh:  TGOB2Header;
  dir: string;
  // f: file;
begin
  try

    AssignFile(f, filename);
    Reset(f, 1);

    BlockRead(f, gh, SizeOf(gh));


    if gh.magic <> 'GOB ' then
      raise Exception.Create(filename + ' is not a GOB 2.0 file');
    gobview.Label3.Caption := IntToStr(gh.NEntries);
    for i := 0 to gh.NEntries - 1 do
    begin
      BlockRead(f, ge, SizeOf(ge));

      Dir := ExtractFileExt(ge.Name);
      if UpperCase(ExtractFileExt(Dir)) = '.MAT' then
      begin
        ListBox1.Items.Append(ge.Name);
      end;
    end;
  finally
    CloseFile(f);
  end;
end;

procedure Tgobview.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  listbox1.Clear;
end;

procedure Tgobview.Button1Click(Sender: TObject);
begin
  main.MainForm.Image1.Picture.Bitmap.Assign(image1.Picture.Bitmap);
  main.MainForm.LabelWidth.Caption := Label6.Caption;
  main.MainForm.LabelHeight.Caption := Label17.Caption;
  main.MainForm.LabelFormat.Caption := label15.Caption;
  main.MainForm.Label3.Caption := '1';
  image1.Picture.Bitmap.FreeImage;
  listbox1.Clear;
  gobview.Close;
end;

procedure Tgobview.Button2Click(Sender: TObject);
var
  i: integer;
  savebitmap: Tbitmap;
  bestcmp, gpath, mpath, fext, mname: string;
begin
 // savebitmap := Tbitmap.Create;
  gpath := ExtractFilePath(label1.Caption);
  fext  := ExtractName(label1.Caption);
  fext  := ChangeFileExt(fext, '');
  gpath := gpath + fext;
  Screen.Cursor := crHourGlass;
  CreateDir(gpath);
  BatchForm.Show;

  BatchForm.ProgressBar1.Max := ListBox1.Items.Count;


  for i := 0 to (ListBox1.Items.Count - 1) do
  begin
    BatchForm.ProgressBar1.Position := i;
    //savebitmap := Tbitmap.Create;
    //savebitmap:=nil;
    bestcmp    := GetbestCMP(listBox1.Items.Strings[i], label1.Caption);
    ReadCMPfromGOB(label1.Caption, bestcmp);
    mainform.gridPalette.Repaint;

    saveBitmap:=ReadMatfromGOB(label1.Caption, listBox1.Items.Strings[i]);
    mname      := ExtractName(listBox1.Items.Strings[i]);
    mname      := ChangeFileExt(mname, '.BMP');
    mpath      := gpath + '\' + mname;
    saveBitmap.SaveToFile(mpath);

    BatchForm.Memo1.Lines.Add('Saved ' + mpath + ' cmp:' + bestcmp);
    application.ProcessMessages;

    saveBitmap.Free;

  end;

  BatchForm.Memo1.Lines.Add('-Done-');
  Screen.Cursor := crDefault;

  //if Assigned(saveBitmap) then saveBitmap.Free;
end;

end.
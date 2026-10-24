unit MatFormat;

{ Jedi Knight (Sith engine) .MAT header model, laid out to match MATHeaders.pas:

    TMatHeader                      76 bytes, always
    mat_Type = 0:  record_count x TColorHeader     (24 bytes each)
    mat_Type = 2/3: record_count x TTextureHeader  (40 bytes each), then for
                    each cell a TTextureMipmapHeader (24 bytes) followed by
                    its pixel data (main image + sub mipmaps)

  The file is kept as raw bytes. Every header value is a node that remembers
  its byte offset and size (2 or 4), so editing patches those bytes in place.
  Pixel data and anything we don't parse is never touched.

  Pixel data is only *skipped*, using SizeX * SizeY * (bits div 8) per mip
  level (each level halves, minimum 1), to find the next cell's header.
  mat_Type 3's trailing palette dump is not parsed. }

interface

uses
  System.SysUtils, System.IOUtils, System.Generics.Collections;

const
  MAT_MAGIC            = $2054414D;  // 'MAT ' as a little-endian int32
  MAT_HEADER_SIZE      = 76;
  OFS_MAT_TYPE         = 8;
  OFS_RECORD_COUNT     = 12;
  OFS_BITS             = 24;
  MAT_TYPE_COLOR       = 0;
  MAT_TYPE_TEXTURE     = 2;
  MAT_TYPE_TEXTURE_PAL = 3;
  COLOR_HEADER_SIZE    = 24;
  TEXTURE_HEADER_SIZE  = 40;
  MIPMAP_HEADER_SIZE   = 24;
  MAX_MIP_LEVELS       = 32;

type
  TMatNode = class
  private
    FChildren: TObjectList<TMatNode>;
  public
    Caption: string;
    Offset: Integer;      // byte offset in the file; -1 for group/note nodes
    Size: Integer;        // 2 (word, unsigned) or 4 (longint, signed)
    Structural: Boolean;  // changing it alters how the rest of the file parses
    constructor Create(const ACaption: string; AOffset: Integer = -1;
      ASize: Integer = 4);
    destructor Destroy; override;
    function Add(const ACaption: string; AOffset: Integer = -1;
      ASize: Integer = 4): TMatNode;
    function IsField: Boolean;
    property Children: TObjectList<TMatNode> read FChildren;
  end;

  TMatFile = class
  private
    FData: TBytes;
    FFileName: string;
    FRoot: TMatNode;
    function AddField(AParent: TMatNode; const AName: string; var AOfs: Integer;
      ASize: Integer = 4; AStructural: Boolean = False): TMatNode;
    procedure AddInts(AParent: TMatNode; const ANames: array of string;
      var AOfs: Integer);
    procedure Note(const AText: string);
    function RecordsFit(AOfs, ACount, ARecSize: Integer): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromFile(const AFileName: string);
    procedure SaveToFile(const AFileName: string);
    /// Rebuild the node tree from the current bytes. Call after editing a
    /// node whose Structural flag is set. Invalidates all existing TMatNodes.
    procedure Parse;
    function ReadInt(AOffset: Integer): Integer;
    function ReadField(ANode: TMatNode): Int64;
    procedure ValueRange(ANode: TMatNode; out Lo, Hi: Int64);
    /// Returns False (and changes nothing) if AValue doesn't fit the field.
    function TrySetField(ANode: TMatNode; AValue: Int64): Boolean;
    property FileName: string read FFileName;
    property Root: TMatNode read FRoot;
  end;

implementation

{ TMatNode }

constructor TMatNode.Create(const ACaption: string; AOffset, ASize: Integer);
begin
  inherited Create;
  Caption := ACaption;
  Offset := AOffset;
  Size := ASize;
  FChildren := TObjectList<TMatNode>.Create(True);
end;

destructor TMatNode.Destroy;
begin
  FChildren.Free;
  inherited;
end;

function TMatNode.Add(const ACaption: string; AOffset, ASize: Integer): TMatNode;
begin
  Result := TMatNode.Create(ACaption, AOffset, ASize);
  FChildren.Add(Result);
end;

function TMatNode.IsField: Boolean;
begin
  Result := Offset >= 0;
end;

{ TMatFile }

constructor TMatFile.Create;
begin
  inherited Create;
  FRoot := TMatNode.Create('MAT');
end;

destructor TMatFile.Destroy;
begin
  FRoot.Free;
  inherited;
end;

function TMatFile.ReadInt(AOffset: Integer): Integer;
begin
  if (AOffset < 0) or (AOffset + SizeOf(Integer) > Length(FData)) then
    raise ERangeError.CreateFmt('Read past end of file at offset %d', [AOffset]);
  Move(FData[AOffset], Result, SizeOf(Integer));
end;

function TMatFile.ReadField(ANode: TMatNode): Int64;
var
  W: Word;
begin
  if ANode.Size = 2 then
  begin
    if (ANode.Offset < 0) or (ANode.Offset + 2 > Length(FData)) then
      raise ERangeError.CreateFmt('Read past end of file at offset %d',
        [ANode.Offset]);
    Move(FData[ANode.Offset], W, 2);
    Result := W;
  end
  else
    Result := ReadInt(ANode.Offset);
end;

procedure TMatFile.ValueRange(ANode: TMatNode; out Lo, Hi: Int64);
begin
  if ANode.Size = 2 then
  begin
    Lo := 0;
    Hi := High(Word);
  end
  else
  begin
    // Accept hex like $FFFFFFFF as well as the signed view.
    Lo := Low(Integer);
    Hi := High(Cardinal);
  end;
end;

function TMatFile.TrySetField(ANode: TMatNode; AValue: Int64): Boolean;
var
  Lo, Hi: Int64;
  W: Word;
  I: Integer;
begin
  Result := False;
  if (ANode.Offset < 0) or (ANode.Offset + ANode.Size > Length(FData)) then
    Exit;
  ValueRange(ANode, Lo, Hi);
  if (AValue < Lo) or (AValue > Hi) then
    Exit;
  if ANode.Size = 2 then
  begin
    W := Word(AValue);
    Move(W, FData[ANode.Offset], 2);
  end
  else
  begin
    if AValue > High(Integer) then
      Dec(AValue, $100000000);
    I := Integer(AValue);
    Move(I, FData[ANode.Offset], SizeOf(Integer));
  end;
  Result := True;
end;

function TMatFile.AddField(AParent: TMatNode; const AName: string;
  var AOfs: Integer; ASize: Integer; AStructural: Boolean): TMatNode;
begin
  Result := AParent.Add(AName, AOfs, ASize);
  Result.Structural := AStructural;
  Inc(AOfs, ASize);
end;

procedure TMatFile.AddInts(AParent: TMatNode; const ANames: array of string;
  var AOfs: Integer);
var
  I: Integer;
begin
  for I := Low(ANames) to High(ANames) do
    AddField(AParent, ANames[I], AOfs);
end;

procedure TMatFile.Note(const AText: string);
begin
  FRoot.Add('(' + AText + ')');
end;

function TMatFile.RecordsFit(AOfs, ACount, ARecSize: Integer): Boolean;
begin
  Result := (ACount >= 0) and
    (Int64(AOfs) + Int64(ACount) * ARecSize <= Length(FData));
end;

procedure TMatFile.LoadFromFile(const AFileName: string);
var
  Data: TBytes;
  Magic: Integer;
begin
  Data := TFile.ReadAllBytes(AFileName);
  if Length(Data) < MAT_HEADER_SIZE then
    raise Exception.Create('File is too small to be a MAT file.');
  Move(Data[0], Magic, SizeOf(Magic));
  if Magic <> MAT_MAGIC then
    raise Exception.Create('Missing "MAT " tag - not a Jedi Knight MAT file.');
  // Only commit once the file has passed validation.
  FData := Data;
  FFileName := AFileName;
  Parse;
end;

procedure TMatFile.SaveToFile(const AFileName: string);
begin
  TFile.WriteAllBytes(AFileName, FData);
  FFileName := AFileName;
end;

procedure TMatFile.Parse;
var
  Ofs, Start, I, Lvl, Count, Bits, MatType: Integer;
  SizeX, SizeY, NumMips, W, H: Integer;
  PixBytes: Int64;
  Grp, Rec: TMatNode;
begin
  FRoot.Children.Clear;
  Ofs := 0;

  // ---- TMatHeader (19 fields, 76 bytes) ----
  Grp := FRoot.Add('TMatHeader');
  AddField(Grp, 'tag', Ofs);
  AddField(Grp, 'ver', Ofs);
  AddField(Grp, 'mat_Type', Ofs, 4, True);
  AddField(Grp, 'record_count', Ofs, 4, True);
  AddField(Grp, 'cel_count', Ofs);
  AddField(Grp, 'ColorMode', Ofs);
  AddField(Grp, 'bits', Ofs, 4, True);
  AddInts(Grp, ['redbits', 'greenbits', 'bluebits',
    'shiftR', 'shiftG', 'shiftB',
    'RedBitDif', 'GreenBitDif', 'BlueBitDif',
    'alpha_bpp', 'alpha_sh', 'alpha_BitDif'], Ofs);

  MatType := ReadInt(OFS_MAT_TYPE);
  Count := ReadInt(OFS_RECORD_COUNT);
  Bits := ReadInt(OFS_BITS);

  case MatType of
    MAT_TYPE_COLOR:
      begin
        if not RecordsFit(Ofs, Count, COLOR_HEADER_SIZE) then
        begin
          Note('record_count is out of range for this file - records not parsed');
          Exit;
        end;
        Grp := FRoot.Add('TColorHeader records');
        for I := 0 to Count - 1 do
        begin
          Rec := Grp.Add(Format('Color %d', [I]));
          AddInts(Rec, ['textype', 'colornum',
            'pads[0]', 'pads[1]', 'pads[2]', 'pads[3]'], Ofs);
        end;
      end;

    MAT_TYPE_TEXTURE, MAT_TYPE_TEXTURE_PAL:
      begin
        if not RecordsFit(Ofs, Count, TEXTURE_HEADER_SIZE) then
        begin
          Note('record_count is out of range for this file - records not parsed');
          Exit;
        end;

        Grp := FRoot.Add('TTextureHeader records');
        for I := 0 to Count - 1 do
        begin
          Rec := Grp.Add(Format('Texture %d', [I]));
          AddInts(Rec, ['textype', 'solid-fill_color',
            'pads[0]', 'pads[1]', 'pads[2]'], Ofs);
          AddField(Rec, 'unk1tha', Ofs, 2);   // 16-bit
          AddField(Rec, 'unk1thb', Ofs, 2);   // 16-bit
          AddInts(Rec, ['unk2th', 'unk3th', 'unk4th', 'cel_idx'], Ofs);
        end;

        Grp := FRoot.Add('TTextureMipmapHeader (one per cell)');
        for I := 0 to Count - 1 do
        begin
          if Ofs + MIPMAP_HEADER_SIZE > Length(FData) then
          begin
            Note(Format('file ends before the mipmap header of cell %d', [I]));
            Break;
          end;
          Start := Ofs;
          Rec := Grp.Add(Format('Cell %d', [I]));
          AddField(Rec, 'SizeX', Ofs, 4, True);
          AddField(Rec, 'SizeY', Ofs, 4, True);
          AddInts(Rec, ['TransparentBool', 'Pad[0]', 'ColorKey'], Ofs);
          AddField(Rec, 'NumMipMaps', Ofs, 4, True);

          // Skip this cell's pixel data to land on the next mipmap header.
          SizeX := ReadInt(Start);
          SizeY := ReadInt(Start + 4);
          NumMips := ReadInt(Start + 20);
          if (Bits <= 0) or (Bits mod 8 <> 0) or (SizeX <= 0) or (SizeY <= 0) or
             (NumMips < 1) or (NumMips > MAX_MIP_LEVELS) then
          begin
            Note(Format('cannot size the pixel data of cell %d - later cells not parsed', [I]));
            Break;
          end;
          PixBytes := 0;
          for Lvl := 0 to NumMips - 1 do
          begin
            W := SizeX shr Lvl;
            if W < 1 then W := 1;
            H := SizeY shr Lvl;
            if H < 1 then H := 1;
            Inc(PixBytes, Int64(W) * H * (Bits div 8));
          end;
          if Int64(Ofs) + PixBytes > Length(FData) then
          begin
            Note(Format('pixel data of cell %d runs past the end of the file - later cells not parsed', [I]));
            Break;
          end;
          Inc(Ofs, Integer(PixBytes));
        end;
      end;
  else
    Note(Format('mat_Type %d is not understood - only TMatHeader is shown', [MatType]));
  end;
end;

end.

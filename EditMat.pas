unit EditMat;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, main, Vcl.ExtCtrls,
  Vcl.ExtDlgs, bmparrays, Vcl.GraphUtil, Vcl.ComCtrls,Vcl.Imaging.GIFImg,MATImage,StrUtils,BMP_IO,util;

type
  TEditMatForm = class(TForm)
    CellsListBox: TListBox;
    MipsListBox: TListBox;
    Panel1: TPanel;
    Image1: TImage;
    OpenPic: TOpenPictureDialog;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    OKButton: TButton;
    Options: TGroupBox;
    MipRadioGroup: TRadioGroup;
    AddCellButton: TButton;
    FormatComboBox: TComboBox;
    Label4: TLabel;
    RemoveCellButton: TButton;
    Label_Color: TLabel;
    Edit_color: TEdit;
    procedure FormShow(Sender: TObject);
    procedure CellsListBoxClick(Sender: TObject);
    procedure MipsListBoxClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure AddCellButtonClick(Sender: TObject);
    procedure Update;
    procedure FormatComboBoxClick(Sender: TObject);
    procedure OKButtonClick(Sender: TObject);
    procedure RemoveCellButtonClick(Sender: TObject);
    procedure CreateMipMapsFromCell(BMPArray:Tbmparray;CellBMP:Tbitmap);
    procedure UpdateSolidColor;
  private
    { Private declarations }
    DitherCheckBox: TCheckBox;  {created in FormShow}
  public
    { Public declarations }
    editA:Tbmparray;
  end;

var
  EditMatForm: TEditMatForm;

type
  TTarget16 = (t565, t1555);
  TAlphaMode = (amUse, amInvert, amIgnore);  {how the alpha channel of a 32-bit source is used for 1555}

{ Converts any bitmap (8-bit, 15/16-bit, 24-bit, 32-bit) to 16-bit RGB565 or ARGB1555, optionally with
  Floyd-Steinberg dithering. For 1555 the alpha channel of a 32-bit source becomes the 1-bit alpha
  (sources without alpha are fully opaque). Caller owns the result. }
function ConvertTo16bit(Src: TBitmap; Target: TTarget16; Dither: Boolean = True; AlphaMode: TAlphaMode = amUse): TBitmap;
function ConvertToRGB565(Src: TBitmap; Dither: Boolean = True): TBitmap;

{ Average color of all cells (LOD 0) -> index of the closest color in the CMP selected on the main form }
function CalcSolidColorIndex(BMPA: TBMPArray): Integer;

implementation

uses CMPHeaders;

{$R *.dfm}

{ Averages the colors of all cells (LOD 0), then returns the palette index of the closest color
  in the CMP currently selected on the main form. }
function CalcSolidColorIndex(BMPA: TBMPArray): Integer;
type
  TWordRow = array[0..32767] of Word;
  PWordRow = ^TWordRow;
var
  c, x, y, i, best, d, bestD, r, g, b: Integer;
  bmp: TBitmap;
  sumR, sumG, sumB, cnt: Int64;
  avgR, avgG, avgB: Integer;
  pal: array[0..255] of TPaletteEntry;
  bytes: PByteArray;
  words: PWordRow;
  w: Word;
  col: TColor;
  cmp: TCMPPal;
begin
  Result := 0;
  if BMPA.GetCellCount = 0 then
    exit;

  sumR := 0; sumG := 0; sumB := 0; cnt := 0;

  for c := 0 to BMPA.GetCellCount - 1 do
  begin
    bmp := BMPA.GetCell(c);  {function creates bmp}
    try
      if bmp.PixelFormat = pf8bit then
      begin
        FillChar(pal, SizeOf(pal), 0);
        GetPaletteEntries(bmp.Palette, 0, 256, pal);
      end;

      for y := 0 to bmp.Height - 1 do
        for x := 0 to bmp.Width - 1 do
        begin
          case bmp.PixelFormat of
            pf8bit:
              begin
                bytes := bmp.ScanLine[y];
                i := bytes^[x];
                r := pal[i].peRed; g := pal[i].peGreen; b := pal[i].peBlue;
              end;
            pf16bit:   {565}
              begin
                words := bmp.ScanLine[y];
                w := words^[x];
                r := ((w shr 11) and 31) * 255 div 31;
                g := ((w shr 5) and 63) * 255 div 63;
                b := (w and 31) * 255 div 31;
              end;
            pf15bit, pfCustom:   {1555, alpha bit ignored}
              begin
                words := bmp.ScanLine[y];
                w := words^[x];
                r := ((w shr 10) and 31) * 255 div 31;
                g := ((w shr 5) and 31) * 255 div 31;
                b := (w and 31) * 255 div 31;
              end;
            pf24bit:
              begin
                bytes := bmp.ScanLine[y];
                b := bytes^[x * 3]; g := bytes^[x * 3 + 1]; r := bytes^[x * 3 + 2];
              end;
            pf32bit:
              begin
                bytes := bmp.ScanLine[y];
                b := bytes^[x * 4]; g := bytes^[x * 4 + 1]; r := bytes^[x * 4 + 2];
              end;
          else
            begin
              col := bmp.Canvas.Pixels[x, y];
              r := GetRValue(col); g := GetGValue(col); b := GetBValue(col);
            end;
          end;
          Inc(sumR, r); Inc(sumG, g); Inc(sumB, b); Inc(cnt);
        end;
    finally
      bmp.Free;
    end;
  end;

  if cnt = 0 then
    exit;

  avgR := sumR div cnt;
  avgG := sumG div cnt;
  avgB := sumB div cnt;

  {nearest palette entry (squared RGB distance)}
  cmp := MainCMP.GetRGB;
  best := 0;
  bestD := MaxInt;
  for i := 0 to 255 do
  begin
    d := Sqr(cmp[i].r - avgR) + Sqr(cmp[i].g - avgG) + Sqr(cmp[i].b - avgB);
    if d < bestD then
    begin
      bestD := d;
      best := i;
    end;
  end;

  Result := best;
end;

procedure TEditMatForm.UpdateSolidColor;
var
  best: Integer;
begin
  if editA.GetCellCount = 0 then
    exit;
  best := CalcSolidColorIndex(editA);
  editA.transparentColorValue := best;
  Edit_color.Text := IntToStr(best);
end;

{ True-color (24/32-bit) source to 16-bit 565 or ARGB1555. Caller owns the result. }
function ConvertTrueColorTo16(Src: TBitmap; Target: TTarget16; Dither: Boolean; AlphaMode: TAlphaMode): TBitmap;
type
  TWordRow = array[0..32767] of Word;
  PWordRow = ^TWordRow;
var
  W, H, x, y, c, bpp, idx, v, q, recon, err, a: Integer;
  sp: PByteArray;
  dp: PWordRow;
  cur, nxt: array of Integer;   // carried error * weight (x16), 1 pixel padding each side, 3 channels
  ch: array[0..2] of Integer;   // quantized B, G, R
  hasAlpha: Boolean;
  alphaBit: Word;
  out16: TBitmap;
begin
  if Src.PixelFormat = pf32bit then
    bpp := 4
  else if Src.PixelFormat = pf24bit then
    bpp := 3
  else
    raise Exception.Create('ConvertTrueColorTo16: source must be 24-bit or 32-bit');

  W := Src.Width;
  H := Src.Height;

  {a 32-bit bitmap whose alpha is all zero (X8R8G8B8) has no alpha info: treat it as opaque}
  hasAlpha := False;
  if bpp = 4 then
    for y := 0 to H - 1 do
    begin
      sp := Src.ScanLine[y];
      for x := 0 to W - 1 do
        if sp^[x * 4 + 3] <> 0 then
        begin
          hasAlpha := True;
          Break;
        end;
      if hasAlpha then Break;
    end;
  if AlphaMode = amIgnore then
    hasAlpha := False;

  out16 := TBitmap.Create;
  if Target = t565 then
    out16.PixelFormat := pf16bit
  else
    out16.PixelFormat := pf15bit;
  out16.HandleType := bmDIB;
  out16.SetSize(W, H);

  SetLength(cur, (W + 2) * 3);
  SetLength(nxt, (W + 2) * 3);

  for y := 0 to H - 1 do
  begin
    sp := Src.ScanLine[y];
    dp := PWordRow(out16.ScanLine[y]);
    for idx := 0 to High(nxt) do nxt[idx] := 0;

    for x := 0 to W - 1 do
    begin
      {1555: a transparent pixel is written as 0 (black, alpha bit clear) and adds no dither error}
      if (Target = t1555) and hasAlpha then
      begin
        a := sp^[x * 4 + 3];
        if AlphaMode = amInvert then
          a := 255 - a;
        if a < 128 then
        begin
          dp^[x] := 0;
          Continue;
        end;
      end;

      for c := 0 to 2 do   // 0=B, 1=G, 2=R (memory order for both 24 and 32-bit DIBs)
      begin
        idx := (x + 1) * 3 + c;
        v := sp^[x * bpp + c] + (cur[idx] div 16);
        if v < 0 then v := 0;
        if v > 255 then v := 255;

        if (c = 1) and (Target = t565) then
        begin
          q := (v * 63 + 127) div 255;       // 6 bits green (565)
          recon := (q * 255 + 31) div 63;
        end
        else
        begin
          q := (v * 31 + 127) div 255;       // 5 bits
          recon := (q * 255 + 15) div 31;
        end;
        ch[c] := q;

        if Dither then
        begin
          err := v - recon;
          // Floyd-Steinberg error diffusion
          Inc(cur[(x + 2) * 3 + c], err * 7);
          Inc(nxt[x * 3 + c],       err * 3);
          Inc(nxt[(x + 1) * 3 + c], err * 5);
          Inc(nxt[(x + 2) * 3 + c], err * 1);
        end;
      end;

      if Target = t565 then
        dp^[x] := Word((ch[2] shl 11) or (ch[1] shl 5) or ch[0])
      else
      begin
        alphaBit := $8000;   // opaque pixel: alpha bit set (transparent pixels were written as 0 above)
        {an opaque pure-black pixel would look transparent in viewers that use black as the transparent
         color, so nudge it to the darkest non-black blue}
        if (ch[0] = 0) and (ch[1] = 0) and (ch[2] = 0) then
          ch[0] := 1;
        dp^[x] := Word(alphaBit or (ch[2] shl 10) or (ch[1] shl 5) or ch[0]);
      end;
    end;

    // next row becomes current
    cur := Copy(nxt, 0, Length(nxt));
  end;

  if Target = t565 then
    Result := out16
  else
  begin
    {same path BMP_Open uses for 1555 so cells have the same pixel format as loaded 1555 bitmaps}
    Result := TBitmap.Create;
    Result.Assign(out16);
    out16.Free;
  end;
end;

{ Non true-color sources are first expanded to 24-bit using their own palette. }
function ConvertTo16bit(Src: TBitmap; Target: TTarget16; Dither: Boolean; AlphaMode: TAlphaMode): TBitmap;
var
  Tmp: TBitmap;
begin
  if (Src.PixelFormat = pf24bit) or (Src.PixelFormat = pf32bit) then
    Result := ConvertTrueColorTo16(Src, Target, Dither, AlphaMode)
  else
  begin
    Tmp := TBitmap.Create;
    try
      Tmp.PixelFormat := pf24bit;
      Tmp.SetSize(Src.Width, Src.Height);
      Tmp.Canvas.Draw(0, 0, Src);
      Result := ConvertTrueColorTo16(Tmp, Target, Dither, AlphaMode);
    finally
      Tmp.Free;
    end;
  end;
end;

function ConvertToRGB565(Src: TBitmap; Dither: Boolean): TBitmap;
begin
  Result := ConvertTo16bit(Src, t565, Dither);
end;

function BmpDesc(F: TBMPFormat): string;
begin
  case F of
    bf8bit: Result := '8-bit';
    bf16bit565: Result := '16-bit RGB565';
    bf16bitX1555, bf16bitA1555: Result := '16-bit 1555';
    bf16bitX444, bf16bitA444: Result := '16-bit 4444';
    bf24bit: Result := '24-bit';
    bf32bit: Result := '32-bit';
  else
    Result := 'an unsupported format';
  end;
end;

{ Percentage (0..100) of pixels with alpha >= 128 in a 32-bit bitmap; -1 when there is no alpha data }
function OpaquePercent(Src: TBitmap): Integer;
var
  x, y: Integer;
  sp: PByteArray;
  opaque, nonZero: Int64;
begin
  Result := -1;
  if Src.PixelFormat <> pf32bit then
    exit;
  opaque := 0; nonZero := 0;
  for y := 0 to Src.Height - 1 do
  begin
    sp := Src.ScanLine[y];
    for x := 0 to Src.Width - 1 do
    begin
      if sp^[x * 4 + 3] <> 0 then Inc(nonZero);
      if sp^[x * 4 + 3] >= 128 then Inc(opaque);
    end;
  end;
  if nonZero = 0 then
    exit;
  Result := Round(100.0 * opaque / (Int64(Src.Width) * Src.Height));
end;

{ Asks whether to convert a bitmap to 1555. Returns 0 = cancel, 1 = use alpha as is, 2 = invert alpha,
  3 = ignore alpha. pct is the percentage of opaque pixels (-1 when the bitmap has no alpha data). }
function Ask1555Convert(AOwner: TComponent; const SrcDesc: string; pct: Integer): Integer;
begin
  Result := 0;
  if pct < 0 then
  begin
    if MessageDlg('The selected bitmap is '+SrcDesc+', but the internal format is 16-bit ARGB1555.'+
                  sLineBreak+sLineBreak+'Do you want to automatically convert it to 16-bit ARGB1555?'+
                  sLineBreak+'(No alpha data: all pixels will be opaque.)',
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      Result := 1;
    exit;
  end;

  with TTaskDialog.Create(AOwner) do
  try
    Caption := 'Confirm';
    Title := 'Convert to 16-bit ARGB1555?';
    Text := 'The selected bitmap is '+SrcDesc+', but the internal format is 16-bit ARGB1555.'+sLineBreak+
            'Alpha channel: '+IntToStr(pct)+'% of the pixels have alpha of 128 or more.';
    MainIcon := tdiNone;
    Flags := [tfUseCommandLinks];
    CommonButtons := [tcbCancel];
    with Buttons.Add do begin Caption := 'Convert using the alpha as is ('+IntToStr(pct)+'% opaque)'; ModalResult := 101; end;
    with Buttons.Add do begin Caption := 'Convert with the alpha inverted ('+IntToStr(100-pct)+'% opaque)'; ModalResult := 102; end;
    with Buttons.Add do begin Caption := 'Convert ignoring alpha (100% opaque)'; ModalResult := 103; end;
    if Execute then
      case ModalResult of
        101: Result := 1;
        102: Result := 2;
        103: Result := 3;
      end;
  finally
    Free;
  end;
end;

{ Shows a cell in the preview. 1555 cells are drawn on a checkerboard so transparent pixels
  (alpha bit clear) are visible instead of looking black. }
procedure ShowCellPreview(Img: TImage; Bmp: TBitmap; Is1555: Boolean);
type
  TWordRow = array[0..32767] of Word;
  PWordRow = ^TWordRow;
var
  pv: TBitmap;
  x, y: Integer;
  w: Word;
  sp: PWordRow;
  dp: PByteArray;
  chk: Byte;
begin
  if (not Is1555) or ((Bmp.PixelFormat <> pf15bit) and (Bmp.PixelFormat <> pfCustom)) then
  begin
    Img.Picture.Bitmap.Assign(Bmp);
    exit;
  end;

  pv := TBitmap.Create;
  try
    pv.PixelFormat := pf24bit;
    pv.SetSize(Bmp.Width, Bmp.Height);
    for y := 0 to Bmp.Height - 1 do
    begin
      sp := Bmp.ScanLine[y];
      dp := pv.ScanLine[y];
      for x := 0 to Bmp.Width - 1 do
      begin
        w := sp^[x];
        if (w and $8000) = 0 then
        begin
          if (((x div 4) + (y div 4)) and 1) = 0 then chk := 128 else chk := 192;
          dp^[x * 3] := chk; dp^[x * 3 + 1] := chk; dp^[x * 3 + 2] := chk;
        end
        else
        begin
          dp^[x * 3]     := (w and 31) * 255 div 31;             // B
          dp^[x * 3 + 1] := ((w shr 5) and 31) * 255 div 31;     // G
          dp^[x * 3 + 2] := ((w shr 10) and 31) * 255 div 31;    // R
        end;
      end;
    end;
    Img.Picture.Bitmap.Assign(pv);
  finally
    pv.Free;
  end;
end;

{ 32-bit RGBA -> 16-bit ARGB1555 for an emissive mat.  Unlike ConvertTo16bit the colour of every pixel is kept,
  the source alpha (>= 128) only decides the glow bit. }
function ConvertToEmissive1555(Src: TBitmap; Dither: Boolean): TBitmap;
type
  TEmByteRow = array[0..262143] of Byte;
  PEmByteRow = ^TEmByteRow;
  TEmWordRow = array[0..65535] of Word;
  PEmWordRow = ^TEmWordRow;
var
  x, y: Integer;
  sp: PEmByteRow;
  dp: PEmWordRow;
begin
  Result := ConvertTo16bit(Src, t1555, Dither, amIgnore);   {colour only, every pixel gets bit 15}
  for y := 0 to Src.Height - 1 do
  begin
    sp := Src.ScanLine[y];
    dp := PEmWordRow(Result.ScanLine[y]);
    for x := 0 to Src.Width - 1 do
      if sp^[x * 4 + 3] >= 128 then
        dp^[x] := dp^[x] or $8000
      else
        dp^[x] := dp^[x] and $7FFF;
  end;
end;

{ Cell preview that knows about emissive formats }
procedure ShowCellPreviewFmt(Img: TImage; Bmp: TBitmap; const Fmt: string);
var
  g: TBitmap;
begin
  if IsEmissiveFmt(Fmt) then
  begin
    g := BuildGlowPreview(Bmp);
    try
      Img.Picture.Bitmap.Assign(g);
    finally
      g.Free;
    end;
  end
  else
    ShowCellPreview(Img, Bmp, ContainsText(Fmt, 'ARGB1555'));
end;

procedure TEditMatForm.AddCellButtonClick(Sender: TObject);
var
loadbmp,resize,resample,converted:tbitmap;
i,cellsBefore,pct,choice:integer;
am:TAlphaMode;
size:double;
fmt:TPixelFormat;

MH:HBITMAP;
BMPFormat:TBMPFORMAT;
begin
  cellsBefore := editA.GetCellCount;
  OpenPic.Filter     :=
    'bmp files |*.bmp;';
//loadbmp := Tbitmap.Create;
resize := Tbitmap.Create;

  if Openpic.Execute then
  begin
       if UpperCase(ExtractFileExt(Openpic.FileName)) = '.BMP' then
    begin

      //loadbmp.HandleType := bmDIB;



      loadbmp:=BMP_Open(OpenPic.FileName); //function creates bmp
    //  loadbmp.LoadFromFile(OpenPic.FileName);
      fmt:= loadbmp.PixelFormat;
     // BMPFormat:=GetBMPFormat(loadbmp);                                                                 fmt:= loadbmp.PixelFormat;


    // 8 bit non transparent
    if (FormatComboBox.ItemIndex < 2) then
     begin
       if fmt <> pf8bit then
        begin
        showmessage('bitmap is '+BMPFMTtoStr(inputBMPFormat)+' not 8-bit');
        exit;
        end

      else
        begin
        editA.AddCellFromBMP(loadbmp);
        editA.ConvertBMPPal;
        if (FormatComboBox.ItemIndex = 0) then
         editA.fmt:= '8-bit INDEXED'
        else
          begin
          editA.fmt:= '8-bit trans INDEXED';
          MipRadioGroup.Enabled:=false;
          MipRadioGroup.ItemIndex :=0;
          end;
        end;
     end;

    if (FormatComboBox.ItemIndex = 2) then
     begin
       {24/32-bit sources can be reduced to 565 automatically, after asking the user}
       if (inputBMPFormat = bf8bit) or (inputBMPFormat = bf24bit) or (inputBMPFormat = bf32bit) then
        begin
         if MessageDlg('The selected bitmap is '+
                       BmpDesc(inputBMPFormat)+
                       ', but the internal format is 16-bit RGB565.'+sLineBreak+sLineBreak+
                       'Do you want to automatically convert it to 16-bit RGB565?'+
                       IfThen(inputBMPFormat = bf32bit,sLineBreak+'(The alpha channel will be discarded.)',''),
                       mtConfirmation, [mbYes, mbNo], 0) = mrYes then
          begin
           converted:= ConvertToRGB565(loadbmp, DitherCheckBox.Checked);
           loadbmp.Free;
           loadbmp:= converted;
           fmt:= loadbmp.PixelFormat;  {now pf16bit, used by the mip-map code below}
           inputBMPFormat:= bf16bit565;
          end
         else
          begin
           loadbmp.Free;
           resize.Free;
           exit;
          end;
        end;

       if inputBMPFormat <> bf16bit565  then
        begin
        showmessage('bitmap is '+BMPFMTtoStr(inputBMPFormat)+' not 16-bit RGB565');
        loadbmp.Free;
        resize.Free;
        exit;
        end

      else
        begin
        editA.AddCellFromBMP(loadbmp);
        editA.fmt:= '16-bit RGB565';
        end;
     end;

    if (FormatComboBox.ItemIndex = 3) then
     begin
       {any other bitmap can be converted to 1555 automatically, after asking the user}
       if inputBMPFormat <> bf16bitA1555 then
        begin
         pct := OpaquePercent(loadbmp);
         choice := Ask1555Convert(Self, BmpDesc(inputBMPFormat), pct);
         if choice <> 0 then
          begin
           case choice of
             2: am := amInvert;
             3: am := amIgnore;
           else am := amUse;
           end;
           converted:= ConvertTo16bit(loadbmp, t1555, DitherCheckBox.Checked, am);
           loadbmp.Free;
           loadbmp:= converted;
           fmt:= loadbmp.PixelFormat;
           inputBMPFormat:= bf16bitA1555;
          end
         else
          begin
           loadbmp.Free;
           resize.Free;
           exit;
          end;
        end;

       if inputBMPFormat <> bf16bitA1555 then
        begin
        showmessage('bitmap is '+BMPFMTtoStr(inputBMPFormat)+' not 16-bit ARGB1555');
        loadbmp.Free;
        resize.Free;
        exit;
        end

      else
        begin
        editA.AddCellFromBMP(loadbmp);
        editA.fmt:= '16-bit ARGB1555';
        MipRadioGroup.Enabled:=false;
        MipRadioGroup.ItemIndex :=0;
        end;
     end;

    {emissive formats (items 7..9): the alpha channel of the source bitmap is the glow mask}
    if (FormatComboBox.ItemIndex >= 7) then
     begin
       if FormatComboBox.ItemIndex = 7 then
        begin
         if inputBMPFormat = bf32bit then
          begin
           converted:= ConvertToEmissive1555(loadbmp, DitherCheckBox.Checked);
           loadbmp.Free;
           loadbmp:= converted;
           fmt:= loadbmp.PixelFormat;
           inputBMPFormat:= bf16bitA1555;
          end;

         if (inputBMPFormat <> bf16bitA1555) and (inputBMPFormat <> bf16bitX1555) then
          begin
           showmessage('bitmap is '+BMPFMTtoStr(inputBMPFormat)+'. Emissive 1555 needs a 32-bit bitmap (alpha = glow mask) or a 16-bit ARGB1555 bitmap');
           loadbmp.Free;
           resize.Free;
           exit;
          end;
         editA.AddCellFromBMP(loadbmp);
         editA.fmt:= '16-bit ARGB1555 emissive';
        end
       else
        begin
         if (inputBMPFormat <> bf32bit) and not ((FormatComboBox.ItemIndex = 8) and (inputBMPFormat = bf16bitA444)) then
          begin
           showmessage('bitmap is '+BMPFMTtoStr(inputBMPFormat)+'. Emissive formats need a 32-bit bitmap (alpha = glow mask)');
           loadbmp.Free;
           resize.Free;
           exit;
          end;
         editA.AddCellFromBMP(loadbmp);
         if FormatComboBox.ItemIndex = 8 then
           editA.fmt:= '16-bit RGBA4444 emissive'
         else
           editA.fmt:= '16-bit RGBA5551 emissive';
        end;
       MipRadioGroup.Enabled:=false;
       MipRadioGroup.ItemIndex :=0;
     end;

    {internal format is actually 32-bit here}
    if (FormatComboBox.ItemIndex = 4) then
     begin
       if (inputBMPFormat <> bf16bitA444) and (inputBMPFormat <> bf32bit) then
        begin
        showmessage('bitmap is '+BMPFMTtoStr(inputBMPFormat)+' not 32-bit or 16-bit RGBA4444');
        exit;
        end

      else
        begin
        editA.AddCellFromBMP(loadbmp);
        editA.fmt:= '16-bit RGBA4444';
        MipRadioGroup.Enabled:=false;
        MipRadioGroup.ItemIndex :=0;
        end;
     end;

    if (FormatComboBox.ItemIndex = 5) then
     begin
       if (inputBMPFormat <> bf24bit) then
        begin
        showmessage('bitmap is '+BMPFMTtoStr(inputBMPFormat)+' not 24-bit');
        exit;
        end

      else
        begin
        editA.AddCellFromBMP(loadbmp);
        editA.fmt:= '24-bit RGB';
        end;
     end;

    if (FormatComboBox.ItemIndex = 6) then
     begin
       if (inputBMPFormat <> bf32bit) then
        begin
        showmessage('bitmap is '+BMPFMTtoStr(inputBMPFormat)+' not 32-bit');
        exit;
        end

      else
        begin
        editA.AddCellFromBMP(loadbmp);
        editA.fmt:= '32-bit RGBA';
        MipRadioGroup.Enabled:=false;
        MipRadioGroup.ItemIndex :=0;
        end;
     end;


      resize.HandleType :=  bmDIB;
      size:=1;

     if IsBMPmipsOK(loadbmp) then
       begin

       if ( (loadbmp.Height > 256) or (loadbmp.Width > 256) ) and (MipRadioGroup.ItemIndex >0 ) then
          begin
            with TTaskDialog.Create(self) do
            try
              Caption := 'Mat16';
              Title := 'Create Mip-Maps';
              Text := 'Do you want to continue even though JK doesnt support Mip-Maps for images >256?';
              CommonButtons := [tcbYes, tcbNo];
              DefaultButton := tcbNo;
              MainIcon := tdiNone;
              if Execute then
                if ModalResult = mrNo then
                  MipRadioGroup.ItemIndex:=0;;
            finally
              Free;
            end;
          end;

        for i := 0 to (MipRadioGroup.ItemIndex - 1) do
          begin
          size:=size / 2;
          scaleimage(loadbmp,resize,size); //converts bmps to 24bit

           //reduce colors back to 8-bit using original pallette
           //https://docwiki.embarcadero.com/Libraries/Sydney/en/Vcl.Imaging.GIFImg.TDitherMode
           if fmt = pf8bit then
             begin
              resample:=ReduceColors(resize,rmPalette,dmNearest,8,loadbmp.Palette);  //palette must still exist after conversion
              editA.AddSubMipMapFromBMP(resample);
              resample.free;
             end;

            if fmt = pf16bit then
             begin
             // resample:= Conv24bitTo16(resize,3,2,3);
              resample:= DitherTo16(resize);
              editA.AddSubMipMapFromBMP(resample);
              resample.free;
             end;

             if fmt = pf24bit then
               editA.AddSubMipMapFromBMP(resize);

          end;
        end;

     loadbmp.Free;
    end;
  end;
  update;
  {a cell was added: auto-fill the solid color index from the cell colors}
  if editA.GetCellCount > cellsBefore then
    UpdateSolidColor;
  resize.Free;

end;

procedure TEditMatForm.CellsListBoxClick(Sender: TObject);
var
i,k:integer;
mname:string;
tmpbmp:tbitmap;
begin
  MipsListBox.Clear;

for i := 0 to (CellsListBox.Items.Count - 1) do
    begin

      if CellsListBox.Selected[i] then
      begin
      tmpbmp:= editA.GetCell(i);
      for K := 0 to editA.GetMipCount - 1 do
        begin
          mname      := 'Cell'+inttostr(i)+'_Mip'+inttostr(K);
          mname      := ChangeFileExt(mname, '.bmp');
          MipsListBox.Items.Add(mname);
        end;

      end;
    end;

   ShowCellPreviewFmt(image1, tmpbmp, editA.fmt);
   tmpbmp.Free;
end;

procedure TEditMatForm.FormatComboBoxClick(Sender: TObject);
begin
update;
end;

procedure TEditMatForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
CellsListBox.Clear;
MipsListBox.Clear;

// if assigned(image1.Picture.Bitmap) then image1.Picture.Bitmap.Free;
image1.Picture:=nil;

end;


procedure TEditMatForm.Update;
var
J:Integer;
mname:string;
begin
CellsListBox.Clear;
MipsListBox.Clear;

//if assigned(image1.Picture.Bitmap) then image1.Picture.Bitmap.Free;
//image1.Picture.Bitmap:=nil;

  if editA.GetCellCount = 0 then
   begin
   OKButton.ModalResult:=mrCancel;
   RemoveCellButton.Enabled:=false;
   FormatComboBox.Enabled:=true;
   MipRadioGroup.Enabled:=true;
    if FormatComboBox.ItemIndex = -1 then
     begin
     AddCellButton.Enabled:=false;
     //RemoveCellButton.Enabled:=false;
     end
    else
     begin
     AddCellButton.Enabled:=true;
     //RemoveCellButton.Enabled:=true;
     end;
   end
  else
   begin
   OKButton.ModalResult:=mrOk;
   end;

  if editA.GetCellCount <> 0 then
     begin
       MipRadioGroup.ItemIndex := editA.GetMipCount;
       MipRadioGroup.Enabled:=false;
       AddCellButton.Enabled:=true;
       RemoveCellButton.Enabled:=true;
       Edit_color.Text:= editA.transparentColorValue.ToString();
     end;

 if editA.GetCellCount >= 16 then
    AddCellButton.Enabled:=false;

  if editA.fmt <> '' then
     begin
       if ContainsText(editA.fmt, '8-bit INDEXED') then
         FormatComboBox.ItemIndex:=0;

       if ContainsText(editA.fmt, '8-bit trans INDEXED') then
         begin
         FormatComboBox.ItemIndex:=1;
         MipRadioGroup.Enabled:=false;
         MipRadioGroup.ItemIndex :=0;
         end;

      if ContainsText(editA.fmt, '16-bit RGB565') then
         FormatComboBox.ItemIndex:=2;

     if ContainsText(editA.fmt, '16-bit ARGB1555') then
        begin
         FormatComboBox.ItemIndex:=3;
         MipRadioGroup.Enabled:=false;
         MipRadioGroup.ItemIndex :=0;
        end;

     if ContainsText(editA.fmt, 'RGBA4444') then
         begin
         FormatComboBox.ItemIndex:=4;
         MipRadioGroup.Enabled:=false;
         MipRadioGroup.ItemIndex :=0;
         end;

     if ContainsText(editA.fmt, '24-bit RGB') then
         FormatComboBox.ItemIndex:=5;

     if ContainsText(editA.fmt, '32-bit RGBA') then
         begin
         FormatComboBox.ItemIndex:=6;
         MipRadioGroup.Enabled:=false;
         MipRadioGroup.ItemIndex :=0;
         end;

     if IsEmissiveFmt(editA.fmt) then
         begin
         if ContainsText(editA.fmt, 'ARGB1555') then FormatComboBox.ItemIndex:=7;
         if ContainsText(editA.fmt, 'RGBA4444') then FormatComboBox.ItemIndex:=8;
         if ContainsText(editA.fmt, 'RGBA5551') then FormatComboBox.ItemIndex:=9;
         MipRadioGroup.Enabled:=false;
         MipRadioGroup.ItemIndex :=0;
         end;

      FormatComboBox.Enabled:=false;
      end;

   for J := 0 to editA.GetCellCount - 1 do
      begin
        mname      := 'Cell'+inttostr(j);
        mname      := ChangeFileExt(mname, '.bmp');
        CellsListBox.Items.Add(mname);
      end;

   if CellsListBox.Items.Count <> 0 then
    begin
      CellsListBox.ItemIndex:=0;
      CellsListBox.OnClick(self);
    end;


end;

procedure TEditMatForm.FormShow(Sender: TObject);
begin
  {dither option for the 16-bit conversions (created in code, the form file is binary)}
  if DitherCheckBox = nil then
  begin
    DitherCheckBox := TCheckBox.Create(Self);
    DitherCheckBox.Parent := Options;
    DitherCheckBox.SetBounds(210, 64, 185, 17);
    DitherCheckBox.Caption := 'Dither 16-bit conversions';
    DitherCheckBox.Hint := 'Floyd-Steinberg dithering when a bitmap is converted to 16-bit 565 or 1555';
    DitherCheckBox.ShowHint := True;
    DitherCheckBox.Checked := True;
  end;

  {default internal format is 16-bit 565 when starting with no cells}
  if editA.GetCellCount = 0 then
    FormatComboBox.ItemIndex := 2;

update;


end;

procedure TEditMatForm.MipsListBoxClick(Sender: TObject);
var
i,j:integer;
tmpbmp:tbitmap;
begin
    for i := 0 to (CellsListBox.Items.Count - 1) do
    begin
     if CellsListBox.Selected[i] then
      begin
       for j := 0 to (MipsListBox.Items.Count - 1) do
           if MipsListBox.Selected[j] then
            tmpbmp:=editA.GetMip(i,j);

      end;
    end;

   ShowCellPreviewFmt(image1, tmpbmp, editA.fmt);
   tmpbmp.Free;
end;

procedure TEditMatForm.OKButtonClick(Sender: TObject);
var
h:Hbitmap;
begin
editA.transparentColorValue:= StrToInt(Edit_color.Text);
end;

procedure TEditMatForm.RemoveCellButtonClick(Sender: TObject);
var
CellIndexToRemove,i:Integer;
NewBMPArray:Tbmparray;
tempBMP:tbitmap;
begin
NewBMPArray:=Tbmparray.Create;
NewBMPArray.fmt:=editA.fmt;

for i := 0 to (CellsListBox.Items.Count - 1) do
 if CellsListBox.Selected[i] then  CellIndexToRemove:=i;

for i := 0 to (editA.GetCellCount - 1) do
  begin
   if i<>CellIndexToRemove then
     begin
     tempBMP:=edita.GetCell(i); {function creates bmp}
     NewBMPArray.AddCellFromBMP( tempBMP );

     if ContainsText(NewBMPArray.fmt,'INDEXED') then
        NewBMPArray.ConvertBMPPal;
     CreateMipMapsFromCell( NewBMPArray,tempBMP );
     tempBMP.Free;
     tempBMP:=nil;
     end;
  end;

edita.Assign(NewBMPArray);
NewBMPArray.Free;
update;
end;

procedure TEditMatForm.CreateMipMapsFromCell(BMPArray:Tbmparray;CellBMP:Tbitmap);
var
resize,resample:tbitmap;
size:double;
i:Integer;
fmt:TPixelFormat;
begin
  resize := Tbitmap.Create;
  resize.HandleType :=  bmDIB;
  size:=1;
  fmt:= CellBMP.PixelFormat;
     if IsBMPmipsOK(CellBMP) then
       begin
        for i := 0 to (MipRadioGroup.ItemIndex - 1) do
          begin
          size:=size / 2;
          scaleimage(CellBMP,resize,size); //converts bmps to 24bit

           //reduce colors back to 8-bit using original pallette
           //https://docwiki.embarcadero.com/Libraries/Sydney/en/Vcl.Imaging.GIFImg.TDitherMode
           if fmt = pf8bit then
             begin
              resample:=ReduceColors(resize,rmPalette,dmNearest,8,CellBMP.Palette);  //palette must still exist after conversion
              BMPArray.AddSubMipMapFromBMP(resample);
              resample.free;
             end;

            if fmt = pf16bit then
             begin
             // resample:= Conv24bitTo16(resize,3,2,3);
              resample:= DitherTo16(resize);
              BMPArray.AddSubMipMapFromBMP( resample);
              resample.free;
             end;

          end;
        end;
resize.Free;
end;

end.

unit cmptool;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Grids, mat_read, ExtCtrls, PaletteLibrary, main, ColorQuantizationLibrary;

type
  TForm1 = class(TForm)
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    gridPalette: TDrawGrid;
    Button1: TButton;
    DrawGrid1: TDrawGrid;
    Memo1:  TMemo;
    Label1: TLabel;
    Label2: TLabel;
    procedure gridPaletteDrawCell(Sender: TObject; ACol, ARow: integer;
      Rect: TRect; State: TGridDrawState);
    procedure FormShow(Sender: TObject);
    procedure DrawGrid1DrawCell(Sender: TObject; ACol, ARow: integer;
      Rect: TRect; State: TGridDrawState);
  private
    Bitmap: TBitmap;
    //PaletteHandle:  hPalette;
    RGBQuadArray: TRGBQuadArray;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

procedure TForm1.gridPaletteDrawCell(Sender: TObject; ACol, ARow: integer;
  Rect: TRect; State: TGridDrawState);
var
  //ColorQuantizer     :  TColorQuantizer;
  // RGBQuadArray       :  TRGBQuadArray;
  //BrushNew  :  hBrush;
  //BrushOld  :  hBrush;
  i, rowi, coli: integer;
begin
  rowi := -1;
  coli := 0;
  // just display the common colors
  for i := 0 to 191 do
  begin
    Inc(rowi);

    if rowi = 16 then
    begin
      rowi := 0;
      Inc(coli);
    end;



    if (arow = coli) and (acol = rowi) then
    begin
      gridPalette.canvas.Brush.Color :=
        (2 shl 24) + rgb(defCmppal[i].r, defCmppal[i].g, defcmppal[i].b);
      gridPalette.canvas.FillRect(Rect);
    end;
  end;
end;


procedure TForm1.FormShow(Sender: TObject);
 //var
 // ColorQuantizer     :  TColorQuantizer;
begin
  //Bitmap.Free;    // Release any existing bitmap
  Bitmap := TBitmap.Create;
  bitmap := main.MainForm.Image1.Picture.Bitmap;
  //PaletteHandle := CreateOptimizedPaletteForSingleBitmap(Bitmap, 6);
  //ColorQuantizer := TColorQuantizer.Create(64, 6);
  //ColorQuantizer.ProcessImage(Bitmap.Handle);
  //ColorQuantizer.GetColorTable(RGBQuadArray);
  //colorQuantizer.Free;
end;

procedure TForm1.DrawGrid1DrawCell(Sender: TObject; ACol, ARow: integer;
  Rect: TRect; State: TGridDrawState);
var
  ColorQuantizer: TColorQuantizer;
  RGBQuadArray:   TRGBQuadArray;
  //BrushNew  :  hBrush;
  //BrushOld  :  hBrush;
  i, rowi, coli:  integer;
begin
  rowi := -1;
  coli := 0;
  //bitmap image pallete
  // SelectPalette(gridPalette.Canvas.Handle, PaletteHandle, FALSE);
  // RealizePalette(gridPalette.Canvas.Handle);
  if bitmap.Empty <> True then
  begin
    ColorQuantizer := TColorQuantizer.Create(64, 6);
    ColorQuantizer.ProcessImage(Bitmap.Handle);
    ColorQuantizer.GetColorTable(RGBQuadArray);


    for i := 0 to 63 do
    begin
      application.ProcessMessages;
      Inc(rowi);

      if rowi = 16 then
      begin
        rowi := 0;
        Inc(coli);
      end;

      if (arow = coli) and (acol = rowi) then
      begin
        Drawgrid1.canvas.Brush.Color :=
          rgb(RGBQuadArray[i].rgbRed, RGBQuadArray[i].rgbGreen, RGBQuadArray[i].rgbBlue);
        Drawgrid1.canvas.FillRect(Rect);
      end;
    end;
    ColorQuantizer.Free;
  end;
  //  ColorQuantizer.Free;
  // bitmap.free;
end;

end.

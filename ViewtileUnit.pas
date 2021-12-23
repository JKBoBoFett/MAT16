unit ViewtileUnit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs;

type
  TViewTiled = class(TForm)
    procedure FormPaint(Sender: TObject);

    procedure FormClose(Sender: TObject; var Action: TCloseAction);

  private
    { Private declarations }
    //MyBitmap: TBitmap;
    procedure WMEraseBkgnd(var m: TWMEraseBkgnd);
      message WM_ERASEBKGND;
  public
    { Public declarations }
  end;

var
  ViewTiled: TViewTiled;

implementation

uses Main;

{$R *.DFM}

procedure TViewTiled.WMEraseBkgnd(var m: TWMEraseBkgnd);
begin
  m.Result := LRESULT(False);
end;


procedure TViewTiled.FormPaint(Sender: TObject);
var
  x, y: integer;
  iBMWid, iBMHeight: integer;
begin
  iBMWid := mainform.image1.Picture.Bitmap.Width;
  iBMHeight := mainform.image1.Picture.Bitmap.Height;
  y := 0;
  while y < Height do
  begin
    x := 0;
    while x < Width do
    begin
      Canvas.Draw(x, y, mainform.image1.Picture.Bitmap);
      x := x + iBMWid;
    end;
    y := y + iBMHeight;
  end;
end;



procedure TViewTiled.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  // Action := caFree;
end;




end.

unit about_unit;

interface

uses Windows, SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls;

type
  TAboutBox = class(TForm)
    Panel1:      TPanel;
    ProductName: TLabel;
    Version:     TLabel;
    Copyright:   TLabel;
    OKButton:    TButton;
    Image1:      TImage;
    Label1:      TLabel;
    Label2:      TLabel;
    Label3:      TLabel;
    Label7:      TLabel;
    Label8:      TLabel;
    Label9:      TLabel;
    Label10:     TLabel;
    Label11:     TLabel;
    Label5:      TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  AboutBox: TAboutBox;

implementation

{$R *.DFM}

end.

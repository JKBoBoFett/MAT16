unit gob_form;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  Tgobview = class(TForm)
    ListBox1: TListBox;
    Label1:   TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  gobview: Tgobview;

implementation

{$R *.DFM}

end.

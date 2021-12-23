unit Batch;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls;

type
  TBatchForm = class(TForm)
    Memo1: TMemo;
    ProgressBar1: TProgressBar;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  BatchForm: TBatchForm;

implementation

{$R *.DFM}

end.

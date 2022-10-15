program Mat16;

{$R *.dres}

uses
  FastMM4 in 'FastMM4\FastMM4.pas',
  Forms,
  MAIN in 'MAIN.PAS' {MainForm},
  Batch in 'Batch.pas' {BatchForm},
  Util in 'Util.pas',
  about_unit in 'about_unit.pas' {AboutBox},
  gobgoo in 'gobgoo.pas',
  gobform in 'gobform.pas' {gobview},
  ViewtileUnit in 'ViewtileUnit.pas' {ViewTiled},
  SaveDLGUnit in 'SaveDLGUnit.pas' {MATSaveDlg},
  mess_frm in 'mess_frm.pas' {mess},
  Vcl.Themes,
  Vcl.Styles,
  MATImage in 'MATImage.pas',
  Color16 in 'Color16.pas',
  MATHeaders in 'MATHeaders.pas',
  BMParrays in 'BMParrays.pas',
  ColorMap in 'ColorMap.pas',
  options in 'options.pas' {OptionsForm},
  CMPHeaders in 'CMPHeaders.pas',
  FastMM4DataCollector in 'FastMM4\FastMM4DataCollector.pas',
  FastMM4LockFreeStack in 'FastMM4\FastMM4LockFreeStack.pas',
  FastMM4Messages in 'FastMM4\FastMM4Messages.pas',
  CNDHeaders in 'CNDHeaders.pas',
  Set8bitFormatOnOpen in 'Set8bitFormatOnOpen.pas' {Set8bitFormatForm},
  EditMat in 'EditMat.pas' {EditMatForm},
  BMP_IO in 'BMP_IO.pas';

// MemCheck;
{$R *.RES}

{
  procedure Leak;
        begin
            TObject.Create;
        end;
 }
begin
{
MemChk;
        Leak;
 }
 //  ReportMemoryLeaksOnShutdown := DebugHook <> 0;
  // Application.CreateForm(TOptionsForm, OptionsForm);
   {$INCLUDE FastMM4\FastMM4Options.inc}
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(Tgobview, gobview);
  Application.CreateForm(TViewTiled, ViewTiled);
  Application.CreateForm(TMATSaveDlg, MATSaveDlg);
  Application.CreateForm(Tmess, mess);
  Application.CreateForm(TOptionsForm, OptionsForm);
  Application.CreateForm(TSet8bitFormatForm, Set8bitFormatForm);
  Application.CreateForm(TEditMatForm, EditMatForm);
  Application.Title := 'Mat16';
  Application.CreateForm(TBatchForm, BatchForm);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.CreateForm(TMATSaveDlg, MATSaveDlg);
  Application.Run;
end.

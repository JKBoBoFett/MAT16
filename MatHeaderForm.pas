unit MatHeaderForm;

{ Main form for the MAT header editor. Built entirely in code, so there is no
  .dfm to keep in sync - add the unit to a project and it just works. }

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.Menus,
  MatFormat;

type
  TMatHeaderForm = class(TForm)
  private
    FMat: TMatFile;
    FTree: TTreeView;
    FStatus: TStatusBar;
    FMenu: TMainMenu;
    FOpenDlg: TOpenDialog;
    FSaveDlg: TSaveDialog;
    FModified: Boolean;
    procedure BuildUI;
    procedure AddMenuItem(AParent: TMenuItem; const ACaption: string;
      AHandler: TNotifyEvent; AShortCut: TShortCut);
    procedure OpenClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure SaveAsClick(Sender: TObject);
    procedure ExitClick(Sender: TObject);
    procedure TreeDblClick(Sender: TObject);
    procedure TreeKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TreeChange(Sender: TObject; Node: TTreeNode);
    procedure DoClose(Sender: TObject; var Action: TCloseAction);
    procedure DoCloseQuery(Sender: TObject; var CanClose: Boolean);
    function ConfirmDiscard: Boolean;
    procedure SaveTo(const AFileName: string);
    procedure PopulateTree;
    procedure AddNodes(AParent: TTreeNode; AMatNode: TMatNode);
    function FieldText(ANode: TMatNode): string;
    procedure EditSelected;
    procedure SelectOffset(AOffset: Integer);
    procedure UpdateCaption;
  public
    procedure LoadFile(const AFileName: string);
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

procedure ShowMatHeaderEditor(const AFileName: string = '');

implementation

procedure ShowMatHeaderEditor(const AFileName: string);
var
  F: TMatHeaderForm;
begin
  F := TMatHeaderForm.Create(Application);
  F.Show;
  if (AFileName <> '') and FileExists(AFileName) then
    F.LoadFile(AFileName);
end;

{ TMatHeaderForm }

constructor TMatHeaderForm.Create(AOwner: TComponent);
begin
  // No .dfm resource, so use CreateNew instead of the inherited Create.
  CreateNew(AOwner);
  FMat := TMatFile.Create;
  BuildUI;
  UpdateCaption;
end;

destructor TMatHeaderForm.Destroy;
begin
  FMat.Free;
  inherited;
end;

procedure TMatHeaderForm.AddMenuItem(AParent: TMenuItem; const ACaption: string;
  AHandler: TNotifyEvent; AShortCut: TShortCut);
var
  Item: TMenuItem;
begin
  Item := TMenuItem.Create(Self);
  Item.Caption := ACaption;
  Item.OnClick := AHandler;
  Item.ShortCut := AShortCut;
  AParent.Add(Item);
end;

procedure TMatHeaderForm.BuildUI;
var
  FileMenu: TMenuItem;
begin
  Width := 520;
  Height := 640;
  Position := poScreenCenter;
  OnCloseQuery := DoCloseQuery;
  OnClose := DoClose;

  FMenu := TMainMenu.Create(Self);
  FileMenu := TMenuItem.Create(Self);
  FileMenu.Caption := '&File';
  FMenu.Items.Add(FileMenu);
  AddMenuItem(FileMenu, '&Open...', OpenClick, ShortCut(Ord('O'), [ssCtrl]));
  AddMenuItem(FileMenu, '&Save', SaveClick, ShortCut(Ord('S'), [ssCtrl]));
  AddMenuItem(FileMenu, 'Save &As...', SaveAsClick, 0);
  AddMenuItem(FileMenu, '-', nil, 0);
  AddMenuItem(FileMenu, 'E&xit', ExitClick, 0);
  Menu := FMenu;

  FStatus := TStatusBar.Create(Self);
  FStatus.Parent := Self;
  FStatus.SimplePanel := True;
  FStatus.SimpleText := 'File > Open to load a .MAT file';

  FTree := TTreeView.Create(Self);
  FTree.Parent := Self;
  FTree.Align := alClient;
  FTree.ReadOnly := True;          // editing goes through our own dialog
  FTree.HideSelection := False;
  FTree.Font.Name := 'Consolas';
  FTree.Font.Size := 10;
  FTree.OnDblClick := TreeDblClick;
  FTree.OnKeyDown := TreeKeyDown;
  FTree.OnChange := TreeChange;

  FOpenDlg := TOpenDialog.Create(Self);
  FOpenDlg.Filter := 'MAT files (*.mat)|*.mat|All files (*.*)|*.*';
  FOpenDlg.Options := [ofFileMustExist, ofEnableSizing];

  FSaveDlg := TSaveDialog.Create(Self);
  FSaveDlg.Filter := FOpenDlg.Filter;
  FSaveDlg.DefaultExt := 'mat';
  FSaveDlg.Options := [ofOverwritePrompt, ofEnableSizing];
end;

function TMatHeaderForm.FieldText(ANode: TMatNode): string;
var
  V, U: Int64;
begin
  V := FMat.ReadField(ANode);
  // Unsigned view for the hex column (2 or 4 bytes wide).
  U := V and ((Int64(1) shl (ANode.Size * 8)) - 1);
  Result := Format('%s = %d   ($%.*x)', [ANode.Caption, V, ANode.Size * 2, U]);
end;

procedure TMatHeaderForm.AddNodes(AParent: TTreeNode; AMatNode: TMatNode);
var
  Child: TMatNode;
  TN: TTreeNode;
begin
  for Child in AMatNode.Children do
  begin
    if Child.IsField then
      TN := FTree.Items.AddChild(AParent, FieldText(Child))
    else
      TN := FTree.Items.AddChild(AParent, Child.Caption);
    TN.Data := Child;
    AddNodes(TN, Child);
  end;
end;

procedure TMatHeaderForm.PopulateTree;
var
  RootNode: TTreeNode;
begin
  FTree.Items.BeginUpdate;
  try
    FTree.Items.Clear;
    RootNode := FTree.Items.Add(nil, ExtractFileName(FMat.FileName));
    AddNodes(RootNode, FMat.Root);
    RootNode.Expand(True);
    RootNode.Selected := True;
  finally
    FTree.Items.EndUpdate;
  end;
end;

procedure TMatHeaderForm.LoadFile(const AFileName: string);
begin
  // Tree nodes point into the model, so drop them before the model rebuilds.
  FTree.Items.Clear;
  try
    FMat.LoadFromFile(AFileName);
  except
    on E: Exception do
    begin
      if FMat.FileName <> '' then
        PopulateTree;   // a failed load leaves the previous file intact
      MessageDlg('Could not open file:'#13#10 + E.Message, mtError, [mbOK], 0);
      Exit;
    end;
  end;
  FModified := False;
  PopulateTree;
  UpdateCaption;
end;

procedure TMatHeaderForm.SaveTo(const AFileName: string);
var
  Bak: string;
begin
  // One-time safety copy of the original next to it.
  Bak := AFileName + '.bak';
  if TFile.Exists(AFileName) and not TFile.Exists(Bak) then
    TFile.Copy(AFileName, Bak);
  FMat.SaveToFile(AFileName);
  FModified := False;
  UpdateCaption;
end;

procedure TMatHeaderForm.EditSelected;
var
  TN: TTreeNode;
  MN: TMatNode;
  S: string;
  V, Lo, Hi: Int64;
  Ofs: Integer;
begin
  TN := FTree.Selected;
  if (TN = nil) or (TN.Data = nil) then
    Exit;
  MN := TMatNode(TN.Data);
  if not MN.IsField then
    Exit;

  S := IntToStr(FMat.ReadField(MN));
  if not InputQuery('Edit ' + MN.Caption, 'Value (decimal, or $hex):', S) then
    Exit;

  if not TryStrToInt64(Trim(S), V) or not FMat.TrySetField(MN, V) then
  begin
    FMat.ValueRange(MN, Lo, Hi);
    MessageDlg(Format('Enter an integer between %d and %d.', [Lo, Hi]),
      mtWarning, [mbOK], 0);
    Exit;
  end;
  FModified := True;

  if MN.Structural then
  begin
    // mat_Type, record_count, bits, SizeX/SizeY/NumMipMaps change how the
    // rest of the file parses, so rebuild the tree and come back to this row.
    Ofs := MN.Offset;
    FTree.Items.Clear;   // before Parse, which frees the nodes the tree points at
    FMat.Parse;
    PopulateTree;
    SelectOffset(Ofs);
  end
  else
    TN.Text := FieldText(MN);

  UpdateCaption;
end;

procedure TMatHeaderForm.SelectOffset(AOffset: Integer);
var
  I: Integer;
begin
  for I := 0 to FTree.Items.Count - 1 do
    if (FTree.Items[I].Data <> nil) and
       (TMatNode(FTree.Items[I].Data).Offset = AOffset) then
    begin
      FTree.Items[I].Selected := True;
      FTree.Items[I].MakeVisible;
      Exit;
    end;
end;

procedure TMatHeaderForm.UpdateCaption;
var
  S: string;
begin
  S := 'MAT Header Editor';
  if FMat.FileName <> '' then
    S := S + ' - ' + ExtractFileName(FMat.FileName);
  if FModified then
    S := S + ' *';
  Caption := S;
end;

function TMatHeaderForm.ConfirmDiscard: Boolean;
begin
  Result := True;
  if not FModified then
    Exit;
  case MessageDlg('Save changes to ' + ExtractFileName(FMat.FileName) + '?',
    mtConfirmation, [mbYes, mbNo, mbCancel], 0) of
    mrYes: SaveTo(FMat.FileName);
    mrNo: ;
  else
    Result := False;
  end;
end;

procedure TMatHeaderForm.DoClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TMatHeaderForm.DoCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := ConfirmDiscard;
end;

procedure TMatHeaderForm.OpenClick(Sender: TObject);
begin
  if ConfirmDiscard and FOpenDlg.Execute then
    LoadFile(FOpenDlg.FileName);
end;

procedure TMatHeaderForm.SaveClick(Sender: TObject);
begin
  if FMat.FileName <> '' then
    SaveTo(FMat.FileName);
end;

procedure TMatHeaderForm.SaveAsClick(Sender: TObject);
begin
  if FMat.FileName = '' then
    Exit;
  FSaveDlg.FileName := FMat.FileName;
  if FSaveDlg.Execute then
    SaveTo(FSaveDlg.FileName);
end;

procedure TMatHeaderForm.ExitClick(Sender: TObject);
begin
  Close;
end;

procedure TMatHeaderForm.TreeDblClick(Sender: TObject);
begin
  EditSelected;
end;

procedure TMatHeaderForm.TreeKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_F2) or (Key = VK_RETURN) then
  begin
    EditSelected;
    Key := 0;
  end;
end;

procedure TMatHeaderForm.TreeChange(Sender: TObject; Node: TTreeNode);
var
  MN: TMatNode;
begin
  if (Node <> nil) and (Node.Data <> nil) then
  begin
    MN := TMatNode(Node.Data);
    if MN.IsField then
    begin
      FStatus.SimpleText := Format(
        'Offset $%.4x (%d), %d bytes  -  double-click or press F2 / Enter to edit',
        [MN.Offset, MN.Offset, MN.Size]);
      Exit;
    end;
  end;
  FStatus.SimpleText := 'Double-click or press F2 / Enter on a value to edit it';
end;

end.

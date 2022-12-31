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
  private
    { Private declarations }
  public
    { Public declarations }
    editA:Tbmparray;
  end;

var
  EditMatForm: TEditMatForm;

implementation

{$R *.dfm}

procedure TEditMatForm.AddCellButtonClick(Sender: TObject);
var
loadbmp,resize,resample:tbitmap;
i:integer;
size:double;
fmt:TPixelFormat;

MH:HBITMAP;
BMPFormat:TBMPFORMAT;
begin
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
       if inputBMPFormat <> bf16bit565  then
        begin
        showmessage('bitmap is '+BMPFMTtoStr(inputBMPFormat)+' not 16-bit RGB565');
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
       if inputBMPFormat <> bf16bitA1555 then
        begin
        showmessage('bitmap is '+BMPFMTtoStr(inputBMPFormat)+' not 16-bit ARGB1555');
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

   image1.Picture.Bitmap.Assign(tmpbmp);
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

   image1.Picture.Bitmap.Assign(tmpbmp);
   tmpbmp.Free;
end;

procedure TEditMatForm.OKButtonClick(Sender: TObject);
var
h:Hbitmap;
begin

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

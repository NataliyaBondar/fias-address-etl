unit fmStreet;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, Menus, cxLookAndFeelPainters, StdCtrls, cxButtons,
  cxTextEdit, cxMaskEdit, cxDropDownEdit, ExtCtrls, cxGroupBox, cxRadioGroup,
  jpeg, cxImage, cxControls, cxContainer, cxEdit, cxLabel, ExecuteStack, DBClient;

type
  TfrStreet = class(TForm)
    cxLabel1: TcxLabel;
    cxImage1: TcxImage;
    cxRadioGroup1: TcxRadioGroup;
    Panel1: TPanel;
    Panel2: TPanel;
    cmbTypeStreet: TcxComboBox;
    cmbNameStreet: TcxTextEdit;
    cxLabel2: TcxLabel;
    cxLabel3: TcxLabel;
    cxButton1: TcxButton;
    cxButton2: TcxButton;
    procedure cxRadioGroup1PropertiesChange(Sender: TObject);
    procedure cxTextEdit1PropertiesChange(Sender: TObject);
    procedure cmbTypeStreetPropertiesChange(Sender: TObject);
    procedure cxButton2Click(Sender: TObject);
    procedure cmbTypeStreetPropertiesEditValueChanged(Sender: TObject);
    procedure cxButton1Click(Sender: TObject);
  private
    { Private declarations }
  public
   // RunStreet: TRunStack;
    procedure LoadTypeStreet;
    { Public declarations }
  end;

var
  frStreet: TfrStreet;
  prStreet: Integer;
  NameStreet: String;
  TypeStreet: Integer;

  cdsTypeStreet: TClientDataSet;
  arTypeStreet: array of Integer;
  guidTypeStreet: Integer;

implementation

uses fmFIAS;

{$R *.dfm}
procedure TfrStreet.LoadTypeStreet;
var
  stXML : String;
begin
  try
    if cdsTypeStreet <> nil then
      cdsTypeStreet.Free;

    cdsTypeStreet := TClientDataSet.Create(nil);
    stXML := '<Root>AOLevel=3|guid=""</Root>';
    cdsTypeStreet.Data := frFIAS.Run.RunTaskNow('XMLProcessing',[0,0, stXML, 400]);

    if cdsTypeStreet <> nil then
      if (arTypeStreet = nil) then
         SetLength(arTypeStreet,cdsTypeStreet.RecordCount)
      else
        begin
          arTypeStreet:=nil;
          SetLength(arTypeStreet,cdsTypeStreet.RecordCount);
        end;

    cmbTypeStreet.Properties.Items.Clear;
    cdsTypeStreet.First;
    while (cdsTypeStreet.RecordCount>0) and not(cdsTypeStreet.Eof) do
    begin
      cmbTypeStreet.Properties.Items.Add(cdsTypeStreet.FieldByName('stName').AsString);
      arTypeStreet[cmbTypeStreet.Properties.Items.Count-1]:= cdsTypeStreet.FieldByName('inID').AsInteger;
      cdsTypeStreet.Next;
    end;
    if cmbTypeStreet.Properties.Items.Count>0 then
        cmbTypeStreet.ItemIndex :=-1;
  except
    on E: Exception do begin
      MessageDlg(PChar('Сообщение: ' + E.Message), mtError, [mbOk], 0);
    end;
  end;
end;

procedure TfrStreet.cmbTypeStreetPropertiesChange(Sender: TObject);
begin
    if (cmbNameStreet.Text <> '') and (cmbTypeStreet.ItemIndex <> -1) then
    begin
      cxButton1.Enabled:=True
    end;
end;

procedure TfrStreet.cmbTypeStreetPropertiesEditValueChanged(Sender: TObject);
begin
  guidTypeStreet := arTypeStreet[cmbTypeStreet.ItemIndex];
end;

procedure TfrStreet.cxButton1Click(Sender: TObject);
Var
  guid: String;
  level: Integer;
  stXML, str : String;
  cdsAdr: TClientDataSet;
begin
  if frFIAS.cxMO.ItemIndex <> -1 then
    mo:=idMO
  else mo:=-1;

   if frFIAS.cbTypeTerr.Checked=True then
    idTypeTerr:=1
  else idTypeTerr:=0;

  DateTypeTerr:=frFIAS.cxDateTerr.Date;

  if frFIAS.cxPlanStruct.ItemIndex <> -1 then
    begin
      guid:=guidPlanStruct;
      level:=65;
    end
  else
    begin
      if frFIAS.cxNasPunct.ItemIndex <> -1 then
        begin
          guid:=guidNasPunct;
          level:=6;
        end
      else
        begin
          guid:=guidCity;
          level:=0;
        end;
    end;


  if prStreet = 0 then
    stXML := '<Root>City='+guidCity+'|AOLevel='+IntToStr(level)+'|guid='+guid+'|mode='+IntToStr(flag)+'|street= |mo='+IntToStr(mo)+
              '|idTypeTerr='+IntToStr(idTypeTerr)+'|DateTerr='+DateToStr(DateTypeTerr)+'</Root>';
  if prStreet = 1 then
    stXML := '<Root>City='+guidCity+'|AOLevel='+IntToStr(level)+'|guid='+guid+'|mode='+IntToStr(flag)+'|street='+cmbNameStreet.Text+
              '|TypeStreet='+intToStr(guidTypeStreet)+'|mo='+IntToStr(mo)+
              '|idTypeTerr='+IntToStr(idTypeTerr)+'|DateTerr='+DateToStr(DateTypeTerr)+'</Root>';

  try
    cdsAdr := TClientDataSet.Create(nil);
    cdsAdr.Data := frFIAS.Run.RunTaskNow('XMLProcessing',[fmFIAS.i_street,0, stXML, 400]);

    if (cdsAdr <> nil) and (cdsAdr.RecordCount >0 ) then
      begin
        if flag=1 then
          str:='добавлена в базу данных!'
        else
          str:='изменена в базе данных!';

        if cdsAdr.FieldByName('Res').AsString = 'OK' then
          ShowMessage('Улица: '+cdsAdr.FieldByName('Street').AsString+' '+str);

        cdsAdr.Free;
        Close;
        frFIAS.Close;
      end;
        except
          on E: Exception do begin
            MessageDlg(PChar('Сообщение: ' + E.Message), mtError, [mbOk], 0);
          end;
  end;

end;

procedure TfrStreet.cxButton2Click(Sender: TObject);
begin
  Close;
end;

procedure TfrStreet.cxRadioGroup1PropertiesChange(Sender: TObject);
begin
  if cxRadioGroup1.ItemIndex = 0 then
    begin
      Panel1.Visible:=False;
      cxButton1.Enabled:=True;
      prStreet:=0;
    end
  else if cxRadioGroup1.ItemIndex = 1 then
    begin
      Panel1.Visible:=True;
      cxButton1.Enabled:=False;
      prStreet:=1;
    end;
end;

procedure TfrStreet.cxTextEdit1PropertiesChange(Sender: TObject);
begin
  if (cmbNameStreet.Text <> '') and (cmbTypeStreet.ItemIndex <> -1) then
    begin
      cxButton1.Enabled:=True
    end;
end;

end.

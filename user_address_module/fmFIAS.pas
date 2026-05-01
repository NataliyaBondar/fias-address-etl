unit fmFIAS;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, cxGraphics, StdCtrls, cxControls, cxContainer, cxEdit, cxTextEdit,
  cxMaskEdit, cxDropDownEdit, ExtCtrls, ExecuteStack, DBClient, ComCtrls, fmStreet,
  cxCalendar, cxCheckBox;

type
  TfrFIAS = class(TForm)
    pnFIAS: TPanel;
    Panel1: TPanel;
    cxMO: TcxComboBox;
    cxNasPunct: TcxComboBox;
    cxPlanStruct: TcxComboBox;
    cxStreet: TcxComboBox;
    lbCity: TLabel;
    lbMO: TLabel;
    lbNasPunct: TLabel;
    lbPlanStruct: TLabel;
    lbStreet: TLabel;
    cxCity: TcxComboBox;
    Panel2: TPanel;
    lbAddress: TLabel;
    Status: TStatusBar;
    btnOK: TButton;
    btnCancel: TButton;
    Panel3: TPanel;
    lbAdrBilling: TLabel;
    pTypeTerr: TPanel;
    cxDateTerr: TcxDateEdit;
    lbTerr: TLabel;
    Panel4: TPanel;
    Label1: TLabel;
    cbTypeTerr: TcxCheckBox;
    procedure cxCityPropertiesEditValueChanged(Sender: TObject);
    procedure cxNasPunctPropertiesEditValueChanged(Sender: TObject);
    procedure cxPlanStructPropertiesEditValueChanged(Sender: TObject);
    procedure cxCityPropertiesCloseUp(Sender: TObject);
    procedure cxPlanStructPropertiesCloseUp(Sender: TObject);
    procedure cxStreetPropertiesCloseUp(Sender: TObject);
    procedure cxStreetPropertiesEditValueChanged(Sender: TObject);
    procedure cxNasPunctPropertiesCloseUp(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure cxCityKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure cxNasPunctKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure cxPlanStructKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure cbTypeTerrPropertiesChange(Sender: TObject);
    procedure cxMOPropertiesCloseUp(Sender: TObject);
    procedure cxMOPropertiesEditValueChanged(Sender: TObject);
  private
    { Private declarations }
    cdsResult: TClientDataSet;
  public
    { Public declarations }
   // i_street  : integer;
    Run: TRunStack;
    procedure LoadCity;
    procedure LoadMO;
    procedure LoadNasPunct(guidCity: String);
    procedure LoadPlanStruct(guidCity: String);
    procedure LoadStreet(guidCity: String);
    procedure LoadAddress(guid: String);
    procedure LoadAddressUpdate(inId: integer);
    function FindElement(mas: array of String; str: String):Integer;
    function FindElementInt(mas: array of Integer; str: Integer):Integer;
  end;

var
  frFIAS: TfrFIAS;
  RunMethod: TRunStack;

  cdsCity: TClientDataSet;
  cdsMO: TClientDataSet;
  cdsNasPunct: TClientDataSet;
  cdsPlanStruct: TClientDataSet;
  cdsStreet: TClientDataSet;
  cdsAddress: TClientDataSet;
  cdsAddressUpdate: TClientDataSet;

  arCity: array of String;
  arMO: array of Integer;
  arNasPunct: array of String;
  arPlanStruct: array of String;
  arStreet: array of String;

  guidCity: String;
  idMO: Integer;
  idTypeTerr: Integer;
  DateTypeTerr: TDateTime;
  guidNasPunct: String;
  guidPlanStruct: String;
  guidStreet: String;
  flag:Integer;

  i_street: Integer;
  mo: Integer;


implementation

{$R *.dfm}
procedure TfrFIAS.LoadCity;
var
  stXML : String;
begin
  try
    if cdsCity <> nil then
      cdsCity.Free;

    cdsCity := TClientDataSet.Create(nil);
    stXML := '<Root>AOLevel=0|guid=""</Root>';
    cdsCity.Data := Run.RunTaskNow('XMLProcessing',[0,0, stXML, 400]);

    if cdsCity <> nil then
      if (arCity = nil) then
         SetLength(arCity,cdsCity.RecordCount)
      else
        begin
          arCity:=nil;
          SetLength(arCity,cdsCity.RecordCount);
        end;

    cxCity.Properties.Items.Clear;
    cdsCity.First;
    while (cdsCity.RecordCount>0) and not(cdsCity.Eof) do
    begin
      cxCity.Properties.Items.Add(cdsCity.FieldByName('stName').AsString);
      arCity[cxCity.Properties.Items.Count-1]:= cdsCity.FieldByName('inGUID').AsString;
      cdsCity.Next;
    end;

    LoadMO;
  //  if cxCity.Properties.Items.Count>0 then
  //      cxCity.ItemIndex :=-1;
  except
    on E: Exception do begin
      MessageDlg(PChar('Сообщение: ' + E.Message), mtError, [mbOk], 0);
    end;
  end;
end;

function TfrFIAS.FindElement(mas: array of String; str: String):Integer;
var
  i:Integer;
begin
  result:=-1;
  for i := 0 to length(mas) - 1 do
  begin
    if str = mas[i] then
      result:=i;
  end;
end;

function TfrFIAS.FindElementInt(mas: array of Integer; str: Integer):Integer;
var
  i:Integer;
begin
  result:=-1;
  for i := 0 to length(mas) - 1 do
  begin
    if str = mas[i] then
      result:=i;
  end;
end;

procedure TfrFIAS.LoadAddressUpdate(inId: integer);
var
  stXML : String;
  i: Integer;
begin
  try
    if cdsAddressUpdate <> nil then
      cdsAddressUpdate.Free;

    cdsAddressUpdate := TClientDataSet.Create(nil);
    stXML := '<Root>AOLevel=0|guid=""</Root>';
    cdsAddressUpdate.Data := Run.RunTaskNow('XMLProcessing',[inId,1, stXML, 400]);

    if cdsAddressUpdate <> nil then
      begin
        lbAdrBilling.Caption:='Выбран адрес:   '+ cdsAddressUpdate.FieldByName('inAddress').AsString;
        lbAdrBilling.Visible:= True;
        LoadCity;
        cxCity.Text:=cdsAddressUpdate.FieldByName('stNameCity').AsString;
        guidCity:= cdsAddressUpdate.FieldByName('inGuidCity').AsString;
        cxCity.Enabled:=False;

        guidPlanStruct:= cdsAddressUpdate.FieldByName('inGuidPlanStruct').AsString;
        guidNasPunct:= cdsAddressUpdate.FieldByName('inGuidNasPunct').AsString;
        guidStreet:= cdsAddressUpdate.FieldByName('inGuidStreet').AsString;
        IdMO:= cdsAddressUpdate.FieldByName('inIdMO').AsInteger;
        IdTypeTerr:= cdsAddressUpdate.FieldByName('inIdTypeTerr').AsInteger;
        DateTypeTerr:= cdsAddressUpdate.FieldByName('inDateTerr').AsDateTime;

        if IdTypeTerr = 0 then
        begin
          cbTypeTerr.Caption:='Отключено';
          cbTypeTerr.Style.TextColor:=clBlue;
          cbTypeTerr.Checked:=False;
        end
        else
        begin
          cbTypeTerr.Caption:='Установлено';
          cbTypeTerr.Style.TextColor:=clTeal;
          cbTypeTerr.Checked:=True;
        end;


        LoadMO;
        cxMO.Enabled:=True;
        if IdMO <> 0 then
          cxMO.ItemIndex:=FindElementInt(arMO, IdMO);

        LoadNasPunct(guidCity);
        cxNasPunct.Enabled:=True;
        status.SimpleText:='...';

        if guidNasPunct <> '' then
          begin
            cxNasPunct.ItemIndex:=FindElement(arNasPunct, guidNasPunct);
            if cxNasPunct.ItemIndex <> -1 then
              begin
                LoadPlanStruct(guidNasPunct);
                LoadAddress(guidNasPunct);
              end
            else
              begin
                LoadPlanStruct(guidCity);
                LoadAddress(guidCity);
              end;
          end
        else
          begin
             LoadPlanStruct(guidCity);
             LoadAddress(guidCity);
          end;

        if guidPlanStruct <> '' then
          begin
            cxPlanStruct.ItemIndex:=FindElement(arPlanStruct, guidPlanStruct);
            if cxPlanStruct.ItemIndex <> -1 then
              begin
                LoadStreet(guidPlanStruct);
                LoadAddress(guidPlanStruct);
              end
            else
              begin
                if cxNasPunct.ItemIndex <> -1 then
                  begin
                     LoadStreet(guidNasPunct);
                     LoadAddress(guidNasPunct);
                  end
                else
                  begin
                    LoadStreet(guidCity);
                    LoadAddress(guidCity);
                  end;
              end;
          end
        else
          begin
            if cxNasPunct.ItemIndex <> -1 then
              begin
                LoadStreet(guidNasPunct);
                LoadAddress(guidNasPunct);
              end
            else
              begin
                LoadStreet(guidCity);
                LoadAddress(guidCity);
              end;
          end;

        if guidStreet <> '' then
          cxStreet.ItemIndex:=FindElement(arStreet, guidStreet);
          if cxStreet.ItemIndex <> -1 then
            LoadAddress(guidStreet);

        status.SimpleText:='...';    
        cxNasPunct.SelStart := length(cxNasPunct.Text);
        cxPlanStruct.Enabled:=True;
        cxPlanStruct.SelStart := length(cxPlanStruct.Text);
        cxStreet.Enabled:=True;
        cxStreet.SelStart := length(cxStreet.Text);
      end;
  except
    on E: Exception do begin
      MessageDlg(PChar('Сообщение: ' + E.Message), mtError, [mbOk], 0);
    end;
  end;
end;

procedure TfrFIAS.LoadMO;
var
  stXML : String;
begin
  try
  if cdsMO <> nil then
      cdsMO.Free;

    cdsMO := TClientDataSet.Create(nil);
    stXML := '<Root>AOLevel=1|guid=""</Root>';
    cdsMO.Data := Run.RunTaskNow('XMLProcessing',[0,0, stXML, 400]);

    if cdsMO <> nil then
      if (arMO = nil) then
      SetLength(arMO,cdsMO.RecordCount)
    else
      begin
        arMO:=nil;
        SetLength(arMO,cdsMO.RecordCount);
      end;

    cxMO.Properties.Items.Clear;
    cdsMO.First;
    while (cdsMO.RecordCount>0) and not(cdsMO.Eof) do
    begin
      cxMO.Properties.Items.Add(cdsMO.FieldByName('stName').AsString);
      arMO[cxMO.Properties.Items.Count-1]:= cdsMO.FieldByName('inID').AsInteger;
      cdsMO.Next;
    end;
 //   if cxMO.Properties.Items.Count>0 then
 //       cxMO.ItemIndex := -1;
  except
    on E: Exception do begin
      MessageDlg(PChar('Сообщение: ' + E.Message), mtError, [mbOk], 0);
    end;
  end;
end;

procedure TfrFIAS.LoadNasPunct(guidCity: String);
var
  stXML : String;
begin
  try
    if cdsNasPunct <> nil then
      cdsNasPunct.Free;

    cdsNasPunct := TClientDataSet.Create(nil);
    stXML := '<Root>AOLevel=6|guid='+guidCity+'</Root>';
    cdsNasPunct.Data := Run.RunTaskNow('XMLProcessing',[0,0, stXML, 400]);

    if cdsNasPunct <> nil then
      if (arNasPunct = nil) then
      SetLength(arNasPunct,cdsNasPunct.RecordCount)
    else
      begin
        arNasPunct:=nil;
        SetLength(arNasPunct,cdsNasPunct.RecordCount);
      end;

    frFIAS.cxNasPunct.Properties.Items.Clear;
    cdsNasPunct.First;
    while (cdsNasPunct.RecordCount>0) and not(cdsNasPunct.Eof) do
    begin
      cxNasPunct.Properties.Items.Add(cdsNasPunct.FieldByName('stName').AsString);
      arNasPunct[cxNasPunct.Properties.Items.Count-1]:= cdsNasPunct.FieldByName('inGUID').AsString;
      cdsNasPunct.Next;
    end;
//    if frFIAS.cxNasPunct.Properties.Items.Count>0 then
//        frFIAS.cxNasPunct.ItemIndex := -1;
  except
    on E: Exception do begin
      MessageDlg(PChar('Сообщение: ' + E.Message), mtError, [mbOk], 0);
    end;
  end;
end;

procedure TfrFIAS.LoadPlanStruct(guidCity: String);
var
  stXML : String;
begin
  try
    if cdsPlanStruct <> nil then
      cdsPlanStruct.Free;

    cdsPlanStruct := TClientDataSet.Create(nil);
    stXML := '<Root>AOLevel=65|guid='+guidCity+'</Root>';
    cdsPlanStruct.Data := Run.RunTaskNow('XMLProcessing',[0,0, stXML, 400]);

    if cdsPlanStruct <> nil then
      if (arPlanStruct = nil) then
      SetLength(arPlanStruct,cdsPlanStruct.RecordCount)
    else
      begin
        arPlanStruct:=nil;
        SetLength(arPlanStruct,cdsPlanStruct.RecordCount);
      end;

    frFIAS.cxPlanStruct.Properties.Items.Clear;
    cdsPlanStruct.First;
    while (cdsPlanStruct.RecordCount>0) and not(cdsPlanStruct.Eof) do
    begin
      cxPlanStruct.Properties.Items.Add(cdsPlanStruct.FieldByName('stName').AsString);
      arPlanStruct[cxPlanStruct.Properties.Items.Count-1]:= cdsPlanStruct.FieldByName('inGUID').AsString;
      cdsPlanStruct.Next;
    end;
 //   if frFIAS.cxPlanStruct.Properties.Items.Count>0 then
 //       frFIAS.cxPlanStruct.ItemIndex := -1;
  except
    on E: Exception do begin
      MessageDlg(PChar('Сообщение: ' + E.Message), mtError, [mbOk], 0);
    end;
  end;
end;

procedure TfrFIAS.LoadStreet(guidCity: String);
var
  stXML : String;
begin
  try
    if cdsStreet <> nil then
      cdsStreet.Free;

    cdsStreet := TClientDataSet.Create(nil);
    stXML := '<Root>AOLevel=7|guid='+guidCity+'</Root>';
    cdsStreet.Data := Run.RunTaskNow('XMLProcessing',[0,0, stXML, 400]);

    if cdsStreet <> nil then
      if (arStreet = nil) then
      SetLength(arStreet,cdsStreet.RecordCount)
    else
      begin
        arStreet:=nil;
        SetLength(arStreet,cdsStreet.RecordCount);
      end;

    frFIAS.cxStreet.Properties.Items.Clear;
    cdsStreet.First;
    while (cdsStreet.RecordCount>0) and not(cdsStreet.Eof) do
    begin
      cxStreet.Properties.Items.Add(cdsStreet.FieldByName('stName').AsString);
      arStreet[cxStreet.Properties.Items.Count-1]:= cdsStreet.FieldByName('inGUID').AsString;
      cdsStreet.Next;
    end;
 //   if frFIAS.cxStreet.Properties.Items.Count>0 then
 //       frFIAS.cxStreet.ItemIndex := -1;
  except
    on E: Exception do begin
      MessageDlg(PChar('Сообщение: ' + E.Message), mtError, [mbOk], 0);
    end;
  end;
end;

procedure TfrFIAS.LoadAddress(guid: String);
var
  stXML : String;
begin
  try
    if cdsAddress <> nil then
      cdsAddress.Free;

    cdsAddress := TClientDataSet.Create(nil);
    stXML := '<Root>AOLevel=2|guid='+guid+'</Root>';
    cdsAddress.Data := Run.RunTaskNow('XMLProcessing',[0,0, stXML, 400]);

    if cdsAddress <> nil then
    begin
        lbAddress.Caption:= cdsAddress.FieldByName('stName').AsString;
        lbAddress.Visible:=True;
    end;
  except
    on E: Exception do begin
      MessageDlg(PChar('Сообщение: ' + E.Message), mtError, [mbOk], 0);
    end;
  end;
end;

procedure TfrFIAS.btnCancelClick(Sender: TObject);
begin
    Close;
end;

procedure TfrFIAS.btnOKClick(Sender: TObject);
var
  guid: String;
  level: Integer;
  stXML : String;
  cdsAdr: TClientDataSet;
  Str: String;
begin
//  ShowMessage(IntToStr(cxCity.ItemIndex)+' '+IntToStr(cxNasPunct.ItemIndex)+' '+IntToStr(cxPlanStruct.ItemIndex)+' '+IntToStr(cxStreet.ItemIndex));
//  ShowMessage(IntToStr(i_street));
  if cxMO.ItemIndex <> -1 then
    mo:=idMO
  else mo:=-1;

  if cbTypeTerr.Checked=True then
    idTypeTerr:=1
  else idTypeTerr:=0;

  DateTypeTerr:=cxDateTerr.Date;

  if cxCity.ItemIndex <> -1 then
    begin
      if ((cxNasPunct.ItemIndex = -1) and (cxNasPunct.Text <> ''))
          OR ((cxPlanStruct.ItemIndex = -1) and (cxPlanStruct.Text <> '')) then

             ShowMessage('Введеный населенный пункт или планировочная структура, отсутствует в ФИАС. Адрес не будет добавлен.')
      else
    if cxStreet.ItemIndex <> -1 then
      begin
        guid:=guidStreet;
        level:=7;
 //showmessage(IntToStr(idTypeTerr)+'    '+DateToStr(DateTypeTerr));
        stXML := '<Root>AOLevel='+IntToStr(level)+'|guid='+guid+'|mode='+IntToStr(flag)+'|mo='+IntToStr(mo)+
                  '|idTypeTerr='+IntToStr(idTypeTerr)+'|DateTerr='+DateToStr(DateTypeTerr)+'</Root>';

        try
          cdsAdr := TClientDataSet.Create(nil);
          cdsAdr.Data := Run.RunTaskNow('XMLProcessing',[i_street,0, stXML, 400]);

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
            end;
          except
            on E: Exception do begin
              MessageDlg(PChar('Сообщение: ' + E.Message), mtError, [mbOk], 0);
            end;
        end;
      end
    else
      begin
          frStreet.LoadTypeStreet;
          frStreet.ShowModal;
      end
    end
  else
    ShowMessage('Введена не вся информация. Заполните данные.')
end;

procedure TfrFIAS.cbTypeTerrPropertiesChange(Sender: TObject);
begin
if cbTypeTerr.Checked = False then
  begin
    cbTypeTerr.Caption:='Отключено';
    cbTypeTerr.Style.TextColor:=clBlue;
    lbTerr.Caption:='Укажите дату окончания действия';
    cxDateTerr.Date:=Date;
    pTypeTerr.Visible:=True;
  end
else
  begin
    cbTypeTerr.Caption:='Установлено';
    cbTypeTerr.Style.TextColor:=clTeal;
    lbTerr.Caption:='Укажите дату начала действия';
    cxDateTerr.Date:=DateTypeTerr;
    pTypeTerr.Visible:=True;
  end;
end;

procedure TfrFIAS.cxCityKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
if ((Key = (VK_DELETE)) or (Key = (VK_BACK))) and (cxCity.Text = '') then
  begin
   cxMO.Enabled:=False;
   cxNasPunct.Enabled:=False;
   cxPlanStruct.Enabled:=False;
   cxStreet.Enabled:=False;

   cxMO.Text:='';
   cxNasPunct.Text:='';
   cxPlanStruct.Text:='';
   cxStreet.Text:='';

   lbAddress.Caption:='';
   lbAddress.Visible:=False;
   btnOK.Enabled:=False;
  end;
end;

procedure TfrFIAS.cxCityPropertiesCloseUp(Sender: TObject);
begin
  if cxCity.ItemIndex > -1 then
  begin
      loadNasPunct(guidCity);
      loadPlanStruct(guidCity);
      loadStreet(guidCity);

      cxNaspunct.Text:='';
      cxPlanStruct.Text:='' ;
      cxStreet.Text:='';

      LoadAddress(guidCity);
      cxNaspunct.Enabled:=True;
      cxNasPunct.SetFocus;
      cxPlanStruct.Enabled:=True;
      cxStreet.Enabled:=True;
      cxMO.Enabled:=True;
      status.SimpleText:='...';

      btnOK.Enabled:=True;
  end;
end;

procedure TfrFIAS.cxCityPropertiesEditValueChanged(Sender: TObject);
begin
  if cxCity.ItemIndex > -1 then
  begin
      status.SimpleText:='Подождите, идет загрузка данных...';
      guidCity := arCity[cxCity.ItemIndex];
      cxCity.SelStart := length(cxCity.Text);
  end;
end;

procedure TfrFIAS.cxMOPropertiesCloseUp(Sender: TObject);
begin
  if cxMO.ItemIndex > -1 then
  begin
      status.SimpleText:='...';
      btnOK.Enabled:=True;
  end;
end;

procedure TfrFIAS.cxMOPropertiesEditValueChanged(Sender: TObject);
begin
  if cxMO.ItemIndex > -1 then
  begin
      status.SimpleText:='Подождите, идет загрузка данных...';
      idMO := arMO[cxMO.ItemIndex];
      cxMO.SelStart := length(cxMO.Text);
  end;
end;

procedure TfrFIAS.cxNasPunctKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
if ((Key = (VK_DELETE)) or (Key = (VK_BACK))) and (cxNasPunct.Text = '') then
  begin
    loadPlanStruct(guidCity);
    loadStreet(guidCity);
    LoadAddress(guidCity);
    cxPlanStruct.Text:='';
    cxStreet.Text:='';
  end;
end;

procedure TfrFIAS.cxNasPunctPropertiesCloseUp(Sender: TObject);
begin
  if cxNasPunct.ItemIndex > -1 then
  begin
      cxPlanStruct.SetFocus;
      loadPlanStruct(guidNasPunct);
      loadStreet(guidNasPunct);
      LoadAddress(guidNasPunct);
      cxPlanStruct.Text:='' ;
      cxStreet.Text:='';
      status.SimpleText:='...';
      btnOK.Enabled:=True;
  end;
end;

procedure TfrFIAS.cxNasPunctPropertiesEditValueChanged(Sender: TObject);
begin
  if cxNasPunct.ItemIndex > -1 then
  begin
      status.SimpleText:='Подождите, идет загрузка данных...';
      guidNasPunct := arNasPunct[cxNasPunct.ItemIndex];
      cxNasPunct.SelStart := length(cxNasPunct.Text);
  end;
end;

procedure TfrFIAS.cxPlanStructKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
if ((Key = (VK_DELETE)) or (Key = (VK_BACK))) and (cxPlanStruct.Text = '') then
  begin
    if (guidPlanStruct<>'') and (cxPlanStruct.ItemIndex <> -1) then
      begin
        status.SimpleText:='Подождите, идет загрузка данных...';
        cxNasPunct.Enabled:=False;
        cxPlanStruct.Enabled:=False;
        cxStreet.Enabled:=False;
        loadPlanStruct(guidNasPunct);
        loadStreet(guidNasPunct);
        LoadAddress(guidNasPunct);
        status.SimpleText:='...';
        cxNasPunct.Enabled:=True;
        cxPlanStruct.Enabled:=True;
        cxStreet.Enabled:=True;
      end
    else
      begin
        status.SimpleText:='Подождите, идет загрузка данных...';
        cxNasPunct.Enabled:=False;
        cxPlanStruct.Enabled:=False;
        cxStreet.Enabled:=False;
        loadPlanStruct(guidCity);
        loadStreet(guidCity);
        LoadAddress(guidCity);
        status.SimpleText:='...';
        cxNasPunct.Enabled:=True;
        cxPlanStruct.Enabled:=True;
        cxStreet.Enabled:=True;
      end;
    cxStreet.Text:='';
  end;
end;

procedure TfrFIAS.cxPlanStructPropertiesCloseUp(Sender: TObject);
begin
  if cxPlanStruct.ItemIndex > -1 then
  begin
      cxStreet.SetFocus;
      loadStreet(guidPlanStruct);
      LoadAddress(guidPlanStruct);
      cxStreet.Text:='';
      status.SimpleText:='...';
      btnOK.Enabled:=True;
  end;
end;

procedure TfrFIAS.cxPlanStructPropertiesEditValueChanged(Sender: TObject);
begin
  if cxPlanStruct.ItemIndex > -1 then
  begin
      status.SimpleText:='Подождите, идет загрузка данных...';
      guidPlanStruct := arPlanStruct[cxPlanStruct.ItemIndex];
      cxPlanStruct.SelStart := length(cxPlanStruct.Text);
  end;
end;

procedure TfrFIAS.cxStreetPropertiesCloseUp(Sender: TObject);
begin
  if cxStreet.ItemIndex > -1 then
  begin
      cxMO.SetFocus;
      LoadAddress(guidStreet);
      status.SimpleText:='...';
      btnOK.Enabled:=True;
  end;
end;

procedure TfrFIAS.cxStreetPropertiesEditValueChanged(Sender: TObject);
begin
  if cxStreet.ItemIndex > -1 then
  begin
      status.SimpleText:='Подождите, идет загрузка данных...';
      guidStreet := arStreet[cxStreet.ItemIndex];
      cxStreet.SelStart := length(cxStreet.Text);
  end;
end;

end.

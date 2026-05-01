unit Main;

interface

uses  Forms,sysutils, fmFIAS, Dialogs, DbClient, Variants,
      PIClasses, ExecuteStack, Windows, fmStreet;

function FuncAddStreet (inContext: integer; tvParentObj: TDBObject; tvObj: TDBObject; ptData: OleVariant; inIndex: integer): integer; stdcall; export;
function FuncUpdateStreet (inContext: integer; tvParentObj: TDBObject; tvObj: TDBObject; ptData: OleVariant; inIndex: integer): integer; stdcall; export;

function InitUserDll(
            inHandle: integer;
            Run: TRunStack): integer; stdcall; export;

function DestroyUserDll: integer; stdcall; export;

function SetData(inDataType: integer; ptData: pointer): integer; stdcall; export;
function GetData(inDataType: integer; ptData: pointer): integer; stdcall; export;
function GetOleData(inDataType: integer): OleVariant; stdcall; export;

var
  RunMethod: TRunStack;
  App: TRunStack;
  AppHandle: integer;
  Context: integer;
  ixPlugin : Integer;
  w_Handle : Integer;
  TmpFindData : OleVariant;

implementation

uses DB, cxDropDownEdit, Classes;

function InitUserDll(
            inHandle: integer;
            Run: TRunStack): integer; stdcall; export;
begin
  RunMethod := Run;
  Application.Handle := inHandle;
  Result:=0;
end;


function DestroyUserDll: integer; stdcall; export;
begin
  Application.Handle := 0;
  result:=0;
end;

function GetData(inDataType: integer; ptData: pointer): integer; stdcall; export;
var
  item: PAddMenu;
begin
  Result := -1;
  if inDataType = pvm_MenuName then begin
    if ptData = nil then
      result := 2
    else begin
      item := ptData;
      item.stMenu := 'ФИАС/Добавление улицы';
      item.stFunction := 'FuncAddStreet';
      inc(item);
      item.stMenu := 'ФИАС/Изменение улицы';
      item.stFunction := 'FuncUpdateStreet';
    end;
  end;

  if inDataType = pvm_GetInfo Then Begin
     if ptData = nil then
      result := 2
    else begin
      item := ptData;
      item.stMenu := 'Добавление улицы';
      item.inImage := 0;
      inc(item);
      item.stMenu := 'Изменение улицы';
    end;
  end;
end;

function GetOleData(inDataType: integer): OleVariant; stdcall; export;
begin
  if inDataType = pvm_GetFindData then begin
    result := TmpFindData;
  end
  else result := null;
end;

function SetData(inDataType: integer; ptData: pointer): integer; stdcall; export;
var
  item: PAddMenu;
  NewObjID, NewTypeObj : Integer;

begin
  if inDataType = pvm_Index then ixPlugin := Integer(ptData);
  if inDataType = pvm_WHandle then w_Handle := Integer(ptData);
  Result:=0;
end;

function FuncAddStreet (inContext: integer; tvParentObj: TDBObject; tvObj: TDBObject; ptData: OleVariant; inIndex: integer): integer; stdcall; export;
var
  oleData : OleVariant;
  stError : String; inRes : Integer;
  ix : Integer;
  stXML : String;
begin
  Context := inContext;
    try
      try
        frFIAS:=TfrFIAS.Create(nil);
        frFIAS.Run := RunMethod;
        frStreet:= TfrStreet.Create(nil);
       // frStreet.RunStreet := RunMethod;

        frFIAS.status.SimpleText:='...';
        frFIAS.Caption:='Добавление улицы';
        frFIAS.btnOK.Caption:='Добавить улицу';
        fmFIAS.flag:=1;
        fmFIAS.i_street:=0;
        frFIAS.LoadCity();

        frFIAS.cxMO.Enabled:=False;
        frFIAS.cxNasPunct.Enabled:=False;
        frFIAS.cxPlanStruct.Enabled:=False;
        frFIAS.cxStreet.Enabled:=False;

        frFIAS.ShowModal;
      except
        on E: Exception do begin
          MessageDlg(e.Message, mtError, [mbOK], 0);
        end;
      end;
    finally
      frFIAS.Free;
      frStreet.Free;
    end;
end;

function FuncUpdateStreet (inContext: integer; tvParentObj: TDBObject; tvObj: TDBObject; ptData: OleVariant; inIndex: integer): integer; stdcall; export;
var
  oleData : OleVariant;
  stError : String; inRes : Integer;
  ix : Integer;
  stXML : String;
begin
  Context := inContext;
   if (tvObj=nil)or((tvObj<>nil)and(tvObj.inType<>1)) then
    MessageBoxEx(Application.Handle,
         Pchar('Нужно выбрать Улицу!'),
              Pchar('Ошибка!'),MB_OK+MB_ICONWARNING,0)
  else
    try
      try
        frFIAS:=TfrFIAS.Create(nil);
        frFIAS.Run := RunMethod;
        frFIAS.status.SimpleText:='...';
        frFIAS.Caption:='Изменение улицы';
        frFIAS.btnOK.Caption:='Изменить улицу';
        fmFIAS.flag:=2;
        fmFIAS.i_street:=tvObj.inID;
        frFIAS.LoadAddressUpdate(fmFIAS.i_street);
        frFIAS.btnOK.Enabled:=True;

        frStreet:= TfrStreet.Create(nil);
        frFIAS.ShowModal;
      except
        on E: Exception do begin
          MessageDlg(e.Message, mtError, [mbOK], 0);
        end;
      end;
    finally
      frFIAS.Free;
    end;
end;

end.

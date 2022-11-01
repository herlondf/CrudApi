unit Cliente.DAO;

interface

uses
  System.SysUtils, System.StrUtils, System.Math, System.JSON, Server.Status,
  Cliente.Entity, Cliente.DAO.Contract, KrkConnection.Core, GBJSON.Helper,
  GBJSON.Interfaces;

type
  TClienteDAO = class(TInterfacedObject, iClienteDAO)
    constructor Create;
    destructor Destroy; override;
    class function New: iClienteDAO;
  private
    FClientes: TClientes;

    function IsValidId(const AId: Integer): Boolean;
    function IsValidCliente(ACliente: TCliente): Boolean;
  public
    function Find(const AId: String; AStatuscode: Integer): string;
    function FindAll(AStatuscode: Integer): string;
    function Insert(const ACliente: String; AStatuscode: Integer): String;
    function Update(const ACliente: String; AStatuscode: Integer): string;
    function Delete(const AId: string; AStatuscode: Integer): string;
  end;


implementation

{ TClienteDAO }

constructor TClienteDAO.Create;
begin
  FClientes := TClientes.Create;
end;

destructor TClienteDAO.Destroy;
begin
  FreeAndNil(FClientes);
  inherited;
end;

class function TClienteDAO.New: iClienteDAO;
begin
  Result := Self.Create;
end;

function TClienteDAO.IsValidId(const AId: Integer): Boolean;
begin
  Result := AId <> -1;
end;

function TClienteDAO.IsValidCliente(ACliente: TCliente): Boolean;
begin
  Result := (not ACliente.Nome.IsEmpty)
end;

function TClienteDAO.Find(const AId: String; AStatuscode: Integer): string;
var
  LJson: TJSONArray;
begin
  Result := '';
  FClientes.Clear;

  if not IsValidId(StrToIntDef(AId, -1)) then
  begin
    AStatuscode := BAD_REQUEST;
    Exit;
  end;

  TKrakenCore.DefaultManager
    .TryGetProvider(
      procedure(AConnection: TKrakenProvider)
      begin
        with AConnection.Query do
        begin
          try
            SQL.Clear;
            SQL.Add('SELECT * FROM cliente WHERE id = :id');
            ParamByName('id').AsInteger := StrToInt(AId);
            Open;

            while not eof do
            begin
              with FClientes.Items[FClientes.Add(TCliente.New)] do
              begin
                Id := FieldByName('id').AsInteger;
                Nome := FieldByName('nome').AsString;
              end;

              Next;
            end;

            if FClientes.Count > 0 then
              AStatuscode := SUCCESS
            else
              AStatuscode := NOT_FOUND;

            Close;
          except
            AStatuscode := INTERNAL_ERROR;
            raise;
          end;
        end;
      end
    );

  LJson := TGBJSONDefault.Deserializer<TCliente>.ListToJSONArray(FClientes);

  Result := LJson.ToJSON;
  LJson.Free;
end;

function TClienteDAO.FindAll(AStatuscode: Integer): string;
var
  LJson: TJSONArray;
begin
  Result := '';
  FClientes.Clear;

  TKrakenCore.DefaultManager
    .TryGetProvider(
      procedure(AConnection: TKrakenProvider)
      begin
        with AConnection.Query do
        begin
          try
            SQL.Clear;
            SQL.Add('SELECT * FROM cliente');
            Open;

            while not eof do
            begin
              with FClientes.Items[FClientes.Add(TCliente.New)] do
              begin
                Id := FieldByName('id').AsInteger;
                Nome := FieldByName('nome').AsString;
              end;

              Next;
            end;

            if FClientes.Count > 0 then
              AStatuscode := SUCCESS
            else
              AStatuscode := NOT_FOUND;

            Close;
          except
            AStatuscode := INTERNAL_ERROR;
            raise;
          end;
        end;
      end
    );

  LJson := TGBJSONDefault.Deserializer<TCliente>.ListToJSONArray(FClientes);

  Result := LJson.ToJSON;
  LJson.Free;
end;

function TClienteDAO.Insert(const ACliente: String; AStatuscode: Integer): String;
var
  LCliente: TCliente;
begin
  Result   := '';

  LCliente := TGBJSONDefault.Serializer<TCliente>.JsonStringToObject(ACliente);

  if not IsValidCliente(LCliente) then
  begin
    AStatuscode := BAD_REQUEST;
    Exit;
  end;


  TKrakenCore.DefaultManager
    .TryGetProvider(
      procedure(AConnection: TKrakenProvider)
      begin
        with AConnection.Query do
        begin
          SQL.Clear;
          SQL.Add('SELECT MAX( COALESCE(id, 1) )+1 id FROM cliente');
          Open;

          LCliente.Id := FieldByName('id').AsInteger;

          SQL.Clear;
          SQL.Add(
            'INSERT INTO cliente(  ' +
            '  id,                 ' +
            '  nome                ' +
            ')                     ' +
            'VALUES(               ' +
            '  :id,                ' +
            '  :nome               ' +
            ')                     '
          );

          ParamByName('id').AsInteger := LCliente.Id;
          ParamByName('nome').AsString  := LCliente.Nome;

          try
            ExecSQL;
            Close;

            AStatuscode := SUCCESS;
          except
            AStatuscode := INTERNAL_ERROR;

            Close;
            LCLiente.Free;
            raise;
          end;
        end;
      end
    );

  Result := LCliente.ToJSONString;
  LCliente.Free;
end;

function TClienteDAO.Update(const ACliente: String; AStatuscode: Integer): string;
var
  LCliente: TCliente;
begin
  Result   := '';
  LCliente := TGBJSONDefault.Serializer<TCliente>.JsonStringToObject(ACliente);

  if not IsValidCliente(LCliente) then
  begin
    AStatuscode := BAD_REQUEST;
    Exit;
  end;

  TKrakenCore.DefaultManager
    .TryGetProvider(
      procedure(AConnection: TKrakenProvider)
      begin
        with AConnection.Query do
        begin
          try
            SQL.Clear;
            SQL.Add(
              'UPDATE cliente       ' +
              'SET    nome = :nome  ' +
              'WHERE  id = :id      '
            );

            ParamByName('id').AsInteger := LCliente.Id;
            ParamByName('nome').AsString  := LCliente.Nome;

            ExecSQL;
            Close;

            AStatuscode := SUCCESS;
          except
            AStatuscode := INTERNAL_ERROR;

            Close;
            LCLiente.Free;
            raise;
          end;
        end;
      end
    );

  Result := LCliente.ToJSONString;
  LCliente.Free;
end;

function TClienteDAO.Delete(const AId: string; AStatuscode: Integer): string;
begin
  Result := '';

  if not IsValidId(StrToIntDef(AId, -1)) then
  begin
    AStatuscode := BAD_REQUEST;
    Exit;
  end;

  TKrakenCore.DefaultManager
    .TryGetProvider(
      procedure(AConnection: TKrakenProvider)
      begin
        with AConnection.Query do
        begin
          try
            SQL.Clear;
            SQL.Add(
              'DELETE            ' +
              'FROM   cliente    ' +
              'WHERE  id = :id   '
            );

            ParamByName('id').AsInteger := StrToIntDef(AId, -1);

            ExecSQL;
            Close;

            AStatuscode := SUCCESS;
          except
            AStatuscode := INTERNAL_ERROR;

            Close;
            raise;
          end;
        end;
      end
    );
end;

end.

unit KrkConnection.Provider.Types;

interface

uses
  System.SysUtils,
  System.Classes,
  FireDAC.Comp.Client,
  FireDAC.Phys.PGDef,
  FireDAC.Phys,
  FireDAC.Phys.PG,
  FireDAC.Phys.FBDef,
  FireDAC.Phys.IBBase,
  FireDAC.Phys.FB,
  FireDAC.Phys.Intf,
  FireDAC.Stan.ExprFuncs,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.Intf,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.MySQLDef,
  FireDAC.Phys.MySQL;

type
  TKrakenProviderTypes<T: class, constructor> = class
  private
    FReturn: T;
    FDriver: TComponent;

    FConnection: TFDConnection;

    destructor Destroy; override;
  public
    constructor Create(AOwner: T);

    function Postgres: T;
    function Firebird: T;
    function MySQL   : T;
    function SQLite  : T;
  end;

implementation

{ TKrakenProviderTypes }

constructor TKrakenProviderTypes<T>.Create(AOwner: T);
begin
  FReturn     := AOwner;
  FConnection := TFDConnection(AOwner);
end;

destructor TKrakenProviderTypes<T>.Destroy;
begin
  if Assigned(FDriver) then
    FreeAndNil(FDriver);

  inherited;
end;

function TKrakenProviderTypes<T>.Postgres: T;
begin
  Result := FReturn;

  if Assigned(FDriver) then Exit;
  FDriver := TFDPhysPgDriverLink.Create(FConnection);
  TFDPhysPgDriverLink(FDriver).Name := 'PGDriver';
  TFDPhysPgDriverLink(FDriver).VendorLib := 'libpq.dll';
  FConnection.DriverName := 'PG';
end;

function TKrakenProviderTypes<T>.Firebird: T;
begin
  Result := FReturn;

  if Assigned(FDriver) then Exit;
  FDriver := TFDPhysFBDriverLink.Create(FConnection);
  TFDPhysFBDriverLink(FDriver).Name := 'FBDriver';
  FConnection.DriverName := 'FB';
end;

function TKrakenProviderTypes<T>.MySQL: T;
begin
  Result := FReturn;

  if Assigned(FDriver) then Exit;
  FDriver := TFDPhysMySQLDriverLink.Create(FConnection);
  TFDPhysMySQLDriverLink(FDriver).Name := 'MySQLDriver';
  TFDPhysMySQLDriverLink(FDriver).VendorLib := 'libmysql.dll';
  FConnection.DriverName := 'MySQL';
end;

function TKrakenProviderTypes<T>.SQLite: T;
begin
  Result := FReturn;

  if Assigned(FDriver) then Exit;
  FDriver := TFDPhysSQLiteDriverLink.Create(FConnection);
  TFDPhysSQLiteDriverLink(FDriver).Name := 'SQLite';
  FConnection.DriverName := 'SQLite';
end;

end.

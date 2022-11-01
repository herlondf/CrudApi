unit KrkConnection.Provider.Firedac;

interface

uses
  RTTI,
  typinfo,

  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  ShellApi,
  Winapi.Windows,

  FireDAC.Comp.Client,
  FireDAC.Comp.UI,
  FireDAC.UI.Intf,
  FireDAC.VCLUI.Async,
  FireDAC.VCLUI.Wait,
  FireDAC.Phys,
  FireDAC.Dapt,

  FireDAC.Stan.Intf,

  FireDAC.Moni.Base,
  FireDAC.Moni.Custom,
  FireDAC.Moni.FlatFile,
  FireDAC.Comp.BatchMove,
  FireDAC.Comp.DataSet,
  FireDAC.Comp.BatchMove.DataSet,
  FireDAC.Comp.BatchMove.SQL,
  FireDAC.DatS,

  IdTCPClient,

  KrkConnection.Enum,
  KrkConnection.Provider.Settings,
  KrkConnection.Provider.Firedac.Query,
  KrkConnection.Provider.Types;

type
  TKrakenQuerys = TObjectList<TKrakenProviderFiredacQuery>;

  TKrakenProviderFiredac = class(TFDConnection)
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  private
    FId                    : String;
    FKrakenQuerys          : TKrakenQuerys;
    FKrakenProviderSettings: TKrakenProviderSettings<TKrakenProviderFiredac>;
    FKrakenProviderTypes   : TKrakenProviderTypes<TKrakenProviderFiredac>;

    LIdTCPClient: TIdTCPClient;

    procedure _SetDefaultConfig;
    function GetDeviceName : String;

    ///<summary>
    ///  Teste de conectividade via IP
    ///</summary>
    function ConnectionInternalTest: Boolean;
  public
    /// <summary>
    ///   Retorna instancia do FDConnection;
    /// </summary>
    function GetInstance: TFDConnection;

    /// <summary>
    ///   Define provedor de banco de dados (PostgreSQL, Firebird ou SQLite)
    /// </summary>
    function ProviderType: TKrakenProviderTypes<TKrakenProviderFiredac>; overload;
    function ProviderType(const AProviderType: TProviderType): TKrakenProviderFiredac; overload;

    /// <summary>
    ///   Define os parametros de conexão
    /// </summary>
    function Settings: TKrakenProviderSettings<TKrakenProviderFiredac>;

    /// <summary>
    ///   Instancia um objeto que implementa uma interface injetando a conexao.
    ///   O create do objeto deve haver um parametro do tipo "TKrakenProvider".
    /// </summary>
    function FactoryClass<T:class>(AInstanceOfInterface: IInterface = nil): T;

    function Id(const Value: String): TKrakenProviderFiredac; overload;
    function Id: String; overload;

    function  Connect: Boolean;
    procedure Disconnect;
    procedure StartTransaction;
    procedure Commit;
    procedure Rollback;

    function Querys: TKrakenQuerys;
    function Query: TKrakenProviderFiredacQuery; overload;
    function Query(const AId: String): TKrakenProviderFiredacQuery; overload;
    function Query(const AId: Integer ): TKrakenProviderFiredacQuery; overload;
  end;

implementation

{ TKrakenProviderFiredac }

constructor TKrakenProviderFiredac.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  _SetDefaultConfig;

  FKrakenQuerys := TKrakenQuerys.Create();
end;

destructor TKrakenProviderFiredac.Destroy;
begin
  if FKrakenProviderSettings <> nil then
    FreeAndNil(FKrakenProviderSettings);

  if FKrakenProviderTypes <> nil then
    FreeAndNil(FKrakenProviderTypes);

  if FKrakenQuerys <> nil then
    FreeAndNil(FKrakenQuerys);

  if Assigned(LIdTCPClient) then
    FreeAndNil(LIdTCPClient);

  inherited;
end;

procedure TKrakenProviderFiredac._SetDefaultConfig;
begin
  GetInstance.LoginPrompt := False;

  {Configuracao obrigatoria do autorecover de conexao}
  GetInstance.ResourceOptions.AutoReconnect  := True;
  GetInstance.ResourceOptions.KeepConnection := True;

  { No caso do PostgreSQL, foi usado para capturar nome da tabela em querys        }
  { http://docwiki.embarcadero.com/RADStudio/Sydney/en/Extended_Metadata_(FireDAC) }
  GetInstance.Params.Add('ExtendedMetadata=True');

  {Configuracao de rodar a query em thread separada - amNonBlocking}
  GetInstance.ResourceOptions.CmdExecMode := amBlocking;

  GetInstance.TxOptions.AutoCommit := False;
end;

function TKrakenProviderFiredac.GetInstance: TFDConnection;
begin
  Result := TFDConnection(Self);
end;

function TKrakenProviderFiredac.ProviderType: TKrakenProviderTypes<TKrakenProviderFiredac>;
begin
  if not Assigned(FKrakenProviderTypes) then
    FKrakenProviderTypes := TKrakenProviderTypes<TKrakenProviderFiredac>.Create(Self);
  Result := FKrakenProviderTypes;
end;

function TKrakenProviderFiredac.ProviderType(const AProviderType: TProviderType): TKrakenProviderFiredac;
begin
  Result := Self;

  if not Assigned(FKrakenProviderTypes) then
    FKrakenProviderTypes := TKrakenProviderTypes<TKrakenProviderFiredac>.Create(Self);

  case AProviderType of
    ptPostgres : FKrakenProviderTypes.Postgres;
    ptMysql    : FKrakenProviderTypes.MySQL;
    ptFirebird : FKrakenProviderTypes.Firebird;
    ptSqlite   : FKrakenProviderTypes.SQLite;
  end;
end;

function TKrakenProviderFiredac.Settings: TKrakenProviderSettings<TKrakenProviderFiredac>;
begin
  if FKrakenProviderSettings = nil then
    FKrakenProviderSettings := TKrakenProviderSettings<TKrakenProviderFiredac>.Create(Self);
  Result := FKrakenProviderSettings;

  //Params.Add('application_name=' + Copy( ExtractFileName( ParamStr(0) ),  1, Pos('.', ExtractFileName(ParamStr(0)))-1) + '-' + id + '-' + GetDeviceName );
end;

function TKrakenProviderFiredac.GetDeviceName : String;
var ipbuffer : string;
      nsize : dword;
begin
   nsize := 255;
   SetLength(ipbuffer,nsize);
   if GetComputerName(pchar(ipbuffer),nsize) then
      result := ipbuffer;
end;

function TKrakenProviderFiredac.Id: String;
begin
  Result := FId;
end;

function TKrakenProviderFiredac.Id(const Value: String): TKrakenProviderFiredac;
begin
  Result := Self;
  FId    := Value;
  Self.Name := 'FDConn' + FId;
end;

function TKrakenProviderFiredac.Connect: Boolean;
begin
  Result := False;

  try
    Disconnect;
  except

  end;
  
  try
    try
      if ( not Connected ) and ( ConnectionInternalTest ) then
        GetInstance.Connected := True;
    finally
      Result := True;
    end;
  except
    on e: exception do
    begin
      //KrakenLogger.Error(E.Message);
      raise;
    end;
  end;
end;

function TKrakenProviderFiredac.ConnectionInternalTest: Boolean;
begin
  try
    LIdTCPClient.Disconnect;
  except

  end;

  try
    try
      LIdTCPClient.Host           := Settings.Host;
      LIdTCPClient.Port           := Settings.Port;
      LIdTCPClient.ConnectTimeout := Settings.TimeOut;
      LIdTCPClient.Connect;
    finally
      Result := LIdTCPClient.Connected;
    end;
  except
    on e: exception do
    begin
      //KrakenLogger.Error(E.Message);
      raise;
    end;
  end;
end;

procedure TKrakenProviderFiredac.Disconnect;
begin
  try
    GetInstance.Close;
  except
    on e: exception do
    begin
      //KrakenLogger.Error(E.Message);
      raise;
    end;
  end;
end;

function TKrakenProviderFiredac.FactoryClass<T>(AInstanceOfInterface: IInterface): T;
var
  LRttiContext       : TRttiContext;
  LRTTiInstanceType  : TRttiInstanceType;
  LRTTiMethod        : TRttiMethod;
  LValue             : TValue;
begin
  LRttiContext       := TRttiContext.Create;
  LRTTiInstanceType  := LRttiContext.GetType(T).AsInstance;
  LRTTiMethod        := LRTTiInstanceType.GetMethod('Create');

  if AInstanceOfInterface <> nil then
    LValue := LRTTiMethod.Invoke( LRTTiInstanceType.MetaclassType , [ Self , TValue.From( AInstanceOfInterface ) ] )
  else
    LValue := LRTTiMethod.Invoke( LRTTiInstanceType.MetaclassType , [ Self ] );

  Result := LValue.AsType<T>;
end;

procedure TKrakenProviderFiredac.StartTransaction;
var
  LSQL: string;
begin
  try
    if GetInstance.TxOptions.AutoCommit then
    begin
      if not GetInstance.InTransaction then
        GetInstance.StartTransaction
    end
    else
    begin
      LSQL := Query.SQL.Text;
      Query.SQL.Text := 'BEGIN';
      Query.ExecSQL;
      Query.SQL.Text := LSQL;
    end;
  except
    on e: exception do
    begin
      Rollback;
      if LSQL <> '' then Query.SQL.Text := LSQL;
      //Krakenlogger.Error(E.Message);
      raise;
    end;
  end;
end;

procedure TKrakenProviderFiredac.Commit;
var
  LSQL: String;
begin
  try
    if GetInstance.TxOptions.AutoCommit then
    begin
      if GetInstance.InTransaction then
        GetInstance.Commit
    end
    else
    begin
      LSQL := Query.SQL.Text;
      Query.SQL.Text := 'COMMIT';
      Query.ExecSQL;
      Query.SQL.Text := LSQL;
    end;
  except
    on e: exception do
    begin
      Rollback;
      if LSQL <> '' then Query.SQL.Text := LSQL;
      //Krakenlogger.Error(E.Message);
      raise;
    end;
  end;
end;

procedure TKrakenProviderFiredac.Rollback;
var
  LSQL: String;
begin
  try
    if GetInstance.TxOptions.AutoCommit then
    begin
      if GetInstance.InTransaction then
        GetInstance.Rollback
    end
    else
    begin
      LSQL := Query.SQL.Text;
      Query.SQL.Text := 'ROLLBACK';
      Query.ExecSQL;
      Query.SQL.Text := LSQL;
    end;

  except
    on e: exception do
    begin
      if LSQL <> '' then Query.SQL.Text := LSQL;
      //Krakenlogger.Error(E.Message);
      raise;
    end;
  end;
end;

function TKrakenProviderFiredac.Querys: TKrakenQuerys;
begin
  Result := FKrakenQuerys;
end;

function TKrakenProviderFiredac.Query: TKrakenProviderFiredacQuery;
begin
  if FKrakenQuerys.Count > 0 then
    Result := FKrakenQuerys.First
  else
    Result := FKrakenQuerys.Items[ FKrakenQuerys.Add( TKrakenProviderFiredacQuery.Create(Self) ) ];
end;

function TKrakenProviderFiredac.Query(const AId: String): TKrakenProviderFiredacQuery;
var
  LKrakenQuery: TKrakenProviderFiredacQuery;
begin
  Result := nil;

  for LKrakenQuery in FKrakenQuerys do
  begin
    if AnsiUpperCase(LKrakenQuery.Id) = AnsiUpperCase(AId) then
    begin
      Result := LKrakenQuery;
      Break;
    end;
  end;

  if Result = nil then
  begin
    LKrakenQuery := FKrakenQuerys.Items[ FKrakenQuerys.Add( TKrakenProviderFiredacQuery.Create(Self) ) ];
    LKrakenQuery.Id(AId);
    Result := LKrakenQuery;
  end;
end;

function TKrakenProviderFiredac.Query(const AId: Integer): TKrakenProviderFiredacQuery;
begin
  Result := Query( IntToStr( AId ) );
end;

end.

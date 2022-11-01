unit KrkConnection.Core;

interface

uses
  System.Classes,
  System.SyncObjs,
  System.SysUtils,
  System.Generics.Collections,

  KrkConnection.Server,
  KrkConnection.Enum,
  KrkConnection.Provider,
  KrkConnection.Provider.Query,
  KrkConnection.PoolManager;

type
  TKrakenProvider      = KrkConnection.Provider.TKrakenProvider;
  TKrakenProviderQuery = KrkConnection.Provider.Query.TKrakenProviderQuery;

  TConnectionCallback  = reference to procedure(AConnection: TKrakenProvider);
  
  TKrakenCore = class( TPoolManager<TKrakenProvider> )
  private
    class var FProviders: TObjectList<TKrakenProvider>;
    class var FDefaultFDConnectionPoolManager: TKrakenCore;
    class var FInstance: TKrakenCore;
  protected
    ///<summary>
    ///   Cria instancia gerenciadora da thread pool
    ///</summary>
    class procedure CreateDefaultInstance;
    
    class function GetDefaultFDConnectionPoolManager: TKrakenCore; static;
  public
    {$IFDEF KRAKEN_API}
    ///<summary>
    ///   Construtor ( chama o metodo CreateDefaultInstance )
    ///</summary>
    class constructor Initialize;

    ///<summary>
    ///   Destroi o gerenciador de threads  ( FDefaultFDConnectionPoolManager )
    ///</summary>
    class destructor UnInitialize;

    ///<summary>
    ///   Sobrescrita do metodo abstrato do pool, usado para quando o contador de referencia do objeto solicitado for maior que zero,
    ///   ou seja, estiver em uso, irá instanciar um novo com os mesmos atributos.
    ///</summary>
    procedure DoGetInstance(var AInstance: TKrakenProvider; var AInstanceOwner: Boolean; const AId: Integer = -1); override;

    ///<summary>
    ///  Getter padrao para o pool manager
    ///  Ex.: TKrakenCore.DefaultManager
    ///</summary>
    class property DefaultManager: TKrakenCore read GetDefaultFDConnectionPoolManager;

    ///<summary>
    ///  Getter padrao para a conexao com pool
    ///  Ex.: TKrakenCore.DefaultManager
    ///</summary>
    procedure TryGetProvider(AConnectionCallback: TConnectionCallback); overload;
    {$ELSE}
    class function Invoker: TKrakenCore;
    class procedure Clear;

    function TryGetProvider( const AId: Integer     ): TKrakenProvider; overload;
    function TryGetProvider( const AId: String = '' ): TKrakenProvider; overload;
    {$ENDIF}
  end;

implementation
  
{ TKrakenCore }

class function TKrakenCore.GetDefaultFDConnectionPoolManager: TKrakenCore;
begin
  if (FDefaultFDConnectionPoolManager = nil) then
  begin
    CreateDefaultInstance;
  end;
  Result := FDefaultFDConnectionPoolManager;
end;


{$IFDEF KRAKEN_API}
class constructor TKrakenCore.Initialize;
begin
  CreateDefaultInstance;
end;

class procedure TKrakenCore.CreateDefaultInstance;
begin
  FProviders := TObjectList<TKrakenProvider>.Create;

  FDefaultFDConnectionPoolManager := TKrakenCore.Create(True);
  FDefaultFDConnectionPoolManager.SetMaxIdleSeconds(10000);
  FDefaultFDConnectionPoolManager.SetMaxRefCountPerItem(1);
  FDefaultFDConnectionPoolManager.Start;
end;

procedure TKrakenCore.DoGetInstance(var AInstance: TKrakenProvider; var AInstanceOwner: Boolean; const AId: Integer);
begin
  inherited;
  AInstanceOwner := True;
  AInstance := TKrakenProvider.Create(nil);

  {$IFDEF KRAKEN_API}
  try
    AInstance
      .ProviderType( StrToProviderType( DRIVER_NAME ) )
      .Settings
        .Host( HOST )
        .Port( PORT )
        .Username( USERNAME )
        .Password( PASSWORD )
        .Database( DATABASE );
  except
    FreeAndNil(AInstance);
    raise;
  end;
  {$ELSE}
  try
    AInstance.Id( IntToStr( AId ) );
  except
    FreeAndNil(AInstance);
    raise;
  end;
  {$ENDIF}
end;

class destructor TKrakenCore.UnInitialize;
begin
  if Assigned(FInstance) then
    FreeAndNil(FInstance);

  if Assigned(FProviders) then
    FreeAndNil(FProviders);

  if FDefaultFDConnectionPoolManager <> nil then
  begin
    FDefaultFDConnectionPoolManager.Free;
  end;
end;

procedure TKrakenCore.TryGetProvider(AConnectionCallback: TConnectionCallback);
var
  LItem: TPoolItem<TKrakenProvider>;
  LConnection: TKrakenProvider;
begin
  LItem := TKrakenCore.DefaultManager.TryGetItem;
  LConnection := LItem.Acquire;
  try
    AConnectionCallback(LConnection);
  finally
    LItem.Release;
  end;
end;

{$ELSE}

class procedure TKrakenCore.CreateDefaultInstance;
begin
  FProviders := TObjectList<TKrakenProvider>.Create;

  FDefaultFDConnectionPoolManager := TKrakenCore.Create(True);
  FDefaultFDConnectionPoolManager.SetMaxIdleSeconds(0); { Tempo de conexao ativa / 0 inativa controlador }
  FDefaultFDConnectionPoolManager.SetMaxRefCountPerItem(0); { Se o contador de referencia for igual ao max, é instanciado nova conexao / 0 inativa o controlaor }
  FDefaultFDConnectionPoolManager.Start;
end;

class procedure TKrakenCore.Clear;
begin
  Invoker.FProviders.Clear;
end;

class function TKrakenCore.Invoker: TKrakenCore;
begin
  if not Assigned(FInstance) then
    FInstance := TKrakenCore.Create;

  Result := FInstance;
end;

function TKrakenCore.TryGetProvider(const AId: Integer): TKrakenProvider;
begin
  Result := TryGetProvider( IntToStr( AId ) );
end;

function TKrakenCore.TryGetProvider(const AId: String): TKrakenProvider;
var
  LProvider: TKrakenProvider;
begin
  Result := nil;

  for LProvider in FProviders do
  begin
    if AnsiUpperCase(LProvider.Id) = AnsiUpperCase(AId) then
    begin
      Result := LProvider;
      Break;
    end;
  end;

  if Result = nil then
  begin
    LProvider := FProviders.Items[ FProviders.Add( TKrakenProvider.Create(nil) ) ];
    LProvider.Id(AId);
    Result := LProvider;
  end;
end;

{$ENDIF}
end.

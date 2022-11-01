unit Server;

interface

uses
  System.SysUtils, Server.Env, Server.Swagger, Server.Routes, Horse,
  Horse.CORS, Horse.Logger, Horse.Logger.Provider.Console,
  Horse.Jhonson, Horse.GBSwagger, Horse.HandleException,
  GBJSON.Config;

  procedure ServerRun;

implementation

procedure ServerRun;
begin
  THorseLoggerManager.RegisterProvider(
    THorseLoggerProviderConsole.New(
      THorseLoggerConsoleConfig.New
        .SetLogFormat('${request_clientip} [${time}] ${response_status}')
    )
  );

  TServerSwagger.Initialize;

  THorse
    .Use(CORS)
    .Use(THorseLoggerManager.HorseCallback)
    .Use(Jhonson)
    .Use(HandleException)
    .Use(HorseSwagger);

  TGBJSONConfig.GetInstance.CaseDefinition(cdNone);

  TClienteController.Register;

  THorse.Listen(
    TServerEnv.PORT,
    procedure(AHorse: THorse)
    begin
      WriteLn( Format( TServerEnv.SERVER_IS_RUNNING, [THorse.Host, THorse.Port] ) );
    end);
end;


end.

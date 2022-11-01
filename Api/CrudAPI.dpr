program CrudAPI;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Server in 'src\Server\Server.pas',
  Server.Swagger in 'src\Server\Server.Swagger.pas',
  Server.Env in 'src\Server\Server.Env.pas',
  Cliente.Entity in '..\Common\Cliente\Model\Cliente.Entity.pas',
  Cliente.Controller in 'src\Cliente\Controller\Cliente.Controller.pas',
  Cliente.DAO in 'src\Cliente\DAO\Cliente.DAO.pas',
  Cliente.DAO.Contract in 'src\Cliente\DAO\Cliente.DAO.Contract.pas',
  Server.Routes in 'src\Server\Server.Routes.pas',
  Server.Status in 'src\Server\Server.Status.pas';

begin
  ReportMemoryLeaksOnShutdown := True;

  ServerRun;
end.

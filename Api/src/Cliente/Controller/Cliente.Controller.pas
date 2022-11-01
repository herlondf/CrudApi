unit Cliente.Controller;

interface

uses
  Horse, Cliente.Entity, Cliente.DAO;

type
  TClienteController = class
  private
    class var FStatus: Integer;
    class procedure Find(AReq: THorseRequest; ARes: THorseResponse);
    class procedure FindAll(AReq: THorseRequest; ARes: THorseResponse);
    class procedure Insert(AReq: THorseRequest; ARes: THorseResponse);
    class procedure Update(AReq: THorseRequest; ARes: THorseResponse);
    class procedure Delete(AReq: THorseRequest; ARes: THorseResponse);
  public
    class procedure Register;
  end;

implementation

{ TClienteController }

class procedure TClienteController.Find(AReq: THorseRequest; ARes: THorseResponse);
begin
  ARes.Send(TClienteDAO.New.Find(AReq.Params['id'], Fstatus)).Status(FStatus);
end;

class procedure TClienteController.FindAll(AReq: THorseRequest; ARes: THorseResponse);
begin
  ARes.Send(TClienteDAO.New.FindAll(FStatus)).Status(FStatus);
end;

class procedure TClienteController.Insert(AReq: THorseRequest; ARes: THorseResponse);
begin
  ARes.Send(TClienteDAO.New.Insert(AReq.Body, Fstatus)).Status(FStatus);
end;

class procedure TClienteController.Update(AReq: THorseRequest; ARes: THorseResponse);
begin
  ARes.Send(TClienteDAO.New.Update( AReq.Body, Fstatus)).Status(FStatus);
end;

class procedure TClienteController.Delete(AReq: THorseRequest; ARes: THorseResponse);
begin
  ARes.Send(TClienteDAO.New.Delete(AReq.Params['id'], Fstatus)).Status(FStatus);
end;

class procedure TClienteController.Register;
begin
  THorse.GET('cliente', FindAll);
  THorse.GET('cliente/:id', Find);
  THorse.POST('cliente', Insert);
  THorse.PUT('cliente', Update);
  THorse.DELETE('cliente/:id', Delete);
end;

end.


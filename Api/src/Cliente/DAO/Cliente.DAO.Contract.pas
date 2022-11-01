unit Cliente.DAO.Contract;

interface

uses
  System.JSON;

type
  iClienteDAO = interface
    ['{1AD36221-3813-4F44-A7D3-03F3A8A1D889}']
    function Find(const AId: String; AStatuscode: Integer): string;
    function FindAll(AStatuscode: Integer): string;
    function Insert(const ACliente: String; AStatuscode: Integer): String;
    function Update(const ACliente: String; AStatuscode: Integer): string;
    function Delete(const AId: string; AStatuscode: Integer): string;
  end;

implementation

end.

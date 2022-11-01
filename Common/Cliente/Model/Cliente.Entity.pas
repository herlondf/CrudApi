unit Cliente.Entity;

interface

uses
  System.Generics.Collections;

type
  TClientePost = class
  private
    FNome: string;
    procedure SetNome(const Value: string);
  published
    property Nome: string read FNome write SetNome;
  end;

  TCliente = class
    constructor Create;
    destructor Destroy; override;
    class function New: TCliente;
  private
    FId: Integer;
    FNome: string;
    procedure SetId(const Value: Integer);
    procedure SetNome(const Value: string);
  public
    property Id: Integer read FId write SetId;
    property Nome: string read FNome write SetNome;
  end;

  TClientes = TObjectList<TCliente>;

implementation

{ TCliente }

constructor TCliente.Create;
begin

end;

destructor TCliente.Destroy;
begin

  inherited;
end;

class function TCliente.New: TCliente;
begin
  Result := Self.Create;
end;

procedure TCliente.SetId(const Value: Integer);
begin
  FId := Value;
end;

procedure TCliente.SetNome(const Value: string);
begin
  FNome := Value;
end;

{ TClientePost }

procedure TClientePost.SetNome(const Value: string);
begin
  FNome := Value;
end;

end.

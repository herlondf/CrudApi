unit Server.Swagger;

interface

uses
  Horse.GBSwagger, GBSwagger.Model.Types;

type
  TServerSwagger = class
    class procedure Initialize;
  end;

implementation

uses
  Horse.Exception,
  Cliente.Entity;

{ TServerSwagger }

class procedure TServerSwagger.Initialize;
begin
  Swagger
    .Info
      .Title('Projeto Crud Api 1.0')
      .Description('Projeto de exemplo de uma api para operações básicas')
      .&End
    .AddProtocol( TGBSwaggerProtocol.gbHttp )

    .Path('cliente')
      .Tag('CLIENTE')

      .GET('Consultar cliente', 'Retorna JSON com dados pertinentes ao cliente')
        .AddParamPath('id', 'Valor do id')
          .Required(False)
        .&End
        .AddResponse(200, 'Sucesso')
          .Schema( TCliente )
        .&End
        .AddResponse(400)
          .Description('Falha na requisicao')
        .&End
        .AddResponse(404)
          .Description('Dados nao encontrados')
        .&End
        .AddResponse(500)
          .Description('Erro interno')
        .&End
      .&End

      .POST('Insere cliente', 'Adiciona novo cliente na base de dados')
        .AddParamBody('Body', 'JSON modelo para POST de cliente')
          .Schema(TClientePost)
          .Required(True)
        .&End
        .AddResponse(200, 'Sucesso')
          .Schema( TCliente )
        .&End
        .AddResponse(400)
          .Description('Falha na requisicao')
        .&End
        .AddResponse(404)
          .Description('Dados nao encontrados')
        .&End
        .AddResponse(500)
          .Description('Erro interno')
        .&End
      .&End

      .PUT('Atualiza dados do cliente', 'Atualiza e retorna JSON com dados atualizados')
        .AddParamPath('id', 'Valor do id')
          .Required(True)
        .&End
        .AddResponse(200, 'Sucesso')
          .Schema( TCliente )
        .&End
        .AddResponse(400)
          .Description('Falha na requisicao')
        .&End
        .AddResponse(404)
          .Description('Dados nao encontrados')
        .&End
        .AddResponse(500)
          .Description('Erro interno')
        .&End
      .&End

      .DELETE('Deleta cliente', 'Remove o cliente do banco de dados')
        .AddParamPath('id', 'Valor do id')
          .Required(True)
        .&End
        .AddResponse(200, 'Sucesso')
          .Schema( TCliente )
        .&End
        .AddResponse(400)
          .Description('Falha na requisicao')
        .&End
        .AddResponse(404)
          .Description('Dados nao encontrados')
        .&End
        .AddResponse(500)
          .Description('Erro interno')
        .&End
      .&End
  .&End;
end;

end.

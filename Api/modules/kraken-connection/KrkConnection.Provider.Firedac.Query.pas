unit KrkConnection.Provider.Firedac.Query;

interface

uses
  System.SysUtils,
  System.Classes,

  FireDAC.Comp.Client,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.Stan.Param,
  FireDAC.Stan.Error,
  FireDAC.Stan.Option, Data.DB;

type
  TKrakenProviderFiredacQuery = class(TFDQuery)
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  private
    FOwner     : TComponent;
    FId        : String;

  public
    function  GetInstance: TFDQuery;

    function  Id(const Value: String): TKrakenProviderFiredacQuery; overload;
    function  Id: String; overload;

    function  SaveQuery: String;

    procedure Open(ASQL: String; ALog: Boolean = false); overload;
    procedure Open(ALog: Boolean = false); overload;

    procedure ExecSQL(ALog: Boolean = false);

    procedure Clear;
  end;

implementation

uses
  KrkConnection.Provider.Firedac;

{ TKrakenProviderFiredacQuery }

constructor TKrakenProviderFiredacQuery.Create(AOwner: TComponent);
begin
  Inherited Create(AOwner);
  FOwner := AOwner;
  GetInstance.Connection := TFDConnection(AOwner);
end;

destructor TKrakenProviderFiredacQuery.Destroy;
begin

  inherited;
end;

function TKrakenProviderFiredacQuery.GetInstance: TFDQuery;
begin
  Result := TFDQuery(Self);
end;

function TKrakenProviderFiredacQuery.Id: String;
begin
  Result    := FId;
end;

function TKrakenProviderFiredacQuery.Id(const Value: String): TKrakenProviderFiredacQuery;
begin
  Result    := Self;
  FId       := Value;
  Self.Name := 'FDQuery' + FId;
end;

function TKrakenProviderFiredacQuery.SaveQuery: String;
var
  I            : Integer;
  LParams      : TStringList;
  LRecordCount : String;
  LQuery       : string;
begin
  Result := '';

  LParams := TStringLIst.Create;

  if SQL.GetText <> '' then  
    LQuery  := SQL.GetText
  else
    LQuery  := SQL.Text;
    

  for I := 0 to Pred( Params.Count ) do
  begin
    LParams.Add( Format( '- %s: %s', [Params[I].Name.ToLower, Params[I].AsString] ) );

    StringReplace( LQuery, ':'+Params[I].Name.ToLower, Params[I].AsString + '{' + Params[I].Name + '}', [rfReplaceAll, rfIgnoreCase] );
  end;

  try
    if Self.Active then
      LRecordCount := IntToStr( RecordCount )
    else
      LRecordCount := '-';
  except
    LRecordCount := '0';
  end;

  Result := Format(
      ''                                                   + sLineBreak +
      '/*-----------------------------------------------'  + sLineBreak +
      'Data......: %s as %s '                              + sLineBreak +
      'Registros.: %s '                                    + sLineBreak +
      'Parametros: %s '                                    + sLineBreak +
      '/*-----------------------------------------------'  + sLineBreak +
      ''                                                   + sLineBreak +
      '%s'
    ,
    [
      FormatDateTime( 'dd/mm/yyyy', Now ),
      FormatDateTime( 'hh:mm:ss  ', Now ),
      LRecordCount,
      LParams.Text,
      LQuery
    ]
  );

  LParams.Free;
end;

procedure TKrakenProviderFiredacQuery.Open(ASQL: String; ALog: Boolean = false);
begin
  try
    GetInstance.SQL.Clear;
    GetInstance.SQL.Add(ASQL);

    if not GetInstance.Prepared then
      GetInstance.Prepare;

    //if ALog then KrakenLogger.Trace( SaveQuery );

    GetInstance.Active := True;
  except
    on E: Exception do 
    begin

      raise;
    end;
  end;
end;

procedure TKrakenProviderFiredacQuery.Open(ALog: Boolean = false);
begin
  //if ALog then KrakenLogger.Trace( SaveQuery );

  try
    if not GetInstance.Prepared then
      GetInstance.Prepare;

    GetInstance.Active := True;
  except
    on E: Exception do 
    begin

      raise;
    end;
  end;
end;

procedure TKrakenProviderFiredacQuery.ExecSQL(ALog: Boolean = false);
begin
  //if ALog then KrakenLogger.Trace( SaveQuery );

  try
    GetInstance.ExecSQL;
  except
    on E: Exception do 
    begin

      raise;
    end;
  end;
end;

procedure TKrakenProviderFiredacQuery.Clear;
begin
  SQL.Clear;
  {$IF CompilerVersion > 30}
  ClearColumnMap;
  {$ENDIF}
  ClearBlobs;
  ClearDetails;
  ClearBuffers;
end;

end.

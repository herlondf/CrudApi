unit KrkConnection.Enum;

interface

type
  TProviderType = (ptPostgres, ptMysql, ptFirebird, ptSqlite);

  function StrToEnumerado(const s: string; const AString: array of String; const AEnumerados: array of variant): variant;
  function EnumeradoToStr(const t: variant; const AMode: array of variant; const AEnumerados: array of String): String;

  function StrToProviderType(const ADrivername: String): TProviderType;


implementation

function StrToEnumerado(const s: string; const AString: array of String; const AEnumerados: array of variant): variant;
var
  i: integer;
begin
  result := -1;
  for i := Low(AString) to High(AString) do
    if s = AString[i] then
    begin
      result := AEnumerados[i];
      exit;
    end;

  if result <> -1 then
    result := AEnumerados[0];
end;

function EnumeradoToStr(const t: variant; const AMode: array of variant; const AEnumerados: array of String): String;
var
  i: integer;
begin
  result := '';
  for i := Low(AMode) to High(AMode) do
    if t = AMode[i] then
    begin
      result := AEnumerados[i];
      Break;
    end;
end;

function StrToProviderType(const ADrivername: String): TProviderType;
begin
  Result :=
    StrToEnumerado(
      ADrivername,
      [
       'Postgres', 'Mysql', 'Firebird', 'Sqlite'
      ],
      [
       ptPostgres, ptMysql, ptFirebird, ptSqlite
      ]
    );
end;

end.

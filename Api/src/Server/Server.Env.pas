unit Server.Env;

interface

uses
  System.SysUtils, System.IniFiles;

type
  TServerEnv = class
    class function PORT: Word;
    class function SERVER_IS_RUNNING: String;
    class function VERSION: String;



  end;

implementation

{ TServerEnv }

class function TServerEnv.PORT: Word;
var
  LIniFile: TIniFile;
begin
  LIniFile := TIniFile.Create( ChangeFileExt( ParamStr( 0 ), '.ini' ) );
  Result :=
    LIniFile
      .ReadInteger(
        'Server',
        'Port',
        9000
      );
  LIniFile.Free;
end;

class function TServerEnv.SERVER_IS_RUNNING: String;
begin
  Result := 'Server is running on %s:%d';
end;

class function TServerEnv.VERSION: String;
begin
  Result := 'v1';
end;

end.

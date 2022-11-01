unit KrkConnection.Server;

interface

uses
  System.IniFiles, System.SysUtils;

  function DRIVER_NAME: string;
  function HOST: string;
  function PORT: string;
  function USERNAME: string;
  function PASSWORD: string;
  function DATABASE: string;


implementation

var
  FIniFile: TIniFile;

function DRIVER_NAME: string;
begin
  FIniFile := TIniFile.Create( ChangeFileExt( ParamStr( 0 ), '.ini' ) );

  Result :=
    FIniFile
      .ReadString(
        ChangeFileExt( ExtractFileName( ParamStr( 0 ) ), '' ),
        'Driver',
        ''
      );
  FIniFile.Free;
end;

function HOST: string;
begin
  FIniFile := TIniFile.Create( ChangeFileExt( ParamStr( 0 ), '.ini' ) );

  Result :=
    FIniFile
      .ReadString(
        ChangeFileExt( ExtractFileName( ParamStr( 0 ) ), '' ),
        'Host',
        ''
      );
  FIniFile.Free;
end;

function PORT: string;
begin
  FIniFile := TIniFile.Create( ChangeFileExt( ParamStr( 0 ), '.ini' ) );

  Result :=
    FIniFile
      .ReadString(
        ChangeFileExt( ExtractFileName( ParamStr( 0 ) ), '' ),
        'Port',
        ''
      );
  FIniFile.Free;
end;

function USERNAME: string;
begin
  FIniFile := TIniFile.Create( ChangeFileExt( ParamStr( 0 ), '.ini' ) );

  Result :=
    FIniFile
      .ReadString(
        ChangeFileExt( ExtractFileName( ParamStr( 0 ) ), '' ),
        'Username',
        ''
      );
  FIniFile.Free;
end;

function PASSWORD: string;
begin
  FIniFile := TIniFile.Create( ChangeFileExt( ParamStr( 0 ), '.ini' ) );

  Result :=
    FIniFile
      .ReadString(
        ChangeFileExt( ExtractFileName( ParamStr( 0 ) ), '' ),
        'Password',
        ''
      );
  FIniFile.Free;
end;

function DATABASE: string;
begin
  FIniFile := TIniFile.Create( ChangeFileExt( ParamStr( 0 ), '.ini' ) );

  Result :=
    FIniFile
      .ReadString(
        ChangeFileExt( ExtractFileName( ParamStr( 0 ) ), '' ),
        'Database',
        ''
      );
  FIniFile.Free;
end;


end.

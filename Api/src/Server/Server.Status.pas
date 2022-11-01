unit Server.Status;

interface

function SUCCESS: Integer;
function NOT_FOUND: Integer;
function INTERNAL_ERROR: Integer;
function BAD_REQUEST: Integer;

implementation

function SUCCESS: Integer;
begin
  Result := 200;
end;

function NOT_FOUND: Integer;
begin
  Result := 404;
end;

function INTERNAL_ERROR: Integer;
begin
  Result := 500;
end;

function BAD_REQUEST: Integer;
begin
  Result := 400;
end;

end.

{ Fonte Original: https://github.com/CarlosHe/pool-manager }

unit KrkConnection.PoolManager;

interface

uses
  System.SyncObjs,
  System.Generics.Collections,
  System.Classes,
  System.SysUtils;

type
  TPoolItem<T: class> = class
  private
    FMultiReadExclusiveWriteSynchronizer: TMultiReadExclusiveWriteSynchronizer;
    FInstance: T;
    FRefCount: Integer;
    FIdleTime: TDateTime;
    FInstanceOwner: Boolean;
    FId: Integer;
  public
    function GetRefCount: Integer;
    function IsIdle(out AIdleTime: TDateTime): Boolean;
    function Acquire: T;
    procedure Id(const Value: Integer); overload;
    function  Id: Integer; overload;
    procedure Release;
    constructor Create(AInstance: T; const AInstanceOwner: Boolean = True);
    destructor Destroy; override;
  end;

  TPoolManager<T: class> = class(TThread)
  private
    { private declarations }
    FMultiReadExclusiveWriteSynchronizer: TMultiReadExclusiveWriteSynchronizer;
    FEvent: TEvent;
    FPoolItemList: TObjectList<TPoolItem<T>>;
    FMaxRefCountPerItem: Integer;
    FIgnoreRefCount: Boolean;
    FMaxIdleSeconds: Int64;
    FMinPoolCount: Integer;
  protected
    { protected declarations }
    procedure FreeInternalInternalInstances;
    procedure DoReleaseItems;
  public
    { public declarations }
    procedure DoGetInstance(var AInstance: T; var AInstanceOwner: Boolean; const AId: Integer = 0); virtual; abstract;
    procedure SetMaxRefCountPerItem(AMaxRefCountPerItem: Integer);
    procedure SetMaxIdleSeconds(AMaxIdleSeconds: Int64);
    procedure SetMinPoolCount(AMinPoolCount: Integer);
    procedure SetIgnoreRefCount(AIgnoreRefCount: Boolean);
    
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure Execute; override;
    
    function TryGetItem(AId: Integer = -1): TPoolItem<T>;    
  end;

implementation

uses
  System.DateUtils;

{ TPoolItem<T> }

function TPoolItem<T>.Acquire: T;
begin
  FMultiReadExclusiveWriteSynchronizer.BeginWrite;
  try
    TInterlocked.Increment(FRefCount);
    Result := FInstance;
  finally
    FMultiReadExclusiveWriteSynchronizer.EndWrite
  end;
end;

constructor TPoolItem<T>.Create(AInstance: T; const AInstanceOwner: Boolean = True);
begin
  FMultiReadExclusiveWriteSynchronizer := TMultiReadExclusiveWriteSynchronizer.Create;
  FInstance := AInstance;
  FInstanceOwner := AInstanceOwner;
  FIdleTime := Now();
end;

destructor TPoolItem<T>.Destroy;
begin
  if FInstanceOwner then
    FInstance.Free;
  FMultiReadExclusiveWriteSynchronizer.Free;
  inherited;
end;

function TPoolItem<T>.GetRefCount: Integer;
begin
  FMultiReadExclusiveWriteSynchronizer.BeginRead;
  try
    Result := FRefCount;
  finally
    FMultiReadExclusiveWriteSynchronizer.EndRead;
  end;
end;

procedure TPoolItem<T>.Id(const Value: Integer);
begin
  if FId <> Value then FId := Value;
end;

function TPoolItem<T>.Id: Integer;
begin
  Result := FId;
end;

function TPoolItem<T>.IsIdle(out AIdleTime: TDateTime): Boolean;
begin
  FMultiReadExclusiveWriteSynchronizer.BeginRead;
  try
    Result := FRefCount = 0;
    if Result then
      AIdleTime := FIdleTime;
  finally
    FMultiReadExclusiveWriteSynchronizer.EndRead;
  end;
end;

procedure TPoolItem<T>.Release;
begin
  FMultiReadExclusiveWriteSynchronizer.BeginWrite;
  try
    if FRefCount > 0 then
      TInterlocked.Decrement(FRefCount);
    if FRefCount = 0 then
      FIdleTime := Now;
  finally
    FMultiReadExclusiveWriteSynchronizer.EndWrite;
  end;
end;

{ TPoolManager<T> }

function TPoolManager<T>.TryGetItem(AId: Integer = -1): TPoolItem<T>;
var
  I: Integer;
  LPoolItem: TPoolItem<T>;
  LInstance: T;
  LInstanceOwner: Boolean;
begin
  Result := nil;
  FMultiReadExclusiveWriteSynchronizer.BeginWrite;
  
  try
    for I := 0 to Pred(FPoolItemList.Count) do
    begin     
      if ( FPoolItemList.Items[I].GetRefCount < FMaxRefCountPerItem ) or ( FIgnoreRefCount ) then
      begin
        if AId <> -1 then
        begin
          if FPoolItemList.Items[I].Id = AId then
          begin
            Result := FPoolItemList.Items[I];
            Break;
          end;
        end
        else
        begin
          Result := FPoolItemList.Items[I];
          Break;
        end;
      end;
    end;
    
    if Result = nil then
    begin
      try
        LInstance := nil;
        LInstanceOwner := False;
        DoGetInstance(LInstance, LInstanceOwner);
      finally
        if LInstance <> nil then
        begin
          LPoolItem := TPoolItem<T>.Create(LInstance, LInstanceOwner);
          Result := LPoolItem;
          FPoolItemList.Add(LPoolItem);
        end;
      end;
    end;
  finally
    FMultiReadExclusiveWriteSynchronizer.EndWrite;
  end;
end;

procedure TPoolManager<T>.AfterConstruction;
begin
  inherited;
  FreeOnTerminate := False;
  FMinPoolCount := 0;
  FMaxRefCountPerItem := 1;
  FIgnoreRefCount := False;
  FMaxIdleSeconds := 60;
  FEvent := TEvent.Create;
  FPoolItemList := TObjectList <TPoolItem <T>>.Create;
  FMultiReadExclusiveWriteSynchronizer := TMultiReadExclusiveWriteSynchronizer.Create;
end;

procedure TPoolManager<T>.BeforeDestruction;
begin
  Terminate;
  FEvent.SetEvent;
  WaitFor;
  FreeInternalInternalInstances;
  inherited;
end;

procedure TPoolManager<T>.DoReleaseItems;
var
  I: Integer;
  LIdleTime: TDateTime;
begin
  FMultiReadExclusiveWriteSynchronizer.BeginWrite;
  try
    for I := Pred(FPoolItemList.Count) downto 0 do
    begin
      if CheckTerminated then
        Break;
      if (FPoolItemList.Items[I].IsIdle(LIdleTime)) and (FPoolItemList.Count > FMinPoolCount) then
      begin
        if ( SecondsBetween(Now, LIdleTime) >= FMaxIdleSeconds ) and ( FMaxIdleSeconds > 0 ) then
        begin
          FPoolItemList.Delete(I);
        end;
      end;
    end;
  finally
    FMultiReadExclusiveWriteSynchronizer.EndWrite;
  end;
end;

procedure TPoolManager<T>.Execute;
var
  LWaitResult: TWaitResult;
begin
  inherited;
  while not CheckTerminated do
  begin
    try
      LWaitResult := FEvent.WaitFor(100);
      if CheckTerminated then
        Exit;
      if LWaitResult = wrTimeout then
        DoReleaseItems;
      if LWaitResult = wrSignaled then
        Break;
    except
      continue;
    end;
  end;
end;

procedure TPoolManager<T>.FreeInternalInternalInstances;
begin
  FPoolItemList.Free;
  FEvent.Free;
  FMultiReadExclusiveWriteSynchronizer.Free;
end;

procedure TPoolManager<T>.SetIgnoreRefCount(AIgnoreRefCount: Boolean);
begin
  FIgnoreRefCount := AIgnoreRefCount;
end;

procedure TPoolManager<T>.SetMaxIdleSeconds(AMaxIdleSeconds: Int64);
begin
  FMaxIdleSeconds := AMaxIdleSeconds;
end;

procedure TPoolManager<T>.SetMaxRefCountPerItem(AMaxRefCountPerItem: Integer);
begin
  FMaxRefCountPerItem := AMaxRefCountPerItem;
end;

procedure TPoolManager<T>.SetMinPoolCount(AMinPoolCount: Integer);
begin
  FMinPoolCount := AMinPoolCount;
end;

end.

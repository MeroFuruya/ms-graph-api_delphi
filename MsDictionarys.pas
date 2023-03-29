unit MsDictionarys;

interface

uses
  System.Generics.Collections;

type
  TMsDictionaryItem = record
    Id: string;
    Entity: TObject;
    Index: Integer;
  end;

  TMsEntityDictionary = class
  private
    FUsesCustomIndex: Boolean;
    FId: TList<string>;
    FEntity: TList<TObject>;
    FIndex: TList<Integer>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AId: string; const AEntity: TObject);
    procedure AddWithIndex(const AId: string; const AEntity: TObject; const AIndex: Integer);
    function GetEntityById(const AId: string): TObject;
    function GetEntityByIndex(const AIndex: Integer): TObject;
    function GetIndexById(const AId: string): Integer;
    function GetIndexByEntity(const AEntity: TObject): Integer;
    function GetIdByIndex(const AIndex: Integer): string;
    function GetIdByEntity(const AEntity: TObject): string;
    function RemoveById(const AId: string): Boolean;
    function RemoveByIndex(const AIndex: Integer): Boolean;
    function RemoveByEntity(const AEntity: TObject): Boolean;
    function GetCount: Integer;
    function Clone: TMsEntityDictionary;
    function Items: TArray<TMsDictionaryItem>;
    property Count: Integer read GetCount;
  end;

implementation

{ TMsEntityDictionary }

procedure TMsEntityDictionary.Add(const AId: string; const AEntity: TObject);
begin
  FId.Add(AId);
  FEntity.Add(AEntity);
end;

procedure TMsEntityDictionary.AddWithIndex(const AId: string; const AEntity: TObject; const AIndex: Integer);
begin
  FUsesCustomIndex := True;
  FId.Add(AId);
  FEntity.Add(AEntity);
  FIndex.Add(AIndex);
end;

function TMsEntityDictionary.Clone: TMsEntityDictionary;
var
  i: Integer;
begin
  Result := TMsEntityDictionary.Create;
  for i := 0 to FId.Count - 1 do
  begin
    if FUsesCustomIndex then
      Result.AddWithIndex(FId[i], FEntity[i], FIndex[i])
    else
      Result.Add(FId[i], FEntity[i]);
  end;
end;

constructor TMsEntityDictionary.Create;
begin
  FId := TList<string>.Create;
  FEntity := TList<TObject>.Create;
  FIndex := TList<Integer>.Create;
end;

destructor TMsEntityDictionary.Destroy;
begin
  FId.Free;
  FEntity.Free;
  FIndex.Free;
  inherited;
end;

function TMsEntityDictionary.GetCount: Integer;
begin
  Result := FId.Count;
end;

function TMsEntityDictionary.GetEntityById(const AId: string): TObject;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to FId.Count - 1 do
  begin
    if FId[i] = AId then
    begin
      Result := FEntity[i];
      Break;
    end;
  end;
end;

function TMsEntityDictionary.GetEntityByIndex(const AIndex: Integer): TObject;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to FIndex.Count - 1 do
  begin
    if FIndex[i] = AIndex then
    begin
      Result := FEntity[i];
      Break;
    end;
  end;
end;

function TMsEntityDictionary.GetIdByEntity(const AEntity: TObject): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to FEntity.Count - 1 do
  begin
    if FEntity[i] = AEntity then
    begin
      Result := FId[i];
      Break;
    end;
  end;
end;

function TMsEntityDictionary.GetIdByIndex(const AIndex: Integer): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to FIndex.Count - 1 do
  begin
    if FIndex[i] = AIndex then
    begin
      Result := FId[i];
      Break;
    end;
  end;
end;

function TMsEntityDictionary.GetIndexByEntity(const AEntity: TObject): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to FEntity.Count - 1 do
  begin
    if FEntity[i] = AEntity then
    begin
      Result := FIndex[i];
      Break;
    end;
  end;
end;

function TMsEntityDictionary.GetIndexById(const AId: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to FId.Count - 1 do
  begin
    if FId[i] = AId then
    begin
      Result := FIndex[i];
      Break;
    end;
  end;
end;

function TMsEntityDictionary.RemoveByEntity(const AEntity: TObject): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to FEntity.Count - 1 do
  begin
    if FEntity[i] = AEntity then
    begin
      FId.Delete(i);
      FEntity.Delete(i);
      FIndex.Delete(i);
      Result := True;
      Break;
    end;
  end;
end;

function TMsEntityDictionary.RemoveById(const AId: string): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to FId.Count - 1 do
  begin
    if FId[i] = AId then
    begin
      FId.Delete(i);
      FEntity.Delete(i);
      FIndex.Delete(i);
      Result := True;
      Break;
    end;
  end;
end;

function TMsEntityDictionary.RemoveByIndex(const AIndex: Integer): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to FIndex.Count - 1 do
  begin
    if FIndex[i] = AIndex then
    begin
      FId.Delete(i);
      FEntity.Delete(i);
      FIndex.Delete(i);
      Result := True;
      Break;
    end;
  end;
end;

function TMsEntityDictionary.Items: TArray<TMsDictionaryItem>;
var
  i: Integer;
begin
  SetLength(Result, FId.Count);
  for i := 0 to FId.Count - 1 do
  begin
    Result[i].Id := FId[i];
    Result[i].Entity := FEntity[i];
    Result[i].Index := FIndex[i];
  end;
end;

end.
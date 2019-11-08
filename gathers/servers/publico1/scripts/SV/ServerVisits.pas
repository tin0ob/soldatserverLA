const
  _FOLDER_DATABASE = '';
  _NAME_DATABASE = 'database.txt';

var
  Exception, Today: string;
  database        : array of string;

procedure OnErrorOccur(const ERROR_MSG: string);
begin
  Exception:= ERROR_MSG;
  WriteLn('MySSQL: ' + Exception);
end;

function IXSplit(const SOURCE: string; Delimiter: string): array of string;
var
  i, x, d: integer;
  s, b: string;
begin
  d:= length(Delimiter);
  i:= 1;
  SetArrayLength(Result, 0);
  while (i <= length(SOURCE)) do
  begin
    s:= Copy(SOURCE, i, d);
    if (s = Delimiter) then
    begin
      SetArrayLength(Result, x + 1);
      Result[x]:= b;
      Inc(i, d);
      Inc(x, 1);
      b:= '';
    end else
    begin       
      b:= b + Copy(s, 1, 1);
      Inc(i, 1);
    end;
  end;
  if (b <> '') then
  begin
    SetArrayLength(Result, x + 1);
    Result[x]:= b;
  end;
end;

function ReadFromFile(File: string): string;
begin
  Result:= ReadFile(File);
  Result:= Copy(Result, 0, length(Result) - 2);
end;

function DoesFileExist(Name: string): boolean;
begin
  if (GetSystem() = 'windows') then
  begin
    if (FileExists(Name)) then
    begin
      result:= true;
    end;
  end else
  begin
    if ((FileExists(Name)) or (ReadFromFile(Name) <> '')) then
    begin
      result:= true;
    end;
  end;
end;

procedure _LoadDatabase();
begin
  if (DoesFileExist(_FOLDER_DATABASE + _NAME_DATABASE)) then
  begin
    database:= IXSplit(ReadFromFile(_FOLDER_DATABASE + _NAME_DATABASE), #13#10);
  end else
  begin
    WriteFile(_FOLDER_DATABASE + _NAME_DATABASE, '');
  end;
end;
 
procedure _SnapDatabase();
var
  i: integer;
  b: string;
begin
  for i:= 0 to GetArrayLength(database) - 1 do
  begin
    if (b <> '') then
    begin
      b:= b + #13#10 + database[i];
    end else
    begin
      b:= database[i];
    end;
  end;
  WriteFile(_FOLDER_DATABASE + _NAME_DATABASE, b);
end;

function _RowExists(RowID: integer): boolean;
begin
  result:= ArrayHigh(database) >= RowID;
end;

function _getColumnInfo(RowID, ColumnID: integer): integer;
var
  ch, x, tabs: integer;
  b: string;
begin
  tabs:= -1;
  b:= database[RowID];
  while (tabs <> ColumnID) do
  begin
    x:= StrPos(#9, b);
    if ((x = 0) and (tabs <> ColumnID)) then
    begin
      exit;
    end;
    Inc(tabs, 1);
    if (tabs = ColumnID) then
    begin
      result:= ch + 1;
      break;
    end else
    begin
      ch:= ch + x;
      Delete(b, 1, x);
    end;
  end;
end;

function GetTypeOF(Value: variant): string;
begin
  case VarType(Value) of
    3  : result:= IntToStr(Value);
    5  : result:= FormatFloat('', Value);
    11 : result:= iif(Value, 'true', 'false');
    256: result:= Value;
    else result:= 'unknown Type';
  end;
end;

procedure _CreateRow(Columns: array of variant);
var
  i, x: integer;
begin
  SetArrayLength(database, GetArrayLength(database) + 1);
  x:= GetArrayLength(database) - 1;
  for i:= 0 to GetArrayLength(Columns) - 1 do
  begin
    database[x]:= database[x] + GetTypeOF(Columns[i]) + #9;
  end;
  _SnapDatabase();
end;

function _DeleteRow(RowID: integer): boolean;
var
  HIndex: integer;
begin
  if (_RowExists(RowID)) then
  begin
    HIndex:= GetArrayLength(database) - 1;
    if (RowID <> HIndex) then
    begin
      database[RowID]:= database[HIndex];
    end;
    SetArrayLength(database, iif(HIndex > 0, HIndex - 1, 0));
    _SnapDatabase();
    result:= true;
  end else
  begin
    OnErrorOccur('RowID ' + IntToStr(RowID) + ' does not exist');
  end;
end;

function _UpdateColumn(RowID, ColumnID: integer; Increase: extended): boolean;
var
  data, Sum: string;
  pos: integer;
begin
  if (_RowExists(RowID)) then
  begin
    pos:= _getColumnInfo(RowID, ColumnID);
    if (pos > 0) then
    begin
      data:= GetPiece(database[RowID], #9, ColumnID);
      if (RegExpMatch('^-?(\d+|\d+.?\d+)$', data)) then
      begin
        Sum:= FormatFloat('', StrToFloat(data) + Increase);
        Delete(database[RowID], pos, length(data));
        Insert(Sum, database[RowID], pos);
        result:= true;
      end else
      begin
        OnErrorOccur('Column "' + IntToStr(ColumnID) + '" represents no numeric value');
      end;
    end else
    begin
      OnErrorOccur('ColumnID ' + IntToStr(ColumnID) + ' does not exist');
    end;
  end else
  begin
    OnErrorOccur('RowID ' + IntToStr(RowID) + ' does not exist');
  end;
end;

function _SetColumn(RowID, ColumnID: integer; Value: variant): boolean;
var
  pos: integer;
  data: string;
begin
  if (_RowExists(RowID)) then
  begin
    pos:= _getColumnInfo(RowID, ColumnID);
    if (pos > 0) then
    begin
      data:= GetPiece(database[RowID], #9, ColumnID);
      Delete(database[RowID], pos, length(data));
      Insert(GetTypeOF(Value), database[RowID], pos);
      result:= true;
    end else
    begin
      OnErrorOccur('ColumnID ' + IntToStr(ColumnID) + ' does not exist');
    end;
  end else
  begin
    OnErrorOccur('RowID ' + IntToStr(RowID) + ' does not exist');
  end;
end;

function _AppendColumn(RowID: integer; Value: variant): boolean;
begin
  if (_RowExists(RowID)) then
  begin
    database[RowID]:= database[RowID] + GetTypeOF(Value) + #9;
    result:= true;
  end else
  begin
    OnErrorOccur('RowID ' + IntToStr(RowID) + ' does not exist');
  end;
end;

function FillWith(const Filler: char; Amount: integer): string;
var
  i: integer;
begin
  for i:= 1 to Amount do
  begin
    Result:= Result + Filler;
  end;
end;

procedure CreateBox(ID: byte; const Headline: string; const BorderStyleX, BorderStyleY, CornerStyle: char; const Content: array of string; BorderColor: longint);
var
  i, MaxSize, len_Headline: integer;
begin
  len_Headline:= length(Headline);
  MaxSize:= len_HeadLine;
  for i:= 0 to ArrayHigh(Content) do
  begin
    if (length(Content[i]) > MaxSize) then
    begin
      MaxSize:= length(Content[i]);
    end;
  end;
  if ((MaxSize - len_Headline) MOD 2 = 1) then
  begin
    Inc(MaxSize, 1);
  end;
  WriteConsole(ID, CornerStyle + FillWith(BorderStyleX, (MaxSize - len_Headline) div 2) + Headline + FillWith(BorderStyleX, (MaxSize - len_Headline) div 2) + CornerStyle, BorderColor);
  for i:= 0 to GetArrayLength(Content) - 1 do
  begin
    WriteConsole(ID, BorderStyleY + Content[i] + FillWith(' ', MaxSize - length(Content[i])) + BorderStyleY, BorderColor - ((i + 1) * 25));
  end;
  WriteConsole(ID, CornerStyle + FillWith(BorderStyleX, MaxSize) + CornerStyle, BorderColor - ((i + 1) * 25));
end;


procedure ActivateServer();
begin
  _LoadDatabase();
  if (GetArrayLength(database) - 1 < 0) then
  begin
    _CreateRow(['Today', 0]);
    _CreateRow(['Week', FormatDate('dddd'), 0]);
    _CreateRow(['Total', 0]);
    _LoadDatabase();
  end;
  Today:= FormatDate('dddd');
end;

procedure OnDateCheck();
begin
  if (Today <> FormatDate('dddd')) then
  begin
    _SetColumn(0, 1, 0);
    Today:= FormatDate('dddd');
    if (Today = GetPiece(database[1], #9, 1)) then
    begin
      _SetColumn(1, 2, 0);
    end;
  end;
  _SnapDatabase();
end;

procedure AppOnIdle(Ticks: integer);
var
  Visits: array [0..2] of string;
begin
  if (Ticks mod (3600 * 5) = 0) then
  begin
    OnDateCheck();
    Visits[0]:= 'Today    : ' + GetPiece(database[0], #9, 1);
    Visits[1]:= 'This week: ' + GetPiece(database[1], #9, 2);
    Visits[2]:= 'Over-all : ' + GetPiece(database[2], #9, 1);
    CreateBox(0, '_ Server Visits _', '_', '|', '.', Visits, $23DBDB)
  end;
end;

procedure OnJoinGame(ID, Team: byte);
begin
  _UpdateColumn(0, 1, 1);
  _UpdateColumn(1, 2, 1);
  _UpdateColumn(2, 1, 1);
end;

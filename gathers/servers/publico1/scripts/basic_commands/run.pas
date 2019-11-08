const
    TEAM_NONE       = 0;
    TEAM_ALPHA      = 1;
    TEAM_BRAVO      = 2;
    TEAM_CHARLIE    = 3;
    TEAM_DELTA      = 4;
    TEAM_SPECTATORS = 5;
    PLAYERS_MAX     = 32;

    UNPAUSE_DELAY   = 3;
    MAPS_FILEPATH   = '~/mapslist.txt';

    COLOR_LOG       = $BBBBBB;
    COLOR_INFO      = $EECCAA;
    COLOR_WARN      = $FFAAAA;

var
    UnpauseCountdown: shortint;
    MapNamesNormal: TStringList;
    MapNamesSearch: TStringList;

procedure PlayersWriteConsole(Text: string; Color: Longint);
begin
    WriteLn(Text);
    Players.WriteConsole(Text, Color);
end;

function LoadMaps(FilePath: string): boolean;
var
    i: integer;
begin
    // init lists
    MapNamesNormal := File.CreateStringList();
    MapNamesSearch := File.CreateStringList();

    if File.CheckAccess(FilePath) then
        if File.Exists(FilePath) then begin
            MapNamesNormal := File.CreateStringListFromFile(FilePath);
            for i := 0 to MapNamesNormal.Count - 1 do
                MapNamesSearch.Append(lowercase(MapNamesNormal[i]));
        end else
            WriteLn('Not found: '+FilePath)
    else
        WriteLn('Access denied: '+FilePath);

    Result := true;
end;

function ChangeMap(MapName: string): boolean;
var
    i: integer;
begin
    MapName := Trim(MapName);

    if Length(MapName) > 0 then begin
        i := MapNamesSearch.IndexOf(lowercase(MapName));
        if i < 0 then
            i := MapNamesSearch.IndexOf('ctf_'+lowercase(MapName));

        if i >= 0 then
            MapName := MapNamesNormal.Strings[i];

        Map.SetMap(MapName);
    end;

    Result := true;
end;

function ProcessPause(DoPause: boolean): boolean;
begin
    if DoPause then
        if Game.Paused then
            if UnpauseCountdown = -1 then
                PlayersWriteConsole('Paused!', COLOR_INFO)
            else begin
                UnpauseCountdown := -1;
                PlayersWriteConsole('Unpausing was cancelled...', COLOR_INFO);
            end
        else begin
            PlayersWriteConsole('Pausing...', COLOR_INFO);
            Game.Paused := true;
        end
    else
        if not Game.Paused then
            PlayersWriteConsole('Unpaused!', COLOR_INFO)
        else
            UnpauseCountdown := UNPAUSE_DELAY;

    Result := true;
end;

function ProcessRestart(): boolean;
begin
    PlayersWriteConsole('Restarting...', COLOR_LOG);
    Game.Restart

    Result := true;
end;

function OnCommand(Player: TActivePlayer; Command: string): boolean;
var
    CommandExecuted: boolean;
begin
    case lowercase(trim(Command)) of
        '/pause'    : CommandExecuted := ProcessPause(true);
        '/unpause'  : CommandExecuted := ProcessPause(false);
    else
        if Copy(Command, 1, 5) = '/map ' then
            CommandExecuted := ChangeMap(Copy(Command, 6, 255));
    end;

    if CommandExecuted then begin
        if Player <> nil then
            PlayersWriteConsole(Player.Name+' triggered a command ('+Command+')', COLOR_INFO);

        Result := true;
    end else
        Result := false;
end;

function OnAdminCommand(Player: TActivePlayer; Command: string): boolean;
begin
    Result := OnCommand(Player, Command);
end;

function CheckPlayerTeam(Player: TActivePlayer; TeamID: Byte; ShowWarning: boolean): boolean;
begin
    if Player.Team = TeamID then begin
        if ShowWarning then
            Player.WriteConsole('Your team is not allowed to use this.', COLOR_WARN);

        Result := true;
    end else
        Result := false;
end;

procedure OnSpeak(Player: TActivePlayer; Text: string);
begin
    Text := lowercase(trim(Text));
    case Text of
        '!p', '!pause'               : ProcessPause(true);
        '!up', '!unpause'            : ProcessPause(false);
        '!a', '!1', '!red', '!alpha' : if not CheckPlayerTeam(Player, TEAM_ALPHA,      false) then Player.Team := TEAM_ALPHA;
        '!b', '!2', '!blue', '!bravo': if not CheckPlayerTeam(Player, TEAM_BRAVO,      false) then Player.Team := TEAM_BRAVO;
        '!s', '!5', '!spec'          : if not CheckPlayerTeam(Player, TEAM_SPECTATORS, false) then Player.Team := TEAM_SPECTATORS;
        '!r', '!res', '!restart'     : if not CheckPlayerTeam(Player, TEAM_SPECTATORS, true)  then ProcessRestart;
    else
        if (Copy(Text, 1, 5) = '!map ') then
            if not CheckPlayerTeam(Player, TEAM_SPECTATORS, true) then
                ChangeMap(Copy(Text, 6, 255));
    end;
end;

procedure OnTick(Ticks: integer);
begin
    if UnpauseCountdown > 0 then begin
        PlayersWriteConsole('Unpausing in: '+IntToStr(UnpauseCountdown), COLOR_LOG);
        UnpauseCountdown := UnpauseCountdown - 1;
    end else if UnpauseCountdown = 0 then begin
        PlayersWriteConsole('Go!', COLOR_LOG);
        Game.Paused := false;
        UnpauseCountdown := -1;
    end;
end;

procedure Init;
var
    i: byte;
begin
    LoadMaps(MAPS_FILEPATH);

    UnpauseCountdown := -1;

    Game.OnClockTick := @OnTick;
    Game.OnAdminCommand := @OnAdminCommand;

    for i := 1 to PLAYERS_MAX do
    begin
        Players[i].OnCommand := @OnCommand;
        Players[i].OnSpeak := @OnSpeak;
    end;
end;

begin
    Init;
end.


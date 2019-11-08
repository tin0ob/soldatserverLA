{
    WhoIs + GAuth scripts
}
const
    PLAYERS_MAX             = 32;
    TEAMS_MAX               = 5;

    PREFIX_MSG_INCOMING     = '<<' + #9;
    PREFIX_MSG_OUTCOMING    = '>>' + #9;

    PREFIX_DATA_INCOMING    = '<=' + #9;
    PREFIX_DATA_OUTCOMING   = '=>' + #9;

    WHOIS_SKIP_ADMINS       = True;

    AUTH_FAILS_MAX          = 3;
    AUTH_TOKEN_LEN          = 6;
    AUTH_TIMEOUT_NOTIFY     = 15;
    AUTH_TIMEOUT_REQUIRED   = AUTH_TIMEOUT_NOTIFY * 6;
    AUTH_TIMEOUT_PENDING    = AUTH_TIMEOUT_NOTIFY * 1;

type TMessage = record
    ID: integer;
    Text: string;
end;

type TAuthenticationStatus = (AUTH_NONE, AUTH_REQUIRED, AUTH_PENDING, AUTH_OK);

type TAuthenticationData = record
    Status: TAuthenticationStatus;
    IP, HWID: string;
    Timestamp: TDateTime;
    FailedAttempts: integer;
end;

var
    PlayersAuth: array[1..PLAYERS_MAX] of TAuthenticationData;

function SecondsBetween(TimeBegin, TimeEnd: TDateTime): Integer;
begin
    Result := DateTimeToUnix(TimeEnd) - DateTimeToUnix(TimeBegin);
end;

procedure SetAuthStatus(Player: TActivePlayer; NewStatus: TAuthenticationStatus; KeepData: Boolean);
begin
    with PlayersAuth[Player.ID] do begin
        Status := NewStatus;
        Timestamp := Now();

        if KeepData then begin
            HWID := Player.HWID;
            IP := Player.IP;
        end else begin
            HWID := '';
            IP := '';
            FailedAttempts := 0;
        end;
    end;
end;

procedure GameOnLeave(Player: TActivePlayer; Kicked: Boolean);
begin
    SetAuthStatus(Player, AUTH_NONE, False);
end;

function OnAdminCommand(Player: TActivePlayer; Text: string): boolean;
var
    data, message: String;
    i, id: Integer;
    Target: TActivePlayer;
begin
    Result := False;
    Text := LowerCase(Trim(Text));

    if Copy(Text, 1, 7) = '/whois ' then begin
        data := Copy(Text, 8, 255);

        if Length(data) < 3 then
            try
                id := StrToInt(data);
            except
                id := 0;
            end;

        if (id >= 1) and (id <= PLAYERS_MAX) then
            if Players[id].Active and Players[id].Human then
                Target := Players[id];

        if Target = nil then
            for i := 1 to PLAYERS_MAX do begin
                if Players[i].Active and Players[i].Human and (LowerCase(Players[i].Name) = data) then begin
                    Target := Players[i];
                    break;
                end;
            end;

        if Target <> nil then
            if WHOIS_SKIP_ADMINS and Target.IsAdmin then
                message := 'I cannot do this. "' + Target.Name + '" is an admin.'
            else begin
                message := ': /whois HWID: ' + Target.HWID + '; IP: ' + Target.IP + '; Name: '+ Target.Name;
                if Player <> nil then
                    WriteLn(PREFIX_MSG_OUTCOMING + '[' + IntToStr(Player.ID) + '] ' + Player.Name + message)
                else
                    WriteLn(PREFIX_MSG_OUTCOMING + '[0] TCP Admin' + message);
                message := 'Retrieving WhoIs information...';
            end
        else
            message := 'No matches found';

        if Player <> nil then
            Player.Tell(message)
        else
            WriteLn(message);

    end;
end;

function OnPlayerCommand(Player: TActivePlayer; Command: String): Boolean;
var
    AuthToken: string;
begin
    Result := False;
    Command := LowerCase(Trim(Command));

    if Copy(Command, 1, 6) = '/auth ' then begin
        AuthToken := Copy(Command, 7, 255);
        if Length(AuthToken) = AUTH_TOKEN_LEN then
            case PlayersAuth[Player.ID].Status of
            AUTH_REQUIRED:
                begin
                    WriteLn(PREFIX_DATA_OUTCOMING+'AUTH HWID:'+Player.HWID+' TOKEN:'+AuthToken);
                    SetAuthStatus(Player, AUTH_PENDING, True);
                    Player.Tell('Authentication request has been sent...');
                end;
            AUTH_PENDING:
                Player.Tell('You are in process of authentication at the moment.');
            else
                Player.Tell('You have already been authenticated.');
            end
        else
            Player.Tell('Authentication token must be '+IntToStr(AUTH_TOKEN_LEN)+' characters long.');
    end;
end;

function ParseTCPMessage(Message: string): TMessage;
var
    i: integer;
begin
    // '<<' + #9 + '[0] Some text here'
    i := Pos(']', Message);

    with Result do
        try
            ID := StrToInt(Copy(Message, Length(PREFIX_MSG_INCOMING) + 2, i - Length(PREFIX_MSG_INCOMING) - 2));
        except
            ID := 0;
        finally
            Text := Trim(Copy(Message, i + 1, 255));
            if (ID < 0) or (ID > PLAYERS_MAX) then
                ID := 0;
        end;
end;

procedure OnTCPMessage(IP: string; Port: word; Text: string);
var
    Msg: TMessage;
    i: integer;
    HWID: string;
    PlayerFound: boolean;
begin
    if (Copy(Text, 1, Length(PREFIX_MSG_INCOMING)) = PREFIX_MSG_INCOMING) then begin
        Msg := ParseTCPMessage(Text);
        // will "redirect" output to the user mentioned (via ID) in the message
        with Msg do
            if ID > 0 then
                if Players[ID].Active and Players[ID].IsAdmin then
                    Players[ID].Tell(Text)

    end else if (Copy(Text, 1, Length(PREFIX_DATA_INCOMING + 'AUTH HWID:')) = PREFIX_DATA_INCOMING + 'AUTH HWID:') then begin
        i := Pos(':', Text);
        HWID := Trim(Copy(Text, i + 1, 255));
        WriteLn('Authentication is required for HWID: ' + HWID);

        for i := 1 to PLAYERS_MAX do
            if Players[i].HWID = HWID then begin
                if not((PlayersAuth[i].HWID = HWID) and (PlayersAuth[i].Status = AUTH_REQUIRED)) then
                    SetAuthStatus(Players[i], AUTH_REQUIRED, True);

                Players[i].Tell('Authentication required! You have '+IntToStr(AUTH_TIMEOUT_REQUIRED)+' seconds before auto-kick.');
                Players[i].Tell('Please PM SoldatGather#6644 at Discord with "!auth" command and follow instructions.');
                PlayerFound := True;
                break;
            end;

        if not PlayerFound then
            WriteLn('Player with HWID:'+HWID+' was not found');

    end else if (Copy(Text, 1, Length(PREFIX_DATA_INCOMING + 'AUTH OK HWID:')) = PREFIX_DATA_INCOMING + 'AUTH OK HWID:') then begin
        i := Pos(':', Text);
        HWID := Trim(Copy(Text, i + 1, 255));
        WriteLn('Authentication of HWID:'+HWID+' completed.');

        for i := 1 to PLAYERS_MAX do
            if Players[i].HWID = HWID then begin
                SetAuthStatus(Players[i], AUTH_OK, True);
                Players[i].Tell('You''ve been authenticated.');
            end;

    end else if (Copy(Text, 1, Length(PREFIX_DATA_INCOMING + 'AUTH FAIL HWID:')) = PREFIX_DATA_INCOMING + 'AUTH FAIL HWID:') then begin
        i := Pos(':', Text);
        HWID := Trim(Copy(Text, i + 1, 255));
        WriteLn('Authentication of HWID:'+HWID+' failed!');

        for i := 1 to PLAYERS_MAX do
            if Players[i].HWID = HWID then begin
                PlayersAuth[i].FailedAttempts := PlayersAuth[i].FailedAttempts + 1;
                Players[i].Tell('Authentication token is wrong or has expired, try again. You have '+IntToStr(AUTH_FAILS_MAX - PlayersAuth[i].FailedAttempts)+' more attempt(s).');
                if (PlayersAuth[i].FailedAttempts >= AUTH_FAILS_MAX) then
                    Players[i].Kick(TKickConsole)
                else
                    SetAuthStatus(Players[i], AUTH_REQUIRED, True);
            end;
    end;
end;

procedure OnClockTick(Ticks: Integer);
var
    status: string;
    i: byte;
    seconds: integer;
begin
    for i := 1 to PLAYERS_MAX do
        if Players[i].Active and Players[i].Human then begin
            case PlayersAuth[i].Status of
            AUTH_REQUIRED:
                begin
                    {$IFDEF DEBUG}
                    status := 'REQUIRED '+ FormatDateTime('n:ss', Now() - PlayersAuth[i].Timestamp);
                    {$ENDIF}
                    seconds := SecondsBetween(PlayersAuth[i].Timestamp, Now());
                    if (seconds > AUTH_TIMEOUT_NOTIFY) and (seconds mod AUTH_TIMEOUT_NOTIFY = 0) then begin
                        Players[i].Tell('Please PM SoldatGather#6644 at Discord with "!auth" command and follow instructions.');
                        if seconds >= AUTH_TIMEOUT_REQUIRED then
                            Players[i].Kick(TKickConsole);
                    end;
                end;
            AUTH_PENDING:
                begin
                    {$IFDEF DEBUG}
                    status := 'PENDING '+ FormatDateTime('n:ss', Now() - PlayersAuth[i].Timestamp);
                    {$ENDIF}
                    seconds := SecondsBetween(PlayersAuth[i].Timestamp, Now());
                    if (seconds >= AUTH_TIMEOUT_PENDING) and (seconds mod AUTH_TIMEOUT_NOTIFY = 0) then begin
                        WriteLn('Authentication of HWID:'+PlayersAuth[i].HWID+' has timed out...');
                        SetAuthStatus(Players[i], AUTH_NONE, True); // reset status
                    end;
                end;
            else
                status := '';
            end;
            
            {$IFDEF DEBUG}
            if status <> '' then
                WriteLn(Players[i].Name+' ['+IntToStr(PlayersAuth[i].FailedAttempts)+']: '+status);
            {$ENDIF}
        end;

    
end;

var 
    i: Byte;
begin
    Game.OnTCPMessage := @OnTCPMessage;
    Game.OnAdminCommand := @OnAdminCommand;
    Game.OnClockTick := @OnClockTick;
    Game.OnLeave := @GameOnLeave;

    for i := 1 to PLAYERS_MAX do begin
        Players[i].OnCommand := @OnPlayerCommand;
        SetAuthStatus(Players[i], AUTH_NONE, False);
    end;        
end.
{        _                         
     ___| | ___ ____  __
    / __| |/ / '__\ \/ /
    \__ \   <| |   >  < 
    |___/_|\_\_|  /_/\_\
	
	Stats with rank
	Version: 1.0.1

	Credits to: DorkeyDear
}
 
const
 
        playermax = 4;
 
        kills = 0;
        deaths = 1;
        points = 2;
		caps = 3;
 
        rank_filename = 'topranks.txt';
        rank_show = 10; // number of top players to show
        rank_store = 10;  // number of top players to store; this should be greater or equal to rank_show
        rank_dispcolor = $12ff5f;
        msg_dispcolor = $00ffff;
 
        CR = #13;
        LF = #10;
        CRLF = CR + LF;
 
type
        TRank = record
                Points: integer;
                HWID, Name: string;
        end;
		
var
 
        ranks: array of TRank;
        playerdata: array[1..32] of array[0..playermax-1] of integer;

		
function XSplit(const Source: string; const Delimiter: string): tstringarray;
var
  i,x,d: integer;
  s: string;
begin
  d := Length(Delimiter);
  x := 0;
  i := 1;
  SetArrayLength(Result,1);
  while i <= Length(source) do begin
    s := Copy(Source,i,d);
    if s = Delimiter then begin
      Inc(i,d);
      Inc(x,1);
      SetArrayLength(result,x + 1);
    end else begin
      Result[x] := Result[x] + Copy(s,1,1);
      Inc(i,1);
    end;
  end;
end;
 
function XJoin(ary: array of string; splitter: string): string;
var
i: integer;
begin
result := ary[0];
for i := 1 to getarraylength(ary)-1 do begin
        result := result+splitter+ary[i];
        end;
end;
 
// read from the file and set variables pertaining to the ranks
procedure LoadRanks();
var
        i: word;
        data: array of string;
begin
        ranks := [];
        if (FileExists('scripts/' + ScriptName + '/' + rank_filename)) then begin
                data := xsplit(ReadFile('scripts/' + ScriptName + '/' + rank_filename), CRLF);
                SetArrayLength(ranks, GetArrayLength(data) div 3);
                if (GetArrayLength(ranks) > 0) then
                        for i := 0 to GetArrayLength(ranks) - 1 do begin
                                ranks[i].HWID := data[i * 3];
                                ranks[i].Points := StrtoInt(data[i * 3 + 1]);
                                ranks[i].Name := data[i * 3 + 2];
                        end;
        end;
end;
 
// save to the ranks file
procedure SaveRanks();
var
        i: word;
        buffer: string;
begin
        buffer := '';
        if (GetArrayLength(ranks) > 0) then begin
                for i := 0 to GetArrayLength(ranks) - 1 do
                        buffer := buffer
                                + ranks[i].HWID + CRLF
                                + InttoStr(ranks[i].Points) + CRLF
                                + ranks[i].Name + CRLF;
                Delete(buffer, Length(buffer) - 1, 2);
        end;
        WriteFile('scripts/' + ScriptName + '/' + rank_filename, buffer);
end;
 
// check if the player belongs in the ranks, and if so, add the player
// this could be made more efficient
procedure UpdateRanks(const ID: byte);
var
        i, j, lowpoints: integer;
begin
        if (GetArrayLength(ranks) = 0) then
                lowpoints := 0
        else
                lowpoints := ranks[GetArrayLength(ranks) - 1].Points;
 
        // should that person be on the ranks?
        if ((playerdata[ID][points] > lowpoints) or (GetArrayLength(ranks) < rank_store)) then begin
 
                // if that person is already listed in the ranks, remove that person
                for i := 0 to GetArrayLength(ranks) - 1 do
                        if (ranks[i].HWID = GetPlayerStat(ID, 'HWID')) then begin
                                if (GetArrayLength(ranks) >= i + 2) then
                                        for j := i + 1 to GetArrayLength(ranks) - 1 do begin
                                                // ranks[i - 1] := ranks[i];
                                                ranks[j - 1].HWID := ranks[j].HWID;
                                                ranks[j - 1].Name := ranks[j].Name;
                                                ranks[j - 1].Points := ranks[j].Points;
                                        end;
                                SetArrayLength(ranks, GetArrayLength(ranks) - 1);
                                break;
                        end;
               
                // find where the player belongs in the rankings
                for i := 0 to GetArrayLength(ranks) - 1 do
                        if (playerdata[ID][points] > ranks[i].Points) then
                                break;
                SetArrayLength(ranks, GetArrayLength(ranks) + 1);
                if (GetArrayLength(ranks) >= i + 2) then
                        for j := GetArrayLength(ranks) - 1 downto i + 1 do begin
                                //ranks[j + 1] := ranks[j];
                                ranks[j].HWID := ranks[j - 1].HWID;
                                ranks[j].Name := ranks[j - 1].Name;
                                ranks[j].Points := ranks[j - 1].Points;
                        end;
 
                // insert the player into the rankings
                ranks[i].HWID := GetPlayerStat(ID, 'HWID');
                ranks[i].Name := GetPlayerStat(ID, 'Name');
                ranks[i].Points := playerdata[ID][points];
        end;
end;
 
procedure DisplayRank(const ID: byte);
var
        i: word;
begin
        if (GetPlayerStat(ID, 'Active') = true) then
                if (GetPlayerStat(ID, 'Human') = true) then begin
                        if (GetArrayLength(ranks) > 0) then
                                for i := 0 to GetArrayLength(ranks) - 1 do
                                        if (ranks[i].HWID = GetPlayerStat(ID, 'HWID')) then begin
                                                WriteConsole(ID, 'Tu ranking actual es ' + InttoStr(i + 1) + ' de ' + InttoStr(GetArrayLength(ranks)) + ' dentro de ' + InttoStr(ranks[i].Points) + ' jugadores!', rank_dispcolor);
                                                exit;
                                        end;
								WriteConsole(ID, 'Tu no tienes un ranking.', rank_dispcolor);
                end else
                        WriteConsole(ID, 'No puedes ver el ranking de todos los jugadores.', rank_dispcolor)
			else
                WriteConsole(ID, 'No puedes obtener el ranking del Jugador.', rank_dispcolor)
end;
 
// display the top ranks
procedure DisplayRanks(const ID: byte);
var
        i, High: integer;
begin

        if (GetArrayLength(ranks) > 0) then begin
                if (GetArrayLength(ranks) < rank_show) then
                        high := GetArrayLength(ranks) - 1
                else
                        high := rank_show - 1;
                WriteConsole(ID, 'Top ' + InttoStr(high + 1) + ' ranked players:', rank_dispcolor);
                for i := 0 to high do
                        WriteConsole(ID, InttoStr(i + 1) + '. ' + ranks[i].Name + ' - ' + InttoStr(ranks[i].Points) + ' pts.', rank_dispcolor);
        end else
                WriteConsole(ID, 'No existen jugadores para crear un ranking.', rank_dispcolor);
end;
 
procedure LoadPlayer(ID: byte);
var
i: integer;
tempdata: array of string;
begin
if GetPlayerStat(ID, 'Active') then begin
        if FileExists('scripts/'+ScriptName+'/players/'+GetPlayerStat(ID, 'HWID')+'.txt') then begin
                tempdata := xsplit(ReadFile('scripts/'+scriptname+'/players/'+GetPlayerStat(ID, 'HWID')+'.txt'),chr(13)+chr(10));
                for i := 0 to playermax-1 do playerdata[ID][i] := strtoint(tempdata[i]);
                end else begin
                        for i := 0 to playermax-1 do playerdata[ID][i] := 0;
                end;
        end;
end;
 
procedure SavePlayer(ID: byte);
var
i: integer;
tempdata: array of string;
begin
if GetPlayerStat(ID, 'Active') then begin
        setarraylength(tempdata,playermax);
        for i := 0 to playermax-1 do tempdata[i] := inttostr(playerdata[ID][i]);
        WriteFile('scripts/'+ScriptName+'/players/'+GetPlayerStat(ID, 'HWID')+'.txt',xjoin(tempdata,chr(13)+chr(10)));
        end;
end;

procedure ShowPlayerStats(ID: byte);
var
KD: double;
i:word;
begin

// rate
KD := single(playerdata[ID][kills])/single(playerdata[ID][deaths]);

WriteConsole(ID,'Stats por jugador: '+GetPlayerStat(ID, 'Name'),msg_dispcolor);
WriteConsole(ID,'Kills o Asesinatos            - '+IntToStr(playerdata[ID][kills]),msg_dispcolor);
WriteConsole(ID,'Deaths o Muertes            - '+IntToStr(playerdata[ID][deaths]),msg_dispcolor);
WriteConsole(ID,'Flag capturadas         - '+IntToStr(playerdata[ID][caps]),msg_dispcolor);
WriteConsole(ID,'Ratio K/D         - '+FormatFloat('0.00',KD)+' ('+inttostr(playerdata[ID][points])+'/'+inttostr(playerdata[ID][deaths])+')',msg_dispcolor);
WriteConsole(ID,' Total de puntos      - '+IntToStr(playerdata[ID][points]),msg_dispcolor);
end;

 
procedure ActivateServer();
begin
    LoadRanks();
end;
 
procedure OnPlayerSpeak(ID: Byte; Text: string);
begin
 
        // !top - Muestra a los mejores jugadores
        if ((LowerCase(Text) = '!top') or (LowerCase(Text) = '!top' + InttoStr(rank_show)) or (LowerCase(Text) = '!rankings') or (LowerCase(Text) = '!ranks')) then begin
            DisplayRanks(ID);
			exit;
			
        // !rank - Muestra tu ranking, si es que existe
        end else if ((LowerCase(Text) = '!rank') or (LowerCase(Text) = '!mi rank')) then begin
            DisplayRank(ID);
            exit;
				
		end else if (LowerCase(Text) = '!stats') then ShowPlayerStats(ID);
end;
 
procedure OnMapChange(NewMap: String);
var 
i: byte;
begin
        for i := 1 to 32 do
                if (GetPlayerStat(i, 'Active') = true) then
                        if (GetPlayerStat(i, 'Human') = true) then begin
                                SavePlayer(i);
                                UpdateRanks(i);
							WriteConsole(i,'Ranking Actualizado',rank_dispcolor);
                        end;
        SaveRanks();
end;

procedure OnJoinGame(ID, Team: byte);
begin
if GetPlayerStat(ID, 'Human') then begin
        LoadPlayer(ID);
	    UpdateRanks(ID);
    end;
end;

procedure OnFlagScore(ID, TeamFlag: byte);
begin
if GetPlayerStat(ID, 'Human') then playerdata[ID][caps] := playerdata[ID][caps] + 1;
if GetPlayerStat(ID, 'Human') then playerdata[ID][points] := playerdata[ID][points] + 3;
end;
 
procedure OnLeaveGame(ID, Team: byte;Kicked: boolean);
begin
if GetPlayerStat(ID, 'Human') then begin
        SavePlayer(ID);
        UpdateRanks(ID);
    end;
    SaveRanks();
end;

procedure OnPlayerKill(Killer, Victim: byte;Weapon: string);
begin
if killer <> victim then begin
        playerdata[victim][deaths] := playerdata[victim][deaths] + 1;
        playerdata[killer][kills] := playerdata[killer][kills] + 1;
        playerdata[killer][points] := playerdata[killer][points] + 1;
end;
end;

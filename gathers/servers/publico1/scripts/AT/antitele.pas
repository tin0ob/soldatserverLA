//**Speed/Teleport Anti-Hack by Snowy**

const
  TIMEAFTERCLEAR = 3; //determines how long a person has to move around after a position changing event, in seconds
  DISTANCEPERSECOND = 640; //determines how far a person must move to be kicked, in pixels
  WARNINGSPERJOIN = 3; //how many warnings a person gets (until they rejoin)
  EASYONLAGGERS = 1; //if this is selected, high pingers will get a greater distance to cover before being kicked
  PINGDISTANCE = 1; //how much more distance for laggers, eg if this is 1, a 500 pinger will get 500 extra distance

var
recompiler: integer;
clear: array[1..32] of integer;
warnings: array[1..32] of integer;
x: array[1..32] of integer; 
y: array[1..32] of integer;

procedure ActivateServer();
begin
recompiler := 1;
end;

procedure OnPlayerRespawn(ID: Byte);
begin
clear[ID] := TIMEAFTERCLEAR;
end;

procedure OnLeaveGame(ID, Team: byte;Kicked: boolean);
begin
clear[ID] := TIMEAFTERCLEAR;
end;

procedure OnJoinTeam(ID, Team: byte);
begin
clear[ID] := TIMEAFTERCLEAR;
end;

procedure OnJoinGame(ID, Team: byte);
begin
warnings[ID] := WARNINGSPERJOIN;
clear[ID] := TIMEAFTERCLEAR;
end;

procedure AppOnIdle(Ticks: integer);
var i: integer;

begin
for i:=1 to 32 do

if GetPlayerStat(i,'active') = true then begin

if clear[i] = 0 then begin
if recompiler = 0 then begin

if EASYONLAGGERS = 1 then begin
if Distance(GetPlayerStat(i,'x'),GetPlayerStat(i,'y'),x[i],y[i]) > DISTANCEPERSECOND + (GetPlayerStat(i,'Ping') * PINGDISTANCE) then begin

if warnings[i] > 0 then begin
warnings[i] := warnings[i] - 1;
if warnings[i] > 0 then begin
WriteConsole(i,'Possible speed hack detected - ' + inttostr(warnings[i]) + ' warning(s) left',$00FF0000);
end;
end;

if warnings[i] = 0 then begin
Command('/say ' + idtoname(i) + ' kicked for possible speed/teleport hacks');
Command('/kick ' + inttostr(i));
end;

end;
end;

if EASYONLAGGERS = 0 then begin
if Distance(GetPlayerStat(i,'x'),GetPlayerStat(i,'y'),x[i],y[i]) > DISTANCEPERSECOND then begin

if warnings[i] > 0 then begin
warnings[i] := warnings[i] - 1;
if warnings[i] > 0 then begin
WriteConsole(i,'Possible speed hack detected - ' + inttostr(warnings[i]) + ' warning(s) left',$00FF0000);
end;
end;

if warnings[i] = 0 then begin
Command('/say ' + idtoname(i) + ' kicked for possible speed/teleport hacks');
Command('/kick ' + inttostr(i));
end;

end;
end;

end;
end;


if clear[i] > 0 then begin
clear[i] := clear[i] - 1;
end;

x[i] := GetPlayerStat(i,'x');
y[i] := GetPlayerStat(i,'y');


end;

recompiler := 0;

end;

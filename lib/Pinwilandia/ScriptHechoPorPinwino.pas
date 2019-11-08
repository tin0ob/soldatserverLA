CONST
	{EDITABLES}
	SEGUNDOS = 3; // para el conteo regresivo de quitar pausa
	CLONES_PERMITIDOS = 1; // cuantas veces se puede repetir una IP
	CLAVE = ''; // clave por defecto
	
VAR
	pausado						:boolean;
	unpause						:boolean;
	conteoPausa					:integer;
	matchEnCurso					:boolean;
	matchPlayers					:integer;
	

{Entrega la palabra correspondiente al indice indicado, dado un string}
FUNCTION Lindex (Index :integer; Str :string) :string;
VAR
	cont		:byte;
	i			:byte;
	resultado	:string;
BEGIN
	cont := 0;
	i := 0;
	WHILE (cont < Index) DO
		BEGIN
		i := Pos(' ', Str);
		cont := cont + 1;
		IF i <> 0 THEN
			BEGIN
			resultado := Copy(Str, 1, i-1);
			Str := Copy(Str, i+1, Length(Str));
			END
		ELSE
			BEGIN
			resultado := Str;
			BREAK;
			END;
		END;
	IF (i <> 0) OR ((i = 0) AND (cont = Index)) THEN
		BEGIN
		Result := resultado;
		END
	ELSE IF (i = 0) THEN
		BEGIN
		Result := '';
		END;
END;

{Revisa si el contenido de un texto es un valor numerico}
FUNCTION esNumero (Str :string) :boolean;
VAR
	tmp		:Extended;
BEGIN
	TRY
		BEGIN
		tmp := StrToFloat(Str);
		Result := true;
		END
	EXCEPT
		BEGIN
		Result := false;
		END
	END;
END;

{Este es una especie de main loop}
PROCEDURE AppOnIdle(Ticks: integer);	
BEGIN
	IF (unpause = true) THEN
		BEGIN
			IF (conteoPausa = 0) THEN
				BEGIN
					Command('/SAY Avispense en 3!!!');
					Command('/SAY Juege');
					Command('/UNPAUSE');
					unpause := false;
				END
			ELSE IF (conteoPausa > 0) THEN
				BEGIN
					Command('/SAY ' + IntToStr(conteoPausa));
					conteoPausa := conteoPausa - 1;
				END;
		END;
END;

{Cuando un weon habla por el chat}
PROCEDURE OnPlayerSpeak(ID: byte; Text: string);
VAR
	argumentos		:Array [1..100] of string;
	tmpClave		:integer;
	i			 :integer;
	comando			:string;
BEGIN
	comando := LowerCase(Lindex(1, Text));
	IF ( (comando = '!pause') OR (comando = '!p') ) AND (pausado = false) AND (GetPlayerStat(ID,'team')<>5) THEN
		BEGIN
			IF (unpause = true) THEN
				BEGIN
					unpause := false;
					Command('/SAY Cuenta regresiva cancelada...');
				END;
			Command('/PAUSE');
			pausado := true;
		END
	ELSE IF ( (comando = '!unpause') OR (comando = '!up') ) AND (pausado = true) AND (GetPlayerStat(ID,'team')<>5) THEN
		BEGIN
			unpause := true;
			pausado := false;
			Command('/SAY Quitando pausa en:');
			conteoPausa := SEGUNDOS;
		END
	ELSE IF (comando = '!alpha') OR (comando = '!a') THEN
		BEGIN
			IF (matchEnCurso) THEN
				BEGIN
					IF (AlphaPlayers < matchPlayers/2) AND (GetPlayerStat(ID, 'Team') <> 1) THEN
						BEGIN
							Command('/SETTEAM1 ' + IntToStr(ID));
						END
					ELSE IF (AlphaPlayers < matchPlayers/2) THEN
						BEGIN
							Command('/SAY ERROR => ' + IDToName(ID) + ': Ya perteneces al equipo Alpha');
						END;
				END
			ELSE IF (GetPlayerStat(ID, 'Team') = 1) THEN
				BEGIN
					Command('/SAY ERROR => ' + IDToName(ID) + ': Ya perteneces al equipo Alpha');
				END
			ELSE
				BEGIN
					Command('/SETTEAM1 ' + IntToStr(ID));
				END;
		END
	ELSE IF (comando = '!bravo') OR (comando = '!b') THEN
		BEGIN
			IF (matchEnCurso) THEN
				BEGIN
					IF (BravoPlayers < matchPlayers/2) AND (GetPlayerStat(ID, 'Team') <> 2) THEN
						BEGIN
							Command('/SETTEAM2 ' + IntToStr(ID));
						END
					ELSE IF (BravoPlayers < matchPlayers/2) THEN
						BEGIN
							Command('/SAY ERROR => ' + IDToName(ID) + ': Ya perteneces al equipo Bravo');
						END;
				END
			ELSE IF (GetPlayerStat(ID, 'Team') = 2) THEN
				BEGIN
					Command('/SAY ERROR => ' + IDToName(ID) + ': Ya perteneces al equipo Bravo');
				END
			ELSE
				BEGIN
					Command('/SETTEAM2 ' + IntToStr(ID));
				END;
		END
	ELSE IF (comando = '!spect') OR (comando = '!s') THEN
		BEGIN
			Command('/SETTEAM5 ' + IntToStr(ID));
		END
	ELSE IF	( (comando = '!restart') OR (comando = '!r') ) AND (GetPlayerStat(ID,'team')<>5) THEN
		BEGIN
			Command('/RESTART');
		END
	ELSE IF ( (comando = '!unbanlast') OR (comando = '!ub') ) AND (GetPlayerStat(ID,'team')<>5) THEN
		BEGIN
			Command('/UNBANLAST');
			Command('/SAY Unbanlast Aplicado!!!!!!!!!!');
			Command('/SAY Cuando juegas sin desbaniar pipol el juego se vuelve juego rial no fake 100%');
			Command('/SAY El jugador baniado te lo agradece');
		END
	ELSE IF (comando = '!map') AND (GetPlayerStat(ID,'team')<>5) THEN
		BEGIN
			argumentos[1] := LowerCase(Lindex(2, Text));
			IF (argumentos[1] <> '') THEN
				BEGIN
				IF (Copy(argumentos[1], 1, 4) = 'ctf_') THEN
					BEGIN
						argumentos[1] := 'ctf_' + UpperCase(argumentos[1][5]) + Copy(argumentos[1], 6, Length(argumentos[1]));
					END
			ELSE	 IF (Copy(argumentos[1], 1, 4) = 'htf_') THEN
					BEGIN
						argumentos[1] := 'htf_' + UpperCase(argumentos[1][5]) + Copy(argumentos[1], 6, Length(argumentos[1]));
					END
				ELSE
					BEGIN
						argumentos[1] := UpperCase(argumentos[1][1]) + Copy(argumentos[1], 2, Length(argumentos[1]));
					END;
				Command('/MAP ' + argumentos[1]);
				END;
		END
	ELSE IF (comando = '!setpassword') OR (comando = '!sp') AND (GetPlayerStat(ID,'team')<>5) THEN
		BEGIN
			tmpClave := Random(100,999);
			Command('/PASSWORD ' + IntToStr(tmpClave));
			Command('/SAY Clave modificada a: ' + IntToStr(tmpClave));
		END
	ELSE IF (comando = '!delpassword') OR (comando = '!dp') AND (GetPlayerStat(ID,'team')<>5) THEN
		BEGIN
			Command('/PASSWORD ' + CLAVE);
			Command('/SAY Se ha restaurado a la clave por defecto!!!!!');
			Command('/SAY Password por defecto: cl');
		END
	ELSE IF (comando = '!match') AND (GetPlayerStat(ID,'team')<>5) THEN
		BEGIN
			argumentos[1] := LowerCase(Lindex(2, Text));
			IF (esNumero(argumentos[1])) THEN
				BEGIN					
					i := StrToInt(argumentos[1]);
					IF (i >= 1) AND (i <= 32) THEN
						BEGIN
						matchEnCurso := true;
						matchPlayers := i*2;
						Command('/SAY MATCH ACTIVADO '+argumentos[1]+'vs'+argumentos[1]);
						END;
				END
			ELSE IF (argumentos[1] = 'off') THEN
				BEGIN
				matchEnCurso := false;
				Command('/SAY MATCH DESACTIVADO');
				END;
		END
	ELSE IF (comando = '!cmds') OR (comando = '!help') THEN
		BEGIN
			WriteConsole(ID, '!map <mapa> : para cambiar el mapa', $ADFF2F);
			WriteConsole(ID, '!pause(!P) : para pausar el juego', $FFDEAD);
			WriteConsole(ID, '!unpause!(!up) : para quitar pausa', $FFDEAD);
			WriteConsole(ID, '!unbanlast(!ub) : desbanea la ultima IP baneada', $FF0000);
			WriteConsole(ID, '!restart(!r) : reinicia el mapa', $FFCC33);
			WriteConsole(ID, '!alpha(!a) : para cambiarte al equipo Alpha', $FF0044);
			WriteConsole(ID, '!bravo(!b) : para cambiarte al equipo bravo', $0000AA);
			WriteConsole(ID, '!spect(!s) : para ponerte de espectador', $00FF7F);
			WriteConsole(ID, '!setpassword(!sp): cambia la clave de acceso al servidor', $EE81FAA1);
			WriteConsole(ID, '!delpassword(!dl) : restaura a la clave por defecto', $EE81FAA1);
			WriteConsole(ID, '!match <cantidad|off> : para activar el modo "clan war"', $EE81FAA1);
			WriteConsole(ID, '!rank : para ver tu ranking general', $99FFCC);
			WriteConsole(ID, '!stats : para ver tu estatus', $66FF99);
			WriteConsole(ID, '!ranks : para ver el Ranking de la ID del jugador', $0000BB);
			WriteConsole(ID, '!mi rank : para ver tu ranking actualizado', $99FFCC);
			WriteConsole(ID, '!top : para ver los mejores jugadores en general', $FFFF99);
			WriteConsole(ID, '!maps : para ver los mapas', $FFFF99);
			WriteConsole(ID, 'Administradores: LinkcL y Yngwie', $FFFB82);
		END
	ELSE IF (comando = '!maps') OR (comando = '!mapslist') THEN
		BEGIN 
			WriteConsole(ID, 'ctf_Ash 		|	ctf_Guardian	|	ctf_Beer', $FFDEAD);
			WriteConsole(ID, 'ctf_Laos		|	ctf_Rotten		|	ctf_CareFree', $FFDEAD);
			WriteConsole(ID, 'ctf_B2b		|	ctf_Pod 		|	ctf_Infinity', $FFCC33);
			WriteConsole(ID, 'ctf_Viet 		|	ctf_Viet2 		|	ctf_Conflict', $FF0044);
			WriteConsole(ID, 'ctf_Run 		|	ctf_OldRun 		|	ctf_Runprime', $0000AA);
			WriteConsole(ID, 'ctf_Voland 	|	ctf_Mine		|	ctf_Inam', $00FF7F);
			WriteConsole(ID, 'ctf_Kampf 	|	ctf_OldKampfx2 	| 	ctf_OldKampf', $EE81FAA1);
			WriteConsole(ID, 'ctf_Death 	|	ctf_Equinox		|	ctf_Mayapan', $EE81FAA1);
			WriteConsole(ID, 'ctf_Chernobyl |	ctf_Dropdown	|	ctf_Kampfy', $EE81FAA1);
			WriteConsole(ID, 'ctf_Crashed	|	ctf_Arabic		|	ctf_FlumbleJungle', $99FFCC);
			WriteConsole(ID, 'ctf_Voland 	|	ctf_Voland2		|	ctf_Towers2', $66FF99);
			WriteConsole(ID, 'ctf_Snakebite |	ctf_OldSnakebite|	ctf_Windmill', $0000BB);
			WriteConsole(ID, 'ctf_Maya		|	ctf_OldMaya2	|	ctf_Wire', $99FFCC);
			WriteConsole(ID, 'ctf_Lanubya 	|	ctf_OldLanubya	|	ctf_Stone', $FFFF99);
			WriteConsole(ID, 'ctf_Nuubia	|	ctf_Aftermatch	|	ctf_Canti', $FFFB82);
			WriteConsole(ID, 'ctf_Blako		|	ctf_Caro		|	ctf_Area', $FFDEAD);
			WriteConsole(ID, 'ctf_Fl 		|	ctf_Lava		|	ctf_Conquest', $FFCC33);
			WriteConsole(ID, 'ctf_Paradigm 	|	ctf_Spark		|	ctf_Away', $EE81FAA1);
			WriteConsole(ID, 'ctf_Wretch 	|	ctf_Mine		|	ctf_Mold', $EE81FAA1);
			WriteConsole(ID, 'ctf_X3		|	ctf_Steel		|	ctf_Horror', $EE81FAA1);
			WriteConsole(ID, 'ctf_x2 		|	ctf_Scorpion	|	ctf_OldRuins', $EE81FAA1);
			WriteConsole(ID, 'ctf_IceBeam	|	ctf_Amnesia		|	ctf_MFM', $EE81FAA1);
			WriteConsole(ID, 'ctf_Campeche 	|	ctf_Catch		|	', $EE81FAA1);
			WriteConsole(ID, 'ctf_Hormone	|	ctf_Crucifix	|	', $EE81FAA1);		
		END;
END;

{Cuando un rq entra a un team}
PROCEDURE OnJoinTeam(ID, Team: byte);
VAR
	i			:byte;
	clones			:integer;
	IP			:string;
BEGIN
	clones := 0;
	IF (NumPlayers - NumBots > 1) THEN
		BEGIN
			FOR i := 1 TO NumPlayers DO
				BEGIN
					IF (i <> ID) THEN
						BEGIN
							IF (GetPlayerStat(i, 'IP') = GetPlayerStat(ID, 'IP')) THEN
								BEGIN
									clones := clones + 1;
									Command('/SAY Se ha detectado un clon: ' + IDToName(ID) + ' -> ' + IDToName(i));
								END;
						END;
				END;
			IF (clones > CLONES_PERMITIDOS) THEN
				BEGIN
					Command('/SAY La IP -> ' + GetPlayerStat(ID, 'IP') + ' Hay sobrepasado el limite de clones');
					IP := GetPlayerStat(ID, 'IP');
					Command('/BANIP ' + IP);
					FOR i:= 1 TO NumPlayers DO
						BEGIN
							IF ((GetPlayerStat(i, 'IP') = IP)) THEN
								BEGIN
									Command('/KICK ' + IntToStr(i));
								END;
						END;
					Command('/KICK ' + IntToStr(IPToID(IP)));
				END;
		END;
END;

{Al subir el server}
PROCEDURE ActivateServer();
BEGIN
	pausado := false;
	unpause := false;
	matchEnCurso := false;
END;

{Cuando alguien se une al servidor}
PROCEDURE OnJoinGame(ID, Team: byte);
BEGIN
	IF (matchEnCurso) THEN
		BEGIN
			IF (NumPlayers - NumBots > matchPlayers) THEN
				BEGIN
					Command('/SETTEAM5 ' + IntToStr(ID));
					Command('/GMUTE ' + IntToStr(ID));
				END;
		END;
END;

{Cuando alguien sale del juego}
PROCEDURE OnLeaveGame(ID, Team: byte; Kicked: boolean);
BEGIN
	IF (NumPlayers - NumBots - 1 = 0) THEN
		BEGIN
			Command('/PASSWORD ' + CLAVE);
			matchEnCurso := false;
		END;
END;

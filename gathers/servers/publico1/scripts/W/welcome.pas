//   Vyka's Welcome Message Script  
//   (WM - Welcome Message)
//   /welcome  - activate or deactivate script (admin command)
//   
//   message shows to joining player only!


const
color=$4BA8FF;                                                           // color used to write messages in console, change it ;)


var
status: boolean;

procedure ActivateServer();
begin
	status:=true;                                                                      // on opening server status sets automatically to 1 so WM is active
	WriteLn('Welcome Message Activated');                                              // message on server start
end;

function OnCommand(ID: Byte; Text: string): boolean;
begin
if (Text = '/welcome') then                                                               
	begin
		if (status=false) then
		begin
			status:=true;
			WriteConsole(0,'Welcome Message Activated!', color);                // console message
			WriteLn('Welcome Message Activated!');                              // server message
		end
		else 
		begin 
			status:=false;
			WriteConsole(0,'Welcome Message Deactivated!', color);             // console message
			WriteLn('Welcome Message Deactivated!');                           // server message
		end;
	end;
end;

procedure OnJoinGame(ID, Team: byte);
begin
	if status=true then
		begin
			DrawText(ID,'Bienvenidos a Soldat Chile'+chr(13)+chr(10)+                 // first line of text
				    'Servidor Privado 1'+chr(13)+chr(10)+                   // second line of text
				    '!map ctf_"Nombredelmapa"' +chr(13)+chr(10)+                     // third line of text
				    'Servidor Potenciado por Pionetworks.cl',                                     // last line of text
				     600,RGB(64,157,243),0.09,85,350);                        // here, you must define your own settings. I described them few lines under.
		end;
end;

// ##################################################################################################################################################
//
// If you need, you can add more lines of text. Just copy and paste:
// 'another line of text'+chr(13)+chr(10)+
// and put in in script, for example:
//
//                     DrawText(ID, 'Bienvenido a LASoldat.com | Privado'+chr(13)+chr(10)+                
//				    'Disfruta'+chr(13)+chr(10)+                  
//				    'Digita !cmds para conocer los comandos'+chr(13)+chr(10)+ 
//				    'another line of text'+chr(13)+chr(10)+
//				    'another line of text'+chr(13)+chr(10)+                 
//				    'last line of text.',                                  
//				     600,RGB(64,157,243),0.09,85,350); 
//
// ................................................................................................................................................
//
// procedure DrawText(ID: Byte; Text: string; Delay: Integer; Colour: Longint; Scale: Single;X,Y: Integer)
// 
// Parameter Info:
//   ID (Byte): Player ID to write text to. Set to 0 to write to all players!
//   Text (String): Text to be written to the screen.
//   Delay (Integer): Time in ticks for the text to remain on screen. (60 ticks = 1000 ms)
//   Colour (Longint): Colour the text should be when drawn to the console.
//   Scale (Single): Scale to use for drawing.
//   X (Integer): X position for the text. 1 -> 640
//   Y (Integer): Y position for the text. 1 -> 480
//
//
// Syntax Example: 
// 
// begin
//     DrawText(0,'Hello big world!',330,RGB(255,255,255),0.20,40,240);
//     // Will draw: "Hello big world!" in the center of ALL players screens
// end; 

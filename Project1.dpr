program Project1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  MicrosoftApiAuthenticator,
  key_press_helper,
  MsGraphGetUser in 'MsGraphGetUser.pas';

var
  auth: TMsAuthenticator;
  graph: TMsGraph;
  stop: boolean;
  inp: string;

  tenantId: string;
  clientId: string;
  redirectPort: string;
  redirectPath: string;
  redirectPort_int: integer;
  redirectPort_word: word;
begin

  tenantId := GetEnvironmentVariable('tenantId');
  clientId := GetEnvironmentVariable('clientId');
  redirectPort := GetEnvironmentVariable('redirectPort');
  redirectPath := GetEnvironmentVariable('redirectPath');

  if (tenantId = '') or (clientId = '') or (redirectPath = '') or (redirectPort = '') then
  begin
    Writeln('Please set the following environment variables:');
    Writeln('tenantId');
    Writeln('clientId');
    Writeln('redirectPort');
    Writeln('redirectPath');
    Writeln('Press any key to exit..');
    ReadLn;
    Exit;
  end
  else if not TryStrToInt(redirectPort, redirectPort_int) then
  begin
    Writeln('redirectPort must be a number');
    Writeln('Press any key to exit..');
    ReadLn;
    Exit;
  end
  else if (redirectPort_int < 0) or (redirectPort_int > 65535) then
  begin
    Writeln('redirectPort must be between 0 and 65535');
    Writeln('Press any key to exit..');
    ReadLn;
    Exit;
  end
  else
  begin
    redirectPort_word := redirectPort_int;
    auth := TMsAuthenticator.Create(
      ATDelegated,
      TMsClientInfo.Create(
        tenantId,
        clientId,
        ['User.Read.All'],
        TRedirectUri.Create(redirectPort_word, redirectPath), // YOUR REDIRECT URI (it must be localhost though)
        TMsTokenStorege.CreateEmpty
      ),
      TMsClientEvents.Create(
      procedure(ResponseInfo: THttpServerResponse)
      begin
        ResponseInfo.ContentStream := TStringStream.Create('<title>Login Succes</title>This tab can be closed now :)');  // YOUR SUCCESS PAGE, do whatever you want here
      end,
      procedure(Error: TMsError)
      begin
        Writeln(Format(  // A premade error message, do whatever you want here
          ''
          + '%sStatus: . . . . . %d : %s'
          + '%sErrorName:  . . . %s'
          + '%sErrorDescription: %s'
          + '%sUrl:  . . . . . . %s %s'
          + '%sData: . . . . . . %s',
          [
            sLineBreak, error.HTTPStatusCode, error.HTTPStatusText,
            sLineBreak, error.HTTPerror_name,
            sLineBreak, error.HTTPerror_description,
            sLineBreak, error.HTTPMethod, error.HTTPurl,
            sLineBreak, error.HTTPerror_data
          ]
        ));
      end,
      procedure(out Cancel: boolean)
      begin
        Cancel := KeyPressed(0);  // Cancel the authentication if a key is pressed
        sleep(0); // if you refresh app-messages here you dont need the sleep
        // Application.ProcessMessages;
      end
      )
    );

    graph := TMsGraph.Create(auth, tenantId);

    stop := false;
    while not stop do
    begin
      write('type sysLogin, all or quit: ');
      ReadLn(inp);
      if inp.ToLower = 'quit' then
        stop := true
      else if inp.ToLower = 'all' then
      begin
        Writeln(sLineBreak + graph.GetUsers + sLineBreak);
      end
      else
      begin
        Writeln(sLineBreak + graph.GetUser(inp) + sLineBreak);
      end;
    end;
    Writeln('Goodbye..');
    graph.Free;
    auth.Free;
  end;
end.

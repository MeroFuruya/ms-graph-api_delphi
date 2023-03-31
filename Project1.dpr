program Project1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  MsAuthenticator in 'MsAuthenticator.pas',
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
      TMsAuthenticator.TAthenticatorType.ATDelegated,
      TMsClientInfo.Create(
        tenantId,
        clientId,
        ['User.Read.All'],
        TRedirectUri.Create(redirectPort_word, redirectPath),
        TMsTokenStorege.Create('LMPS')
      ),
      TMsClientEvents.Create(
        procedure(ResponseInfo: THttpServerResponse)
        begin
          ResponseInfo.ContentStream := TStringStream.Create('<title>Login Succes</title>This Tab can be closed now :)');
        end,
        procedure(Error: TMserror)
        begin
          writeln(
            Format(
              ''
              + '%sStatus: . . . . . %d : %s'
              + '%sErrorName: . . .  %s'
              + '%sErrorDescription: %s'
              + '%sUrl: . . . . . .  %s %s'
              + '%sData: . . . . . . %s',
              [
                sLineBreak, error.StatusCode, error.StatusText,
                sLineBreak, error.error_name,
                sLineBreak, error.error_description,
                sLineBreak, error.Method, error.url,
                sLineBreak, error.error_data
              ]
            )
          );
        end,
        procedure(out Cancel: boolean)
        begin

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

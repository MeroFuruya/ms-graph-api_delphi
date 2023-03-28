program Project1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  MsAdAuthenticator in 'MsAdAuthenticator.pas',
  MsAdGraphGetUser in 'MsAdGraphGetUser.pas';

var
  auth: TMsAdAuthenticator;
  graph: TMsAdGraph;
  stop: boolean;
  inp: string;
begin
  auth := TMsAdAuthenticator.Create(
    TMsAdAuthenticator.TAthenticatorType.ATDelegated,
    TMsAdClientInfo.Create(
      '<tenantId>',
      '<clientId>',
      ['User.Read.All'],
      TRedirectUri.Create(0000, '<redirectUri>'),
      TMsAdTokenStorege.Create('LMPS')
    ),
    TMsAdClientEvents.Create(
      procedure(ResponseInfo: THttpServerResponse)
      begin
        ResponseInfo.ContentStream := TStringStream.Create('<title>Login Succes</title>This Tab can be closed now :)');
      end,
      procedure(Error: TMsAderror)
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

  graph := TMsAdGraph.Create(auth, '<tenantId>');

  stop := false;
  while not stop do
  begin
    write('type sysLogin or quit: ');
    ReadLn(inp);
    if inp.ToLower = 'quit' then
      stop := true
    else
    begin
      Writeln('');
      Writeln(graph.GetUser(inp));
    end;
  end;

  Writeln('Goodbye..');
  graph.Free;
  auth.Free;
end.

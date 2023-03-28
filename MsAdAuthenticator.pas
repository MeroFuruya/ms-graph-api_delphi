unit MsAdAuthenticator;

interface

uses
  System.Net.HttpClient,
  System.Net.URLClient,
  System.NetConsts,
  System.NetEncoding,
  System.JSON,
  System.SysUtils,
  System.DateUtils,
  System.StrUtils,
  System.Classes,
  System.IOUtils,
  {$IFDEF MSWINDOWS}
  Winapi.ShellAPI,
  Windows,
  {$ELSEIF POSIX}
  Posix.Stdlib,
  {$ENDIF}
  IdHTTPServer, IdContext, IdCustomHTTPServer, IdSocketHandle, IdURI, IdCustomTCPServer;

type
  TMsAdError = record
    StatusCode: integer;
    StatusText: string;
    url: string;
    Method: string;
    req_Header: TNetHeaders;
    res_header: TNetHeaders;
    error_data: string;
    error_name: string;
    error_description: string;
  end;

  THttpServerResponse = TIdHTTPResponseInfo;
  TRedirectUri = record
  public const
    Transport = 'http://';
    IP = '127.0.0.1';
    Domain = 'localhost';
  private
    function GetRedirectUri: string;
  public
    Port: word;
    URL: string;
    class function Create(Port: word; URL: string): TRedirectUri; static;
  end;

  TMsAdTokenStorege = record
  private const
    FileName = 'MicrosoftAzureAuthentication.bin';
  private type
    TToken = record
      token: string;
      scope: string;
      tenant: string;
      redirectUri: string;
    end;
  private
    Token: TToken;
    AppName: string;
    function BuildFilename(): string;
    procedure store();
    function load(): boolean;
  public
    class function Create(AppName: string): TMsAdTokenStorege; static;
    class function CreateEmpty: TMsAdTokenStorege; static;
  end;

  TMsAdClientInfo = record
  private type
    TScope = record
      scopes: TArray<string>;
      function makeScopeString: string;
    end;
  private
    Tenant,
    ClientId,
    ClientSecret: string;
    Scope: TScope;
    RedirectUri: TRedirectUri;
    TokenStorage: TMsAdTokenStorege;
    function CheckToken: boolean;
  public
    class function Create(Tenant, ClientId: string; Scope: TArray<string>; RedirectUri: TRedirectUri; TokenStorage: TMsAdTokenStorege): TMsAdClientInfo; overload; static;
    class function Create(Tenant, ClientId, ClientSecret: string; Scope: TArray<string>; RedirectUri: TRedirectUri): TMsAdClientInfo; overload; static;
  end;

  TMsAdClientEvents = record
  public type
    // EVENTS
    TOnPageOpen = reference to procedure(ResponseInfo: THttpServerResponse);
    TOnRequestError = reference to procedure(Error: TMsAdError);
    TWhileWaitingOnToken = reference to procedure(out Cancel: boolean);
  public
    OnPageOpen: TOnPageOpen;
    OnRequestError: TOnRequestError;
    WhileWaitingOnToken: TWhileWaitingOnToken;
    class function Create(OnPageOpen: TOnPageOpen; OnRequestError: TOnRequestError; WhileWaitingOnToken: TWhileWaitingOnToken): TMsAdClientEvents; static;
  end;

  TMsAdAuthenticator = class
  private type
    TOnRequestError = TMsAdClientEvents.TOnRequestError;
  public type
    TAthenticatorType = (ATDelegated, ATDeamon);
  private
    FAuthenticatorType: TAthenticatorType;
    // main Vars
    FClientInfo: TMsAdClientInfo;
    FEvents: TMsAdClientEvents;
    function FGetToken: string; virtual; abstract;
    function FForceRefresh: string; virtual; abstract;
    function FGetRequestErrorEvent: TOnRequestError; virtual; abstract;
  public
    class function Create(AuthenticatorType: TAthenticatorType; ClientInfo: TMsAdClientInfo; ClientEvents: TMsAdClientEvents): TMsAdAuthenticator; overload;
  end;

  TMsAdDelegatedAuthenticator = class(TMsAdAuthenticator)
  private
    // HTTP Vars
    FHttpClient: THTTPClient;
    FScope: TMsAdClientInfo.TScope;

    // Token Vars
    FAccesCode: string;
    FAccesCodeSet: boolean;
    FAccesCodeErrorIsCancel: boolean;
    FAccesCodeErrorOccured: boolean;

    FAccesToken: string;

    FAccesTokenExpiresAt: int64;

    FState: string;


    // HTTPServer Events
    procedure FOnCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure FOnIdListenException(AThread: TIdListenerThread; AException: Exception);
    procedure FOnIdException(AContext: TIdContext; AException: Exception);
    procedure FOnIdCommandError(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo; AException: Exception);

    // Helper functions
    function FCreateState: string;

    // auth functions
    function FDoUserAuth(): boolean;
    function FDoRefreshToken(): boolean;

    // main functions
    function FGetToken: string; override;
    function FForceRefresh: string; override;

    function FGetRequestErrorEvent: TMsAdAuthenticator.TOnRequestError; override;
  public
    constructor Create(ClientInfo: TMsAdClientInfo; ClientEvents: TMsAdClientEvents);
    destructor Destroy; override;
  end;

  TMsAdDeamonAuthenticator = class(TMsAdAuthenticator)
  private

    // HTTP Vars
    FHttpClient: THTTPClient;
    FScope: TMsAdClientInfo.TScope;

    // Token Vars
    FAdminConsentGiven: boolean;
    FAdminConsentErrorOccured: boolean;

    FAccesToken: string;

    FAccesTokenExpiresAt: int64;

    FState: string;


    // HTTPServer Events
    procedure FOnCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure FOnIdListenException(AThread: TIdListenerThread; AException: Exception);
    procedure FOnIdException(AContext: TIdContext; AException: Exception);
    procedure FOnIdCommandError(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo; AException: Exception);

    // Helper functions
    function FCreateState: string;

    // auth functions
    function FDoAdminAuth(): boolean;
    function FDoGetNewToken(): boolean;

    // main functions
    function FGetToken: string; override;
    function FForceRefresh: string; override;

    function FGetRequestErrorEvent: TMsAdAuthenticator.TOnRequestError; override;
  public
    constructor Create(ClientInfo: TMsAdClientInfo; ClientEvents: TMsAdClientEvents);
    destructor Destroy; override;
  end;


  TMsAdAdapter = class abstract
  public type
    TAthenticatorType = TMsAdAuthenticator.TAthenticatorType;
  private type
    TOnRequestError = TMsAdAuthenticator.TOnRequestError;
  private
    AAuthenticator: TMsAdAuthenticator;
    function FGetToken: string;
    function FForeRefresh: string;
    function FGetAuthenticatorType: TAthenticatorType;
    function FGetRequestErrorEvent: TOnRequestError;
  protected
    property Token: string read FGetToken;
    property ForceRefresh: string read FForeRefresh;
    property AuthenticatorType: TAthenticatorType read FGetAuthenticatorType;
    property OnRequestError: TOnRequestError read FGetRequestErrorEvent;
  public
    constructor Create(Authenticator: TMsAdAuthenticator);
  end;

implementation

{ TMsAdTokenStorege }

function TMsAdTokenStorege.BuildFilename(): string;
begin
  if self.AppName = '' then self.AppName := extractfilename(paramstr(0));
  Result := IncludeTrailingPathDelimiter(IncludeTrailingPathDelimiter(TPath.GetHomePath)+self.AppName)+TMsAdTokenStorege.FileName;
end;

class function TMsAdTokenStorege.Create(AppName: string): TMsAdTokenStorege;
begin
  Result := Default(TMsAdTokenStorege);
  Result.AppName := AppName;
end;

class function TMsAdTokenStorege.CreateEmpty: TMsAdTokenStorege;
begin
  Result := Default(TMsAdTokenStorege);
end;

function TMsAdTokenStorege.load(): boolean;
var
  AF: TStringStream;
  Aj: TJsonValue;
begin
  Result := False;
  if FileExists(self.BuildFilename()) then
  begin
    // Open File And create stream
    AF := TStringStream.Create;
    try
      AF.LoadFromFile(self.BuildFilename());
      // read data
      Aj := TJSONValue.ParseJSONValue(AF.ReadString(Af.Size));

      Aj.TryGetValue<string>('token', self.Token.token);
      Aj.TryGetValue<string>('scope', self.Token.scope);
      Aj.TryGetValue<string>('tenant', self.Token.tenant);
      Aj.TryGetValue<string>('redirectUri', self.Token.redirectUri);

      Aj.Free;
    finally
      // close File and free stream
      AF.Free;
    end;
    Result := self.Token.token <> '';
  end;
end;

procedure TMsAdTokenStorege.store();
var
  AF: TStringStream;
  Aj: TJSONObject;
begin
  if self.Token.token <> '' then
  begin
    Aj := TJSONObject.Create;
    Aj.AddPair('token', self.Token.token);
    Aj.AddPair('scope', self.Token.scope);
    Aj.AddPair('tenant', self.Token.tenant);
    Aj.AddPair('redirectUri', self.Token.redirectUri);


    // create stream and read token
    AF := TStringStream.Create(aj.ToJSON);
    Aj.Free;
    try
      if not DirectoryExists(IncludeTrailingPathDelimiter(GetHomePath)+self.AppName) then
        CreateDir(IncludeTrailingPathDelimiter(IncludeTrailingPathDelimiter(GetHomePath)+self.AppName));
      // save data to file
      AF.SaveToFile(self.BuildFilename());
    finally
      // free stream
      AF.Free;
    end;
  end;
end;

{ TRedirectUri }

class function TRedirectUri.Create(Port: word; URL: string): TRedirectUri;
begin
  Result := Default(TRedirectUri);
  Result.Port := Port;
  if (URL <> URL.Empty) and (not URL.StartsWith('/')) then URL := '/' + URL;
  Result.URL := URL;
end;

function TRedirectUri.GetRedirectUri: string;
begin
  Result := TNetEncoding.URL.Encode(self.Transport + self.Domain + ':' + IntToStr(self.Port) + self.URL);
end;

class function TMsAdClientInfo.Create(Tenant, ClientId: string;
  Scope: TArray<string>; RedirectUri: TRedirectUri; TokenStorage: TMsAdTokenStorege): TMsAdClientInfo;
begin
  Result := Default(TMsAdClientInfo);
  Result.Tenant := Tenant;
  Result.ClientId := ClientId;
  Result.Scope.scopes := Scope;
  Result.RedirectUri := RedirectUri;
  Result.TokenStorage := TokenStorage;
end;

function TMsAdClientInfo.CheckToken: boolean;
begin
  result := (
    (self.TokenStorage.Token.token <> '') and
    (self.TokenStorage.Token.scope = self.Scope.makeScopeString) and
    (self.TokenStorage.Token.tenant = self.Tenant) and
    (self.TokenStorage.Token.redirectUri = self.RedirectUri.GetRedirectUri)
  );
end;

class function TMsAdClientInfo.Create(Tenant, ClientId, ClientSecret: string;
  Scope: TArray<string>; RedirectUri: TRedirectUri): TMsAdClientInfo;
begin
Result := Default(TMsAdClientInfo);
  Result.Tenant := Tenant;
  Result.ClientId := ClientId;
  Result.ClientSecret := ClientSecret;
  Result.Scope.scopes := Scope;
  Result.RedirectUri := RedirectUri;
end;

{ TMsAdClientEvents }

class function TMsAdClientEvents.Create(OnPageOpen: TOnPageOpen;
  OnRequestError: TOnRequestError;
  WhileWaitingOnToken: TWhileWaitingOnToken): TMsAdClientEvents;
begin
  Result.OnPageOpen := OnPageOpen;
  result.OnRequestError := OnRequestError;
  Result.WhileWaitingOnToken := WhileWaitingOnToken;
end;

{ TMsAdDelegatedAuthenticator }

constructor TMsAdDelegatedAuthenticator.Create(ClientInfo: TMsAdClientInfo;
  ClientEvents: TMsAdClientEvents);
begin
  inherited Create;
  self.FAuthenticatorType := TAthenticatorType.ATDelegated;
  // setup HTTP Client
  self.FHttpClient := THTTPClient.Create;
  self.FHttpClient.Accept := 'application/json';
  self.FHttpClient.ContentType := 'application/x-www-form-urlencoded';
  self.FHttpClient.AcceptCharSet := TEncoding.UTF8.EncodingName;

  // set Variables
  self.FClientInfo := ClientInfo;
  self.FEvents := ClientEvents;
  self.FScope := ClientInfo.Scope;
end;

destructor TMsAdDelegatedAuthenticator.Destroy;
begin
  if self.FClientInfo.CheckToken then
  begin
    self.FClientInfo.TokenStorage.store;
  end;
  self.FHttpClient.Free;
  inherited;
end;

function TMsAdDelegatedAuthenticator.FDoRefreshToken: boolean;
var
  AUrl: string;
  ARequest: IHTTPRequest;
  AResponse: IHTTPResponse;
  ARequestData: TStringStream;

  AResponseJson: TJSONValue;
  AExpiresIn: int64;

  AError: TMsAdError;
begin
  // build Url
  AUrl := ''
  + 'https://login.microsoftonline.com/'
  + self.FClientInfo.Tenant + '/oauth2/v2.0/token';
  // create Request object
  ARequest := self.FHttpClient.GetRequest(sHTTPMethodPost, AUrl);
  // create Request Stream
  ARequestData := TStringStream.Create(''
  + 'client_id=' + self.FClientInfo.ClientId
  + '&scope=' + self.FScope.makeScopeString
  + '&refresh_token=' + self.FClientInfo.TokenStorage.Token.token
  + '&redirect_uri=' + self.FClientInfo.RedirectUri.GetRedirectUri
  + '&grant_type=refresh_token');
  ARequest.SourceStream := ARequestData;
  // Execute Request
  AResponse := self.FHttpClient.Execute(ARequest);
  // Free Request Data Stream
  ARequestData.Free;

  // try to parse the response data
  AResponseJson := TJSONValue.ParseJSONValue(AResponse.ContentAsString(TEncoding.UTF8));

  //Check Response and Extract Data
  if AResponse.StatusCode <> 200 then
  begin
    AError.error_data := AResponse.ContentAsString(TEncoding.UTF8);
    AError.StatusCode := AResponse.StatusCode;
    AError.StatusText := AResponse.StatusText;
    Result := False;

    // containing an error message (maybe)
    if AResponseJson.TryGetValue<string>('error', AError.error_name) then
    begin
      AError.error_data := AResponse.ContentAsString(TEncoding.UTF8);

      AResponseJson.TryGetValue<string>('error_description', AError.error_description);
      // check if the error is an "refresh Token Expired Message"
      if (AError.error_description = 'invalid_grant') and ContainsText(AError.error_description, 'AADSTS700082') then
      begin
        // Refresh token expired so do user auth
        Result := self.FDoUserAuth;
      end;
    end;

    if not Result then
      self.FEvents.OnRequestError(AError);

  end
  else
  begin
    // parse the response data containing the Token :)
    AResponseJson.TryGetValue<string>('access_token', self.FAccesToken);
    AResponseJson.TryGetValue<string>('refresh_token', self.FClientInfo.TokenStorage.Token.token);
    AResponseJson.TryGetValue<int64>('expires_in', AExpiresIn);
    // AResponseJson.TryGetValue<int64>('ext_expires_in', AExtExpiresIn);

    // calculate expiration time
    self.FAccesTokenExpiresAt := HttpToDate(AResponse.Date, True).ToUnix(True) + AExpiresIn;
    // Acces Token is Gathered so there we go:
    Result := True;
  end;
  // Free JsonResponse Object
  AResponseJson.Free;
end;

function TMsAdDelegatedAuthenticator.FDoUserAuth: boolean;
var
  AHttpServer: TIdHTTPServer;
  ACancel: boolean;
  AUrl: string;
  ARequest: IHttpRequest;
  ARequestData: TStringStream;
  AResponse: IHttpResponse;

  AResponseJson: TJSONValue;

  AExpiresIn: int64;

  AError: TMsAdError;
begin
  self.FAccesCodeSet := false;
  self.FAccesCodeErrorOccured := false;
  // run server and aquire AccesCode
  AHttpServer := TIdHTTPServer.Create();
  AHttpServer.Bindings.Add.SetBinding(self.FClientInfo.RedirectUri.IP, self.FClientInfo.RedirectUri.Port);
  AHttpServer.OnException := self.FOnIdException;
  AHttpServer.OnListenException := self.FOnIdListenException;
  AHttpServer.OnCommandError := self.FOnIdCommandError;
  AHttpServer.OnCommandGet := self.FOnCommandGet;
  AHttpServer.Active := True;

  // Create New State
  self.FState := Self.FCreateState;
  // open the Browser
  AUrl := ''
  + 'https://login.microsoftonline.com/'
  + self.FClientInfo.Tenant
  + '/oauth2/v2.0/authorize'
  + '?client_id=' + self.FClientInfo.ClientId
  + '&response_type=code'
  + '&redirect_uri=' + self.FClientInfo.RedirectUri.GetRedirectUri
  + '&response_mode=query'
  + '&scope=' + self.FScope.makeScopeString
  + '&state=' + self.FState;
  {$IFDEF MSWINDOWS}
  ShellExecute(0, 'open', PChar(AUrl), nil, nil, SW_SHOWNORMAL);
  {$ELSEIF POSIX}
  _system(PAnsiChar('open ' + AnsiString(AUrl)));
  {$ENDIF}

  // Wait for AccesCode to be aquired
  while (not self.FAccesCodeSet) and (not ACancel) and (not self.FAccesCodeErrorOccured) do self.FEvents.WhileWaitingOnToken(ACancel);

  // shutdown HttpServer
  AHttpServer.Active := false;
  AHttpServer.Free;

  if (not ACancel) and (not self.FAccesCodeErrorOccured) then
  begin
    // Get Acces Token With Acces Code
    // build Url
    AUrl := ''
    + 'https://login.microsoftonline.com/'
    + self.FClientInfo.Tenant + '/oauth2/v2.0/token';
    // create Request object
    ARequest := self.FHttpClient.GetRequest(sHTTPMethodPost, AUrl);
    // create Request Stream
    ARequestData := TStringStream.Create(''
    + 'client_id=' + self.FClientInfo.ClientId
    + '&scope=' + self.FScope.makeScopeString
    + '&code=' + self.FAccesCode
    + '&redirect_uri=' + self.FClientInfo.RedirectUri.GetRedirectUri
    + '&grant_type=authorization_code');
    ARequest.SourceStream := ARequestData;
    // Execute Request
    AResponse := self.FHttpClient.Execute(ARequest);
    // Free Request Data Stream
    ARequestData.Free;

    // try to parse the response data
    AResponseJson := TJSONValue.ParseJSONValue(AResponse.ContentAsString(TEncoding.UTF8));

    // Check Response And Extract Data
    if AResponse.StatusCode <> 200 then
    begin
      AError.error_data := AResponse.ContentAsString(TEncoding.UTF8);
      AError.StatusCode := AResponse.StatusCode;
      AError.StatusText := AResponse.StatusText;
      Result := False;

      // containing an error message (maybe)
      if AResponseJson.TryGetValue<string>('error', AError.error_name) then
      begin
        AError.error_data := AResponse.ContentAsString(TEncoding.UTF8);

        AResponseJson.TryGetValue<string>('error_description', AError.error_description);
      end;

      if not Result then
        self.FEvents.OnRequestError(AError);

    end
    else
    begin
      // parse the response data containing the Token :)
      AResponseJson.TryGetValue<string>('access_token', self.FAccesToken);
      AResponseJson.TryGetValue<string>('refresh_token', self.FClientInfo.TokenStorage.Token.token);
      AResponseJson.TryGetValue<int64>('expires_in', AExpiresIn);
      // AResponseJson.TryGetValue<int64>('ext_expires_in', AExtExpiresIn);

      // set correct values of token storage
      self.FClientInfo.TokenStorage.Token.scope := self.FScope.makeScopeString;
      self.FClientInfo.TokenStorage.Token.tenant := self.FClientInfo.Tenant;
      self.FClientInfo.TokenStorage.Token.redirectUri := self.FClientInfo.RedirectUri.GetRedirectUri;

      // calculate expiration time
      self.FAccesTokenExpiresAt := HttpToDate(AResponse.Date, True).ToUnix(True) + AExpiresIn;
      // Acces Token is Gathered so there we go:
      Result := True;
    end;
    AResponseJson.Free;
  end
  else
  begin
    Result := False;
  end;
end;

function TMsAdDelegatedAuthenticator.FForceRefresh: string;
begin
  if self.FClientInfo.TokenStorage.Token.token = '' then
    self.FClientInfo.TokenStorage.load;
  if Self.FDoRefreshToken then
    Result := self.FAccesToken
  else
    Result := '';
end;

function TMsAdDelegatedAuthenticator.FCreateState: string;
const
  StateDefaultLength = 200;
var
  AI: integer;
  AData: string;
begin
  // Create State
  for AI := 0 to StateDefaultLength do
  begin
    AData := AData + Char(Random(128));
  end;
  Result := TNetEncoding.Base64URL.Encode(AData);
end;

function TMsAdDelegatedAuthenticator.FGetRequestErrorEvent: TMsAdAuthenticator.TOnRequestError;
begin
  Result := self.FEvents.OnRequestError;
end;

function TMsAdDelegatedAuthenticator.FGetToken: string;
var
  ok: boolean;
begin
  if (self.FClientInfo.TokenStorage.Token.token = '') and not self.FClientInfo.CheckToken then
  begin
    // Refresh Token Is empty so it is tried to be loaded or a user auth must be done
    if self.FClientInfo.TokenStorage.load then
    begin
      if self.FClientInfo.CheckToken then
      begin
        // the Refresh Token was loaded
        ok := self.FDoRefreshToken;
      end
      else
      begin
        // The Refresh Token couldnt be loaded
        ok := self.FDoUserAuth;
      end;
    end
    else
    begin
      // The Refresh Token couldnt be loaded
      ok := self.FDoUserAuth;
    end;
  end
  else
  begin
    // the Refresh Token isnt Empty
    if self.FAccesToken = '' then
    begin
      // The Acces Token Is Empty so a refresh must be done
      ok := self.FDoRefreshToken;
    end
    else
    begin
      // the acces token isnt empty either
      if self.FAccesTokenExpiresAt <= TDateTime.NowUTC.ToUnix(True) then
      begin
        // The Acces Token Expired So a refresh must be done
        ok := self.FDoRefreshToken;
      end
      else
      begin
        // the acces token should be valid
        ok := true;
      end;
    end;
  end;

  if ok then
  begin
    // acces token should be ok so everything is fine
    Result := self.FAccesToken;
  end
  else
  begin
    // acces token isnt ok so a empty string is returned
    Result := '';
  end;
end;

procedure TMsAdDelegatedAuthenticator.FOnCommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
const
  Code = 'code';
  State = 'state';
  Error = 'error';
  Adminconstent = 'admin_consent';
  Error_unknown = 'unknown';
  ErrorDescription = 'error_description';
  Error_invalidRequest = 'invalid_request';
  Error_invalidRequestDescription = 'The "state" of the answer from Microsoft was not correct.';
var
  AError, AErrorDescription: string;
  AParams: TStringList;
begin
  // parse Url Params
  AParams := TStringList.Create;
  AParams.Delimiter := '&';
  AParams.StrictDelimiter := true;
  AParams.DelimitedText := ARequestInfo.QueryParams;
  // handle connection
  if (AParams.Values[Code] <> '') and (AParams.Values[State] <> '') then
  begin
    // Check if State is correct
    if AParams.Values[State] = Self.FState then
    begin
      // save Acces Code
      self.FAccesCode := AParams.Values[Code];
    end
    else
    begin
      // in case the state is not correct, "create" the error
      AError := Error_invalidRequest;
      AErrorDescription := Error_invalidRequestDescription;
    end;
  end
  else
  begin
    // try to get the error message, if there is none, just say unknown
    AError := AParams.Values[Error];
    if AError = '' then AError := Error_unknown;
    AErrorDescription := AParams.Values[ErrorDescription];
    if AErrorDescription = '' then
    begin
      AErrorDescription := AParams.Values['error_subcode'];
      if AErrorDescription = '' then
        AErrorDescription := Error_unknown;
    end;
  end;
  AParams.Free;

  // create the Response Page
  if (AError <> '') or (AErrorDescription <> '') then
  begin
    self.FAccesCodeErrorOccured := true;
    if (AError = 'access_denied') and (AErrorDescription = 'cancel') then
    begin
      self.FAccesCodeErrorIsCancel := true;
      AResponseInfo.ContentStream := TStringStream.Create(
      '<title>Login cancelled</title>The Authentication process was cancelled. You can close this tab now.'
      );
    end
    else
    begin
      self.FAccesCodeErrorIsCancel := false;
      // when there is an error, the error page is shown
      // TODO: Check if content stream is already a created object
      AResponseInfo.ContentStream := TStringStream.Create(
        '<title>Login error</title><b>Error:</b><br>' + AError +
        '<br><br><b>Description:</b><br>' + AErrorDescription
      );
    end;
  end
  else
  begin
    // if everything is ok, the OnPageOpen function is called and the Response
    // must be built there
    self.FEvents.OnPageOpen(AResponseInfo);
    // Set Variable
    self.FAccesCodeSet := true;
  end;
end;

procedure TMsAdDelegatedAuthenticator.FOnIdCommandError(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo;
  AException: Exception);
begin
end;

procedure TMsAdDelegatedAuthenticator.FOnIdException(AContext: TIdContext;
  AException: Exception);
begin
end;

procedure TMsAdDelegatedAuthenticator.FOnIdListenException(
  AThread: TIdListenerThread; AException: Exception);
begin
end;

{ TMsAdDeamonAuthenticator }

constructor TMsAdDeamonAuthenticator.Create(ClientInfo: TMsAdClientInfo;
  ClientEvents: TMsAdClientEvents);
begin
  inherited Create;
  self.FAuthenticatorType := TAthenticatorType.ATDeamon;
  // setup HTTP Client
  self.FHttpClient := THTTPClient.Create;
  self.FHttpClient.Accept := 'application/json';
  self.FHttpClient.ContentType := 'application/x-www-form-urlencoded';
  self.FHttpClient.AcceptCharSet := TEncoding.UTF8.EncodingName;

  // set Variables
  self.FClientInfo := ClientInfo;
  if self.FClientInfo.ClientSecret = '' then raise Exception.Create('Client secret cannot be empty for Deamon Authenticators');
  self.FEvents := ClientEvents;
  self.FScope := ClientInfo.Scope;
end;

destructor TMsAdDeamonAuthenticator.Destroy;
begin
  self.FHttpClient.Free;
  inherited;
end;

function TMsAdDeamonAuthenticator.FCreateState: string;
const
  StateDefaultLength = 200;
var
  AI: integer;
  AData: string;
begin
  // Create State
  for AI := 0 to StateDefaultLength do
  begin
    AData := AData + Char(Random(128));
  end;
  Result := TNetEncoding.Base64URL.Encode(AData);
end;

function TMsAdDeamonAuthenticator.FDoAdminAuth: boolean;
var
  AHttpServer: TIdHTTPServer;
  ACancel: boolean;
  AUrl: string;
begin
  self.FAdminConsentGiven := false;
  self.FAdminConsentErrorOccured := false;
  // run server and aquire AccesCode
  AHttpServer := TIdHTTPServer.Create();
  AHttpServer.Bindings.Add.SetBinding(self.FClientInfo.RedirectUri.IP, self.FClientInfo.RedirectUri.Port);
  AHttpServer.OnException := self.FOnIdException;
  AHttpServer.OnListenException := self.FOnIdListenException;
  AHttpServer.OnCommandError := self.FOnIdCommandError;
  AHttpServer.OnCommandGet := self.FOnCommandGet;
  AHttpServer.Active := True;

  // Create New State
  self.FState := Self.FCreateState;
  // open the Browser
  AUrl := ''
  + 'https://login.microsoftonline.com/'
  + self.FClientInfo.Tenant
  + '/oauth2/v2.0/authorize'
  + '?client_id=' + self.FClientInfo.ClientId
  + '&redirect_uri=' + self.FClientInfo.RedirectUri.GetRedirectUri
  + '&state=' + self.FState;
  {$IFDEF MSWINDOWS}
  ShellExecute(0, 'open', PChar(AUrl), nil, nil, SW_SHOWNORMAL);
  {$ELSEIF POSIX}
  _system(PAnsiChar('open ' + AnsiString(AUrl)));
  {$ENDIF}

  // Wait for AccesCode to be aquired
  while (not self.FAdminConsentGiven) and (not ACancel) and (not self.FAdminConsentErrorOccured) do self.FEvents.WhileWaitingOnToken(ACancel);

  // shutdown HttpServer
  AHttpServer.Active := false;
  AHttpServer.Free;

  Result := false;
  if not ACancel and (self.FAdminConsentErrorOccured) then
  begin
    Result := Self.FDoGetNewToken;
  end
end;

function TMsAdDeamonAuthenticator.FDoGetNewToken: boolean;
var
  AUrl: string;
  ARequest: IHTTPRequest;
  AResponse: IHTTPResponse;
  ARequestData: TStringStream;

  AResponseJson: TJSONValue;
  AExpiresIn: int64;
  AError: TMsAdError;
begin
  // build Url
  AUrl := ''
  + 'https://login.microsoftonline.com/'
  + self.FClientInfo.Tenant + '/oauth2/v2.0/token';
  // create Request object
  ARequest := self.FHttpClient.GetRequest(sHTTPMethodPost, AUrl);
  // create Request Stream
  ARequestData := TStringStream.Create(''
  + 'client_id=' + self.FClientInfo.ClientId
  + '&scope=' + self.FScope.makeScopeString
  + '&client_secret=' + self.FClientInfo.ClientSecret
  + '&grant_type=client_credentials');
  ARequest.SourceStream := ARequestData;
  // Execute Request
  AResponse := self.FHttpClient.Execute(ARequest);
  // Free Request Data Stream
  ARequestData.Free;

  // try to parse the response data
  AResponseJson := TJSONValue.ParseJSONValue(AResponse.ContentAsString(TEncoding.UTF8));

  //Check Response and Extract Data
  if AResponse.StatusCode <> 200 then
  begin
    AError.error_data := AResponse.ContentAsString(TEncoding.UTF8);
    AError.StatusCode := AResponse.StatusCode;
    AError.StatusText := AResponse.StatusText;
    Result := False;

    // containing an error message (maybe)
    if AResponseJson.TryGetValue<string>('error', AError.error_name) then
    begin

      AResponseJson.TryGetValue<string>('error_description', AError.error_description);

      // check if the error is an "refresh Token Expired Message"
      if (AError.error_name = 'invalid_grant') and ContainsText(AError.error_description, 'AADSTS700082') then
      begin
        // Refresh token expired so do user auth
        Result := self.FDoAdminAuth;
      end
    end;

    if not Result then
      self.FEvents.OnRequestError(AError);
  end
  else
  begin
    // parse the response data containing the Token :)
    AResponseJson.TryGetValue<string>('access_token', self.FAccesToken);
    AResponseJson.TryGetValue<int64>('expires_in', AExpiresIn);
    // AResponseJson.TryGetValue<int64>('ext_expires_in', AExtExpiresIn);

    // calculate expiration time
    self.FAccesTokenExpiresAt := HttpToDate(AResponse.Date, True).ToUnix(True) + AExpiresIn;
    // Acces Token is Gathered so there we go:
    Result := True;
  end;
  // Free JsonResponse Object
  AResponseJson.Free;
end;

function TMsAdDeamonAuthenticator.FForceRefresh: string;
begin
  if self.FDoGetNewToken then
    Result := self.FAccesToken
  else
    Result := '';
end;

function TMsAdDeamonAuthenticator.FGetRequestErrorEvent: TMsAdAuthenticator.TOnRequestError;
begin
  Result := self.FEvents.OnRequestError;
end;

function TMsAdDeamonAuthenticator.FGetToken: string;
var
  ok: boolean;
begin
  if self.FAccesToken = '' then
  begin
    ok := self.FDoGetNewToken;
  end
  else
  begin
    if self.FAccesTokenExpiresAt <= TDateTime.NowUTC.ToUnix(True) then
    begin
      ok := self.FDoGetNewToken;
    end
    else
    begin
      ok := True;
    end;
  end;

  if ok then
    Result := self.FAccesToken
  else
    Result := '';
end;

procedure TMsAdDeamonAuthenticator.FOnCommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
const
  Code = 'code';
  State = 'state';
  Error = 'error';
  Adminconstent = 'admin_consent';
  Error_unknown = 'unknown';
  ErrorDescription = 'error_description';
  Error_invalidRequest = 'invalid_request';
  Error_invalidRequestDescription = 'The "state" of the answer from Microsoft was not correct.';
var
  AError, AErrorDescription: string;
  AParams: TStringList;
begin
  // parse Url Params
  AParams := TStringList.Create;
  AParams.Delimiter := '&';
  AParams.StrictDelimiter := true;
  AParams.DelimitedText := ARequestInfo.QueryParams;
  // handle connection
  if (AParams.Values[Adminconstent] <> '') and (AParams.Values[State] <> '') then
  begin
    // Check if State is correct
    if AParams.Values[State] = Self.FState then
    begin
      // everything is ok :)

    end
    else
    begin
      // in case the state is not correct, "create" the error
      AError := Error_invalidRequest;
      AErrorDescription := Error_invalidRequestDescription;
    end;
  end
  else
  begin
    // try to get the error message, if there is none, just say unknown
    AError := AParams.Values[Error];
    if AError = '' then AError := Error_unknown;
    AErrorDescription := AParams.Values[ErrorDescription];
    if AErrorDescription = '' then AErrorDescription := Error_unknown;
  end;
  AParams.Free;

  // create the Response Page
  if (AError <> '') or (AErrorDescription <> '') then
  begin
    self.FAdminConsentErrorOccured := true;
    // when there is an error, the error page is shown
    // TODO: Check if content stream is already a created object
    AResponseInfo.ContentStream := TStringStream.Create(
      '<b>Error:</b><br>' + AError +
      '<br><br><b>Description:</b><br>' + AErrorDescription
    );
  end
  else
  begin
    // if everything is ok, the OnPageOpen function is called and the Response
    // must be built there
    self.FEvents.OnPageOpen(AResponseInfo);
    // Set Variable
    self.FAdminConsentGiven := true;
  end;
end;

procedure TMsAdDeamonAuthenticator.FOnIdCommandError(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo;
  AException: Exception);
begin

end;

procedure TMsAdDeamonAuthenticator.FOnIdException(AContext: TIdContext;
  AException: Exception);
begin

end;

procedure TMsAdDeamonAuthenticator.FOnIdListenException(
  AThread: TIdListenerThread; AException: Exception);
begin

end;

{ TMsAdAdapter }

constructor TMsAdAdapter.Create(Authenticator: TMsAdAuthenticator);
begin
  self.AAuthenticator := Authenticator;
end;

function TMsAdAdapter.FForeRefresh: string;
begin
  Result := self.AAuthenticator.FForceRefresh;
end;

function TMsAdAdapter.FGetAuthenticatorType: TAthenticatorType;
begin
  Result := self.AAuthenticator.FAuthenticatorType;
end;

function TMsAdAdapter.FGetRequestErrorEvent: TOnRequestError;
begin
  Result := self.AAuthenticator.FGetRequestErrorEvent();
end;

function TMsAdAdapter.FGetToken: string;
var
  AToken: string;
begin
  Result := '';
  AToken := self.AAuthenticator.FGetToken;
  if AToken <> '' then
    Result := 'Bearer ' + AToken;
end;

{ TMsAdAuthenticator }

class function TMsAdAuthenticator.Create(AuthenticatorType: TAthenticatorType;
  ClientInfo: TMsAdClientInfo;
  ClientEvents: TMsAdClientEvents): TMsAdAuthenticator;
begin
  Result := nil;
  case AuthenticatorType of
    ATDelegated: Result := TMsAdDelegatedAuthenticator.Create(ClientInfo, ClientEvents);
    ATDeamon: Result := TMsAdDeamonAuthenticator.Create(ClientInfo, ClientEvents);
  end;
end;

{ TMsAdClientInfo.TScope }

function TMsAdClientInfo.TScope.makeScopeString: string;
var
  AI: integer;
  AEncoded: TArray<string>;
begin
  // URL-Encode scopes
  SetLength(AEncoded, Length(self.scopes));
  for AI := 0 to Length(self.scopes)-1 do AEncoded[AI] := TNetEncoding.URL.Encode(self.scopes[AI]);
  // check if offline Acces Scope is missing and add it if applicable
  if IndexText('offline_access', AEncoded) = -1 then AEncoded := AEncoded + ['offline_access'];
  // join them with ' '
  Result := String.Join(' ', AEncoded);
end;

// seeding so random ist really random
var
  Seeded: boolean;
begin
  if not Seeded then
  begin
    RandSeed := integer(Now.ToUnix()-MainThreadID+integer(@Seeded));
    Seeded := true;
  end;
end.

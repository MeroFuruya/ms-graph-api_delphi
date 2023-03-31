unit MsGraphGetUser;

interface

uses
  System.Net.HttpClient,
  System.NetEncoding,
  System.NetConsts,
  System.JSON,
  System.SysUtils,
  System.StrUtils,
  System.Generics.Collections,
  MsAuthenticator;


type
  TMsGraph = class(TMsAdapter)
  private
    FHTTP: THTTPClient;
    FTenant: string;
    function GetValue(AJ: TJsonValue; AKey: string; var AValue: string): boolean;
  public
    constructor Create(authenticator: TMsAuthenticator; tenantId: string);
    destructor Destroy; override;
    function GetUser(sysLogin: string): string;
    function GetUsers: string;
  end;

implementation

{ TMsGraph }

constructor TMsGraph.Create(authenticator: TMsAuthenticator;
  tenantId: string);
begin
  inherited Create(authenticator);
  self.FHTTP := THTTPClient.Create;
  self.FTenant := tenantId;
end;

destructor TMsGraph.Destroy;
begin
  self.FHTTP.Free;
  inherited Destroy;
end;

function TMsGraph.GetUser(sysLogin: string): string;
var
  ASelectFields: TArray<string>;
  AQuery: string;
  AUrl: string;
  AReq: IHTTPRequest;
  ARes: IHTTPResponse;
  Aj: TJsonValue;
  AJArr: TJSONArray;
  AJUser: TJSONValue;
  AJErr: TJsonValue;
  AErr: TMsError;
  AToken: string;

  displayName, givenName, surname, mail, bussinesPhone, mobilePhone, faxNumber: string;
begin
  AToken := self.Token;

  Result := '';

  if AToken <> '' then
  begin
    ASelectFields := [
      'businessPhones',
      'displayName',
      'faxNumber',
      'givenName',
      'mail',
      'mobilePhone',
      'surname'
    ];
    AQuery := Format(
      '?$filter=onPremisesSamAccountName eq ''%s''&$select=%s&$count=true',
      [sysLogin, string.join(',', ASelectFields)]
    );

    //AQuery := '?$filter=onPremisesSamAccountName eq ''KEHL''';

    AUrl := Format(
      'https://graph.microsoft.com/v1.0/%s/users%s',
      [self.FTenant, TNetEncoding.URL.EncodeQuery(AQuery)]
    );

    AReq := FHTTP.GetRequest(sHTTPMethodGet, AUrl);
    AReq.Accept := 'application/json';

    Areq.AddHeader('Authorization', AToken);
    AReq.AddHeader('ConsistencyLevel', 'eventual');
    ARes := self.FHTTP.Execute(AReq);

    if ARes.StatusCode <> 200 then
    begin
      AErr := Default(TMsError);
      AErr.StatusCode := ARes.StatusCode;
      AErr.StatusText := ARes.StatusText;
      AErr.url := AUrl;
      AErr.Method := sHTTPMethodGet;
      AErr.req_Header := AReq.Headers;
      AErr.res_header := ARes.Headers;
      AErr.error_data := ARes.ContentAsString();

      Aj := TJSONValue.ParseJSONValue(ARes.ContentAsString(TEncoding.UTF8));
      if Aj.TryGetValue<TJsonValue>('error', AJErr) then
      begin
        AJErr.TryGetValue<string>('code', AErr.error_name);
        AJErr.TryGetValue<string>('message', AErr.error_description);
      end;
      Aj.Free;
      self.OnRequestError(AErr);
    end
    else
    begin
      //displayName, givenName, surname, mail, bussinesPhone, mobilePhone, faxNumber
      Aj := TJSONValue.ParseJSONValue(ARes.ContentAsString(TEncoding.UTF8));
      if Aj.TryGetValue<TJsonArray>('value', AJArr) then
      begin
        if AJArr.Count > 0 then
        begin
          AJUser := AJArr.Items[0];

          AJUser.TryGetValue<string>('displayName', displayName);
          AJUser.TryGetValue<string>('businessPhones[0]', bussinesPhone);
          AJUser.TryGetValue<string>('givenName', givenName);
          AJUser.TryGetValue<string>('surname', surname);
          AJUser.TryGetValue<string>('mail', mail);
          //AJUser.TryGetValue<string>('bussinesPhone', bussinesPhone);
          AJUser.TryGetValue<string>('mobilePhone', mobilePhone);
          AJUser.TryGetValue<string>('faxNumber', faxNumber);

          Result := ''
          + '<?xml version="1.0" standalone="yes"?>'
          + '<DATAPACKET Version="2.0">'
          + '<METADATA>'
          + '<FIELDS>'
          + '<FIELD attrname="SYSTEMLOGIN" fieldtype="string" WIDTH="60"/>'
          + '<FIELD attrname="NAME" fieldtype="string" WIDTH="40"/>'
          + '<FIELD attrname="EMAIL" fieldtype="string" WIDTH="255"/>'
          + '<FIELD attrname="TELEFON" fieldtype="string" WIDTH="35"/>'
          + '<FIELD attrname="VORNAME" fieldtype="string" WIDTH="35"/>'
          + '<FIELD attrname="NACHNAME" fieldtype="string" WIDTH="35"/>'
          + '<FIELD attrname="FAX" fieldtype="string" WIDTH="35"/>'
          + '<FIELD attrname="MOBILTELEFON" fieldtype="string" WIDTH="35"/>'
          + '</FIELDS>'
          + '<PARAMS/>'
          + '</METADATA>'
          + '<ROWDATA>'
          + Format(''
              + '<ROW SYSTEMLOGIN="%s" NAME="%s" EMAIL="%s" TELEFON="%s" '
              + 'VORNAME="%s" NACHNAME="%s" FAX="%s" MOBILTELEFON="%s" />',
              [sysLogin, displayName, mail, bussinesPhone, givenName, surname,
                faxNumber, mobilePhone]
            )
          + '</ROWDATA>'
          + '</DATAPACKET>';
        end;
      end;
      Aj.Free;
    end;
  end;
end;

function TMsGraph.GetUsers: string;
var
  ASelectFields: TArray<string>;
  AQuery: string;
  AUrl: string;
  AReq: IHTTPRequest;
  ARes: IHTTPResponse;
  Aj: TJsonValue;
  AJArr: TJSONArray;
  AJUser: TJSONValue;
  AJErr: TJsonValue;
  AErr: TMsError;
  AToken: string;

  AJsonArrayList: TList<TJSONArray>;

  AResCode: Integer;

  displayName, givenName, surname, mail, bussinesPhone, mobilePhone, faxNumber: string;
  sysLogin: string;
begin
  AToken := self.Token;

  Result := '';

  if AToken <> '' then
  begin
    ASelectFields := [
      'businessPhones',
      'displayName',
      'faxNumber',
      'givenName',
      'mail',
      'mobilePhone',
      'surname',
      'onPremisesSamAccountName'
    ];
    AQuery := Format(
      '?$filter=accountEnabled eq true&$select=%s&$count=true',
      [string.join(',', ASelectFields)]
    );

    //AQuery := '?$filter=onPremisesSamAccountName eq ''KEHL''';

    AUrl := Format(
      'https://graph.microsoft.com/v1.0/%s/users%s',
      [self.FTenant, TNetEncoding.URL.EncodeQuery(AQuery)]
    );

    AResCode := 200;

    AJsonArrayList := TList<TJSONArray>.Create;

    while (AResCode = 200) and (AUrl <> '') do
    begin
      AReq := FHTTP.GetRequest(sHTTPMethodGet, AUrl);
      AReq.Accept := 'application/json';

      Areq.AddHeader('Authorization', AToken);
      AReq.AddHeader('ConsistencyLevel', 'eventual');
      ARes := self.FHTTP.Execute(AReq);

      AResCode := ARes.StatusCode;

      if AResCode <> 200 then
      begin
        AErr := Default(TMsError);
        AErr.StatusCode := ARes.StatusCode;
        AErr.StatusText := ARes.StatusText;
        AErr.url := AUrl;
        AErr.Method := sHTTPMethodGet;
        AErr.req_Header := AReq.Headers;
        AErr.res_header := ARes.Headers;
        AErr.error_data := ARes.ContentAsString();

        Aj := TJSONValue.ParseJSONValue(ARes.ContentAsString(TEncoding.UTF8));
        if Aj.TryGetValue<TJsonValue>('error', AJErr) then
        begin
          AJErr.TryGetValue<string>('code', AErr.error_name);
          AJErr.TryGetValue<string>('message', AErr.error_description);
        end;
        Aj.Free;
        self.OnRequestError(AErr);
      end
      else
      begin
        // displayName, givenName, surname, mail, bussinesPhone, mobilePhone, faxNumber

        Aj := TJSONValue.ParseJSONValue(ARes.ContentAsString(TEncoding.UTF8));
        // get next url
        if not self.GetValue(Aj, '@odata.nextLink', AUrl) then
          AUrl := '';
        
        if Aj.TryGetValue<TJsonArray>('value', AJArr) then
          AJsonArrayList.Add(TJSONArray(AJArr.Clone));
        Aj.Free;
      end;
    end;
    if AJsonArrayList.Count > 0 then
    begin
      Result := ''
      + '<?xml version="1.0" standalone="yes"?>'
      + '<DATAPACKET Version="2.0">'
      + '<METADATA>'
      + '<FIELDS>'
      + '<FIELD attrname="SYSTEMLOGIN" fieldtype="string" WIDTH="60"/>'
      + '<FIELD attrname="NAME" fieldtype="string" WIDTH="40"/>'
      + '<FIELD attrname="EMAIL" fieldtype="string" WIDTH="255"/>'
      + '<FIELD attrname="TELEFON" fieldtype="string" WIDTH="35"/>'
      + '<FIELD attrname="VORNAME" fieldtype="string" WIDTH="35"/>'
      + '<FIELD attrname="NACHNAME" fieldtype="string" WIDTH="35"/>'
      + '<FIELD attrname="FAX" fieldtype="string" WIDTH="35"/>'
      + '<FIELD attrname="MOBILTELEFON" fieldtype="string" WIDTH="35"/>'
      + '</FIELDS>'
      + '<PARAMS/>'
      + '</METADATA>'
      + '<ROWDATA>';
      
      for AJArr in AJsonArrayList do
      begin
        for AJUser in AJArr do
        begin
          AJUser.TryGetValue<string>('displayName', displayName);
          AJUser.TryGetValue<string>('businessPhones[0]', bussinesPhone);
          AJUser.TryGetValue<string>('givenName', givenName);
          AJUser.TryGetValue<string>('surname', surname);
          AJUser.TryGetValue<string>('mail', mail);
          //AJUser.TryGetValue<string>('bussinesPhone', bussinesPhone);
          AJUser.TryGetValue<string>('mobilePhone', mobilePhone);
          AJUser.TryGetValue<string>('faxNumber', faxNumber);

          Result := Result
            + Format(''
            + '<ROW SYSTEMLOGIN="%s" NAME="%s" EMAIL="%s" TELEFON="%s" '
            + 'VORNAME="%s" NACHNAME="%s" FAX="%s" MOBILTELEFON="%s" />',
            [sysLogin, displayName, mail, bussinesPhone, givenName, surname,
              faxNumber, mobilePhone]
          );
        end;
      end;
      
      Result := Result
      + '</ROWDATA>'
      + '</DATAPACKET>';
    end
    else
    begin
      Result := '';
    end;
  end;
end;

function TMsGraph.GetValue(AJ: TJsonValue; AKey: string; var AValue: string): boolean;
var
  AI: Integer;
begin
  Result := False;
  AValue := '';
  if AKey <> '' then
  begin
    for AI := 0 to TJSONObject(AJ).Count - 1 do
    begin
      if TJSONObject(AJ).Pairs[AI].JsonString.Value = AKey then
      begin
        AValue := TJSONObject(AJ).Pairs[AI].JsonValue.Value;
        Result := True;
        Break;
      end;
    end;
  end;
end;

end.

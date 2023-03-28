unit MsAdGraphGetUser;

interface

uses
  System.Net.HttpClient,
  System.NetEncoding,
  System.NetConsts,
  System.JSON,
  System.SysUtils,
  System.StrUtils,
  System.Generics.Collections,
  MsAdAuthenticator;


type
  TMsAdGraph = class(TMsAdAdapter)
  private
    FHTTP: THTTPClient;
    FTenant: string;
  public
    constructor Create(authenticator: TMsAdAuthenticator; tenantId: string);
    destructor Destroy; override;
    function GetUser(sysLogin: string): string;
  end;

implementation

{ TMsAdGraph }

constructor TMsAdGraph.Create(authenticator: TMsAdAuthenticator;
  tenantId: string);
begin
  inherited Create(authenticator);
  self.FHTTP := THTTPClient.Create;
  self.FTenant := tenantId;
end;

destructor TMsAdGraph.Destroy;
begin
  self.FHTTP.Free;
  inherited Destroy;
end;

function TMsAdGraph.GetUser(sysLogin: string): string;
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
  AErr: TMsAdError;
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
      AErr := Default(TMsAdError);
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

end.

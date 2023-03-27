unit MsGraphRequestHandler;

interface

uses
  System.Net.HttpClient,
  System.Net.URLClient,
  System.NetEncoding,
  System.NetConsts,
  System.Classes,
  System.StrUtils,
  System.SysUtils,
  System.DateUtils,
  System.JSON,
  System.Generics.Collections,
  System.Generics.Defaults,
  MsAuthenticator;

type
  THeaderPair = TNameValuePair;

  TMsGraphRequestResult = record
  private
    FIsOk: boolean;
    FError: TMsError;
    FOk: IHTTPResponse;
    class function Create(req: IHTTPRequest; res: IHttpResponse): TMsGraphRequestResult; static;
  public
    function is_ok: boolean;
    function is_err: boolean;
    function unwrap_ok: IHTTPResponse;
    function unwrap_err: TMsError;
  end;


  TMsGraphRequestHandler = class(TMsAdapter)
  private
    FWaitOnThrottle: boolean;
  public
    procedure HandleError(err: TMsError);
    property waitOnThrottle: boolean read FWaitOnThrottle write FWaitOnThrottle;
    function newReq(method, url: string; headers: TNetHeaders; payload: string): TMsGraphRequestResult; overload;
    function newReq(method, url: string; headers: TNetHeaders; payload: TStream): TMsGraphRequestResult; overload;
  end;

implementation


{ TMsGraphRequestHandler }

procedure TMsGraphRequestHandler.HandleError(err: TMsError);
begin
  self.OnRequestError(err);
end;

function TMsGraphRequestHandler.newReq(method, url: string;
  headers: TNetHeaders; payload: TStream): TMsGraphRequestResult;
var
  AReq: IHTTPRequest;
  ARes: IHTTPResponse;
  AHeader: TNetHeader;
  AWaitUntil: TDateTime;
  AReqId: string;
  AToken: string;
begin
  if Assigned(Self) then
  begin
    AToken := self.Token;
    if AToken <> '' then
    begin
      AReq := self.Http.GetRequest(method, url);
      AReqId := TGUID.NewGuid.ToString.Remove(0, 1).Remove(36);
      AReq.AddHeader('client-request-id', AReqId);
      AReq.AddHeader('Authorization', AToken);
      for AHeader in headers do AReq.HeaderValue[AHeader.Name] := AHeader.Value;
      if Assigned(payload) then AReq.SourceStream := payload;
      ARes := self.Http.Execute(AReq);

      if ARes.HeaderValue['client-request-id'] <> AReqId then
        exit(self.newReq(method, url, headers, payload));
      if (ARes.StatusCode = 429) and self.FWaitOnThrottle then
      begin
        AWaitUntil := Now;
        AWaitUntil.AddSecond(ARes.HeaderValue['Retry-After'].ToInt64);
        while AWaitUntil > Now do sleep(3);
        exit(self.newReq(method, url, headers, payload));
      end;

      Result := TMsGraphRequestResult.Create(AReq, ARes);
    end;
  end;
end;

function TMsGraphRequestHandler.newReq(method, url: string;
  headers: TNetHeaders; payload: string): TMsGraphRequestResult;
var
  AStream: TStringStream;
begin
  AStream := nil;
  if payload <> '' then AStream := TStringStream.Create(payload);
  Result := self.newReq(method, url, headers, AStream);
  if Assigned(AStream) then AStream.Free;
end;

{ TMsGraphRequestResult }

class function TMsGraphRequestResult.Create(req: IHTTPRequest;
  res: IHttpResponse): TMsGraphRequestResult;
var
  json:TJsonValue;
begin
  Result.FIsOk := (res.StatusCode >= 200) and (res.StatusCode <= 299);
  if Result.FIsOk then
    Result.FOk := res
  else
  begin
    Result.FError.HTTPStatusCode := res.StatusCode;
    Result.FError.HTTPStatusText := res.StatusText;
    Result.FError.HTTPurl := req.URL.ToString;
    Result.FError.HTTPMethod := req.MethodString;
    Result.FError.HTTPreq_Header := req.Headers;
    Result.FError.HTTPres_header := res.Headers;

    Result.FError.HTTPerror_description := res.ContentAsString();
    json := TJsonValue.ParseJSONValue(Result.FError.HTTPerror_description);
    if Assigned(json) then
    begin
      json.TryGetValue<string>('error.code', Result.FError.HTTPerror_name);
      json.TryGetValue<string>('error.message', Result.FError.HTTPerror_description);
    end;
  end;
end;

function TMsGraphRequestResult.is_err: boolean;
begin
  Result := not self.FIsOk;
end;

function TMsGraphRequestResult.is_ok: boolean;
begin
  Result := self.FIsOk;
end;

function TMsGraphRequestResult.unwrap_err: TMsError;
begin
  if not self.FIsOk then
    Result := self.FError
  else
    raise Exception.Create('Result is not an error.');
end;

function TMsGraphRequestResult.unwrap_ok: IHTTPResponse;
begin
  if self.FIsOk then
    Result := self.FOk
  else
    raise Exception.Create('Result is not an ok.');
end;

end.

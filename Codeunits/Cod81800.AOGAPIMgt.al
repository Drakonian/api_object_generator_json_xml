codeunit 81800 "AOG API Mgt"
{
    //Generic codeunit to send http requests
    procedure SendRequest(var APIHeader: Record "AOG API Header"; RequestMethod: enum "Http Request Type"; requestUri: Text): text
    var
        DictionaryDefaultHeaders: Codeunit "Dictionary Wrapper";
        DictionaryContentHeaders: Codeunit "Dictionary Wrapper";
        ContentType: Text;
    begin
        exit(SendRequest(APIHeader, '', RequestMethod, requestUri, ContentType, 0, DictionaryContentHeaders, DictionaryDefaultHeaders));
    end;

    procedure SendRequest(var APIHeader: Record "AOG API Header"; contentToSend: Variant; RequestMethod: enum "Http Request Type"; requestUri: Text; ContentType: Text): text
    var
        DictionaryDefaultHeaders: Codeunit "Dictionary Wrapper";
        DictionaryContentHeaders: Codeunit "Dictionary Wrapper";
    begin
        exit(SendRequest(APIHeader, contentToSend, RequestMethod, requestUri, ContentType, 0, DictionaryContentHeaders, DictionaryDefaultHeaders));
    end;

    procedure SendRequest(var APIHeader: Record "AOG API Header"; contentToSend: Variant; RequestMethod: enum "Http Request Type"; requestUri: Text; ContentType: Text; DictionaryDefaultHeaders: Codeunit "Dictionary Wrapper"): text
    var
        DictionaryContentHeaders: Codeunit "Dictionary Wrapper";
    begin
        exit(SendRequest(APIHeader, contentToSend, RequestMethod, requestUri, ContentType, 0, DictionaryContentHeaders, DictionaryDefaultHeaders));
    end;

    procedure SendRequest(var APIHeader: Record "AOG API Header"; contentToSend: Variant; RequestMethod: enum "Http Request Type"; requestUri: Text; ContentType: Text; HttpTimeout: integer; DictionaryContentHeaders: Codeunit "Dictionary Wrapper"; DictionaryDefaultHeaders: Codeunit "Dictionary Wrapper"): text
    var
        Base64Convert: Codeunit "Base64 Convert";
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        ContentHeaders: HttpHeaders;
        Content: HttpContent;
        ErrorContent: Text;
        AccessToken: Text;
        ResponseText: Text;
        ErrorBodyContent: Text;
        TextContent: Text;
        InStreamContent: InStream;
        i: Integer;
        KeyVariant: Variant;
        ValueVariant: Variant;
        HasContent: Boolean;
    begin

        case APIHeader."Auth Type" of
            APIHeader."Auth Type"::"OAuth 1.0", APIHeader."Auth Type"::"OAuth 2.0":
                begin
                    RequestAccessToken(APIHeader, ErrorContent, AccessToken);
                    Client.DefaultRequestHeaders().Add(
                        'Authorization',
                        'Bearer ' + AccessToken);
                end;
            APIHeader."Auth Type"::"Bearer Token":
                begin
                    Client.DefaultRequestHeaders().Add(
                        'Authorization',
                        'Bearer ' + APIHeader.GetClientSecret());
                end;
            APIHeader."Auth Type"::Basic:
                begin
                    Client.DefaultRequestHeaders().Add(
                        'Authorization',
                        'Basic ' + Base64Convert.ToBase64(StrSubstNo('%1:%2', APIHeader.Login, APIHeader.GetClientSecret())));
                end;
        end;


        case true of
            contentToSend.IsText():
                begin
                    TextContent := contentToSend;
                    if TextContent <> '' then begin
                        Content.WriteFrom(TextContent);
                        HasContent := true;
                    end;
                end;
            contentToSend.IsInStream():
                begin
                    InStreamContent := contentToSend;
                    Content.WriteFrom(InStreamContent);
                    HasContent := true;
                end;
            else
                Error(UnsupportedContentToSendErr);
        end;

        if HasContent then
            Request.Content := Content;

        if ContentType <> '' then begin
            ContentHeaders.Clear();
            Request.Content.GetHeaders(ContentHeaders);
            if ContentHeaders.Contains(ContentTypeKeyLbl) then
                ContentHeaders.Remove(ContentTypeKeyLbl);

            ContentHeaders.Add(ContentTypeKeyLbl, ContentType);
        end;

        for i := 0 to DictionaryContentHeaders.Count() do
            if DictionaryContentHeaders.TryGetKeyValue(i, KeyVariant, ValueVariant) then
                ContentHeaders.Add(Format(KeyVariant), Format(ValueVariant));

        Request.SetRequestUri(requestUri);
        Request.Method := Format(RequestMethod);

        for i := 0 to DictionaryDefaultHeaders.Count() do
            if DictionaryDefaultHeaders.TryGetKeyValue(i, KeyVariant, ValueVariant) then
                Client.DefaultRequestHeaders.Add(Format(KeyVariant), Format(ValueVariant));

        if HttpTimeout <> 0 then
            Client.Timeout(HttpTimeout);

        Client.Send(Request, Response);

        Response.Content().ReadAs(ResponseText);
        if not Response.IsSuccessStatusCode() then begin
            Response.Content().ReadAs(ErrorBodyContent);
            Error(RequestErr, Response.HttpStatusCode(), ErrorBodyContent);
        end;

        exit(ResponseText);
    end;

    procedure RequestAccessToken(var APIHeader: Record "AOG API Header"; var ErrorContent: Text; var AccessToken: Text) IsConnected: Boolean
    var
        OAuth2: Codeunit OAuth2;
        ListOfScopes: List of [Text];
    begin
        ListOfScopes.Add(APIHeader.Scope);

        case APIHeader."Grant Type" of
            APIHeader."Grant Type"::"Authorization Code":
                IsConnected := OAuth2.AcquireTokenByAuthorizationCode(APIHeader."Client ID", APIHeader.GetClientSecret(),
                    APIHeader."Authorization URL", APIHeader."Redirect URL", ListOfScopes, Enum::"Prompt Interaction"::None,
                    AccessToken, ErrorContent);
            APIHeader."Grant Type"::"Client Credentials":
                case APIHeader."Auth Type" of
                    APIHeader."Auth Type"::"OAuth 1.0":
                        begin
                            IsConnected := OAuth2.AcquireTokenWithClientCredentials(APIHeader."Client ID", APIHeader.GetClientSecret(),
                                APIHeader."Authorization URL", APIHeader."Redirect URL",
                                AccessToken, ErrorContent)
                        end;
                    APIHeader."Auth Type"::"OAuth 2.0":
                        begin
                            IsConnected := OAuth2.AcquireTokenWithClientCredentials(APIHeader."Client ID", APIHeader.GetClientSecret(),
                                APIHeader."Authorization URL", APIHeader."Redirect URL", ListOfScopes, AccessToken);
                        end;
                end;
        end;
        if not IsConnected then
            Error(GetLastErrorText());
    end;

    var
        RequestErr: Label 'Request failed with HTTP Code:: %1 Request Body:: %2', Comment = '%1 = HttpCode, %2 = RequestBody';
        UnsupportedContentToSendErr: Label 'Unsuportted content to send.';
        ContentTypeKeyLbl: Label 'Content-Type', Locked = true;
}

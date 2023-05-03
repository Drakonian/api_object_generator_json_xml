table 81800 "AOG API Header"
{
    Caption = 'API Header';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            DataClassification = CustomerContent;
        }
        field(3; Description; Text[250])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
        field(4; "Data Format"; Enum "AOG Data Format")
        {
            Caption = 'Data Format';
            DataClassification = CustomerContent;
        }
        field(5; "Auth Type"; Enum "AOG Auth Type")
        {
            Caption = 'Auth Type';
            DataClassification = CustomerContent;
        }
        field(6; "Base Prefix"; Text[5])
        {
            Caption = 'Base Prefix';
            DataClassification = CustomerContent;
        }
        field(8; "Base ID"; Integer)
        {
            Caption = 'Base ID';
            DataClassification = CustomerContent;
            InitValue = 50000;
        }
        field(9; "Generation Type"; enum "AOG Generation Type")
        {
            Caption = 'Generation Type';
            DataClassification = CustomerContent;
        }
        field(10; "Response Data"; Blob)
        {
            Caption = 'Response Data';
            DataClassification = CustomerContent;
        }
        field(11; "Request Data"; Blob)
        {
            Caption = 'Request Data';
            DataClassification = CustomerContent;
        }
        field(12; "Http Request Type"; enum "Http Request Type")
        {
            Caption = 'Http Request Type';
            DataClassification = CustomerContent;
        }
        field(14; "Response Code"; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Response Code';
        }
        field(15; "Request Content Type"; Text[100])
        {
            DataClassification = CustomerContent;
            Caption = 'Request Content Type';
        }
        field(16; "Request URL"; Text[500])
        {
            DataClassification = CustomerContent;
            Caption = 'Request URL';
        }

        field(17; "Client ID"; Text[250])
        {
            Caption = 'Client ID';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(18; "Redirect URL"; Text[250])
        {
            Caption = 'Redirect URL';
            DataClassification = CustomerContent;

        }
        field(19; "Auth. URL Parms"; Text[250])
        {
            Caption = 'Auth. URL Parms';
            DataClassification = CustomerContent;

        }
        field(20; Scope; Text[250])
        {
            Caption = 'Scope';
            DataClassification = CustomerContent;

        }
        field(21; "Authorization URL"; Text[250])
        {
            Caption = 'Authorization URL';
            DataClassification = CustomerContent;


            trigger OnValidate()
            var
                WebRequestHelper: Codeunit "Web Request Helper";
            begin
                if "Authorization URL" <> '' then
                    WebRequestHelper.IsSecureHttpUrl("Authorization URL");
            end;
        }
        field(22; "Access Token URL"; Text[250])
        {
            DataClassification = CustomerContent;
            Caption = 'Access Token URL';

            trigger OnValidate()
            var
                WebRequestHelper: Codeunit "Web Request Helper";
            begin
                if "Access Token URL" <> '' then
                    WebRequestHelper.IsSecureHttpUrl("Access Token URL");
            end;
        }
        field(23; Login; Text[2048])
        {
            DataClassification = CustomerContent;
            Caption = 'Login';
        }

        field(25; "Grant Type"; Enum "AOG Grant Type")
        {
            Caption = 'Grant Type';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(26; "Root Path"; Text[2048])
        {
            Caption = 'Root Path';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    procedure GetBLOBDataAsTxt(FieldNo: Integer; Encoding: TextEncoding) Result: Text
    var
        TempBlob: Codeunit "Temp Blob";
        TypeHelper: Codeunit "Type Helper";
        CurrentAPIHeaderRecRef: RecordRef;
        DataFieldRef: FieldRef;
        ResponseInStream: InStream;
        TextBuffer: Text;
    begin
        CurrentAPIHeaderRecRef.GetTable(Rec);
        DataFieldRef := CurrentAPIHeaderRecRef.Field(FieldNo);
        if DataFieldRef.Type <> DataFieldRef.Type::Blob then
            exit;
        DataFieldRef.CalcField();

        TempBlob.FromFieldRef(DataFieldRef);

        if not TempBlob.HasValue() then
            exit;

        TempBlob.CreateInStream(ResponseInStream, Encoding);
        while not ResponseInStream.EOS() do begin
            ResponseInStream.ReadText(TextBuffer);
            Result += TextBuffer + TypeHelper.CRLFSeparator();
        end;
    end;


    procedure SetBLOBTextData(FieldNo: Integer; TextData: Text; Encoding: TextEncoding)
    var
        ResponseOutStream: OutStream;
    begin
        case FieldNo of
            Rec.FieldNo("Request Data"):
                Rec."Request Data".CreateOutStream(ResponseOutStream, Encoding);

            Rec.FieldNo("Response Data"):
                Rec."Response Data".CreateOutStream(ResponseOutStream, Encoding);
        end;

        ResponseOutStream.WriteText(TextData);

        Rec.Modify(true);
    end;

    procedure SetClientSecret(ClientSecret: Text)
    begin
        if IsolatedStorage.Contains(Rec."Client ID", DataScope::Company) then
            IsolatedStorage.Delete(Rec."Client ID", DataScope::Company);

        IsolatedStorage.set(Rec."Client ID", ClientSecret, DataScope::Company);
    end;

    procedure GetClientSecret(): Text
    var
        ClientSecret: Text;
    begin
        if IsolatedStorage.Contains(Rec."Client ID", DataScope::Company) then begin
            IsolatedStorage.Get(Rec."Client ID", DataScope::Company, ClientSecret);
            exit(ClientSecret);
        end;
    end;
}

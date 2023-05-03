page 81800 "AOG API Object Generator"
{
    Caption = 'API Object Generator';
    PageType = Card;
    SourceTable = "AOG API Header";
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec."Code")
                {
                    ToolTip = 'Specifies the value of the Code field.';
                }
                field(Name; Rec.Name)
                {
                    ToolTip = 'Specifies the value of the Name field.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the value of the Description field.';
                }
                field("Generation Type"; Rec."Generation Type")
                {
                    ToolTip = 'Specifies the value of the Generation Type" field.';
                }
                field("Data Format"; Rec."Data Format")
                {
                    ToolTip = 'Specifies the value of the Data Format field.';
                }
                field("Auth Type"; Rec."Auth Type")
                {
                    ToolTip = 'Specifies the value of the Auth Type field.';
                }
                field("Base Prefix"; Rec."Base Prefix")
                {
                    ToolTip = 'Specifies the value of the Base Prefix field.';
                }
                field("Base ID"; Rec."Base ID")
                {
                    ToolTip = 'Specifies the value of the Base ID field.';
                }
                field("Root Path"; Rec."Root Path")
                {
                    ToolTip = 'Specifies the value of the Root Path field.';
                }
            }


            group("Raw Data")
            {
                Caption = 'Raw Data';
                Visible = Rec."Generation Type" = Rec."Generation Type"::"Raw Data";

                field("RawData"; ResponseData)
                {
                    ToolTip = 'Specifies the value of the Request Data field.';
                    ShowCaption = false;
                    ShowMandatory = true;
                    MultiLine = true;
                    trigger OnValidate()
                    begin
                        Rec.SetBLOBTextData(Rec.FieldNo("Response Data"), ResponseData, TextEncoding::UTF8);
                    end;
                }
            }
            group("Request")
            {
                Caption = 'Request';
                Visible = Rec."Generation Type" = Rec."Generation Type"::API;
                field("Request URL"; Rec."Request URL")
                {
                    ToolTip = 'Specifies the value of the Request URL field.';
                    ShowMandatory = true;
                }
                field("Http Request Type"; Rec."Http Request Type")
                {
                    ToolTip = 'Specifies the value of the Http Request Type field.';
                }
                field("Request Content Type"; Rec."Request Content Type")
                {
                    ToolTip = 'Specifies the value of the Request Content Type field.';
                }
                field("Request Data"; RequestData)
                {
                    ToolTip = 'Specifies the value of the Request Data field.';
                    Caption = 'Request Data';
                    MultiLine = true;
                    trigger OnValidate()
                    begin
                        Rec.SetBLOBTextData(Rec.FieldNo("Request Data"), RequestData, TextEncoding::UTF8);
                    end;
                }
            }
            group("Authorization")
            {
                Caption = 'Authorization';
                Visible = (Rec."Generation Type" = Rec."Generation Type"::API) and (Rec."Auth Type" <> Rec."Auth Type"::"No Auth");
                group("OAuth20")
                {
                    Caption = 'OAuth 2.0';
                    ShowCaption = false;
                    Visible = (Rec."Auth Type" = Rec."Auth Type"::"OAuth 2.0");

                    field("Grant Type"; Rec."Grant Type")
                    {
                        ToolTip = 'Specifies the value of the Grant Type field.';
                    }
                    field("Access Token URL"; Rec."Access Token URL")
                    {
                        ToolTip = 'Specifies the value of the Access Token URL field.';
                    }
                    field("Authorization URL"; Rec."Authorization URL")
                    {
                        ToolTip = 'Specifies the value of the Authorization URL field.';
                    }
                    field("Redirect URL"; Rec."Redirect URL")
                    {
                        ToolTip = 'Specifies the value of the Redirect URL field.';
                    }
                    field(Scope; Rec.Scope)
                    {
                        ToolTip = 'Specifies the value of the Scope field.';
                    }
                    field("Client ID"; Rec."Client ID")
                    {
                        ToolTip = 'Specifies the value of the Client ID field.';
                    }
                    field("Client Secret"; ClientSecret)
                    {
                        ApplicationArea = All;
                        ExtendedDatatype = Masked;
                        ToolTip = 'Specifies the client secret.';
                        Caption = 'Client Secret';
                        trigger OnValidate()
                        begin
                            Rec.SetClientSecret(ClientSecret);
                        end;
                    }
                }
                group("Bearer")
                {
                    ShowCaption = false;
                    Visible = Rec."Auth Type" = Rec."Auth Type"::"Bearer Token";
                    field("Bearer Token"; ClientSecret)
                    {
                        ApplicationArea = All;
                        ExtendedDatatype = Masked;
                        ToolTip = 'Specifies the bearer token.';
                        Caption = 'Bearer Token';
                        trigger OnValidate()
                        begin
                            Rec.SetClientSecret(ClientSecret);
                        end;
                    }
                }
                group("Basic")
                {
                    ShowCaption = false;
                    Visible = Rec."Auth Type" = Rec."Auth Type"::Basic;
                    field(Login; Rec.Login)
                    {
                        ToolTip = 'Specifies the value of the Login field.';
                    }
                    field("Password"; ClientSecret)
                    {
                        ApplicationArea = All;
                        ExtendedDatatype = Masked;
                        ToolTip = 'Specifies the password.';
                        Caption = 'Password';
                        trigger OnValidate()
                        begin
                            Rec.SetClientSecret(ClientSecret);
                        end;
                    }
                }
                group("OAuth 1.0")
                {
                    ShowCaption = false;
                    Caption = 'OAuth 1.0';
                    Visible = Rec."Auth Type" = Rec."Auth Type"::"OAuth 1.0";
                    field("Grant Type2"; Rec."Grant Type")
                    {
                        ToolTip = 'Specifies the value of the Grant Type field.';
                    }
                    field("Access Token URL2"; Rec."Access Token URL")
                    {
                        ToolTip = 'Specifies the value of the Access Token URL field.';
                    }
                    field("Authorization URL2"; Rec."Authorization URL")
                    {
                        ToolTip = 'Specifies the value of the Authorization URL field.';
                    }
                    field("Redirect URL2"; Rec."Redirect URL")
                    {
                        ToolTip = 'Specifies the value of the Redirect URL field.';
                    }
                    field("Client ID2"; Rec."Client ID")
                    {
                        ToolTip = 'Specifies the value of the Client ID field.';
                    }
                    field("Client Secret2"; ClientSecret)
                    {
                        ApplicationArea = All;
                        ExtendedDatatype = Masked;
                        ToolTip = 'Specifies the client secret.';
                        Caption = 'Client Secret';
                        trigger OnValidate()
                        begin
                            Rec.SetClientSecret(ClientSecret);
                        end;
                    }
                }
            }
            group("Respone")
            {
                Caption = 'Respone';
                Editable = false;
                field("Response Data"; ResponseData)
                {
                    ToolTip = 'Specifies the value of the Response Data field.';
                    ShowCaption = false;
                    MultiLine = true;
                }
                field("Response Code"; Rec."Response Code")
                {
                    ToolTip = 'Specifies the value of the Response Code field.';
                }
            }
        }
    }

    actions
    {
        area(Promoted)
        {
            actionref("GenerateObjectsPromoted"; "GenerateObjects")
            {
            }
            actionref("ValidateRootPathPromoted"; "ValidateRootPath")
            {
            }
        }
        area(Processing)
        {
            action(ValidateRootPath)
            {
                ApplicationArea = All;
                Caption = 'Validate Root Path';
                ToolTip = 'Validate Root Path';
                Image = Approve;
                trigger OnAction()
                var
                    APIObjectGeneratorMgt: Codeunit "AOG API Object Generator Mgt";
                begin
                    APIObjectGeneratorMgt.ValidateRootPath(Rec);
                end;
            }
            action(GenerateObjects)
            {
                ApplicationArea = All;
                Caption = 'Generate Objects';
                ToolTip = 'Generate Objects';
                Image = Download;
                trigger OnAction()
                var
                    APIObjectGeneratorMgt: Codeunit "AOG API Object Generator Mgt";
                begin
                    APIObjectGeneratorMgt.GenerateObjects(Rec);
                end;
            }

        }
    }
    trigger OnOpenPage()
    begin
        ClientSecret := '****';
    end;

    trigger OnAfterGetCurrRecord()
    begin
        ResponseData := Rec.GetBLOBDataAsTxt(Rec.FieldNo("Response Data"), TextEncoding::UTF8);
    end;

    var
        ClientSecret: Text;
        RequestData: Text;
        ResponseData: Text;
}

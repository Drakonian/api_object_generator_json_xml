page 81801 "AOG API Object Generator List"
{
    ApplicationArea = All;
    Caption = 'API Object Generator List';
    PageType = List;
    SourceTable = "AOG API Header";
    UsageCategory = Lists;
    CardPageId = "AOG API Object Generator";
    Editable = false;

    layout
    {
        area(content)
        {
            repeater(General)
            {
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
                    ToolTip = 'Specifies the value of the Base Suffix field.';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        APIHeader: Record "AOG API Header";
    begin
        if not APIHeader.Get(JSONAPIExampleKeyLbl) then begin
            APIHeader.Init();
            APIHeader.Code := JSONAPIExampleKeyLbl;
            APIHeader.Name := 'JSONAPIHeader';
            APIHeader."Generation Type" := APIHeader."Generation Type"::API;
            APIHeader."Data Format" := APIHeader."Data Format"::JSON;
            APIHeader."Auth Type" := APIHeader."Auth Type"::"No Auth";
            APIHeader."Base Prefix" := 'JAT';
            APIHeader."Request URL" := 'https://dummyjson.com/products/1';
            APIHeader."Http Request Type" := APIHeader."Http Request Type"::GET;
            APIHeader.Description := StrSubstNo(APIDescLbl, APIHeader."Data Format");
            APIHeader.Insert(true);
        end;

        Clear(APIHeader);
        if not APIHeader.Get(XMLExampleKeyLbl) then begin
            APIHeader.Init();
            APIHeader.Code := XMLExampleKeyLbl;
            APIHeader.Name := 'XMLHeader';
            APIHeader."Generation Type" := APIHeader."Generation Type"::"Raw Data";
            APIHeader."Data Format" := APIHeader."Data Format"::XML;
            APIHeader."Auth Type" := APIHeader."Auth Type"::"No Auth";
            APIHeader."Base Prefix" := 'XT';
            APIHeader."Root Path" := 'note';
            APIHeader.Description := StrSubstNo(APIDescLbl, APIHeader."Data Format");
            APIHeader.Insert(true);
            APIHeader.SetBLOBTextData(APIHeader.FieldNo("Response Data"), GetTestXMLAsText(), TextEncoding::UTF8);
            APIHeader.Modify(true);
        end;
    end;


    local procedure GetTestXMLAsText(): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
    begin
        exit(Base64Convert.FromBase64('PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iSVNPLTg4NTktMSI/PiAgCjxub3RlPiAgCiAgPHRvPlRvdmU8L3RvPiAgCiAgPGZyb20+SmFuaTwvZnJvbT4gIAogIDxoZWFkaW5nPlJlbWluZGVyPC9oZWFkaW5nPiAgCiAgPGJvZHk+RG9uJ3QgZm9yZ2V0IG1lIHRoaXMgd2Vla2VuZCE8L2JvZHk+ICAKPC9ub3RlPiAg'));
    end;

    var
        JSONAPIExampleKeyLbl: Label 'JSONAPIKey', Locked = true;
        XMLExampleKeyLbl: Label 'XMLKey', Locked = true;
        APIDescLbl: Label 'This is an example of generating objects for the %1 API.';
}

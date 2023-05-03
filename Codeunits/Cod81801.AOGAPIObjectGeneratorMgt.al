codeunit 81801 "AOG API Object Generator Mgt"
{
    procedure GenerateObjects(var APIHeader: Record "AOG API Header")
    var
        APIMgt: Codeunit "AOG API Mgt";
        DataToProcess: Text;
    begin
        APIHeader.TestField("Base ID");
        APIHeader.TestField("Base Prefix");
        APIHeader.TestField(Name);

        case APIHeader."Generation Type" of
            APIHeader."Generation Type"::"Raw Data":
                DataToProcess := APIHeader.GetBLOBDataAsTxt(APIHeader.FieldNo("Response Data"), TextEncoding::UTF8);
            APIHeader."Generation Type"::API:
                begin
                    DataToProcess := APIMgt.SendRequest(APIHeader, APIHeader.GetBLOBDataAsTxt(APIHeader.FieldNo("Request Data"), TextEncoding::UTF8),
                        APIHeader."Http Request Type", APIHeader."Request URL", APIHeader."Request Content Type");
                    APIHeader.SetBLOBTextData(APIHeader.FieldNo("Response Data"), DataToProcess, TextEncoding::UTF8);
                end;
        end;

        ProcessData(APIHeader, DataToProcess);
    end;

    local procedure ProcessData(var APIHeader: Record "AOG API Header"; Data: Text)
    var
        Base64Convert: Codeunit "Base64 Convert";
        DataCompression: Codeunit "Data Compression";
        TempBlobListAttachments: Codeunit "Temp Blob List";
        TempBlob: Codeunit "Temp Blob";
        ResultArchiveInStream: InStream;
        ResultArchiveOutStream: OutStream;
        XMLDoc: XmlDocument;
        JRootObject: JsonObject;
        JObject: JsonObject;
        JToken: JsonToken;
        JArray: JsonArray;
        NodeList: XmlNodeList;
        Node: XmlNode;
        TableObject: Text;
        TableFieldsGroup, ProcedureBody, CodeunitBody, ProcedureVariables, ProcedureLoopGroup : TextBuilder;
        BaseTableFieldTemplate, BaseTableTemplate, BaseCodeunitTemplate, BaseProcedureTemplate, BaseReaderProcedureBody, BaseProcedureBody : Text;
        JNode, FileName, RootPath, PartPath : Text;
        i: Integer;
    begin
        BaseTableFieldTemplate := Base64Convert.FromBase64(GetBaseTableFieldTemplate());
        BaseTableTemplate := Base64Convert.FromBase64(GetBaseTableTemplate());
        BaseCodeunitTemplate := Base64Convert.FromBase64(GetBaseCodeunitTemplate());
        BaseProcedureTemplate := Base64Convert.FromBase64(GetBaseProcedureTemplate());

        i := 1;
        TableFieldsGroup.AppendLine(StrSubstNo(BaseTableFieldTemplate, i, 'Entry No.', 'Integer'));
        ProcedureLoopGroup.AppendLine(StrSubstNo('Temp%1.Init();', APIHeader.Name));
        ProcedureLoopGroup.AppendLine('i += 1;');
        ProcedureLoopGroup.AppendLine(StrSubstNo('Temp%1."Entry No." := i;', APIHeader.Name));

        case APIHeader."Data Format" of
            APIHeader."Data Format"::JSON:
                begin
                    ProcedureVariables.AppendLine('var');
                    ProcedureVariables.AppendLine('  JObject: JsonObject;');
                    ProcedureVariables.AppendLine('  JToken: JsonToken;');
                    ProcedureVariables.AppendLine('  JArray: JsonArray;');
                    ProcedureVariables.AppendLine('  i: Integer;');
                    CodeunitBody.AppendLine(Base64Convert.FromBase64(GetBaseParseJSONProcedures()));
                    CodeunitBody.AppendLine();
                    JRootObject.ReadFrom(Data);
                    JRootObject.SelectToken(APIHeader."Root Path", JToken);
                    if JToken.IsArray() then begin
                        JArray := JToken.AsArray();
                        JArray.Get(0, JToken);
                    end;
                    JObject := JToken.AsObject();
                    Clear(JToken);
                    foreach JNode in JObject.Keys() do begin
                        JObject.Get(JNode, JToken);
                        if JToken.IsValue() then begin
                            i += 1;
                            TableFieldsGroup.AppendLine(StrSubstNo(BaseTableFieldTemplate, i, JNode, 'Text[2048]'));
                            ProcedureLoopGroup.AppendLine(StrSubstNo('Temp%1."%2" := CopyStr(GetValueAsText(JToken, "%2"), 1, MaxStrLen(%1."%2"));', APIHeader.Name, JNode));
                        end;
                    end;
                end;

            APIHeader."Data Format"::XML:
                begin
                    ProcedureVariables.AppendLine('var');
                    ProcedureVariables.AppendLine('  i: Integer;');
                    CodeunitBody.AppendLine(Base64Convert.FromBase64(GetBaseParseXMLProcedures()));
                    CodeunitBody.AppendLine();
                    foreach PartPath in APIHeader."Root Path".Split('/') do
                        RootPath += StrSubstNo('/*[local-name()="%1"]', PartPath);
                    NodeList := GetNodeList(Data, RootPath);
                    for i := 1 to NodeList.Count() do begin
                        NodeList.Get(i, Node);
                        if Node.IsXmlElement() then
                            if not Node.AsXmlElement().HasElements() then begin
                                i += 1;
                                TableFieldsGroup.AppendLine(StrSubstNo(BaseTableFieldTemplate, i, Node.AsXmlElement().LocalName, 'Text[2048]'));
                                ProcedureLoopGroup.AppendLine(StrSubstNo('Temp%1."%2" := GetValueFromXML(ObjectAsTxt, %3);)', APIHeader.Name, Node.AsXmlElement().LocalName, RootPath + StrSubstNo('/*[local-name()="%1"]', Node.AsXmlElement().LocalName)));
                            end;
                    end;
                end;

        end;
        ProcedureLoopGroup.AppendLine(StrSubstNo('Temp%1.Insert(true);', APIHeader.Name));
        if APIHeader."Data Format" = APIHeader."Data Format"::JSON then
            BaseProcedureBody := StrSubstNo(Base64Convert.FromBase64(GetBaseJsonReaderProcedureBody()), APIHeader."Root Path", ProcedureLoopGroup.ToText())
        else
            BaseProcedureBody := ProcedureLoopGroup.ToText();
        ProcedureBody.AppendLine(BaseProcedureBody);

        //Id, Prefix, Name, PK, Fields
        BaseTableTemplate := StrSubstNo(BaseTableTemplate, APIHeader."Base ID", APIHeader."Base Prefix", APIHeader.Name, 'Entry No.', TableFieldsGroup.ToText());
        //Local,Name,Input Params,Return value,Variables,Body of procedure
        CodeunitBody.AppendLine(StrSubstNo(BaseProcedureTemplate, '', StrSubstNo('Read%1%2', APIHeader."Data Format", APIHeader.Name),
            StrSubstNo(ProcedureParamsLbl, APIHeader.Name, APIHeader."Base Prefix"),
            '', ProcedureVariables.ToText(), ProcedureBody.ToText()));
        //Id, Prefix, Name, Procedures
        BaseCodeunitTemplate := StrSubstNo(BaseCodeunitTemplate, APIHeader."Base ID", APIHeader."Base Prefix", APIHeader.Name + ' Mgt.', CodeunitBody.ToText());

        DataCompression.CreateZipArchive();

        TempBlob.CreateOutStream(ResultArchiveOutStream, TextEncoding::UTF8);
        ResultArchiveOutStream.WriteText(BaseTableTemplate);
        TempBlob.CreateInStream(ResultArchiveInStream, TextEncoding::UTF8);

        DataCompression.AddEntry(ResultArchiveInStream, StrSubstNo(ObjectNameLbl, 'Tab', APIHeader."Base ID", APIHeader."Base Prefix", APIHeader.Name));

        Clear(TempBlob);
        Clear(ResultArchiveInStream);
        Clear(ResultArchiveOutStream);
        TempBlob.CreateOutStream(ResultArchiveOutStream, TextEncoding::UTF8);
        ResultArchiveOutStream.WriteText(BaseCodeunitTemplate);
        TempBlob.CreateInStream(ResultArchiveInStream, TextEncoding::UTF8);

        DataCompression.AddEntry(ResultArchiveInStream, StrSubstNo(ObjectNameLbl, 'Cod', APIHeader."Base ID", APIHeader."Base Prefix", APIHeader.Name));

        Clear(ResultArchiveInStream);
        Clear(TempBlob);
        TempBlob.CreateOutStream(ResultArchiveOutStream, TextEncoding::UTF8);
        DataCompression.SaveZipArchive(TempBlob);
        TempBlob.CreateInStream(ResultArchiveInStream, TextEncoding::UTF8);
        FileName := StrSubstNo('%1%2.zip', 'Result', APIHeader.Name);

        DownloadFromStream(ResultArchiveInStream, '', '', '', FileName);

    end;

    procedure ValidateRootPath(var APIHeader: Record "AOG API Header")
    var
        XMLDoc: XmlDocument;
        JObject: JsonObject;
        JToken: JsonToken;
        PartPath: Text;
        Data: Text;
        Result: Text;
    begin
        Data := APIHeader.GetBLOBDataAsTxt(APIHeader.FieldNo("Response Data"), TextEncoding::UTF8);

        case APIHeader."Data Format" of
            APIHeader."Data Format"::JSON:
                begin
                    JObject.ReadFrom(Data);
                    JObject.SelectToken(APIHeader."Root Path", JToken);
                    JToken.WriteTo(Result);
                end;

            APIHeader."Data Format"::XML:
                begin
                    foreach PartPath in APIHeader."Root Path".Split('/') do
                        Result += StrSubstNo('/*[local-name()="%1"]', PartPath);
                    Result := GetValueFromXML(Data, Result);
                end;
        end;

        Message(Result);
    end;

    procedure GetValueFromXML(Content: Text; pNodePath: Text): Text
    var
        XMLRootNode: XmlNode;
        XMLChildNode: XmlNode;
        XMLElem: XmlElement;
    begin
        GetRootNode(ConvertTextToXmlDocument(Content), XMLRootNode);

        XMLRootNode.SelectSingleNode(pNodePath, XMLChildNode);
        XMLElem := XMLChildNode.AsXmlElement();
        exit(XMLElem.InnerXml());
    end;

    procedure GetNodeList(Content: Text; pNodePath: Text) NodeList: XmlNodeList
    var
        XMLRootNode: XmlNode;
        XMLChildNode: XmlNode;
    begin
        GetRootNode(ConvertTextToXmlDocument(Content), XMLRootNode);

        XMLRootNode.SelectSingleNode(pNodePath, XMLChildNode);
        NodeList := XMLChildNode.AsXmlElement().GetChildNodes();
    end;

    procedure ConvertTextToXmlDocument(Content: Text): XmlDocument
    var
        XmlDoc: XmlDocument;
    begin
        if XmlDocument.ReadFrom(Content, XmlDoc) then
            exit(XmlDoc);
    end;

    procedure GetRootNode(pXMLDocument: XmlDocument; var pFoundXMLNode: XmlNode)
    var
        lXmlElement: XmlElement;
    begin
        pXMLDocument.GetRoot(lXmlElement);
        pFoundXMLNode := lXmlElement.AsXmlNode();
    end;

    procedure GetBaseTableTemplate(): Text
    begin
        //Id, Prefix, Name, PK, Fields
        exit('dGFibGUgJTEgIiUyICUzIgp7CiAgICBDYXB0aW9uID0gJyUzJzsKICAgIERhdGFDbGFzc2lmaWNhdGlvbiA9IEN1c3RvbWVyQ29udGVudDsKCiAgICBmaWVsZHMKICAgIHsKICAgICAgICU1CiAgICB9CiAgICBrZXlzCiAgICB7CiAgICAgICAga2V5KFBLOyAiJTQiKQogICAgICAgIHsKICAgICAgICAgICAgQ2x1c3RlcmVkID0gdHJ1ZTsKICAgICAgICB9CiAgICB9Cgp9Cg==');
    end;

    procedure GetBaseTableFieldTemplate(): Text
    begin
        //Id, Name, Type
        exit('ZmllbGQoJTE7ICIlMiI7ICUzKQp7CiAgICBDYXB0aW9uID0gJyUyJzsKICAgIERhdGFDbGFzc2lmaWNhdGlvbiA9IEN1c3RvbWVyQ29udGVudDsKfQo=');
    end;

    procedure GetBaseCodeunitTemplate(): Text
    begin
        //Id, Prefix, Name, Procedures
        exit('Y29kZXVuaXQgJTEgIiUyICUzIg0Kew0KICAgICU0DQp9');
    end;

    procedure GetBaseProcedureTemplate(): Text
    begin
        //Local,Name,Input Params,Return value,Variables,Body of procedure
        exit('JTEgcHJvY2VkdXJlICUyKCUzKSU0DQolNQ0KYmVnaW4NCiAgICAlNg0KZW5kOw==');
    end;

    procedure GetBaseParseJSONProcedures(): Text
    begin
        exit('cHJvY2VkdXJlIFNlbGVjdEpzb25Ub2tlbihKT2JqZWN0OiBKc29uT2JqZWN0OyBQYXRoOiBUZXh0KTogVGV4dA0KdmFyDQogICAgSlRva2VuOiBKc29uVG9rZW47DQpiZWdpbg0KICAgIGlmIEpPYmplY3QuU2VsZWN0VG9rZW4oUGF0aCwgSlRva2VuKSB0aGVuDQogICAgICAgIGlmIG5vdCBKVG9rZW4uQXNWYWx1ZSgpLklzTnVsbCgpIHRoZW4NCiAgICAgICAgICAgIGV4aXQoSlRva2VuLkFzVmFsdWUoKS5Bc1RleHQoKSk7DQplbmQ7DQoNCnByb2NlZHVyZSBHZXRWYWx1ZUFzVGV4dChKVG9rZW46IEpzb25Ub2tlbjsgUGFyYW1TdHJpbmc6IFRleHQpOiBUZXh0DQp2YXINCiAgICBKT2JqZWN0OiBKc29uT2JqZWN0Ow0KYmVnaW4NCiAgICBKT2JqZWN0IDo9IEpUb2tlbi5Bc09iamVjdCgpOw0KICAgIGV4aXQoU2VsZWN0SnNvblRva2VuKEpPYmplY3QsIFBhcmFtU3RyaW5nKSk7DQplbmQ7');
    end;

    procedure GetBaseJsonReaderProcedureBody(): Text
    begin
        exit('aWYgSlNPTkFzVHh0ID0gJycgdGhlbgogICAgZXhpdDsKCkpUb2tlbi5SZWFkRnJvbShKU09OQXNUeHQpOwpKT2JqZWN0IDo9IEpUb2tlbi5Bc09iamVjdCgpOwpKT2JqZWN0LlNlbGVjdFRva2VuKCclMScsIEpUb2tlbik7CkpBcnJheSA6PSBKVG9rZW4uQXNBcnJheSgpOwoKZm9yZWFjaCBKVG9rZW4gaW4gSkFycmF5IGRvIGJlZ2luCiAgJTIKZW5kOw==');
    end;

    local procedure GetBaseParseXMLProcedures(): Text
    begin
        exit('cHJvY2VkdXJlIEdldFZhbHVlRnJvbVhNTChDb250ZW50OiBUZXh0OyBwTm9kZVBhdGg6IFRleHQpOiBUZXh0CnZhcgogICAgWE1MUm9vdE5vZGU6IFhtbE5vZGU7CiAgICBYTUxDaGlsZE5vZGU6IFhtbE5vZGU7CiAgICBYTUxFbGVtOiBYbWxFbGVtZW50OwpiZWdpbgogICAgR2V0Um9vdE5vZGUoQ29udmVydFRleHRUb1htbERvY3VtZW50KENvbnRlbnQpLCBYTUxSb290Tm9kZSk7CgogICAgWE1MUm9vdE5vZGUuU2VsZWN0U2luZ2xlTm9kZShwTm9kZVBhdGgsIFhNTENoaWxkTm9kZSk7CiAgICBYTUxFbGVtIDo9IFhNTENoaWxkTm9kZS5Bc1htbEVsZW1lbnQoKTsKICAgIGV4aXQoWE1MRWxlbS5Jbm5lclhtbCgpKTsKZW5kOwoKcHJvY2VkdXJlIEdldE5vZGVMaXN0KENvbnRlbnQ6IFRleHQ7IHBOb2RlUGF0aDogVGV4dCkgTm9kZUxpc3Q6IFhtbE5vZGVMaXN0CnZhcgogICAgWE1MUm9vdE5vZGU6IFhtbE5vZGU7CiAgICBYTUxDaGlsZE5vZGU6IFhtbE5vZGU7CmJlZ2luCiAgICBHZXRSb290Tm9kZShDb252ZXJ0VGV4dFRvWG1sRG9jdW1lbnQoQ29udGVudCksIFhNTFJvb3ROb2RlKTsKCiAgICBYTUxSb290Tm9kZS5TZWxlY3RTaW5nbGVOb2RlKHBOb2RlUGF0aCwgWE1MQ2hpbGROb2RlKTsKICAgIE5vZGVMaXN0IDo9IFhNTENoaWxkTm9kZS5Bc1htbEVsZW1lbnQoKS5HZXRDaGlsZE5vZGVzKCk7CmVuZDsKCnByb2NlZHVyZSBDb252ZXJ0VGV4dFRvWG1sRG9jdW1lbnQoQ29udGVudDogVGV4dCk6IFhtbERvY3VtZW50CnZhcgogICAgWG1sRG9jOiBYbWxEb2N1bWVudDsKYmVnaW4KICAgIGlmIFhtbERvY3VtZW50LlJlYWRGcm9tKENvbnRlbnQsIFhtbERvYykgdGhlbgogICAgICAgIGV4aXQoWG1sRG9jKTsKZW5kOwoKcHJvY2VkdXJlIEdldFJvb3ROb2RlKHBYTUxEb2N1bWVudDogWG1sRG9jdW1lbnQ7IHZhciBwRm91bmRYTUxOb2RlOiBYbWxOb2RlKQp2YXIKICAgIGxYbWxFbGVtZW50OiBYbWxFbGVtZW50OwpiZWdpbgogICAgcFhNTERvY3VtZW50LkdldFJvb3QobFhtbEVsZW1lbnQpOwogICAgcEZvdW5kWE1MTm9kZSA6PSBsWG1sRWxlbWVudC5Bc1htbE5vZGUoKTsKZW5kOw==');
    end;

    var
        ObjectNameLbl: Label '%1%2.%3%4.al', Comment = '%1 = Object Type, %2 = Object Id, %3 = Object Prefix, %4 = Object Name', Locked = true;
        ProcedureParamsLbl: Label 'ObjectAsTxt: Text; var Temp%1: Record "%2 %1" temporary', Locked = true, Comment = '%1 = RecordName, %2 = Prefix';
}

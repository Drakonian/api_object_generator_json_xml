enum 81800 "AOG Auth Type"
{
    Extensible = true;

    value(0; "No Auth")
    {
        Caption = 'No Auth';
    }
    value(1; "Bearer Token")
    {
        Caption = 'Bearer Token';
    }
    value(2; Basic)
    {
        Caption = 'Basic';
    }
    value(3; "OAuth 1.0")
    {
        Caption = 'OAuth 1.0';
    }
    value(4; "OAuth 2.0")
    {
        Caption = 'OAuth 2.0';
    }
}

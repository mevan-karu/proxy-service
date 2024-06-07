public type EndpointConfig record {|
    string endpointContext;
    string backendServiceEp;
    boolean encryptionEnabled;
    boolean cachingEnabled;
    MaskingConfig[] & readonly maskingConfig?;  
|};

public type MaskingConfig record {|
    string fieldName;
    string maskingRegex;
    string maskingString;
|};

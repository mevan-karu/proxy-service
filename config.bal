import ballerina/os;

public configurable string encodedClientPublicKey = "";
public configurable string encodedServerPrivateKey = os:getEnv("ENCODED_SERVER_PRIVATE_KEY");

public configurable EndpointConfig[] endpoint_config = [];


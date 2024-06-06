import ballerina/http;
import ballerina/log;

map<http:Client> clients = {};
map<EndpointConfig> endpointConfigs = {};

function init() {
    foreach EndpointConfig endpointConfig in endpoint_config {
        http:Client|error 'client = new (endpointConfig.backendServiceEp);
        if ('client is error) {
            log:printError("Error creating client for endpoint : " + endpointConfig.endpointContext, 'error = 'client);
            panic(error("Error creating client for endpoint : " + endpointConfig.endpointContext));
        }
        clients[endpointConfig.endpointContext] = 'client;
        endpointConfigs[endpointConfig.endpointContext] = endpointConfig;
    }
}

# A mediation service to perform mediation between the client and the backend service.
# bound to port `9090`.
service / on new http:Listener(9089) {

    resource function get [string ...paths](http:Caller caller, http:Request req) returns error? {
        log:printInfo("Received GET request for : " + req.rawPath);
        string contextPath = resolveContextPath(req.rawPath);
        if (contextPath == "") {
            return error("No matching context path found for : " + req.rawPath);
        }
        http:Client|error 'client = getClient(contextPath);
        if ('client is error) {
            return 'client;
        }
        EndpointConfig|error endpointConfig = getEndpointConfig(contextPath);
        if (endpointConfig is error) {
            return endpointConfig;
        }
        http:Response clientResponse = check 'client->execute(req.method, processRequestPath(req.rawPath), req);
        return replyToCaller(caller, clientResponse);
    }

    resource function post [string ...paths](http:Caller caller, http:Request req) returns error? {
        log:printInfo("Received POST request for : " + req.rawPath);
        string contextPath = resolveContextPath(req.rawPath);
        if (contextPath == "") {
            return error("No matching context path found for : " + req.rawPath);
        }
        http:Client|error 'client = getClient(contextPath);
        if ('client is error) {
            return 'client;
        }
        EndpointConfig|error endpointConfig = getEndpointConfig(contextPath);
        if (endpointConfig is error) {
            return endpointConfig;
        }
        check processRequest(endpointConfig, req);
        http:Response clientResponse = check 'client->execute(req.method, processRequestPath(req.rawPath), req);
        check processResponse(endpointConfig, clientResponse);
        return replyToCaller(caller, clientResponse);
    }
}

function resolveContextPath(string path) returns string {
    string matchingContextPath = "";
    foreach string contextPath in endpointConfigs.keys() {
        if (path.startsWith(contextPath)) {
            matchingContextPath = contextPath;
        }
    }
    return matchingContextPath;
}

function getClient(string contextPath) returns http:Client|error {
    http:Client? 'client = clients[contextPath];
    if ('client == ()) {
        return error("Client not found for context path : " + contextPath);
    }
    return 'client;
}

function getEndpointConfig(string contextPath) returns EndpointConfig|error {
    EndpointConfig? endpointConfig = endpointConfigs[contextPath];
    if (endpointConfig == ()) {
        return error("Endpoint configuration not found");
    }
    return endpointConfig;
}

function replyToCaller(http:Caller caller, http:Response clientResponse) returns http:ListenerError? {
    check caller->respond(clientResponse);
}

function processRequest(EndpointConfig endpointConfig, http:Request req) returns error? {
    if (endpointConfig.encryptionEnabled) {
        byte[] decryptedPayload = check decryptData(check req.getBinaryPayload(), encodedClientPublicKey);
        req.setBinaryPayload(decryptedPayload, contentType = "application/json");
    }
}

function processResponse(EndpointConfig endpointConfig, http:Response res) returns error? {
    json processedResponse = check res.getJsonPayload();
    if (endpointConfig.maskingConfig != ()) {
        processedResponse = check maskData(endpointConfig.maskingConfig ?: [], check res.getJsonPayload());
    }
    if (endpointConfig.encryptionEnabled) {
        byte[] encryptedPayload = check encryptData(processedResponse.toJsonString().toBytes(), encodedClientPublicKey);
        res.setBinaryPayload(encryptedPayload.toBase64().toBytes(), contentType = "application/octet-stream");
    }
}

function processRequestPath(string rawPath) returns string {
    return re `^.*/`.replace(rawPath, "/");
}

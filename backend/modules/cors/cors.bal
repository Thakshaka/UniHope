import ballerina/http;

public isolated class CorsHandler {
    private final string allowedOrigin;

    public function init(string allowedOrigin) {
        self.allowedOrigin = allowedOrigin;
    }

    public isolated function setCorsHeaders(http:Response response) {
        response.setHeader("Access-Control-Allow-Origin", self.allowedOrigin);
        response.setHeader("Access-Control-Allow-Credentials", "true");
    }

    public isolated function getPreflightResponse() returns http:Response {
        http:Response response = new;
        response.setHeader("Access-Control-Allow-Origin", self.allowedOrigin);
        response.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        response.setHeader("Access-Control-Allow-Headers", "Content-Type");
        response.setHeader("Access-Control-Allow-Credentials", "true");
        return response;
    }
}
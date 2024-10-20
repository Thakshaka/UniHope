import ballerina/http;

public class CorsHandler {
    private final string allowedOrigin;

    public function init(string allowedOrigin) {
        self.allowedOrigin = allowedOrigin;
    }

    public function setCorsHeaders(http:Response response) {
        response.setHeader("Access-Control-Allow-Origin", self.allowedOrigin);
        response.setHeader("Access-Control-Allow-Credentials", "true");
    }

    public function getPreflightResponse() returns http:Response {
        http:Response response = new;
        response.setHeader("Access-Control-Allow-Origin", self.allowedOrigin);
        response.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
        response.setHeader("Access-Control-Allow-Headers", "Content-Type");
        response.setHeader("Access-Control-Allow-Credentials", "true");
        return response;
    }
}
import ballerina/http;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;
import ballerina/email;
import backend.auth;
import backend.db;
import backend.types;
import backend.cors;

// Configure the PostgreSQL connection
configurable string dbHost = ?;
configurable string dbName = ?;
configurable string dbUsername = ?;
configurable string dbPassword = ?;
configurable int dbPort = ?;

// Configure email settings
configurable string smtpHost = ?;
configurable string smtpUsername = ?;
configurable string smtpPassword = ?;

// Configue Server
configurable int serverPort = ?;

// Configure Model API
configurable string modelApiUrl = ?;

// Define HTTP client to post data to model
http:Client model = check new (modelApiUrl);

// Initialize the PostgreSQL client
postgresql:Client dbClient = check new(
    host = dbHost,
    database = dbName,
    username = dbUsername,
    password = dbPassword,
    port = dbPort
);

// Initialize the SMTP client
email:SmtpClient smtpClient = check new (smtpHost, smtpUsername, smtpPassword);

// Initialize handlers
auth:AuthHandler authHandler = new(dbClient, smtpClient);
db:DatabaseHandler dbHandler = new(dbClient);
cors:CorsHandler corsHandler = new("http://localhost:3000");

service /api on new http:Listener(serverPort) {
    // Registration endpoint
    resource function post register(@http:Payload json payload) returns http:Response|error {
        string username = check payload.username;
        string email = check payload.email;
        string password = check payload.password;

        http:Response response = new;

        do {
            check authHandler.registerUser(username, email, password);
            response.statusCode = 201;
            response.setJsonPayload({"message": "User registered successfully"});
        } on fail var e {
            response.statusCode = 400;
            response.setJsonPayload({"error": e.message()});
        }

        corsHandler.setCorsHeaders(response);
        return response;
    }

    // Login endpoint
    resource function post login(@http:Payload json payload) returns http:Response|error {
        string email = check payload.email;
        string password = check payload.password;

        http:Response response = new;

        do {
            types:User|error authResult = check authHandler.authenticateUser(email, password);
            if authResult is types:User {
                response.statusCode = 200;
                response.setJsonPayload({
                    "message": "Login successful",
                    "user": {
                        "id": authResult.id,
                        "username": authResult.username,
                        "email": authResult.email
                    }
                });
            } else {
                response.statusCode = 401;
                response.setJsonPayload({"error": "Invalid credentials"});
            }
        } on fail {
            response.statusCode = 500;
            response.setJsonPayload({"error": "Internal server error"});
        }

        corsHandler.setCorsHeaders(response);
        return response;
    }

    // Forgot Password endpoint
    resource function post forgot\-password(@http:Payload json payload) returns http:Response {
    http:Response response = new;
    string successMessage = "If an account exists for this email, you will receive password reset instructions shortly.";

    do {
        string email = check payload.email;
        // Even if handleForgotPassword returns an error, we don't want to expose that
        _ = check authHandler.handleForgotPassword(email);
        response.statusCode = 200;
        response.setJsonPayload({"message": successMessage});
    } on fail {
        // Still return 200 with same message for security
        response.statusCode = 200;
        response.setJsonPayload({"message": successMessage});
    }

    corsHandler.setCorsHeaders(response);
    return response;
}

    // Reset Password endpoint
    resource function post reset\-password(@http:Payload json payload) returns http:Response {
        http:Response response = new;

        do {
            string token = check payload.token;
            string newPassword = check payload.newPassword;

            check authHandler.resetPassword(token, newPassword);
            response.statusCode = 200;
            response.setJsonPayload({"message": "Your password has been successfully reset."});
        } on fail var e {
            response.statusCode = 400;
            response.setJsonPayload({"error": e.message()});
        }

        corsHandler.setCorsHeaders(response);
        return response;
    }

    // Logout endpoint
    resource function post logout() returns http:Response {
        http:Response response = new;
        response.setJsonPayload({"message": "Logged out successfully"});
        response.statusCode = 200;
        
        corsHandler.setCorsHeaders(response);
        return response;
    }

    // Subjects endpoint
    resource function get subjects() returns http:Response|error {
        http:Response response = new;
        
        types:Subject[]|error subjects = dbHandler.getSubjects();
        if subjects is error {
            response.statusCode = 500;
            response.setPayload({"error": "Failed to fetch subjects"});
        } else {
            json[] jsonSubjects = subjects.map(function(types:Subject subject) returns json {
                return {
                    id: subject.id,
                    subject_name: subject.subject_name
                };
            });
            response.setJsonPayload(jsonSubjects);
        }
        
        corsHandler.setCorsHeaders(response);
        return response;
    }

    // Districts endpoint
    resource function get districts() returns http:Response|error {
        http:Response response = new;
        
        types:District[]|error districts = dbHandler.getDistricts();
        if districts is error {
            response.statusCode = 500;
            response.setPayload({"error": "Failed to fetch districts"});
        } else {
            json[] jsonDistricts = districts.map(function(types:District district) returns json {
                return {
                    id: district.id,
                    district_name: district.district_name
                };
            });
            response.setJsonPayload(jsonDistricts);
        }
        
        corsHandler.setCorsHeaders(response);
        return response;
    }

    // Handle POST request for user input data
    resource function post userInputData(http:Caller caller, http:Request req) returns error? {
        json userInputData = check req.getJsonPayload();

        string subject1 = check userInputData.subject1;
        string subject2 = check userInputData.subject2;
        string subject3 = check userInputData.subject3;
        string zScore = check userInputData.zScore;
        string year = check userInputData.year;
        string district = check userInputData.district;

        string category = check dbHandler.getCategory(subject1, subject2, subject3);

        json modelRequest = {
            "category": category,
            "district": district,
            "year": year
        };

        http:Response modelRes = check model->post("/predict", modelRequest);
        json modelResponseData = check modelRes.getJsonPayload();

        json[] filteredModelResponseData = [];

        float zScoreValue = check 'float:fromString(zScore);

        if (modelResponseData is json[]) {
            foreach json obj in modelResponseData {
                float this_year_predicted = check obj.this_year_predicted;
                if (this_year_predicted <= zScoreValue) {
                    filteredModelResponseData.push(obj);
                }
            }
        }

        json Response = {
            "modelResponseData": modelResponseData,
            "filteredModelResponseData": filteredModelResponseData,
            "category": category
        };

        http:Response res = new;
        res.setJsonPayload(Response);
        corsHandler.setCorsHeaders(res);
        check caller->respond(res);
    }

    // CORS preflight handlers
    resource function options forgot\-password() returns http:Response {
        return corsHandler.getPreflightResponse();
    }
    
    resource function options reset\-password() returns http:Response {
        return corsHandler.getPreflightResponse();
    }

    resource function options logout() returns http:Response {
        return corsHandler.getPreflightResponse();
    }

    resource function options register() returns http:Response {
        return corsHandler.getPreflightResponse();
    }

    resource function options login() returns http:Response {
        return corsHandler.getPreflightResponse();
    }

    resource function options districts() returns http:Response {
        return corsHandler.getPreflightResponse();
    }

    resource function options subjects() returns http:Response {
        return corsHandler.getPreflightResponse();
    }

    resource function options userInputData() returns http:Response {
        return corsHandler.getPreflightResponse();
    }
}
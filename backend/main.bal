import ballerina/http;
import ballerina/sql;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;
import ballerina/email;
import backend.auth;

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

configurable int serverPort = ?;
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

// Initialize the AuthHandler
auth:AuthHandler authHandler = new(dbClient, smtpClient);

// Function to get all subjects from database
function getSubjects() returns Subject[]|error {
    sql:ParameterizedQuery query = `SELECT * FROM subjects ORDER BY subject_name`;
    stream<Subject, sql:Error?> resultStream = dbClient->query(query);
    
    Subject[] subjects = [];
    check from Subject subject in resultStream
        do {
            subjects.push(subject);
        };
    
    return subjects;
}

// Function to get all districts from database
function getDistricts() returns District[]|error {
    sql:ParameterizedQuery query = `SELECT * FROM districts`;
    stream<District, sql:Error?> resultStream = dbClient->query(query);
    
    District[] districts = [];
    check from District district in resultStream
        do {
            districts.push(district);
        };
    
    return districts;
}

// Function to determine the category based on 3 subject inputs
function getCategory(string subject1, string subject2, string subject3) returns string|error {
    // SQL query to find matching category considering all possible permutations
    sql:ParameterizedQuery query = `
        SELECT category 
        FROM Category_Combinations 
        WHERE 
        -- Check all possible permutations
        (subject1 = ${subject1} AND subject2 = ${subject2} AND subject3 = ${subject3}) OR
        (subject1 = ${subject1} AND subject2 = ${subject3} AND subject3 = ${subject2}) OR
        (subject1 = ${subject2} AND subject2 = ${subject1} AND subject3 = ${subject3}) OR
        (subject1 = ${subject2} AND subject2 = ${subject3} AND subject3 = ${subject1}) OR
        (subject1 = ${subject3} AND subject2 = ${subject1} AND subject3 = ${subject2}) OR
        (subject1 = ${subject3} AND subject2 = ${subject2} AND subject3 = ${subject1})`;

    stream<record {string category;}, sql:Error?> result = dbClient->query(query);
    record {|record {string category;} value;|}|error? firstRow = result.next();
    
    if firstRow is record {|record {string category;} value;|} {
        return firstRow.value.category;
    }
    
    return "Unknown";
}

service /api on new http:Listener(serverPort) {
    // Forgot Password endpoint
    resource function post forgot\-password(@http:Payload json payload) returns http:Response {
        http:Response response = new;

        do {
            string email = check payload.email;
            check authHandler.handleForgotPassword(email);
            response.statusCode = 200;
            response.setJsonPayload({"message": "If an account exists for this email, you will receive password reset instructions shortly."});
        } on fail {
            response.statusCode = 500;
            response.setJsonPayload({"error": "An error occurred while processing your request."});
        }

        response.setHeader("Access-Control-Allow-Origin", "http://localhost:3000");
        response.setHeader("Access-Control-Allow-Credentials", "true");
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

        response.setHeader("Access-Control-Allow-Origin", "http://localhost:3000");
        response.setHeader("Access-Control-Allow-Credentials", "true");
        return response;
    }

    // Logout endpoint
    resource function post logout() returns http:Response {
        http:Response response = new;
        response.setJsonPayload({"message": "Logged out successfully"});
        response.statusCode = 200;
        
        response.setHeader("Access-Control-Allow-Origin", "http://localhost:3000");
        response.setHeader("Access-Control-Allow-Credentials", "true");
        return response;
    }

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

        response.setHeader("Access-Control-Allow-Origin", "http://localhost:3000");
        response.setHeader("Access-Control-Allow-Credentials", "true");
        return response;
    }

    // Login endpoint
    resource function post login(@http:Payload json payload) returns http:Response|error {
        string email = check payload.email;
        string password = check payload.password;

        http:Response response = new;

        do {
            auth:User|error authResult = check authHandler.authenticateUser(email, password);
            if authResult is auth:User {
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

        response.setHeader("Access-Control-Allow-Origin", "http://localhost:3000");
        response.setHeader("Access-Control-Allow-Credentials", "true");
        return response;
    }

    // Districts endpoint
    resource function get districts() returns http:Response|error {
        District[]|error districts = getDistricts();
        http:Response response = new;
        
        if districts is error {
            response.statusCode = 500;
            response.setPayload({"error": "Failed to fetch districts"});
        } else {
            json[] jsonDistricts = districts.map(function(District district) returns json {
                return {
                    id: district.id,
                    district_name: district.district_name
                };
            });
            response.setJsonPayload(jsonDistricts);
        }
        
        response.setHeader("Access-Control-Allow-Origin", "http://localhost:3000");
        response.setHeader("Access-Control-Allow-Credentials", "true");
        return response;
    }

    // Subjects endpoint
    resource function get subjects() returns http:Response|error {
        Subject[]|error subjects = getSubjects();
        http:Response response = new;
        
        if subjects is error {
            response.statusCode = 500;
            response.setPayload({"error": "Failed to fetch subjects"});
        } else {
            json[] jsonSubjects = subjects.map(function(Subject subject) returns json {
                return {
                    id: subject.id,
                    subject_name: subject.subject_name
                };
            });
            response.setJsonPayload(jsonSubjects);
        }
        
        response.setHeader("Access-Control-Allow-Origin", "http://localhost:3000");
        response.setHeader("Access-Control-Allow-Credentials", "true");
        return response;
    }

    // Handle POST request for user input data
    resource function post postUserInputData(http:Caller caller, http:Request req) returns error? {
        json userInputData = check req.getJsonPayload();

        string subject1 = check userInputData.subject1;
        string subject2 = check userInputData.subject2;
        string subject3 = check userInputData.subject3;
        string zScore = check userInputData.zScore;
        string year = check userInputData.year;
        string district = check userInputData.district;

        string category = check getCategory(subject1, subject2, subject3);

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
        res.setHeader("Access-Control-Allow-Origin", "http://localhost:3000");
        res.setHeader("Access-Control-Allow-Credentials", "true");

        check caller->respond(res);
    }

    // CORS preflight handlers
    resource function options forgot\-password() returns http:Response {
        return getCorsResponse();
    }

    resource function options reset\-password() returns http:Response {
        return getCorsResponse();
    }

    resource function options logout() returns http:Response {
        return getCorsResponse();
    }

    resource function options register() returns http:Response {
        return getCorsResponse();
    }

    resource function options login() returns http:Response {
        return getCorsResponse();
    }

    resource function options districts() returns http:Response {
        return getCorsResponse();
    }

    resource function options subjects() returns http:Response {
        return getCorsResponse();
    }

    resource function options postUserInputData() returns http:Response {
        return getCorsResponse();
    }
}

// Helper function to create CORS response
function getCorsResponse() returns http:Response {
    http:Response response = new;
    response.setHeader("Access-Control-Allow-Origin", "http://localhost:3000");
    response.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    response.setHeader("Access-Control-Allow-Headers", "Content-Type");
    response.setHeader("Access-Control-Allow-Credentials", "true");
    return response;
}
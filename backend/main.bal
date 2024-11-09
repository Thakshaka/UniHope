import ballerina/http;
import ballerinax/postgresql;
import ballerinax/postgresql.driver as _;
import ballerina/email;
import backend.auth;
import backend.db;
import backend.types;

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
final http:Client model = check new (modelApiUrl);

// Initialize the PostgreSQL client
final postgresql:Client dbClient = check new(
    host = dbHost,
    database = dbName,
    username = dbUsername,
    password = dbPassword,
    port = dbPort
);

// Initialize the SMTP client
final email:SmtpClient smtpClient = check new (smtpHost, smtpUsername, smtpPassword);

// Initialize handlers
final auth:AuthHandler authHandler = new(dbClient, smtpClient);
final db:DatabaseHandler dbHandler = new(dbClient);

// Record type for Registration Payload
public type RegistrationPayload record {|
    string username;
    string email;
    string password;
|};

// Record type for Login Payload
public type LoginPayload record {|
    string email;
    string password;
|};

// Record type for Forgot Password Payload
public type ForgotPasswordPayload record {|
    string email;
|};

// Record type for Reset Password Payload
public type ResetPasswordPayload record {|
    string token;
    string newPassword;
|};

// Record type for User Input Payload
public type UserInputPayload record {|
        string subject1;
        string subject2;
        string subject3;
        string zScore;
        string year;
        string district;
    |};

// Add service-level CORS configuration
@http:ServiceConfig {
    cors: {
        allowOrigins: ["http://localhost:3000"],
        allowCredentials: true,
        allowHeaders: ["Content-Type", "Authorization"],
        maxAge: 84900
    }
}

service /api on new http:Listener(serverPort) {
    // Registration endpoint
    isolated resource function post register(RegistrationPayload payload) returns http:Created|http:BadRequest {
        do {
            check authHandler->registerUser(payload.username, payload.email, payload.password);
            return <http:Created> { body: { message: "User registered successfully" } };
        } on fail var e {
            return <http:BadRequest> { body: { message: e.message() } };
        }
    }

    // Login endpoint
    isolated resource function post login(LoginPayload payload) returns http:Ok|http:Unauthorized|http:InternalServerError {
        do {
            types:User|error authResult = check authHandler->authenticateUser(payload.email, payload.password);
            if authResult is types:User {
                return <http:Ok> {
                    body: {
                        message: "Login successful",
                        user: {
                            id: authResult.id,
                            username: authResult.username,
                            email: authResult.email
                        }
                    }
                };
            } else {
                return <http:Unauthorized> {
                    body: {message: "Invalid credentials"}
                };
            }
        } on fail {
            return <http:InternalServerError> {
                body: {message: "Internal server error"}
            };
        }
    }

    // Forgot Password endpoint
    isolated resource function post forgot\-password(ForgotPasswordPayload payload) returns http:Ok {
        do {
            _ = check authHandler->handleForgotPassword(payload.email);
        } on fail {
            // Intentionally ignore errors to prevent email enumeration
        }
        return {
            body: { message: "If an account exists for this email, you will receive password reset instructions shortly." }
        };
    }

    // Reset Password endpoint
    isolated resource function post reset\-password(ResetPasswordPayload payload) returns http:Ok|http:BadRequest {
        do {
            check authHandler->resetPassword(payload.token, payload.newPassword);
            return <http:Ok>{
                body: { message: "Your password has been successfully reset." }
            };
        } on fail var e {
            return <http:BadRequest>{ 
                body: { message: e.message() }
            };
        }
    }

    // Logout endpoint
    resource function post logout() returns http:Ok {
        return { body: { message: "Logged out successfully" } };
    }

    // Subjects endpoint
    isolated resource function get subjects() returns types:Subject[]|http:InternalServerError {
        types:Subject[]|error subjects = dbHandler->getSubjects();
        if subjects is error {
            return { body: { message: "Failed to fetch subjects" } };
        } else {
            return subjects;
        }
    }

    // Districts endpoint
    isolated resource function get districts() returns types:District[]|http:InternalServerError {
        
        types:District[]|error districts = dbHandler->getDistricts();
        if districts is error {
            return { body: { message: "Failed to fetch districts" } };
        } else {
            return districts;
        }
    }

    // Handle POST request for user input data
    isolated resource function post userInputData(UserInputPayload payload) returns http:Ok|http:InternalServerError {
        do {
            string category = check dbHandler->getCategory(payload.subject1, payload.subject2, payload.subject3);

            json modelRequest = {
                category: category,
                district: payload.district,
                year: payload.year
            };

            json[] modelResponseData = check model->post("/predict", modelRequest);

            float zScoreValue = check 'float:fromString(payload.zScore);

            json[] filteredModelResponseData = [];

            foreach json obj in modelResponseData {
                float this_year_predicted = check obj.this_year_predicted;
                if (this_year_predicted <= zScoreValue) {
                    filteredModelResponseData.push(obj);
                }
            }

            return <http:Ok> {
                body:  {
                    modelResponseData: modelResponseData,
                    filteredModelResponseData: filteredModelResponseData,
                    category: category
                }
            };
        } on fail var e {
            return <http:InternalServerError> {
                body: { message: e.message() }
            };
        }
    }
}
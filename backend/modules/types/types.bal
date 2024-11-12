// types.bal

import ballerina/time;

// Record type for Subject
public type Subject record {|
    int id;
    string subject_name;
|};

// Record type for District
public type District record {|
    int id;
    string district_name;
|};

// Record type for User
public type User record {|
    int id;
    string username;
    string email;
    string password_hash;
    string? reset_token;
    time:Civil? reset_token_expires;
|};

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
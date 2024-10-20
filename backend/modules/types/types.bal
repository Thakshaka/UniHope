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
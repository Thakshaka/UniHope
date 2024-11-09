import ballerina/sql;
import ballerinax/postgresql;
import backend.types;

public client class DatabaseHandler {
    private final postgresql:Client dbClient;

    public function init(postgresql:Client dbClient) {
        self.dbClient = dbClient;
    }

    // Function to get all subjects from database
    remote function getSubjects() returns types:Subject[]|error {
        sql:ParameterizedQuery query = `SELECT * FROM subjects ORDER BY subject_name`;
        stream<types:Subject, sql:Error?> resultStream = self.dbClient->query(query);
        
        types:Subject[] subjects = [];
        check from types:Subject subject in resultStream
            do {
                subjects.push(subject);
            };
        
        return subjects;
    }

    // Function to get all districts from database
    remote function getDistricts() returns types:District[]|error {
        sql:ParameterizedQuery query = `SELECT * FROM districts`;
        stream<types:District, sql:Error?> resultStream = self.dbClient->query(query);
        
        types:District[] districts = [];
        check from types:District district in resultStream
            do {
                districts.push(district);
            };
        
        return districts;
    }

    // Function to determine the category based on 3 subject inputs
    remote function getCategory(string subject1, string subject2, string subject3) returns string|error {
        sql:ParameterizedQuery query = `
            SELECT category 
            FROM Category_Combinations 
            WHERE 
            (subject1 = ${subject1} AND subject2 = ${subject2} AND subject3 = ${subject3}) OR
            (subject1 = ${subject1} AND subject2 = ${subject3} AND subject3 = ${subject2}) OR
            (subject1 = ${subject2} AND subject2 = ${subject1} AND subject3 = ${subject3}) OR
            (subject1 = ${subject2} AND subject2 = ${subject3} AND subject3 = ${subject1}) OR
            (subject1 = ${subject3} AND subject2 = ${subject1} AND subject3 = ${subject2}) OR
            (subject1 = ${subject3} AND subject2 = ${subject2} AND subject3 = ${subject1})`;

        stream<record {string category;}, sql:Error?> result = self.dbClient->query(query);
        record {|record {string category;} value;|}|error? firstRow = result.next();
        
        if firstRow is record {|record {string category;} value;|} {
            return firstRow.value.category;
        }
        
        return "Unknown";
    }
}
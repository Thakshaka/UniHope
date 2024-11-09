import ballerina/crypto;
import ballerina/uuid;
import ballerina/sql;
import ballerinax/postgresql;
import ballerina/email;
import backend.types;
import ballerina/io;

public client class AuthHandler {
    private final postgresql:Client dbClient;
    private final email:SmtpClient smtpClient;

    public function init(postgresql:Client dbClient, email:SmtpClient smtpClient) {
        self.dbClient = dbClient;
        self.smtpClient = smtpClient;
    }

    // Function to hash a password
    isolated function hashPassword(string password) returns string {
        byte[] hashedBytes = crypto:hashSha256(password.toBytes());
        return hashedBytes.toBase16();
    }

    // Function to register a new user
    remote function registerUser(string username, string email, string password) returns error? {
        string hashedPassword = self.hashPassword(password);
        sql:ParameterizedQuery query = `
            INSERT INTO users (username, email, password_hash)
            VALUES (${username}, ${email}, ${hashedPassword})
        `;
        _ = check self.dbClient->execute(query);
    }

    // Function to authenticate a user
    remote function authenticateUser(string email, string password) returns types:User|error {
        string hashedPassword = self.hashPassword(password);
        sql:ParameterizedQuery query = `
            SELECT * FROM users
            WHERE email = ${email} AND password_hash = ${hashedPassword}
        `;
        types:User|sql:Error result = self.dbClient->queryRow(query);
        if result is sql:NoRowsError {
            return error("Authentication failed");
        }
        return result;
    }

    // Function to handle forgot password request
    remote function handleForgotPassword(string email) returns error? {
        // Check if the email exists in the database
        sql:ParameterizedQuery query = `SELECT * FROM users WHERE email = ${email}`;
        types:User|error result = self.dbClient->queryRow(query);

        if result is types:User {
            do {
                // Generate a secure random token
                string resetToken = uuid:createType1AsString();

                // Hash the token before storing it
                byte[] resetTokenHash = crypto:hashSha256(resetToken.toBytes());
                string hashedResetToken = resetTokenHash.toBase16();

                // Store the hashed reset token in the database
                sql:ParameterizedQuery updateQuery = `
                    UPDATE users 
                    SET reset_token = ${hashedResetToken}, 
                        reset_token_expires = (CURRENT_TIMESTAMP + INTERVAL '1 hour')
                    WHERE email = ${email}
                `;
                _ = check self.dbClient->execute(updateQuery);

                // Construct the password reset URL
                string resetUrl = "http://localhost:3000/reset-password?token=" + resetToken;

                // Send email with password reset link
                check self.sendPasswordResetEmail(email, resetUrl);
            } on fail var e {
                // Log error internally, but don't expose it
                io:println("Error sending password reset email: ", e.message());
                // This ensures same behavior for both success and failure cases
                return;
            }
        }
        // Return success for both existing and non-existing emails
        return;
    }

    // Function to reset password
    remote function resetPassword(string token, string newPassword) returns error? {
        // Hash the provided token
        byte[] tokenHash = crypto:hashSha256(token.toBytes());
        string hashedToken = tokenHash.toBase16();

        // Check if the token exists and is not expired
        sql:ParameterizedQuery query = `
            SELECT * FROM users 
            WHERE reset_token = ${hashedToken} AND reset_token_expires > CURRENT_TIMESTAMP
        `;
        types:User|error result = self.dbClient->queryRow(query);

        if result is types:User {
            // Hash the new password
            string hashedPassword = self.hashPassword(newPassword);

            // Update the user's password and clear the reset token
            sql:ParameterizedQuery updateQuery = `
                UPDATE users 
                SET password_hash = ${hashedPassword}, reset_token = NULL, reset_token_expires = NULL 
                WHERE id = ${result.id}
            `;
            _ = check self.dbClient->execute(updateQuery);
        } else {
            return error("Invalid or expired reset token");
        }
    }

    // Function to send password reset email
    private function sendPasswordResetEmail(string toEmail, string resetUrl) returns error? {
        email:Message message = {
            to: [toEmail],
            subject: "Password Reset Instructions",
            body: string `
                Dear User,

                You have requested to reset your password. Please click on the link below to reset your password:

                ${resetUrl}

                This link will expire in 1 hour.

                If you did not request a password reset, please ignore this email.

                Best regards,
                The UniHope Team
            `
        };

        check self.smtpClient->sendMessage(message);
    }
}
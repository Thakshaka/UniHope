import React from "react";
import logo from "./logo.svg";
import "./Footer.css";
import "../Home/Home.js"
import { useTranslation } from "react-i18next";

export default function Footer() {
  const { t } = useTranslation();  // Translation hook
  
  return (
    <div>
      <footer
        className="text-center text-white"
        style={{ backgroundColor: "#0A4275" }}
        id="footer"
      >
        <div className="container p-5">
          <div className="row">
            <div className="col-lg-6 col-md-6">
              <h5>UniHope</h5>

              <p className="description">
                UniHope is an innovative AI-powered platform designed to assist Sri Lankan G.C.E Advanced Level students in their state university course selection process. UniHope analyzes your academic profiles to provide personalized course recommendations, helping you make informed decisions about your higher education journey. UniHope's user-friendly interface and multi-language support ensure accessibility for all, while its advanced algorithms offer up-to-date insights on state university course cutoff predictions. At UniHope, we're committed to simplifying your paths to the right state university course and empowering your academic future.
              </p>
            </div>

            <div className="col-lg-6 col-md-6">
              <h5>Contact</h5>

              <p className="description">
                We're here to help you navigate your educational journey. If you have any questions, suggestions, or need assistance, please don't hesitate to reach out to us.
              </p>
              <ul className="list-unstyled">
                <li><i className="fas fa-envelope me-3"></i> Email: smtpinnovators@gmail.com</li>
              </ul>
            </div>
          </div>
        </div>

        <div className="mb-2">
          <ul className="nav justify-content-center">
            <li className="nav-item">
              <a href="#home" className="nav-link px-2">
                Home
              </a>
            </li>
            <li className="nav-item">
              <a href="#footer" className="nav-link px-2">
                About
              </a>
            </li>
            <li className="nav-item">
              <a href="#footer" className="nav-link px-2">
                Contact
              </a>
            </li>
          </ul>
        </div>

        <div className="text-center p-2 copyright" style={{ backgroundColor: "#17345A" }}>
          Copyright © 2024{" "}
          <img src={logo} alt="LOGO" width="40" height="27"></img> All rights
          reserved
        </div>
      </footer>
    </div>
  );
}

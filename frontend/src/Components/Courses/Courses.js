import React, { useState, useEffect } from "react";
import "./Courses.css";
import NavBar from "../NavBar/NavBar";
import Modal from "../Modal/Modal";
import Footer from "../Footer/Footer";
import ReCAPTCHA from "react-google-recaptcha";
import DistrictSearchableSelect from '../SearchableSelect/DistrictSearchableSelect';
import SubjectSearchableSelect from "../SearchableSelect/SubjectSearchableSelect";
import { useTranslation } from "react-i18next";

export default function Courses() {
  const { t } = useTranslation();  // Translation hook
  const [subject1, setSubject1] = useState("");
  const [subject2, setSubject2] = useState("");
  const [subject3, setSubject3] = useState("");
  const [subjects, setSubjects] = useState([]);
  const [zScore, setZScore] = useState("");
  const [year, setYear] = useState("");
  const [district, setDistrict] = useState("");
  const [userInputData, setInputData] = useState({});
  const [response, setResponse] = useState({});
  const [filteredResponse, setFilteredResponse] = useState([]);
  const [loading, setLoading] = useState(false);
  const [captchaValue, setCaptchaValue] = useState(null);
  const [error, setError] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");
  const [category, setCategory] = useState("");
  const [districts, setDistricts] = useState([]);

  const RECAPTCHA_SITE_KEY = process.env.REACT_APP_RECAPTCHA_SITE_KEY;

  // Render district dropdown
  const renderDistrictSelect = () => (
    <DistrictSearchableSelect
      id="district"
      label={t('form.district')}
      options={districts}
      value={district}
      onChange={setDistrict}
      placeholder="Search district..."
      required
    />
  );

   // Render subject dropdown
   const renderSubjectDropdown = (value, setter, label, number) => (
    <SubjectSearchableSelect
      id={`subject${number}`}
      label={label}
      options={subjects}
      value={value}
      onChange={setter}
      placeholder="Search subject..."
      required
      disabled={getDisabledSubjects(number)}
      getOptionLabel={(option) => option.subject_name}
      getOptionValue={(option) => option.id}
    />
  );

  // Get disabled subjects for each dropdown
  const getDisabledSubjects = (dropdownNumber) => {
    const selectedSubjects = [subject1, subject2, subject3];
    return selectedSubjects.filter((subject, index) => index !== dropdownNumber - 1 && subject !== "");
  };

  // Fetch subjects when component mounts
  const fetchSubjects = async () => {
    try {
      const response = await fetch("http://localhost:8080/api/subjects");
      if (!response.ok) {
        throw new Error("Failed to fetch subjects");
      }
      const data = await response.json();
      setSubjects(data);
    } catch (error) {
      console.error("Error fetching subjects:", error);
      setError(true);
      setErrorMessage("Failed to load subjects. Please try again later.");
    }
  };

  // Fetch districts when component mounts
  const fetchDistricts = async () => {
    try {
      const response = await fetch("http://localhost:8080/api/districts");
      if (!response.ok) {
        throw new Error("Failed to fetch districts");
      }
      const data = await response.json();
      setDistricts(data);
    } catch (error) {
      console.error("Error fetching districts:", error);
      setError(true);
      setErrorMessage("Failed to load districts. Please try again later.");
    }
  };

  // Fetch subjects when component mounts
  useEffect(() => {
    fetchSubjects();
    fetchDistricts();
  }, []);

  // This will be called when the CAPTCHA is solved
  const handleCaptchaChange = (value) => {
    setCaptchaValue(value);
  };

  const handleSubmit = async (e) => {
    e.preventDefault(); // Prevent form submission
    setError(false);
    setErrorMessage("");

    if (!captchaValue) {
      setError(true);
      setErrorMessage("Please verify the CAPTCHA.");
      return;
    }

    setLoading(true);

    const userInputData = {
      subject1,
      subject2,
      subject3,
      zScore,
      year,
      district,
    };

    setInputData(userInputData);
    
    try {
      const response = await fetch("http://localhost:8080/api/userInputData", {
        method: "POST",
        headers: {
          "Content-Type": "application/json", 
        },
        body: JSON.stringify(userInputData),
      });

      if (!response.ok) {
        throw new Error("Failed to send userInputData to backend");
      }

      const res = await response.json();
      console.log("Response:", res);
      setResponse(res.modelResponseData);
      setFilteredResponse(res.filteredModelResponseData);
      setCategory(res.category);

      // Trigger modal using its JavaScript API
      const modal = new window.bootstrap.Modal(document.getElementById('staticBackdrop'));
      modal.show();
    } 
    
    catch (error) {
      console.error("Error:", error);
    }

    finally {
      setLoading(false);
    }

  };

  return (
    <div className="content" id="home">
      <NavBar />

      <div className="container d-flex flex-column bd-highlight justify-content-center align-items-center shadow-lg p-5">
        <div className="p-2 bd-highlight">
          {/* <img src={uom_logo} alt="UOM LOGO" width="150" height="160"></img> */}
        </div>

        <div className="p-2 bd-highlight pb-4">
          <h2 className="topic fw-bold text-center">{t('courses.welcome')}</h2>
          <p className="text-gray-600 text-center">
            {t('courses.description')}
          </p>
        </div>

        <div className="p-2 bd-highlight">
          <form className="row g-4 needs-validation" onSubmit={handleSubmit}>
            <div className="col-md-6">
              {renderSubjectDropdown(subject1, setSubject1, t('form.subject1'), 1)}
              <div className="mt-2"></div>
              {renderSubjectDropdown(subject2, setSubject2, t('form.subject2'), 2)}
              <div className="mt-2"></div>
              {renderSubjectDropdown(subject3, setSubject3, t('form.subject3'), 3)}
            </div>

            <div className="col-md-6">
            <label htmlFor="zScore" className="form-label">
              {t('form.zScore')}
            </label>
            <div className="input-group has-validation">
              <span className="input-group-text" id="inputGroupPrepend">
                #
              </span>
              <input
                type="text"
                className="form-control shadow-sm"
                id="zScore"
                value={zScore}
                pattern="^[0-9]*\.[0-9]{4}$"
                step="0.0001"
                placeholder="1.2345"
                onChange={(e) => {
                  const value = e.target.value;
                  // Match the format X.XXXX
                  const formattedZScore = value.match(/^\d*(\.\d{0,4})?$/) ? value : zScore;
                  setZScore(formattedZScore);
                }}
                required
              />
            </div>

              <div className="mt-2"></div>

              <label htmlFor="year" className="form-label">
               {t('form.year')}
              </label>
              <select
                className="form-select shadow-sm"
                id="year"
                value={year}
                onChange={(e) => setYear(e.target.value)}
                required
              >
                <option selected disabled value="">
                  Select
                </option>
                <option>2024</option>
              </select>

              <div className="mt-2"></div>

              {renderDistrictSelect()}
            </div>

            {/* CAPTCHA */}
            <div className="col-12 d-flex justify-content-center pt-4">
              <ReCAPTCHA
                sitekey={RECAPTCHA_SITE_KEY}
                onChange={handleCaptchaChange}
              />
            </div>

            {error && (
                <small className="text-danger mt-2 text-center">{errorMessage}</small>
              )}

            <div className="col-12 d-flex justify-content-center">
              <button className="btn btn-primary shadow-sm" type="submit" disabled={loading}>
                {loading ? (
                  <span 
                    className="spinner-border spinner-border-sm" 
                    role="status" 
                    aria-hidden="true"
                  ></span>
                ) : (
                   t('courses.submit')
                )}
              </button>

              <button 
                className="btn btn-secondary shadow-sm ms-2"
                type="button" 
                onClick={() => {
                  // Reset all fields
                  setSubject1("");
                  setSubject2("");
                  setSubject3("");
                  setZScore("");
                  setYear("");
                  setDistrict("");
                  setResponse({});
                }}
              >
                {t('courses.reset')}
              </button>
            </div>
          </form>
        </div>
      </div>

      <Modal 
        userInputData={userInputData}
        response={response}
        filteredResponse={filteredResponse}
        category={category}
      />

      <Footer />
    </div>
  );
}
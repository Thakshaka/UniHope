# UniHope 📈 AI-Based Personalized Courses Recommendation and Cutoff Prediction SaaS

## Overview

UniHope is an innovative AI-powered platform designed to assist Sri Lankan students in their university course selection process. By analyzing academic information, UniHope provides personalized course recommendations, helping students make informed decisions about their higher education journey.

<p align="center">
    <img src="./assets/images/home.png" alt="Home Page" width="600"/>
    <img src="./assets/images/courses.png" alt="Courses Page" width="600"/>
    <img src="./assets/images/results.png" alt="Results Page" width="600"/>
</p>


## Release Notes

**20th October 2024** - We're pleased to present **UniHope 1.0x**

Highlights:

We're targeting UniHope's full release by the end of 2024, starting with the 2024 G.C.E. A/L students in Sri Lanka. Understanding the significant impact our system has on students' futures, we're currently conducting extensive beta testing and continuously enhancing our dataset to ensure utmost accuracy and reliability. We warmly welcome contributions from open-source developers who are passionate about collaborating on innovative projects. Your expertise can help shape the future of this initiative. More details are in this [video](https://youtu.be/GnyNuqQK2Oc?feature=shared).

## Features

- Personalized course recommendations based on academic profile
- AI-driven cutoff mark predictions
- Multi-language support (Sinhala, Tamil, English)
- User-friendly interface for easy navigation
- Comprehensive dataset of university courses and their requirements
- Secure user authentication and data protection

## Tech Stack

- Frontend: React.js, Bootstrap
- Backend: Ballerina
- Database: PostgreSQL
- AI Model: Python, FastAPI

## Prerequisites

- Node.js and npm
- Ballerina
- Python 3.7+
- PostgreSQL

## Installation and Setup

### 1. Frontend Setup

```bash
cd frontend
npm install
```

Create a `.env` file in the frontend directory and add:
```
REACT_APP_RECAPTCHA_SITE_KEY=your_recaptcha_site_key_here
```

Start the frontend:
```bash
npm start
```

### 2. Backend Setup

Navigate to the backend directory:
```bash
cd backend
```

Create a `config.toml` file in the backend directory and add:
```
# Database Configuration
dbHost = ""
dbName = ""
dbUsername = ""
dbPassword = ""
dbPort = 

# Email Configuration
smtpHost = "smtp.gmail.com"
smtpUsername = ""
smtpPassword = ""

# Server Configuration
serverPort = 8080

# Model API Configuration
modelApiUrl = "http://localhost:8000"
```

Run the Ballerina server:
```bash
bal run
```

### 3. Machine Learning Model Setup

Navigate to the model directory:
```bash
cd model
```

Install required Python packages:
```bash
pip install -r requirements.txt
```

Start the FastAPI server:
```bash
python -m uvicorn cutoff_predictor:app --reload
```

## Usage

After setting up all components, access the application through `http://localhost:3000` in your web browser.

> **⚠️ Important:**
> 
> Please be noticed that, as this is a **real-world project**, access has been intentionally limited to a smaller portion of our dataset. Testing is currently available for the following subjects: **Combined Mathematics, Biology, Physics, and Chemistry** and districts: **Colombo**.

<p align="center">
    <img src="./assets/images/responsive_1.png" alt="Responsive" width="300"/>
    <img src="./assets/images/responsive_2.png" alt="Responsive" width="300"/>
</p>

## Contributing

We welcome contributions from the open-source community! If you'd like to contribute, please:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

Distributed under the MIT License. See `LICENSE` for more information.

## Contact

```
Email: thakshakarathnayake20@gmail.com
WhatsApp: +94 758447545
```

## Acknowledgements

- [Ballerina](https://ballerina.io/)
- [React.js](https://reactjs.org/)
- [FastAPI](https://fastapi.tiangolo.com/)
- [scikit-learn](https://scikit-learn.org/)
- [PostgreSQL](https://www.postgresql.org/)

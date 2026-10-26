# SDI 4213 Week 9 - DevSecOps Individual Exercise

This repository continues the **Help Desk / Service Request Tracker** used in Week 7. The application and Docker Compose stack are already functional. Your Week 9 task is to improve the security of the software delivery workflow.

## Week 9 focus
You will practice:
- secret and `.env` hygiene
- Dependabot configuration
- Docker image vulnerability scanning with Docker Scout
- interpreting CVE findings and recommendations
- running the application container as a non-root user
- adding automated security policy checks to GitHub Actions
- documenting security evidence with screenshots

## Baseline application
The stack contains:
- Streamlit web application
- PostgreSQL database
- Adminer database interface
- named PostgreSQL volume

## Before you begin
Copy `.env.example` to `.env` and replace the sample password with a local development password. Never commit `.env`.

Windows PowerShell:
```powershell
Copy-Item .env.example .env
```

macOS/Linux:
```bash
cp .env.example .env
```

## Run tests
```bash
python -m pytest -v
```

## Start the application
```bash
docker compose up -d --build
docker compose ps
```

Web app: http://localhost:8501
Adminer: http://localhost:8080

## Assignment
Follow `docs/Week9_Individual_Exercise.docx`.

## Important
Never put a real password, token, cloud credential, SSH key, or API key into this repository or into your screenshot evidence.

FROM python:3.13-slim

# Dedicated, unprivileged account for the application. A fixed UID makes the
# runtime user predictable (CI checks it is not 0). --create-home gives
# Streamlit a writable home for its ~/.streamlit config and cache.
RUN useradd --create-home --uid 10001 --shell /usr/sbin/nologin appuser

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Code stays owned by root: appuser can read and run it but not change it.
COPY app ./app

# Without DATABASE_HOST the app falls back to SQLite and creates helpdesk.db
# in the working directory, so appuser needs write access to /app itself
# (the directory only, not the code inside it).
RUN chown appuser:appuser /app

EXPOSE 8501

# Everything above ran as root at build time; the application runs as appuser.
USER appuser

CMD ["streamlit", "run", "app/main.py", "--server.address=0.0.0.0", "--server.port=8501"]

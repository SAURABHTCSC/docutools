FROM python:3.11-slim-bookworm

WORKDIR /app

RUN apt-get update && apt-get install -y ghostscript default-jre libreoffice && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

THIS IS THE NEW LINE THAT FIXES THE ERROR

ENV PYTHONPATH /app

CMD ["gunicorn", "docutools.wsgi"]

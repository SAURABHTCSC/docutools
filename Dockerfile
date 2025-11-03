1. Start with a standard Python base image

FROM python:3.11-slim-bookworm

2. Set a working directory inside the container

WORKDIR /app

3. Update apt and install your system dependencies

This is the part that fixes your "Read-only" error

RUN apt-get update && apt-get install -y 

ghostscript 

default-jre 

libreoffice 

&& rm -rf /var/lib/apt/lists/*

4. Copy your requirements file

COPY requirements.txt .

5. Install your Python dependencies

RUN pip install --no-cache-dir -r requirements.txt

6. Copy the rest of your application code

COPY . .

7. --- IMPORTANT! ---

I have made an educated guess for your Start Command based on your

repository name "docutools". The command is "gunicorn docutools.wsgi".

Please check your "Start Command" in your Render Settings.

If it is different, you must change the line below to match it.

For example, if your command is "python manage.py runserver":

CMD ["python", "manage.py", "runserver"]

CMD ["gunicorn", "docutools.wsgi"]

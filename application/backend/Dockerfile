FROM python:3.10-alpine
# Install system dependencies for psycopg2 & Flask
RUN apk add --no-cache gcc musl-dev libpq-dev
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python3", "app.py"]

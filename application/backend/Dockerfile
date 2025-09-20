FROM python:3.10-alpine

RUN apk add --no-cache gcc musl-dev libpq-dev

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN chown -R appuser:appgroup /app

USER appuser

# Run the application
CMD ["python3", "app.py"]
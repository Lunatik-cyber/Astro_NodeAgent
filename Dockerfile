FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

RUN apt-get update \
    && apt-get install -y wget gzip curl\
    && wget https://github.com/ginuerzh/gost/releases/download/v2.11.1/gost-linux-amd64-2.11.1.gz \
    && gzip -d gost-linux-amd64-2.11.1.gz \
    && mv gost-linux-amd64-2.11.1 /usr/local/bin/gost \
    && chmod +x /usr/local/bin/gost \
    && rm -rf /var/lib/apt/lists/*

COPY . .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
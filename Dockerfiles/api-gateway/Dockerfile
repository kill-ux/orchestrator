FROM alpine:3.18

WORKDIR /app

RUN apk add --no-cache python3 py3-pip

RUN mkdir -p /app/logs

COPY ./requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENTRYPOINT gunicorn --workers=4 \
                    --bind=0.0.0.0:$APIGATEWAY_PORT \
                    --access-logfile=/app/logs/access.log \
                    --error-logfile=- \
                    server:app
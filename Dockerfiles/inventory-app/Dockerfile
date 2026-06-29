FROM alpine:3.18

WORKDIR /app

RUN apk add --no-cache python3 py3-pip

COPY ./requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENTRYPOINT gunicorn --workers=4 \
                    --bind=0.0.0.0:$INVENTORY_APP_PORT \
                    --access-logfile=- \
                    --error-logfile=- \
                    server:app




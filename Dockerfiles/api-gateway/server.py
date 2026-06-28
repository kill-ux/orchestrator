from dotenv import load_dotenv
load_dotenv()

import os

from app import create_app, get_env_variable

app = create_app()

APIGATEWAY_PORT = get_env_variable("APIGATEWAY_PORT")

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=int(APIGATEWAY_PORT))
    
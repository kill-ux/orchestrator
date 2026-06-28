from dotenv import load_dotenv
load_dotenv()

from app import create_app, get_env_variable

INVENTORY_APP_PORT = get_env_variable("INVENTORY_APP_PORT")

app = create_app()

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=int(INVENTORY_APP_PORT))

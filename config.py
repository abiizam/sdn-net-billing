import os
from dotenv import load_dotenv
load_dotenv()

class Config:
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key')
    SQLALCHEMY_DATABASE_URI = 'sqlite:///sdn_net_billing.db'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    CHECK_INTERVAL = int(os.getenv('CHECK_INTERVAL_DETIK', 60))
    OFFLINE_THRESHOLD = int(os.getenv('BATAS_OFFLINE_MENIT', 60))
    MIKROTIK = {
        'host': os.getenv('MIKROTIK_HOST'),
        'port': int(os.getenv('MIKROTIK_PORT', 8728)),
        'user': os.getenv('MIKROTIK_USER'),
        'password': os.getenv('MIKROTIK_PASSWORD')
    }
    OLT = {
        'host': os.getenv('OLT_HOST'),
        'port': int(os.getenv('OLT_PORT', 23)),
        'username': os.getenv('OLT_USERNAME'),
        'password': os.getenv('OLT_PASSWORD')
    }

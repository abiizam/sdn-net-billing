from flask import Flask
from models import db, Pengguna
from werkzeug.security import generate_password_hash

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///sdn_net_billing.db'
app.config['SECRET_KEY'] = 'init-db-temp-key'
db.init_app(app)

with app.app_context():
    db.create_all()
    if not Pengguna.query.filter_by(username='admin').first():
        admin = Pengguna(
            username='admin',
            password=generate_password_hash('admin123', method='pbkdf2:sha256'),
            nama_lengkap='Administrator',
            level='admin'
        )
        db.session.add(admin)
        db.session.commit()
        print("✅ User admin dibuat — username: admin | password: admin123")
    else:
        print("✅ Database sudah siap!")

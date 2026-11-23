from flask import Flask, render_template, redirect, url_for, flash
from flask_login import LoginManager, current_user
from models import db, Pengguna
from config import Config
from auth import auth
import os

app = Flask(__name__)
app.config.from_object(Config)
db.init_app(app)

login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'auth.login'

@login_manager.user_loader
def load_user(user_id):
    return Pengguna.query.get(int(user_id))

app.register_blueprint(auth)

@app.route('/')
def index():
    if current_user.is_authenticated:
        return redirect(url_for('dashboard'))
    return redirect(url_for('auth.login'))

@app.route('/dashboard')
def dashboard():
    return render_template('dashboard.html', nama=current_user.nama_lengkap)

@app.route('/konfigurasi')
def konfigurasi():
    return render_template('konfigurasi.html')

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    print(f"🚀 Server berjalan di http://0.0.0.0:5000")
    app.run(host='0.0.0.0', port=5000, debug=False)

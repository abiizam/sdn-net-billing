#!/bin/bash
# ==========================================
#   SDN NET BILLING — Installer Otomatis
# ==========================================

set -e  # Berhenti jika ada error

echo "=========================================="
echo "   SDN NET BILLING — Sedang Menginstal"
echo "=========================================="
echo ""

# 🔑 Cek hak akses
if [ "$(id -u)" -ne 0 ]; then
    echo "[INFO] Beberapa langkah butuh hak admin..."
    SUDO="sudo"
else
    SUDO=""
fi

# 📥 Langkah 1: Update Sistem
echo "[1/7] Memperbarui sistem..."
$SUDO apt update && $SUDO apt upgrade -y

# 📦 Langkah 2: Install Dependensi Sistem
echo "[2/7] Menginstal komponen sistem..."
$SUDO apt install -y python3 python3-pip python3-venv git curl telnet net-tools sqlite3

# 📂 Langkah 3: Buat Folder Proyek
echo "[3/7] Menyiapkan folder..."
mkdir -p ~/sdn-net-billing
cd ~/sdn-net-billing

# 🌐 Langkah 4: Unduh Semua File
echo "[4/7] Mengunduh file aplikasi..."

# === BUAT SETIAP FILE SECARA OTOMATIS ===

# requirements.txt
cat > requirements.txt << 'EOF'
Flask==3.0.0
Flask-SQLAlchemy==3.1.1
Flask-Login==0.6.3
librouteros==3.2.0
python-dotenv==1.1.1
requests==2.31.0
EOF

# .env.example
cat > .env.example << 'EOF'
SECRET_KEY=ganti_dengan_kata_rahasia_sangat_aman_123
FLASK_HOST=0.0.0.0
FLASK_PORT=5000
CHECK_INTERVAL_DETIK=60
BATAS_OFFLINE_MENIT=60

MIKROTIK_HOST=192.168.88.1
MIKROTIK_PORT=8728
MIKROTIK_USER=sdnbilling
MIKROTIK_PASSWORD=password_mikrotik_kamu

OLT_HOST=192.168.1.100
OLT_PORT=23
OLT_USERNAME=admin
OLT_PASSWORD=admin
EOF

# config.py
cat > config.py << 'EOF'
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
EOF

# models.py
cat > models.py << 'EOF'
from datetime import datetime
from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin
db = SQLAlchemy()

class Pengguna(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    password = db.Column(db.String(255), nullable=False)
    nama_lengkap = db.Column(db.String(100))
    level = db.Column(db.String(20), nullable=False)
    no_hp = db.Column(db.String(20))
    aktif = db.Column(db.Boolean, default=True)
    dibuat = db.Column(db.DateTime, default=datetime.utcnow)

class Paket(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nama = db.Column(db.String(100), nullable=False)
    kecepatan = db.Column(db.Integer, nullable=False)
    harga = db.Column(db.Integer, nullable=False)
    deskripsi = db.Column(db.Text)
    dibuat = db.Column(db.DateTime, default=datetime.utcnow)

class Pelanggan(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nama = db.Column(db.String(100), nullable=False)
    alamat = db.Column(db.Text, nullable=False)
    no_hp = db.Column(db.String(20), nullable=False)
    onu_id = db.Column(db.String(50))
    onu_mac = db.Column(db.String(30))
    paket_id = db.Column(db.Integer, db.ForeignKey('paket.id'))
    pppoe_user = db.Column(db.String(100))
    ip_address = db.Column(db.String(15))
    status = db.Column(db.String(20), default='aktif')
    terakhir_online = db.Column(db.DateTime, default=datetime.utcnow)
    dibuat = db.Column(db.DateTime, default=datetime.utcnow)
    paket = db.relationship('Paket', backref='pelanggan', lazy=True)

class Tagihan(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    pelanggan_id = db.Column(db.Integer, db.ForeignKey('pelanggan.id'), nullable=False)
    bulan = db.Column(db.String(7), nullable=False)
    jumlah = db.Column(db.Integer, nullable=False)
    status = db.Column(db.String(20), default='belum_bayar')
    dibuat = db.Column(db.DateTime, default=datetime.utcnow)
    pelanggan = db.relationship('Pelanggan', backref='tagihan', lazy=True)

class Tiket(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    nomor = db.Column(db.String(20), unique=True, nullable=False)
    pelanggan_id = db.Column(db.Integer, db.ForeignKey('pelanggan.id'))
    judul = db.Column(db.String(200), nullable=False)
    deskripsi = db.Column(db.Text, nullable=False)
    status = db.Column(db.String(30), default='baru')
    dibuat = db.Column(db.DateTime, default=datetime.utcnow)
EOF

class StatusONU(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    pelanggan_id = db.Column(db.Integer, db.ForeignKey('pelanggan.id'))
    onu_id = db.Column(db.String(50))
    status = db.Column(db.String(20), nullable=False)
    dicek_pada = db.Column(db.DateTime, default=datetime.utcnow)
    pelanggan = db.relationship('Pelanggan', backref='onu_log', lazy=True)
EOF

# init_db.py
cat > init_db.py << 'EOF'
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
EOF

# app.py
cat > app.py << 'EOF'
from flask import Flask, render_template, redirect, url_for, request, flash
from flask_login import LoginManager, login_user, logout_user, login_required, current_user
from models import db, Pengguna
from config import Config
import os

app = Flask(__name__)
app.config.from_object(Config)
db.init_app(app)

login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

@login_manager.user_loader
def load_user(user_id):
    return Pengguna.query.get(int(user_id))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('dashboard'))
    if request.method == 'POST':
        user = Pengguna.query.filter_by(username=request.form.get('username')).first()
        if user and user.password == request.form.get('password'):
            login_user(user)
            return redirect(url_for('dashboard'))
        flash('Username atau password salah', 'danger')
    return "<h1>Halaman Login</h1><form method=POST>User:<input name=username><br>Pass:<input type=password name=password><br><button>Masuk</button></form>"

@app.route('/logout')
def logout():
    logout_user()
    return redirect(url_for('login'))

@app.route('/')
def index():
    if current_user.is_authenticated:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))

@app.route('/dashboard')
@login_required
def dashboard():
    return f"<h1>Selamat Datang di SDN NET BILLING</h1><p>Halo, {current_user.nama_lengkap}!</p><a href='/logout'>Keluar</a>"

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    print(f"🚀 Server berjalan di http://0.0.0.0:5000")
    app.run(host='0.0.0.0', port=5000, debug=False)
EOF

# 📂 Langkah 5: Buat Folder Template
echo "[5/7] Menyiapkan folder..."
mkdir -p templates static/css static/js

# 🐍 Langkah 6: Buat Lingkungan Virtual & Install Library
echo "[6/7] Menginstal komponen Python..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# ⚙️ Langkah 7: Siapkan Konfigurasi & Database
echo "[7/7] Menyiapkan konfigurasi..."
if [ ! -f ".env" ]; then
    cp .env.example .env
fi

python3 init_db.py

echo ""
echo "=========================================="
echo "  ✅ INSTALASI SELESAI!"
echo ""
echo "  🚀 Untuk Menjalankan:"
echo "     cd ~/sdn-net-billing"
echo "     source venv/bin/activate"
echo "     python app.py"
echo ""
echo "  🌐 Buka di browser: http://$(hostname -I | awk '{print $1}'):5000"
echo ""
echo "  🔑 Login Awal:"
echo "     Username: admin"
echo "     Password: admin123"
echo ""
echo "  ⚠️ Ubah password setelah login pertama!"
echo "=========================================="
EOF

chmod +x install.sh
echo "✅ File install.sh siap. Jalankan dengan: ./install.sh"

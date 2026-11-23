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

class StatusONU(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    pelanggan_id = db.Column(db.Integer, db.ForeignKey('pelanggan.id'))
    onu_id = db.Column(db.String(50))
    status = db.Column(db.String(20), nullable=False)
    dicek_pada = db.Column(db.DateTime, default=datetime.utcnow)
    pelanggan = db.relationship('Pelanggan', backref='onu_log', lazy=True)

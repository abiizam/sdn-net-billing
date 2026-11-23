from datetime import datetime
from models import db, Tiket
import random

def buat_nomor_tiket():
    return f"TK{datetime.now().strftime('%Y%m%d')}{random.randint(1000,9999)}"

def buat_tiket(pelanggan_id, judul, deskripsi):
    nomor = buat_nomor_tiket()
    tiket = Tiket(
        nomor=nomor,
        pelanggan_id=pelanggan_id,
        judul=judul,
        deskripsi=deskripsi,
        status='baru'
    )
    db.session.add(tiket)
    db.session.commit()
    return tiket

def ubah_status_tiket(tiket_id, status_baru):
    tiket = Tiket.query.get(tiket_id)
    if tiket:
        tiket.status = status_baru
        db.session.commit()
        return True
    return False

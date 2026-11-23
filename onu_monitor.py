import time
from datetime import datetime
from models import db, Pelanggan, StatusONU

def cek_status_onu(olt):
    hasil = olt.send_command("show onu info")
    if not hasil: return

    for pel in Pelanggan.query.all():
        if pel.onu_id and pel.onu_id in hasil:
            pel.terakhir_online = datetime.utcnow()
            status = StatusONU(
                pelanggan_id=pel.id,
                onu_id=pel.onu_id,
                status='online'
            )
            db.session.add(status)
    db.session.commit()

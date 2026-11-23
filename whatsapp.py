import requests

def kirim_pesan(nomor_hp, pesan, api_url=None):
    if not api_url:
        print(f"[SIMULASI] Kirim ke {nomor_hp}: {pesan}")
        return True
    try:
        data = {'number': nomor_hp, 'message': pesan}
        requests.post(api_url, data=data, timeout=10)
        return True
    except:
        return False

def kirim_notif_tagihan(nomor_hp, nama_pelanggan, bulan, jumlah):
    pesan = f"Halo {nama_pelanggan},\nTagihan internet bulan {bulan} sebesar Rp{jumlah:,} sudah siap pembayarannya. Terima kasih!"
    return kirim_pesan(nomor_hp, pesan)

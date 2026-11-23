import telnetlib
import time

class OLTConnector:
    def __init__(self, host, port, username, password):
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.tn = None

    def connect(self):
        try:
            self.tn = telnetlib.Telnet(self.host, self.port, timeout=10)
            self.tn.read_until(b"name:", timeout=5)
            self.tn.write(self.username.encode('ascii') + b"\n")
            self.tn.read_until(b"word:", timeout=5)
            self.tn.write(self.password.encode('ascii') + b"\n")
            time.sleep(1)
            return True, "Terhubung ke OLT"
        except Exception as e:
            return False, str(e)

    def send_command(self, cmd):
        if not self.tn: return None
        try:
            self.tn.write(cmd.encode('ascii') + b"\n")
            time.sleep(0.5)
            return self.tn.read_very_eager().decode('utf-8', errors='ignore')
        except:
            return None

import librouteros

class MikroTikAPI:
    def __init__(self, host, port, user, password):
        self.host = host
        self.port = port
        self.user = user
        self.password = password
        self.conn = None

    def connect(self):
        try:
            self.conn = librouteros.connect(
                username=self.user,
                password=self.password,
                host=self.host,
                port=self.port
            )
            return True, "Terhubung"
        except Exception as e:
            return False, str(e)

    def get_pppoe_active(self):
        if not self.conn: return []
        return list(self.conn.path('/ppp/active'))

    def get_pppoe_secret(self):
        if not self.conn: return []
        return list(self.conn.path('/ppp/secret'))

    def disable_secret(self, name):
        if not self.conn: return False
        try:
            secret = self.conn.path('/ppp/secret').get(name=name)
            self.conn.path('/ppp/secret').update(secret['.id'], disabled='yes')
            return True
        except:
            return False

    def enable_secret(self, name):
        if not self.conn: return False
        try:
            secret = self.conn.path('/ppp/secret').get(name=name)
            self.conn.path('/ppp/secret').update(secret['.id'], disabled='no')
            return True
        except:
            return False

import cloudblaze.blazeweb.models as models
import simplejson
from werkzeug import generate_password_hash, check_password_hash

def new_user(client, email, password, docs=None):
    key = User.modelkey(email)
    with client.pipeline() as pipe:
        pipe.watch(key)
        pipe.multi()
        if client.exists(key):
            raise models.UnauthorizedException
        passhash = generate_password_hash(password, method='sha256')
        user = User(email, passhash, docs=docs)
        user.save(pipe)
        pipe.execute()
        return user

def auth_user(client, email, password):
    user = User.load(client, email)
    if user is None:
        raise models.UnauthorizedException        
    if check_password_hash(user.passhash, password):
        return user
    else:
        raise models.UnauthorizedException
    
class User(models.ServerModel):
    idfield = 'email'
    typename = 'user'
    #we're using email as the id for now...
    def __init__(self, email, passhash, docs=None):
        self.email = email
        self.passhash = passhash
        if docs is None:
            docs = []
        self.docs = docs

    def to_json(self):
        return {'email' : self.email,
                'passhash' : self.passhash,
                'docs' : self.docs}
    
    @staticmethod
    def from_json(obj):
        return User(obj['email'], obj['passhash'], obj['docs'])
        
    
def get_current_user(app, session):
    current_user = None
    if 'username' in session:
        current_user = User.load(app.model_redis, session['username'])
    if current_user is None:
        if app.desktopmode:
            current_user = maincontroller.ensure_default_user(app)
    return current_user
        
        

from app import data
data.init_db()
from app import importer
importer.import_posts('/home/website/posts')

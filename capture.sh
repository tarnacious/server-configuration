ssh pi@192.168.0.161 -C "fswebcam image.jpg"
scp pi@192.168.0.161:image.jpg image.jpg
eog image.jpg

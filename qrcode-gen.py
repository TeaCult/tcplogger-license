import qrcode,os,sys
import requests


# Create qr code instance
qr = qrcode.QRCode(
    version=1,
    error_correction=qrcode.constants.ERROR_CORRECT_L,
    box_size=10,
    border=4,
)

# The data you want to store
data = os.popen('python3 checkids.py').read().split('longuuid=')[1].split('\n')[0]

# Add data
qr.add_data(data)
qr.make(fit=True)


# Create an image from the QR Code instance
img = qr.make_image(fill='black', back_color='white')

# Save it somewhere, change the extension as needed
imgname=sys.argv[1].replace(':','')+".png"
img.save(imgname)

url = 'http://192.168.5.26:5000/upload'  # Change to your Flask server URL
files = {'file': open(imgname, 'rb')}
data = {sys.argv[1]: data}  # Additional data if needed

response = requests.post(url, files=files, data=data)
print(response.text)

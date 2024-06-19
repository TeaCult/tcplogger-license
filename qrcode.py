import qrcode,os

# Create qr code instance
qr = qrcode.QRCode(
    version=1,
    error_correction=qrcode.constants.ERROR_CORRECT_L,
    box_size=10,
    border=4,
)

# The data you want to store
data = "https://www.example.com"

# Add data
qr.add_data(data)
qr.make(fit=True)
#os.popen('python3 checkids.py').read().split('License :')

# Create an image from the QR Code instance
img = qr.make_image(fill='black', back_color='white')

# Save it somewhere, change the extension as needed
img.save("example_qr.png")

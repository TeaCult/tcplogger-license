import qrcode,os,sys

# Create qr code instance
qr = qrcode.QRCode(
    version=1,
    error_correction=qrcode.constants.ERROR_CORRECT_L,
    box_size=10,
    border=4,
)

# The data you want to store
data = os.popen('python3 checkids.py').read().split('longuuid:')[1].split('\n')[0]

# Add data
qr.add_data(data)
qr.make(fit=True)


# Create an image from the QR Code instance
img = qr.make_image(fill='black', back_color='white')

# Save it somewhere, change the extension as needed
img.save(sys.argv[1].replace(':','')+".png")

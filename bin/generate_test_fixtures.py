import os
from PIL import Image, ImageDraw, ImageFont

os.makedirs('fixtures', exist_ok=True)
os.makedirs('assets/samples', exist_ok=True)

def create_portrait(path):
    img = Image.new('RGB', (640, 640), color=(220, 235, 245))
    draw = ImageDraw.Draw(img)
    # Background garden/bokeh
    draw.ellipse([40, 40, 200, 200], fill=(200, 230, 220))
    draw.ellipse([450, 80, 600, 230], fill=(210, 225, 240))
    # Shoulders / Torso
    draw.ellipse([140, 420, 500, 780], fill=(50, 75, 110))
    # Neck
    draw.rectangle([280, 360, 360, 450], fill=(235, 195, 170))
    # Head / Face
    draw.ellipse([230, 160, 410, 390], fill=(245, 205, 180))
    # Hair
    draw.chord([220, 130, 420, 310], 180, 360, fill=(60, 40, 30))
    # Eyes
    draw.ellipse([270, 250, 295, 270], fill=(255, 255, 255))
    draw.ellipse([280, 255, 292, 267], fill=(40, 60, 80))
    draw.ellipse([345, 250, 370, 270], fill=(255, 255, 255))
    draw.ellipse([348, 255, 360, 267], fill=(40, 60, 80))
    # Nose
    draw.line([(320, 275), (320, 310), (330, 315)], fill=(200, 160, 140), width=3)
    # Smile
    draw.arc([290, 315, 350, 350], 20, 160, fill=(180, 80, 80), width=3)
    img.save(path)
    print(f"Created portrait: {path}")

def create_badge(path):
    img = Image.new('RGB', (600, 800), color=(240, 240, 245))
    draw = ImageDraw.Draw(img)
    # Lanyard
    draw.rectangle([280, 0, 320, 100], fill=(30, 90, 200))
    # Card body
    draw.rounded_rectangle([80, 100, 520, 750], radius=20, fill=(255, 255, 255), outline=(180, 180, 200), width=3)
    # Header
    draw.rectangle([80, 100, 520, 220], fill=(20, 50, 120))
    draw.text((120, 140), "GLOBAL ENTERPRISE CORP", fill=(255, 255, 255))
    draw.text((120, 175), "SECURITY ACCESS BADGE", fill=(100, 200, 255))
    # Photo placeholder
    draw.rectangle([140, 260, 320, 480], fill=(200, 215, 230), outline=(150, 150, 150), width=2)
    draw.ellipse([190, 300, 270, 380], fill=(240, 200, 180))
    draw.text((340, 280), "NAME:\nAlex Vance\n\nROLE:\nSenior SRE\n\nID NO:\nEMP-88391-Z\n\nTIER:\nLevel 4 Restricted", fill=(30, 30, 30))
    # Barcode
    for x in range(120, 480, 8):
        w = 3 if (x % 16 == 0) else 5
        draw.rectangle([x, 580, x + w, 680], fill=(0, 0, 0))
    img.save(path)
    print(f"Created badge: {path}")

def create_passport(path):
    img = Image.new('RGB', (800, 600), color=(230, 230, 230))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle([40, 40, 760, 560], radius=16, fill=(255, 255, 250), outline=(150, 150, 160), width=3)
    draw.text((80, 70), "PASSPORT / PASSEPORT", fill=(20, 40, 100))
    draw.text((80, 100), "REPUBLIC OF ZENITH", fill=(40, 60, 120))
    # Photo box
    draw.rectangle([80, 140, 260, 360], fill=(210, 220, 230), outline=(100, 100, 100))
    draw.text((300, 140), "SURNAME: DOE\nGIVEN NAMES: JOHN EDWARD\nNATIONALITY: ZENITHIAN\nDATE OF BIRTH: 14 MAY 1988\nPASSPORT NO: P<USA987654321\nEXPIRY DATE: 22 OCT 2032", fill=(20, 20, 20))
    # MRZ Machine Readable Zone
    draw.rectangle([60, 420, 740, 520], fill=(245, 245, 240))
    draw.text((80, 435), "P<ZENITH<<DOE<<JOHN<EDWARD<<<<<<<<<<<<<<<<<<", fill=(10, 10, 10))
    draw.text((80, 475), "P<USA9876543216ZEN8805142M3210228<<<<<<<<<<02", fill=(10, 10, 10))
    img.save(path)
    print(f"Created passport: {path}")

def create_license_plate(path):
    img = Image.new('RGB', (700, 400), color=(40, 45, 50))
    draw = ImageDraw.Draw(img)
    # Bumper
    draw.rectangle([50, 100, 650, 320], fill=(70, 75, 80))
    # License plate
    draw.rounded_rectangle([140, 130, 560, 290], radius=10, fill=(255, 255, 255), outline=(30, 30, 30), width=4)
    draw.text((300, 145), "CALIFORNIA", fill=(200, 30, 30))
    draw.text((220, 190), "7 X Y Z 8 9 0", fill=(10, 20, 80))
    draw.text((200, 255), "dmv.ca.gov", fill=(120, 120, 120))
    img.save(path)
    print(f"Created license plate: {path}")

def create_business_card(path):
    img = Image.new('RGB', (650, 400), color=(245, 245, 245))
    draw = ImageDraw.Draw(img)
    draw.rectangle([50, 50, 600, 350], fill=(255, 255, 255), outline=(200, 200, 210), width=2)
    draw.rectangle([50, 50, 600, 90], fill=(40, 50, 90))
    draw.text((70, 60), "ZENITH HEALTH INNOVATIONS", fill=(255, 255, 255))
    draw.text((80, 130), "Dr. Robert Smith, MD\nDirector of Clinical Operations\n\nDirect Phone: +1-555-0199\nPrivate Email: robert.smith@private-clinic.org\nOffice: 1044 Medical Center Blvd, Suite 400", fill=(30, 30, 30))
    img.save(path)
    print(f"Created business card: {path}")

def create_wifi_qr(path):
    img = Image.new('RGB', (500, 600), color=(240, 245, 250))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle([50, 40, 450, 560], radius=14, fill=(255, 255, 255), outline=(190, 200, 215), width=3)
    draw.text((120, 70), "GUEST WI-FI ACCESS", fill=(20, 40, 100))
    draw.text((120, 100), "Scan to connect automatically", fill=(100, 100, 100))
    # Simulated QR Pattern
    for r in range(14):
        for c in range(14):
            if (r + c) % 2 == 0 or (r in (0, 1, 12, 13) and c in (0, 1, 12, 13)):
                draw.rectangle([110 + c*20, 140 + r*20, 126 + c*20, 156 + r*20], fill=(10, 10, 10))
    draw.text((100, 450), "SSID: Zenith_Corp_Guest\nKEY: WPA2-SecretCorp#2026", fill=(40, 40, 40))
    img.save(path)
    print(f"Created wifi qr: {path}")

def create_bank_statement(path):
    img = Image.new('RGB', (650, 800), color=(235, 235, 235))
    draw = ImageDraw.Draw(img)
    draw.rectangle([50, 40, 600, 760], fill=(255, 255, 255), outline=(180, 180, 190), width=2)
    draw.text((80, 70), "ZENITH FEDERAL FINANCIAL", fill=(10, 50, 120))
    draw.text((80, 95), "MONTHLY ACCOUNT STATEMENT", fill=(80, 80, 80))
    draw.line([(80, 130), (570, 130)], fill=(200, 200, 200), width=1)
    draw.text((80, 150), "Primary Account Holder: John E. Doe\nAccount Number: 4091-8821-9902\nRouting Number: 122000496\nStatement Period: Sep 01 - Sep 30, 2026\n\nOpening Balance: $12,410.50\nTotal Deposits: +$4,500.00\nTotal Withdrawals: -$2,660.50\nEnding Balance: $14,250.00", fill=(30, 30, 30))
    img.save(path)
    print(f"Created bank statement: {path}")

def create_sticky_password(path):
    img = Image.new('RGB', (600, 500), color=(60, 65, 75))
    draw = ImageDraw.Draw(img)
    # Monitor bezel
    draw.rectangle([40, 40, 560, 460], fill=(25, 30, 35))
    draw.rectangle([70, 70, 530, 400], fill=(10, 15, 20))
    # Post-it note
    draw.rectangle([300, 200, 500, 380], fill=(255, 250, 140))
    draw.text((320, 230), "VPN LOGIN:\nUser: admin\nPwd: CorrectHorseBattery#9\nPIN: 4920", fill=(20, 20, 20))
    img.save(path)
    print(f"Created sticky password: {path}")

def create_compound_driveway(path):
    img = Image.new('RGB', (700, 500), color=(140, 180, 210))
    draw = ImageDraw.Draw(img)
    # House
    draw.rectangle([100, 100, 500, 400], fill=(210, 190, 160))
    draw.polygon([(80, 100), (300, 20), (520, 100)], fill=(120, 50, 40))
    # House placard
    draw.rectangle([340, 180, 420, 220], fill=(20, 20, 20))
    draw.text((350, 190), "742", fill=(255, 255, 255))
    draw.text((345, 225), "Evergreen Terr.", fill=(20, 20, 20))
    # Driveway vehicle
    draw.rectangle([150, 340, 450, 480], fill=(50, 60, 90))
    draw.rectangle([220, 420, 380, 460], fill=(255, 255, 255))
    draw.text((250, 430), "7XYZ890", fill=(10, 10, 10))
    # Mailbox with lanyard
    draw.rectangle([540, 280, 580, 450], fill=(100, 100, 100))
    draw.rectangle([530, 230, 590, 280], fill=(180, 180, 180))
    draw.rectangle([550, 270, 575, 320], fill=(20, 80, 200))
    img.save(path)
    print(f"Created compound scene: {path}")

def create_partially_blurred(path):
    img = Image.new('RGB', (600, 380), color=(220, 225, 235))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle([50, 40, 550, 340], radius=16, fill=(30, 50, 110), outline=(100, 120, 180), width=2)
    draw.text((80, 70), "ZENITH PLATINUM CARD", fill=(240, 240, 255))
    # First 12 digits visible, last 4 masked
    draw.text((80, 180), "4111  2222  3333  ••••", fill=(255, 255, 255))
    draw.text((80, 240), "VALID THRU: 12/29\nCARDHOLDER: J DOE", fill=(200, 210, 240))
    img.save(path)
    print(f"Created partially blurred card: {path}")

def create_low_quality(path):
    img = Image.new('RGB', (320, 240), color=(120, 125, 120))
    draw = ImageDraw.Draw(img)
    # Grain / noise
    for x in range(0, 320, 10):
        for y in range(0, 240, 10):
            val = ((x * 13 + y * 17) % 80) + 80
            draw.point((x, y), fill=(val, val, val))
    draw.text((30, 100), "Fuzzy public street view", fill=(180, 180, 180))
    img.save(path, quality=20)
    print(f"Created low quality: {path}")

def create_ambiguous_digits(path):
    img = Image.new('RGB', (500, 400), color=(210, 210, 210))
    draw = ImageDraw.Draw(img)
    draw.polygon([(100, 120), (380, 90), (420, 280), (140, 310)], fill=(255, 255, 250), outline=(180, 180, 180))
    draw.text((160, 180), "Ref: ...4591...", fill=(40, 40, 40))
    draw.text((160, 220), "Date: ...2024...", fill=(100, 100, 100))
    img.save(path)
    print(f"Created ambiguous digits: {path}")

def create_movie_poster(path):
    img = Image.new('RGB', (500, 750), color=(20, 15, 35))
    draw = ImageDraw.Draw(img)
    draw.rectangle([20, 20, 480, 730], outline=(150, 100, 255), width=3)
    draw.text((80, 80), "THE MATRIX: REBOOTED", fill=(0, 255, 200))
    draw.text((80, 140), "STARRING\nKEANU REEVES AS NEO\nLAURENCE FISHBURNE AS MORPHEUS", fill=(200, 200, 230))
    draw.text((80, 600), "IN THEATERS NOVEMBER 2026\nWARNER BROS PICTURES PROP", fill=(150, 150, 180))
    img.save(path)
    print(f"Created movie poster: {path}")

# Generate all
create_portrait('assets/samples/sample_ordinary_portrait.png')
create_portrait('fixtures/identity_portrait.png')
create_badge('fixtures/corporate_badge.png')
create_passport('fixtures/passport_mrz.png')
create_license_plate('fixtures/license_plate.png')
create_business_card('fixtures/business_card_contact.png')
create_wifi_qr('fixtures/wifi_qr_code.png')
create_bank_statement('fixtures/bank_statement.png')
create_sticky_password('fixtures/sticky_password.png')
create_portrait('fixtures/exif_gps_image.jpg') # JPG format
create_compound_driveway('fixtures/compound_driveway_scene.png')
create_partially_blurred('fixtures/partially_blurred_card.png')
create_low_quality('fixtures/low_quality_grain.jpg')
create_ambiguous_digits('fixtures/ambiguous_digits.png')
create_movie_poster('fixtures/movie_poster_prop.png')

print("All fixtures generated successfully!")

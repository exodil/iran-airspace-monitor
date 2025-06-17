# AdSense Configuration
# Bu dosyayı düzenleyerek AdMob/AdSense bilgilerinizi güncelleyin

# AdSense Publisher ID'nizi buraya girin (AdMob Console'dan alın)
ADSENSE_CLIENT_ID = "ca-pub-XXXXXXXXXXXXXXXX"  # pub-xxxxxxxxxxxxxxxx formatında

# Ad Unit ID'lerini buraya girin (AdMob Console'dan her reklam alanı için ayrı ID)
ADSENSE_SLOT_TOP = "XXXXXXXXXX"        # Üst banner reklamı
ADSENSE_SLOT_SIDEBAR = "XXXXXXXXXX"    # Sidebar reklamı  
ADSENSE_SLOT_MAP = "XXXXXXXXXX"        # Harita altı reklamı
ADSENSE_SLOT_FOOTER = "XXXXXXXXXX"     # Footer reklamı

# Bu dosyayı düzenledikten sonra:
# 1. GitHub'a push edin
# 2. EC2'de repo'yu güncelleyin
# 3. Flask uygulamasını yeniden başlatın

# AdMob Console'dan nasıl alınır:
# 1. https://admob.google.com → hesabınıza girin
# 2. Apps → Add App → Web App
# 3. Ad Units → Create Ad Unit
# 4. Publisher ID ve Ad Unit ID'leri kopyalayın

# Örnek kullanım:
# export ADSENSE_CLIENT_ID="ca-pub-1234567890123456"
# export ADSENSE_SLOT_TOP="9876543210" 
# CombatArena.gd
extends Control

@export var kart_sahnesi: PackedScene # CardBase.tscn'yi buraya atacağız
@export var test_destesi: Array[CardData] # Inspector'dan test kartlarımızı buraya dizeceğiz

@onready var oyuncu_eli_kutusu = $OyuncuEliKutusu # Görünmez kutumuzun referansı

# Diğer script ve sahnelerin referansları
@onready var engine = CombatEngine.new()

# Oyun Biyomları (Engine ile senkronize)
enum Biom {ORMAN, SU, HAVA, CIFTLIK, SAVAN, BOS}

# --- DESTE VE EL DEĞİŞKENLERİ ---
var oyuncu_destesi: Array[CardData] = []
var bot_destesi: Array[CardData] = []

var oyuncu_eli: Array[CardData] = []
var bot_eli: Array[CardData] = []

# BURALARA YENİ EKLİYORUZ: Mezarlıklar
var oyuncu_mezarligi: Array[CardData] = []
var bot_mezarligi: Array[CardData] = []

# --- SKOR VE TUR BİLGİLERİ ---
var aktif_biom: int = Biom.BOS
var oyuncu_kalan_kart_sayisi: int = 20
var bot_kalan_kart_sayisi: int = 20

# Oyun başladığında tetiklenecek ilk fonksiyon
func _ready():
	print("Arena başladı ve oyunu_baslat fonksiyonu çağrılıyor!")
	add_child(engine) # Savaş motorunu sahneye dahil ediyoruz
	oyunu_baslat()

# Oyunun kurulum aşaması
func oyunu_baslat():
	# TEST: Oyuna başlarken test destemizi asıl destemize kopyalıyoruz
	oyuncu_destesi = test_destesi.duplicate()
	oyuncu_kalan_kart_sayisi = oyuncu_destesi.size()
	bot_kalan_kart_sayisi = bot_destesi.size()
	
	# İlk başta desteden 5 kart çekilir
	for i in range(5):
		kart_cek_oyuncu()
		kart_cek_bot()
		
	yeni_tur_baslat()
# Her turun başlangıcında çağrılan fonksiyon
func yeni_tur_baslat():
	# Tur başında 1 kart çekilir (El 5 kartı geçebilir veya azalabilir)
	kart_cek_oyuncu()
	kart_cek_bot()
	
	# 1. ZAR ATMA AŞAMASI
	zar_at()
	
	# Mobil UI Güncelleme Noktası: Oyuncuya "Kart Seç" uyarısı verilir
	print("Aktif Biyom: ", aktif_biom_adi(), " | Kartınızı seçip arenaya sürükleyin!")
	
	# Burada kod durur, oyuncunun kart seçip sahaya bırakmasını (Drag-Drop) bekler.

# 🎲 Zar atma ve biyom belirleme mekaniği
func zar_at():
	randomize()
	aktif_biom = randi() % 6 # 0 ile 5 arasında rastgele sayı (BOS dahil)
	# Mobil UI Güncelleme Noktası: Burada zar döndürme animasyonu tetiklenecek

# 🃏 Oyuncu için desteden 1 kart çeker
func kart_cek_oyuncu():
	if oyuncu_destesi.size() > 0:
		var cekilen_kart = oyuncu_destesi.pop_front()
		oyuncu_eli.append(cekilen_kart)
		oyuncu_kalan_kart_sayisi = oyuncu_destesi.size()
		
		# --- GÖRSELLEŞTİRME KISMI ---
		if kart_sahnesi != null:
			var yeni_kart_ui = kart_sahnesi.instantiate() # Kartın görselini oluştur
			oyuncu_eli_kutusu.add_child(yeni_kart_ui) # Görünmez kutunun içine at
			yeni_kart_ui.kart_kur(cekilen_kart) # Tilki vb. verileri UI'a bas
# 🤖 Bot için desteden 1 kart çeker
func kart_cek_bot():
	if bot_destesi.size() > 0:
		var cekilen_kart = bot_destesi.pop_front()
		bot_eli.append(cekilen_kart)
		bot_kalan_kart_sayisi = bot_destesi.size()

# Oyuncu elinden bir kartı seçip arenaya bıraktığında bu fonksiyon tetiklenecek
func oyuncu_kart_oynadi(secilen_kart_index: int):
	var oyuncu_kart = oyuncu_eli[secilen_kart_index]
	oyuncu_eli.remove_at(secilen_kart_index)
	
	# Botun yapay zeka hamlesini alıyoruz
	var bot_kart = bot_hamlesi_sec()
	
	# KARTLAR ARENADA: Altlı üstlü yerleşim ve savaş hesaplaması başlıyor
	savas_kapismasini_yurut(oyuncu_kart, bot_kart)

# 🤖 PvZ 2 Mantığıyla Bot Hamle Seçimi (Orta Seviye Bot Yapay Zekası)
func bot_hamlesi_sec() -> CardData:
	var secilen_index = 0
	var uyumlu_kartlar: Array[int] = []
	
	# 1. Elindeki biyom uyumlu kartları ara
	for i in range(bot_eli.size()):
		if aktif_biom in bot_eli[i].tabiatlar:
			uyumlu_kartlar.append(i)
			
	# 2. Eğer uyumlu kart varsa içlerinden rastgele birini seç (ceza yememek için)
	if uyumlu_kartlar.size() > 0:
		secilen_index = uyumlu_kartlar[randi() % uyumlu_kartlar.size()]
	else:
		# 3. Uyumlu kart yoksa, elindeki en güçsüz (feda edilecek) kartı seç
		var en_dusuk_guc = 999
		for i in range(bot_eli.size()):
			if bot_eli[i].guc < en_dusuk_guc:
				en_dusuk_guc = bot_eli[i].guc
				secilen_index = i
				
	var secilen_kart = bot_eli[secilen_index]
	bot_eli.remove_at(secilen_index)
	return secilen_kart

func savas_kapismasini_yurut(o_kart: CardData, b_kart: CardData):
	# Matematik motorunu çalıştır
	var sonuc = engine.turu_hesapla(o_kart, b_kart, aktif_biom)
	
	# --- 🧠 YENİ: ZEKA 12+ KONTROLÜ (Savaş başlamadan önce veya sonra tetiklenir) ---
	mezardan_kart_kurtar(o_kart, "oyuncu")
	mezardan_kart_kurtar(b_kart, "bot")
	
	# Hasarları destelerden düşüyoruz VE MEZARA EKLİYORUZ
	if sonuc.oyuncu_hasar > 0:
		for i in range(sonuc.oyuncu_hasar):
			if oyuncu_destesi.size() > 0: 
				var yokedilen = oyuncu_destesi.pop_back()
				oyuncu_mezarligi.append(yokedilen) # Mezara gönder
		oyuncu_kalan_kart_sayisi = oyuncu_destesi.size()
		
	if sonuc.bot_hasar > 0:
		for i in range(sonuc.bot_hasar):
			if bot_destesi.size() > 0: 
				var yokedilen = bot_destesi.pop_back()
				bot_mezarligi.append(yokedilen) # Mezara gönder
		bot_kalan_kart_sayisi = bot_destesi.size()
		
	# Tur sonunda sahaya oynanan kartlar da görevini tamamlayıp mezara gider
	oyuncu_mezarligi.append(o_kart)
	bot_mezarligi.append(b_kart)
	
	# KONTROL: Oyun bitti mi?
	if oyuncu_kalan_kart_sayisi <= 0 or bot_kalan_kart_sayisi <= 0:
		oyun_bitti_kontrol(oyuncu_kalan_kart_sayisi, bot_kalan_kart_sayisi)
	else:
		yeni_tur_baslat()

func oyun_bitti_kontrol(p_kalan, b_kalan):
	if p_kalan <= 0 and b_kalan <= 0:
		print("BERABERE!")
	elif p_kalan <= 0:
		print("KAYBETTİNİZ! Bot kazandı.")
	elif b_kalan <= 0:
		print("TEBRİKLER! Kazandınız.")

func aktif_biom_adi() -> String:
	match aktif_biom:
		Biom.ORMAN: return "Orman"
		Biom.SU: return "Su"
		Biom.HAVA: return "Hava"
		Biom.CIFTLIK: return "Çiftlik"
		Biom.SAVAN: return "Savan"
	return "Joker (Boş)"
	
# 🧠 Zeka 12+ Mezardan Kart Kurtarma Mekaniği
func mezardan_kart_kurtar(kart: CardData, sahip: String):
	if kart.zeka >= 12:
		if sahip == "oyuncu" and oyuncu_mezarligi.size() > 0:
			# Mezarlıktan en son düşen kartı al
			var kurtarilan_kart = oyuncu_mezarligi.pop_back()
			# Destenin en altına (başlangıcına) ekle
			oyuncu_destesi.push_front(kurtarilan_kart)
			oyuncu_kalan_kart_sayisi = oyuncu_destesi.size()
			print("🌟 ", kart.kart_adi, " (Zeka: ", kart.zeka, ") zekasıyla mezardan ", kurtarilan_kart.kart_adi, " kartını desteye geri döndürdü!")
			
		elif sahip == "bot" and bot_mezarligi.size() > 0:
			var kurtarilan_kart = bot_mezarligi.pop_back()
			bot_destesi.push_front(kurtarilan_kart)
			bot_kalan_kart_sayisi = bot_destesi.size()
			print("🌟 Botun ", kart.kart_adi, " kartı zekasıyla mezardan bir kart kurtardı!")
func _can_drop_data(_at_position, data):
	# Sürüklenen şey bir CardData ise bırakmaya izin ver
	return data is CardData

func _drop_data(_at_position, data):
	# Kart arenaya bırakıldığında ne olacağını buraya yazacağız
	print(data.kart_adi, " arenaya bırakıldı!")
	
	# Buraya, bırakılan kartı görselleştirecek bir fonksiyon çağıracağız:
	# arenaya_kart_ekle(data)

# CombatEngine.gd
extends Node
class_name CombatEngine

# Zar biyomlarını ana koda uyumlu enum olarak tanımlıyoruz
enum Biom {ORMAN, SU, HAVA, CIFTLIK, SAVAN, BOS}

# Savaşın tüm aşamalarını sırayla çalıştıran ana fonksiyon
func turu_hesapla(oyuncu_kart: CardData, bot_kart: CardData, aktif_biom: int) -> Dictionary:
	# Kartların orijinal verilerini bozmamak için oyun içi geçici kopyalarını (Dictionary) oluşturuyoruz
	# Çünkü kartlar tur sonunda mezara gidiyor, statları anlık değişmeli.
	var p_stats = _kart_statlarini_hazirla(oyuncu_kart)
	var b_stats = _kart_statlarini_hazirla(bot_kart)
	
	# Savaş raporunu arayüze (UI) aktarmak için bir sözlük hazırlıyoruz
	var rapor = {
		"oyuncu_debuff": false,
		"bot_debuff": false,
		"zeka_buff_alan": "", # "oyuncu", "bot" veya "yok"
		"zeka_farki": 0,
		"zeka_etki_edilen_stat": "",
		"hiz_farki": 0,
		"yavas_kilitlendi": false,
		"oyuncu_hasar": 0, # Oyuncunun destesinden gidecek kart sayısı
		"bot_hasar": 0     # Botun destesinden gidecek kart sayısı
	}
	
	# --- 1. BIYOM DEBUFF KONTROLÜ ---
	rapor.oyuncu_debuff = _debuff_uygula(p_stats, oyuncu_kart.tabiatlar, aktif_biom)
	rapor.bot_debuff = _debuff_uygula(b_stats, bot_kart.tabiatlar, aktif_biom)
	
	# --- 2. ZEKA BUFFI UYGULAMA ---
	if p_stats.zeka != b_stats.zeka:
		var zeki = p_stats if p_stats.zeka > b_stats.zeka else b_stats
		var aptal = b_stats if p_stats.zeka > b_stats.zeka else p_stats
		var zeka_farki = zeki.zeka - aptal.zeka
		
		rapor.zeka_farki = zeka_farki
		rapor.zeka_buff_alan = "oyuncu" if p_stats.zeka > b_stats.zeka else "bot"
		
		# En düşük statı bul
		var en_dusuk_stat = "hiz"
		var min_deger = zeki.hiz
		if zeki.saldiri < min_deger:
			min_deger = zeki.saldiri
			en_dusuk_stat = "saldiri"
		if zeki.savunma < min_deger:
			min_deger = zeki.savunma
			en_dusuk_stat = "savunma"
			
		# Farkı en düşük stata ekle
		zeki[en_dusuk_stat] += zeka_farki
		rapor.zeka_etki_edilen_stat = en_dusuk_stat

	# --- 3. HIZ KARŞILAŞTIRMASI VE DEBUFF'LAR ---
	var hiz_farki = abs(p_stats.hiz - b_stats.hiz)
	rapor.hiz_farki = hiz_farki
	
	var oyuncu_vurabilir = true
	var bot_vurabilir = true
	
	if hiz_farki > 0:
		var yavas_olan = p_stats if p_stats.hiz < b_stats.hiz else b_stats
		var yavas_sahibi = "oyuncu" if p_stats.hiz < b_stats.hiz else "bot"
		
		if hiz_farki >= 1 and hiz_farki <= 3:
			yavas_olan.saldiri = max(0, yavas_olan.saldiri - 2)
		elif hiz_farki >= 4 and hiz_farki <= 8:
			yavas_olan.saldiri = max(0, yavas_olan.saldiri - 2)
			yavas_olan.savunma = max(0, yavas_olan.savunma - 2)
		elif hiz_farki > 8:
			yavas_olan.savunma = max(0, yavas_olan.savunma - 3)
			rapor.yavas_kilitlendi = true
			if yavas_sahibi == "oyuncu": oyuncu_vurabilir = false
			else: bot_vurabilir = false

	# --- 4. HASAR HESAPLAMA (DESTE EKSİLTME) ---
	# Durum A: Hızlar eşitse aynı anda vururlar
	if hiz_farki == 0:
		rapor.bot_hasar = _atak_hasari_hesapla(p_stats, b_stats)   # Oyuncu bota vurur
		rapor.oyuncu_hasar = _atak_hasari_hesapla(b_stats, p_stats) # Bot oyuncuya vurur
	else:
		# Durum B: Hızlar farklıysa önce hızlı olan vurur
		if p_stats.hiz > b_stats.hiz:
			rapor.bot_hasar = _atak_hasari_hesapla(p_stats, b_stats)
			if bot_vurabilir:
				rapor.oyuncu_hasar = _atak_hasari_hesapla(b_stats, p_stats)
		else:
			rapor.oyuncu_hasar = _atak_hasari_hesapla(b_stats, p_stats)
			if oyuncu_vurabilir:
				rapor.bot_hasar = _atak_hasari_hesapla(p_stats, b_stats)
				
	return rapor

# Yardımcı Fonksiyon: Kart verilerini işlenebilir Dictionary'e çevirir
func _kart_statlarini_hazirla(kart: CardData) -> Dictionary:
	return {
		"ad": kart.kart_adi, "hiz": kart.hiz, 
		"saldiri": kart.saldiri, "savunma": kart.savunma, "zeka": kart.zeka
	}

# Yardımcı Fonksiyon: Biyom uyumunu denetler ve debuff uygular
func _debuff_uygula(stats: Dictionary, tabiat_listesi: Array, aktif_biom: int) -> bool:
	if aktif_biom == Biom.BOS: return false # Joker biyomda ceza yok
	
	# Kartın tabiat dizisinde aktif biyom kodu var mı? (Enum değerleri eşleşiyor)
	if aktif_biom in tabiat_listesi:
		return false # Uyumlu, debuff yok
		
	# Eğer kart o biyoma ait değilse debuff uygulanır
	match aktif_biom:
		Biom.SAVAN: stats.saldiri = max(0, stats.saldiri - 2)
		Biom.HAVA: stats.savunma = max(0, stats.savunma - 2)
		Biom.ORMAN, Biom.SU: stats.hiz = max(0, stats.hiz - 2)
		Biom.CIFTLIK: stats.zeka = max(0, stats.zeka - 2)
	return true # Debuff yedi

# Yardımcı Fonksiyon: Saldırı - Savunma farkına göre deste hasarını bulur (1-3, 4-8, 8+)
func _atak_hasari_hesapla(saldiran: Dictionary, savunan: Dictionary) -> int:
	var fark = saldiran.saldiri - savunan.savunma
	if fark <= 0: return 0 # Saldırı boşa çıktı
	
	if fark >= 1 and fark <= 3: return 1
	if fark >= 4 and fark <= 8: return 2
	return 3 # 8+ fark durumu

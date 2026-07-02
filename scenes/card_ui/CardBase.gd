extends Control

@export var kart_verisi: CardData

# --- UI Referansları ---
@onready var kart_gorseli = $KartGorseli
@onready var guc_sayisi = $GucSayisi
@onready var hiz_sayisi = $HizSayisi
@onready var saldiri_sayisi = $SaldiriSayisi
@onready var savunma_sayisi = $SavunmaSayisi
@onready var zeka_sayisi = $ZekaSayisi

func _ready():
	if kart_verisi != null:
		kart_kur(kart_verisi)

func kart_kur(veri: CardData):
	kart_verisi = veri
	
	# ÇÖZÜM 1: Düğüm tamamen hazır olana kadar bekle (is_inside_tree yerine is_node_ready kullandık)
	if not is_node_ready():
		await ready
		
	# Resim ve sayıların varlığını kontrol ederek ata
	if kart_gorseli != null and veri.gorsel != null:
		kart_gorseli.texture = veri.gorsel
		
	if guc_sayisi: guc_sayisi.text = str(veri.guc)
	if hiz_sayisi: hiz_sayisi.text = str(veri.hiz)
	if saldiri_sayisi: saldiri_sayisi.text = str(veri.saldiri)
	if savunma_sayisi: savunma_sayisi.text = str(veri.savunma)
	if zeka_sayisi: zeka_sayisi.text = str(veri.zeka)

func statlari_guncelle(yeni_hiz: int, yeni_saldiri: int, yeni_savunma: int, yeni_zeka: int):
	if hiz_sayisi:
		hiz_sayisi.text = str(yeni_hiz)
		_renk_belirle(hiz_sayisi, yeni_hiz, kart_verisi.hiz)
	if saldiri_sayisi:
		saldiri_sayisi.text = str(yeni_saldiri)
		_renk_belirle(saldiri_sayisi, yeni_saldiri, kart_verisi.saldiri)
	if savunma_sayisi:
		savunma_sayisi.text = str(yeni_savunma)
		_renk_belirle(savunma_sayisi, yeni_savunma, kart_verisi.savunma)
	if zeka_sayisi:
		zeka_sayisi.text = str(yeni_zeka)
		_renk_belirle(zeka_sayisi, yeni_zeka, kart_verisi.zeka)

func _renk_belirle(label_dugumu: Label, yeni_deger: int, orjinal_deger: int):
	if yeni_deger < orjinal_deger:
		label_dugumu.add_theme_color_override("font_color", Color.RED)
	elif yeni_deger > orjinal_deger:
		label_dugumu.add_theme_color_override("font_color", Color.GREEN)
	else:
		label_dugumu.add_theme_color_override("font_color", Color.WHITE)

func _get_drag_data(_at_position):
	if kart_verisi == null: return null
	
	var preview_kart = load("res://scenes/card_ui/CardBase.tscn").instantiate()
	var preview_kontrol = Control.new()
	
	# ÇÖZÜM 2: Sürükleme (Drag) hatasını engellemek için ÖNCE sahneye ekliyoruz, SONRA veriyi basıyoruz
	preview_kontrol.add_child(preview_kart)
	preview_kart.kart_kur(kart_verisi)
	
	preview_kart.modulate = Color(1, 1, 1, 0.7)
	preview_kart.scale = Vector2(0.8, 0.8) 
	preview_kart.position = Vector2(-80, -112)
	
	set_drag_preview(preview_kontrol)
	return kart_verisi

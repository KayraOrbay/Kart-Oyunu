extends Resource
class_name CardData

# --- KART TEMEL BİLGİLERİ ---
@export var kart_adi: String

# Nadirlik derecesi açılır menüsü
@export_enum("Yaygın", "Nadir", "Destansı", "Efsanevi") var nadirlik: String = "Yaygın"

# Önce kendi özel tabiat listemizi Godot'a tanıtıyoruz
enum Tabiat {
	ORMAN,
	SU,
	HAVA,
	CIFTLIK,
	SAVAN
}

# Sonra diyoruz ki: Bu kartın tabiatları, yukarıdaki listeden seçilsin!
@export var tabiatlar: Array[Tabiat] = []

# --- KART İSTATİSTİKLERİ ---
# Kartın sağ üst köşesinde görünen genel ortalama puan

@export var guc: int 
@export var hiz: int
@export var saldiri: int
@export var savunma: int
@export var zeka: int

# --- GÖRSEL VE METİN ---
# Kartın 2D resim dosyası
@export var gorsel: Texture2D

# Kartın alt kısmında yer alan hayvanla ilgili ilginç bilgi
@export_multiline var aciklama: String

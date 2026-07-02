extends Node
func desteyi_gecerli_mi(secilen_deste: Array) -> bool:
	var efsanevi_sayisi = 0
	var destansi_sayisi = 0
	var nadir_sayisi = 0
	
	# Destekdeki her bir kartı tek tek kontrol ediyoruz
	for kart in secilen_deste:
		if kart.nadirlik == "Efsanevi":
			efsanevi_sayisi += 1
		elif kart.nadirlik == "Destansı":
			destansi_sayisi += 1
		elif kart.nadirlik == "Nadir":
			nadir_sayisi += 1
			
	# Kurallarımızı (Limitleri) burada test ediyoruz
	if efsanevi_sayisi > 1:
		print("Hata: Destenizde en fazla 1 Efsanevi kart olabilir!")
		return false
	elif destansi_sayisi > 2:
		print("Hata: Destenizde en fazla 2 Destansı kart olabilir!")
		return false
	elif nadir_sayisi > 4:
		print("Hata: Destenizde en fazla 4 Nadir kart olabilir!")
		return false
		
	# Eğer hiçbir kural ihlal edilmediyse deste geçerlidir
	print("Deste geçerli, savaşa hazır!")
	return true

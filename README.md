# abap-p2p-approval-ai
P2P Approval Flow with AI Invoice Check

ABAP Cloud + RAP ile geliştirilmiş, satın alma (PR → PO → GR → IR) onay akışı
ve AI destekli fatura kontrolü. Karar insanda kalır, AI yalnızca öneri üretir.

## Why this project
Clean core ve ABAP Cloud yaklaşımıyla, gerçek bir P2P senaryosunu uçtan uca modelleme.

## Tech stack
ABAP Cloud · RAP (managed, draft) · CDS · Fiori Elements · SAP BTP ABAP Environment · LLM API

## Features
- [x] Proje kurulumu
- [ ] PO header/item + masraf yeri atama
- [ ] Onay akışı (approval)
- [ ] 3-way match ve tolerans kontrolü
- [ ] AI açıklama katmanı ("Fatura neden uyuşmuyor?")

## Architecture
(Diyagram buraya)

## Data model
(Tablo/CDS ilişkileri buraya)

## Screenshots / Demo
(Ekran görüntüleri ve video linki)

## How to run
1. BTP trial ABAP Environment kur
2. abapGit ile repo'yu import et
3. Service binding'i publish et

## Simplifications
Standart MM/FI tabloları yerine sadeleştirilmiş tablolar kullanıldı (trial kısıtı).
Standartta para birimi sadece EKKO’da durur. Amount alanları aynı tabloda bir currency alanına bağlı olmak zorunda olduğu için kalemde de currency tutuyoruz. Header’daki değeri determination ile kopyalayacağız.
PEINH (price unit) yok, fiyat 1 birim için kabul edilir.
Controlling area (KOKRS) yok, masraf yeri doğrudan company code’a bağlı.
net_amount = quantity × unit_price, H2'de determination ile dolacak.
ItemNo otomatik numbering için kullanılan MAX + 1 yöntemi demo içindir. Gerçek bir projede number range object kullanılır.
Onay limiti para birimi dönüşümü yapmaz (limit ve PO aynı para biriminde kabul edildi), onay seviyesi tek (çok seviyeli release yok).

## Author
Halil · SAP ABAP/Fiori Developer

--!strict
return table.freeze({
    -- Production is Mini quantity per base cycle; value is dollars per individual
    -- Mini before cash/rebirth boosts. Each rendered drop carries this quantity.
    tier_01 = table.freeze({tier = 1, name = "Tung Tung", production = 1, value = 1, nextId = "tier_02", color = {204, 142, 83}}),
    tier_02 = table.freeze({tier = 2, name = "Chimpanzini Bananini", production = 5, value = 1, nextId = "tier_03", color = {255, 222, 51}}),
    tier_03 = table.freeze({tier = 3, name = "Ballerina Cappuccina", production = 25, value = 1, nextId = "tier_04", color = {255, 150, 205}}),
    tier_04 = table.freeze({tier = 4, name = "Tralalero Tralala", production = 90, value = 1, nextId = "tier_05", color = {67, 165, 242}}),
    tier_05 = table.freeze({tier = 5, name = "Skibidi Toilet", production = 300, value = 1, nextId = "tier_06", color = {255, 236, 218}}),
    tier_06 = table.freeze({tier = 6, name = "Bombardiro Crocodilo", production = 1100, value = 1, nextId = "tier_07", color = {100, 139, 76}}),
    tier_07 = table.freeze({tier = 7, name = "Fluriflura", modelKey = "Fluriflura", production = 4000, value = 1, nextId = "tier_08", color = {133, 219, 137}}),
    tier_08 = table.freeze({tier = 8, name = "Gorillo Subwoofero", modelKey = "GorilloSubwoofero", production = 15000, value = 1, nextId = "tier_09", color = {180, 148, 242}}),
    tier_09 = table.freeze({tier = 9, name = "Lirilì Larilà", modelKey = "LiriliLarila", production = 60000, value = 1, nextId = "tier_10", color = {174, 216, 117}}),
    -- Tiers 10–25 are inferred balance values: 3.2x, rounded to 1,000 Minis.
    tier_10 = table.freeze({tier = 10, name = "Noobini Pizzanini", modelKey = "NoobiniPizzanini", production = 192000, value = 1, nextId = "tier_11", color = {255, 204, 86}}),
    tier_11 = table.freeze({tier = 11, name = "Odin Din Din Dun", modelKey = "OdinDinDinDun", production = 614000, value = 1, nextId = "tier_12", color = {143, 187, 255}}),
    tier_12 = table.freeze({tier = 12, name = "Pipi Potato", modelKey = "PipiPotato", production = 1965000, value = 1, nextId = "tier_13", color = {220, 181, 123}}),
    tier_13 = table.freeze({tier = 13, name = "Raccooni Jandelini", modelKey = "RaccooniJandelini", production = 6288000, value = 1, nextId = "tier_14", color = {190, 196, 221}}),
    tier_14 = table.freeze({tier = 14, name = "Talpa Di Fero", modelKey = "TalpaDiFero", production = 20122000, value = 1, nextId = "tier_15", color = {173, 195, 204}}),
    tier_15 = table.freeze({tier = 15, name = "Tim Cheese", modelKey = "TimCheese", production = 64390000, value = 1, nextId = "tier_16", color = {255, 218, 105}}),
    tier_16 = table.freeze({tier = 16, name = "Toiletto Focaccino", modelKey = "ToilettoFocaccino", production = 206048000, value = 1, nextId = "tier_17", color = {255, 211, 175}}),
    tier_17 = table.freeze({tier = 17, name = "Tukanno Bananno", modelKey = "TukannoBananno", production = 659354000, value = 1, nextId = "tier_18", color = {255, 177, 80}}),
    tier_18 = table.freeze({tier = 18, name = "Noobini Santanini", modelKey = "NoobiniSantanini", production = 2109933000, value = 1, nextId = "tier_19", color = {255, 132, 129}}),
    tier_19 = table.freeze({tier = 19, name = "Svinina Bombardino", modelKey = "SvininaBombardino", production = 6751786000, value = 1, nextId = "tier_20", color = {248, 164, 190}}),
    tier_20 = table.freeze({tier = 20, name = "Pipi Kiwi", modelKey = "PipiKiwi", production = 21605715000, value = 1, nextId = "tier_21", color = {184, 225, 108}}),
    tier_21 = table.freeze({tier = 21, name = "Tartaragno", modelKey = "Tartaragno", production = 69138288000, value = 1, nextId = "tier_22", color = {141, 203, 135}}),
    tier_22 = table.freeze({tier = 22, name = "Pipi Corni", modelKey = "PipiCorni", production = 221242522000, value = 1, nextId = "tier_23", color = {255, 224, 102}}),
    tier_23 = table.freeze({tier = 23, name = "Trippi Troppi", modelKey = "TrippiTroppi", production = 707976070000, value = 1, nextId = "tier_24", color = {252, 170, 151}}),
    tier_24 = table.freeze({tier = 24, name = "Gangster Footera", modelKey = "GangsterFootera", production = 2265523424000, value = 1, nextId = "tier_25", color = {190, 185, 226}}),
    tier_25 = table.freeze({tier = 25, name = "Bandito Bobritto", modelKey = "BanditoBobritto", production = 7249674957000, value = 1, color = {228, 188, 137}}),
})

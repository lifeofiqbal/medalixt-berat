-- SQL INI GA PERLU DI TAMBAHKAN SECARA MANUAL KARENA AKAN BERJALAN OTOMATIS APABILA medalixt-berat SUDAH DI CFG

CREATE TABLE player_custom_weight (
    identifier VARCHAR(60),  -- license:xxxx
    max_weight INT,           -- dalam gram
    updated_at TIMESTAMP
)

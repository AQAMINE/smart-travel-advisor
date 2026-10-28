-- V1__init_schema.sql
-- Smart Travel Advisor : schéma minimal (PostgreSQL), sans gestion d'utilisateurs

CREATE TABLE destination (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name         VARCHAR(150)     NOT NULL,
    country_code CHAR(2)          NOT NULL,
    latitude     DOUBLE PRECISION NOT NULL,
    longitude    DOUBLE PRECISION NOT NULL,
    timezone     VARCHAR(50),
    UNIQUE (name, country_code)
);

-- Lieux et activités ; setting sert à choisir selon la météo
CREATE TABLE activity (
    id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    destination_id   BIGINT       NOT NULL REFERENCES destination(id) ON DELETE CASCADE,
    name             VARCHAR(200) NOT NULL,
    description      TEXT,
    category         VARCHAR(50)  NOT NULL,
    setting          VARCHAR(10)  NOT NULL CHECK (setting IN ('OUTDOOR', 'INDOOR', 'MIXED')),
    avg_duration_min INT,
    price_level      SMALLINT CHECK (price_level BETWEEN 0 AND 4)
);
CREATE INDEX idx_activity_destination_setting ON activity (destination_id, setting);

-- Cache des prévisions OpenWeatherMap
CREATE TABLE weather_forecast (
    id                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    destination_id     BIGINT      NOT NULL REFERENCES destination(id) ON DELETE CASCADE,
    forecast_date      DATE        NOT NULL,
    temp_min           NUMERIC(4,1),
    temp_max           NUMERIC(4,1),
    condition          VARCHAR(30) NOT NULL,   -- CLEAR, CLOUDS, RAIN...
    precipitation_prob SMALLINT CHECK (precipitation_prob BETWEEN 0 AND 100),
    fetched_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (destination_id, forecast_date)
);

-- Un voyage généré par l'IA (préférences stockées en texte : "CULTURE,NATURE")
CREATE TABLE trip (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    destination_id BIGINT       NOT NULL REFERENCES destination(id),
    start_date     DATE         NOT NULL,
    end_date       DATE         NOT NULL,
    preferences    VARCHAR(255),
    ai_summary     TEXT,                        -- "Conseil IA" global
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CHECK (end_date >= start_date)
);

-- Timeline : une ligne par étape ; is_backup = true pour le "Plan B si la pluie"
CREATE TABLE itinerary_stop (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    trip_id       BIGINT       NOT NULL REFERENCES trip(id) ON DELETE CASCADE,
    activity_id   BIGINT REFERENCES activity(id) ON DELETE SET NULL,
    day_date      DATE         NOT NULL,
    start_time    TIME,
    title         VARCHAR(200) NOT NULL,
    note          VARCHAR(500),
    is_backup     BOOLEAN      NOT NULL DEFAULT FALSE,
    expected_temp NUMERIC(4,1)
);
CREATE INDEX idx_stop_trip_day ON itinerary_stop (trip_id, day_date, start_time);
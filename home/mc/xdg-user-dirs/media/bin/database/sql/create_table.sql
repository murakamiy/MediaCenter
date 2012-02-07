CREATE TABLE play (
    transport_stream_id INTEGER,
    service_id INTEGER,
    event_id INTEGER,
    series_id INTEGER DEFAULT -1,
    category_id INTEGER DEFAULT -1,
    channel TEXT,
    title TEXT,
    desc TEXT,
    category_1 TEXT,
    category_2 TEXT,
    start INTEGER,
    stop INTEGER,
    priority INTEGER,
    foundby TEXT,
    play_time_total INTEGER DEFAULT 0,
    play_time_queue INTEGER DEFAULT 0,
    length INTEGER,
    created_at INTEGER DEFAULT (strftime('%s','now')),
    updated_at INTEGER DEFAULT (strftime('%s','now')),
    PRIMARY KEY (transport_stream_id, service_id, event_id)
);

CREATE INDEX idx_play_series_id ON play (series_id);
CREATE INDEX idx_play_category_id ON play (category_id);
CREATE INDEX idx_play_play_time_queue ON play (play_time_queue);

CREATE TABLE rating_series (
    series_id INTEGER PRIMARY KEY,
    transport_stream_id INTEGER,
    service_id INTEGER,
    title TEXT,
    play_time INTEGER DEFAULT 0,
    length INTEGER DEFAULT 0,
    rating INTEGER DEFAULT 0,
    created_at INTEGER DEFAULT (strftime('%s','now')),
    updated_at INTEGER DEFAULT (strftime('%s','now'))
);

CREATE INDEX idx_rating_series_transport_stream_id_service_id 
ON rating_series (transport_stream_id, service_id);
CREATE INDEX idx_rating_series_title ON rating_series (title);

CREATE TABLE rating_category (
    category_id INTEGER PRIMARY KEY,
    category_1 TEXT,
    category_2 TEXT,
    play_time INTEGER DEFAULT 0,
    length INTEGER DEFAULT 0,
    rating INTEGER DEFAULT 0,
    created_at INTEGER DEFAULT (strftime('%s','now')),
    updated_at INTEGER DEFAULT (strftime('%s','now'))
);

CREATE UNIQUE INDEX idx_rating_category_category
ON rating_category (category_1, category_2);

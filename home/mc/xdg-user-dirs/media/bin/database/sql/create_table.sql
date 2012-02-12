CREATE TABLE programme (
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
    length INTEGER,
    created_at INTEGER DEFAULT (strftime('%s','now')),
    updated_at INTEGER DEFAULT (strftime('%s','now')),
    PRIMARY KEY (transport_stream_id, service_id, event_id)
);

CREATE INDEX idx_programme_series_id ON programme (series_id);
CREATE INDEX idx_programme_category_id ON programme (category_id);
CREATE INDEX idx_programme_title ON programme (title);


CREATE TABLE play (
    transport_stream_id INTEGER,
    service_id INTEGER,
    event_id INTEGER,
    play_time INTEGER DEFAULT 0,
    aggregate INTEGER DEFAULT 0,
    created_at INTEGER DEFAULT (strftime('%s','now')),
    updated_at INTEGER DEFAULT (strftime('%s','now'))
);

CREATE INDEX idx_play_id ON play (transport_stream_id, service_id, event_id);
CREATE INDEX idx_play_aggregate ON play (aggregate);


CREATE TABLE rating_series (
    series_id INTEGER PRIMARY KEY,
    category_id INTEGER,
    title TEXT,
    play_time INTEGER DEFAULT 0,
    length INTEGER DEFAULT 0,
    rating INTEGER DEFAULT 0,
    created_at INTEGER DEFAULT (strftime('%s','now')),
    updated_at INTEGER DEFAULT (strftime('%s','now'))
);

CREATE UNIQUE INDEX idx_rating_series_category_id_title ON rating_series (category_id, title);

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

CREATE TABLE programme (
    channel TEXT,
    start INTEGER,
    stop INTEGER,
    series_id INTEGER DEFAULT -1,
    title TEXT,
    smb_filename TEXT DEFAULT '',
    category TEXT,
    period INTEGER,
    foundby TEXT,
    created_at INTEGER DEFAULT (strftime('%s','now')),
    updated_at INTEGER DEFAULT (strftime('%s','now')),
    PRIMARY KEY (channel, start)
);

CREATE INDEX idx_programme_series_id ON programme (series_id);
CREATE INDEX idx_programme_title ON programme (title);
CREATE INDEX idx_programme_smb_filename ON programme (smb_filename);
CREATE INDEX idx_programme_channel ON programme (channel);
CREATE INDEX idx_programme_category ON programme (category);
CREATE INDEX idx_programme_start ON programme (start);
CREATE INDEX idx_programme_period ON programme (period);


CREATE TABLE play (
    channel TEXT,
    start INTEGER,
    play_time INTEGER DEFAULT 0,
    aggregate INTEGER DEFAULT 0,
    created_at INTEGER DEFAULT (strftime('%s','now')),
    updated_at INTEGER DEFAULT (strftime('%s','now'))
);

CREATE INDEX idx_play_id ON play (channel, start);
CREATE INDEX idx_play_aggregate ON play (aggregate);


CREATE TABLE series (
    series_id INTEGER PRIMARY KEY,
    keyword TEXT DEFAULT '',
    rating INTEGER DEFAULT 0,
    series_count INTEGER DEFAULT 1,
    created_at INTEGER DEFAULT (strftime('%s','now')),
    updated_at INTEGER DEFAULT (strftime('%s','now'))
);

CREATE UNIQUE INDEX idx_series_keyword ON series (keyword);
CREATE INDEX idx_series_series_count ON series (series_count);


CREATE TABLE tmp_group (
    count INTEGER,
    channel TEXT,
    category TEXT,
    period INTEGER
);


CREATE TABLE tmp_title (
    channel TEXT,
    start INTEGER,
    title_normalize TEXT
);

CREATE TABLE programme (
    channel TEXT,
    start INTEGER,
    stop INTEGER,
    series_id INTEGER DEFAULT -1,
    title TEXT,
    smb_filename TEXT DEFAULT '',
    category_id INTEGER,
    weekday INTEGER,
    period INTEGER,
    foundby TEXT,
    created_at INTEGER DEFAULT (strftime('%s','now')),
    updated_at INTEGER DEFAULT (strftime('%s','now')),
    PRIMARY KEY (channel, start)
);

CREATE INDEX idx_programme_series_id ON programme (series_id);
CREATE INDEX idx_programme_title ON programme (title);


CREATE TABLE play (
    channel TEXT,
    start INTEGER,
    play_time INTEGER DEFAULT 0,
    aggregate INTEGER DEFAULT 0,
    created_at INTEGER DEFAULT (strftime('%s','now')),
    updated_at INTEGER DEFAULT (strftime('%s','now'))
);

CREATE INDEX idx_play_id ON play (channel, start);


CREATE TABLE series (
    series_id INTEGER PRIMARY KEY,
    rating INTEGER DEFAULT 0,
    series_count INTEGER DEFAULT 0,
    keyword_length INTEGER DEFAULT 0,
    created_at INTEGER DEFAULT (strftime('%s','now')),
    updated_at INTEGER DEFAULT (strftime('%s','now'))
);


CREATE TABLE keywords (
    series_id INTEGER,
    keyword TEXT,
    created_at INTEGER DEFAULT (strftime('%s','now')),
    updated_at INTEGER DEFAULT (strftime('%s','now'))
);

CREATE INDEX idx_keywords_series_id ON keywords (series_id);
CREATE INDEX idx_keywords_keyword ON keywords (keyword);


CREATE TABLE category (
    category_id INTEGER PRIMARY KEY,
    category_list TEXT,
    created_at INTEGER DEFAULT (strftime('%s','now')),
    updated_at INTEGER DEFAULT (strftime('%s','now'))
);

CREATE UNIQUE INDEX idx_category_category_list ON category (category_list);





CREATE TABLE tmp_group (
    count INTEGER,
    channel TEXT,
    category_id INTEGER,
    weekday INTEGER,
    period INTEGER
);


CREATE TABLE tmp_title (
    channel TEXT,
    start INTEGER,
    title_normalize TEXT
);

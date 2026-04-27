-- Database Project - Part 2
-- Group: BOYER Timothe, LAINE Martin, MOURET Basile
-- Theme: Pokemon database
-- Target DBMS: SQLite 3
--
-- Note:
-- This implementation follows the relational schema from Part 1.
-- Two enforcement details are added here because they are implied by the UML
-- and integrity constraints from Part 1:
--   1. Pokemon.evolves_from is UNIQUE to preserve the 0..1 reflexive cardinality.
--   2. A trigger prevents inserting more than two types for the same Pokemon.

PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

DROP TABLE IF EXISTS CapturedPokemonTeam;
DROP TABLE IF EXISTS CapturedPokemonSpecies;
DROP TABLE IF EXISTS TrainerCapturedPokemon;
DROP TABLE IF EXISTS PokemonMove;
DROP TABLE IF EXISTS PokemonType;
DROP TABLE IF EXISTS Battle;
DROP TABLE IF EXISTS CapturedPokemon;
DROP TABLE IF EXISTS Team;
DROP TABLE IF EXISTS Trainer;
DROP TABLE IF EXISTS Move;
DROP TABLE IF EXISTS WildPokemon;
DROP TABLE IF EXISTS Pokemon;
DROP TABLE IF EXISTS Type;

CREATE TABLE Type (
    type_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE Pokemon (
    pokedex_no INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    height REAL NOT NULL CHECK (height > 0),
    weight REAL NOT NULL CHECK (weight > 0),
    evolves_from INTEGER UNIQUE,
    FOREIGN KEY (evolves_from) REFERENCES Pokemon(pokedex_no),
    CHECK (evolves_from IS NULL OR evolves_from <> pokedex_no)
);

CREATE TABLE WildPokemon (
    pokedex_no INTEGER PRIMARY KEY,
    location TEXT NOT NULL,
    level_range TEXT NOT NULL,
    FOREIGN KEY (pokedex_no) REFERENCES Pokemon(pokedex_no) ON DELETE CASCADE
);

CREATE TABLE Move (
    move_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    power INTEGER,
    accuracy INTEGER CHECK (accuracy BETWEEN 0 AND 100),
    pp INTEGER NOT NULL CHECK (pp > 0),
    category TEXT NOT NULL CHECK (category IN ('Physical', 'Special', 'Status')),
    type_id INTEGER NOT NULL,
    FOREIGN KEY (type_id) REFERENCES Type(type_id)
);

CREATE TABLE Trainer (
    trainer_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    birth_date TEXT,
    region TEXT
);

CREATE TABLE Team (
    trainer_id INTEGER NOT NULL,
    team_name TEXT NOT NULL,
    PRIMARY KEY (trainer_id, team_name),
    FOREIGN KEY (trainer_id) REFERENCES Trainer(trainer_id) ON DELETE CASCADE
);

CREATE TABLE CapturedPokemon (
    captured_id INTEGER PRIMARY KEY,
    nickname TEXT,
    level INTEGER NOT NULL CHECK (level BETWEEN 1 AND 100),
    captured_on TEXT
);

CREATE TABLE Battle (
    battle_id INTEGER PRIMARY KEY,
    battle_date TEXT NOT NULL,
    location TEXT,
    challenger_id INTEGER NOT NULL,
    opponent_id INTEGER NOT NULL,
    challenger_team TEXT,
    opponent_team TEXT,
    result TEXT NOT NULL CHECK (result IN ('challenger', 'opponent', 'draw')),
    CHECK (challenger_id <> opponent_id),
    FOREIGN KEY (challenger_id) REFERENCES Trainer(trainer_id),
    FOREIGN KEY (opponent_id) REFERENCES Trainer(trainer_id),
    FOREIGN KEY (challenger_id, challenger_team)
        REFERENCES Team(trainer_id, team_name),
    FOREIGN KEY (opponent_id, opponent_team)
        REFERENCES Team(trainer_id, team_name)
);

CREATE TABLE PokemonType (
    pokedex_no INTEGER NOT NULL,
    type_id INTEGER NOT NULL,
    PRIMARY KEY (pokedex_no, type_id),
    FOREIGN KEY (pokedex_no) REFERENCES Pokemon(pokedex_no) ON DELETE CASCADE,
    FOREIGN KEY (type_id) REFERENCES Type(type_id)
);

CREATE TABLE PokemonMove (
    pokedex_no INTEGER NOT NULL,
    move_id INTEGER NOT NULL,
    learn_method TEXT NOT NULL,
    PRIMARY KEY (pokedex_no, move_id),
    FOREIGN KEY (pokedex_no) REFERENCES Pokemon(pokedex_no) ON DELETE CASCADE,
    FOREIGN KEY (move_id) REFERENCES Move(move_id)
);

CREATE TABLE TrainerCapturedPokemon (
    trainer_id INTEGER NOT NULL,
    captured_id INTEGER NOT NULL UNIQUE,
    PRIMARY KEY (trainer_id, captured_id),
    FOREIGN KEY (trainer_id) REFERENCES Trainer(trainer_id) ON DELETE CASCADE,
    FOREIGN KEY (captured_id) REFERENCES CapturedPokemon(captured_id) ON DELETE CASCADE
);

CREATE TABLE CapturedPokemonSpecies (
    captured_id INTEGER PRIMARY KEY,
    pokedex_no INTEGER NOT NULL,
    FOREIGN KEY (captured_id) REFERENCES CapturedPokemon(captured_id) ON DELETE CASCADE,
    FOREIGN KEY (pokedex_no) REFERENCES Pokemon(pokedex_no)
);

CREATE TABLE CapturedPokemonTeam (
    captured_id INTEGER PRIMARY KEY,
    trainer_id INTEGER NOT NULL,
    team_name TEXT NOT NULL,
    position INTEGER NOT NULL CHECK (position BETWEEN 1 AND 6),
    UNIQUE (trainer_id, team_name, position),
    FOREIGN KEY (trainer_id, team_name)
        REFERENCES Team(trainer_id, team_name)
        ON DELETE CASCADE,
    FOREIGN KEY (trainer_id, captured_id)
        REFERENCES TrainerCapturedPokemon(trainer_id, captured_id)
        ON DELETE CASCADE,
    FOREIGN KEY (captured_id)
        REFERENCES CapturedPokemon(captured_id)
        ON DELETE CASCADE
);

CREATE TRIGGER pokemon_type_max_two
BEFORE INSERT ON PokemonType
FOR EACH ROW
WHEN (
    SELECT COUNT(*)
    FROM PokemonType
    WHERE pokedex_no = NEW.pokedex_no
) >= 2
BEGIN
    SELECT RAISE(ABORT, 'A Pokemon cannot have more than two types.');
END;

-- Data insertion section
INSERT INTO Type (type_id, name) VALUES
    (1, 'Fire'),
    (2, 'Water'),
    (3, 'Grass'),
    (4, 'Electric'),
    (5, 'Poison'),
    (6, 'Flying'),
    (7, 'Normal'),
    (8, 'Ghost'),
    (9, 'Dragon'),
    (10, 'Ice'),
    (11, 'Fairy'),
    (12, 'Rock'),
    (13, 'Ground');

INSERT INTO Pokemon (pokedex_no, name, height, weight, evolves_from) VALUES
    (1, 'Bulbasaur', 0.7, 6.9, NULL),
    (2, 'Ivysaur', 1.0, 13.0, 1),
    (3, 'Venusaur', 2.0, 100.0, 2),
    (4, 'Charmander', 0.6, 8.5, NULL),
    (5, 'Charmeleon', 1.1, 19.0, 4),
    (6, 'Charizard', 1.7, 90.5, 5),
    (7, 'Squirtle', 0.5, 9.0, NULL),
    (8, 'Wartortle', 1.0, 22.5, 7),
    (9, 'Blastoise', 1.6, 85.5, 8),
    (25, 'Pikachu', 0.4, 6.0, NULL),
    (39, 'Jigglypuff', 0.5, 5.5, NULL),
    (52, 'Meowth', 0.4, 4.2, NULL),
    (92, 'Gastly', 1.3, 0.1, NULL),
    (95, 'Onix', 8.8, 210.0, NULL),
    (131, 'Lapras', 2.5, 220.0, NULL),
    (133, 'Eevee', 0.3, 6.5, NULL),
    (134, 'Vaporeon', 1.0, 29.0, 133),
    (135, 'Jolteon', 0.8, 24.5, NULL),
    (149, 'Dragonite', 2.2, 210.0, NULL);

INSERT INTO WildPokemon (pokedex_no, location, level_range) VALUES
    (1, 'Viridian Forest', '5-7'),
    (4, 'Route 3', '8-10'),
    (25, 'Viridian Forest', '3-5'),
    (92, 'Pokemon Tower', '20-24'),
    (95, 'Rock Tunnel', '13-17'),
    (131, 'Seafoam Islands', '25-30');

INSERT INTO Move (move_id, name, power, accuracy, pp, category, type_id) VALUES
    (1, 'Ember', 40, 100, 25, 'Special', 1),
    (2, 'Flamethrower', 90, 100, 15, 'Special', 1),
    (3, 'Water Gun', 40, 100, 25, 'Special', 2),
    (4, 'Hydro Pump', 110, 80, 5, 'Special', 2),
    (5, 'Vine Whip', 45, 100, 25, 'Physical', 3),
    (6, 'Razor Leaf', 55, 95, 25, 'Physical', 3),
    (7, 'Thunderbolt', 90, 100, 15, 'Special', 4),
    (8, 'Quick Attack', 40, 100, 30, 'Physical', 7),
    (9, 'Shadow Ball', 80, 100, 15, 'Special', 8),
    (10, 'Surf', 90, 100, 15, 'Special', 2),
    (11, 'Tackle', 40, 100, 35, 'Physical', 7),
    (12, 'Growl', NULL, 100, 40, 'Status', 7),
    (13, 'Sing', NULL, 55, 15, 'Status', 7),
    (14, 'Ice Beam', 90, 100, 10, 'Special', 10),
    (15, 'Dragon Claw', 80, 100, 15, 'Physical', 9),
    (16, 'Earthquake', 100, 100, 10, 'Physical', 13),
    (17, 'Rock Throw', 50, 90, 15, 'Physical', 12),
    (18, 'Thunder Wave', NULL, 90, 20, 'Status', 4),
    (19, 'Sleep Powder', NULL, 75, 15, 'Status', 3),
    (20, 'Scratch', 40, 100, 35, 'Physical', 7),
    (21, 'Fly', 90, 95, 15, 'Physical', 6);

INSERT INTO Trainer (trainer_id, name, birth_date, region) VALUES
    (1, 'Red', '1996-02-27', 'Kanto'),
    (2, 'Blue', '1996-11-22', 'Kanto'),
    (3, 'Misty', '1994-06-15', 'Kanto'),
    (4, 'Brock', '1993-02-03', 'Kanto'),
    (5, 'Cynthia', '1990-04-05', 'Sinnoh');

INSERT INTO Team (trainer_id, team_name) VALUES
    (1, 'Main Squad'),
    (1, 'Rotation'),
    (2, 'League Team'),
    (3, 'Water Rush'),
    (3, 'Gym Defense'),
    (4, 'Rock Solid'),
    (5, 'Champion Core');

INSERT INTO CapturedPokemon (captured_id, nickname, level, captured_on) VALUES
    (101, 'Leafy', 18, '2026-03-01'),
    (102, 'Blaze', 36, '2026-03-02'),
    (103, 'Shellshock', 34, '2026-03-02'),
    (104, 'Scout', 22, '2026-03-03'),
    (105, 'Volt', 28, '2026-03-04'),
    (106, 'Nimbus', 55, '2026-03-05'),
    (107, 'Payday', 24, '2026-03-05'),
    (108, 'Bubbles', 30, '2026-03-06'),
    (109, 'Echo', 27, '2026-03-06'),
    (110, 'Atlas', 33, '2026-03-07'),
    (111, 'Aurora', 48, '2026-03-08'),
    (112, 'Thorn', 44, '2026-03-09'),
    (113, 'Mimi', 20, '2026-03-10'),
    (114, 'Circuit', 25, '2026-03-10'),
    (115, 'Ripple', 26, '2026-03-11'),
    (116, 'Pebble', 29, '2026-03-11'),
    (117, 'Static', 31, '2026-03-12'),
    (118, 'Torrent', 32, '2026-03-12');

INSERT INTO PokemonType (pokedex_no, type_id) VALUES
    (1, 3),
    (1, 5),
    (2, 3),
    (2, 5),
    (3, 3),
    (3, 5),
    (4, 1),
    (5, 1),
    (6, 1),
    (6, 6),
    (7, 2),
    (8, 2),
    (9, 2),
    (25, 4),
    (39, 7),
    (39, 11),
    (52, 7),
    (92, 8),
    (92, 5),
    (95, 12),
    (95, 13),
    (131, 2),
    (131, 10),
    (133, 7),
    (134, 2),
    (135, 4),
    (149, 9),
    (149, 6);

INSERT INTO PokemonMove (pokedex_no, move_id, learn_method) VALUES
    (1, 5, 'Level-up'),
    (1, 11, 'Level-up'),
    (1, 12, 'Level-up'),
    (1, 19, 'Level-up'),
    (2, 6, 'Level-up'),
    (2, 12, 'Level-up'),
    (2, 19, 'Level-up'),
    (3, 6, 'Level-up'),
    (3, 16, 'TM'),
    (3, 19, 'Level-up'),
    (4, 1, 'Level-up'),
    (4, 12, 'Level-up'),
    (4, 20, 'Level-up'),
    (5, 1, 'Level-up'),
    (5, 2, 'Level-up'),
    (5, 15, 'TM'),
    (5, 20, 'Level-up'),
    (6, 1, 'Level-up'),
    (6, 2, 'Level-up'),
    (6, 15, 'TM'),
    (6, 16, 'TM'),
    (6, 21, 'HM'),
    (7, 3, 'Level-up'),
    (7, 4, 'Level-up'),
    (7, 11, 'Level-up'),
    (8, 3, 'Level-up'),
    (8, 4, 'Level-up'),
    (8, 10, 'HM'),
    (8, 11, 'Level-up'),
    (9, 3, 'Level-up'),
    (9, 4, 'Level-up'),
    (9, 10, 'HM'),
    (9, 14, 'TM'),
    (25, 7, 'Level-up'),
    (25, 8, 'Level-up'),
    (25, 18, 'Level-up'),
    (39, 11, 'Level-up'),
    (39, 13, 'Level-up'),
    (52, 8, 'Level-up'),
    (52, 20, 'Level-up'),
    (92, 9, 'Level-up'),
    (95, 16, 'TM'),
    (95, 17, 'Level-up'),
    (131, 3, 'Level-up'),
    (131, 10, 'HM'),
    (131, 13, 'Level-up'),
    (131, 14, 'TM'),
    (133, 8, 'Level-up'),
    (133, 11, 'Level-up'),
    (134, 3, 'Level-up'),
    (134, 10, 'HM'),
    (134, 14, 'TM'),
    (135, 7, 'Level-up'),
    (135, 8, 'Level-up'),
    (135, 18, 'Level-up'),
    (149, 7, 'TM'),
    (149, 15, 'Level-up'),
    (149, 21, 'HM');

INSERT INTO TrainerCapturedPokemon (trainer_id, captured_id) VALUES
    (1, 101),
    (1, 102),
    (1, 104),
    (1, 105),
    (1, 113),
    (2, 103),
    (2, 107),
    (2, 109),
    (2, 114),
    (3, 108),
    (3, 111),
    (3, 115),
    (3, 118),
    (4, 110),
    (4, 116),
    (5, 106),
    (5, 112),
    (5, 117);

INSERT INTO CapturedPokemonSpecies (captured_id, pokedex_no) VALUES
    (101, 1),
    (102, 6),
    (103, 9),
    (104, 133),
    (105, 25),
    (106, 149),
    (107, 52),
    (108, 134),
    (109, 92),
    (110, 95),
    (111, 131),
    (112, 3),
    (113, 39),
    (114, 135),
    (115, 7),
    (116, 95),
    (117, 25),
    (118, 8);

INSERT INTO CapturedPokemonTeam (captured_id, trainer_id, team_name, position) VALUES
    (102, 1, 'Main Squad', 1),
    (105, 1, 'Main Squad', 2),
    (101, 1, 'Main Squad', 3),
    (104, 1, 'Main Squad', 4),
    (113, 1, 'Rotation', 1),
    (103, 2, 'League Team', 1),
    (114, 2, 'League Team', 2),
    (109, 2, 'League Team', 3),
    (111, 3, 'Water Rush', 1),
    (108, 3, 'Water Rush', 2),
    (115, 3, 'Water Rush', 3),
    (118, 3, 'Gym Defense', 1),
    (110, 4, 'Rock Solid', 1),
    (116, 4, 'Rock Solid', 2),
    (106, 5, 'Champion Core', 1),
    (112, 5, 'Champion Core', 2);

INSERT INTO Battle (
    battle_id,
    battle_date,
    location,
    challenger_id,
    opponent_id,
    challenger_team,
    opponent_team,
    result
) VALUES
    (201, '2026-03-12', 'Indigo Plateau', 1, 2, 'Main Squad', 'League Team', 'challenger'),
    (202, '2026-03-15', 'Cerulean Gym', 2, 3, 'League Team', 'Water Rush', 'opponent'),
    (203, '2026-03-18', 'Pewter Gym', 4, 1, 'Rock Solid', 'Main Squad', 'opponent'),
    (204, '2026-03-20', 'Sinnoh League', 5, 1, 'Champion Core', 'Main Squad', 'challenger'),
    (205, '2026-03-22', 'Saffron City', 3, 5, 'Water Rush', 'Champion Core', 'draw'),
    (206, '2026-03-24', 'Lavender Town', 2, 4, NULL, 'Rock Solid', 'opponent'),
    (207, '2026-03-26', 'Indigo Plateau', 1, 3, 'Rotation', 'Gym Defense', 'opponent');

COMMIT;

-- Query section
-- ============================================================
-- Five queries without aggregates
-- ============================================================

-- Q1. Show the composition of every declared team.
-- Objective:
-- A trainer often wants to inspect the exact roster currently assigned to each
-- team, including slot order and the species behind each nickname.
-- Relational algebra:
-- pi_{t.name, cpt.team_name, cpt.position, cp.nickname, p.name, cp.level}(
--   ((((CapturedPokemonTeam cpt
--      join_{cpt.trainer_id = t.trainer_id} Trainer t)
--      join_{cpt.captured_id = cp.captured_id} CapturedPokemon cp)
--      join_{cp.captured_id = cps.captured_id} CapturedPokemonSpecies cps)
--      join_{cps.pokedex_no = p.pokedex_no} Pokemon p)
-- )
-- Result:
-- trainer | team_name      | position | nickname   | species    | level
-- Blue    | League Team    | 1        | Shellshock | Blastoise  | 34
-- Blue    | League Team    | 2        | Circuit    | Jolteon    | 25
-- Blue    | League Team    | 3        | Echo       | Gastly     | 27
-- Brock   | Rock Solid     | 1        | Atlas      | Onix       | 33
-- Brock   | Rock Solid     | 2        | Pebble     | Onix       | 29
-- Cynthia | Champion Core  | 1        | Nimbus     | Dragonite  | 55
-- Cynthia | Champion Core  | 2        | Thorn      | Venusaur   | 44
-- Misty   | Gym Defense    | 1        | Torrent    | Wartortle  | 32
-- Misty   | Water Rush     | 1        | Aurora     | Lapras     | 48
-- Misty   | Water Rush     | 2        | Bubbles    | Vaporeon   | 30
-- Misty   | Water Rush     | 3        | Ripple     | Squirtle   | 26
-- Red     | Main Squad     | 1        | Blaze      | Charizard  | 36
-- Red     | Main Squad     | 2        | Volt       | Pikachu    | 28
-- Red     | Main Squad     | 3        | Leafy      | Bulbasaur  | 18
-- Red     | Main Squad     | 4        | Scout      | Eevee      | 22
-- Red     | Rotation       | 1        | Mimi       | Jigglypuff | 20
SELECT t.name AS trainer,
       cpt.team_name,
       cpt.position,
       cp.nickname,
       p.name AS species,
       cp.level
FROM CapturedPokemonTeam cpt
JOIN Trainer t ON t.trainer_id = cpt.trainer_id
JOIN CapturedPokemon cp ON cp.captured_id = cpt.captured_id
JOIN CapturedPokemonSpecies cps ON cps.captured_id = cp.captured_id
JOIN Pokemon p ON p.pokedex_no = cps.pokedex_no
ORDER BY t.name, cpt.team_name, cpt.position;

-- Q2. List all moves that Charizard can learn.
-- Objective:
-- This query helps build a moveset for a specific species, together with the
-- move type, category, and the way the move is learned.
-- Relational algebra:
-- pi_{m.name, ty.name, m.category, pm.learn_method}(
--   sigma_{p.name = 'Charizard'}(
--     (((Pokemon p
--        join_{p.pokedex_no = pm.pokedex_no} PokemonMove pm)
--        join_{pm.move_id = m.move_id} Move m)
--        join_{m.type_id = ty.type_id} Type ty)
--   )
-- )
-- Result:
-- name         | move_type | category | learn_method
-- Dragon Claw  | Dragon    | Physical | TM
-- Earthquake   | Ground    | Physical | TM
-- Ember        | Fire      | Special  | Level-up
-- Flamethrower | Fire      | Special  | Level-up
-- Fly          | Flying    | Physical | HM
SELECT m.name,
       ty.name AS move_type,
       m.category,
       pm.learn_method
FROM Pokemon p
JOIN PokemonMove pm ON p.pokedex_no = pm.pokedex_no
JOIN Move m ON m.move_id = pm.move_id
JOIN Type ty ON ty.type_id = m.type_id
WHERE p.name = 'Charizard'
ORDER BY m.name;

-- Q3. Find species that have exactly two types.
-- Objective:
-- Dual-type species are tactically important because they combine strengths and
-- weaknesses from two elemental types.
-- Relational algebra:
-- pi_{p.name, t1.name, t2.name}(
--   ((((Pokemon p
--      join_{p.pokedex_no = pt1.pokedex_no} PokemonType pt1)
--      join_{p.pokedex_no = pt2.pokedex_no AND pt1.type_id < pt2.type_id} PokemonType pt2)
--      join_{pt1.type_id = t1.type_id} Type t1)
--      join_{pt2.type_id = t2.type_id} Type t2)
-- )
-- Result:
-- name       | first_type | second_type
-- Bulbasaur  | Grass      | Poison
-- Ivysaur    | Grass      | Poison
-- Venusaur   | Grass      | Poison
-- Charizard  | Fire       | Flying
-- Jigglypuff | Normal     | Fairy
-- Gastly     | Poison     | Ghost
-- Onix       | Rock       | Ground
-- Lapras     | Water      | Ice
-- Dragonite  | Flying     | Dragon
SELECT p.name,
       t1.name AS first_type,
       t2.name AS second_type
FROM Pokemon p
JOIN PokemonType pt1 ON p.pokedex_no = pt1.pokedex_no
JOIN PokemonType pt2
    ON p.pokedex_no = pt2.pokedex_no
   AND pt1.type_id < pt2.type_id
JOIN Type t1 ON t1.type_id = pt1.type_id
JOIN Type t2 ON t2.type_id = pt2.type_id
ORDER BY p.pokedex_no;

-- Q4. Show battles where both sides declared a team.
-- Objective:
-- This query reconstructs battle history in a readable way, showing the two
-- trainers, the teams they used, and the winner.
-- Relational algebra:
-- pi_{b.battle_id, b.battle_date, ch.name, b.challenger_team, op.name, b.opponent_team, winner}(
--   sigma_{b.challenger_team IS NOT NULL AND b.opponent_team IS NOT NULL}(
--     ((Battle b
--       join_{b.challenger_id = ch.trainer_id} Trainer ch)
--       join_{b.opponent_id = op.trainer_id} Trainer op)
--   )
-- )
-- Result:
-- battle_id | battle_date | challenger | challenger_team | opponent | opponent_team | winner
-- 201       | 2026-03-12  | Red        | Main Squad      | Blue     | League Team   | Red
-- 202       | 2026-03-15  | Blue       | League Team     | Misty    | Water Rush    | Misty
-- 203       | 2026-03-18  | Brock      | Rock Solid      | Red      | Main Squad    | Red
-- 204       | 2026-03-20  | Cynthia    | Champion Core   | Red      | Main Squad    | Cynthia
-- 205       | 2026-03-22  | Misty      | Water Rush      | Cynthia  | Champion Core | Draw
-- 207       | 2026-03-26  | Red        | Rotation        | Misty    | Gym Defense   | Misty
SELECT b.battle_id,
       b.battle_date,
       ch.name AS challenger,
       b.challenger_team,
       op.name AS opponent,
       b.opponent_team,
       CASE
           WHEN b.result = 'challenger' THEN ch.name
           WHEN b.result = 'opponent' THEN op.name
           ELSE 'Draw'
       END AS winner
FROM Battle b
JOIN Trainer ch ON ch.trainer_id = b.challenger_id
JOIN Trainer op ON op.trainer_id = b.opponent_id
WHERE b.challenger_team IS NOT NULL
  AND b.opponent_team IS NOT NULL
ORDER BY b.battle_date;

-- Q5. Find captured Pokemon that are not assigned to any team.
-- Objective:
-- This query helps detect Pokemon that belong to a trainer but are still in
-- storage and not currently used in any team.
-- Relational algebra:
-- Let
--   A = pi_{t.name, cp.captured_id, cp.nickname, p.name, cp.level}(
--         ((((TrainerCapturedPokemon tcp
--            join_{tcp.trainer_id = t.trainer_id} Trainer t)
--            join_{tcp.captured_id = cp.captured_id} CapturedPokemon cp)
--            join_{cp.captured_id = cps.captured_id} CapturedPokemonSpecies cps)
--            join_{cps.pokedex_no = p.pokedex_no} Pokemon p)
--       )
--   B = pi_{t.name, cp.captured_id, cp.nickname, p.name, cp.level}(
--         (((((TrainerCapturedPokemon tcp
--             join_{tcp.trainer_id = t.trainer_id} Trainer t)
--             join_{tcp.captured_id = cp.captured_id} CapturedPokemon cp)
--             join_{cp.captured_id = cps.captured_id} CapturedPokemonSpecies cps)
--             join_{cps.pokedex_no = p.pokedex_no} Pokemon p)
--             join_{cp.captured_id = cpt.captured_id} CapturedPokemonTeam cpt)
--       )
-- Result = A - B
-- Result:
-- trainer | captured_id | nickname | species | level
-- Blue    | 107         | Payday   | Meowth  | 24
-- Cynthia | 117         | Static   | Pikachu | 31
SELECT t.name AS trainer,
       cp.captured_id,
       cp.nickname,
       p.name AS species,
       cp.level
FROM TrainerCapturedPokemon tcp
JOIN Trainer t ON t.trainer_id = tcp.trainer_id
JOIN CapturedPokemon cp ON cp.captured_id = tcp.captured_id
JOIN CapturedPokemonSpecies cps ON cps.captured_id = cp.captured_id
JOIN Pokemon p ON p.pokedex_no = cps.pokedex_no
WHERE NOT EXISTS (
    SELECT 1
    FROM CapturedPokemonTeam cpt
    WHERE cpt.captured_id = cp.captured_id
)
ORDER BY t.name, cp.captured_id;

-- ============================================================
-- Three aggregate queries
-- ============================================================

-- A1. Count how many captured Pokemon each trainer owns.
-- Objective:
-- This query summarizes the size of each trainer's personal collection.
-- Result:
-- name    | captured_count
-- Red     | 5
-- Blue    | 4
-- Misty   | 4
-- Cynthia | 3
-- Brock   | 2
SELECT t.name,
       COUNT(tcp.captured_id) AS captured_count
FROM Trainer t
LEFT JOIN TrainerCapturedPokemon tcp ON t.trainer_id = tcp.trainer_id
GROUP BY t.trainer_id, t.name
ORDER BY captured_count DESC, t.name;

-- A2. Compute the average level and size of every team.
-- Objective:
-- This query compares the strength and size of the active teams owned by each
-- trainer.
-- Result:
-- trainer | team_name     | avg_level | team_size
-- Cynthia | Champion Core | 49.50     | 2
-- Misty   | Water Rush    | 34.67     | 3
-- Misty   | Gym Defense   | 32.00     | 1
-- Brock   | Rock Solid    | 31.00     | 2
-- Blue    | League Team   | 28.67     | 3
-- Red     | Main Squad    | 26.00     | 4
-- Red     | Rotation      | 20.00     | 1
SELECT t.name AS trainer,
       tm.team_name,
       ROUND(AVG(cp.level), 2) AS avg_level,
       COUNT(*) AS team_size
FROM Team tm
JOIN Trainer t ON t.trainer_id = tm.trainer_id
JOIN CapturedPokemonTeam cpt
    ON cpt.trainer_id = tm.trainer_id
   AND cpt.team_name = tm.team_name
JOIN CapturedPokemon cp ON cp.captured_id = cpt.captured_id
GROUP BY t.trainer_id, t.name, tm.team_name
ORDER BY avg_level DESC, t.name, tm.team_name;

-- A3. Count the number of victories for each trainer.
-- Objective:
-- This query measures competitive performance by counting only battles that a
-- trainer actually won, excluding draws.
-- Result:
-- name    | victories
-- Misty   | 2
-- Red     | 2
-- Brock   | 1
-- Cynthia | 1
-- Blue    | 0
SELECT t.name,
       SUM(
           CASE
               WHEN b.result = 'challenger' AND b.challenger_id = t.trainer_id THEN 1
               WHEN b.result = 'opponent' AND b.opponent_id = t.trainer_id THEN 1
               ELSE 0
           END
       ) AS victories
FROM Trainer t
LEFT JOIN Battle b
    ON b.challenger_id = t.trainer_id
    OR b.opponent_id = t.trainer_id
GROUP BY t.trainer_id, t.name
ORDER BY victories DESC, t.name;
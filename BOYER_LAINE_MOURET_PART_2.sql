-- Database Project — Part 2

PRAGMA foreign_keys = ON;

DROP TRIGGER IF EXISTS trg_pokemon_type_max_two;

DROP TABLE IF EXISTS CapturedPokemonTeam;
DROP TABLE IF EXISTS CapturedPokemonSpecies;
DROP TABLE IF EXISTS TrainerCapturedPokemon;
DROP TABLE IF EXISTS PokemonMove;
DROP TABLE IF EXISTS PokemonType;
DROP TABLE IF EXISTS Battle;
DROP TABLE IF EXISTS Team;
DROP TABLE IF EXISTS CapturedPokemon;
DROP TABLE IF EXISTS WildPokemon;
DROP TABLE IF EXISTS Move;
DROP TABLE IF EXISTS Trainer;
DROP TABLE IF EXISTS Pokemon;
DROP TABLE IF EXISTS Type;

-- Schema definition

CREATE TABLE Type (
    type_id     INTEGER      PRIMARY KEY,
    name        VARCHAR(20)  NOT NULL UNIQUE
);

CREATE TABLE Pokemon (
    pokedex_no      INTEGER       PRIMARY KEY,
    name            VARCHAR(40)   NOT NULL UNIQUE,
    height          DECIMAL(4,1)  NOT NULL CHECK (height > 0),
    weight          DECIMAL(6,1)  NOT NULL CHECK (weight > 0),
    evolves_from    INTEGER       UNIQUE,
    FOREIGN KEY (evolves_from) REFERENCES Pokemon(pokedex_no)
);

CREATE TABLE WildPokemon (
    pokedex_no  INTEGER      PRIMARY KEY,
    location    VARCHAR(60)  NOT NULL,
    level_range VARCHAR(10)  NOT NULL,
    FOREIGN KEY (pokedex_no) REFERENCES Pokemon(pokedex_no) ON DELETE CASCADE
);

CREATE TABLE Move (
    move_id     INTEGER      PRIMARY KEY,
    name        VARCHAR(40)  NOT NULL UNIQUE,
    power       INTEGER,
    accuracy    INTEGER      CHECK (accuracy BETWEEN 0 AND 100),
    pp          INTEGER      NOT NULL CHECK (pp > 0),
    category    VARCHAR(10)  NOT NULL CHECK (category IN ('Physical', 'Special', 'Status')),
    type_id     INTEGER      NOT NULL,
    CHECK (
        (category = 'Status' AND power IS NULL)
        OR (category IN ('Physical', 'Special') AND power IS NOT NULL AND power > 0)
    ),
    FOREIGN KEY (type_id) REFERENCES Type(type_id)
);

CREATE TABLE Trainer (
    trainer_id  INTEGER      PRIMARY KEY,
    name        VARCHAR(60)  NOT NULL,
    birth_date  DATE,
    region      VARCHAR(30)
);

CREATE TABLE Team (
    trainer_id  INTEGER      NOT NULL,
    team_name   VARCHAR(40)  NOT NULL,
    PRIMARY KEY (trainer_id, team_name),
    FOREIGN KEY (trainer_id) REFERENCES Trainer(trainer_id) ON DELETE CASCADE
);

CREATE TABLE CapturedPokemon (
    captured_id  INTEGER      PRIMARY KEY,
    nickname     VARCHAR(40),
    level        INTEGER      NOT NULL CHECK (level BETWEEN 1 AND 100),
    captured_on  DATE
);

CREATE TABLE Battle (
    battle_id           INTEGER      PRIMARY KEY,
    battle_date         DATE         NOT NULL,
    location            VARCHAR(60),
    challenger_id       INTEGER      NOT NULL,
    opponent_id         INTEGER      NOT NULL,
    challenger_team     VARCHAR(40),
    opponent_team       VARCHAR(40),
    result              VARCHAR(12)  NOT NULL CHECK (result IN ('challenger', 'opponent', 'draw')),
    CHECK (challenger_id <> opponent_id),
    FOREIGN KEY (challenger_id) REFERENCES Trainer(trainer_id),
    FOREIGN KEY (opponent_id) REFERENCES Trainer(trainer_id),
    FOREIGN KEY (challenger_id, challenger_team) REFERENCES Team(trainer_id, team_name),
    FOREIGN KEY (opponent_id, opponent_team) REFERENCES Team(trainer_id, team_name)
);

CREATE TABLE PokemonType (
    pokedex_no  INTEGER  NOT NULL,
    type_id     INTEGER  NOT NULL,
    PRIMARY KEY (pokedex_no, type_id),
    FOREIGN KEY (pokedex_no) REFERENCES Pokemon(pokedex_no) ON DELETE CASCADE,
    FOREIGN KEY (type_id) REFERENCES Type(type_id)
);

CREATE TABLE PokemonMove (
    pokedex_no    INTEGER      NOT NULL,
    move_id       INTEGER      NOT NULL,
    learn_method  VARCHAR(20)  NOT NULL,
    PRIMARY KEY (pokedex_no, move_id),
    FOREIGN KEY (pokedex_no) REFERENCES Pokemon(pokedex_no) ON DELETE CASCADE,
    FOREIGN KEY (move_id) REFERENCES Move(move_id)
);

CREATE TABLE TrainerCapturedPokemon (
    trainer_id   INTEGER  NOT NULL,
    captured_id  INTEGER  NOT NULL UNIQUE,
    PRIMARY KEY (trainer_id, captured_id),
    FOREIGN KEY (trainer_id) REFERENCES Trainer(trainer_id) ON DELETE CASCADE,
    FOREIGN KEY (captured_id) REFERENCES CapturedPokemon(captured_id) ON DELETE CASCADE
);

CREATE TABLE CapturedPokemonSpecies (
    captured_id  INTEGER  PRIMARY KEY,
    pokedex_no   INTEGER  NOT NULL,
    FOREIGN KEY (captured_id) REFERENCES CapturedPokemon(captured_id) ON DELETE CASCADE,
    FOREIGN KEY (pokedex_no) REFERENCES Pokemon(pokedex_no)
);

CREATE TABLE CapturedPokemonTeam (
    captured_id  INTEGER      PRIMARY KEY,
    trainer_id   INTEGER      NOT NULL,
    team_name    VARCHAR(40)  NOT NULL,
    position     INTEGER      NOT NULL CHECK (position BETWEEN 1 AND 6),
    UNIQUE (trainer_id, team_name, position),
    FOREIGN KEY (captured_id) REFERENCES CapturedPokemon(captured_id) ON DELETE CASCADE,
    FOREIGN KEY (trainer_id, team_name) REFERENCES Team(trainer_id, team_name) ON DELETE CASCADE,
    FOREIGN KEY (trainer_id, captured_id) REFERENCES TrainerCapturedPokemon(trainer_id, captured_id) ON DELETE CASCADE
);

CREATE TRIGGER trg_pokemon_type_max_two
BEFORE INSERT ON PokemonType
FOR EACH ROW
WHEN (
    SELECT COUNT(*)
    FROM PokemonType
    WHERE pokedex_no = NEW.pokedex_no
) >= 2
BEGIN
    SELECT RAISE(ABORT, 'A Pokemon cannot have more than two types');
END;

-- Sample data

INSERT INTO Type (type_id, name) VALUES
    (1, 'Grass'),
    (2, 'Poison'),
    (3, 'Fire'),
    (4, 'Water'),
    (5, 'Electric'),
    (6, 'Normal'),
    (7, 'Flying'),
    (8, 'Rock'),
    (9, 'Ground');

INSERT INTO Pokemon (pokedex_no, name, height, weight, evolves_from) VALUES
    (1, 'Bulbasaur', 0.7, 6.9, NULL),
    (2, 'Ivysaur', 1.0, 13.0, 1),
    (4, 'Charmander', 0.6, 8.5, NULL),
    (5, 'Charmeleon', 1.1, 19.0, 4),
    (6, 'Charizard', 1.7, 90.5, 5),
    (7, 'Squirtle', 0.5, 9.0, NULL),
    (16, 'Pidgey', 0.3, 1.8, NULL),
    (25, 'Pikachu', 0.4, 6.0, NULL),
    (43, 'Oddish', 0.5, 5.4, NULL),
    (74, 'Geodude', 0.4, 20.0, NULL),
    (95, 'Onix', 8.8, 210.0, NULL);

INSERT INTO WildPokemon (pokedex_no, location, level_range) VALUES
    (1, 'Viridian Forest', '5-7'),
    (4, 'Route 3', '9-12'),
    (7, 'Cerulean Cape', '8-10'),
    (16, 'Route 1', '2-4'),
    (25, 'Viridian Forest', '4-6'),
    (43, 'Route 24', '12-14'),
    (74, 'Mt. Moon', '9-12'),
    (95, 'Rock Tunnel', '13-16');

INSERT INTO Move (move_id, name, power, accuracy, pp, category, type_id) VALUES
    (1, 'Tackle', 40, 100, 35, 'Physical', 6),
    (2, 'Vine Whip', 45, 100, 25, 'Physical', 1),
    (3, 'Ember', 40, 100, 25, 'Special', 3),
    (4, 'Water Gun', 40, 100, 25, 'Special', 4),
    (5, 'Thunder Shock', 40, 100, 30, 'Special', 5),
    (6, 'Razor Leaf', 55, 95, 25, 'Physical', 1),
    (7, 'Sleep Powder', NULL, 75, 15, 'Status', 1),
    (8, 'Quick Attack', 40, 100, 30, 'Physical', 6),
    (9, 'Wing Attack', 60, 100, 35, 'Physical', 7),
    (10, 'Rock Throw', 50, 90, 15, 'Physical', 8),
    (11, 'Flamethrower', 90, 100, 15, 'Special', 3),
    (12, 'Fly', 90, 95, 15, 'Physical', 7);

INSERT INTO Trainer (trainer_id, name, birth_date, region) VALUES
    (1, 'Ash Ketchum', '1987-05-22', 'Kanto'),
    (2, 'Misty', '1988-01-15', 'Kanto'),
    (3, 'Brock', '1987-02-12', 'Kanto'),
    (4, 'Erika', '1986-10-05', 'Kanto');

INSERT INTO Team (trainer_id, team_name) VALUES
    (1, 'Kanto Core'),
    (1, 'Speed Squad'),
    (2, 'Tide'),
    (3, 'Stone Wall'),
    (4, 'Greenhouse');

INSERT INTO CapturedPokemon (captured_id, nickname, level, captured_on) VALUES
    (100, 'Sparky', 26, '2026-03-01'),
    (101, 'Blaze', 18, '2026-03-04'),
    (102, 'Leafy', 15, '2026-03-07'),
    (103, 'Shell', 20, '2026-03-08'),
    (104, 'Ivy', 27, '2026-03-12'),
    (105, 'Bloom', 19, '2026-03-14'),
    (106, 'Boulder', 30, '2026-03-15'),
    (107, 'Pebble', 22, '2026-03-18'),
    (108, 'Swift', 12, '2026-03-20'),
    (109, 'Wave', 17, '2026-03-22'),
    (110, 'Bud', 13, '2026-03-23');

INSERT INTO PokemonType (pokedex_no, type_id) VALUES
    (1, 1), (1, 2),
    (2, 1), (2, 2),
    (4, 3),
    (5, 3),
    (6, 3), (6, 7),
    (7, 4),
    (16, 6), (16, 7),
    (25, 5),
    (43, 1), (43, 2),
    (74, 8), (74, 9),
    (95, 8), (95, 9);

INSERT INTO PokemonMove (pokedex_no, move_id, learn_method) VALUES
    (1, 1, 'Level-up'),
    (1, 2, 'Level-up'),
    (1, 6, 'Level-up'),
    (1, 7, 'Level-up'),
    (2, 2, 'Level-up'),
    (2, 6, 'Level-up'),
    (2, 7, 'Level-up'),
    (4, 3, 'Level-up'),
    (4, 8, 'TM'),
    (5, 3, 'Level-up'),
    (5, 8, 'TM'),
    (6, 3, 'Level-up'),
    (6, 9, 'Level-up'),
    (6, 11, 'TM'),
    (6, 12, 'HM'),
    (7, 1, 'Level-up'),
    (7, 4, 'Level-up'),
    (16, 1, 'Level-up'),
    (16, 8, 'Level-up'),
    (16, 9, 'Level-up'),
    (25, 5, 'Level-up'),
    (25, 8, 'Level-up'),
    (43, 2, 'Level-up'),
    (43, 7, 'Level-up'),
    (74, 10, 'Level-up'),
    (95, 10, 'Level-up');

INSERT INTO TrainerCapturedPokemon (trainer_id, captured_id) VALUES
    (1, 100),
    (1, 101),
    (1, 102),
    (1, 108),
    (1, 110),
    (2, 103),
    (2, 109),
    (3, 106),
    (3, 107),
    (4, 104),
    (4, 105);

INSERT INTO CapturedPokemonSpecies (captured_id, pokedex_no) VALUES
    (100, 25),
    (101, 4),
    (102, 1),
    (103, 7),
    (104, 2),
    (105, 43),
    (106, 95),
    (107, 74),
    (108, 16),
    (109, 7),
    (110, 43);

INSERT INTO CapturedPokemonTeam (captured_id, trainer_id, team_name, position) VALUES
    (100, 1, 'Speed Squad', 1),
    (108, 1, 'Speed Squad', 2),
    (102, 1, 'Kanto Core', 1),
    (101, 1, 'Kanto Core', 2),
    (103, 2, 'Tide', 1),
    (109, 2, 'Tide', 2),
    (106, 3, 'Stone Wall', 1),
    (107, 3, 'Stone Wall', 2),
    (104, 4, 'Greenhouse', 1),
    (105, 4, 'Greenhouse', 2);

INSERT INTO Battle (battle_id, battle_date, location, challenger_id, opponent_id, challenger_team, opponent_team, result) VALUES
    (201, '2026-04-02', 'Pewter City Gym', 1, 3, 'Kanto Core', 'Stone Wall', 'opponent'),
    (202, '2026-04-10', 'Cerulean City Gym', 1, 2, 'Speed Squad', 'Tide', 'challenger'),
    (203, '2026-04-18', 'Celadon City Gym', 3, 4, 'Stone Wall', 'Greenhouse', 'draw'),
    (204, '2026-04-25', 'Saffron Dojo', 4, 1, 'Greenhouse', 'Kanto Core', 'challenger');

-- Query set without aggregates

-- Q1. Show the composition of every declared team.
-- Objective:
-- A trainer often wants to inspect the exact roster currently assigned to each
-- team, including slot order and the species behind each nickname.
SELECT
    tr.name AS trainer,
    tm.team_name,
    cpt.position,
    cp.nickname,
    p.name AS species,
    cp.level
FROM Team AS tm
JOIN Trainer AS tr
    ON tr.trainer_id = tm.trainer_id
JOIN CapturedPokemonTeam AS cpt
    ON cpt.trainer_id = tm.trainer_id
   AND cpt.team_name = tm.team_name
JOIN CapturedPokemon AS cp
    ON cp.captured_id = cpt.captured_id
JOIN CapturedPokemonSpecies AS cps
    ON cps.captured_id = cp.captured_id
JOIN Pokemon AS p
    ON p.pokedex_no = cps.pokedex_no
ORDER BY tr.name, tm.team_name, cpt.position;

-- Returned rows:
-- trainer      | team_name    | position | nickname | species     | level
-- Ash Ketchum  | Kanto Core   | 1        | Leafy    | Bulbasaur   | 15
-- Ash Ketchum  | Kanto Core   | 2        | Blaze    | Charmander  | 18
-- Ash Ketchum  | Speed Squad  | 1        | Sparky   | Pikachu     | 26
-- Ash Ketchum  | Speed Squad  | 2        | Swift    | Pidgey      | 12
-- Brock        | Stone Wall   | 1        | Boulder  | Onix        | 30
-- Brock        | Stone Wall   | 2        | Pebble   | Geodude     | 22
-- Erika        | Greenhouse   | 1        | Ivy      | Ivysaur     | 27
-- Erika        | Greenhouse   | 2        | Bloom    | Oddish      | 19
-- Misty        | Tide         | 1        | Shell    | Squirtle    | 20
-- Misty        | Tide         | 2        | Wave     | Squirtle    | 17

-- Q2. List all moves that Charizard can learn.
-- Objective:
-- This query helps build a moveset for a specific species, together with the
-- move type, category, and the way the move is learned.
SELECT
    p.name AS pokemon,
    m.name AS move,
    ty.name AS move_type,
    m.category,
    pm.learn_method
FROM Pokemon AS p
JOIN PokemonMove AS pm
    ON pm.pokedex_no = p.pokedex_no
JOIN Move AS m
    ON m.move_id = pm.move_id
JOIN Type AS ty
    ON ty.type_id = m.type_id
WHERE p.name = 'Charizard'
ORDER BY ty.name, m.name;

-- Returned rows:
-- pokemon    | move          | move_type | category | learn_method
-- Charizard  | Ember         | Fire      | Special  | Level-up
-- Charizard  | Flamethrower  | Fire      | Special  | TM
-- Charizard  | Fly           | Flying    | Physical | HM
-- Charizard  | Wing Attack   | Flying    | Physical | Level-up

-- Q3. Find species that have exactly two types.
-- Objective:
-- Dual-type species are tactically important because they combine strengths and
-- weaknesses from two elemental types.
SELECT
    p.name AS pokemon,
    t1.name AS first_type,
    t2.name AS second_type
FROM Pokemon AS p
JOIN PokemonType AS pt1
    ON pt1.pokedex_no = p.pokedex_no
JOIN PokemonType AS pt2
    ON pt2.pokedex_no = p.pokedex_no
   AND pt1.type_id < pt2.type_id
JOIN Type AS t1
    ON t1.type_id = pt1.type_id
JOIN Type AS t2
    ON t2.type_id = pt2.type_id
ORDER BY p.pokedex_no;

-- Returned rows:
-- pokemon     | first_type | second_type
-- Bulbasaur   | Grass      | Poison
-- Ivysaur     | Grass      | Poison
-- Charizard   | Fire       | Flying
-- Pidgey      | Normal     | Flying
-- Oddish      | Grass      | Poison
-- Geodude     | Rock       | Ground
-- Onix        | Rock       | Ground

-- Q4. Show battles where both sides declared a team.
-- Objective:
-- This query reconstructs battle history in a readable way, showing the two
-- trainers, the teams they used, and the winner.
SELECT
    b.battle_id,
    b.battle_date,
    challenger.name AS challenger,
    b.challenger_team,
    opponent.name AS opponent,
    b.opponent_team,
    CASE
        WHEN b.result = 'challenger' THEN challenger.name
        WHEN b.result = 'opponent' THEN opponent.name
        ELSE 'Draw'
    END AS winner
FROM Battle AS b
JOIN Trainer AS challenger
    ON challenger.trainer_id = b.challenger_id
JOIN Trainer AS opponent
    ON opponent.trainer_id = b.opponent_id
JOIN Team AS challenger_team_declared
    ON challenger_team_declared.trainer_id = b.challenger_id
   AND challenger_team_declared.team_name = b.challenger_team
JOIN Team AS opponent_team_declared
    ON opponent_team_declared.trainer_id = b.opponent_id
   AND opponent_team_declared.team_name = b.opponent_team
ORDER BY b.battle_date;

-- Returned rows:
-- battle_id | battle_date | challenger   | challenger_team | opponent     | opponent_team | winner
-- 201       | 2026-04-02  | Ash Ketchum  | Kanto Core      | Brock        | Stone Wall    | Brock
-- 202       | 2026-04-10  | Ash Ketchum  | Speed Squad     | Misty        | Tide          | Ash Ketchum
-- 203       | 2026-04-18  | Brock        | Stone Wall      | Erika        | Greenhouse    | Draw
-- 204       | 2026-04-25  | Erika        | Greenhouse      | Ash Ketchum  | Kanto Core    | Erika

-- Q5. Find captured Pokemon that are not assigned to any team.
-- Objective:
-- This query helps detect Pokemon that belong to a trainer but are still in
-- storage and not currently used in any team.
SELECT
    cp.captured_id,
    cp.nickname,
    p.name AS species,
    t.name AS trainer,
    cp.level
FROM CapturedPokemon AS cp
JOIN TrainerCapturedPokemon AS tcp
    ON tcp.captured_id = cp.captured_id
JOIN Trainer AS t
    ON t.trainer_id = tcp.trainer_id
JOIN CapturedPokemonSpecies AS cps
    ON cps.captured_id = cp.captured_id
JOIN Pokemon AS p
    ON p.pokedex_no = cps.pokedex_no
LEFT JOIN CapturedPokemonTeam AS cpt
    ON cpt.captured_id = cp.captured_id
WHERE cpt.captured_id IS NULL
ORDER BY t.name, cp.captured_id;

-- Returned rows:
-- captured_id | nickname | species | trainer      | level
-- 110         | Bud      | Oddish  | Ash Ketchum  | 13

-- ============================================================
-- Query set with aggregates
-- ============================================================

-- A1. Count how many captured Pokemon each trainer owns.
-- Objective:
-- This query summarizes the size of each trainer's personal collection.
SELECT
    t.name AS trainer,
    COUNT(*) AS captured_pokemon
FROM Trainer AS t
JOIN TrainerCapturedPokemon AS tcp
    ON tcp.trainer_id = t.trainer_id
GROUP BY t.trainer_id, t.name
ORDER BY captured_pokemon DESC, t.name;

-- Returned rows:
-- trainer      | captured_pokemon
-- Ash Ketchum  | 5
-- Brock        | 2
-- Erika        | 2
-- Misty        | 2

-- A2. Compute the average level and size of every team.
-- Objective:
-- This query compares the strength and size of the active teams owned by each
-- trainer.
SELECT
    t.team_name,
    tr.name AS trainer,
    ROUND(AVG(cp.level), 2) AS average_level,
    COUNT(cpt.captured_id) AS team_size
FROM Team AS t
JOIN Trainer AS tr
    ON tr.trainer_id = t.trainer_id
LEFT JOIN CapturedPokemonTeam AS cpt
    ON cpt.trainer_id = t.trainer_id
   AND cpt.team_name = t.team_name
LEFT JOIN CapturedPokemon AS cp
    ON cp.captured_id = cpt.captured_id
GROUP BY t.trainer_id, tr.name, t.team_name
ORDER BY average_level DESC, tr.name, t.team_name;

-- Returned rows:
-- team_name    | trainer      | average_level | team_size
-- Stone Wall   | Brock        | 26.0          | 2
-- Greenhouse   | Erika        | 23.0          | 2
-- Speed Squad  | Ash Ketchum  | 19.0          | 2
-- Tide         | Misty        | 18.5          | 2
-- Kanto Core   | Ash Ketchum  | 16.5          | 2

-- A3. Count the number of victories for each trainer.
-- Objective:
-- This query measures competitive performance by counting only battles that a
-- trainer actually won, excluding draws, while also showing the total number
-- of battles they participated in.
SELECT
    t.name AS trainer,
    COUNT(b.battle_id) AS total_battles,
    COALESCE(SUM(
        CASE
            WHEN b.result = 'challenger' AND b.challenger_id = t.trainer_id THEN 1
            WHEN b.result = 'opponent' AND b.opponent_id = t.trainer_id THEN 1
            ELSE 0
        END
    ), 0) AS victories
FROM Trainer AS t
LEFT JOIN Battle AS b
    ON b.challenger_id = t.trainer_id
   OR b.opponent_id = t.trainer_id
GROUP BY t.trainer_id, t.name
ORDER BY victories DESC, total_battles DESC, t.name;

-- Returned rows:
-- trainer      | total_battles | victories
-- Ash Ketchum  | 3             | 1
-- Brock        | 2             | 1
-- Erika        | 2             | 1
-- Misty        | 1             | 0
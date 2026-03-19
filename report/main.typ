// ──────────────────────────────────────────────
//  Database Project — Pokémon
// ──────────────────────────────────────────────

#set text(font: "New Computer Modern", size: 11pt)
#set page(margin: 2cm, numbering: "1")
#set heading(numbering: "1.")
#set par(justify: true)

#align(center)[
  #text(size: 20pt, weight: "bold")[Pokémon Database]
  #v(0.4em)
  #text(size: 13pt)[Database Project — Design Report]
  #v(0.3em)
  #text(size: 11pt, style: "italic")[BOYER Timothé, LAINE Martin, MOURET Basile]
]

#v(1em)

// ═══════════════════════════════════════════════
= Motivation
// ═══════════════════════════════════════════════

The Pokémon franchise, created by Nintendo in 1996, features a rich and
highly structured universe that lends itself naturally to relational
database modelling. Our goal is to design a database that captures the
core entities of the Pokémon world and the relationships between them.

The database stores information about *Pokémon* (identified by
their Pokédex number), including their name, height, weight, and the
one or two *types* they belong to (Fire, Water, Grass, etc.). Because
Pokémon can be encountered in different contexts we distinguish two
specialisations: *Wild Pokémon*, which appear at specific locations and
within a level range, and *Captured Pokémon*, which are owned by
trainers.

Each Pokémon species can learn a set of *Moves*. A move has a name,
power, accuracy, PP (power points), and a category (Physical, Special,
or Status). Every move is also associated with exactly one type.

*Trainers* are the human characters that capture and battle Pokémon. A
trainer is identified by a unique identifier and characterised by a
name, birth date, and home region. Captured Pokémon belong to exactly
one trainer, and can optionally be assigned to one of that trainer's
*Teams*. A team is a _weak entity_ that cannot exist without its owning
trainer: it is identified by the combination of the trainer and a team
name.

The database also keeps a *Battle history*. A battle is a fight
between two trainers, each using one of their teams. Every battle
records the date, location, and the outcome (which trainer won). This
allows us to track the competitive history of every trainer over time.

Finally, evolution is modelled as a *reflexive association* on the
Pokémon class: a Pokémon species may evolve into another Pokémon
species (e.g.\ Charmander → Charmeleon → Charizard), and each species
has at most one direct pre-evolution.

This application domain is interesting because it naturally exhibits a
weak entity (Team), ownership and optional assignment of captured
Pokémon, a reflexive association (evolution), and a rich battle
history, while remaining intuitive and easy to populate with
well-known data.

#pagebreak()

= UML Diagram

The UML class diagram below represents our data model. We use the
notation presented in class (UML with OCL-style constraints where
needed).

#figure(
  image("uml_pokemon.svg", width: 95%),
  caption: [UML class diagram of the Pokémon database.],
) <fig:uml>

#pagebreak()

// ═══════════════════════════════════════════════
= Justification of Design Choices
// ═══════════════════════════════════════════════

== Classes

/ Pokemon: Central entity. Identified by `pokedex_no` (natural key from the official Pokédex). Attributes `name`, `height` (m), `weight` (kg) describe each species.

/ WildPokemon: Subclass of Pokémon. Adds `location` (where the Pokémon can be found, string, e.g. "Kanto/road 2") and `level_range` (string, e.g. "12–15").

/ CapturedPokemon: Individual Pokémon captured by a trainer. Identified by `captured_id` (surrogate key). Attributes include `nickname` (optional), `level`, and `captured_on`. Each captured Pokémon references one species (`pokedex_no`) and one owning trainer (`trainer_id`). It can optionally be assigned to one team of the same trainer.

/ Type: Represents elemental types (Fire, Water, Grass …). Identified by `type_id`. Attribute `name`.

/ Move: A battle move. Identified by `move_id`. Attributes: `name`, `power` (nullable for Status moves), `accuracy`, `pp`, `category` ∈ {Physical, Special, Status}.

/ Trainer: A human trainer. Identified by `trainer_id`. Attributes: `name`, `birth_date`, `region`.

/ Team: A named team of Pokémon owned by a trainer. *Weak entity* identified by (`trainer_id`, `team_name`). Cannot exist without its owning Trainer.

/ Battle: A recorded fight between two trainers. Identified by `battle_id` (surrogate key). Attributes: `battle_date`, `location`, `result` (which side won). References two trainers (challenger and opponent) and optionally the team each used.

== Associations

/ has_type (Pokemon – Type): Many-to-many. A Pokémon has 1 or 2 types; a type is shared by many Pokémon. Cardinality: `1..2` on the Type side, `0..*` on the Pokémon side.

/ move_type (Move – Type): Many-to-one. Each move has exactly one type. Cardinality: `1` on the Type side, `0..*` on the Move side.

/ can_learn (Pokemon – Move): Many-to-many. A Pokémon can learn many moves; a move can be learnt by many Pokémon. An association attribute `learn_method` (Level-up, TM, Egg…) is recorded.

/ evolves_into (Pokemon – Pokemon): *Reflexive* association. A Pokémon may evolve into at most one other Pokémon, and may be the evolution of at most one Pokémon. Cardinality: `0..1` — `0..1`. An association attribute `min_level` records the minimum level needed to trigger the evolution.

/ owns (Trainer – Team): One-to-many (identifying). A trainer owns zero or more teams; each team belongs to exactly one trainer.

/ owns_captured (Trainer – CapturedPokemon): One-to-many. A trainer owns zero or more captured Pokémon; each captured Pokémon belongs to exactly one trainer.

/ is_species_of (CapturedPokemon – Pokemon): Many-to-one. Each captured Pokémon is an instance of exactly one Pokémon species; one species can correspond to many captured Pokémon.

/ assigned_to_team (CapturedPokemon – Team): Optional many-to-one. A captured Pokémon is either unassigned (stored directly by its trainer) or assigned to exactly one team of the same trainer. Team slot `position` (1–6) is stored in the `CapturedPokemonTeam` association table.

/ fights (Battle – Trainer): Each battle involves exactly two trainers: a *challenger* and an *opponent*. A trainer may participate in zero or more battles. This is modelled with two foreign keys from Battle to Trainer.

/ uses_team (Battle – Team): Each side of a battle optionally references the team used. Two foreign keys (`challenger_team` and `opponent_team`) link to Team.

== Cardinalities summary

#table(
  columns: (auto, auto, auto, auto),
  align: (left, center, center, left),
  table.header[*Association*][*Side A*][*Side B*][*Semantics*],
  [has\_type],       [Pokemon `0..*`],  [Type `1..2`],     [A Pokémon has 1 or 2 types],
  [move\_type],      [Move `0..*`],     [Type `1`],        [A move has exactly 1 type],
  [can\_learn],      [Pokemon `0..*`],  [Move `0..*`],     [Many-to-many],
  [evolves\_into],   [Pokemon `0..1`],  [Pokemon `0..1`],  [Reflexive, optional],
  [owns],            [Trainer `1`],     [Team `0..*`],     [Identifying relationship],
    [owns\_captured],  [Trainer `1`],     [CapturedPokemon `0..*`], [Ownership of captured Pokémon],
    [is\_species\_of], [CapturedPokemon `0..*`], [Pokemon `1`], [Captured instance → species],
    [assigned\_to\_team], [CapturedPokemon `0..*`], [Team `0..1`], [Optional assignment to one team],
  [fights],          [Battle `0..*`],   [Trainer `2`],     [Exactly 2 trainers per battle],
  [uses\_team],      [Battle `0..*`],   [Team `0..1`],     [Optional team per side],
)

== Keys

- *Pokemon*: `pokedex_no` (natural key)
- *Type*: `type_id` (surrogate) ; `name` is unique (alternate key)
- *Move*: `move_id` (surrogate) ; `name` is unique
- *Trainer*: `trainer_id` (surrogate)
- *Team*: (`trainer_id`, `team_name`) — composite key (weak entity)
- *Battle*: `battle_id` (surrogate)

#pagebreak()

// ═══════════════════════════════════════════════
= Database Schema
// ═══════════════════════════════════════════════

Below is the relational schema derived from the UML diagram, followed
by the integrity constraints.

== Relations

```sql
-- Elemental types
Type (
    type_id     INT          PRIMARY KEY,
    name        VARCHAR(20)  NOT NULL UNIQUE
);

-- Pokémon species
Pokemon (
    pokedex_no      INT          PRIMARY KEY,
    name            VARCHAR(40)  NOT NULL UNIQUE,
    height          DECIMAL(4,1) NOT NULL,  -- in metres
    weight          DECIMAL(6,1) NOT NULL,  -- in kg
    evolves_from    INT          REFERENCES Pokemon(pokedex_no)
    -- nullable: NULL means no pre-evolution
);

-- Wild Pokémon
WildPokemon (
    pokedex_no  INT          PRIMARY KEY
                             REFERENCES Pokemon(pokedex_no) ON DELETE CASCADE,
    location    VARCHAR(60)  NOT NULL,
    level_range VARCHAR(10)  NOT NULL   -- e.g. '12-15'
);

-- Battle moves
Move (
    move_id     INT          PRIMARY KEY,
    name        VARCHAR(40)  NOT NULL UNIQUE,
    power       INT,                        -- NULL for Status moves
    accuracy    INT          CHECK (accuracy BETWEEN 0 AND 100),
    pp          INT          NOT NULL CHECK (pp > 0),
    category    VARCHAR(10)  NOT NULL CHECK (category IN ('Physical','Special','Status')),
    type_id     INT          NOT NULL REFERENCES Type(type_id)
);

-- Trainers
Trainer (
    trainer_id  INT          PRIMARY KEY,
    name        VARCHAR(60)  NOT NULL,
    birth_date  DATE,
    region      VARCHAR(30)
);

-- Teams (weak entity — identified by trainer + team_name)
Team (
    trainer_id  INT          NOT NULL REFERENCES Trainer(trainer_id) ON DELETE CASCADE,
    team_name   VARCHAR(40)  NOT NULL,
    PRIMARY KEY (trainer_id, team_name)
);

-- Captured Pokémon owned by trainers (optionally assigned to a team)
CapturedPokemon (
    captured_id  INT          PRIMARY KEY,
    nickname     VARCHAR(40),
    level        INT          NOT NULL CHECK (level BETWEEN 1 AND 100),
    captured_on  DATE
);

-- Battle history (fight between two trainers)
Battle (
    battle_id           INT          PRIMARY KEY,
    battle_date         DATE         NOT NULL,
    location            VARCHAR(60),
    challenger_id       INT          NOT NULL REFERENCES Trainer(trainer_id),
    opponent_id         INT          NOT NULL REFERENCES Trainer(trainer_id),
    challenger_team     VARCHAR(40),
    opponent_team       VARCHAR(40),
    result              VARCHAR(12)  NOT NULL
                        CHECK (result IN ('challenger','opponent','draw')),
    CHECK (challenger_id <> opponent_id),
    FOREIGN KEY (challenger_id, challenger_team)
        REFERENCES Team(trainer_id, team_name),
    FOREIGN KEY (opponent_id, opponent_team)
        REFERENCES Team(trainer_id, team_name)
);

-- ─── Association tables ────────────────────────

-- Pokemon ↔ Type  (1..2 types per Pokémon)
PokemonType (
    pokedex_no  INT  NOT NULL REFERENCES Pokemon(pokedex_no) ON DELETE CASCADE,
    type_id     INT  NOT NULL REFERENCES Type(type_id),
    PRIMARY KEY (pokedex_no, type_id)
);

-- Pokemon ↔ Move  (can_learn)
PokemonMove (
    pokedex_no    INT          NOT NULL REFERENCES Pokemon(pokedex_no) ON DELETE CASCADE,
    move_id       INT          NOT NULL REFERENCES Move(move_id),
    learn_method  VARCHAR(20)  NOT NULL,  -- 'Level-up', 'TM', 'Egg', …
    PRIMARY KEY (pokedex_no, move_id)
);

-- Trainer ↔ CapturedPokemon  (owns_captured)
TrainerCapturedPokemon (
    trainer_id   INT  NOT NULL REFERENCES Trainer(trainer_id) ON DELETE CASCADE,
    captured_id  INT  NOT NULL UNIQUE
                    REFERENCES CapturedPokemon(captured_id) ON DELETE CASCADE,
    PRIMARY KEY (trainer_id, captured_id)
);

-- CapturedPokemon ↔ Pokemon  (is_species_of)
CapturedPokemonSpecies (
    captured_id  INT  PRIMARY KEY
                    REFERENCES CapturedPokemon(captured_id) ON DELETE CASCADE,
    pokedex_no   INT  NOT NULL REFERENCES Pokemon(pokedex_no)
);

-- CapturedPokemon ↔ Team  (assigned_to_team, optional)
CapturedPokemonTeam (
    captured_id  INT  PRIMARY KEY
                    REFERENCES CapturedPokemon(captured_id) ON DELETE CASCADE,
    trainer_id   INT  NOT NULL,
    team_name    VARCHAR(40) NOT NULL,
    position     INT  NOT NULL CHECK (position BETWEEN 1 AND 6),
    UNIQUE (trainer_id, team_name, position),
    FOREIGN KEY (trainer_id, team_name)
        REFERENCES Team(trainer_id, team_name)
        ON DELETE CASCADE,
    FOREIGN KEY (trainer_id, captured_id)
        REFERENCES TrainerCapturedPokemon(trainer_id, captured_id)
        ON DELETE CASCADE
);
```

== Integrity Constraints

*Domain constraints:*
- `Pokemon.height > 0`, `Pokemon.weight > 0`.
- `Move.accuracy` ∈ \[0, 100\], `Move.pp > 0`.
- `Move.category` ∈ {Physical, Special, Status}.
- `CapturedPokemon.level` ∈ \[1, 100\].
- `CapturedPokemonTeam.position` ∈ \[1, 6\].
- `Battle.result` ∈ {challenger, opponent, draw}.
- `Battle.challenger_id ≠ Battle.opponent_id` (a trainer cannot fight themselves).

*Key constraints:*
- Each relation has a primary key as shown above.
- `Type.name`, `Pokemon.name`, and `Move.name` are alternate (unique) keys.

*Referential integrity (foreign keys):*
- `Pokemon.evolves_from` → `Pokemon.pokedex_no` (self-referencing, nullable).
- `WildPokemon.pokedex_no` → `Pokemon.pokedex_no` (ON DELETE CASCADE).
- `Move.type_id` → `Type.type_id`.
- `Team(trainer_id)` → `Trainer.trainer_id` (ON DELETE CASCADE).
- `PokemonType` references both `Pokemon` and `Type`.
- `PokemonMove` references both `Pokemon` and `Move`.
- `TrainerCapturedPokemon` references both `Trainer` and `CapturedPokemon`.
- `CapturedPokemonSpecies` references both `CapturedPokemon` and `Pokemon`.
- `CapturedPokemonTeam(captured_id)` → `CapturedPokemon(captured_id)`.
- `CapturedPokemonTeam(trainer_id, team_name)` → `Team(trainer_id, team_name)`.
- `CapturedPokemonTeam(trainer_id, captured_id)` → `TrainerCapturedPokemon(trainer_id, captured_id)` (same owner consistency).
- `Battle.challenger_id` → `Trainer.trainer_id`.
- `Battle.opponent_id` → `Trainer.trainer_id`.
- `Battle(challenger_id, challenger_team)` → `Team(trainer_id, team_name)`.
- `Battle(opponent_id, opponent_team)` → `Team(trainer_id, team_name)`.

*Cardinality constraints (enforced at application level or via triggers):*
- Each Pokémon must have at least 1 and at most 2 types in `PokemonType`.
- Each captured Pokémon belongs to exactly one trainer (`captured_id` unique in `TrainerCapturedPokemon`).
- Each captured Pokémon refers to exactly one species (`captured_id` PK in `CapturedPokemonSpecies`).
- A captured Pokémon is either unassigned to any team (no row in `CapturedPokemonTeam`) or assigned to exactly one team (PK on `captured_id`).
- Each team has at most 6 assigned captured Pokémon (enforced by `UNIQUE (trainer_id, team_name, position)` in `CapturedPokemonTeam`).

#set text(font: "New Computer Modern", size: 11pt)
#set page(margin: 2cm, numbering: "1")
#set heading(numbering: "1.")
#set par(justify: true)

#show raw: set text(size: 8.5pt)

#align(center)[
  #text(size: 20pt, weight: "bold")[Relational Algebra]
]

#v(1em)

This document rewrites each query from the SQL file into relational algebra.

Conventions used here:

- `ORDER BY` is omitted because relational algebra is unordered.
- `pi`, `sigma`, `rho`, `join`, and `-` denote projection, selection,
  rename, theta-join, and difference.
- `gamma` and `leftjoin` are used only for the aggregate queries A1--A3,
  because those queries are not expressible in plain relational algebra.
- Output aliases are written with `->` to match the SQL column names.

= Q1 to Q5: plain relational algebra

== Q1. Composition of every declared team

```text
TeamRoster :=
  rho_tm(Team)
  join_{tm.trainer_id = tr.trainer_id}
    rho_tr(Trainer)
  join_{cpt.trainer_id = tm.trainer_id and
        cpt.team_name = tm.team_name}
    rho_cpt(CapturedPokemonTeam)
  join_{cp.captured_id = cpt.captured_id}
    rho_cp(CapturedPokemon)
  join_{cps.captured_id = cp.captured_id}
    rho_cps(CapturedPokemonSpecies)
  join_{p.pokedex_no = cps.pokedex_no}
    rho_p(Pokemon)

Q1 :=
  pi_{tr.name -> trainer, tm.team_name, cpt.position,
      cp.nickname, p.name -> species, cp.level}(
    TeamRoster
  )
```

== Q2. Moves that Charizard can learn

```text
Q2 :=
  pi_{p.name -> pokemon, m.name -> move,
      ty.name -> move_type, m.category,
      pm.learn_method}(
    sigma_{p.name = 'Charizard'}(rho_p(Pokemon))
    join_{pm.pokedex_no = p.pokedex_no}
      rho_pm(PokemonMove)
    join_{m.move_id = pm.move_id}
      rho_m(Move)
    join_{ty.type_id = m.type_id}
      rho_ty(Type)
  )
```

== Q3. Species having exactly two types

```text
DualTyped :=
  rho_pt1(PokemonType)
  join_{pt1.pokedex_no = pt2.pokedex_no and
        pt1.type_id < pt2.type_id}
    rho_pt2(PokemonType)

Q3 :=
  pi_{p.name -> pokemon, t1.name -> first_type,
      t2.name -> second_type}(
    rho_p(Pokemon)
    join_{p.pokedex_no = pt1.pokedex_no}
      DualTyped
    join_{t1.type_id = pt1.type_id}
      rho_t1(Type)
    join_{t2.type_id = pt2.type_id}
      rho_t2(Type)
  )
```

== Q4. Battles where both sides declared a team

The winner column is reconstructed by taking one projection per possible
result and then unioning the three compatible relations.

```text
DeclaredBattles :=
  rho_b(Battle)
  join_{challenger.trainer_id = b.challenger_id}
    rho_challenger(Trainer)
  join_{opponent.trainer_id = b.opponent_id}
    rho_opponent(Trainer)
  join_{cteam.trainer_id = b.challenger_id and
        cteam.team_name = b.challenger_team}
    rho_cteam(Team)
  join_{oteam.trainer_id = b.opponent_id and
        oteam.team_name = b.opponent_team}
    rho_oteam(Team)

Q4 :=
  pi_{b.battle_id, b.battle_date,
      challenger.name -> challenger,
      b.challenger_team,
      opponent.name -> opponent,
      b.opponent_team,
      challenger.name -> winner}(
    sigma_{b.result = 'challenger'}(DeclaredBattles)
  )
  union
  pi_{b.battle_id, b.battle_date,
      challenger.name -> challenger,
      b.challenger_team,
      opponent.name -> opponent,
      b.opponent_team,
      opponent.name -> winner}(
    sigma_{b.result = 'opponent'}(DeclaredBattles)
  )
  union
  pi_{b.battle_id, b.battle_date,
      challenger.name -> challenger,
      b.challenger_team,
      opponent.name -> opponent,
      b.opponent_team,
      'Draw' -> winner}(
    sigma_{b.result = 'draw'}(DeclaredBattles)
  )
```

== Q5. Captured Pokemon not assigned to any team

The SQL query uses `LEFT JOIN ... IS NULL`; the algebraic form is a
difference between the owned captured Pokemon and the assigned ones.

```text
OwnedCaptured :=
  pi_{cp.captured_id, cp.nickname,
      p.name -> species, t.name -> trainer,
      cp.level}(
    rho_cp(CapturedPokemon)
    join_{tcp.captured_id = cp.captured_id}
      rho_tcp(TrainerCapturedPokemon)
    join_{t.trainer_id = tcp.trainer_id}
      rho_t(Trainer)
    join_{cps.captured_id = cp.captured_id}
      rho_cps(CapturedPokemonSpecies)
    join_{p.pokedex_no = cps.pokedex_no}
      rho_p(Pokemon)
  )

AssignedCaptured :=
  pi_{cp.captured_id, cp.nickname,
      p.name -> species, t.name -> trainer,
      cp.level}(
    rho_cp(CapturedPokemon)
    join_{tcp.captured_id = cp.captured_id}
      rho_tcp(TrainerCapturedPokemon)
    join_{t.trainer_id = tcp.trainer_id}
      rho_t(Trainer)
    join_{cps.captured_id = cp.captured_id}
      rho_cps(CapturedPokemonSpecies)
    join_{p.pokedex_no = cps.pokedex_no}
      rho_p(Pokemon)
    join_{cpt.captured_id = cp.captured_id}
      rho_cpt(CapturedPokemonTeam)
  )

Q5 :=
  OwnedCaptured - AssignedCaptured
```

#pagebreak()

= A1 to A3: extended relational algebra

These three queries rely on aggregation. Under the course convention,
they require extended relational algebra.

== A1. Number of captured Pokemon owned by each trainer

```text
A1 :=
  pi_{t.name -> trainer, captured_pokemon}(
    gamma_{t.trainer_id, t.name;
           COUNT(tcp.captured_id) -> captured_pokemon}(
      rho_t(Trainer)
      join_{tcp.trainer_id = t.trainer_id}
        rho_tcp(TrainerCapturedPokemon)
    )
  )
```

== A2. Average level and size of every team

The SQL rounding is only a presentation step, so the algebra keeps the
aggregated value itself.

```text
TeamLevels :=
  rho_t(Team)
  join_{tr.trainer_id = t.trainer_id}
    rho_tr(Trainer)
  leftjoin_{cpt.trainer_id = t.trainer_id and
            cpt.team_name = t.team_name}
    rho_cpt(CapturedPokemonTeam)
  leftjoin_{cp.captured_id = cpt.captured_id}
    rho_cp(CapturedPokemon)

A2 :=
  pi_{t.team_name, tr.name -> trainer,
      average_level, team_size}(
    gamma_{t.trainer_id, t.team_name, tr.name;
           AVG(cp.level) -> average_level,
           COUNT(cpt.captured_id) -> team_size}(
      TeamLevels
    )
  )
```

== A3. Total battles and victories for each trainer

This algebra mirrors the SQL logic by first building one participation
row per trainer and per battle, then aggregating totals and wins.

```text
Participation :=
  pi_{b.battle_id, b.challenger_id -> trainer_id,
      1 -> win}(
    sigma_{b.result = 'challenger'}(rho_b(Battle))
  )
  union
  pi_{b.battle_id, b.challenger_id -> trainer_id,
      0 -> win}(
    sigma_{b.result = 'opponent' or
           b.result = 'draw'}(rho_b(Battle))
  )
  union
  pi_{b.battle_id, b.opponent_id -> trainer_id,
      1 -> win}(
    sigma_{b.result = 'opponent'}(rho_b(Battle))
  )
  union
  pi_{b.battle_id, b.opponent_id -> trainer_id,
      0 -> win}(
    sigma_{b.result = 'challenger' or
           b.result = 'draw'}(rho_b(Battle))
  )

BattleStats :=
  gamma_{trainer_id;
         COUNT(battle_id) -> total_battles,
         SUM(win) -> victories}(
    Participation
  )

A3 :=
  pi_{t.name -> trainer,
      COALESCE(s.total_battles, 0) -> total_battles,
      COALESCE(s.victories, 0) -> victories}(
    rho_t(Trainer)
    leftjoin_{t.trainer_id = s.trainer_id}
      rho_s(BattleStats)
  )
```
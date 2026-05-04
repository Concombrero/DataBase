# Database Course Summary

This document rewrites the course in three layers:

1. Formal or mathematical notation.
2. Database vocabulary used in the lectures.
3. SQL notation and query patterns.

It is also organized so that the 2024 exam can be answered from it:

- Exercise 1: UML design and constraints.
- Exercise 2: keys, functional dependencies, normal forms, BCNF decomposition.
- Exercise 3: relational algebra, SQL joins, difference, aggregation, grouping, NULL, and DISTINCT.

## 1. Core Objects

### 1.1 Sets, tuples, domains, relations

#### Formal notation

- A set is a collection of distinct elements.
- Membership is written `x in A` and non-membership `x not in A`.
- A cartesian product is written `D1 x D2 x ... x Dn`.
- A tuple is an ordered value such as `<v1, v2, ..., vn>`.
- A relation schema is written `R(A1, A2, ..., An)`.
- An instance of `R` is a set of tuples over the domains of its attributes.
- If attribute `Ai` has domain `Di`, then an instance satisfies:

  `R subseteq D1 x D2 x ... x Dn`

- Relations use set semantics in the formal model: duplicate tuples do not exist.

#### Lecture language

- Attribute = column.
- Tuple = row.
- Relation = table at the logical level.
- Relation schema = table name plus its columns.
- Domain = the set of admissible values for one attribute.
- A database is a set of relations.

#### SQL notation

- A relation schema is implemented as a table.
- Attributes are declared with types and constraints.

```sql
CREATE TABLE R (
  A1 type1,
  A2 type2,
  ...
);
```

- Important difference: SQL usually uses bag semantics by default, so duplicates may appear unless `DISTINCT` or a key prevents them.

### 1.2 Domain constraints, keys, and referential integrity

#### Formal notation

- Domain constraint: `domain(A) = ...`
- Referential integrity:

  `R[X] subseteq S[Y]`

  This means every value of projection `R[X]` must appear in `S[Y]`.

- A set of attributes `K` is a key of relation `R(U)` if `K` determines all attributes of `U`.
- Equivalent closure formulation:

  `K+ = U`

- A candidate key is a minimal key.

#### Lecture language

- Candidate key: minimal identifier.
- Primary key: chosen candidate key.
- Foreign key: attributes in one relation that reference a key in another relation.
- Prime attribute: belongs to some key.
- Non-prime attribute: belongs to no key.

#### SQL notation

```sql
CREATE TABLE S (
  id INTEGER PRIMARY KEY,
  ...
);

CREATE TABLE R (
  id INTEGER PRIMARY KEY,
  sid INTEGER NOT NULL,
  code TEXT UNIQUE,
  amount REAL CHECK (amount > 0),
  CONSTRAINT fk_r_s FOREIGN KEY (sid) REFERENCES S(id)
);
```

- `NOT NULL` expresses mandatory data.
- `UNIQUE` expresses uniqueness.
- `PRIMARY KEY` expresses identification.
- `FOREIGN KEY ... REFERENCES ...` expresses referential integrity.
- `CHECK (...)` expresses value restrictions.

## 2. Relational Algebra Used in the Course

The course uses a compact notation. It is important to know both the course notation and the more standard textbook notation.

### 2.1 Projection

#### Formal notation

- Course notation: `R[A]`
- Standard notation: `pi_A(R)`
- Meaning:

  `R[A] = { t[A] | t in R }`

- Result schema: the attributes in `A` only.
- Duplicates disappear because relations are sets.

#### Lecture language

- Keep only some columns.
- Forget the others.
- If two rows become identical after projection, only one remains in the relational model.

#### SQL notation

```sql
SELECT DISTINCT A
FROM R;
```

- `DISTINCT` is the SQL counterpart when duplicate elimination is needed.
- If selected attributes are already unique because of a key, `DISTINCT` is usually unnecessary.

### 2.2 Selection

#### Formal notation

- Course notation: `R:P`
- Standard notation: `sigma_P(R)`
- Meaning:

  `R:P = { t | t in R and P(t) }`

- Result schema: same as `R`.

#### Lecture language

- Keep only rows satisfying a condition.
- Conditions are built from comparisons and boolean operators.

#### SQL notation

```sql
SELECT *
FROM R
WHERE P;
```

- Boolean operators: `NOT`, `AND`, `OR`.
- Use parentheses whenever precedence may be ambiguous.

### 2.3 Rename

#### Formal notation

- Course notation: `X <- expr`
- Renaming of attributes can also appear as `R(X, Y) <- expr`.

#### Lecture language

- Give a name to an intermediate relation.
- Rename attributes to avoid ambiguity or to express self-joins.

#### SQL notation

```sql
SELECT name AS spectator
FROM Spectators;

SELECT ...
FROM Opinions O1
JOIN Opinions O2 ON (...);
```

- Use aliases for relations and columns.
- This is mandatory in self-joins and highly recommended in multi-join queries.

### 2.4 Cartesian product

#### Formal notation

- Course notation: `R x S`
- Meaning:

  `R x S = { <r, s> | r in R and s in S }`

- If names clash, fully qualified attribute names are needed.

#### Lecture language

- Combine every tuple of `R` with every tuple of `S`.
- It is usually an intermediate step before a join condition filters the useful pairs.

#### SQL notation

```sql
SELECT *
FROM R CROSS JOIN S;
```

### 2.5 Theta join

#### Formal notation

- Course notation: `R(P)*S`
- Standard view: `(R x S):P`
- Meaning:

  `R(P)*S = { <r, s> | r in R and s in S and P(<r, s>) }`

#### Lecture language

- Join two relations with an arbitrary condition.
- Often equality, but it can also use `<`, `>`, `<>`, etc.

#### SQL notation

```sql
SELECT ...
FROM R
JOIN S ON (P);
```

### 2.6 Natural join

#### Formal notation

- Course notation: `R * S`
- Meaning: join on common attribute names with equality, then remove duplicated join columns.

#### Lecture language

- Join on attributes with the same name.
- Use it only when that common-name equality is exactly the intended semantics.

#### SQL notation

```sql
SELECT ...
FROM R
JOIN S USING (A1, A2, ...);
```

- `USING (...)` is the closest SQL equivalent.
- `JOIN ... ON (...)` is often clearer when you want full control.

### 2.7 Set operators

#### Formal notation

- Union: `R union S`
- Intersection: `R intersect S`
- Difference: `R - S`
- Compatibility condition: same arity and comparable domains.

#### Lecture language

- Union: tuples in either relation.
- Intersection: tuples in both relations.
- Difference: tuples in the first relation but not in the second.

#### SQL notation

```sql
SELECT ... FROM R
UNION
SELECT ... FROM S;

SELECT ... FROM R
INTERSECT
SELECT ... FROM S;

SELECT ... FROM R
EXCEPT
SELECT ... FROM S;
```

- In Oracle the course uses `MINUS` instead of `EXCEPT`.
- `UNION ALL` keeps duplicates.
- `UNION`, `INTERSECT`, and `EXCEPT` remove duplicates.

### 2.8 Division

#### Formal notation

- Course notation: `R / S`
- Meaning: retrieve values of one side that are related to all values of the other side.

Example:

- `Enrolls(student, sport) / Enrolls[sport]`
- Result: students enrolled in all sports.

#### Lecture language

- Division is the algebraic operator for "for all" queries.
- In practice, SQL often expresses the same idea with counting or double negation.

#### SQL notation

Common counting pattern:

```sql
WITH PerX AS (
  SELECT x, COUNT(DISTINCT y) AS ny
  FROM R
  GROUP BY x
),
AllY AS (
  SELECT COUNT(DISTINCT y) AS total_y
  FROM R
)
SELECT x
FROM PerX
JOIN AllY ON (ny = total_y);
```

### 2.9 Operator precedence

#### Formal notation

- Unary operators first: projection, selection.
- Multiplicative operators next: product, joins, division.
- Additive operators last: difference, union, intersection.
- All operators are read left-to-right.

#### Practical advice

- Even if precedence is known, add parentheses around binary operators in exam answers.
- This avoids ambiguity and makes the reasoning clearer.

## 3. SQL SELECT Notation

### 3.1 Basic query skeleton

#### Formal view

- SQL implements relational operations in a clause-based syntax.

#### Lecture language

- `SELECT` expresses projection.
- `FROM` expresses relations and joins.
- `WHERE` expresses selection.

#### SQL notation

```sql
SELECT A1, A2, ...
FROM R1
JOIN R2 ON (...)
WHERE P;
```

### 3.2 Duplicates and DISTINCT

#### Key idea

- The relational model is set-based.
- SQL is usually bag-based.
- Therefore, SQL may need `DISTINCT` even when relational algebra would not.

#### When DISTINCT is needed

- When projection can collapse several rows to the same output row.
- After joins when the selected attributes are not a key of the joined result.
- In exam answers, explicitly justify it.

#### When DISTINCT is often unnecessary

- When selecting a primary key.
- When `GROUP BY` already produces one row per group.
- When a join preserves uniqueness on the projected attributes.

### 3.3 Qualified names and aliases

#### Why they matter

- They remove ambiguity.
- They are mandatory when the same attribute name appears in several relations.
- They are mandatory in self-joins.

#### SQL notation

```sql
SELECT O1.movie, O1.stars, O2.stars
FROM Opinions O1
JOIN Opinions O2
  ON (O1.movie = O2.movie AND O1.spectator < O2.spectator);
```

### 3.4 Join patterns

#### Inner join

```sql
SELECT ...
FROM R
JOIN S ON (...);
```

#### Natural-style join on explicit common attributes

```sql
SELECT ...
FROM R
JOIN S USING (A1, A2);
```

#### Cross join

```sql
SELECT ...
FROM R CROSS JOIN S;
```

#### Left outer join

```sql
SELECT ...
FROM R
LEFT OUTER JOIN S ON (...);
```

- Use a left outer join when you want all rows from the left side, even if no match exists on the right.
- It is often paired with `IS NULL` to express "no related tuple exists".

### 3.5 Set operators in SQL

#### Main patterns

- "In A but not in B": `EXCEPT` or `MINUS`
- "In both": `INTERSECT`
- "In A or B": `UNION`

#### Example pattern

```sql
SELECT ISBN FROM WISHLIST
EXCEPT
SELECT ISBN FROM RATING;
```

This is the cleanest SQL pattern for "wishlisted but never rated" when the schemas are compatible.

### 3.6 Subqueries and IN

#### Lecture language

- A query result is itself a relation.
- This relation can be used inside another query.

#### SQL notation

```sql
SELECT ...
FROM R
WHERE A IN (
  SELECT B
  FROM S
  WHERE ...
);
```

- For tuple membership:

```sql
WHERE (A1, A2) IN (
  SELECT B1, B2
  FROM S
)
```

- Use `IN` rather than `=` whenever the subquery may return several tuples.

### 3.7 WITH clause

#### Lecture language

- The course recommends `WITH` to factor intermediate relations.
- It makes complex queries easier to test and easier to read.

#### SQL notation

```sql
WITH R AS (
  SELECT ...
)
SELECT ...
FROM R;
```

### 3.8 Aggregation

#### SQL operators

- `COUNT(*)`: number of tuples.
- `COUNT(A)`: number of non-NULL values of `A`.
- `COUNT(DISTINCT A)`: number of distinct non-NULL values of `A`.
- `AVG(A)`, `MIN(A)`, `MAX(A)`, `SUM(A)`.

#### Important exam rule

- If the question asks for number of authors per year, the correct pattern is usually `COUNT(DISTINCT Author)`, not `COUNT(Author)`, because one author may have several books in the same year.

### 3.9 Grouping and HAVING

#### Lecture language

- `GROUP BY` partitions rows.
- Aggregates are computed per group.
- `HAVING` filters the groups after aggregation.

#### SQL notation

```sql
SELECT Author, AVG(Rating) AS avg_rating
FROM BOOK
JOIN RATING USING (ISBN)
GROUP BY Author;
```

```sql
SELECT ISBN
FROM RATING
GROUP BY ISBN
HAVING COUNT(*) > 1;
```

#### Restriction on SELECT when GROUP BY is present

- Every selected attribute must be:
  - either in the `GROUP BY`,
  - or the result of an aggregate.

This is one of the most common exam mistakes.

### 3.10 Operational order of a grouped query

The course gives the following logical order:

1. `FROM`
2. `WHERE`
3. `GROUP BY`
4. `HAVING`
5. `SELECT`
6. `ORDER BY`

This is the right mental model for debugging grouped queries.

### 3.11 NULL and three-valued logic

#### Key facts

- `NULL` means missing or inapplicable value.
- Comparisons with `NULL` do not return true or false; they return unknown.
- Therefore `A = NULL` and `A <> NULL` are wrong tests.

#### Correct SQL notation

```sql
WHERE A IS NULL
WHERE A IS NOT NULL
```

#### Aggregation with NULL

- `MIN`, `MAX`, `SUM`, `AVG` ignore NULL values.
- `COUNT(*)` counts rows.
- `COUNT(A)` and `COUNT(DISTINCT A)` ignore NULL values.

#### Outer join pattern for absence

```sql
SELECT B.Author
FROM BOOK B
LEFT OUTER JOIN RATING R USING (ISBN)
WHERE R.ISBN IS NULL;
```

This is one standard way to express "books or authors with no rating".

## 4. SQL DDL and DML

### 4.1 Main SQL types in the course

- Strings: `CHAR`, `VARCHAR`, `TEXT`
- Numbers: `INTEGER`, `REAL`, `NUMBER(p,s)` depending on the DBMS
- Dates: stored differently depending on the DBMS

### 4.2 Creating tables

```sql
CREATE TABLE T (
  A1 INTEGER,
  A2 TEXT,
  A3 REAL DEFAULT 1,
  CONSTRAINT t_pk PRIMARY KEY (A1),
  CONSTRAINT t_ck CHECK (A3 > 0)
);
```

### 4.3 Integrity constraints

```sql
CONSTRAINT c1 CHECK (P)
CONSTRAINT c2 UNIQUE (A)
CONSTRAINT c3 PRIMARY KEY (A1, A2)
CONSTRAINT c4 FOREIGN KEY (A1, A2) REFERENCES S(B1, B2)
```

### 4.4 Referential actions

```sql
FOREIGN KEY (sid) REFERENCES S(id)
  ON DELETE CASCADE
  ON UPDATE CASCADE
```

- `RESTRICT` or default behavior: refuse the change.
- `SET NULL`: replace dependent values by `NULL`.
- `CASCADE`: propagate the deletion or update.

### 4.5 Insert, update, delete

```sql
INSERT INTO T VALUES (...);

UPDATE T
SET A = ...
WHERE ...;

DELETE FROM T
WHERE ...;
```

- A modification succeeds only if all declared constraints remain satisfied.

### 4.6 Altering and dropping

```sql
ALTER TABLE T ADD (A DATE);
ALTER TABLE T MODIFY (A TEXT);
DROP TABLE T;
```

### 4.7 Views

```sql
CREATE VIEW V AS
SELECT ...
FROM ...;
```

- A view is a stored query.
- It is useful for derived information and for simplifying later queries.

### 4.8 Important course warning

- Not every business rule can be expressed as a simple SQL integrity constraint.
- Some constraints remain at the application level.

Examples from the course style:

- cardinality over time,
- upper bounds like "at most 4 current loans",
- temporal overlap constraints.

This is important for UML exam questions too: if a constraint is hard to express directly, add it as a comment.

## 5. UML and UML-to-Relational Mapping

The PDF images are not visible in extracted text, but the lecture rules are clear enough to summarize.

### 5.1 What to identify in a UML design question

#### Lecture language

- Classes
- Attributes
- Identifiers
- Associations
- Multiplicities
- Association classes
- Composition
- Optional comments for constraints not directly expressible

#### Formal interpretation

- A class usually becomes a relation.
- An identifier becomes a key.
- Multiplicity constraints become nullability, foreign keys, or separate relations.
- Association attributes often indicate an association class.

### 5.2 Main mapping rules

#### A class

- One relation per class.
- Class attributes become relation attributes.
- Identifier attributes become the key.

#### A 1-to-many association

- Put the key of the `1` side inside the `many` side.
- If participation is mandatory on the `many` side, the foreign key is `NOT NULL`.

Formal pattern:

- If `B` is on the many side and references `C` on the one side, then:

  `B[Kc] subseteq C[Kc]`

#### A 0..1-to-many association

Two options:

1. Put the foreign key in the many side and allow `NULL`.
2. Create a separate relation for the association to avoid `NULL`.

#### A many-to-many association

- Create a new relation for the association.
- Its key is the union of the keys of the two participating classes.

Formal pattern:

- If `A` has key `Ka` and `B` has key `Kb`, association relation `R` has key `Ka union Kb`.
- Referential integrity:

  `R[Ka] subseteq A[Ka]`

  `R[Kb] subseteq B[Kb]`

#### An association class

- Treat it as a relation containing:
  - the keys of the related classes,
  - the attributes of the association itself.

This is very important for exam statements like:

- a rental has `price`, `arrival`, `departure`,
- a sale has `timestamp` and `price`.

Those attributes belong to the relationship, not to one endpoint alone.

#### A 1-to-1 association

- Put one key inside the other relation and make it another candidate key.
- If one side is optional and the other mandatory, choose the placement that avoids missing values when possible.

#### Composition

- The key of the whole is included in the key of the part.

Formal pattern:

- If `Floor` belongs to `Building`, key of `Floor` includes building key.
- If `Room` belongs to `Floor`, key of `Room` includes floor key and therefore also building key.

### 5.3 How to answer a UML exam question

Use this checklist:

1. List the main entity types.
2. Choose identifiers for each class.
3. Add attributes to each class.
4. Identify relationships and multiplicities.
5. Detect association classes when a relationship has its own attributes.
6. Add comments for constraints not captured graphically.

Typical comment-worthy constraints:

- enumeration domains such as `type in {tent, caravan, house}`
- upper bounds like "a client rents at most 2 places"
- temporal constraints like "a place can be rented by only one client at a time"

These are exactly the kinds of comments expected in the 2024 camping exercise.

## 6. Functional Dependencies and Normalization

### 6.1 Notation and terminology

#### Formal notation

- Schemas: uppercase letters such as `R`, `S`, `Q`
- Attributes: uppercase letters such as `A`, `B`, `C`, `D`
- Tuples: lowercase letters such as `t`, `u`
- Sets of attributes are often written by concatenation, for example `X = ABCD`
- Tuple projection: `t[X]`

#### Functional dependency

- `X -> Y` means:

  for all `t, u in R`, if `t[X] = u[X]` then `t[Y] = u[Y]`

- Read it as "X determines Y".

### 6.2 Armstrong rules used in the course

From `F`, derive new functional dependencies with:

1. Reflexivity: if `X subseteq Y`, then `Y -> X`
2. Augmentation: if `X -> Y`, then `XZ -> YZ`
3. Transitivity: if `X -> Y` and `Y -> Z`, then `X -> Z`
4. Decomposition: if `X -> Y` and `Z subseteq Y`, then `X -> Z`
5. Union: if `X -> Y` and `X -> Z`, then `X -> YZ`
6. Pseudo-transitivity: if `X -> Y` and `YW -> Z`, then `XW -> Z`

### 6.3 Closure and keys

#### Closure

- `X+` is the set of all attributes functionally determined by `X` under `F`.

#### Key test

- `X` is a key of `R(U)` iff `X+ = U`.

#### Very useful exam tip from the course

- If an attribute never appears on the right-hand side of any functional dependency, then it must belong to every key.

### 6.4 Full functional dependency

- `X -> Y` is a full functional dependency if no strict subset of `X` still determines `Y`.
- This matters for 2NF.

### 6.5 Normal forms

#### 1NF

- All attributes are atomic.
- No set-valued or nested attributes.

#### 2NF

- Relation is in 1NF.
- Every non-prime attribute fully depends on every key.
- Partial dependence on part of a composite key violates 2NF.

Useful consequence:

- If every key is atomic, then the relation is automatically in 2NF.

#### 3NF

- Relation is in 2NF.
- Every non-prime attribute is non-transitively dependent on every key.

Important correction to keep in mind:

- If `NumE -> Department` and `Department -> Building`, then `Building` is transitively dependent on `NumE`.
- Therefore such a relation is not in 3NF.

#### BCNF

- Relation is in 3NF.
- For every non-trivial dependency `X -> A`, the left side `X` must be a key.

This is stricter than 3NF.

### 6.6 Lossless decomposition

#### Lecture language

- When decomposing a relation, we want a lossless join.
- Rejoining the decomposition should reconstruct exactly the original relation, not a larger one with spurious tuples.

#### Formal criterion given in the course

- A decomposition of `R(X, Y, Z)` into `R1(X, Y)` and `R2(X, Z)` is lossless if:

  `X -> Y`

  or

  `X -> Z`

### 6.7 BCNF decomposition procedure

1. Compute the keys of the relation.
2. Find a dependency `X -> Y` that violates BCNF, meaning `X` is not a key.
3. Decompose the relation into:
   - `Q1(X, Y)`
   - `Q2(X, Z)` where the original schema is `Q(X, Y, Z)`
4. Repeat until every relation is in BCNF.

Important warning from the course:

- Different choices of violating dependencies may produce different BCNF decompositions.
- A BCNF decomposition can lose some original dependencies.

## 7. Query and Reasoning Patterns for the Exam

This section is not a full solution sheet. It tells you which concepts and templates are needed to solve each kind of question from the 2024 exam.

### 7.1 Exercise 1: UML design of the camping database

You need the following concepts:

- class identification
- attribute placement
- identifiers
- multiplicities
- association class
- comment-only constraints

Likely modeling decisions:

- `Camping`, `Zone`, `Place`, `Facility`, `Camper` are classes.
- The rental relation has its own attributes `price`, `arrival`, `departure`, so it should be modeled as an association class or a dedicated class representing the rental.
- `Zone` belongs to exactly one `Camping`.
- `Place` belongs to exactly one `Zone`.
- `Facility` is located in one `Zone`.
- Domain constraint for zone type can be added as a UML comment.
- "A client can rent at most 2 places" is a constraint comment.
- "A place can only be rented by one client at a time" is a temporal constraint comment.

That is enough conceptual material to answer the design question correctly.

### 7.2 Exercise 2: keys, normal forms, BCNF

You need the following workflow:

1. Write the set of functional dependencies `F`.
2. Compute closures of plausible attribute sets.
3. Identify all keys.
4. Mark prime and non-prime attributes.
5. Test 2NF, then 3NF, then BCNF.
6. If BCNF fails, choose a violating dependency and decompose.
7. For the last question, remove only the dependencies that violate BCNF while keeping the same key.

In the 2024 schema `R(A, B, C, D)` with dependencies including `A -> B`, `A -> C`, `C -> D`, `B -> D`:

- closure computation is enough to find the key,
- transitive dependence through `C -> D` and `B -> D` is the core issue,
- BCNF checking depends on whether every determinant is a key.

That is exactly what the normalization section above prepares you to do.

### 7.3 Exercise 3a: titles and authors in Peter's wishlist

Needed concepts:

- selection
- joins
- projection
- `DISTINCT` in SQL because the projection is on `(Title, Author)` rather than on `ISBN`

Relational algebra pattern:

- select reader `Peter`
- join with `WISHLIST`
- join with `BOOK`
- project `(Title, Author)`

SQL pattern:

```sql
SELECT DISTINCT B.Title, B.Author
FROM READER R
JOIN WISHLIST W USING (RId)
JOIN BOOK B USING (ISBN)
WHERE R.Name = 'Peter';
```

`DISTINCT` is the safe SQL answer here because different ISBNs may collapse to the same `(Title, Author)` pair.

### 7.4 Exercise 3b: books wishlisted but never rated

Needed concepts:

- set difference
- anti-join pattern
- `NOT EXISTS` or `EXCEPT`

Relational algebra pattern:

- `WISHLIST[ISBN] - RATING[ISBN]`

SQL patterns:

```sql
SELECT ISBN FROM WISHLIST
EXCEPT
SELECT ISBN FROM RATING;
```

or

```sql
SELECT DISTINCT W.ISBN
FROM WISHLIST W
LEFT OUTER JOIN RATING R ON (W.ISBN = R.ISBN)
WHERE R.ISBN IS NULL;
```

### 7.5 Exercise 3c: books rated more than once

Needed concepts:

- grouping and `HAVING`, or
- self-join with different readers

SQL pattern:

```sql
SELECT DISTINCT B.Title, B.Author
FROM BOOK B
JOIN RATING R USING (ISBN)
GROUP BY B.ISBN, B.Title, B.Author
HAVING COUNT(*) > 1;
```

Relational algebra is possible with a self-join of `RATING` on same `ISBN` and different `RId`, then join with `BOOK` and project `(Title, Author)`.

### 7.6 Exercise 3d: author(s) with the highest average rating

Needed concepts:

- grouping
- `AVG`
- comparison with a global maximum
- `WITH` or nested query

SQL pattern:

```sql
WITH AvgPerAuthor AS (
  SELECT B.Author, AVG(R.Rating) AS avg_rating
  FROM BOOK B
  JOIN RATING R USING (ISBN)
  GROUP BY B.Author
),
Best AS (
  SELECT MAX(avg_rating) AS best_avg
  FROM AvgPerAuthor
)
SELECT Author
FROM AvgPerAuthor
JOIN Best ON (avg_rating = best_avg);
```

Basic relational algebra from the course does not express `AVG` and `MAX`, so this is not expected in plain algebra unless extended operators are allowed.

### 7.7 Exercise 3e: author(s) none of whose books were rated

Needed concepts:

- difference between all authors and rated authors
- or left outer join with `IS NULL`

SQL pattern with difference:

```sql
SELECT Author FROM BOOK
EXCEPT
SELECT B.Author
FROM BOOK B
JOIN RATING R USING (ISBN);
```

SQL pattern with grouped outer join:

```sql
SELECT B.Author
FROM BOOK B
LEFT OUTER JOIN RATING R USING (ISBN)
GROUP BY B.Author
HAVING COUNT(R.ISBN) = 0;
```

Relational algebra is possible with difference.

Important trap:

- `WHERE R.ISBN IS NULL` at the book level is not sufficient here, because it would keep an author having one unrated book and another rated book.

### 7.8 Exercise 3f: number of authors for each year

Needed concepts:

- grouping by year
- counting distinct authors

SQL pattern:

```sql
SELECT Year, COUNT(DISTINCT Author) AS nb_authors
FROM BOOK
GROUP BY Year;
```

Why `DISTINCT` matters here:

- one author may publish several books in the same year,
- the question asks for number of authors, not number of books.

Basic relational algebra from the course does not include `COUNT`, so plain algebra is not expected here.

## 8. Final Revision Checklist

Before an exam answer, check that you can do all of the following.

### Modeling

- Identify classes, identifiers, and association classes.
- Read multiplicities correctly.
- Add comments for constraints not directly expressible in UML.

### Relational algebra

- Translate a query into projection, selection, join, difference, and possibly division.
- Use rename for self-joins.
- Explain when algebra is not expressive enough because aggregation is needed.

### SQL

- Write a `SELECT-FROM-WHERE` query without ambiguity.
- Know when `DISTINCT` is required.
- Use `JOIN`, `USING`, aliases, `GROUP BY`, `HAVING`, `IN`, `WITH`, `EXCEPT`.
- Handle `NULL` with `IS NULL` and `IS NOT NULL`.

### Normalization

- Compute a closure.
- Find keys.
- Distinguish prime from non-prime attributes.
- Test 2NF, 3NF, BCNF.
- Produce a BCNF decomposition with lossless join.

If you can do every item in this checklist, then the course material covered here is enough to answer the 2024 exam questions.
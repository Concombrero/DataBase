# Exercise 3 Review Sheet

This sheet is the compact revision version of Exercise 3.
It focuses on:

- the operations to recognize,
- the shortest correct SQL pattern,
- the relational algebra form when possible,
- the useful alternative formulations.

## 1. Operations to Recognize

### Plain relational algebra

- Projection: `pi`
- Selection: `sigma`
- Rename: `rho`
- Cartesian product: `x`
- Join: `join`
- Difference: `-`

### SQL operations repeatedly used in the exercise

- `SELECT`
- `DISTINCT`
- `JOIN ... USING (...)`
- `JOIN ... ON (...)`
- `WHERE`
- `GROUP BY`
- `HAVING`
- `WITH`
- `EXCEPT` or `MINUS`
- `COUNT`, `AVG`, `MAX`
- `LEFT JOIN`
- `IS NULL`
- subquery in `WHERE`

### Extended relational algebra if aggregation is accepted

Sometimes teachers allow grouping notation such as:

- `gamma_{grouping ; aggregate}`

Example:

- `gamma_{Author ; AVG(Rating) -> avg_rating}(...)`

If your teacher expects plain relational algebra only, then aggregation questions are not expressible in algebra.

## 2. Distinct Cheat Sheet

- Use `DISTINCT` when SQL may keep duplicates but the expected mathematical result is a set.
- Do not add `DISTINCT` after `EXCEPT`, `INTERSECT`, or `UNION`, because those operators already eliminate duplicates.
- In grouped queries, `DISTINCT` is often unnecessary if one output row is already produced per logical result.
- Inside aggregates, `COUNT(DISTINCT A)` is different from `COUNT(A)`.

## 3. Query Patterns by Question

### a) Titles and authors in Peter's wishlist

#### Operations

- selection on reader name
- join `READER` with `WISHLIST`
- join with `BOOK`
- projection on `(Title, Author)`
- `DISTINCT` in SQL

#### Short SQL

```sql
SELECT DISTINCT B.Title, B.Author
FROM READER R
JOIN WISHLIST W USING (RId)
JOIN BOOK B USING (ISBN)
WHERE R.Name = 'Peter';
```

#### Plain relational algebra

```text
pi_{Title, Author}(
  sigma_{Name = 'Peter'}(READER)
  join WISHLIST
  join BOOK
)
```

#### Why `DISTINCT`

- because the output keeps `(Title, Author)` and not `ISBN`,
- several ISBNs can collapse to the same visible result.

### b) ISBN of books wishlisted but never rated

#### Operations

- projection on `ISBN`
- set difference
- possible anti-join formulation

#### Short SQL

```sql
SELECT ISBN
FROM WISHLIST
EXCEPT
SELECT ISBN
FROM RATING;
```

Use `MINUS` instead of `EXCEPT` if the expected SQL dialect is Oracle-style.

#### Other valid SQL form

```sql
SELECT DISTINCT W.ISBN
FROM WISHLIST W
LEFT JOIN RATING R ON (W.ISBN = R.ISBN)
WHERE R.ISBN IS NULL;
```

#### Plain relational algebra

```text
pi_{ISBN}(WISHLIST) - pi_{ISBN}(RATING)
```

#### Best idea to remember

- this is the standard “A but not B” query,
- so think immediately of `EXCEPT` or difference.

### c) Books `(Title, Author)` rated more than once

Because each reader can rate a given book only once, “more than once” means “by at least two distinct readers”.

#### Operations

- join `BOOK` with `RATING`
- grouping by book
- `HAVING COUNT(*) > 1`
- possible self-join on `RATING`
- projection on `(Title, Author)`
- `DISTINCT` in SQL

#### Short SQL

```sql
SELECT DISTINCT B.Title, B.Author
FROM BOOK B
JOIN RATING R USING (ISBN)
GROUP BY B.ISBN, B.Title, B.Author
HAVING COUNT(*) > 1;
```

#### Other valid SQL form: self-join

```sql
SELECT DISTINCT B.Title, B.Author
FROM BOOK B
JOIN RATING R1 USING (ISBN)
JOIN RATING R2 USING (ISBN)
WHERE R1.RId <> R2.RId;
```

#### Plain relational algebra

```text
pi_{Title, Author}(
  BOOK join_{BOOK.ISBN = R1.ISBN}
  sigma_{R1.ISBN = R2.ISBN and R1.RId <> R2.RId}(
    rho_{R1}(RATING) x rho_{R2}(RATING)
  )
)
```

#### Why `DISTINCT`

- the grouping key contains `ISBN`,
- but the displayed result hides `ISBN`,
- so duplicates can reappear at `(Title, Author)` level.

### d) Author name(s) with the highest average rating

#### Operations

- join `BOOK` with `RATING`
- grouping by author
- `AVG(Rating)`
- global `MAX` over per-author averages
- tie handling
- `WITH` or nested subquery

#### Short SQL

```sql
WITH AvgPerAuthor AS (
  SELECT B.Author, AVG(R.Rating) AS avg_rating
  FROM BOOK B
  JOIN RATING R USING (ISBN)
  GROUP BY B.Author
)
SELECT Author
FROM AvgPerAuthor
WHERE avg_rating = (
  SELECT MAX(avg_rating)
  FROM AvgPerAuthor
);
```

#### Alternative SQL form

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
SELECT A.Author
FROM AvgPerAuthor A
JOIN Best B ON (A.avg_rating = B.best_avg);
```

#### Plain relational algebra

- not expressible in plain relational algebra.

#### Extended relational algebra if allowed

```text
Let X = gamma_{Author ; AVG(Rating) -> avg_rating}(BOOK join RATING)
Result = sigma_{avg_rating = max_avg}(X join gamma_{ ; MAX(avg_rating) -> max_avg}(X))
```

#### Best idea to remember

- this is a “group, aggregate, then compare to global optimum” query.

### e) Author name(s) none of whose books were rated

#### Operations

- projection on all authors
- projection on rated authors
- set difference
- possible grouped outer join

#### Short SQL

```sql
SELECT Author
FROM BOOK
EXCEPT
SELECT B.Author
FROM BOOK B
JOIN RATING R USING (ISBN);
```

#### Other valid SQL form: grouped left join

```sql
SELECT B.Author
FROM BOOK B
LEFT JOIN RATING R USING (ISBN)
GROUP BY B.Author
HAVING COUNT(R.ISBN) = 0;
```

#### Plain relational algebra

```text
pi_{Author}(BOOK) - pi_{Author}(BOOK join RATING)
```

#### Important trap

- do **not** write only:

```sql
SELECT DISTINCT B.Author
FROM BOOK B
LEFT JOIN RATING R USING (ISBN)
WHERE R.ISBN IS NULL;
```

- that query means “author has at least one unrated book”,
- not “none of the author's books were rated”.

### f) Number of authors for each year

#### Operations

- grouping by year
- counting authors
- `COUNT(DISTINCT Author)`

#### Short SQL

```sql
SELECT Year, COUNT(DISTINCT Author) AS nb_authors
FROM BOOK
GROUP BY Year;
```

#### Plain relational algebra

- not expressible in plain relational algebra.

#### Extended relational algebra if allowed

```text
gamma_{Year ; COUNT_DISTINCT(Author) -> nb_authors}(BOOK)
```

#### Best idea to remember

- count authors, not books,
- so `DISTINCT Author` is the crucial part.

## 4. Fast Classification of the Six Questions

- a) selection + joins + projection
- b) difference / anti-join
- c) grouping or self-join
- d) aggregation + maximum over groups
- e) difference over authors
- f) grouping + count distinct

## 5. What Is and Is Not Expressible in Plain Relational Algebra

### Expressible

- a)
- b)
- c) via self-join
- e)

### Not expressible in plain relational algebra

- d) because of `AVG` and `MAX`
- f) because of `COUNT`

### Expressible only with extended algebra

- d)
- f)

## 6. Exam Reflexes

- If you see “but not”, think `EXCEPT` or difference.
- If you see “more than once”, think `GROUP BY ... HAVING COUNT(*) > 1` or self-join.
- If you see “highest average”, think two-step aggregation.
- If you see “none of whose”, think global difference, not row-by-row `IS NULL`.
- If you see “number of authors”, check whether `COUNT(DISTINCT Author)` is required.
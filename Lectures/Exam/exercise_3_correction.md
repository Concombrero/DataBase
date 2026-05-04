# Correction of Exercise 3

This correction uses plain SQL plus plain relational algebra where that is possible.

Assumption on relational algebra:

- plain relational algebra supports projection, selection, product, joins, rename, union, intersection, and difference,
- it does not support aggregation operators such as `COUNT`, `AVG`, or `MAX`.

Important SQL reminder:

- relational algebra uses set semantics,
- SQL usually uses bag semantics,
- so `DISTINCT` is required exactly when projecting away a key can create duplicates.

## a) Titles and authors in Peter's wishlist

### SQL

`DISTINCT` is needed because the result keeps `(Title, Author)` but not `ISBN`.

```sql
SELECT DISTINCT B.Title, B.Author
FROM READER R
JOIN WISHLIST W USING (RId)
JOIN BOOK B USING (ISBN)
WHERE R.Name = 'Peter';
```

### Relational algebra

```text
pi_{Title, Author}(
  sigma_{Name = 'Peter'}(READER)
  join WISHLIST
  join BOOK
)
```

## b) ISBN of books wishlisted but never rated

### SQL

`DISTINCT` is not needed here because `EXCEPT` already removes duplicates.

```sql
SELECT ISBN
FROM WISHLIST
EXCEPT
SELECT ISBN
FROM RATING;
```

Equivalent in Oracle syntax: replace `EXCEPT` by `MINUS`.

### Relational algebra

```text
pi_{ISBN}(WISHLIST) - pi_{ISBN}(RATING)
```

## c) Books `(Title, Author)` rated more than once

Because only one rating per `(RId, ISBN)` is allowed, “rated more than once” means “rated by at least two readers”.

### SQL

`DISTINCT` is needed because the grouping is by `ISBN`, while the final projection keeps only `(Title, Author)`.

```sql
SELECT DISTINCT B.Title, B.Author
FROM BOOK B
JOIN RATING R USING (ISBN)
GROUP BY B.ISBN, B.Title, B.Author
HAVING COUNT(*) > 1;
```

### Relational algebra

```text
pi_{Title, Author}(
  BOOK join_{BOOK.ISBN = R1.ISBN}
  sigma_{R1.ISBN = R2.ISBN and R1.RId <> R2.RId}(
    rho_{R1}(RATING) x rho_{R2}(RATING)
  )
)
```

The self-join detects one same book rated by two different readers.

## d) Author name(s) with the highest average rating

### SQL

`DISTINCT` is not needed because the grouping is already by author.

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

This correctly keeps all ties.

### Relational algebra

Not expressible in plain relational algebra, because it requires `AVG` and `MAX`.

## e) Author name(s) none of whose books were rated

The cleanest reading is:

- all authors appearing in `BOOK`,
- minus the authors for which at least one book appears in `RATING`.

### SQL

`DISTINCT` is not needed because `EXCEPT` already removes duplicates.

```sql
SELECT Author
FROM BOOK
EXCEPT
SELECT B.Author
FROM BOOK B
JOIN RATING R USING (ISBN);
```

Equivalent in Oracle syntax: replace `EXCEPT` by `MINUS`.

### Relational algebra

```text
pi_{Author}(BOOK) - pi_{Author}(BOOK join RATING)
```

### Common trap

This query is **not** the same as selecting authors having at least one unrated book.
A naive left join with `WHERE R.ISBN IS NULL` at the book level would be wrong for an author who has one rated book and one unrated book.

## f) Number of authors for each year

The condition “for years in which at least one author has published a book” is automatic: a `GROUP BY Year` over `BOOK` only returns years present in `BOOK`.

### SQL

`DISTINCT` is required because one author may have several books in the same year.

```sql
SELECT Year, COUNT(DISTINCT Author) AS nb_authors
FROM BOOK
GROUP BY Year;
```

### Relational algebra

Not expressible in plain relational algebra, because it requires `COUNT`.

## Final Check on `DISTINCT`

- a) needed
- b) not needed with `EXCEPT`
- c) needed
- d) not needed
- e) not needed with `EXCEPT`
- f) needed inside `COUNT(DISTINCT Author)`
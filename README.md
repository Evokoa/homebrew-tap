# Evokoa Homebrew Tap

Homebrew formulae for Evokoa projects.

## pgGraph

```sh
brew tap Evokoa/tap
brew install pggraph
```

pgGraph is packaged for Homebrew PostgreSQL 17. After installation, start or
restart PostgreSQL and create the extension:

```sh
psql -d postgres -c "CREATE EXTENSION graph;"
```

## Upgrade From 0.1.x To 1.0

The alpha-to-1.0 upgrade preserves your PostgreSQL source tables but requires a
clean extension installation and graph rebuild. Before the maintenance window,
back up the database and save the reviewed `graph.add_table(...)`,
`graph.add_edge(...)`, and `graph.add_filter_column(...)` registration calls.

Stop graph-using application traffic, review objects that depend on the
extension, and drop the alpha extension. Do not use `CASCADE` without reviewing
the dependent objects it will remove.

```sql
DROP EXTENSION graph;
```

Upgrade the package and restart PostgreSQL:

```sh
brew update
brew upgrade Evokoa/tap/pggraph
brew services restart postgresql@17
```

Create the 1.0 extension, reapply the saved registrations, and rebuild the
derived graph state:

```sql
CREATE EXTENSION graph VERSION '1.0.0';
-- Reapply graph.add_table(...), graph.add_edge(...), and
-- graph.add_filter_column(...) calls here.
SELECT * FROM graph.build();
SELECT * FROM graph.status();
```

See the
[pgGraph 1.0 migration guide](https://github.com/evokoa/pggraph/blob/v1.0.0/docs/user_guide/migration-1-0.mdx)
for dependency preflight, validation, and rollback instructions.

For local formula validation:

```sh
brew install --build-from-source ./Formula/pgrx@0.19.1.rb
brew install --build-from-source ./Formula/pggraph.rb
brew test pggraph
```

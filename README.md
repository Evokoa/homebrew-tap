# Evokoa Homebrew Tap

Source-build Homebrew formulae for Evokoa PostgreSQL extensions.

## What Gets Installed

pgGraph and pgContext are PostgreSQL extensions, not command-line programs.
Homebrew installs their shared libraries, control files, and SQL definitions for
Homebrew `postgresql@17`. It does not add `pggraph` or `pgcontext` commands to
your shell's `PATH`.

| Homebrew formula | PostgreSQL extension | Enable with |
| --- | --- | --- |
| `pggraph` | `graph` | `CREATE EXTENSION graph;` |
| `pgcontext` | `pgcontext` | `CREATE EXTENSION pgcontext;` |

## Install

Install either formula directly. A fully qualified install automatically adds
the tap and trusts only the requested formula.

```sh
brew install Evokoa/tap/pggraph
brew install Evokoa/tap/pgcontext
```

Both formulae build against Homebrew PostgreSQL 17. Start the server after a
new installation, or restart it after replacing extension binaries:

```sh
brew services start postgresql@17
```

Enable the installed extension in each database that should use it. Run only
the command for the formula you installed, and replace `postgres` with the
target database name:

```sh
psql -X -v ON_ERROR_STOP=1 -d postgres -c "CREATE EXTENSION graph;"
psql -X -v ON_ERROR_STOP=1 -d postgres -c "CREATE EXTENSION pgcontext;"
```

Verify the database-visible extension versions:

```sh
psql -X -d postgres -c \
  "SELECT extname, extversion
     FROM pg_extension
    WHERE extname IN ('graph', 'pgcontext')
    ORDER BY extname;"
```

## Upgrade pgGraph From 0.1.x To 1.0

The alpha-to-1.0 boundary preserves ordinary PostgreSQL source tables but
requires a clean pgGraph extension installation and graph rebuild. Before the
maintenance window:

- take and verify a PostgreSQL backup;
- save the reviewed `graph.add_table(...)`, `graph.add_edge(...)`, and
  `graph.add_filter_column(...)` registration calls;
- stop application traffic that uses pgGraph.

Review extension dependencies with the transaction preflight in the
[pgGraph 1.0 migration guide](https://github.com/evokoa/pggraph/blob/v1.0.0/docs/user_guide/migration-1-0.mdx).
Then drop the alpha extension. Do not use `CASCADE` without reviewing every
dependent object it will remove.

```sql
DROP EXTENSION graph;
```

Upgrade the Homebrew package and restart PostgreSQL:

```sh
brew update
brew upgrade Evokoa/tap/pggraph
brew services restart postgresql@17
```

Create pgGraph 1.0, reapply the saved registrations, and rebuild its derived
graph state:

```sql
CREATE EXTENSION graph VERSION '1.0.0';
-- Reapply graph.add_table(...), graph.add_edge(...), and
-- graph.add_filter_column(...) calls here.
SELECT * FROM graph.build();
SELECT * FROM graph.status();
```

## Move pgContext 0.1.0 To Homebrew 0.2.0

pgContext provides a versioned database update from 0.1.0 to 0.2.0, but 0.1.0
was distributed outside this Homebrew tap. Take a PostgreSQL backup and stop
pgContext-using traffic. Keep the `pgcontext` extension registered in the
database, remove the 0.1.0 package files using the original source or PGXN
installation method, and confirm that stale `pgcontext` library, control, and
SQL files no longer occupy Homebrew PostgreSQL 17's directories.

Install the 0.2.0 Homebrew package and restart PostgreSQL:

```sh
brew install Evokoa/tap/pgcontext
brew services restart postgresql@17
```

Run the extension update as a PostgreSQL superuser:

```sh
psql -X -v ON_ERROR_STOP=1 -d postgres \
  -c "ALTER EXTENSION pgcontext UPDATE TO '0.2.0';"
```

The database update preserves pgContext catalog rows and user-owned source
tables. It moves pgContext-owned vector types into the `pgcontext` schema, so
applications should use qualified types such as `pgcontext.vector` or
deliberately configure their `search_path`. A pgvector-first 0.1.0 coexistence
installation has a different migration boundary; follow the
[pgContext 0.2.0 release notes](https://github.com/evokoa/pgcontext/blob/v0.2.0/docs/user_guide/release_notes.md)
instead of forcing the update.

## Routine Package Upgrades

For supported non-migration releases, update the tap and upgrade the installed
formula:

```sh
brew update
brew upgrade Evokoa/tap/pggraph
brew upgrade Evokoa/tap/pgcontext
brew services restart postgresql@17
```

Homebrew upgrades extension files on disk; it does not change an extension
already registered inside a database. Check the target release notes and run
`ALTER EXTENSION ... UPDATE` only when that release declares a supported update
path.

## Troubleshooting

### `pggraph` Or `pgcontext`: Command Not Found

This is expected. These formulae install PostgreSQL extensions, not shell
executables. Use `psql` to run `CREATE EXTENSION`, SQL queries, and extension
administration commands.

### PostgreSQL Cannot Find The Extension

Confirm that the formula and Homebrew PostgreSQL 17 are installed, then restart
the service:

```sh
brew info Evokoa/tap/pggraph
brew info Evokoa/tap/pgcontext
brew list --versions postgresql@17
brew services restart postgresql@17
```

The formula, `pg_config`, and running PostgreSQL server must use the same major
version.

### The Tap Or Formula Is Stale

```sh
brew update
brew info Evokoa/tap/pggraph
brew info Evokoa/tap/pgcontext
```

If a previously tapped checkout remains stale, repair the tap metadata and
update again:

```sh
brew tap --repair
brew update
```

## Maintainer Validation

Homebrew requires formulae under a registered tap. Run validation from the
checkout returned by:

```sh
brew --repository Evokoa/tap
```

Then validate style, metadata, source builds, and PostgreSQL smoke tests:

```sh
brew style --formula Evokoa/tap/pggraph Evokoa/tap/pgcontext
brew audit --strict --online Evokoa/tap/pggraph Evokoa/tap/pgcontext
brew install --build-from-source Evokoa/tap/pgrx@0.19.1
brew install --build-from-source Evokoa/tap/pggraph
brew install --build-from-source Evokoa/tap/pgcontext
brew test Evokoa/tap/pggraph
brew test Evokoa/tap/pgcontext
```

Use `brew reinstall --build-from-source ...` when the formula is already
installed and must be rebuilt.

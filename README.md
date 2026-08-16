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

## Upgrade pgGraph 1.0 To 1.1

pgGraph provides a supported database update from 1.0.0 to 1.1.0. Take a
PostgreSQL backup, record `SELECT * FROM graph.status();`, and stop application
traffic that uses pgGraph before replacing the package.

Upgrade the Homebrew package and restart PostgreSQL:

```sh
brew update
brew upgrade Evokoa/tap/pggraph
brew services restart postgresql@17
```

Run the extension update in every database that has pgGraph installed, then
verify its version and graph state:

```sql
ALTER EXTENSION graph UPDATE TO '1.1.0';
SELECT extversion FROM pg_extension WHERE extname = 'graph';
SELECT * FROM graph.status();
```

Existing v6 graph artifacts remain compatible and do not require a blanket
rebuild. If an RLS-active relationship mapping fails with diagnostic `PG023`,
run `graph.build()` to repair that targeted compatibility condition. Follow the
[pgGraph 1.1 compatibility guide](https://github.com/evokoa/pggraph/blob/v1.1.0/docs/user_guide/versioning-and-compatibility.mdx)
for validation and backup-restore rollback; an in-place downgrade to 1.0.0 is
not supported.

## Upgrade pgContext 0.1 Or 0.2 To 0.3

pgContext 0.3.0 is a clean-install baseline. It does not provide an extension
update script from 0.1 or 0.2, so do not run `ALTER EXTENSION ... UPDATE` for
this release. A Homebrew package upgrade replaces files on disk but cannot
migrate an extension already registered inside a database.

Before replacing the package:

- take and verify a PostgreSQL backup;
- stop application traffic that uses pgContext;
- inventory objects that depend on pgContext and export collection or profile
  configuration that must be recreated;
- preserve ordinary source tables, and cast or export columns that use
  pgContext-owned source types before removing the old extension.

Follow the complete
[pgContext 0.3.0 migration procedure](https://github.com/evokoa/pgcontext/blob/v0.3.0/docs/user_guide/release_notes.md#compatibility-and-migration).
After reviewing the dependency plan, remove the old extensions without
`CASCADE`. These commands fail safely if dependent objects still need attention:

```sql
DROP EXTENSION IF EXISTS pgcontext_pgvector;
DROP EXTENSION pgcontext;
```

Upgrade an existing Homebrew installation, then restart PostgreSQL:

```sh
brew update
brew upgrade Evokoa/tap/pgcontext
brew services restart postgresql@17
```

For a 0.1 or 0.2 package installed from source or PGXN, remove its package files
using the original installation method and run the following instead. Do not
leave stale library, control, or SQL files in Homebrew PostgreSQL 17's
directories.

```sh
brew install Evokoa/tap/pgcontext
brew services restart postgresql@17
```

Finally, create pgContext 0.3, recreate registrations, and rebuild derived
indexes and artifacts from the authoritative source rows:

```sql
CREATE EXTENSION pgcontext VERSION '0.3.0';
-- Recreate registrations, profiles, indexes, and other derived artifacts.
```

The separate `pgcontext_pgvector` companion extension is retired in 0.3.0. For
pgvector coexistence, install the pgContext and pgvector main extensions and
follow pgContext's documented binding and migration workflow.

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

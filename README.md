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

For local formula validation:

```sh
brew install --build-from-source ./Formula/pggraph.rb
brew test pggraph
```

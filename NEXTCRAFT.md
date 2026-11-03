# ArtCraft Launcher — NextCraft edition

This is the `NextCraft` branch of GameDirection's fork of [storytold/craft-launcher](https://github.com/storytold/craft-launcher), maintained by GameDirection for [NextCraft](https://github.com/Gamedirection/nextcraft). It is not an official storytold release.

## What it changes

The official web launcher can't install anything, so each card offers a download. This build reads an optional `craft-links.json` next to `index.html`:

```json
{ "photocraft": "https://cloud.example.com/index.php/apps/nextcraft/edit/photocraft" }
```

When an app has an entry, its main button is **Open** and opens that address in a new tab. Downloads stay in the `⋯` menu. Without the file, the launcher behaves exactly like upstream.

- Values may use `{proto}` (`https:`), `{host}` (host name) and `{app}` (the app id); the page fills them in from its own address.
- Plain `http://` addresses are allowed for these links (`release::safe_instance_link`); every other link keeps upstream's https-only rule.
- `Dockerfile` + `packaging/docker/` build an nginx image whose entrypoint writes `craft-links.json` from `CRAFT_APP_PORTS`, `CRAFT_LINK_TEMPLATE` and `CRAFT_LINK_<APP>` variables, for running the launcher on its own.

NextCraft builds this branch with `deploy/install-launcher.sh` and writes `craft-links.json` itself.

## Keeping up with upstream

```sh
git fetch upstream            # upstream = https://github.com/storytold/craft-launcher
git rebase upstream/main      # on the NextCraft branch
```

The change is one commit touching `crates/core/src/protocol.rs`, `crates/core/src/release.rs`, `crates/ui-egui/src/views.rs` and `apps/artcraft-launcher-web/`.

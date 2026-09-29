# addon-ha-raicov-hearth

Home Assistant add-on for [ha-raicov-hearth](https://github.com/raicovx/ha-raicov-hearth), a fork of [Hearth](https://github.com/knowald/ha-hearth), a dashboard for wall tablets, phones and desktops. It is forked from [addon-ha-hearth](https://github.com/knowald/addon-ha-hearth) and uses its own slugs, so it installs alongside the original.

## Install

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fraicovx%2Faddon-ha-raicov-hearth)

To add the repository by hand, open Settings, Add-ons, Add-on Store, then Repositories from the overflow menu, and paste `https://github.com/raicovx/addon-ha-raicov-hearth`. Install Hearth from the store once the repository is listed, then start it.

Hearth appears in the sidebar and is served over Ingress. Setting a port in the add-on configuration exposes it directly as well, which is what wall tablets should use. Dashboard configuration is stored on the add-on's own volume and survives updates.

## Channels

The repository offers three add-ons. Each has its own data, so they can run side by side.

- **Hearth** tracks stable Hearth releases.
- **Hearth (beta)** tracks Hearth prereleases and falls back to the stable version between betas.
- **Hearth (edge)** tracks the `master` image of ha-raicov-hearth. It updates at most once a day, or sooner when the workflow is run by hand, and may break without notice.

## Direct access

When exposing a port for a wall tablet, set **Home Assistant URL for direct access**
(`hass_public_url`) in the add-on configuration to a Home Assistant address the
browser can reach, for example:

```yaml
hass_public_url: http://homeassistant.local:8123
```

If Hearth is served over HTTPS, use an HTTPS Home Assistant URL, such as your
Nabu Casa address. Restart the add-on after changing this setting.

Ingress requires no URL configuration and always uses the current Home Assistant
origin, even when this option is set. The server continues using the internal
Home Assistant address for proxy requests.

This option is available from version `0.1.1`.

## HTTPS and the default dashboard

An HTTPS Home Assistant cannot embed Hearth's plain HTTP port. To use Hearth as a
Webpage dashboard, for example as the default dashboard in the companion app,
serve it over HTTPS with the certificate Home Assistant already uses:

1. Turn on **HTTPS** and set a host port for `8443/tcp`. The certificate and key
   default to `fullchain.pem` and `privkey.pem` in `/ssl`, where the DuckDNS and
   Let's Encrypt add-ons put them.
2. Set **Home Assistant URL for direct access** to the HTTPS Home Assistant URL,
   such as `https://example.duckdns.org:8123`, and restart the add-on.
3. Open `https://example.duckdns.org:8443`, and under Application settings save a
   long-lived access token. The companion app and embedded pages cannot sign in
   through Home Assistant's login page.
4. In Home Assistant, add a Webpage dashboard for
   `https://example.duckdns.org:8443/?menu=false` and set it as the default.

The plain port and Ingress keep working alongside it.

## How it builds

The add-on does not build Hearth itself. It copies the app out of the image that ha-raicov-hearth's `docker-publish` workflow pushes to `ghcr.io/raicovx/ha-raicov-hearth`, onto pinned Home Assistant base images, and publishes `ghcr.io/raicovx/addon-ha-raicov-hearth-{arch}` for `aarch64` and `amd64`. All three add-ons share these images: stable versions are also tagged `latest`, betas `beta` and edge builds `edge`.

`version` in `config.yaml` names the ha-raicov-hearth image tag a release packages, which `docker-publish` creates when a ha-raicov-hearth GitHub release with that tag is published.

The edge add-on is built by the same workflow on a nightly schedule. It reads the `master` image that `docker-publish` last pushed from a manual run on `master`, pins it by digest, builds it as `<hearth version>-edge.<commit>`, and then commits that version to `edge/config.yaml` so the Supervisor offers the update only once both images exist. It skips an image it has already published. Run the workflow by hand with the `edge` channel to publish sooner.

The published container packages, including `ha-raicov-hearth` itself, must be public for this workflow and the Supervisor to pull them. GitHub creates them private on the first push; change that once per package under Packages, Package settings, Change visibility. Later pushes keep the setting.

## Releasing

Publish the matching ha-raicov-hearth release first and wait for its `docker-publish` run. Then update `version` in `config.yaml`
and `CHANGELOG.md`, push the changes, and publish a GitHub release with that exact
tag (no `v` prefix). The workflow verifies that the tag matches the configured
version and publishes both architecture images. Ordinary pushes do not publish
images. Manual recovery builds must run from the matching release tag.

For a beta, set `version` in `beta/config.yaml` to the Hearth prerelease tag, such
as `0.4.0-beta.1`, and publish the GitHub release as a pre-release. Tags with a
`-` suffix must be pre-releases and read `beta/config.yaml`; other tags must not
be. Betas get no `CHANGELOG.md` entry. When the stable version ships, set
`beta/config.yaml` to it as well so beta users move onto it.

`CHANGELOG.md` follows [Common Changelog](https://common-changelog.org/): one
`## [VERSION] - YYYY-MM-DD` entry per stable release, newest first, with `Changed`,
`Added`, `Removed` and `Fixed` groups in that order, imperative entries, and a
reference link per version at the bottom. The Hearth version an add-on release
tracks goes under `Changed`, or `Fixed` when that Hearth release only fixes bugs,
linked to its Hearth release.

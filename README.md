# H3 Code

H3 Code is an independent build of [T3 Code](https://github.com/pingdotgg/t3code) by Hotchi. The upstream source and this overlay are distributed under the MIT license. T3 Code is developed by T3 Tools Inc.

Configure a CLIProxyAPI hub under **Settings → Providers → Usage providers**. Turn on **Antigravity limits** for that hub to see its accounts in **Usage → Limits**. H3 Code uses the same `H3Code` user agent on every installation. The hub's account identity is used to count a shared account once. Google may refuse a third-party quota request. H3 Code displays the quota as unavailable when that happens.

H3 uses the existing `~/.t3` data directory and T3 Connect link scheme. Quit T3 Code before starting H3 Code against that directory.

## Build

The overlay applies `patches/` to an exact T3 Code nightly commit. Use Git, Bash, jq and the Node and pnpm versions in the upstream manifest.

```sh
scripts/prepare.sh "$(jq -r .tag upstream.json)" "$(jq -r .commit upstream.json)" _upstream
cd _upstream
pnpm install --frozen-lockfile
pnpm exec vp run build:desktop
```

The GitHub workflow checks upstream for a new nightly every six hours and uses the pinned commit for pull requests. Linux x64, Windows x64, and macOS arm64 packages are available as Actions artifacts after a successful build. To make a release, run **H3 Code nightly** with **Publish the verified packages** selected. Set the repository variable `H3_PUBLISH_NIGHTLIES` to `true` to enable automatic releases.

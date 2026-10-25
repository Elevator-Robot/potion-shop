# Publishing Potion Shop to itch.io

The `Build and publish to itch.io` GitHub Actions workflow uses **Godot 4.7.2**,
matching the project's validated engine version. Pull requests run the complete
headless checks (including native ENet co-op), export a single-threaded Web build,
and smoke-test that export in Chromium. A `potion-shop-web` artifact and browser
screenshots/logs in `potion-shop-web-smoke` are retained for 14 days. Pull requests
never publish. The browser smoke checks startup/runtime errors and exercises solo
input and repeat launch; its screenshots still need visual review for appearance.

Once the configuration below is in place and the workflow is merged, **every
push to `main` publishes the checked build to the `html5` channel**. Other branches
cannot publish. `Actions → Build and publish to itch.io → Run workflow` can also
build manually; publishing requires selecting `main` and checking **Publish to
itch.io**. Leave that option unchecked for an artifact-only build.

## One-time setup

1. Confirm the exact Potion Shop page on itch.io. Create it yourself if it does
   not exist; do not reuse the Bound Souls page. Set its project type to **HTML**.
2. In this repository's **Settings → Secrets and variables → Actions → Variables**,
   add `POTION_SHOP_ITCHIO_TARGET` with the verified `username/game-slug` value.
   Do not include `https://`, `.itch.io`, or `:html5`. This deliberately does not
   reuse another game's `ITCHIO_USERNAME` / `ITCHIO_GAME` secrets.
3. Under **Secrets**, add `ITCHIO_API_KEY` with an itch.io API key authorized to
   publish that page. Configure the credential directly in GitHub; never commit
   it or paste it into an issue, pull request, or chat. A key in another repository
   is not automatically available here. Review any organization-secret access
   explicitly before granting this repository access.
4. Review and merge the workflow only when ready for automatic publishing.
   Missing configuration fails the publish job without uploading anything; the
   successful build artifact is still available.
5. After the first upload, edit the itch.io page's upload settings and mark the
   `html5` upload as **This file will be played in the browser**. Set an appropriate
   embed size (1152 × 864 is a good starting point). Save and test the page. Butler
   updates this same channel on subsequent main-branch pushes.

The workflow does not create an itch.io page, change its visibility, or provision
credentials. Destination and credential setup are explicit, separate actions.
The upload is labeled with its exact Git commit SHA for traceability. Only the
isolated upload step receives the credential; build/test steps and PRs do not.
Godot, its templates, Butler, and GitHub Actions are pinned; downloaded binaries
are checksum-verified before execution. When updating Godot, update both asset
checksums and the version in the workflow together.

## Browser versus desktop

The browser export supports **Play Solo**. The menu hides the native Host/Join
controls and explains the limitation; session entry points also reject those
operations on the Web. Native Godot play retains two-player ENet co-op unchanged.
Browsers cannot use ENet/UDP; browser co-op would require a separate transport
project, not a publishing setting. Single-threaded Web export avoids the
cross-origin-isolation headers otherwise required for SharedArrayBuffer.

## Local verification

Install Godot **4.7.2** and its matching export templates, then run:

```sh
python3 tools/check.py --network
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
python3 -m http.server --directory build/web 8000
```

Open `http://localhost:8000` in a WebGL 2-capable browser. Confirm that only solo
play is offered, click Play Solo, move with WASD/arrows, open/close recipes with R,
and use Esc to return to the menu and start again. Check the browser console for
errors. Do not test by opening `index.html` directly as a `file://` URL.

An artifact export passing is not proof that itch.io has accepted or finished
processing an upload. Verify the workflow's publish job and then load the actual
game page after enabling the pipeline.

References: [Godot Web export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html),
[Butler pushes](https://itch.io/docs/butler/pushing.html),
[itch.io HTML5 games](https://itch.io/docs/creators/html5).

# Repository Rulesets

These JSON files are version-controlled copies of the GitHub repository rulesets that protect this repo. They cannot be
applied while the repository is private on a free-tier account — GitHub limits rulesets to public repos or paid (GitHub
Pro / Team / Enterprise) tiers.

The repo ships **PRIVATE** through v0.1.0 by design (see the master plan). Rulesets must be applied immediately after
the visibility flip, before any post-flip pushes.

## Files

| File                | Target            | Effect                                                                                                                                                                            |
| ------------------- | ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `protect-main.json` | `refs/heads/main` | Block direct creation/deletion/force-push; require PR with CODEOWNERS review, signed commits, linear history, and `markdownlint` + `shellcheck` status checks. Squash-only merge. |
| `protect-dev.json`  | `refs/heads/dev`  | Block deletion/force-push; require signed commits. Light-touch by design — `dev` is the integration branch.                                                                       |
| `protect-tags.json` | `refs/tags/v*`    | Block deletion, force-push (re-tag), and updates of release tags. Tags are immutable historical anchors that the site's `install.json` pins to.                                   |

## Apply (after visibility flip)

```bash
gh api repos/brettdavies/agentnative-skill/rulesets -X POST \
  --input .github/rulesets/protect-main.json

gh api repos/brettdavies/agentnative-skill/rulesets -X POST \
  --input .github/rulesets/protect-dev.json

gh api repos/brettdavies/agentnative-skill/rulesets -X POST \
  --input .github/rulesets/protect-tags.json
```

## Verify

```bash
gh api repos/brettdavies/agentnative-skill/rulesets --jq '.[].name'
# expected: Protect main, Protect dev, Protect release tags

# negative test — force-push to main must be refused
git checkout main
git commit --allow-empty -m "test: should be rejected"
git push origin main      # expected: refused by ruleset
git reset --hard HEAD~1   # back out the local test commit

# negative test — re-tagging an existing release tag must be refused
git tag -f v0.1.0
git push --force origin v0.1.0   # expected: refused by ruleset
```

## Bypass

`actor_id: 5` (`RepositoryRole`) corresponds to repo admins, who retain bypass for emergency hotfixes and the visibility
flip itself.

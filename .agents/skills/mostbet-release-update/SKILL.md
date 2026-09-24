---
name: mostbet-release-update
description: Integrate selected Mostbet task branches into a release-ssr branch, validate it, and publish when requested.
---

# Mostbet release update

Use for release preparation in `~/Developer/Dats.Team/mostbet-next`. The release branch, Jira keys or URLs, dates, revisions, runtime, and warning counts are live inputs. Work in the main checkout one branch at a time; do not delegate or create worktrees, and preserve pre-existing worktrees.

## Contract and inputs

Read applicable repository guides and `$mostbet` routing. Before any Dats.Team request, run the Jira reachability preflight from [dats-team.md](../../references/dats-team.md); use Jira MCP for task confirmation and authenticated `glab` for matching MRs. Record branch, HEAD, clean/dirty state, worktrees, and local/remote heads. Do not stash or overwrite user changes. Fetch refs and resolve each source branch from its actual MR/ref. Use the exact supplied release branch; if it is absent remotely, ask for its starting point. Detect already integrated changes, including squashed or cherry-picked equivalents.

Local-only integration or validation stays local. Release preparation includes validation and publication of the selected task and release branches under the shared autonomy policy, unless the user explicitly limits it to local work. Do not approve or merge MRs, change Jira state, or message anyone as incidental work.

## Prepare task branches

Pin one `origin/master` SHA as the batch base. For each source, use a clean equal or fast-forwardable local branch; preserve unpublished local commits. If a branch diverged or is checked out elsewhere, prepare from the remote head at detached HEAD and record the prepared SHA outside tracked files; do not reset or rewrite the local branch. Merge pinned master when needed, keep hooks enabled, and use repository-compliant task merge messages. Resolve ordinary conflicts from instructions, both versions, history, and callers; follow renames or modify/delete targets instead of resurrecting obsolete paths. Verify the remote task head and pinned master are ancestors of the prepared SHA.

## Assemble and validate

Switch to the clean release branch and synchronize safely, preserving unexplained local-only release commits. Merge prepared task heads one by one, then verify the final head contains pinned master, every task head, and the original release head. Audit the net diff and record the exact release SHA.

Use the configured `mise` Node runtime and current package scripts. Install dependencies once only when changed manifests, lockfiles, or hooks require it. Run full release lint first with a fresh task-owned cache; wait for it to finish. Only after successful lint run `npm run build` alone and wait for complete finalization. Do not add e2e runs or CI polling unless requested or needed for an unresolved conflict. Fix attributable integration errors minimally and rerun affected checks; a failed check blocks push. Restore only proven build-generated tracked drift, and rerun relevant checks if source, dependencies, or build configuration changes.

## Publish and finish

For publication, immediately before pushing refresh selected refs, compare remote heads with recorded starts, confirm fast-forward ancestry, and revalidate after integrating any concurrent update. Push prepared task SHAs sequentially, then the validated release SHA, with explicit non-force refspecs. Read back and compare all remote SHAs. If publication is outside scope, retain validated branches locally and report that state.

Apply `$dats-team-cleanup` to task-owned resources and restore the main checkout to its default branch when clean, unless another final branch was requested. Apply [unslop](../unslop/SKILL.md) to explain which changes are included, whether the release is prepared or published, and the completed validation results. Use descriptive release/MR links and keep exact SHAs and command adjustments in working records unless the reader needs them for a specific action. Mention a blocker when it prevents the requested outcome. Local completion requires successful sequential lint and build; published completion also requires verified remote refs for that validated release.

# SETUP PACKET — <project-slug> — HANDOFF v<N>

Goal: prove the build environment works before the build loop starts (G2 exit). Heimdall never handles credentials: every sign-in below is done by the user.

1. **Repository:** <create or open the repository>; default branch <name>; integration branch <name>.
2. **Tracker sign-in:** <GitHub: `gh auth login`, then `gh auth status` | Gitea: `tea login add --name <name> --url https://<host>` (token created in the Gitea web UI), then `tea login list` | local: nothing>.
3. **Executor harnesses:** for each harness in the topology: <name and version>; install or update with <official command>; sign in with <how>.
4. **Model pins:** <role → model id at effort level>; set with <flag or config key per harness (agent-model-map.md)>.
5. **Containers (if the project needs services such as a test database):** use podman, never Docker: `podman --version`; services run with `podman run …` or `podman compose up`.
6. **Hello-world per dispatch method:** create the worktree root and a scratch worktree (`git worktree add -b heimdall/hello <worktree-root>/hello <integration-branch>`) and a one-line script `.heimdall/packets/hello.sh` (`echo hello-ok`). For each role's dispatch method, dispatch this task with that role's grants (harness-adapters.md): "print the first line of `<main checkout>/.heimdall/HANDOFF.md`, write `hello.txt` in your working directory and commit it, run `bash <main checkout>/.heimdall/packets/hello.sh`, print `git rev-parse --show-toplevel`, and stop." Confirm every step succeeded in `<worktree-root>/hello` with the pinned model, then remove the worktree and branch (`git worktree remove --force <worktree-root>/hello`, `git branch -D heimdall/hello`). A denied step names the missing grant.
7. **Report back:** "setup OK" with each harness version, model, and the tracker account in use — or the exact error text.

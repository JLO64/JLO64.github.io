---
name: serve
description: Start the local Jekyll development server and open the site via a Rodney browser session. Use when you need to preview the site locally or inspect pages in a browser.
argument-hint: [page-path]
allowed-tools: Bash
---

Start the local Jekyll development server and open the site with Rodney.

## Steps

1. Check if Jekyll is already running on port 4000:
   ```
   lsof -ti :4000
   ```
   If a process is found, skip to step 3.

2. Start the Jekyll server in the background and wait for it to be ready:
   ```
   bundle exec jekyll serve --port 4000
   ```
   Wait until the output contains `Server running... press ctrl-c to stop.` before continuing.

3. Check if a local Rodney session exists by looking for `.rodney/state.json`:
   - If it does not exist: `uvx rodney start --local`
   - If it exists, the session is already active — skip this step.

4. Determine the URL to open. If $ARGUMENTS is provided, open `http://127.0.0.1:4000/$ARGUMENTS`. Otherwise open `http://127.0.0.1:4000`.

5. Navigate to the page and wait for it to load:
   ```
   uvx rodney --local open <url>
   uvx rodney --local waitload
   ```

6. Confirm by printing the page title:
   ```
   uvx rodney --local title
   ```

7. Report back that the site is live and the Rodney session is ready.

## Notes

- Always use `--local` with every Rodney command so the session is scoped to this project.
- The `.rodney/` directory is gitignored and excluded from Jekyll's watch list — do not remove those exclusions.
- To stop everything when done: `pkill -f "jekyll serve"` then `uvx rodney --local stop`.

# Monty-Ledger — Extract to Own Repo When Ready

This directory is the Monty-Ledger personal knowledge vault. It lives
inside Monty-CNS temporarily because the separate private repo
(`ezmonty/Monty-Ledger`) hasn't been created yet.

## When you're ready to extract

```bash
# 1. Create the private repo on GitHub
gh repo create ezmonty/Monty-Ledger --private

# 2. Push this directory's contents as the initial commit
cd monty-ledger
git init
git add -A
git commit -m "Initial commit: Monty-Ledger vault"
git remote add origin git@github.com:ezmonty/Monty-Ledger.git
git push -u origin main

# 3. Remove from Monty-CNS and leave a pointer
cd ..
git rm -r monty-ledger/
echo "Extracted to github.com/ezmonty/Monty-Ledger" > monty-ledger-pointer.md
git add monty-ledger-pointer.md
git commit -m "chore: extract Monty-Ledger to own repo"
```

## Until then

The vault works fine here. Obsidian can open this directory directly.
The filesystem MCP server is wired to read it. The Postgres sync
script works from any location.

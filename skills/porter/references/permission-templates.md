# Permission Templates

## Read-Only Agent
```yaml
permissions:
  read: allow
  grep: allow
  glob: allow
  edit: deny
  write: deny
  bash: deny
```

## Standard Dev Agent
```yaml
permissions:
  read: allow
  grep: allow
  glob: allow
  edit: ask
  write: ask
  bash:
    "git diff*": allow
    "git log*": allow
    "git status": allow
    "git branch*": allow
    "ls*": allow
    "find*": allow
    "grep*": allow
    "cat*": allow
    "npm test*": allow
    "npm run lint*": allow
    "go test*": allow
    "cargo test*": allow
    "rm -rf*": deny
    "rm -r /": deny
    "git push --force*": deny
    "git reset --hard*": deny
    "chmod 777*": deny
    "*": ask
```

## Security Reviewer (Strict)
```yaml
permissions:
  read: allow
  grep: allow
  glob: allow
  edit: deny
  write: deny
  bash:
    "git diff*": allow
    "git log*": allow
    "git status": allow
    "grep*": allow
    "find*": allow
    "*": deny
```

## Creative/Documentation Agent
```yaml
permissions:
  read: allow
  grep: allow
  glob: allow
  edit: ask
  write: ask
  bash: deny
```

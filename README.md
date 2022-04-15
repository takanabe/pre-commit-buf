# pre-commit-buf

A pre-commit hook for https://github.com/bufbuild/buf. 
This pre-commit hook automatically install specified version of buf for earch operating system and processor architecture.

## Usage

Add the following config to your `.pre-commit-config.yaml`.


```
repos:
  - repo: https://github.com/takanabe/pre-commit-buf
    rev: main
    hooks:
      - id: buf-format
```

## Note

This pre-commit hook does not use `docker_image` pre-commit language intentionally 
because buf tries to create a new directory `/.cache` which need root user permission when we run `pre-commit run`. 

So, this pre-commit hook install `buf` from https://github.com/bufbuild/buf/releases automatically.

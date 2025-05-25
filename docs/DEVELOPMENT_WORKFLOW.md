# Development Workflow for CodexContinue

This document outlines the recommended workflow for adding new features to CodexContinue.

## Branching Strategy

We use a feature branch workflow:

1. All new features are developed in dedicated feature branches
2. The `main` branch always contains stable, production-ready code
3. Feature branches are merged back to `main` via pull requests

## Workflow Steps

### 1. Starting a New Feature

```bash
# Ensure you're on the main branch and it's up to date
git checkout main
git pull

# Create a new feature branch with a descriptive name
git checkout -b feature/your-feature-name
```

### 2. During Development

Commit your changes frequently with descriptive commit messages:

```bash
git add .
git commit -m "Descriptive message about what you changed"
```

Run tests to ensure your changes don't break existing functionality:

```bash
# Run the validation scripts
./scripts/verify-youtube-transcription.py
# Or use docker-compose to run tests
docker compose exec ml-service python -m pytest
```

### 3. Finishing a Feature

Before submitting your changes:

1. Clean up any temporary files:
   ```bash
   ./scripts/cleanup-root-files.sh
   ```

2. Ensure all tests pass:
   ```bash
   # Run all tests
   docker compose exec ml-service python -m pytest
   ```

3. Push your branch to the remote repository:
   ```bash
   git push -u origin feature/your-feature-name
   ```

4. Create a pull request:
   - Use the pull request template
   - Describe the changes you've made
   - Link to any relevant issues

### 4. Merging a Feature

After your pull request has been reviewed and approved:

1. Merge your feature branch into main:
   ```bash
   git checkout main
   git pull
   git merge feature/your-feature-name
   git push
   ```

2. Delete the feature branch:
   ```bash
   git branch -d feature/your-feature-name
   git push origin --delete feature/your-feature-name
   ```

## Best Practices

1. **Keep feature branches short-lived**: Try to complete features within 1-2 weeks
2. **Commit frequently**: Small, focused commits make review easier
3. **Write descriptive commit messages**: Explain what and why, not how
4. **Keep the repository clean**: Remove temporary files and logs
5. **Update documentation**: Keep documentation in sync with code changes
6. **Add tests**: Every feature should have accompanying tests

## Code Style and Standards

- Follow PEP 8 style guide for Python code
- Use meaningful variable and function names
- Comment your code where necessary
- Add docstrings to all functions and classes

## Troubleshooting

If you encounter issues:

1. Check the troubleshooting guide in `docs/troubleshooting-guide.md`
2. Run the diagnostic scripts:
   ```bash
   ./scripts/diagnose-services.sh
   ```

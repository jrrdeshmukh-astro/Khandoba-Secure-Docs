# Development Checklist

> Quick checklist for development tasks

---

## Initial Setup

- [ ] Run `./scripts/setup_dev_environment.sh` to verify environment
- [ ] Review `docs/DEVELOPMENT_ENVIRONMENT.md`
- [ ] Review `docs/FEATURE_PARITY_ROADMAP.md`
- [ ] Review `docs/WORKFLOW_IMPROVEMENTS.md`
- [ ] Choose target platform(s)
- [ ] Complete platform-specific setup (see platform setup guides)

---

## Before Starting Work

- [ ] Review feature parity status: `docs/FEATURE_PARITY.md`
- [ ] Identify feature gaps or workflow issues
- [ ] Review implementation notes: `docs/IMPLEMENTATION_NOTES.md`
- [ ] Check platform-specific notes: `docs/{platform}/IMPLEMENTATION_NOTES.md`
- [ ] Understand architecture: `docs/shared/architecture/COMPLETE_SYSTEM_ARCHITECTURE.md`

---

## Feature Development

### Planning

- [ ] Identify feature to implement/improve
- [ ] Review source platform implementation (if porting)
- [ ] Understand requirements
- [ ] Plan implementation approach
- [ ] Identify dependencies

### Implementation

- [ ] Follow platform patterns (MVVM, service layer)
- [ ] Implement feature
- [ ] Add error handling
- [ ] Add logging for debugging
- [ ] Follow code conventions

### Testing

- [ ] Unit tests (if applicable)
- [ ] Integration tests (if applicable)
- [ ] Manual testing on device/emulator
- [ ] Test error cases
- [ ] Test cross-platform sync (if applicable)

### Documentation

- [ ] Update implementation notes
- [ ] Update feature parity document
- [ ] Add code comments for complex logic
- [ ] Update README if needed

---

## Feature Parity Work

- [ ] Check `docs/FEATURE_PARITY.md` for gaps
- [ ] Review source platform: `docs/{source_platform}/IMPLEMENTATION_NOTES.md`
- [ ] Review target platform: `docs/{target_platform}/IMPLEMENTATION_NOTES.md`
- [ ] Plan adaptation strategy
- [ ] Implement feature on target platform
- [ ] Test feature works correctly
- [ ] Test cross-platform sync
- [ ] Update feature parity document
- [ ] Update platform implementation notes

---

## Workflow Improvements

- [ ] Identify workflow pain point
- [ ] Research solutions
- [ ] Plan improvement
- [ ] Implement improvement
- [ ] Document new workflow
- [ ] Update `docs/WORKFLOW_IMPROVEMENTS.md` if needed

---

## Before Committing

- [ ] Code follows platform conventions
- [ ] No hardcoded values
- [ ] Error handling comprehensive
- [ ] Logging added for debugging
- [ ] Tests pass (if applicable)
- [ ] Documentation updated
- [ ] Feature parity updated (if applicable)
- [ ] Build succeeds
- [ ] No linter errors (if applicable)

---

## Cross-Platform Sync Testing

- [ ] Create vault on Platform A
- [ ] Verify appears on Platform B
- [ ] Upload document on Platform B
- [ ] Verify appears on Platform A
- [ ] Update document on Platform A
- [ ] Verify update on Platform B
- [ ] Test deletion
- [ ] Test concurrent edits (if applicable)

---

## Release Checklist

- [ ] All features tested
- [ ] Cross-platform sync verified
- [ ] Documentation updated
- [ ] Version numbers updated
- [ ] Build scripts tested
- [ ] Production config verified
- [ ] Release notes prepared

---

**Quick Links:**
- [Development Environment](DEVELOPMENT_ENVIRONMENT.md)
- [Feature Parity Roadmap](FEATURE_PARITY_ROADMAP.md)
- [Workflow Improvements](WORKFLOW_IMPROVEMENTS.md)
- [Implementation Notes](IMPLEMENTATION_NOTES.md)

---

**Last Updated:** December 2024

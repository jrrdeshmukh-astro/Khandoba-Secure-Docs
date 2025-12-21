# Mock Data for Testing

This directory contains mock data used across all platform tests to ensure:
- Consistent test results
- No external dependencies
- Fast test execution
- Privacy compliance

## Structure

```
mock_data/
├── documents/          # Sample document data
├── vaults/            # Sample vault data
├── users/             # Sample user data
├── access_logs/       # Sample access log data
└── ml_results/       # Sample ML analysis results
```

## Usage

All test files should use mock data from this directory rather than generating random data or using real data.


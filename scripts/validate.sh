#!/usr/bin/env bash
# Local validation script for Quantus Node 5tratumOS app

set -euo pipefail

echo "=== Quantus Node App Validation ==="

# Check required files exist
echo "Checking required files..."
for f in 5tratstore-app.yml 5tratstore-review.yml LICENSES.md docker-compose.yml icon.png README.md; do
    if [ -f "$f" ]; then
        echo "  OK: $f"
    else
        echo "  MISSING: $f"
        exit 1
    fi
done

# Check Dockerfiles exist
echo "Checking Dockerfiles..."
for f in node/Dockerfile; do
    if [ -f "$f" ]; then
        echo "  OK: $f"
    else
        echo "  MISSING: $f"
        exit 1
    fi
done

# Check for placeholder values
echo "Checking for placeholder values..."
if grep -r "replace-me" . --include="*.yml" --include="*.yaml" 2>/dev/null; then
    echo "  WARNING: Found placeholder values"
else
    echo "  OK: No placeholders found"
fi

# Check for fake digests
echo "Checking for fake digests..."
if grep -r "sha256:replace-me" . --include="*.yml" --include="*.yaml" 2>/dev/null; then
    echo "  WARNING: Found fake digests"
else
    echo "  OK: No fake digests found"
fi

echo ""
echo "=== Validation Complete ==="

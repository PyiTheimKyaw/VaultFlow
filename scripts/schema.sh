#!/usr/bin/env bash
# Records the current Drift schema so future migrations can be tested from
# every version ever shipped. Run after changing tables and bumping
# VaultFlowDatabase.currentSchemaVersion; commit the results.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../packages/vf_database"
dart run drift_dev schema dump lib/src/database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/generated/
dart format test/generated
echo "schema recorded; run: flutter test test/migration_test.dart"

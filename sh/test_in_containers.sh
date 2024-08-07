
test_in_containers()
{
  local -r USER="${ALPHA_USER}"                     # eg nobody
  local -r CONTAINER_NAME="${ALPHA_CONTAINER_NAME}" # eg alpha_server

  echo '=================================='
  echo "Running alpha tests"
  echo '=================================='

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Run tests (with branch coverage) inside the container.

  local -r COVERAGE_CODE_TAB_NAME=code
  local -r COVERAGE_TEST_TAB_NAME=test
  local -r CONTAINER_COVERAGE_DIR="/app/test/reports"
  local -r TEST_LOG=test.log

  set +e
  docker exec \
    --env COVERAGE_CODE_TAB_NAME=${COVERAGE_CODE_TAB_NAME} \
    --env COVERAGE_TEST_TAB_NAME=${COVERAGE_TEST_TAB_NAME} \
    --user "${USER}" \
    "${CONTAINER_NAME}" \
      sh -c "/app/test/lib/run.sh ${CONTAINER_COVERAGE_DIR} ${TEST_LOG} ${*:3}"

  local STATUS=$?
  set -e

  local -r HOST_TEST_DIR="${ROOT_DIR}/test"

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # Tell caller where the test info is...
  local -r HOST_REPORTS_DIR="${HOST_TEST_DIR}/reports"
  local -r COVERAGE_JSON_FILE="${HOST_REPORTS_DIR}/coverage.json"
  echo
  echo "alpha test branch-coverage report is at: ${HOST_REPORTS_DIR}/index.html"
  echo "alpha test branch-coverage stats are at: ${COVERAGE_JSON_FILE}"
  echo

  if [ "${STATUS}" != "0" ]; then
    echo ">>>> test status != 0    (${STATUS})"
  fi

  local -r code_branches_missed="$(jq '.groups.code.branches.missed' "${COVERAGE_JSON_FILE}")"
  if [ "${code_branches_missed}" != "0" ]; then
    echo ">>>> .groups.code.branches.missed != 0    (${code_branches_missed})"
    STATUS=1
  fi
  local -r code_lines_missed="$(jq '.groups.code.lines.missed' "${COVERAGE_JSON_FILE}")"
  if [ "${code_lines_missed}" != "0" ]; then
    echo ">>>> .groups.code.lines.missed != 0    (${code_lines_missed})"
    STATUS=1
  fi

  local -r test_branches_missed="$(jq '.groups.test.branches.missed' "${COVERAGE_JSON_FILE}")"
  if [ "${test_branches_missed}" != "0" ]; then
    echo ">>>> .groups.test.branches.missed != 0    (${test_branches_missed})"
    STATUS=1
  fi
  local -r test_lines_missed="$(jq '.groups.test.lines.missed' "${COVERAGE_JSON_FILE}")"
  if [ "${test_lines_missed}" != "0" ]; then
    echo ">>>> .groups.test.lines.missed != 0    (${test_lines_missed})"
    STATUS=1
  fi

  if [ "${STATUS}" != 0 ]; then
    echo
    echo Docker logs "${CONTAINER_NAME}"
    echo
    docker logs "${CONTAINER_NAME}" 2>&1
  fi
  return ${STATUS}
}

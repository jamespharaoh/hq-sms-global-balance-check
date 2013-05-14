Feature: Cached results

  If the service does not respond for some reason a cached result can be used
  instead. Alerts will be generated if the time since the last check exceeds a
  specified amount.

  Background:

    Given a file "default.config":
      """
      <hq-sms-global-balance-check-config>
        <server url="${server-url}"/>
        <cache dir="cache"/>
        <account name="account" username="USER" password="PASS"/>
      </hq-sms-global-balance-check-config>
      """

    And a file "default.args":
      """
      --config default.config
      --account account
      --warning 500
      --critical 100
      --cache-warning 10
      --cache-critical 20
      """

    And a directory "cache"

    And the balance is 750
    And the time is 100
    And I run the script with "default.args"

  Scenario: Cache ok

    Given the time is 105
    And the server is offline

    When I run the script with "default.args"

    Then the status should be 0
    And the output should be:
      """
      SMS Global account OK: 750 credits, last check 5 seconds ago
      """

  Scenario: Cache warning

    Given the time is 115
    And the server is offline

    When I run the script with "default.args"

    Then the status should be 1
    And the output should be:
      """
      SMS Global account WARNING: 750 credits, last check 15 seconds ago (warning is 10)
      """

  Scenario: Cache critical

    Given the time is 125
    And the server is offline

    When I run the script with "default.args"

    Then the status should be 2
    And the output should be:
      """
      SMS Global account CRITICAL: 750 credits, last check 25 seconds ago (critical is 20)
      """

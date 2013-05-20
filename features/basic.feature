Feature: Basic functionality

  Background:

    Given a file "default.config":
      """
      <hq-sms-global-balance-check-config>
        <server url="${server-url}"/>
        <account name="account" username="USER" password="PASS"/>
      </hq-sms-global-balance-check-config>
      """

    Given a file "default.args":
      """
      --config default.config
      --account account
      --warning 500
      --critical 100
      --timeout 10
      """

    Given a file "timeout.args":
      """
      --config default.config
      --account account
      --warning 500
      --critical 100
      --timeout 0
      """

  Scenario: Balance ok

    Given the balance is 750

    When I run the script with "default.args"

    Then the status should be 0
    And the output should be:
      """
      SMS Global account OK: 750 credits
      """

  Scenario: Balance warning

    Given the balance is 250

    When I run the script with "default.args"

    Then the status should be 1
    And the output should be:
      """
      SMS Global account WARNING: 250 credits (warning is 500)
      """

  Scenario: Balance critical

    Given the balance is 50

    When I run the script with "default.args"

    Then the status should be 2
    And the output should be:
      """
      SMS Global account CRITICAL: 50 credits (critical is 100)
      """

  Scenario: Read timeout

    Given the server is slow to respond

    When I run the script with "timeout.args"

    Then the status should be 3
    And the output should be:
      """
      SMS Global account UNKNOWN: server timed out
      """

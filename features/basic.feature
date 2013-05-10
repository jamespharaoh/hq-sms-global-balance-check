Feature: Basic functionality

  Background:

    Given a file "default.config":
      """
      <hq-sms-global-balance-check-config>
        <server url="${server-url}"/>
        <account name="account" username="USER" password="PASS"/>
      </hq-sms-global-balance-check-config>
      """

  Scenario: Balance ok

    Given that the balance is 750

    When I run the script with args:
      """
      --config default.config
      --account account
      --warning 500
      --critical 100
      """

    Then the status should be 0
    And the output should be:
      """
      SMS Global account OK: 750 credits
      """

  Scenario: Balance warning

    Given that the balance is 250

    When I run the script with args:
      """
      --config default.config
      --account account
      --warning 500
      --critical 100
      """

    Then the status should be 1
    And the output should be:
      """
      SMS Global account WARNING: 250 credits (warning is 500)
      """

  Scenario: Balance critical

    Given that the balance is 50

    When I run the script with args:
      """
      --config default.config
      --account account
      --warning 500
      --critical 100
      """

    Then the status should be 2
    And the output should be:
      """
      SMS Global account CRITICAL: 50 credits (critical is 100)
      """

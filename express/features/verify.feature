Feature: Client Integration Tests
  Scenario: Application Creation
    Given the libra client tools
    When 1 php-5.3 applications are created
    Then the applications should be accessible

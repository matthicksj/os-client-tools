@sanity
Feature: Sanity Check Tests
 Scenario Outline: Application Creation
    Given the libra client tools
    When <app_count> <type> applications are created
    Then the applications should be accessible

  Scenarios: Application Creation Scenarios
    | app_count |     type     |
    |     1     |  php-5.3     |

#  Scenario Outline: Application Modification
#    Given an existing <type> application
#    When the application is changed
#    Then it should be updated successfully
#    And the application should be accessible
#
#  Scenarios: Application Modification Scenarios
#    |      type     |
#    |   php-5.3     |
#    
#  Scenario Outline: Application Restarting
#    Given an existing <type> application
#    When the application is restarted
#    Then the application should be accessible
#
#  Scenarios: Application Restart Scenarios
#    |      type     |
#    |   php-5.3     |
#
#  Scenario Outline: Application Destroying
#    Given an existing <type> application
#    When the application is destroyed
#    Then the application should not be accessible
#
#  Scenarios: Application Destroying Scenarios
#    |      type     |
#    |   php-5.3     |

#
# Copyright (c) 2015-2020 "Neo Technology,"
# Network Engine for Objects in Lund AB [http://neotechnology.com]
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Attribution Notice under the terms of the Apache License 2.0
#
# This work was created by the collective efforts of the openCypher community.
# Without limiting the terms of Section 6, any Derivative Work that is not
# approved by the public consensus process of the openCypher Implementers Group
# should not be described as “Cypher” (and Cypher® is a registered trademark of
# Neo4j Inc.) or as "openCypher". Extensions by implementers or prototypes or
# proposals for change that have been documented or implemented should only be
# described as "implementation extensions to Cypher" or as "proposed changes to
# Cypher that are not yet approved by the openCypher community".
#

#encoding: utf-8

Feature: ProcedureCallAcceptance

  Background:
    Given an empty graph

  Scenario: In-query call to procedure that takes arguments fails when trying to pass them implicitly
    And there exists a procedure test.my.proc(in :: INTEGER?) :: (out :: INTEGER?):
      | in | out |
    When executing query:
      """
      CALL test.my.proc YIELD out
      RETURN out
      """
    Then a SyntaxError should be raised at compile time: InvalidArgumentPassingMode

  Scenario: Standalone call to procedure that takes no arguments
    And there exists a procedure test.labels() :: (label :: STRING?):
      | label |
      | 'A'   |
      | 'B'   |
      | 'C'   |
    When executing query:
      """
      CALL test.labels()
      """
    Then the result should be, in order:
      | label |
      | 'A'   |
      | 'B'   |
      | 'C'   |
    And no side effects

  Scenario: In-query call to procedure that takes no arguments
    And there exists a procedure test.labels() :: (label :: STRING?):
      | label |
      | 'A'   |
      | 'B'   |
      | 'C'   |
    When executing query:
      """
      CALL test.labels() YIELD label
      RETURN label
      """
    Then the result should be, in order:
      | label |
      | 'A'   |
      | 'B'   |
      | 'C'   |
    And no side effects

  Scenario: Calling the same procedure twice using the same outputs in each call
    And there exists a procedure test.labels() :: (label :: STRING?):
      | label |
      | 'A'   |
      | 'B'   |
      | 'C'   |
    When executing query:
      """
      CALL test.labels() YIELD label
      WITH count(*) AS c
      CALL test.labels() YIELD label
      RETURN *
      """
    Then the result should be, in order:
      | c | label |
      | 3 | 'A'   |
      | 3 | 'B'   |
      | 3 | 'C'   |
    And no side effects

  Scenario: Standalone call to VOID procedure that takes no arguments
    And there exists a procedure test.doNothing() :: VOID:
      |
    When executing query:
      """
      CALL test.doNothing()
      """
    Then the result should be empty
    And no side effects

  Scenario: In-query call to VOID procedure that takes no arguments
    And there exists a procedure test.doNothing() :: VOID:
      |
    When executing query:
      """
      MATCH (n)
      CALL test.doNothing()
      RETURN n
      """
    Then the result should be, in any order:
      | n |
    And no side effects

  Scenario: In-query call to VOID procedure does not consume rows
    And there exists a procedure test.doNothing() :: VOID:
      |
    And having executed:
      """
      CREATE (:A {name: 'a'})
      CREATE (:B {name: 'b'})
      CREATE (:C {name: 'c'})
      """
    When executing query:
      """
      MATCH (n)
      CALL test.doNothing()
      RETURN n.name AS `name`
      """
    Then the result should be, in any order:
      | name |
      | 'a'  |
      | 'b'  |
      | 'c'  |
    And no side effects

  Scenario: Standalone call to VOID procedure that takes no arguments, called with implicit arguments
    And there exists a procedure test.doNothing() :: VOID:
      |
    When executing query:
      """
      CALL test.doNothing
      """
    Then the result should be empty
    And no side effects

  Scenario: In-query call to procedure that takes no arguments and yields no results
    And there exists a procedure test.doNothing() :: ():
      |
    When executing query:
      """
      CALL test.doNothing() YIELD - RETURN 1
      """
    Then the result should be, in any order:
      | 1 |
    And no side effects

  Scenario: Standalone call to procedure that takes no arguments and yields no results
    And there exists a procedure test.doNothing() :: ():
      |
    When executing query:
      """
      CALL test.doNothing()
      """
    Then the result should be empty
    And no side effects

  Scenario: Standalone call to procedure that takes no arguments and yields no results, called with implicit arguments
    And there exists a procedure test.doNothing() :: ():
      |
    When executing query:
      """
      CALL test.doNothing
      """
    Then the result should be empty
    And no side effects

  Scenario: In-query call to procedure with explicit arguments
    And there exists a procedure test.my.proc(name :: STRING?, id :: INTEGER?) :: (city :: STRING?, country_code :: INTEGER?):
      | name     | id | city      | country_code |
      | 'Andres' | 1  | 'Malmö'   | 46           |
      | 'Tobias' | 1  | 'Malmö'   | 46           |
      | 'Mats'   | 1  | 'Malmö'   | 46           |
      | 'Stefan' | 1  | 'Berlin'  | 49           |
      | 'Stefan' | 2  | 'München' | 49           |
      | 'Petra'  | 1  | 'London'  | 44           |
    When executing query:
      """
      CALL test.my.proc('Stefan', 1) YIELD city, country_code
      RETURN city, country_code
      """
    Then the result should be, in order:
      | city     | country_code |
      | 'Berlin' | 49           |
    And no side effects

  Scenario: In-query call to procedure with explicit arguments that drops all result fields
    And there exists a procedure test.my.proc(name :: STRING?, id :: INTEGER?) :: (city :: STRING?, country_code :: INTEGER?):
      | name     | id | city      | country_code |
      | 'Andres' | 1  | 'Malmö'   | 46           |
      | 'Tobias' | 1  | 'Malmö'   | 46           |
      | 'Mats'   | 1  | 'Malmö'   | 46           |
      | 'Stefan' | 1  | 'Berlin'  | 49           |
      | 'Stefan' | 2  | 'München' | 49           |
      | 'Petra'  | 1  | 'London'  | 44           |
    When executing query:
      """
      WITH 'Stefan' AS name, 1 AS id
      CALL test.my.proc(name, id) YIELD -
      RETURN name, id, count(*) AS count
      """
    Then the result should be, in order:
      | name     | id | count |
      | 'Stefan' | 1  | 1     |
    And no side effects

  Scenario: Standalone call to procedure with explicit arguments
    And there exists a procedure test.my.proc(name :: STRING?, id :: INTEGER?) :: (city :: STRING?, country_code :: INTEGER?):
      | name     | id | city      | country_code |
      | 'Andres' | 1  | 'Malmö'   | 46           |
      | 'Tobias' | 1  | 'Malmö'   | 46           |
      | 'Mats'   | 1  | 'Malmö'   | 46           |
      | 'Stefan' | 1  | 'Berlin'  | 49           |
      | 'Stefan' | 2  | 'München' | 49           |
      | 'Petra'  | 1  | 'London'  | 44           |
    When executing query:
      """
      CALL test.my.proc('Stefan', 1)
      """
    Then the result should be, in order:
      | city     | country_code |
      | 'Berlin' | 49           |
    And no side effects

  Scenario: Standalone call to procedure with implicit arguments
    And there exists a procedure test.my.proc(name :: STRING?, id :: INTEGER?) :: (city :: STRING?, country_code :: INTEGER?):
      | name     | id | city      | country_code |
      | 'Andres' | 1  | 'Malmö'   | 46           |
      | 'Tobias' | 1  | 'Malmö'   | 46           |
      | 'Mats'   | 1  | 'Malmö'   | 46           |
      | 'Stefan' | 1  | 'Berlin'  | 49           |
      | 'Stefan' | 2  | 'München' | 49           |
      | 'Petra'  | 1  | 'London'  | 44           |
    And parameters are:
      | name | 'Stefan' |
      | id   | 1        |
    When executing query:
      """
      CALL test.my.proc
      """
    Then the result should be, in order:
      | city     | country_code |
      | 'Berlin' | 49           |
    And no side effects

  Scenario: Standalone call to procedure with argument of type NUMBER accepts value of type INTEGER
    And there exists a procedure test.my.proc(in :: NUMBER?) :: (out :: STRING?):
      | in   | out           |
      | 42   | 'wisdom'      |
      | 42.3 | 'about right' |
    When executing query:
      """
      CALL test.my.proc(42)
      """
    Then the result should be, in order:
      | out      |
      | 'wisdom' |
    And no side effects

  Scenario: In-query call to procedure with argument of type NUMBER accepts value of type INTEGER
    And there exists a procedure test.my.proc(in :: NUMBER?) :: (out :: STRING?):
      | in   | out           |
      | 42   | 'wisdom'      |
      | 42.3 | 'about right' |
    When executing query:
      """
      CALL test.my.proc(42) YIELD out
      RETURN out
      """
    Then the result should be, in order:
      | out      |
      | 'wisdom' |
    And no side effects

  Scenario: Standalone call to procedure with argument of type NUMBER accepts value of type FLOAT
    And there exists a procedure test.my.proc(in :: NUMBER?) :: (out :: STRING?):
      | in   | out           |
      | 42   | 'wisdom'      |
      | 42.3 | 'about right' |
    When executing query:
      """
      CALL test.my.proc(42.3)
      """
    Then the result should be, in order:
      | out           |
      | 'about right' |
    And no side effects

  Scenario: In-query call to procedure with argument of type NUMBER accepts value of type FLOAT
    And there exists a procedure test.my.proc(in :: NUMBER?) :: (out :: STRING?):
      | in   | out           |
      | 42   | 'wisdom'      |
      | 42.3 | 'about right' |
    When executing query:
      """
      CALL test.my.proc(42.3) YIELD out
      RETURN out
      """
    Then the result should be, in order:
      | out           |
      | 'about right' |
    And no side effects

  Scenario: Standalone call to procedure with argument of type FLOAT accepts value of type INTEGER
    And there exists a procedure test.my.proc(in :: FLOAT?) :: (out :: STRING?):
      | in   | out            |
      | 42.0 | 'close enough' |
    When executing query:
      """
      CALL test.my.proc(42)
      """
    Then the result should be, in order:
      | out            |
      | 'close enough' |
    And no side effects

  Scenario: In-query call to procedure with argument of type FLOAT accepts value of type INTEGER
    And there exists a procedure test.my.proc(in :: FLOAT?) :: (out :: STRING?):
      | in   | out            |
      | 42.0 | 'close enough' |
    When executing query:
      """
      CALL test.my.proc(42) YIELD out
      RETURN out
      """
    Then the result should be, in order:
      | out            |
      | 'close enough' |
    And no side effects

  Scenario: Standalone call to procedure with argument of type INTEGER accepts value of type FLOAT
    And there exists a procedure test.my.proc(in :: INTEGER?) :: (out :: STRING?):
      | in | out            |
      | 42 | 'close enough' |
    When executing query:
      """
      CALL test.my.proc(42.0)
      """
    Then the result should be, in order:
      | out            |
      | 'close enough' |
    And no side effects

  Scenario: In-query call to procedure with argument of type INTEGER accepts value of type FLOAT
    And there exists a procedure test.my.proc(in :: INTEGER?) :: (out :: STRING?):
      | in | out            |
      | 42 | 'close enough' |
    When executing query:
      """
      CALL test.my.proc(42.0) YIELD out
      RETURN out
      """
    Then the result should be, in order:
      | out            |
      | 'close enough' |
    And no side effects

  Scenario: Standalone call to procedure with null argument
    And there exists a procedure test.my.proc(in :: INTEGER?) :: (out :: STRING?):
      | in   | out   |
      | null | 'nix' |
    When executing query:
      """
      CALL test.my.proc(null)
      """
    Then the result should be, in order:
      | out   |
      | 'nix' |
    And no side effects

  Scenario: In-query call to procedure with null argument
    And there exists a procedure test.my.proc(in :: INTEGER?) :: (out :: STRING?):
      | in   | out   |
      | null | 'nix' |
    When executing query:
      """
      CALL test.my.proc(null) YIELD out
      RETURN out
      """
    Then the result should be, in order:
      | out   |
      | 'nix' |
    And no side effects

  Scenario: Standalone call to procedure should fail if input type is wrong
    And there exists a procedure test.my.proc(in :: INTEGER?) :: (out :: INTEGER?):
      | in | out |
    When executing query:
      """
      CALL test.my.proc(true)
      """
    Then a SyntaxError should be raised at compile time: InvalidArgumentType

  Scenario: In-query call to procedure should fail if input type is wrong
    And there exists a procedure test.my.proc(in :: INTEGER?) :: (out :: INTEGER?):
      | in | out |
    When executing query:
      """
      CALL test.my.proc(true) YIELD out
      RETURN out
      """
    Then a SyntaxError should be raised at compile time: InvalidArgumentType

  Scenario: Standalone call to procedure should fail if explicit argument is missing
    And there exists a procedure test.my.proc(name :: STRING?, in :: INTEGER?) :: (out :: INTEGER?):
      | name | in | out |
    When executing query:
      """
      CALL test.my.proc('Dobby')
      """
    Then a SyntaxError should be raised at compile time: InvalidNumberOfArguments

  Scenario: In-query call to procedure should fail if explicit argument is missing
    And there exists a procedure test.my.proc(name :: STRING?, in :: INTEGER?) :: (out :: INTEGER?):
      | name | in | out |
    When executing query:
      """
      CALL test.my.proc('Dobby') YIELD out
      RETURN out
      """
    Then a SyntaxError should be raised at compile time: InvalidNumberOfArguments

  Scenario: Standalone call to procedure should fail if too many explicit argument are given
    And there exists a procedure test.my.proc(in :: INTEGER?) :: (out :: INTEGER?):
      | in | out |
    When executing query:
      """
      CALL test.my.proc(1, 2, 3, 4)
      """
    Then a SyntaxError should be raised at compile time: InvalidNumberOfArguments

  Scenario: In-query call to procedure should fail if too many explicit argument are given
    And there exists a procedure test.my.proc(in :: INTEGER?) :: (out :: INTEGER?):
      | in | out |
    When executing query:
      """
      CALL test.my.proc(1, 2, 3, 4) YIELD out
      RETURN out
      """
    Then a SyntaxError should be raised at compile time: InvalidNumberOfArguments

  Scenario: Standalone call to procedure should fail if implicit argument is missing
    And there exists a procedure test.my.proc(name :: STRING?, in :: INTEGER?) :: (out :: INTEGER?):
      | name | in | out |
    And parameters are:
      | name | 'Stefan' |
    When executing query:
      """
      CALL test.my.proc
      """
    Then a ParameterMissing should be raised at compile time: MissingParameter

  Scenario: In-query call to procedure that has outputs fails if no outputs are yielded
    And there exists a procedure test.my.proc(in :: INTEGER?) :: (out :: INTEGER?):
      | in | out |
    When executing query:
      """
      CALL test.my.proc(1)
      RETURN out
      """
    Then a SyntaxError should be raised at compile time: UndefinedVariable

  Scenario: Standalone call to unknown procedure should fail
    When executing query:
      """
      CALL test.my.proc
      """
    Then a ProcedureError should be raised at compile time: ProcedureNotFound

  Scenario: In-query call to unknown procedure should fail
    When executing query:
      """
      CALL test.my.proc() YIELD out
      RETURN out
      """
    Then a ProcedureError should be raised at compile time: ProcedureNotFound

  Scenario: In-query procedure call should fail if shadowing an already bound variable
    And there exists a procedure test.labels() :: (label :: STRING?):
      | label |
      | 'A'   |
      | 'B'   |
      | 'C'   |
    When executing query:
      """
      WITH 'Hi' AS label
      CALL test.labels() YIELD label
      RETURN *
      """
    Then a SyntaxError should be raised at compile time: VariableAlreadyBound

  Scenario: In-query procedure call should fail if one of the argument expressions uses an aggregation function
    And there exists a procedure test.labels(in :: INTEGER?) :: (label :: STRING?):
      | in | label |
    When executing query:
      """
      MATCH (n)
      CALL test.labels(count(n)) YIELD label
      RETURN label
      """
    Then a SyntaxError should be raised at compile time: InvalidAggregation

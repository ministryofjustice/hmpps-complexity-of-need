# hmpps-complexity-of-need

## Complexity Of Need Microservice

A microservice which calculates and makes available the Complexity Of Need level associated with an individual.

Owned by the Manage POM Cases Team - mailto:elephants@digital.justice.gov.uk

API Specification [![API docs](https://img.shields.io/badge/API_docs-view-85EA2D.svg?logo=swagger)](https://editor.swagger.io/?url=https://raw.githubusercontent.com/ministryofjustice/hmpps-complexity-of-need/main/Complexity%20Of%20Need%20API%20Specification.yaml)

Posted event Specification [![Event docs](https://img.shields.io/badge/Event_docs-view-85EA2D.svg)](https://playground.asyncapi.io/?url=https://raw.githubusercontent.com/ministryofjustice/hmpps-complexity-of-need/main/Complexity%20of%20Need%20Event%20Specification.yaml)

The *run_tests* job in `.circleci/config.yml` will mock calls to HMPPS auth.  
Running tests locally will perform these calls to the real auth service. You can also run the tests locally 
with mocked calls: `MOCK_AUTH=1 bundle exec rspec`  

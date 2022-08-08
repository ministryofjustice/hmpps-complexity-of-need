# hmpps-complexity-of-need

## Complexity Of Need Microservice

A microservice which calculates and makes available the Complexity Of Need level associated with an individual.

Owned by the Manage POM Cases Team - mailto:elephants@digital.justice.gov.uk

API Specification [![API docs](https://img.shields.io/badge/API_docs-view-85EA2D.svg?logo=swagger)](https://editor.swagger.io/?url=https://raw.githubusercontent.com/ministryofjustice/hmpps-complexity-of-need/main/Complexity%20Of%20Need%20API%20Specification.yaml)

Posted event Specification [![Event docs](https://img.shields.io/badge/Event_docs-view-85EA2D.svg)](https://playground.asyncapi.io/?url=https://raw.githubusercontent.com/ministryofjustice/hmpps-complexity-of-need/main/Complexity%20of%20Need%20Event%20Specification.yaml)

IMPORTANT NOTE: The *run_tests* job has been temporarily removed from `.circleci/config.yml` until the failing authorisation from CircleCI has been fixed, or the authorisation endpoints are mocked out. This means the specs **will not run on CirlceCI** and it is imperative that **all specs be run locally and verified green before pushing commits on your branch or merging your branch to main**.
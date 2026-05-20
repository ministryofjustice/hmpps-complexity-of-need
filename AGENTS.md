# AGENTS.md

## Big picture
- This is a Rails 8 API-only service that stores **historical** `Complexity` rows in Postgres; the “current” level is always the newest row for an offender, and only counts if `active` is true (`app/models/complexity.rb`, `app/controllers/complexities_controller.rb`).
- A save to `Complexity` publishes an SNS domain event via `ComplexityEventService`; changing persistence logic can change outbound events too (`app/models/complexity.rb`, `app/services/complexity_event_service.rb`, `Complexity of Need Event Specification.yaml`).
- JSON responses are shaped with Jbuilder partials, not serializers. Public API fields are camelCase even though DB/model fields are snake_case (`app/views/shared/_complexity.json.jbuilder`, `app/views/subject_access_request/_complexity.json.jbuilder`).

## API surface and contracts
- Treat the public routes in `config/routes.rb` as stable: comments explicitly say `/swagger-ui.html` and `/v3/api-docs` are expected by other teams/scripts.
- `/v1/complexity-of-need/offender-no/:offender_no` returns only the latest **active** record; if the newest row is inactive the API returns 404, not historical fallback (`ComplexitiesController#show`, request spec around “latest complexity inactive”).
- `/v1/complexity-of-need/multiple/offender-no` returns latest active rows only, excludes offenders with no current level, is **not sorted to request order**, and is **not paginated** (`spec/api/v1/rswag_spec.rb`, `spec/requests/v1/complexities_request_spec.rb`).
- `/v1/complexity-of-need/offender-no/:offender_no/history` returns all rows, including inactive ones, newest first.
- `/subject-access-request` is intentionally different from the normal API: it uses `prn`, rejects `crn`, can return HTTP `209`/`210`, returns `204` with empty body when no data exists, and only emits `level/notes/timestamps/active` under `content` (`app/controllers/subject_access_request_controller.rb`, `spec/requests/v1/subject_access_request_spec.rb`).

## Auth and request handling
- Auth is custom JWT handling, not Devise/OAuth middleware. `ApplicationController` parses the bearer token into `HmppsApi::Oauth::Token`, validates signature against cached JWKS from HMPPS Auth, and checks roles manually (`app/controllers/application_controller.rb`, `app/services/hmpps_api/oauth/token.rb`).
- `create` permits camelCase `sourceUser` but persists it as `source_user`, and always sets `source_system` from `token.client_id`, not the request body (`ComplexitiesController#create`).

## Developer workflows
- First-time/local boot: `bin/setup` installs gems, runs `bin/rails db:prepare`, clears logs/tmp, then starts `bin/dev` (which is just `bin/rails server`).
- Main checks: `bundle exec rspec`, `bundle exec rubocop`.
- Local tests call real HMPPS Auth unless you opt into mocks; use `MOCK_AUTH=1 bundle exec rspec` for offline/CI-like runs (`README.md`, `spec/auth_helper.rb`).
- If you change request/response contracts or rswag specs under `spec/api/v1`, regenerate the checked-in OpenAPI file with `bundle exec rake rswag:specs:swaggerize`; `/v3/api-docs` serves `swagger/v1/swagger.json` directly.
- The container image does **not** define its own `CMD`/`ENTRYPOINT`; deployment config starts it with `bundle exec puma` (`Dockerfile`, `helm_deploy/hmpps-complexity-of-need/values.yaml`). For Docker smoke tests, run Puma explicitly.

## Documentation and writing style
- `AGENTS.md` is primarily for AI agents and other tooling, not general human-facing documentation, so keep it concise and instruction-first; apply these style rules where they help, but do not rewrite it to read like end-user docs.
- For Markdown and other documentation, keep the tone friendly, professional, and concise; prefer clear, actionable wording with minimal jargon.
- Follow GOV.UK style guidance where practical, especially for structure, clarity, grammar, and punctuation.
- Use consistent capitalisation for product names and proper nouns, for example GitHub, macOS, Docker, and Ruby.
- Use British English spelling, for example organise, behaviour, centre, travelling, and labelled.
- Write naturally, including contractions where they help the tone, but avoid sounding too casual.

## Testing patterns worth following
- Request specs usually stub both auth and SNS: `stub_access_token ...` plus `allow(ComplexityEventService).to receive(:sns_topic).and_return(topic)`.
- Use the shared JSON helper `json_object(...)` when comparing responses so timestamps/JSON coercion match Rails serialisation (`spec/rails_helper.rb`).
- FactoryBot has one core factory, `:complexity`, with traits like `:with_user`, `:with_notes`, `:inactive`, and `:random_date` (`spec/factories/complexities.rb`).

## Environment and integrations
- Required env at runtime: `NOMIS_OAUTH_HOST`; tests and health/auth flows also rely on `NOMIS_OAUTH_CLIENT_ID` and `NOMIS_OAUTH_CLIENT_SECRET` (`config/application.rb`, `.env.example`).
- Production boot also requires `COMPLEXITY_OF_NEED_HOST` and `SECRET_KEY_BASE`; without them Puma exits during Rails initialisation before serving requests (`config/environments/production.rb`).
- SNS publishing requires `DOMAIN_EVENTS_TOPIC_ARN`; production DB uses SSL and the container installs the AWS RDS trust bundle (`app/services/complexity_event_service.rb`, `config/database.yml`, `Dockerfile`).
- `/health` checks both Postgres and `GET /auth/ping` against HMPPS Auth, so auth host misconfiguration shows up as health failure (`config/initializers/health.rb`).
- For lightweight container smoke tests, prefer unauthenticated `GET /ping` or `GET /health/ping`, both of which return plain `pong` and do not require DB/Auth dependencies; `GET /health` is the deeper integration check.
- Observability is already wired for Lograge, Sentry, and optional Application Insights; prefer fitting into those initialisers instead of adding parallel logging/reporting paths (`config/initializers/lograge.rb`, `config/initializers/sentry.rb`, `config/initializers/application_insights.rb`).

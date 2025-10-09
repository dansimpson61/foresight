# Foresight AI Agent Quick Checklist

Use this before opening a PR. Keep it tiny and joyful.

## Do
- Read `Ode to Joy - Ruby and Sinatra.txt` and reflect it in your changes.
- Prefer editing the `simple/` app first; keep scope minimal.
- Write or update one small test under `simple/spec/` if behavior changes.
- Keep names intention-revealing; avoid cleverness.
- Keep JS minimal; favor server-rendered Slim.
- Update docs when public behavior changes.

## Don’t
- Don’t add heavy dependencies or large abstractions.
- Don’t modify both classic and simple apps in the same PR without need.
- Don’t introduce surprising behavior (respect POLA).
- Don’t log secrets or make external calls unexpectedly.

## Local sanity
```fish
# install and run simple app
bundle install
bin/dev-simple
# or run both apps
bin/dev-both
# run tests (simple)
bundle exec ruby simple/spec/simulator_spec.rb
```

## PR gates
- Change is cohesive and small.
- Tests pass locally; coverage for your change is adequate.
- User-visible changes documented (README or comments).
- Code reads smoothly and matches project tone.

Thank you for keeping Foresight joyful.

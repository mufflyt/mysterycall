# Contributing to mysterycall

Thank you for considering contributing to **mysterycall**! This guide
explains how to report bugs, propose features, and submit pull requests.

## Code of Conduct

All interactions are governed by our [Code of
Conduct](https://mufflyt.github.io/mysterycall/CODE_OF_CONDUCT.md).
Please read it before participating.

------------------------------------------------------------------------

## Reporting bugs

1.  Search [existing
    issues](https://github.com/mufflyt/mysterycall/issues) first.
2.  Open a new issue using the **Bug report** template.
3.  Include a minimal reproducible example (`reprex::reprex()`), the
    output of
    [`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html), and the
    exact error message.

## Requesting features

Open a **Feature request** issue. Describe the use case first — “I need
X because Y” — rather than jumping to a proposed implementation.

------------------------------------------------------------------------

## Development setup

``` r

# Clone and open the project
usethis::create_from_github("mufflyt/mysterycall", fork = TRUE)

# Install all development dependencies
pak::pak(desc::desc_get_deps("./")$package)

# Run the test suite
devtools::test()

# Check the whole package
devtools::check()
```

Key tools used in this project:

| Tool                   | Purpose                     |
|------------------------|-----------------------------|
| `devtools`             | Build, check, document      |
| `testthat` (edition 3) | Unit tests                  |
| `roxygen2`             | Documentation from `@` tags |
| `pkgdown`              | Website (`_pkgdown.yml`)    |
| `covr`                 | Test coverage               |
| `lintr`                | Code style                  |

------------------------------------------------------------------------

## Submitting a pull request

1.  **Open an issue first** for any non-trivial change to align on
    scope.

2.  Fork the repository and create a branch from `main`:

    ``` bash
    git checkout -b fix/short-description
    ```

3.  Make your changes. Follow the style guide below.

4.  Add or update tests in `tests/testthat/`. Every new function needs
    at least one `test_that` block covering the happy path and
    `NA`/empty input.

5.  Regenerate documentation:

    ``` r

    devtools::document()
    ```

6.  Run the full check and fix any errors, warnings, or notes:

    ``` r

    devtools::check()
    ```

7.  Push and open a pull request against `main`. Fill in the PR
    template.

### PR checklist

`devtools::check()` produces 0 errors and 0 warnings

New or changed functions have roxygen docs (`@param`, `@return`,
`@examples`)

New functions are listed in `_pkgdown.yml` under the appropriate section

`NEWS.md` has a bullet under the current development version

Tests added or updated

------------------------------------------------------------------------

## Style guide

- Follow the [tidyverse style guide](https://style.tidyverse.org/).
- Lines ≤ 100 characters.
- Use `TRUE`/`FALSE`, not `T`/`F`.
- Prefer `|>` (base pipe) over `%>%` for new code.
- No [`library()`](https://rdrr.io/r/base/library.html) or
  [`require()`](https://rdrr.io/r/base/library.html) calls inside
  package functions — use
  [`requireNamespace()`](https://rdrr.io/r/base/ns-load.html) for
  optional dependencies listed in `Suggests`.
- Add a comment only when the **why** is non-obvious. Avoid restating
  what the code already says.

------------------------------------------------------------------------

## Testing conventions

- Test files mirror source files: `R/foo.R` →
  `tests/testthat/test-foo.R`.

- Use `testthat` edition 3 (configured in `DESCRIPTION`).

- Test labels follow `"function: case → expected"`, e.g.:

  ``` r

  test_that("validate_phone: NA input → flag 'missing'", { ... })
  ```

- Wrap any test that requires a non-CRAN package in
  `skip_if_not_installed("pkg")`.

- Do **not** use `skip_on_cran()` to hide failing tests — fix the test
  instead.

------------------------------------------------------------------------

## Adding a new function

1.  Create `R/function_name.R` with full roxygen documentation including
    `@export`, `@param`, `@return`, and at least one `@examples` block.
2.  Add the function to the appropriate section of `_pkgdown.yml`.
3.  Write tests in `tests/testthat/test-function-name.R`.
4.  Add a `NEWS.md` entry under `## New features`.
5.  Run `devtools::document()` to update `NAMESPACE` and `.Rd` files.

------------------------------------------------------------------------

## Questions?

Open a [GitHub
Discussion](https://github.com/mufflyt/mysterycall/discussions) or email
the maintainer at <tyler.muffly@dhha.org>.

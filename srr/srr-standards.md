## [General Standards](https://stats-devguide.ropensci.org/standards.html#general-standards)

### Documentation

- [ ] **G1.0** *Statistical Software should list at least one primary reference from published academic literature.* 
- [ ] **G1.1** *Statistical Software should document whether the algorithm(s) it implements are:* - *The first implementation of a novel algorithm*; or - *The first implementation within **R** of an algorithm which has previously been implemented in other languages or contexts*; or - *An improvement on other implementations of similar algorithms in **R***. 
- [ ] **G1.2** *Statistical Software should include a* Life Cycle Statement *describing current and anticipated future states of development.* 

#### Statistical Terminology

- [ ] **G1.3** *All statistical terminology should be clarified and unambiguously defined.* 

#### Function-level Documentation

- [ ] **G1.4** *Software should use [`roxygen2`](https://roxygen2.r-lib.org/) to document all functions.*
 - [ ] **G1.4a** *All internal (non-exported) functions should also be documented in standard [`roxygen2`](https://roxygen2.r-lib.org/) format, along with a final `@noRd` tag to suppress automatic generation of `.Rd` files or [`@keywords internal`](https://roxygen2.r-lib.org/reference/tags-index-crossref.html?q=keywords%20internal#null) if documentation is still desired.* 

#### Supplementary Documentation

- [ ] **G1.5** *Software should include all code necessary to reproduce results which form the basis of performance claims made in associated publications.* 
- [ ] **G1.6** *Software should include code necessary to compare performance claims with alternative implementations in other R packages.* 

### Input Structures

#### Uni-variate (Vector) Input

- [ ] **G2.0** *Implement assertions on lengths of inputs, particularly through asserting that inputs expected to be single- or multi-valued are indeed so.*
 - [ ] **G2.0a** Provide explicit secondary documentation of any expectations on lengths of inputs
- [ ] **G2.1** *Implement assertions on types of inputs (see the initial point on nomenclature above).*
 - [ ] **G2.1a** *Provide explicit secondary documentation of expectations on data types of all vector inputs.*
- [ ] **G2.2** *Appropriately prohibit or restrict submission of multivariate input to parameters expected to be univariate.*
- [ ] **G2.3** *For univariate character input:*
 - [ ] **G2.3a** *Use `match.arg()` or equivalent where applicable to only permit expected values.*
 - [ ] **G2.3b** *Either: use `tolower()` or equivalent to ensure input of character parameters is not case dependent; or explicitly document that parameters are strictly case-sensitive.*
- [ ] **G2.4** *Provide appropriate mechanisms to convert between different data types, potentially including:*
 - [ ] **G2.4a** *explicit conversion to `integer` via `as.integer()`*
 - [ ] **G2.4b** *explicit conversion to continuous via `as.numeric()`*
 - [ ] **G2.4c** *explicit conversion to character via `as.character()` (and not `paste` or `paste0`)*
 - [ ] **G2.4d** *explicit conversion to factor via `as.factor()`*
 - [ ] **G2.4e** *explicit conversion from factor via `as...()` functions*
- [ ] **G2.5** *Where inputs are expected to be of `factor` type, secondary documentation should explicitly state whether these should be `ordered` or not, and those inputs should provide appropriate error or other routines to ensure inputs follow these expectations.* 
- [ ] **G2.6** *Software which accepts one-dimensional input should ensure values are appropriately pre-processed regardless of class structures.* 

#### Tabular Input

- [ ] **G2.7** *Software should accept as input as many of the above standard tabular forms as possible, including extension to domain-specific forms.* 
- [ ] **G2.8** *Software should provide appropriate conversion or dispatch routines as part of initial pre-processing to ensure that all other sub-functions of a package receive inputs of a single defined class or type.*
- [ ] **G2.9** *Software should issue diagnostic messages for type conversion in which information is lost (such as conversion of variables from factor to character; standardisation of variable names; or removal of meta-data such as those associated with [`sf`-format](https://r-spatial.github.io/sf/) data) or added (such as insertion of variable or column names where none were provided).* 
- [ ] **G2.10** *Software should ensure that extraction or filtering of single columns from tabular inputs should not presume any particular default behaviour, and should ensure all column-extraction operations behave consistently regardless of the class of tabular data used as input.* 
- [ ] **G2.11** *Software should ensure that `data.frame`-like tabular objects which have columns which do not themselves have standard class attributes (typically, `vector`) are appropriately processed, and do not error without reason. This behaviour should be tested. Again, columns created by the [`units` package](https://github.com/r-quantities/units/) provide a good test case.*
- [ ] **G2.12** *Software should ensure that `data.frame`-like tabular objects which have list columns should ensure that those columns are appropriately pre-processed either through being removed, converted to equivalent vector columns where appropriate, or some other appropriate treatment such as an informative error. This behaviour should be tested.* 

#### Missing or Undefined Values

- [ ] **G2.13** *Statistical Software should implement appropriate checks for missing data as part of initial pre-processing prior to passing data to analytic algorithms.*
- [ ] **G2.14** *Where possible, all functions should provide options for users to specify how to handle missing (`NA`) data, with options minimally including:*
 - [ ] **G2.14a** *error on missing data*
 - [ ] **G2.14b** *ignore missing data with default warnings or messages issued*
 - [ ] **G2.14c** *replace missing data with appropriately imputed values*
- [ ] **G2.15** *Functions should never assume non-missingness, and should never pass data with potential missing values to any base routines with default `na.rm = FALSE`-type parameters (such as [`mean()`](https://stat.ethz.ch/R-manual/R-devel/library/base/html/mean.html), [`sd()`](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/sd.html) or [`cor()`](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/cor.html)).*
- [ ] **G2.16** *All functions should also provide options to handle undefined values (e.g., `NaN`, `Inf` and `-Inf`), including potentially ignoring or removing such values.* 

### Algorithms

- [ ] **G3.0** *Statistical software should never compare floating point numbers for equality. All numeric equality comparisons should either ensure that they are made between integers, or use appropriate tolerances for approximate equality.* 
- [ ] **G3.1** *Statistical software which relies on covariance calculations should enable users to choose between different algorithms for calculating covariances, and should not rely solely on covariances from the `stats::cov` function.*
 - [ ] **G3.1a** *The ability to use arbitrarily specified covariance methods should be documented (typically in examples or vignettes).* 

### Output Structures

- [ ] **G4.0** *Statistical Software which enables outputs to be written to local files should parse parameters specifying file names to ensure appropriate file suffixes are automatically generated where not provided.* 

### Testing 

#### Test Data Sets

- [ ] **G5.0** *Where applicable or practicable, tests should use standard data sets with known properties (for example, the [NIST Standard Reference Datasets](https://www.itl.nist.gov/div898/strd/), or data sets provided by other widely-used R packages).*
- [ ] **G5.1** *Data sets created within, and used to test, a package should be exported (or otherwise made generally available) so that users can confirm tests and run examples.* 

#### Responses to Unexpected Input

- [ ] **G5.2** *Appropriate error and warning behaviour of all functions should be explicitly demonstrated through tests. In particular,*
 - [ ] **G5.2a** *Every message produced within R code by `stop()`, `warning()`, `message()`, or equivalent should be unique*
 - [ ] **G5.2b** *Explicit tests should demonstrate conditions which trigger every one of those messages, and should compare the result with expected values.*
- [ ] **G5.3** *For functions which are expected to return objects containing no missing (`NA`) or undefined (`NaN`, `Inf`) values, the absence of any such values in return objects should be explicitly tested.* 

#### Algorithm Tests

- [ ] **G5.4** **Correctness tests** *to test that statistical algorithms produce expected results to some fixed test data sets (potentially through comparisons using binding frameworks such as [RStata](https://github.com/lbraglia/RStata)).*
 - [ ] **G5.4a** *For new methods, it can be difficult to separate out correctness of the method from the correctness of the implementation, as there may not be reference for comparison. In this case, testing may be implemented against simple, trivial cases or against multiple implementations such as an initial R implementation compared with results from a C/C++ implementation.*
 - [ ] **G5.4b** *For new implementations of existing methods, correctness tests should include tests against previous implementations. Such testing may explicitly call those implementations in testing, preferably from fixed-versions of other software, or use stored outputs from those where that is not possible.*
 - [ ] **G5.4c** *Where applicable, stored values may be drawn from published paper outputs when applicable and where code from original implementations is not available*
- [ ] **G5.5** *Correctness tests should be run with a fixed random seed*
- [ ] **G5.6** **Parameter recovery tests** *to test that the implementation produce expected results given data with known properties. For instance, a linear regression algorithm should return expected coefficient values for a simulated data set generated from a linear model.*
 - [ ] **G5.6a** *Parameter recovery tests should generally be expected to succeed within a defined tolerance rather than recovering exact values.*
 - [ ] **G5.6b** *Parameter recovery tests should be run with multiple random seeds when either data simulation or the algorithm contains a random component. (When long-running, such tests may be part of an extended, rather than regular, test suite; see G5.10-4.12, below).* 
- [ ] **G5.7** **Algorithm performance tests** *to test that implementation performs as expected as properties of data change. For instance, a test may show that parameters approach correct estimates within tolerance as data size increases, or that convergence times decrease for higher convergence thresholds.*
- [ ] **G5.8** **Edge condition tests** *to test that these conditions produce expected behaviour such as clear warnings or errors when confronted with data with extreme properties including but not limited to:*
 - [ ] **G5.8a** *Zero-length data*
 - [ ] **G5.8b** *Data of unsupported types (e.g., character or complex numbers in for functions designed only for numeric data)*
 - [ ] **G5.8c** *Data with all-`NA` fields or columns or all identical fields or columns*
 - [ ] **G5.8d** *Data outside the scope of the algorithm (for example, data with more fields (columns) than observations (rows) for some regression algorithms)*
- [ ] **G5.9** **Noise susceptibility tests** *Packages should test for expected stochastic behaviour, such as through the following conditions:*
 - [ ] **G5.9a** *Adding trivial noise (for example, at the scale of `.Machine$double.eps`) to data does not meaningfully change results*
 - [ ] **G5.9b** *Running under different random seeds or initial conditions does not meaningfully change results* 

#### Extended tests

- [ ] **G5.10** *Extended tests should included and run under a common framework with other tests but be switched on by flags such as as a `<MYPKG>_EXTENDED_TESTS="true"` environment variable.* - The extended tests can be then run automatically by GitHub Actions for example by adding the following to the `env` section of the workflow: 
- [ ] **G5.11** *Where extended tests require large data sets or other assets, these should be provided for downloading and fetched as part of the testing workflow.*
 - [ ] **G5.11a** *When any downloads of additional data necessary for extended tests fail, the tests themselves should not fail, rather be skipped and implicitly succeed with an appropriate diagnostic message.*
- [ ] **G5.12** *Any conditions necessary to run extended tests such as platform requirements, memory, expected runtime, and artefacts produced that may need manual inspection, should be described in developer documentation such as a `CONTRIBUTING.md` or `tests/README.md` file.*


---

## [Regression and Supervised Learning Standards](https://stats-devguide.ropensci.org/standards.html#regression-and-supervised-learning)

### Input data structures and validation

- [ ] **RE1.0** *Regression Software should enable models to be specified via a formula interface, unless reasons for not doing so are explicitly documented.*
- [ ] **RE1.1** *Regression Software should document how formula interfaces are converted to matrix representations of input data.* 
- [ ] **RE1.2** *Regression Software should document expected format (types or classes) for inputting predictor variables, including descriptions of types or classes which are not accepted.* 
- [ ] **RE1.3** *Regression Software which passes or otherwise transforms aspects of input data onto output structures should ensure that those output structures retain all relevant aspects of input data, notably including row and column names, and potentially information from other `attributes()`.*
 - [ ] **RE1.3a** *Where otherwise relevant information is not transferred, this should be explicitly documented.* 
- [ ] **RE1.4** *Regression Software should document any assumptions made with regard to input data; for example distributional assumptions, or assumptions that predictor data have mean values of zero. Implications of violations of these assumptions should be both documented and tested.* 

### Pre-processing and Variable Transformation

- [ ] **RE2.0** *Regression Software should document any transformations applied to input data, for example conversion of label-values to `factor`, and should provide ways to explicitly avoid any default transformations (with error or warning conditions where appropriate).*
- [ ] **RE2.1** *Regression Software should implement explicit parameters controlling the processing of missing values, ideally distinguishing `NA` or `NaN` values from `Inf` values (for example, through use of `na.omit()` and related functions from the `stats` package).* 
- [ ] **RE2.2** *Regression Software should provide different options for processing missing values in predictor and response data. For example, it should be possible to fit a model with no missing predictor data in order to generate values for all associated response points, even where submitted response values may be missing.*
- [ ] **RE2.3** *Where applicable, Regression Software should enable data to be centred (for example, through converting to zero-mean equivalent values; or to z-scores) or offset (for example, to zero-intercept equivalent values) via additional parameters, with the effects of any such parameters clearly documented and tested.*
- [ ] **RE2.4** *Regression Software should implement pre-processing routines to identify whether aspects of input data are perfectly collinear, notably including:*
 - [ ] **RE2.4a** *Perfect collinearity among predictor variables*
 - [ ] **RE2.4b** *Perfect collinearity between independent and dependent variables* 

### Algorithms

- [ ] **RE3.0** *Issue appropriate warnings or other diagnostic messages for models which fail to converge.*
- [ ] **RE3.1** *Enable such messages to be optionally suppressed, yet should ensure that the resultant model object nevertheless includes sufficient data to identify lack of convergence.*
- [ ] **RE3.2** *Ensure that convergence thresholds have sensible default values, demonstrated through explicit documentation.*
- [ ] **RE3.3** *Allow explicit setting of convergence thresholds, unless reasons against doing so are explicitly documented.* 

### Return Results

- [ ] **RE4.0** *Regression Software should return some form of "model" object, generally through using or modifying existing class structures for model objects (such as `lm`, `glm`, or model objects from other packages), or creating a new class of model objects.*
- [ ] **RE4.1** *Regression Software may enable an ability to generate a model object without actually fitting values. This may be useful for controlling batch processing of computationally intensive fitting algorithms.* 

#### Accessor Methods

- [ ] **RE4.2** *Model coefficients (via `coef()` / `coefficients()`)*
- [ ] **RE4.3** *Confidence intervals on those coefficients (via `confint()`)*
- [ ] **RE4.4** *The specification of the model, generally as a formula (via `formula()`)*
- [ ] **RE4.5** *Numbers of observations submitted to model (via `nobs()`)*
- [ ] **RE4.6** *The variance-covariance matrix of the model parameters (via `vcov()`)*
- [ ] **RE4.7** *Where appropriate, convergence statistics* 
- [ ] **RE4.8** *Response variables, and associated "metadata" where applicable.*
- [ ] **RE4.9** *Modelled values of response variables.*
- [ ] **RE4.10** *Model Residuals, including sufficient documentation to enable interpretation of residuals, and to enable users to submit residuals to their own tests.*
- [ ] **RE4.11** *Goodness-of-fit and other statistics associated such as effect sizes with model coefficients.*
- [ ] **RE4.12** *Where appropriate, functions used to transform input data, and associated inverse transform functions.* 
- [ ] **RE4.13** *Predictor variables, and associated "metadata" where applicable.* 

#### Prediction, Extrapolation, and Forecasting

- [ ] **RE4.14** *Where possible, values should also be provided for extrapolation or forecast *errors*.*
- [ ] **RE4.15** *Sufficient documentation and/or testing should be provided to demonstrate that forecast errors, confidence intervals, or equivalent values increase with forecast horizons.* 
- [ ] **RE4.16** *Regression Software which models distinct responses for different categorical groups should include the ability to submit new groups to `predict()` methods.* 

#### Reporting Return Results

- [ ] **RE4.17** *Model objects returned by Regression Software should implement or appropriately extend a default `print` method which provides an on-screen summary of model (input) parameters and (output) coefficients.*
- [ ] **RE4.18** *Regression Software may also implement `summary` methods for model objects, and in particular should implement distinct `summary` methods for any cases in which calculation of summary statistics is computationally non-trivial (for example, for bootstrapped estimates of confidence intervals).* 

### Documentation

- [ ] **RE5.0** *Scaling relationships between sizes of input data (numbers of observations, with potential extension to numbers of variables/columns) and speed of algorithm.* 

### Visualization

- [ ] **RE6.0** *Model objects returned by Regression Software (see* **RE4***) should have default `plot` methods, either through explicit implementation, extension of methods for existing model objects, or through ensuring default methods work appropriately.*
- [ ] **RE6.1** *Where the default `plot` method is **NOT** a generic `plot` method dispatched on the class of return objects (that is, through an S3-type `plot.<myclass>` function or equivalent), that method dispatch (or equivalent) should nevertheless exist in order to explicitly direct users to the appropriate function.*
- [ ] **RE6.2** *The default `plot` method should produce a plot of the `fitted` values of the model, with optional visualisation of confidence intervals or equivalent.* 
- [ ] **RE6.3** *Where a model object is used to generate a forecast (for example, through a `predict()` method), the default `plot` method should provide clear visual distinction between modelled (interpolated) and forecast (extrapolated) values.* 

### Testing

#### Input Data

- [ ] **RE7.0** *Tests with noiseless, exact relationships between predictor (independent) data.*
 - [ ] **RE7.0a** In particular, these tests should confirm ability to reject perfectly noiseless input data.
- [ ] **RE7.1** *Tests with noiseless, exact relationships between predictor (independent) and response (dependent) data.*
 - [ ] **RE7.1a** *In particular, these tests should confirm that model fitting is at least as fast or (preferably) faster than testing with equivalent noisy data (see RE2.4b).* 

#### Return Results

- [ ] **RE7.2** Demonstrate that output objects retain aspects of input data such as row or case names (see **RE1.3**).
- [ ] **RE7.3** Demonstrate and test expected behaviour when objects returned from regression software are submitted to the accessor methods of **RE4.2**--**RE4.7**.
- [ ] **RE7.4** Extending directly from **RE4.15**, where appropriate, tests should demonstrate and confirm that forecast errors, confidence intervals, or equivalent values increase with forecast horizons.

---

## [EDA Standards](https://stats-devguide.ropensci.org/standards.html#exploratory-data-analysis)

### Documentation Standards

- [ ] **EA1.0** *Identify one or more target audiences for whom the software is intended*
- [ ] **EA1.1** *Identify the kinds of data the software is capable of analysing (see *Kinds of Data* below).*
- [ ] **EA1.2** *Identify the kinds of questions the software is intended to help explore.* 
- [ ] **EA1.3** *Identify the kinds of data each function is intended to accept as input* 

### Input Data

#### Index Columns

- [ ] **EA2.0** *EDA Software which accepts standard tabular data and implements or relies upon extensive table filter and join operations should utilise an **index column** system*
- [ ] **EA2.1** *All values in an index column must be unique, and this uniqueness should be affirmed as a pre-processing step for all input data.*
- [ ] **EA2.2** *Index columns should be explicitly identified, either:*
 - [ ] **EA2.2a** *by using an appropriate class system, or*
 - [ ] **EA2.2b** *through setting an `attribute` on a table, `x`, of `attr(x, "index") <- <index_col_name>`.* 
- [ ] **EA2.3** *Table join operations should not be based on any assumed variable or column names* 

#### Multi-tabular input

- [ ] **EA2.4** *Use and demand an explicit class system for such input (for example, via the [`DM` package](https://github.com/krlmlr/dm)).*
- [ ] **EA2.5** *Ensure all individual tables follow the above standards for Index Columns* 

#### Classes and Sub-Classes

- [ ] **EA2.6** *Routines should appropriately process vector data regardless of additional attributes* 

### Analytic Algorithms

- [ ] **EA3.0** *The algorithmic components of EDA Software should enable automated extraction and/or reporting of statistics as some sufficiently "meta" level (such as variable or model selection), for which previous or reference implementations require manual intervention.*
- [ ] **EA3.1** *EDA software should enable standardised comparison of inputs, processes, models, or outputs which previous or reference implementations otherwise only enable in some comparably unstandardised form.* 

### Return Results / Output Data

- [ ] **EA4.0** *EDA Software should ensure all return results have types which are consistent with input types.* 
- [ ] **EA4.1** *EDA Software should implement parameters to enable explicit control of numeric precision*
- [ ] **EA4.2** *The primary routines of EDA Software should return objects for which default `print` and `plot` methods give sensible results. Default `summary` methods may also be implemented.* 

### Visualization and Summary Output

- [ ] **EA5.0** *Graphical presentation in EDA software should be as accessible as possible or practicable. In particular, EDA software should consider accessibility in terms of:*
 - [ ] **EA5.0a** *Typeface sizes, which should default to sizes which explicitly enhance accessibility*
 - [ ] **EA5.0b** *Default colour schemes, which should be carefully constructed to ensure accessibility.*
- [ ] **EA5.1** *Any explicit specifications of typefaces which override default values provided through other packages (including the `graphics` package) should consider accessibility* 

#### Summary and Screen-based Output

- [ ] **EA5.2** *Screen-based output should never rely on default print formatting of `numeric` types, rather should also use some version of `round(., digits)`, `formatC`, `sprintf`, or similar functions for numeric formatting according the parameter described in* **EA4.1**.
- [ ] **EA5.3** *Column-based summary statistics should always indicate the `storage.mode`, `class`, or equivalent defining attribute of each column.* 

#### General Standards for Visualization (Static and Dynamic)

- [ ] **EA5.4** *All visualisations should ensure values are rounded sensibly (for example, via `pretty()` function).*
- [ ] **EA5.5** *All visualisations should include units on all axes where such are specified or otherwise obtainable from input data or other routines.* 

#### Dynamic Visualization

- [ ] **EA5.6** *Any packages which internally bundle libraries used for dynamic visualization and which are also bundled in other, pre-existing R packages, should explain the necessity and advantage of re-bundling that library.* 

### Testing

#### Return Values

- [ ] **EA6.0** *Return values from all functions should be tested, including tests for the following characteristics:*
 - [ ] **EA6.0a** *Classes and types of objects*
 - [ ] **EA6.0b** *Dimensions of tabular objects*
 - [ ] **EA6.0c** *Column names (or equivalent) of tabular objects*
 - [ ] **EA6.0d** *Classes or types of all columns contained within `data.frame`-type tabular objects *
 - [ ] **EA6.0e** *Values of single-valued objects; for `numeric` values either using `testthat::expect_equal()` or equivalent with a defined value for the `tolerance` parameter, or using `round(..., digits = x)` with some defined value of `x` prior to testing equality.* 

#### Graphical Output

- [ ] **EA6.1** *The properties of graphical output from EDA software should be explicitly tested, for example via the [`vdiffr` package](https://github.com/r-lib/vdiffr) or equivalent.* 

---

## [Spatial Standards](https://stats-devguide.ropensci.org/standards.html#spatial-software)

### Spatial Domains

- [ ] **SP1.0** *Spatial software should explicitly indicate its domain of applicability, and in particular distinguish whether the software may be applied in Cartesian/rectilinear/geometric domains, curvilinear/geographic domains, or both.* 
- [ ] **SP1.1** *Spatial software should explicitly indicate its dimensional domain of applicability, in particular through identifying whether it is applicable to two or three dimensions only, or whether there are any other restrictions on dimensionality.* 

### Input data structures and validation

- [ ] **SP2.0** *Spatial software should only accept input data of one or more classes explicitly developed to represent such data.*
 - [ ] **SP2.0a** *Where new classes are implemented, conversion to other common classes for spatial data in R should be documented.*
 - [ ] **SP2.0b** *Class systems should ensure that functions error appropriately, rather than merely warning, in response to data from inappropriate spatial domains.* 
- [ ] **SP2.1** *Spatial Software should not use the [`sp` package](https://cran.r-project.org/package=sp), rather should use [`sf`](https://cran.r-project.org/package=sf).* 
- [ ] **SP2.2** *Geographical Spatial Software should ensure maximal compatibility with established packages and workflows, minimally through:*
 - [ ] **SP2.2a** *Clear and extensive documentation demonstrating how routines from that software may be embedded within, or otherwise adapted to, workflows which rely on these established packages; and*
 - [ ] **SP2.2b** *Tests which clearly demonstrate that routines from that software may be successfully translated into forms and workflows which rely on these established packages.* 
- [ ] **SP2.3** *Software which accepts spatial input data in any standard format established in other R packages (such as any of the formats able to be read by [`GDAL`](https://gdal.org), and therefore by the [`sf` package](https://cran.r-project.org/package=sf)) should include example and test code which load those data in spatial formats, rather than R-specific binary formats such as `.Rds`.* 
- [ ] **SP2.4** *Geographical Spatial Software should be compliant with version 6 or larger of* [`PROJ`](https://proj.org/), *and with* `WKT2` *representations. The primary implication, described in detail in the articles linked to above, is that:*
 - [ ] **SP2.4a** *Software should not permit coordinate reference systems to be represented merely by so-called "PROJ4-strings", but should use at least WKT2.* 
- [ ] **SP2.5** *Class systems for input data must contain meta data on associated coordinate reference systems.*
 - [ ] **SP2.5a** *Software which implements new classes to input spatial data (or the spatial components of more general data) should provide an ability to convert such input objects into alternative spatial classes such as those listed above.*
- [ ] **SP2.6** *Spatial Software should explicitly document the types and classes of input data able to be passed to each function.*
- [ ] **SP2.7** *Spatial Software should implement validation routines to confirm that inputs are of acceptable classes (or represented in otherwise appropriate ways for software which does not use class systems).*
- [ ] **SP2.8** *Spatial Software should implement a single pre-processing routine to validate input data, and to appropriately transform it to a single uniform type to be passed to all subsequent data-processing functions.*
- [ ] **SP2.9** *The pre-processing function described above should maintain those metadata attributes of input data which are relevant or important to core algorithms or return values.* 

### Algorithms

- [ ] **SP3.0** *Spatial software which considers spatial neighbours should enable user control over neighbourhood forms and sizes. In particular:*
 - [ ] **SP3.0a** *Neighbours (able to be expressed) on regular grids should be able to be considered in both rectangular only, or rectangular and diagonal (respectively "rook" and "queen" by analogy to chess).*
 - [ ] **SP3.0b** *Neighbourhoods in irregular spaces should be minimally able to be controlled via an integer number of neighbours, an area (or equivalent distance defining an area) in which to include neighbours, or otherwise equivalent user-controlled value.*
- [ ] **SP3.1** *Spatial software which considers spatial neighbours should wherever possible enable neighbour contributions to be weighted by distance (or other continuous weighting variable), and not rely exclusively on a uniform-weight rectangular cut-off.*
- [ ] **SP3.2** *Spatial software which relies on sampling from input data (even if only of spatial coordinates) should enable sampling procedures to be based on local spatial densities of those input data.* 
- [ ] **SP3.3** *Spatial regression software should explicitly quantify and distinguish autocovariant or autoregressive processes from those covariant or regressive processes not directly related to spatial structure alone.* 
- [ ] **SP3.4** *Where possible, spatial clustering software should avoid using standard non-spatial clustering algorithms in which spatial proximity is merely represented by an additional weighting factor in favour of explicitly spatial algorithms.* 
- [ ] **SP3.5** *Spatial machine learning software should ensure that broadcasting procedures for reconciling inputs of different dimensions are **not** applied*. 
- [ ] **SP3.6** *Spatial machine learning software should document (and, where possible, test) the potential effects of different sampling procedures* 

### Return Results

- [ ] **SP4.0** *Return values should either:*
 - [ ] **SP4.0a** *Be in same class as input data, or*
 - [ ] **SP4.0b** *Be in a unique, preferably class-defined, format.*
- [ ] **SP4.1** *Any aspects of input data which are included in output data (either directly, or in some transformed form) and which contain units should ensure those same units are maintained in return values.*
- [ ] **SP4.2** *The type and class of all return values should be explicitly documented.* 

### Visualization

- [ ] **SP5.0** *Implement default `plot` methods for any implemented class system.*
- [ ] **SP5.1** *Implement appropriate placement of variables along x- and y-axes.*
- [ ] **SP5.2** *Ensure that axis labels include appropriate units.* 
- [ ] **SP5.3** *Offer an ability to generate interactive (generally `html`-based) visualisations of results.* 

### Testing

- [ ] **SP6.0** *Software which implements routines for transforming coordinates of input data should include tests which demonstrate ability to recover the original coordinates.* 
- [ ] **SP6.1** *All functions which can be applied to both Cartesian and curvilinear data should be tested through application to both.*
 - [ ] **SP6.1a** *Functions which may yield inaccurate results when applied to data in one or the other forms (such as the preceding examples of centroids and buffers from ellipsoidal data) should test that results from inappropriate application of those functions are indeed less accurate.*
 - [ ] **SP6.1b** *Functions which yield accurate results regardless of whether input data are rectilinear or curvilinear should demonstrate equivalent accuracy in both cases, and should also demonstrate how equivalent results may be obtained through first explicitly transforming input data.* 
- [ ] **SP6.2** *Geographical Software should include tests with extreme geographical coordinates, minimally including extension to polar extremes of +/-90 degrees.* 
- [ ] **SP6.3** *Spatial Software which considers spatial neighbours should explicitly test all possible ways of defining them, and should explicitly compare quantitative effects of different ways of defining neighbours.*
- [ ] **SP6.4** *Spatial Software which considers spatial neighbours should explicitly test effects of different schemes to weight neighbours by spatial proximity.* 
- [ ] **SP6.5** *Spatial Unsupervised Learning Software which uses clustering algorithms should implement tests which explicitly compare results with equivalent results obtained with a non-spatial clustering algorithm.* 
- [ ] **SP6.6** *Spatial Machine Learning Software should implement tests which explicitly demonstrate the detrimental consequences of sampling test and training data from the same spatial region, rather than from spatially distinct regions.

---

## [Machine Learning Standards](https://stats-devguide.ropensci.org/standards.html#machine-learning-software)

### Input Data Specification

- [ ] **ML1.0** *Documentation should make a clear conceptual distinction between training and test data (even where such may ultimately be confounded as described above.)*
 - [ ] **ML1.0a** *Where these terms are ultimately eschewed, these should nevertheless be used in initial documentation, along with clear explanation of, and justification for, alternative terminology.*
- [ ] **ML1.1** *Absent clear justification for alternative design decisions, input data should be expected to be labelled "test", "training", and, where applicable, "validation" data.*
 - [ ] **ML1.1a** *The presence and use of these labels should be explicitly confirmed via pre-processing steps (and tested in accordance with **ML7.0**, below).*
 - [ ] **ML1.1b** *Matches to expected labels should be case-insensitive and based on partial matching such that, for example, "Test", "test", or "testing" should all suffice.* 
- [ ] **ML1.2** *Training and test data sets for ML software should be able to be input as a single, generally tabular, data object, with the training and test data distinguished either by* - *A specified variable containing, for example, `TRUE`/`FALSE` or `0`/`1` values, or which uses some other system such as missing (`NA`) values to denote test data); and/or* - *An additional parameter designating case or row numbers, or labels of test data.* 
- [ ] **ML1.3** *Input data should be clearly partitioned between training and test data (for example, through having each passed as a distinct `list` item), or should enable an additional means of categorically distinguishing training from test data (such as via an additional parameter which provides explicit labels). Where applicable, distinction of validation and any other data should also accord with this standard.* 
- [ ] **ML1.4** *Training and test data sets, along with other necessary components such as validation data sets, should be stored in their own distinctly labelled sub-directories (for distinct files), or according to an explicit and distinct labelling scheme (for example, for database connections). Labelling should in all cases adhere to **ML1.1**, above.* 
- [ ] **ML1.5** *ML software should implement a single function which summarises the contents of test and training (and other) data sets, minimally including counts of numbers of cases, records, or files, and potentially extending to tables or summaries of file or data types, sizes, and other information (such as unique hashes for each component).* 

#### Missing Values

- [ ] **ML1.6** *ML software which does not admit missing values, and which expects no missing values, should implement explicit pre-processing routines to identify whether data has any missing values, and should generally error appropriately and informatively when passed data with missing values. In addition, ML software which does not admit missing values should:*
 - [ ] **ML1.6a** *Explain why missing values are not admitted.*
 - [ ] **ML1.6b** *Provide explicit examples (in function documentation, vignettes, or both) for how missing values may be imputed, rather than simply discarded.*
- [ ] **ML1.7** *ML software which admits missing values should clearly document how such values are processed.*
 - [ ] **ML1.7a** *Where missing values are imputed, software should offer multiple user-defined ways to impute missing data.*
 - [ ] **ML1.7b** *Where missing values are imputed, the precise imputation steps should also be explicitly documented, either in tests (see **ML7.2** below), function documentation, or vignettes.*
- [ ] **ML1.8** *ML software should enable equal treatment of missing values for both training and test data, with optional user ability to control application to either one or both.* 

### Pre-processing

- [ ] **ML2.0** *A dedicated function should enable pre-processing steps to be defined and parametrized.*
 - [ ] **ML2.0a** *That function should return an object which can be directly submitted to a specified model (see section 3, below).*
 - [ ] **ML2.0b** *Absent explicit justification otherwise, that return object should have a defined class minimally intended to implement a default `print` method which summarizes the input data set (as per **ML1.5** above) and associated transformations (see the following standard).* 
- [ ] **ML2.1** *ML software which uses broadcasting to reconcile dimensionally incommensurate input data should offer an ability to at least optionally record transformations applied to each input file.* 
- [ ] **ML2.2** *ML software which requires or relies upon numeric transformations of input data (such as change in mean values or variances) should allow optimal explicit specification of target values, rather than restricting transformations to default generic values only (such as transformations to z-scores).*
 - [ ] **ML2.2a** *Where the parameters have default values, reasons for those particular defaults should be explicitly described.*
 - [ ] **ML2.2b** *Any extended documentation (such as vignettes) which demonstrates the use of explicit values for numeric transformations should explicitly describe why particular values are used.* 
- [ ] **ML2.3** *The values associated with all transformations should be recorded in the object returned by the function described in the preceding standard (**ML2.0**).*
- [ ] **ML2.4** *Default values of all transformations should be explicitly documented, both in documentation of parameters where appropriate (such as for numeric transformations), and in extended documentation such as vignettes.*
- [ ] **ML2.5** *ML software should provide options to bypass or otherwise switch off all default transformations.*
- [ ] **ML2.6** *Where transformations are implemented via distinct functions, these should be exported to a package's namespace so they can be applied in other contexts.*
- [ ] **ML2.7** *Where possible, documentation should be provided for how transformations may be reversed. For example, documentation may demonstrate how the values retained via **ML2.3**, above, can be used along with transformations either exported via **ML2.6** or otherwise exemplified in demonstration code to independently transform data, and then to reverse those transformations.* 

### Model and Algorithm Specification

- [ ] **ML3.0** *Model specification should be implemented as a distinct stage subsequent to specification of pre-processing routines (see Section 2, above) and prior to actual model fitting or training (see Section 4, below). In particular,*
 - [ ] **ML3.0a** *A dedicated function should enable models to be specified without actually fitting or training them, or if this (**ML3**) and the following (**ML4**) stages are controlled by a single function, that function should have a parameter enabling models to be specified yet not fitted (for example, `nofit = FALSE`).*
 - [ ] **ML3.0b** *That function should accept as input the objects produced by the previous Input Data Specification stage, and defined according to **ML2.0**, above.*
 - [ ] **ML3.0c** *The function described above (**ML3.0a**) should return an object which can be directly trained as described in the following sub-section (**ML4**).*
 - [ ] **ML3.0d** *That return object should have a defined class minimally intended to implement a default `print` method which summarises the model specification, including values of all relevant parameters.*
- [ ] **ML3.1** *ML software should allow the use of both untrained models, specified through model parameters only, as well as pre-trained models. Use of the latter commonly entails an ability to submit a previously-trained model object to the function defined according to **ML3.0a**, above.*
- [ ] **ML3.2** *ML software should enable different models to be applied to the object specifying data inputs and transformations (see sub-sections 1--2, above) without needing to re-define those preceding steps.* 
- [ ] **ML3.3** *Where ML software implements its own distinct classes of model objects, the properties and behaviours of those specific classes of objects should be explicitly compared with objects produced by other ML software. In particular, where possible, ML software should provide extended documentation (as vignettes or equivalent) comparing model objects with those from other ML software, noting both unique abilities and restrictions of any implemented classes.*
- [ ] **ML3.4** *Where training rates are used, ML software should provide explicit documentation both in all functions which use training rates, and in extended form such as vignettes, of the importance of, and/or sensitivity to, different values of training rates. In particular,*
 - [ ] **ML3.4a** *Unless explicitly justified otherwise, ML software should offer abilities to automatically determine appropriate or optimal training rates, either as distinct pre-processing stages, or as implicit stages of model training.*
 - [ ] **ML3.4b** *ML software which provides default values for training rates should clearly document anticipated restrictions of validity of those default values; for example through clear suggestions that user-determined and -specified values may generally be necessary or preferable.* 

#### Control Parameters

- [ ] **ML3.5** *Parameters controlling optimization algorithms should minimally include:*
 - [ ] **ML3.5a** *Specification of the type of algorithm used to explore the search space (commonly, for example, some kind of gradient descent algorithm)*
 - [ ] **ML3.5b** *The kind of loss function used to assess distance between model estimates and desired output.*
- [ ] **ML3.6** *Unless explicitly justified otherwise (for example because ML software under consideration is an implementation of one specific algorithm), ML software should:*
 - [ ] **ML3.6a** *Implement or otherwise permit usage of multiple ways of exploring search space*
 - [ ] **ML3.6b** *Implement or otherwise permit usage of multiple loss functions.* 

#### CPU and GPU processing

- [ ] **ML3.7** *For ML software in which algorithms are coded in C++, user-controlled use of either CPUs or GPUs (on NVIDIA processors at least) should be implemented through direct use of [`libcudacxx`](https://github.com/NVIDIA/libcudacxx).* 

### Model Training

- [ ] **ML4.0** *ML software should generally implement a unified single-function interface to model training, able to receive as input a model specified according to all preceding standards. In particular, models with categorically different specifications, such as different model architectures or optimization algorithms, should be able to be submitted to the same model training function.*
- [ ] **ML4.1** *ML software should at least optionally retain explicit information on paths taken as an optimizer advances towards minimal loss. Such information should minimally include:*
 - [ ] **ML4.1a** *Specification of all model-internal parameters, or equivalent hashed representation.*
 - [ ] **ML4.1b** *The value of the loss function at each point*
 - [ ] **ML4.1c** *Information used to advance to next point, for example quantification of local gradient.*
- [ ] **ML4.2** *The subsequent extraction of information retained according to the preceding standard should be explicitly documented, including through example code.* 

#### Batch Processing

- [ ] **ML4.3** *All parameters controlling batch processing and associated terminology should be explicitly documented, and it should not, for example, be presumed that users will understand the definition of "epoch" as implemented in any particular ML software.* 
- [ ] **ML4.4** *Explicit guidance should be provided on selection of appropriate values for parameter controlling batch processing, for example, on trade-offs between batch sizes and numbers of epochs (with both terms provided as Control Parameters in accordance with the preceding standard, **ML3**).*
- [ ] **ML4.5** *ML software may optionally include a function to estimate likely time to train a specified model, through estimating initial timings from a small sample of the full batch.*
- [ ] **ML4.6** *ML software should by default provide explicit information on the progress of batch jobs (even where those jobs may be implemented in parallel on GPUs). That information may be optionally suppressed through additional parameters.* 

#### Re-sampling

- [ ] **ML4.7** *ML software should provide an ability to combine results from multiple re-sampling iterations using a single parameter specifying numbers of iterations.*
- [ ] **ML4.8** *Absent any additional specification, re-sampling algorithms should by default partition data according to proportions of original test and training data.*
 - [ ] **ML4.8a** *Re-sampling routines of ML software should nevertheless offer an ability to explicitly control or override such default proportions of test and training data.* 

### Model Output and Performance

#### Model Output

- [ ] **ML5.0** *The result of applying the training processes described above should be contained within a single model object returned by the function defined according to **ML4.0**, above. Even where the output reflects application to a test data set, the resultant object need not include any information on model performance (see **ML5.3**--**ML5.4**, below).*
 - [ ] **ML5.0a** *That object should either have its own class, or extend some previously-defined class.*
 - [ ] **ML5.0b** *That class should have a defined `print` method which summarises important aspects of the model object, including but not limited to summaries of input data and algorithmic control parameters.*
- [ ] **ML5.1** *As for the untrained model objects produced according to the above standards, and in particular as a direct extension of **ML3.3**, the properties and behaviours of trained models produced by ML software should be explicitly compared with equivalent objects produced by other ML software. (Such comparison will generally be done in terms of comparing model performance, as described in the following standard **ML5.3**--**ML5.4**).*
- [ ] **ML5.2** *The structure and functionality of objects representing trained ML models should be thoroughly documented. In particular,*
 - [ ] **ML5.2a** *Either all functionality extending from the class of model object should be explicitly documented, or a method for listing or otherwise accessing all associated functionality explicitly documented and demonstrated in example code.*
 - [ ] **ML5.2b** *Documentation should include examples of how to save and re-load trained model objects for their re-use in accordance with **ML3.1**, above.*
 - [ ] **ML5.2c** *Where general functions for saving or serializing objects, such as [`saveRDS`](https://stat.ethz.ch/R-manual/R-devel/library/base/html/readRDS.html) are not appropriate for storing local copies of trained models, an explicit function should be provided for that purpose, and should be demonstrated with example code.* 

#### Model Performance

- [ ] **ML5.3** *Assessment of model performance should be implemented as one or more functions distinct from model training.*
- [ ] **ML5.4** *Model performance should be able to be assessed according to a variety of metrics.*
 - [ ] **ML5.4a** *All model performance metrics represented by functions internal to a package must be clearly and distinctly documented.*
 - [ ] **ML5.4b** *It should be possible to submit custom metrics to a model assessment function, and the ability to do so should be clearly documented including through example code.* 

### Documentation

- [ ] **ML6.0** *Descriptions of ML software should make explicit reference to a workflow which separates training and testing stages, and which clearly indicates a need for distinct training and test data sets.* 
- [ ] **ML6.1** *ML software intentionally designed to address only a restricted subset of the workflow described here should clearly document how it can be embedded within a typical full ML workflow in the sense considered here.*
 - [ ] **ML6.1a** *Such demonstrations should include and contrast embedding within a full workflow using at least two other packages to implement that workflow.* 

### Testing

#### Input Data

- [ ] **ML7.0** *Test should explicitly confirm partial and case-insensitive matching of "test", "train", and, where applicable, "validation" data.*
- [ ] **ML7.1** *Tests should demonstrate effects of different numeric scaling of input data (see **ML2.2**).*
- [ ] **ML7.2** *For software which imputes missing data, tests should compare internal imputation with explicit code which directly implements imputation steps (even where such imputation is a single-step implemented via some external package). These tests serve as an explicit reference for how imputation is performed.* 

#### Model Classes

- [ ] **ML7.3** *Where model objects are implemented as distinct classes, tests should explicitly compare the functionality of these classes with functionality of equivalent classes for ML model objects from other packages.*
 - [ ] **ML7.3a** *These tests should explicitly identify restrictions on the functionality of model objects in comparison with those of other packages.*
 - [ ] **ML7.3b** *These tests should explicitly identify functional advantages and unique abilities of the model objects in comparison with those of other packages.* 

#### Model Training

- [ ] **ML7.4** *ML software should explicit document the effects of different training rates, and in particular should demonstrate divergence from optima with inappropriate training rates.*
- [ ] **ML7.5** *ML software which implements routines to determine optimal training rates (see **ML3.4**, above) should implement tests to confirm the optimality of resultant values.*
- [ ] **ML7.6** *ML software which implement independent training "epochs" should demonstrate in tests the effects of lesser versus greater numbers of epochs.*
- [ ] **ML7.7** *ML software should explicitly test different optimization algorithms, even where software is intended to implement one specific algorithm.*
- [ ] **ML7.8** *ML software should explicitly test different loss functions, even where software is intended to implement one specific measure of loss.*
- [ ] **ML7.9** *Tests should explicitly compare all possible combinations in categorical differences in model architecture, such as different model architectures with same optimization algorithms, same model architectures with different optimization algorithms, and differences in both.*
 - [ ] **ML7.9a** *Such combinations will generally be formed from multiple categorical factors, for which explicit use of functions such as [`expand.grid()`](https://stat.ethz.ch/R-manual/R-devel/library/base/html/expand.grid.html) is recommended.* 
- [ ] **ML7.10** *The successful extraction of information on paths taken by optimizers (see **ML5.1**, above), should be tested, including testing the general properties, but not necessarily actual values of, such data.* 

#### Model Performance

- [ ] **ML7.11** *All performance metrics available for a given class of trained model should be thoroughly tested and compared.*
 - [ ] **ML7.11a** *Tests which compare metrics should do so over a range of inputs (generally implying differently trained models) to demonstrate relative advantages and disadvantages of different metrics.*

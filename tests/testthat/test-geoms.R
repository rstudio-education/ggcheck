context("Geoms")
require(ggplot2)

p <-
  ggplot(data = mpg, mapping = aes(x = displ, y = hwy)) +
  geom_point(mapping = aes(color = class)) +
  geom_smooth(se = FALSE) +
  labs(title = "TITLE", subtitle = "SUBTITLE", caption = "CAPTION")

d2 <- head(mpg)

p2 <-
  ggplot(data = mpg, mapping = aes(x = displ, y = hwy)) +
  geom_point(data = d2, color = "red") +
  geom_point(mapping = aes(color = class)) +
  geom_smooth(se = FALSE) +
  labs(title = "TITLE", subtitle = "SUBTITLE", caption = "CAPTION")

p3 <- ggplot(data = diamonds, aes(x = cut, y = price)) +
  geom_boxplot(varwidth = TRUE, outlier.alpha = 0.01)

p4 <- ggplot(data = diamonds, aes(price)) +
  geom_histogram(bins = 20, binwidth = 500)

test_that("Identifies ith geom", {
  expect_equal(
    ith_geom(p, 1),
    "point"
  )
  expect_equal(
    ith_geom(p, 2),
    "smooth"
  )
})

test_that("Identifies ith geom and stat combination", {
  expect_equal(
    ith_geom_stat(p, 1),
    structure(
      list(GEOM = "point", STAT = "identity"),
      class = "GEOM_STAT"
    )
  )
  expect_equal(
    ith_geom_stat(p, 2),
    structure(
      list(GEOM = "smooth", STAT = "smooth"),
      class = "GEOM_STAT"
    )
  )
})

test_that("Checks ith geom", {
  expect_true(ith_geom_is(p, "point", i = 1))
  expect_true(ith_geom_is(p, "smooth", i = 2))
  expect_false(ith_geom_is(p, "smooth", i = 1))
  expect_false(ith_geom_is(p, "point", i = 2))
})

test_that("Identifies sequence of geoms", {
  expect_equal(
    get_geoms(p),
    c("point", "smooth")
  )
})

test_that("Identifies sequence of geom and stat combinations", {
  expect_equal(
    get_geoms_stats(p),
    list(
      structure(
        list(GEOM = "point", STAT = "identity"),
        class = "GEOM_STAT"
      ),
      structure(
        list(GEOM = "smooth", STAT = "smooth"),
        class = "GEOM_STAT"
      )
    )
  )
})

test_that("Checks whether a geom is used", {
  expect_true(uses_geoms(p, "point", exact = FALSE))
  expect_true(uses_geoms(p, "smooth", exact = FALSE))
  expect_true(uses_geoms(p, c("point", "smooth")))
  expect_false(uses_geoms(p, "line"))
  expect_false(uses_geoms(p, c("point", "line")))
  expect_true(uses_geoms(p2, c("point", "point", "point"), exact = FALSE))
  expect_false(uses_geoms(p2, c("point", "point", "point")))
})

test_that("Checks whether a sequence of geoms is used", {
  expect_true(uses_geoms(p, c("point", "smooth")))
  expect_false(uses_geoms(p, "point"))
  expect_false(uses_geoms(p, "smooth"))
  expect_false(uses_geoms(p, c("point", "line")))
})

test_that("Checks whether geom and stat combinations are used", {
  expect_true(uses_geoms(p, geoms = c("point", "smooth"), stats = c("identity", "smooth")))
  expect_false(uses_geoms(p, geoms = c("point", "smooth"), stats = c("sum", "smooth")))
  # throw error if length of stats does not match total number of geoms
  expect_error(uses_geoms(p, geoms = c("point", "smooth"), stats = c("identity")))
})

test_that("Throws a grading error when checking an invalid geom", {
  expect_error(uses_geoms(p, "lline"))
  expect_error(uses_geoms(p, c("point", "lline")))
})

test_that("Throws a grading error when checking an invalid geom and stat combination", {
  # invalid geom
  expect_error(uses_geoms(p, geoms = c("pointtt", "smooth"), stats = c("identity", "smooth")))
  # invalid stat
  expect_error(uses_geoms(p, geoms = c("point", "smooth"), stats = c("point", "smooth")))
})

test_that("Checks whether a geom uses a specfic parameter value", {
  # check a default parameter
  expect_true(uses_geom_param(p, geom = "smooth", params = list(na.rm = FALSE)))
  # check set parameters
  expect_true(uses_geom_param(p, geom = "smooth", params = list(se = FALSE)))
  expect_true(uses_geom_param(p3, geom = "boxplot", params = list(varwidth = TRUE, outlier.alpha = 0.01)))
  # check parameter of a geom which is a stat parameter
  expect_true(uses_geom_param(p4, geom = "histogram", params = list(bins = 20, binwidth = 500)))
})

test_that("Throws a grading error when checking an invalid geom parameter", {
  # typo
  expect_error(uses_geom_param(p, geom = "smooth", params = list(see = FALSE)))
  # invalid parameter for geom
  expect_error(uses_geom_param(p3, geom = "boxplot", params = list(bins = 20, outlier.alpha = 0.01)))
  expect_error(uses_geom_param(p4, geom = "histogram", params = list(bins = 20, outlier.alpha = 0.01)))
  # multiple invalid parameters
  expect_error(uses_geom_param(p3, geom = "boxplot", params = list(varwidthh = TRUE, outlierr.alpha = 0.01)))
})


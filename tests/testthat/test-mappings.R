context("Mappings")
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

test_that("Identifies global mapping", {
  expect_equal(
    get_mappings(p),
    aes(x = displ, y = hwy)
  )
})

test_that("Checks whether mappings are used globally", {
  expect_true(uses_mappings(p, mappings = aes(x = displ, y = hwy)))
  expect_true(uses_mappings(p, mappings = aes(x = displ)))
  expect_false(uses_mappings(p, mappings = aes(x = hwy, y = displ)))
  expect_true(uses_mappings(p, mapping = aes(x = displ)))
  expect_true(uses_mappings(p, mapping = aes(y = hwy)))
  expect_false(uses_mappings(p, mapping = aes(x = hwy)))
})

test_that("Identifies local mappings", {
  expect_equal(
    ith_mappings(p2, i = 1, local_only = FALSE),
    aes(x = displ, y = hwy)
  )
  expect_equal(
    ith_mappings(p2, i = 2, local_only = FALSE),
    aes(x = displ, y = hwy, color = class)
  )
  expect_equal(
    ith_mappings(p2, i = 1, local_only = TRUE),
    NULL
  )
  expect_equal(
    ith_mappings(p2, i = 2, local_only = TRUE),
    aes(color = class)
  )
})

test_that("Checks whether layer mappings exactly match", {
  expect_true(
    ith_mappings_use(p2, aes(x = displ, y = hwy, color = class), i = 2, local_only = FALSE, exact = TRUE)
  )
  expect_true(
    ith_mappings_use(p2, aes(y = hwy, x = displ, color = class), i = 2, local_only = FALSE, exact = TRUE)
  )
  expect_false(
    ith_mappings_use(p2, aes(x = displ, y = hwy), i = 2, local_only = TRUE, exact = TRUE)
  )
  expect_false(
    ith_mappings_use(p2, aes(x = displ, y = hwy, color = class), i = 2, local_only = TRUE, exact = TRUE)
  )
  expect_true(
    ith_mappings_use(p2, aes(color = class), i = 2, local_only = TRUE, exact = TRUE)
  )
})

test_that("Checks whether layer uses a mapping", {
  expect_true(
    ith_mappings_use(p2, aes(x = displ), i = 2, local_only = FALSE)
  )
  expect_true(
    ith_mappings_use(p2, aes(color = class), i = 2, local_only = FALSE)
  )
  expect_false(
    ith_mappings_use(p2, aes(x = displ), i = 2, local_only = TRUE)
  )
})

test_that("Checks whether layer uses extra mappings", {
  expect_true(
    uses_extra_mappings(p, aes(color = class), local_only = FALSE)
  )
  # first geom_point does not use any extra mappings
  expect_false(
    uses_extra_mappings(get_geom_layer(p2, i = 1), aes(x = displ, y = hwy), local_only = FALSE)
  )
  # but second geom_point does
  expect_true(
    uses_extra_mappings(get_geom_layer(p2, i = 2), aes(x = displ, y = hwy), local_only = FALSE)
  )
  # and it does not have more than required
  expect_false(
    uses_extra_mappings(get_geom_layer(p2, i = 2), aes(x = displ, y = hwy, color = class), local_only = FALSE)
  )
})

test_that("Checks whether layer uses certain aesthetics", {
  # loose
  expect_true(
    uses_aesthetics(p, "x")
  )
  expect_true(
    uses_aesthetics(p, c("x", "y"))
  )
  # exact
  expect_false(
    uses_aesthetics(p, "x", exact = TRUE)
  )
  # at the global layer, this is correct
  expect_true(
    uses_aesthetics(p, c("x", "y"), exact = TRUE)
  )
  # at the local layer, this is false because it is missing the color aesthetic
  expect_false(
    uses_aesthetics(get_geom_layer(p, "point"), c("x", "y"), local_only = TRUE)
  )
  # unless you want to include global layer via `local_only` = FALSE
  expect_true(
    uses_aesthetics(get_geom_layer(p, "point"), c("x", "y"), local_only = FALSE)
  )
  # spelling of color vs colour should not matter
  expect_true(
    uses_aesthetics(get_geom_layer(p, "point"), c("x", "y", "colour"), local_only = TRUE)
  )
  expect_true(
    uses_aesthetics(get_geom_layer(p, "point"), c("x", "y", "color"), local_only = TRUE)
  )
})

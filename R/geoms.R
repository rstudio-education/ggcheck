
#' List the geoms used by a plot
#'
#' \code{get_geoms} returns a vector of geom names, written as character
#' strings, that describes which geoms in which order are used by a plot.
#'
#' @param p A ggplot object
#'
#' @return A vector of character strings. Each element corresponds to the suffix
#'   of a ggplot2 \code{geom_} function, e.g. \code{c("point", "line", "smooth")}.
#'
#' @family functions for checking geoms
#' @export
#'
#' @examples
#' require(ggplot2)
#' p <- ggplot(data = mpg, mapping = aes(x = displ, y = hwy)) +
#'   geom_point(mapping = aes(color = class)) +
#'   geom_smooth()
#' get_geoms(p)
get_geoms <- function(p) {
  n <- n_layers(p)
  vapply(seq_len(n), ith_geom, character(1), p = p)
}

#' List the geom and stat combination used by all layers of a plot.
#'
#' @param p A ggplot object
#'
#' @return A list of lists with a GEOM and STAT character.
#'   e.g. list(list(GEOM = "point", STAT = "identity"))
#'
#' @family functions for checking geoms
#' @export
#'
#' @examples
#' require(ggplot2)
#' p <- ggplot(data = mpg, mapping = aes(x = displ, y = hwy)) +
#'   geom_point(mapping = aes(color = class)) +
#'   geom_smooth()
#' get_geoms_stats(p)
get_geoms_stats <- function(p) {
  if (!inherits(p, "ggplot")) {
    stop("p should be a ggplot object")
  }
  n <- n_layers(p)
  lapply(seq_len(n), ith_geom_stat, p = p)
}

#' Does a plot use one or more geoms?
#'
#' \code{use_geoms} tests whether a plot uses one or more geoms created using a \code{geom}.
#' If checking for a layer that is created using a \code{stat} function, please use
#' \code{uses_stats} instead.
#'
#' By default, the plot must have the exact geoms or geom/stat combinations and in the same order.
#' However, if \code{exact} is set to \code{FALSE}, the plot geoms or geom/stat combinations do not have to be exact.
#'
#' @param p A ggplot object
#' @param geoms A vector of character strings. Each element should correspond to
#'   the suffix of a ggplot2 \code{geom_} function, e.g. \code{c("point",
#'   "line", "smooth")}.
#' @param exact A boolean to indicate whether to use exact matching
#' @param stats A character vector to optionally check for the stats corresponding to geoms
#'   e.g. c("identity", "smooth") if checking c("point", "smooth")
#'
#' @return \code{TRUE} or \code{FALSE}
#'
#' @family functions for checking geoms
#' @export
#'
#' @examples
#' require(ggplot2)
#' p <- ggplot(data = mpg, mapping = aes(x = displ, y = hwy)) +
#'   geom_point(mapping = aes(color = class)) +
#'   geom_smooth()
#' uses_geoms(p, geoms = "point")
#' uses_geoms(p, geoms = c("point", "smooth"), exact = TRUE)
#' uses_geoms(p, geoms = c("point", "smooth"), stats = c("identity", "smooth"))
uses_geoms <- function(p, geoms, stats = NULL, exact = TRUE) {
  # map the GEOM + STAT for the instructor's target geoms
  geoms <- lapply(geoms, map_geom)
  # if stats is specified override the STAT(s) defaults of geoms
  if (!is.null(stats)) {
    # number of stats have to be the same as number of geoms
    if (length(stats) != length(geoms)) {
      stop("Grading error: number of stats supplied don't match number of geoms.")
    }
    # map user supplied stats suffixes to actual class names
    stats <- lapply(stats, map_stat)
    geoms <- lapply(seq_along(geoms), function(g) {
      geoms[[g]]$STAT <- stats[[g]]$STAT
      geoms[[g]]
    })
  }
  # extract the GEOM + STAT for the plot
  pgeoms <- get_geoms_stats(p)
  if (exact) {
    return(identical(geoms, pgeoms))
  } else {
    return(all(geoms %in% pgeoms))
  }
}

#' Does a layer use a specific geom parameter?
#'
#' \code{uses_geom_param} checks that a plot's geom layer uses a specific geom parameter.
#'
#' To specify a specific geom layer, either specify using position using the \code{i} index or
#' by using a combination of \code{geom} function suffix name and \code{i} to check the ith layer that
#' uses the geom.
#'
#' The \code{params} argument accepts a list that contains geom or stat parameters. This offers
#' flexibility in certain situations where setting a parameter on a \code{geom_} function is
#' actually setting a stat parameter. For e.g., in \code{geom_histogram(binwidth = 500)},
#' the \code{binwidth} is a stat parameter. \code{uses_geom_param} will take this into account
#' and check both geom and stat parameters.
#'
#' @param p A ggplot object
#' @param geom A character string found in the suffix of a ggplot2 geom function,
#'  e.g. \code{"point"}.
#' @param params A named list of geom or stat parameter values, e.g. \code{list(outlier.alpha = 0.01)}
#' @param i A numerical index, e.g. \code{1}.
#'
#' @return A boolean
#' @export
#'
#' @examples
#' require(ggplot2)
#' p <- ggplot(data = diamonds, aes(x = cut, y = price)) +
#'   geom_boxplot(varwidth = TRUE, outlier.alpha = 0.01)
#' uses_geom_param(p, geom = "boxplot", params = list(varwidth = TRUE, outlier.alpha = 0.01))
uses_geom_param <- function(p, geom, params, i = NULL) {
  layer <- get_geom_layer(p, geom = geom, i = i)$layer
  user_params <- names(params)
  # collect geom and stat parameters
  all_params <- c(layer$geom_params, layer$stat_params)
  p_params <- names(all_params)
  # check if user supplied invalid parameters
  invalid_params <- !(user_params %in% p_params)
  if (any(invalid_params)) {
    stop(
      "Grading error: the supplied parameters ",
       paste0("'", user_params[invalid_params], "'", collapse = ", "), " are invalid."
    )
  }
  # check both the user parameters contained in plot's geom and stat parameters
  identical(params, all_params[user_params])
}

#' Which geom is used in the ith layer?
#'
#' \code{ith_geom} returns the type of geom used by the ith layer.
#'
#' @param p A ggplot object
#' @param i A numerical index that corresponds to the first layer of a plot (1),
#'   the second layer (2), and so on.
#'
#' @return A character string that corresponds to the suffix of a ggplot2
#'   \code{geom_} function, e.g. \code{"point"}.
#'
#' @family functions for checking geoms
#' @export
#'
#' @examples
#' require(ggplot2)
#' p <- ggplot(data = mpg, mapping = aes(x = displ, y = hwy)) +
#'   geom_point(mapping = aes(color = class)) +
#'   geom_smooth()
#' ith_geom(p, i = 2)
ith_geom <- function(p, i) {
  if (!inherits(p, "ggplot")) {
    stop("p should be a ggplot object")
  }
  geom <- class(p$layers[[i]]$geom)[1]
  gsub("geom", "", tolower(geom))
}

#' Which geom/stat combination is used in the ith layer?
#'
#' \code{ith_geom_stat} returns the type of geom used by the ith layer
#' according to a geom/stat combination.
#'
#' @param p A ggplot object
#' @param i A numerical index that corresponds to the first layer of a plot (1),
#'   the second layer (2), and so on.
#' @return A list of lists with a GEOM and STAT strings, each corresponding to the suffix of a ggplot2
#'   \code{geom_} function (e.g. \code{"point"}), and  \code{stat_} function (e.g. \code{"identity"}).
#'   e.g. list(list(GEOM = "point", STAT = "identity"))
#'
#' @family functions for checking geoms
#' @export
#'
#' @examples
#' require(ggplot2)
#' p <- ggplot(data = mpg, mapping = aes(x = displ, y = hwy)) +
#'   geom_point(mapping = aes(color = class)) +
#'   geom_smooth()
#' ith_geom_stat(p, i = 2)
ith_geom_stat <- function(p, i) {
  # extract geom/stat classes
  geom_class <- gsub("geom", "", tolower(class(p$layers[[i]]$geom)[1]))
  stat_class <- gsub("stat", "", tolower(class(p$layers[[i]]$stat)[1]))
  # return combination
  geom_stat(
    geom = geom_class,
    stat = stat_class
  )
}

#' Is the ith geom what it should be?
#'
#' \code{ith_geom_is} checks whether the ith layer uses the prescribed type of geom.
#'
#' @param p A ggplot object
#' @param geom A character string that corresponds to
#'   the suffix of a ggplot2 \code{geom_} function, e.g. \code{"point"}.
#' @param i A numerical index that corresponds to the first layer of a plot (1),
#'   the second layer (2), and so on. \code{ith_geom_is} will check the
#'   geom used by the ith layer.
#'
#' @return \code{TRUE} or \code{FALSE}
#'
#' @family functions for checking geoms
#'
#' @export
#'
#' @examples
#' require(ggplot2)
#' p <- ggplot(data = mpg, mapping = aes(x = displ, y = hwy)) +
#'   geom_point(mapping = aes(color = class)) +
#'   geom_smooth()
#' ith_geom_is(p, geom = "smooth", i = 2)
ith_geom_is <- function(p, geom, i = 1) {
  geom_i <- ith_geom(p, i)
  geom_i == geom
}

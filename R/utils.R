# Created by: Craig Thamotheram
# Created on: 19/02/2022

#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 or 3 of the License
#  (at your option).
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  A copy of the GNU General Public License is available at
#  http://www.r-project.org/Licenses/

#' @title Compute log growth rate of cumulated dataset
#
#' @description Helper method to compute the log growth rates of cumulated
#' variables. It will compute the log cumulative growth rate for each column in
#' the data frame.
#'
#' @param dt Cumulated data series.
#' @returns A data frame of log growth rates of the cumulated variable which has
#' been inputted via the parameter \code{dt}.
#'
#' @examples
#' library(tsgc)
#' data(gauteng,package="tsgc")
#' df2ldl(gauteng)
#'
#'
#' @export
df2ldl <- function(dt) {
  dt.ldl <- log(diff(dt) / stats::lag(dt))
  return(dt.ldl)
}


#' @title Reinitialise a data frame by subtracting the `reinit.date` row from
#' all columns
#'
#' @param dt Cumulated data series.
#' @param reinit.date Reinitialisation date. E.g. \samp{'2021-05-12'}.
#'
#' @returns The reinitialised data frame
#'
#' @examples
#' library(tsgc)
#' data(gauteng,package="tsgc")
#' reinitialise_dataframe(gauteng,as.Date("2021-01-01"))
#'
#' @export
reinitialise_dataframe <- function(dt, reinit.date) {
  # Take cumulative dataframe and reinit from reinit.date as first date of data
  # 1. Get data frame including date before reinit.date
  dt <- dt[index(dt) >= as.Date(reinit.date) - 1,]

  # 2. Substract away the t-1 date data
  dt <- sweep(dt, 2, dt[1,])

  # 3. Keep only data from t onwards.
  dt <- dt[index(dt) >= as.Date(reinit.date),]
  return(dt)
}


#' @title Return index and value of maximum
#' @description Something similar to Python's argmax.
#' @param x Object to have its maximum found
#' @param decreasing Logical value indicating whether \code{x} should be
#' ordered in decreasing order. Default is \code{TRUE}. Setting this to
#' \code{FALSE} would find the minimum.
#' @returns The maximum value and its index.
#' @examples
#' library(tsgc)
#' data(gauteng,package="tsgc")
#' argmax(gauteng)
#' @export
argmax <- function(x, decreasing=TRUE) {
  return(x[order(x, decreasing = decreasing)[1]])
}


#' @title Write a selection of relevant results to disc
#'
#' @description Function writes the following results to csv files which get
#' saved in the location specified in \code{res.dir}: forecast new cases or
#' incidence variable, \eqn{y}; the filtered level and slope of \eqn{\ln g},
#' \eqn{\delta} and \eqn{\gamma}; filtered estimates of \eqn{g_y} and the
#' confidence intervals for these estimates.
#'
#' @param res Results object estimated using the \samp{estimate()} method.
#' @param  res.dir File path to save the results to.
#' @param Y Cumulated variable.
#' @param n.ahead Number of periods ahead to forecast.
#' @param confidence.level Confidence level to use for the confidence interval
#' on the forecasts \eqn{\ln(g_t)}.
#' 
#' @importFrom utils write.csv
#' @importFrom stats qnorm
#'
#' @returns A number of csv files saved in the directory specified in
#' \code{res.dir}.
#' @examples
#' # Not run as do not wish to save to local disc when compiling documentation.
#' # Below will run if copied and pasted into console.
#' library(tsgc)
#' library(here)
#'
#' res.dir <- tempdir()
#' data(gauteng,package="tsgc")
#' idx.est <- zoo::index(gauteng) <= as.Date("2020-07-06")
#' res <- SSModelDynamicGompertz$new(Y = gauteng[idx.est], q = 0.005)$estimate()
#'
#' tsgc::write_results(
#' res=res, res.dir = res.dir, Y = gauteng[idx.est], n.ahead = 14,
#' confidence.level = 0.68
#' )
#'
#' @export
write_results <- function(res, res.dir, Y, n.ahead, confidence.level) {

  est.date.index <- res$index %>% as.Date()
  y.level.est <- Y[est.date.index]

  # 1. New Cases - Delta Y
  y.hat.diff <- res$predict_level(
    y.cum = y.level.est,
    n.ahead = n.ahead,
    confidence_level = confidence.level,
    sea.on = TRUE,
    return.diff = TRUE
  )
  write.csv(
    y.hat.diff,
    row.names = index(y.hat.diff),
    file = file.path(res.dir, "y-forecast.csv")
  )

  # 2. Filtered slope / level
  y.hat.all <- res$predict_all(n.ahead, return.all = TRUE)
  filtered.level <- y.hat.all$level.t.t
  filtered.slope <- y.hat.all$slope.t.t
  a.t.t <- y.hat.all$a.t.t
  P.t.t <- y.hat.all$P.t.t
  idx.slope <- grep("slope", colnames(a.t.t))
  idx.level <- grep("level", colnames(a.t.t))
  gamma.std.err <- sqrt(P.t.t[idx.slope, idx.slope,])
  delta.std.err <- sqrt(P.t.t[idx.level, idx.level,])
  gamma <- cbind(filtered.slope, gamma.std.err)
  delta <- cbind(filtered.level, delta.std.err)
  colnames(gamma) <- c("gamma", "std.err")
  colnames(delta) <- c("delta", "std.err")
  write.csv(
    gamma,
    row.names = index(filtered.slope),
    file = file.path(res.dir, "gamma_filtered.csv")
  )
  write.csv(
    delta,
    row.names = index(filtered.level),
    file = file.path(res.dir, "delta_filtered.csv")
  )

  # 3. Filtered growth rate of new cases (g_{y}) - CI from standard error on
  # slope component of
  # state covariance matrix.
  g.y.t.t <- exp(filtered.level) + filtered.slope
  ci <- qnorm((1 - confidence.level) / 2) * gamma.std.err %o% c(1, -1)
  ci_bounds <- as.vector(g.y.t.t) + ci
  gy.ci <- xts(cbind(fit = g.y.t.t, prediction = ci_bounds),
               order.by = index(filtered.level))
  names(gy.ci)[2:3] <- list('lower', 'upper')

  write.csv(
    gy.ci,
    row.names = index(g.y.t.t),
    file = file.path(res.dir, "g_y_filtered.csv")
  )

}



#' @title Returns forecast of number of periods until peak given
#' \code{KFAS::KFS} output.
#'
#' @description Since Harvey and Kattuman (2021) show that \deqn{g_{y,t+\ell|T}
#' = \exp\{\delta_{T|T}+\ell \gamma_{T|T}\}+\gamma_{T|T},} we can compute the
#' \eqn{\ell} for which \eqn{g_{y,t}=0} and then will fall below zero. This
#' \eqn{\ell} is given by
#' \deqn{\ell = \frac{\ln(-\gamma_{T|T})-\delta_{T|T}}{\gamma_{T|T}}.} This is
#' predicated on \eqn{\gamma_{T|T}<0}, else there is super-exponential growth
#' and no peak in sight. Of course, it only makes sense to investigate an
#' upcoming peak for \eqn{g_{y,T|T}>0} (when cases are growing). The estimates
#' of \eqn{\delta_{T|T}} and \eqn{\gamma_{T|T}} are extracted from the
#' \code{KFS} object passed to the function.
#'
#' @param kfs_out The \code{KFAS::KFS} object for which the forecast peak is to
#' be calculated. This would be the \code{output} element of a model estimated
#' in the \code{SSModelDynamicGompertz} or \code{SSModelDynamic}
#'
#' @returns Forecast of number of periods until peak.
#'
#' @examples
#' library(tsgc)
#' data(gauteng,package="tsgc")
#' idx.est <- zoo::index(gauteng) <= as.Date("2020-07-06")
#'
#' res <- SSModelDynamicGompertz$new(Y = gauteng[idx.est], q = 0.005)$estimate()
#'
#' forecast_peak(res$output)
#'
#' @export
forecast_peak <- function(kfs_out) {
  stopifnot(class(kfs_out) == "KFS")
  n <- attr(kfs_out$model, "n")
  delta.t.t <- kfs_out$att[n, 'level']
  gamma.t.t <- kfs_out$att[n, 'slope']
  if (gamma.t.t > 0) {
    return(Inf)
  } else {
    return(forecast.peak(delta = delta.t.t, gamma = gamma.t.t)
    )
  }
}


#' @title Returns forecast of number of periods until peak given estimated
#' state variables \eqn{\delta} and \eqn{\gamma}.
#'
#' @description Since Harvey and Kattuman (2021) show that
#' \deqn{g_{y,t+\ell|T} = \exp\{\delta_{T|T}+\ell \gamma_{T|T}\}+\gamma_{T|T},}
#' we can compute the \eqn{\ell} for which \eqn{g_{y,t}=0} and then will fall
#' below zero. This \eqn{\ell} is given by
#' \deqn{\ell = \frac{\ln(-\gamma_{T|T})-\delta_{T|T}}{\gamma_{T|T}}.} This is
#' predicated on \eqn{\gamma_{T|T}<0}, else there is super-exponential growth an
#' no peak in sight. Of course, it only makes sense to investigate an upcoming
#' peak for \eqn{g_{y,T|T}>0} (when cases are growing).
#'
#' @param delta The estimate of \eqn{\delta}, the level of \eqn{\ln g}.
#' @param gamma The estimate of \eqn{\gamma}, the slope of \eqn{\ln g}.
#'
#' @examples
#' # Forecasts the peak of an epidemic with gamma < 0 so that a peak is in
#' # sight.
#' forecast.peak(-2.87,-0.045)
#'
#' # Does not return a result (returns an error as gamma > 0)
#' try(forecast.peak(-2.87,0.045), silent=TRUE)
#'
#' @returns Forecast of number of periods until peak.
#'
#' @export
forecast.peak <- function(delta, gamma) {
  # if numerator positive then get negative forecast for ell^*
  # stopifnot(log(-gamma) - delta < 0)
  # If gamma positive then no saturation level.
  stopifnot(gamma < 0)
  return(
    as.numeric(
      (log(-gamma) - delta) / gamma
    ))
}

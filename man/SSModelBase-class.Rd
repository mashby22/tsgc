% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/SSModelBase.R
\docType{class}
\name{SSModelBase-class}
\alias{SSModelBase-class}
\alias{SSModelBase}
\title{Base class for estimating time-series growth curve models. Classes
\code{SSModelDynamicGompertz} and \code{SSModelDynGompertzReinit} refer back
to this base class.}
\description{
Base class for estimating time-series growth curve models. Classes
\code{SSModelDynamicGompertz} and \code{SSModelDynGompertzReinit} refer back
to this base class.
}
\section{Methods}{

\describe{
\item{\code{estimate(sea.type = "trigonometric", sea.period = 7)}}{Estimates the dynamic Gompertz curve model when applied to an object of
class \code{SSModelDynamicGompertz} or \code{SSModelDynGompertzReinit}.
\subsection{Parameters}{\itemize{
  \item{\code{sea.type} Seasonal type. Options are
  \code{'trigonometric'} and \code{'none'}. \code{'trigonometric'} will
   yield a model with a trigonometric seasonal component and
   \code{'none'} will yield a model with no seasonal component.}
  \item{\code{sea.period} The period of seasonality. For a
  day-of-the-week effect with daily data, this would be 7. Not required
  if \code{sea.type = 'none'}.}
}}
\subsection{Return Value}{An object of class \code{FilterResults}
containing the result output for the estimated dynamic Gompertz curve
model.}}

\item{\code{get_dynamic_gompertz_model(
  y,
  q = NULL,
  sea.type = "trigonometric",
  sea.period = 7,
  a1 = NULL,
  P1 = NULL,
  Q = NULL,
  H = NULL
)}}{Returns dynamic Gompertz curve model.
    \subsection{Parameters}{\itemize{
      \item{\code{y} The cumulated variable}
      \item{\code{q} The signal-to-noise ratio (ratio of slope to irregular
      variance). Defaults to \code{'NULL'}, in which case no signal-to-noise
      ratio will be imposed. Instead, it will be estimated.}
      \item{\code{sea.type} Seasonal type. Options are \code{'trigonometric'}
       and \code{'none'}. \code{'trigonometric'} will yield a model with a
       trigonometric seasonal component and \code{'none'} will yield a model
       with no seasonal component.}
      \item{\code{sea.period} The period of seasonality. For a day-of-the-week
       effect with daily data, this would be 7. Not required if
       \code{sea.type = 'none'}.}
      \item{\code{a1} Optional parameter specifying the prior mean of the
      states. Defaults to \code{'NULL'}. Leave as \code{'NULL'} for a diffuse
      prior (no prior information). If a proper prior is to be specified, both
      \code{a1} and \code{P1} must be given.}
      \item{\code{P1} Optional parameter specifying the prior mean of the
      states. Defaults to \code{'NULL'}. Leave as \code{'NULL'} for a diffuse
       prior (no prior information). If a proper prior is to be specified,
       both \code{a1} and \code{P1} must be given.}
      \item{\code{Q} Optional parameter specifying the state error variances
      where these are to be imposed rather than estimated. Defaults to
      \code{'NULL'} which will see the variances estimated.}
      \item{\code{H} Optional parameter specifying the irregular variance
      where this is to be imposed rather than estimated. Defaults to
      \code{'NULL'} which will see the variance estimated.}
    }}
    \subsection{Description}{
    The dynamic Gompertz with an integrated random walk (IRW) trend is
    \deqn{\ln g_{t}=\delta_{t}+\varepsilon_{t},  \;\;\;\;
    \varepsilon_{t}\sim NID(0,\sigma_{\varepsilon }^{2}), \;\;\;\;
    t=2,...,T, }
    where \eqn{Y_t} is the cumulated variable, \eqn{y_t = \Delta Y_t},
    \eqn{\ln g_{t}=\ln y_{t}-\ln Y_{t-1}} and
    \deqn{\delta_{t} =\delta_{t-1}+\gamma_{t-1},}
    \deqn{\gamma_{t} =\gamma_{t-1}+\zeta_{t}, \;\;\;\;
    \zeta_{t}\sim NID(0,\sigma_{\zeta }^{2}),}
    where the observation disturbances \eqn{\varepsilon_{t}}  and slope
    disturbances \eqn{\zeta_{t}}, are iid Normal and mutually independent.
    Note that, the larger the signal-to-noise ratio,
    \eqn{q_{\zeta }=\sigma_{\zeta }^{2}/\sigma_{\varepsilon }^{2}},
    the faster the slope changes in response to new observations. Conversely,
    a lower signal-to-noise ratio induces smoothness.

    For the model without seasonal terms (\code{sea.type = 'none'}) the are
    priors are
    \deqn{\begin{pmatrix} \delta_1 \ \gamma_1 \end{pmatrix}
    \sim N(a_1,P_1)}.
    The diffuse prior has \eqn{P_1 = \kappa I_{2\times 2}} with
    \eqn{\kappa \to \infty}. Implementation of the diffuse prior is handled
     by the package \code{KFAS} (Helske, 2017). Where the model has a seasonal
      component (\code{sea.type = 'trigonometric'}), the vector of prior means
       \eqn{a_1} and the prior covariance matrix \eqn{P_1} are extended
       accordingly.

    See the vignette for details of the variance matrix \eqn{Q}.
    \eqn{H = \sigma^2_{\varepsilon}}.
    }
    }

\item{\code{update(pars, model, q, sea.type)}}{Update method for Kalman filter to implement the dynamic Gompertz curve
 model.
 A maximum of 3 parameters are used to set the observation noise
 (1 parameter), the transition equation slope and seasonal noise. If q (signal
  to noise ratio) is not null then the slope noise is set using this
  ratio.
 \subsection{Parameters}{\itemize{
  \item{\code{pars} Vector of parameters.}
  \item{\code{model} \code{KFS} model object.}
  \item{\code{q} The signal-to-noise ratio (ratio of slope to irregular
   variance).}
  \item{\code{sea.type} Seasonal type. Options are
  \code{'trigonometric'} and \code{'none'}.}
}}
\subsection{Return Value}{\code{KFS} model object.}}
}}

\examples{
library(tsgc)
data(gauteng,package="tsgc")
idx.est <- zoo::index(gauteng) <= as.Date("2020-07-06")

# Specify a model
model <- SSModelDynamicGompertz$new(Y = gauteng[idx.est], q = 0.005)
# Estimate a specified model
res <- model$estimate()
}

rectangle = function(x, y, log=c(), ...) {
  symbols(x=mean(x),
          y=mean(y),
          rectangles=cbind(diff(x),
                           diff(y)),
          inches=F,
          ...)
}


#' ROCplots
#'
#' A variety of ROC-related plots for a binary target and a single continuous predictor.
#'
#' @param data Data frame with columns "class" (binary target variable) and "X" (predictor).
#' @param whichPlots Which plots to do. Options are c("density", "raw", "ROC", "pv", "nnt")
#' @param NNTlower Subjective input. If NNT < NNTlower, the decision is clearly to Treat.
#' @param NNTupper Subjective input. If NNT > NNTupper, the decision is clearly to Wait.
#' @param N For simulated data: sample size
#' @param prev For simulated data: Prevalence
#' @param diffInSd For simulated data: Difference: E(X | group=1) - E(X | group=0),measured in units of S.D (common to the 2 groups).
#' @param ... Extra arguments for a plot. Do not supply unless length(whichPlots)==1.
#' @details  The plots display the values achievable by changing the cutoff, in comparison with the desired values as determined by NNTlower and NNTupper.
#' The "whichPlots" options are as follows:
#' \itemize{
#'  \item{"density"}{Marginal density of X, with rug.}
#'  \item{"raw"}{X versus class.}
#'  \item{"ROC"}{Standard ROC curve.}
#'  \item{"pv"}{Plot of ppv versus npv, with indication of the acceptable range for cutoff.}
#'  \item{"nnt"}{Plot of NNTpos versus NNTneg, with indication of the acceptable region}
#'  \item{"nntRange"}{Plot of NNTpos and NNTneg versus cutoff, with indication of the acceptable range.}
#'
#' By default, all the plots are made.
#' }


ROCplots = function(data,
                    whichPlots=c("density", "raw", "ROC", "pv", "nnt", "nntRange"),
                    NNTlower=3, NNTupper=10,
                    N= 1000, prev=0.2, diffInSD=2,
                    ...) {
  print(whichPlots)
  print(missing(...))
  if(!missing(...) & length(whichPlots) > 1)
    stop("Please, only use ... if length(whichPlots) == 1")
  seeThroughGrey = paste0("#404040", "88")
  seeThroughBlue =   paste0(rgb(0,0,.5), "22")
  seeThroughRed = paste0(rgb(0.9,0.1,.1), "22")
  Usr = function()par()$usr
  UsrX = function()Usr()[1:2]
  UsrY = function()Usr()[3:4]
  if(missing(data)) {  ## Simulate
    muD=0; muN=diffInSD; sd=1
    class = rbinom(N, 1, prev)
    X = rnorm(N, c(muD, muN)[1+class], sd)
    weights = rep(1, length(X))  ### Multiplicity
    data = data.frame(class=class, X=X, weights=weights)
  }
  else {
    class = data$class
    X = data$X
    if(!is.null(data$weights))
      weights = data$weights
    else
      weights = rep(1, length(X))
  }
  N = nrow(data)
  nD = sum(class)
  nH = N - nD
  data = data.frame(class, X) [order(X), ]

  if(is.element(el = "density", set=whichPlots)) {
    plot(density(X, weights = weights/sum(weights)), ...)
    rug(X)
  }

  if(is.element(el = "raw", set=whichPlots))
    plot(X, class)
  sens = (nD - cumsum(data$class == 1))/ nD  # 1 - FN/nD = (TP/nD)
  spec = cumsum(data$class == 0)/nH       # TN/nH
  if(is.element(el = "ROC", set=whichPlots))
    plot(1-spec, sens, type="l", ...)

  ### You can't plot ppv versus npv at the -Inf or +Inf cutoffs,
  ### unlike ROCs. You need at least one Pos and one Neg.
  # Thus we cut off the top cutoff.
  # Ranks for cutoffs:
  nPos = (N-1):1
  nNeg = 1:(N-1)
  ## vectors of ppv and npv for all cutoffs.
  ppv = (nD - cumsum(data$class == 1))[-N]/ nPos  #  TP/Pos
  npv = cumsum(data$class == 0)[-N]/ nNeg  ## TN/Neg

  if(is.element(el = "pv", set=whichPlots)) {
    if(N <= 10)
      plot(ppv, npv, type="b", pch=as.character(1:N))
    else
      plot(ppv, npv, type="l")
    ppvMin = 1/NNTlower
    npvMin = 1 - 1/NNTupper
    lines(c(ppvMin, ppvMin), c(npvMin, 1), col="blue")
    lines(c(ppvMin, 1), c(npvMin, npvMin), col="blue")
  }

  ## plotting NNTpos vs NNTneg is even more limited, because, well, infinity.
  NNTpos = 1/ppv
  NNTneg = 1/(1-npv)
  if(is.element(el = "nnt", set=whichPlots)) {
    if(N <= 10)
      plot(NNTpos, NNTneg, log="y", type="b", pch=as.character(1:N))
    else
      plot(NNTpos, NNTneg, log="y", type="l")
    lines(c(UsrX()[1], NNTlower), c(NNTupper,NNTupper), lty=2, col="blue")
    lines(c(NNTlower, NNTlower), c(10^UsrY()[2],NNTupper), lty=2, col="blue")
    legend("topleft", legend="acceptable region", box.col="blue", text.col="blue")
    rect(Usr()[1], 10^Usr()[3], Usr()[2], NNTupper,
              col=seeThroughRed)
    rect(NNTlower, 10^Usr()[3], Usr()[2], 10^Usr()[4],
              col=seeThroughRed)
    text(x=Usr()[1], y=NNTupper, col="blue", labels = "NNTupper",
         xpd=NA, adj=c(0,0), cex=0.7)
    text(x=NNTlower, y=10^Usr()[4], col="blue", labels = "NNTlower",
         xpd=NA, pos=3, cex=0.7)
#     legend(x="topright",
#            legend="NNTnegTooSmall", text.col="red", cex=0.5,
#           bg=seeThroughRed)
    text(mean(c(UsrX()[2], NNTlower)),
         10^mean(c(log10(NNTupper), UsrY()[2])),
         "NNTposTooBig",
         col="red"
         #, adj=c(1,1)
         )
    text(mean(c(UsrX()[1], NNTlower)),
         10^mean(c(log10(NNTupper), UsrY()[1])),
         "NNTnegTooSmall",
         col="red"
#         , adj=c(0,0)
    )
  }

  if(is.element(el = "nntRange", set=whichPlots)) {
    Xtrunc = data$X[-length(data$X)]   # [-1]
    plot(c(NNTpos, NNTneg), c(Xtrunc, Xtrunc), pch="",
         ylab="cutoff", xlab="NNT", log="x")
    crossovers = c(min(Xtrunc[NNTpos <= NNTlower]),
                   max(Xtrunc[NNTupper <= NNTneg]))
    NNTneg = pmin(NNTneg, 10^Usr()[2])
    # abline(v=c(NNTlower, NNTupper))
    lines(x=c(NNTlower, NNTlower), y=c(Usr()[3], crossovers[2]))
    lines(x=c(NNTupper, NNTupper), y=c(Usr()[4], crossovers[1]))
    text(x=NNTlower, y=Usr()[3], "NNTlower", col="blue",
         srt=90, pos=4, xpd=NA, cex=0.7)
    text(x=NNTupper, y=Usr()[4], "NNTupper", col="blue",
         srt=90, adj=c(1,1), xpd=NA, cex=0.7)
    # abline(h=crossovers)
    NNTposTooBig = which(Xtrunc <= crossovers[1])
    NNTnegTooSmall = which(Xtrunc >= crossovers[2] & ppv > 0)
    invalid = c(NNTposTooBig, NNTnegTooSmall)
    valid = which(
      (Xtrunc >= crossovers[1]
       & Xtrunc <= crossovers[2])
    )
    lines(NNTpos, Xtrunc)
    lines(NNTneg, Xtrunc)
    polygon(x=c(NNTpos[valid], rev(NNTneg[valid])),
            y=c(Xtrunc[valid], rev(Xtrunc[valid])),
            col=seeThroughBlue)
    polygon(x=c(NNTpos[NNTposTooBig], rev(NNTneg[NNTposTooBig])),
            y=c(Xtrunc[NNTposTooBig], rev(Xtrunc[NNTposTooBig])),
            col=seeThroughRed)
    polygon(x=c(NNTpos[NNTnegTooSmall], rev(NNTneg[NNTnegTooSmall])),
            y=c(Xtrunc[NNTnegTooSmall], rev(Xtrunc[NNTnegTooSmall])),
            col=seeThroughRed)
    geometricMean = function(x) exp(mean(log(x)))
    text(x=geometricMean(c(NNTlower, NNTupper)),
         y=mean(Xtrunc[valid]),
         labels="acceptable\ncutoffs", col="blue", bg="white")
    text(x=geometricMean(NNTpos[valid]),
         y=mean(Xtrunc[valid]),
         labels="NNTpos", col="blue", bg="white",
         pos=2, xpd=NA, cex=0.7)
    text(x=geometricMean(NNTneg[valid]),
         y=mean(Xtrunc[valid]),
         labels="NNTneg", col="blue", bg="white",
         pos=4, xpd=NA, cex=0.7)
    text(x=geometricMean(c(NNTpos[NNTnegTooSmall], NNTneg[NNTnegTooSmall])),
         y=mean(Xtrunc[NNTnegTooSmall]),
         labels="NNTneg \ntoo small", col="red")
    text(x=geometricMean(c(NNTpos[NNTposTooBig], NNTneg[NNTposTooBig])),
         y=mean(Xtrunc[NNTposTooBig]),
         labels="NNTpos \ntoo big", col="red")
    #   symbols(NNTupper, mean(crossovers),
    #           rectangles=cbind(10, diff(crossovers)),
    #           inches=F,
    #           bg=seeThroughGrey, add=TRUE)
    #   rectangle(Usr()[1:2], crossovers,
    #             bg=seeThroughGrey, add=TRUE, log="x")
  }
  return(invisible(data))
}
theData = ROCplots()
####  shinyElicit server
appName = "shinyElicit"

shinyServerFunction =
  function(input, output, session) {
    thisSession <<- session

    #source("conveniences.R", local=TRUE)
    source("debugTools.R", local=TRUE)
    source("contraBayesPlot.R", local=TRUE)

    observe({
      if(!is.null(input$contraBayesPlot_click)) {
        ppv = input$contraBayesPlot_click$x
        npv = input$contraBayesPlot_click$y
        nnts = pv.to.NNT(ppv = ppv, npv = npv)
        catn("nnts observed: ", nnts[[1]], nnts[[2]])
        if(all(!is.nan(nnts))) {
          updateNumericInput(session, inputId="NNTneg",
                             value=round(nnts[[2]]))
          updateNumericInput(session, inputId="NNTpos",
                             value=round(nnts[[1]]))
        }
       }
    })

    source("plotDiscomfort.R", local=TRUE)

    #     NNTgap = 1
    #     observe( {
    #       updateNumericInput(session, inputId="NNTpos",
    #                          value=min(input$NNTpos,
    #                                    isolate(input$NNTlower-NNTgap)),
    #                          max = isolate(input$NNTlower-NNTgap))
    #     })
    #     observe( {
    #       updateNumericInput(session, inputId="NNTlower",
    #                          value=max(input$NNTlower,
    #                                    isolate(input$NNTpos+NNTgap)),
    #                          min = isolate(input$NNTpos+NNTgap))
    #     })
    #     observe( {
    #       updateNumericInput(session, inputId="NNTneg",
    #                          value=max(input$NNTneg,
    #                                    isolate(input$NNTupper+NNTgap)),
    #                          min = isolate(input$NNTupper+NNTgap))
    #     })
    #     observe( {
    #       updateNumericInput(session, inputId="NNTupper",
    #                          value=min(input$NNTupper,
    #                                    isolate(input$NNTneg-NNTgap)),
    #                          max = isolate(input$NNTneg-NNTgap))
    #     })
    output$plotDiscomfort = renderPlot({
      plotDiscomfort(drawPosNeg=FALSE,
                     NNTlower = input$NNTlower,
                     NNTupper = input$NNTupper)
    }
    #, height=280
    )

    PPVderived = reactive({1/input$NNTpos})
    output$PPVderived = renderText({PPVderived()})
    NPVderived = reactive({1 - 1/input$NNTneg})
    output$NPVderived = renderText({NPVderived() })

    output$plotNNTgoals = renderPlot({
      plotDiscomfort(drawPosNeg=TRUE,
                     NNTlower = input$NNTlower,
                     NNTupper = input$NNTupper,
                     NNTpos = input$NNTpos,
                     NNTneg = input$NNTneg)
    }
    #, height=280
    )

    observe({
      nPos = input$samplesizePositives
      NNTposConfIntProspective = 1 / binom.confint(
        k=round( nPos * 1/input$NNTpos), nPos, alpha=0.10)

    })
  }
#debug(shinyServerFunction)
shinyServer(func=shinyServerFunction)


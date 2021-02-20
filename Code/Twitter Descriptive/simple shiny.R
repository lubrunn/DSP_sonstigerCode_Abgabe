#gc()

library(shiny)
ui <- fluidRow(
  sliderInput("retweets", "Minimum number of rt", min = 0, max = 300, value = 0),
  dataTableOutput("raw_data")
)

server <- function(session, input, output){
  output$raw_data <- renderDataTable({
    data.table::data.table(tweets_read_test)
  }) 
}

shinyApp(ui, server)
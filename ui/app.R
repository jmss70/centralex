library(shiny)

ui <- fluidPage(
  titlePanel(h1("Displex user interface")),
  mainPanel(h2("File to process"),
            fileInput("file",
                      "Choose file to load"),
            h2("Model to apply"),
            radioButtons("model", "Model to apply",
                         choices = list("Lopez-Strassburger",
                                        "Avila-Sanchez (Zipf + Additive)",
                                        "Exponential + Aditive")),
            submitButton("Submit"))
)

server <- function(input, output, session) {

}

shinyApp(ui, server)

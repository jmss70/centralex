library(shiny)
library(displex)
library(tidyverse)

models = data.frame(name=c("Lopez-Strassburger",
                           "Avila-Sanchez (Zipf + Additive)"),
                    funct=c('build.lopezstrass.availability',
                               'build.avilasanchez.availability'))

generateInform <- function(file, model) {
  data <- read.displex(file$datapath)
  centers <- data %>% select(centers) %>% arrange(centers) %>% unique() %>% pull()
  model <- models %>% filter(name==model) %>% select(funct) %>% pull()
  content <-
    c('---',
  'title: "Presentación Displex"',
  'output:',
  '  pdf_document: default',
  'html_notebook: default',
  'html_document:',
  '  df_print: paged',
  'word_document: default',
  'always_allow_html: yes',
  '---',
  '*Store this file in the same directory where your data is stored')

  content <- c(content,
               '# Carga de librerías',
               '```{r message = FALSE, warning = FALSE}',
               'library(tidyverse)',
               'library(displex)',
               '```')
  content <- c(content,
               '# Carga de datos',
               '```{r}',
               paste('data <- read.displex("', file$name,'")', sep="", collapse=""),
               'data %>% head()',
               '```',
               '')
  content <- c(content,
               '# Modelo de disponibilidad',
               '```{r}',
               paste('disponibilidad <- ', model, '(data)', sep="", collapse=""),
               'disponibilidad %>% head()',
               '```',
               '')
  content <- c(content,
               "## Centros de interés")

  for (center in centers) {
    content <- c(content,
                 paste(c('### Centro de interés: ', center), sep="", collapse=""),
                 '```{r eval=FALSE}',
                 'disponibilidad %>% ',
                 paste(c('  filter(centers=="', center, '") %>% '), sep="", collapse=""),
                 '  arrange(-availability)',
                '```',
                '',
                '```{r}',
                'disponibilidad %>% ',
                paste(c('  filter(centers=="', center, '") %>% '), sep="", collapse=""),
                '  arrange(-availability) %>% ',
                '  ggplot(aes(x=order, y=availability)) + geom_line() +',
                '  xlab("Sucesión de palabras") + ylab("Disponibilidad")',
                '```',
                '')
  }

  content = c(content,
              '## Visión general de los centros de interés',
              '```{r}',
              'disponibilidad %>%',
              '  arrange(-availability) %>% ',
              '  ggplot(aes(x=order,y=availability)) + geom_line() + facet_wrap(~centers)  +',
              '  xlab("Secuencia de palabras (por grado descendente de compatibilidad)") + ',
              '  ylab("Disponibilidad")',
              '```',
              '')
  content = c(content,
              '# Grupos de compatiblidad',
              '```{r}',
              'levels <- classify.availability.levels(disponibilidad)',
              '```',
              '')
  content <- c(content,
               "## Centros de interés")

  for (center in centers) {
    content <- c(content,
                 paste(c('### Centro de interés: ', center), sep="", collapse=""),
                 '```{r eval=FALSE}',
                 'levels %>% ',
                 '   arrange(-availability) %>%',
                 '   select(-order)',
                 '```',
                 ' ',
                 '```{r}',
                 'levels %>%',
                 paste(c('  filter(centers=="', center, '") %>% '), sep="", collapse=""),
                 '  mutate(level=factor(level)) %>% ',
                 '  arrange(-availability) %>% ',
                 '  ggplot(aes(x=order,y=availability,color=level)) + geom_line() +',
                 '  xlab("Posición del término en el centro de interés") +',
                 '  ylab("Disponibilidad")',
                 '```',
                 '',
                 '```{r}',
                 'clasificacion <- build.availability.levels(levels)',
                 '```',
                 '```{r}',
                 'clasificacion %>%',
                 '  filter(levels> 0) %>%',
                 paste(c('  filter(centers=="', center, '") %>% '), sep="", collapse=""),
                 '```',
                 '```{r eval=FALSE}',
                 'clasificacion %>% ',
                 '  filter(levels == 0) %>%',
                 paste(c('  filter(centers=="', center, '") %>% '), sep="", collapse=""),
                 '```')
  }

  paste(content, sep="", collapse="\n")

}

ui <- fluidPage(
  titlePanel(h1("Displex user interface")),
  mainPanel(h2("File to process"),
            fileInput("file",
                      "Choose file to load"),
            h2("Model to apply"),
            radioButtons("model", "Model to apply",
                         choices = list("Lopez-Strassburger",
                                        "Avila-Sanchez (Zipf + Additive)")),
            h2(""),
            downloadButton("report", "Generate report"))
)

server <- function(input, output, session) {
  output$report <- downloadHandler(
    filename="report.rmd",
    content = function(file) {
      content = generateInform(input$file, input$model)
      write(content, file=file)
    }
  )
}

shinyApp(ui, server)

# Run the application
source("global.R")
source("ui.R")
source("server.R")
shinyApp(ui, server)

deployApp()

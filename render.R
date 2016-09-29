rmarkdown::render("presentation.Rmd", output_format = "html_document",
  output_file = "index.html")

rmarkdown::render("presentation.Rmd", output_format = "github_document",
  output_file = "README.md")
# Shiny App Server for polyglotr Translation Services

library(shiny)
library(polyglotr)

# Define server logic for the polyglotr translation app
server <- function(input, output, session) {
  
  # Reactive values to store translation results
  values <- reactiveValues(
    translation = NULL,
    detected_language = NULL,
    error_message = NULL
  )
  
  # Language options for different services
  get_language_options <- function(service) {
    switch(service,
      "google" = list(
        # Common language codes - could be enhanced with actual Google supported languages
        "Auto-detect" = "auto", "English" = "en", "Spanish" = "es", "French" = "fr", 
        "German" = "de", "Italian" = "it", "Portuguese" = "pt", "Russian" = "ru",
        "Chinese" = "zh", "Japanese" = "ja", "Korean" = "ko", "Arabic" = "ar",
        "Dutch" = "nl", "Swedish" = "sv", "Norwegian" = "no", "Danish" = "da"
      ),
      "mymemory" = list(
        "Auto-detect" = "auto", "English" = "en", "Spanish" = "es", "French" = "fr",
        "German" = "de", "Italian" = "it", "Portuguese" = "pt", "Russian" = "ru"
      ),
      "pons" = list(
        "English" = "en", "German" = "de", "French" = "fr", "Spanish" = "es",
        "Italian" = "it", "Portuguese" = "pt", "Russian" = "ru", "Polish" = "pl"
      ),
      "linguee" = list(
        "English" = "en", "German" = "de", "French" = "fr", "Spanish" = "es",
        "Italian" = "it", "Portuguese" = "pt", "Russian" = "ru", "Chinese" = "zh"
      ),
      "qcri" = list(
        "English" = "en", "Arabic" = "ar", "Spanish" = "es", "French" = "fr"
      ),
      "apertium" = list(
        "English" = "en", "Spanish" = "es", "French" = "fr", "Catalan" = "ca",
        "Portuguese" = "pt", "Galician" = "gl"
      ),
      "wmcloud" = list(
        "English" = "en", "Spanish" = "es", "French" = "fr", "German" = "de",
        "Italian" = "it", "Portuguese" = "pt"
      )
    )
  }
  
  # Update language choices when service changes
  observeEvent(input$service, {
    lang_options <- get_language_options(input$service)
    
    # Update source language options
    if (input$service %in% c("pons", "linguee")) {
      # Some services don't support auto-detect
      source_options <- lang_options[names(lang_options) != "Auto-detect"]
      selected_source <- "en"
    } else {
      source_options <- lang_options
      selected_source <- "auto"
    }
    
    updateSelectInput(session, "source_lang",
                      choices = source_options,
                      selected = selected_source)
    
    # Update target language options
    updateSelectInput(session, "target_lang",
                      choices = lang_options,
                      selected = "en")
  })
  
  # Language detection
  observeEvent(input$detect_lang, {
    req(input$input_text)
    
    tryCatch({
      detected <- language_detect(input$input_text)
      values$detected_language <- detected
      
      # Update source language if detection is successful
      lang_options <- get_language_options(input$service)
      if (detected %in% lang_options) {
        updateSelectInput(session, "source_lang", selected = detected)
      }
      
    }, error = function(e) {
      values$detected_language <- paste("Error:", e$message)
    })
  })
  
  # Translation function
  translate_text <- function(text, service, source_lang, target_lang, api_key = NULL) {
    switch(service,
      "google" = google_translate(text, target_language = target_lang, source_language = source_lang),
      "mymemory" = mymemory_translate(text, target_language = target_lang, source_language = source_lang),
      "pons" = pons_translate(text, target_language = target_lang, source_language = source_lang),
      "linguee" = {
        # Linguee returns multiple options, we'll take the first one
        result <- linguee_word_translation(text, target_language = target_lang, source_language = source_lang)
        if (length(result) > 0) result[1] else "No translation found"
      },
      "qcri" = {
        if (is.null(api_key) || api_key == "") {
          stop("API key is required for QCRI service")
        }
        langpair <- paste0(source_lang, "-", target_lang)
        qcri_translate_text(text, langpair = langpair, domain = "general", api_key = api_key)
      },
      "apertium" = apertium_translate(text, target_language = target_lang, source_language = source_lang),
      "wmcloud" = wmcloud_translate(text, target_language = target_lang, source_language = source_lang, format = "text"),
      stop("Unknown service")
    )
  }
  
  # Main translation action
  observeEvent(input$translate, {
    req(input$input_text)
    
    # Clear previous results
    values$translation <- NULL
    values$error_message <- NULL
    
    # Show loading message
    values$translation <- "Translating..."
    
    tryCatch({
      result <- translate_text(
        text = input$input_text,
        service = input$service,
        source_lang = input$source_lang,
        target_lang = input$target_lang,
        api_key = input$api_key
      )
      
      values$translation <- result
      
    }, error = function(e) {
      values$error_message <- paste("Translation failed:", e$message)
      values$translation <- NULL
    })
  })
  
  # Output for detected language
  output$detected_lang <- renderText({
    values$detected_language
  })
  
  # Output for translation result
  output$translation_result <- renderUI({
    if (!is.null(values$error_message)) {
      div(style = "color: red;", h5("Error:"), p(values$error_message))
    } else if (!is.null(values$translation)) {
      if (values$translation == "Translating...") {
        div(style = "color: blue;", p(values$translation))
      } else {
        div(style = "color: green; font-size: 16px;", p(values$translation))
      }
    } else {
      p("Click 'Translate' to see the translation here.", style = "color: gray;")
    }
  })
  
  # Service information
  output$service_info <- renderUI({
    service_descriptions <- list(
      "google" = "Google Translate provides fast, neural machine translation for over 100 languages. Supports automatic language detection.",
      "mymemory" = "MyMemory is the world's largest translation memory. Free service with good language coverage and decent quality.",
      "pons" = "PONS offers dictionary-based translations with high accuracy. Particularly good for European languages.",
      "linguee" = "Linguee provides context-aware translations by showing how words are used in real documents and websites.",
      "qcri" = "QCRI (Qatar Computing Research Institute) provides research-quality translations. Requires API key registration.",
      "apertium" = "Apertium is a free, open-source rule-based machine translation platform with focus on related language pairs.",
      "wmcloud" = "Wikimedia Cloud Services provides community-driven translations leveraging Wikipedia's multilingual content."
    )
    
    api_info <- list(
      "qcri" = "Register for a free API key at: https://mt.qcri.org/api/register"
    )
    
    description <- service_descriptions[[input$service]]
    extra_info <- api_info[[input$service]]
    
    div(
      p(description),
      if (!is.null(extra_info)) {
        div(style = "background-color: #e7f3ff; padding: 10px; border-left: 4px solid #2196F3;",
            strong("API Key Required: "), extra_info)
      }
    )
  })
}
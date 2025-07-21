test_that("launch_polyglotr_app function exists and has correct parameters", {
  expect_true(exists("launch_polyglotr_app"))
  
  # Check function arguments
  args <- formals(launch_polyglotr_app)
  expect_true("launch.browser" %in% names(args))
  expect_true("port" %in% names(args))
  expect_true("host" %in% names(args))
  
  # Check default values
  expect_equal(args$launch.browser, TRUE)
  expect_equal(args$port, NULL)
  expect_equal(args$host, "127.0.0.1")
})

test_that("Shiny app files exist", {
  app_dir <- system.file("shiny-app", package = "polyglotr")
  
  # Skip test if package is not installed
  skip_if(app_dir == "", "Package not properly installed")
  
  expect_true(file.exists(file.path(app_dir, "app.R")))
  expect_true(file.exists(file.path(app_dir, "ui.R")))
  expect_true(file.exists(file.path(app_dir, "server.R")))
  expect_true(file.exists(file.path(app_dir, "README.md")))
})
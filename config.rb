###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

# With alternative layout
# page "/path/to/file.html", layout: :otherlayout

# Proxy pages (http://middlemanapp.com/basics/dynamic-pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", locals: {
#  which_fake_page: "Rendering a fake page with a local variable" }

# General configuration

###
# Helpers
###

# Methods defined in the helpers block are available in templates
# helpers do
#   def some_helper
#     "Helping"
#   end
# end

# Build-specific configuration
configure :build do
  # Minify CSS on build
  # activate :minify_css

  # Minify Javascript on build
  # activate :minify_javascript
end

page "/", :layout => "landing"

activate :blog do |blog|
  blog.default_extension = ".md"
  blog.generate_day_pages = false
  blog.generate_month_pages = false
  blog.generate_tag_pages = false
  blog.generate_year_pages = false
  blog.layout = "post"
  blog.paginate = true
  blog.per_page = 5
  blog.permalink = "post/{title}"
  blog.sources = "posts/{year}-{month}-{day}-{title}.html"
end

activate :directory_indexes

activate :external_pipeline,
  name: :gulp,
  command: 'gulp',
  source: ".tmp/dist"

set :markdown_engine, :redcarpet
set :markdown, :fenced_code_blocks => true, :smarty_pants => true

activate :syntax, lexer_options: { :start_inline => true }

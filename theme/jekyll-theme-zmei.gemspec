# Shared look for zmeiresearch.com and blog.zmeiresearch.com.
# Derived from pages-themes/hacker v0.2.0 (CC0, see LICENSE.hacker).
Gem::Specification.new do |s|
  s.name     = "jekyll-theme-zmei"
  s.version  = "1.0.0"
  s.authors  = ["Zmei Research"]
  s.summary  = "Hacker-style Jekyll theme for zmeiresearch.com"
  s.license  = "CC0-1.0"
  s.files    = Dir.glob("{_layouts,_includes,_sass,assets}/**/*")

  s.add_runtime_dependency "jekyll", "~> 4.4"
  s.add_runtime_dependency "jekyll-seo-tag", "~> 2.8"
end

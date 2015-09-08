Pod::Spec.new do |s|
  s.name             = "R"
  s.version          = "0.1.0"
  s.summary          = "a tool to generate resources."
  s.description      = <<-DESC
                      a tools to generate resources. 
                       DESC

  s.homepage         = "https://github.com/mrdaios/R"
  s.license          = 'MIT'
  s.author           = { "mrdaios" => "mrdaios@gmail.com" }
  s.source           = { :git => "https://github.com/mrdaios/R.git", :tag => s.version.to_s }
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.preserve_paths = 'tools/*'
end

Pod::Spec.new do |s|
  s.name         = 'ContextualMenu'
  s.version      = '1.0.1'
  s.summary      = 'A Swift package for creating contextual menus.'
  s.description  = <<-DESC
                   ContextualMenu provides a flexible way to create contextual menus for iOS and Mac Catalyst applications.
                   DESC
  s.homepage     = 'https://github.com/TranHoaiHung/ContextualMenu.git'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Your Name' => 'youremail@example.com' }
  s.source       = { :git => 'https://github.com/TranHoaiHung/ContextualMenu.git', :tag => s.version.to_s }

  s.platform     = :ios, '14.0'

  s.source_files = 'Sources/ContextualMenu/**/*.{swift}'

  s.swift_version = '5.0'
end

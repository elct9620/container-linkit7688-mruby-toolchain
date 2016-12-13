MRuby::Build.new do |conf|
  toolchain :gcc
  conf.gembox 'default'
end

MRuby::CrossBuild.new("lks7688") do |conf|
  toolchain :openwrt
  conf.gembox 'default'
end

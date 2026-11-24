# Run from any directory: ruby _scripts/validate_i18n.rb [--built]
require 'json'
require 'yaml'
require 'cgi'
require 'pathname'
root = Pathname.new(__dir__).parent
data = JSON.parse((root / '_data/i18n.json').read)
products = YAML.safe_load((root / '_data/products.yml').read)
langs = data.fetch('languages')
expected = %w[en ja de fr es pt ru ko zh-Hans zh-Hant]
abort 'Language list differs' unless langs.map { |x| x.fetch('code') } == expected
base = data.fetch('locales').fetch('en')
errors = []
products.each do |p|
  slug = p.fetch('slug')
  src = data.fetch('source')[slug] || {}
  errors << "stale/missing source: #{slug} summary" unless src['summary'] == p['summary']
  errors << "stale/missing source: #{slug} update" unless src['update'] == p['latest_summary']
  (expected - ['en']).each do |code|
    loc = data.fetch('locales').fetch(code)
    errors << "missing #{code} #{slug} summary" if loc.fetch('products', {})[slug].to_s.strip.empty?
    if p['latest_summary'] && loc.fetch('updates', {})[slug].to_s.strip.empty?
      errors << "missing #{code} #{slug} update"
    end
  end
end
langs.each do |language|
  code = language.fetch('code')
  prefix = language.fetch('prefix')
  loc = data.fetch('locales').fetch(code)
  base.each_key { |k| errors << "missing #{code} UI #{k}" if loc[k].to_s.strip.empty? }
  %w[home news].each do |key|
    relative = prefix.sub(%r{^/}, '')
    relative += '/' unless relative.empty?
    relative += 'whats-new/' if key == 'news'
    path = root / (relative + 'index.html')
    errors << "missing/incorrect page #{path}" unless path.file? && path.read.include?("lang: #{code}\ni18n_key: #{key}\n")
    next unless ARGV.include?('--built')
    out = root / '_site' / (relative + 'index.html')
    unless out.file?
      errors << "missing built page #{out}"
      next
    end
    html = out.read
    errors << "wrong lang #{out}" unless html.include?(%(<html lang="#{code}">))
    errors << "unrendered Liquid #{out}" if html.include?('{%') || html.include?('{{')
    suffix = key == 'news' ? '/whats-new/' : '/'
    langs.each do |other|
      href = "https://bitterapple.github.io#{other.fetch('prefix')}#{suffix}"
      errors << "missing alternate #{other['code']} #{out}" unless html.include?(%(hreflang="#{other['code']}" href="#{href}"))
    end
    own_url = "https://bitterapple.github.io#{prefix}#{suffix}"
    errors << "wrong canonical #{out}" unless html.include?(%(rel="canonical" href="#{own_url}"))
    if code != 'en'
      field = key == 'news' ? 'updates' : 'products'
      loc.fetch(field).each do |slug, translation|
        # Jekyll may encode apostrophes as HTML entities; compare decoded text.
        errors << "missing rendered #{code} #{slug} #{field}" unless CGI.unescapeHTML(html).include?(translation)
      end
    end
    products.each do |p|
      next if key == 'news' && !p['latest_summary']
      errors << "missing original product link #{p['slug']} #{out}" unless html.include?(p.fetch('url'))
    end
  end
end
abort errors.join("\n") unless errors.empty?
puts "PASS: #{langs.size} languages, #{products.size} product descriptions, #{products.count { |p| p['latest_summary'] }} update summaries, 20 pages" + (ARGV.include?('--built') ? ' (including rendered HTML)' : ' (source only)')

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
      errors << "missing localized product link #{p['slug']} #{out}" unless html.include?(%(href="#{prefix}#{p.fetch('url')}))
    end
  end
end
support = JSON.parse((root / '_data/i18n_support.json').read)
product_routes = support.fetch('products')
errors << 'Product routes do not match product catalog' unless product_routes.keys.sort == products.map { |p| p.fetch('slug') }.sort
product_routes.each do |slug, info|
  p = products.find { |item| item['slug'] == slug }
  errors << "route does not match catalog #{slug}" unless p && p['url'] == info['path']
  source = root / (info.fetch('path').sub(%r{^/}, '') + 'index.html')
  next unless source.file?
  original = source.read
  info.fetch('downloads').each do |download|
    url = download.fetch('url')
    errors << "download no longer linked by original product page: #{slug} #{url}" unless original.include?(url)
    errors << "missing download route #{url}" unless (root / (url.sub(%r{^/}, '') + 'index.html')).file?
  end
  if info['store'] && !original.include?(info['store'])
    errors << "App Store link changed: #{slug}"
  end
  if info['release'] && !original.match?(/id=["']release-notes["']/)
    errors << "missing original release anchor #{slug}"
  end
end
langs.each do |language|
  code = language.fetch('code')
  prefix = language.fetch('prefix')
  %w[privacy ui].each do |group|
    dict = support.fetch(group)
    dict.fetch('en').each_key { |k| errors << "missing #{group} #{code} #{k}" if dict.fetch(code)[k].to_s.strip.empty? }
  end
  routes = {'privacy' => '/support/privacy/'}
  product_routes.each { |slug, info| routes[slug] = info.fetch('path') }
  routes.each do |slug, suffix|
    path = root / ((prefix + suffix).sub(%r{^/}, '') + 'index.html')
    unless path.file?
      errors << "missing localized route #{path}"
      next
    end
    if code != 'en' || slug == 'privacy'
      errors << "wrong route #{path}" unless path.read.include?("permalink: #{prefix}#{suffix}\n")
    end
    next unless ARGV.include?('--built')
    out = root / '_site' / ((prefix + suffix).sub(%r{^/}, '') + 'index.html')
    unless out.file?
      errors << "missing built route #{out}"
      next
    end
    html = out.read
    errors << "wrong lang #{out}" unless html.include?(%(<html lang="#{code}">))
    langs.each do |other|
      href = "https://bitterapple.github.io#{other.fetch('prefix')}#{suffix}"
      errors << "missing alternate #{href} #{out}" unless html.include?(%(hreflang="#{other['code']}" href="#{href}"))
    end
    expected_canonical = "https://bitterapple.github.io#{prefix}#{suffix}"
    errors << "wrong canonical #{out}" unless html.include?(%(rel="canonical" href="#{expected_canonical}"))
    next if code == 'en' && slug != 'privacy'
    if slug == 'privacy'
      support.fetch('privacy').fetch(code).each do |k, value|
        next if k == 'description'
        errors << "missing privacy #{code} #{k}" unless CGI.unescapeHTML(html).include?(value)
      end
    else
      p = products.find { |item| item['slug'] == slug }
      if html.include?(%(data-i18n-full="#{slug}"))
        full = JSON.parse((root / "_data/i18n_full/#{slug}.json").read)
        translated = full.fetch('locales').fetch(code)
        decoded = CGI.unescapeHTML(html)
        translated.each_with_index do |word, idx|
          errors << "missing rendered full translation #{code} #{slug} #{idx}" unless decoded.include?(word)
        end
        if p['latest_summary']
          errors << "missing full release anchor #{out}" unless html.include?('id="release-notes"')
        end
        product_routes.fetch(slug).fetch('downloads').each do |download|
          errors << "missing full download link #{out} #{download['url']}" unless html.include?(%(href="#{download['url']}"))
        end
        next
      end
      errors << "full translation not rendered #{code} #{slug}" if ARGV.include?('--require-full')
      errors << "missing localized product #{code} #{slug}" unless CGI.unescapeHTML(html).include?(data.fetch('locales').fetch(code).fetch('products').fetch(slug))
      errors << "missing original documentation link #{out}" unless html.include?(%(href="#{suffix}"))
      product_routes.fetch(slug).fetch('downloads').each do |download|
        errors << "missing download link #{out} #{download['url']}" unless html.include?(%(href="#{download['url']}"))
      end
      if p['latest_summary']
        errors << "missing localized release notes #{out}" unless html.include?('id="release-notes"') && CGI.unescapeHTML(html).include?(data.fetch('locales').fetch(code).fetch('updates').fetch(slug))
      end
    end
  end
end
require 'digest'
full_count = 0
missing_full = []
product_routes.each do |slug, info|
  source = root / (info.fetch('path').sub(%r{^/}, '') + 'index.html')
  full_path = root / "_data/i18n_full/#{slug}.json"
  template = root / "_includes/i18n_full/#{slug}.html"
  unless source.file? && full_path.file? && template.file?
    errors << "missing full translation source/template #{slug}"
    next
  end
  bytes = source.binread
  blob = Digest::SHA1.hexdigest("blob #{bytes.bytesize}\0".b + bytes)
  full = JSON.parse(full_path.read)
  errors << "stale full translation source #{slug}: run _scripts/full_i18n.py prepare" unless full['source_blob'] == blob
  p = products.find { |item| item['slug'] == slug }
  errors << "stale full translation summary #{slug}" unless full['source_summary'] == p['summary'] && full['source_update'] == p['latest_summary']
  units = full.fetch('source_units')
  ids = template.read.scan(/full_text\[(\d+)\]/).flatten.map(&:to_i)
  errors << "full template unit mismatch #{slug}" unless ids == (0...units.size).to_a
  (expected - ['en']).each do |code|
    row = full.fetch('locales')[code]
    if row.is_a?(Array) && row.size == units.size && row.all? { |s| s.is_a?(String) && !s.strip.empty? }
      full_count += 1
    else
      missing_full << "#{slug}/#{code}"
    end
  end
end
errors << "Missing full translations: #{missing_full.join(', ')}" if ARGV.include?('--require-full') && !missing_full.empty?
puts "Full documentation: #{full_count}/#{product_routes.size * (expected.size - 1)} translated product/language pairs; #{missing_full.size} remaining"
abort errors.join("\n") unless errors.empty?
puts "PASS: #{langs.size} languages, #{products.size} product descriptions, #{products.count { |p| p['latest_summary'] }} update summaries, 240 home/news/product/privacy pages" + (ARGV.include?('--built') ? ' (including rendered HTML)' : ' (source only)')

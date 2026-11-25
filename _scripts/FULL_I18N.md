# Full product documentation localization

The English pages in support/ remain authoritative. Localized overview pages remain available if a full translation is absent or if its product summary/release snapshot changes.

- _data/i18n_full/<slug>.json contains numbered source text segments, source Git blob SHA, release/summary snapshots, and complete locale rows.
- _includes/i18n_full/<slug>.html preserves the original document markup, images, links, section anchors and code; only text is replaced.
- _includes/i18n-product.html renders a complete translation when available. Otherwise it renders the localized overview and explicitly links to the English documentation.
- All 21 catalog products have full documentation translations in Japanese, German, French, Spanish, Portuguese, Russian, Korean, Simplified Chinese and Traditional Chinese, in addition to the authoritative English pages (189 translated product/language pairs).
- Source coverage, source Git blob hashes, product summary/release snapshots, template segment positions, version numbers and email addresses were checked against the candidate Git tree. A local Jekyll build and review of rendered HTML are still required before publication.
- When an original product page has a latest update but no release-notes section, the localized full page adds the translated catalog update so the news link has a valid target.

After an English product page changes, run:

    python3 _scripts/full_i18n.py prepare
    ruby _scripts/validate_i18n.rb

Prepare reuses unambiguous identical translated text. It does not invoke an external model. Changed text is not marked translated.

To generate missing translations using an installed and authenticated Codex CLI, explicitly run:

    python3 _scripts/full_i18n.py self-test
    python3 _scripts/full_i18n.py translate
    python3 _scripts/full_i18n.py check --require-full
    ruby _scripts/validate_i18n.rb --require-full
    bundle exec jekyll build
    ruby _scripts/validate_i18n.rb --built --require-full

This uses the user's Codex allowance or configured credentials and sends only public product text to the configured model. It resumes from saved completed batches and never commits, pushes, triggers Actions or changes the English source. Review translated technical content before publishing. No runtime translation service is used.

To limit generation, specify --slug and/or --lang. For example:

    python3 _scripts/full_i18n.py translate --slug sourcefield --lang ja

TakeFlow and its workflow guide already have their own localization. RecScript invitation remains a functional deep link endpoint. WrisTick is outside the existing 21-product catalog and is not part of this extraction.

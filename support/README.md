# Support Site

This repository hosts the public support pages for the apps and plug-ins on
`bitterapple.github.io`.

## Deployment

The site now uses GitHub Pages with Jekyll.

- `index.html` is the home page.
- `_data/products.yml` drives the product cards and the "What's New" section.
- `support/<app>/index.html` contains each support page.
- `_layouts/default.html` provides the shared HTML shell.
- `_layouts/support.html` wraps support pages with the shared container and footer.
- `_layouts/redirect.html` handles simple redirect pages.
- `_includes/footer.html` and `_includes/analytics.html` hold shared fragments.
- `_config.yml` contains the GitHub Pages / Jekyll site settings.

## Notes

- Product cards on the home page are generated from each page's front matter.
- The `support/` index redirects to the home page.
- Shared styles still live in `style.css`.

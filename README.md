<!-- # RailsUrlShortener -->

![RailsUrlShortener Banner](banner.png)

[![Ruby on Rails CI](https://github.com/a-chacon/rails-url-shortener/actions/workflows/rubyonrails.yml/badge.svg)](https://github.com/a-chacon/rails-url-shortener/actions/workflows/rubyonrails.yml)
![Gem Version](https://img.shields.io/gem/v/rails_url_shortener)
![GitHub License](https://img.shields.io/github/license/a-chacon/rails_url_shortener)

RailsUrlShortener is a small Rails engine that provides your app with short URL functionality and IP logging capabilities - like having your own Bitly service. By default, RailsUrlShortener saves all visits to your links for future analysis or other interesting uses.

Why give your data to a third-party app when you can manage it yourself?

## Key Features

Here are some of the things you can do with RailsUrlShortener:

* Generate unique keys for links
* Provide a controller method that finds, saves request information, and performs a redirect to the original URL (status code configurable)
* Configurable HTTP redirect status codes (301, 302, 303, 307, 308) per-URL or globally
* Associate short links with models in your app
* Save browser, system, and IP data from each request
* Track query parameters (e.g., `source`, `campaign`) from short URL visits
* Create scheduled links using the starts_at option
* Create temporary short links using the expires_at option
* Pause and unpause links on demand
* Filter URLs by ownership with `owned`, `unowned`, and `active_owned` / `active_unowned` scopes
* Configurable IP geolocation backend with optional API key support
* Extend gem models from your host app with generated extension concerns
* Password-protect individual short URLs with HTTP Basic Auth
* Remove password protection from existing short URLs with `clear_password!`
* Disable visit tracking and IP lookup on a per-URL basis
* Override the global host on a per-URL basis with `custom_host`
* Built-in host constraint to restrict the engine to configured short-link domains
* Block the engine mount root to prevent fall-through to the main app

## Installation

Follow these steps to install and configure rails_url_shortener in your Rails application.

1. Add the Gem
Add the following line to your application's Gemfile:

```ruby
gem "rails_url_shortener"
```

2. Install the Gem
Run the following command to install the gem:

```bash
bundle install
```

3. Run the Generator
Run the generator to set up the necessary files:

```bash
rails generate rails_url_shortener
```

This will:
✅ Install and run the required migrations

✅ Mount the engine
An entry will be added to the bottom of your config/routes.rb file, mounting the engine at the root of your application.

✅ Generate an initializer for further configuration`

## Usage

1. Generate the short link

And generate the short links like you want:

* Using the helper method, this return the ready short link.

```ruby
short_url("https://www.github.com/a-chacon/rails-url-shortener")
```

* Or model method, this return the object built. So you can save this on a variable, extract the key and build the short link by your own:

```ruby
RailsUrlShortener::Url.generate("https://www.github.com/a-chacon/rails-url-shortener")
```

2. Share the short link

**Then share the short link to your users or wherever you want.**

## Deeper

Full params for the short_url helper:

```ruby
short_url(url, owner: nil, kind: nil, key: nil, starts_at: nil, expires_at: nil, paused: false, category: nil, forward_query_params: nil, password: nil, tracked: true, custom_host: nil, redirect_status: nil, url_options: {})
```

Where:

* **url**: The long URL to be shortened
* **owner**: A model from your app to associate with the URL
* **key**: A custom key for the short URL (optional)
* **starts_at**: Scheduled datetime (before which the redirect won't work)
* **expires_at**: Expiration datetime (after which the redirect won't work)
* **paused**: Boolean to pause the URL (overrides starts_at/expires_at, default: false)
* **category**: A tag for categorizing the link
* **forward_query_params**: Override the global `forward_query_params` setting for this URL (`nil` = use global, `true` = always forward, `false` = never forward)
* **password**: A plaintext password to protect the URL with HTTP Basic Auth (stored as a bcrypt digest)
* **tracked**: Boolean to enable/disable visit tracking and IP geolocation for this URL (default: `true`)
* **custom_host**: A logical key that maps to a hostname via `RailsUrlShortener.custom_hosts` (e.g., `'marketing'`). Mapping keys can be strings or symbols. Falls back to `RailsUrlShortener.host` when `nil` or unmapped
* **redirect_status**: HTTP redirect status code (301, 302, 303, 307, 308). When `nil`, uses `RailsUrlShortener.redirect_status` (default: 301)
* **url_options**: Options for the URL generator (e.g., subdomain or protocol)

The `generate` model method accepts the same parameters except for `url_options`:

```ruby
RailsUrlShortener::Url.generate(url, owner: nil, kind: nil, key: nil, starts_at: nil, expires_at: nil, paused: false, category: nil, forward_query_params: nil, password: nil, tracked: true, custom_host: nil, redirect_status: nil)
```

### Data Collection

You can check the current status of any URL:

```ruby
url = RailsUrlShortener::Url.find_by(key: 'abc123')
url.status # => :active, :paused, :upcoming, or :expired
```

You can filter URLs by ownership:

```ruby
RailsUrlShortener::Url.owned          # URLs with an owner
RailsUrlShortener::Url.unowned        # URLs without an owner
RailsUrlShortener::Url.active_owned   # Active URLs with an owner
RailsUrlShortener::Url.active_unowned # Active URLs without an owner
RailsUrlShortener::Url.invalid_owner  # URLs with inconsistent owner data
```

You can append tracking parameters to short URLs:

```ruby
url = RailsUrlShortener::Url.find_by(key: 'abc123')
url.to_short_url(params: { source: 'qr' })        # => "https://host/shortener/abc123?source=qr"
url.to_short_url(params: { source: 'nfc' })       # => "https://host/shortener/abc123?source=nfc"
```

When a user visits a short URL with query parameters, they are automatically logged in the visit record as JSON:

```ruby
visit = RailsUrlShortener::Visit.last
JSON.parse(visit.params) # => { "source" => "qr" }
```

By default, the engine saves all requests made to your short URLs. You can use this data for analytics or IP logging. To access the data:

1. Get visits for a specific URL:

```ruby
RailsUrlShortener::Url.find_url_by_key("key").visits
```

2. Get all visits:

```ruby
RailsUrlShortener::Visit.all
```

Each Visit is associated with an Ipgeo model that contains information about the IP address:

```ruby
RailsUrlShortener::Visit.first.ipgeo
```

### IP Data Collection

When a Visit record is created, a background job is enqueued to fetch IP geolocation data and populate an Ipgeo record.

By default, no IP lookup backend is configured and geolocation lookups are skipped. To enable them, set a backend in the initializer:

```ruby
# Use ipapi.co instead of ip-api.com
RailsUrlShortener.ip_lookup_backend = RailsUrlShortener::IpLookup::IPAPI_CO

# Provide an API key (for paid tiers or providers that require one)
RailsUrlShortener.ip_lookup_api_key = ENV['IP_LOOKUP_API_KEY']
```

Built-in backends:

| Constant                                   | Provider                          | Free tier limit |
|--------------------------------------------|-----------------------------------|-----------------|
| `RailsUrlShortener::IpLookup::IP_API_COM`  | [ip-api.com](https://ip-api.com/) | 45 req/min      |
| `RailsUrlShortener::IpLookup::IPAPI_CO`    | [ipapi.co](https://ipapi.co/)     | 1 000 req/day   |

You can also provide a custom backend — any object that responds to `#call(ip_address, api_key)` and returns a Hash whose keys match the `Ipgeo` column names (underscore-cased strings):

```ruby
RailsUrlShortener.ip_lookup_backend = lambda { |ip_address, api_key|
  provider = 'my-provider.example'
  response = HTTP.get("https://my-provider.example/lookup/#{ip_address}?token=#{api_key}")

  return nil unless response.code == 200

  data = JSON.parse(response.body)
  {
    provider:  provider,
    ip:        ip_address,
    country:   data['country'],
    city:      data['city'],
    latitude:  data['lat'],
    longitude: data['lng'],
    # … any other Ipgeo columns you want to populate
  }
}
```

### Model Integration

You can associate short URLs with your models using the provided `Shortenable` concern.

```ruby
include RailsUrlShortener::Shortenable

has_short_url :guidebook, dependent: :nullify
has_short_urls :promo_links, dependent: :destroy
```

The `:name`

* defines both the association name and the internal `kind` used for grouping URLs

The `dependent` option

* `dependent: :nullify` → Removes ownership but keeps records (default)
* `dependent: :destroy` → Deletes associated short URLs when parent is destroyed
* Any other standard Rails association `dependent` option

### Guidebook example

```ruby
class Accommodation < ApplicationRecord
  include RailsUrlShortener::Shortenable

  has_short_url :guidebook
end
```

```ruby
accommodation = Accommodation.first

accommodation.guidebook # => <RailsUrlShortener::Url>
accommodation.guidebook_short_url # => "https://..."
accommodation.has_guidebook? # => true / false
```

### Promo links example

```ruby
class Campaign < ApplicationRecord
  include RailsUrlShortener::Shortenable

  has_short_urls :promo_links
end
```

```ruby
campaign = Campaign.first

campaign.promo_links            # => [<RailsUrlShortener::Url>, ...]
campaign.promo_links_short_urls # => ["https://...", "https://..."]
campaign.has_promo_links?       # => true / false
```

### Extending Models

You can extend the gem's models (`Url`, `Visit`, `Ipgeo`) from your host application without monkey-patching. Run the extensions generator:

```bash
rails generate rails_url_shortener:extensions
```

This creates concern files in `app/models/concerns/rails_url_shortener/`:

* `url_extension.rb`
* `visit_extension.rb`
* `ipgeo_extension.rb`

The engine automatically includes any defined extension module into its corresponding model. Simply add your custom associations, validations, scopes, and methods to the generated concern:

```ruby
# app/models/concerns/rails_url_shortener/url_extension.rb

module RailsUrlShortener
  module UrlExtension
    extend ActiveSupport::Concern

    included do
      belongs_to :folder, optional: true
      scope :featured, -> { where(featured: true) }
    end

    def custom_title
      "Short link: #{key}"
    end
  end
end
```

No initializer or manual `include` call is needed — the extension is picked up automatically on boot.

### Password Protection

You can password-protect individual short URLs. When a visitor opens a protected link, the browser prompts for a password via HTTP Basic Auth. The username field is ignored — only the password matters.

Create a password-protected short URL:

```ruby
# Via the helper
short_url("https://example.com/secret-doc", password: "s3cret")

# Via the model
RailsUrlShortener::Url.generate("https://example.com/secret-doc", password: "s3cret")
```

The password is stored as a bcrypt digest in the `password_digest` column. You can check whether a URL is protected and verify passwords programmatically:

```ruby
url = RailsUrlShortener::Url.find_by(key: "abc123")
url.password_protected? # => true
url.authenticate("s3cret") # => <Url> (truthy)
url.authenticate("wrong")  # => false
```

You can also remove password protection from an existing URL:

```ruby
url = RailsUrlShortener::Url.find_by(key: "abc123")
url.clear_password!
url.password_protected? # => false
```

When a visitor opens the short link, the browser displays a standard username/password dialog. They can enter anything (or nothing) for the username — only the password is checked. On success, the visitor is redirected as usual. On failure, a 401 Unauthorized response is returned.

### Disabling Tracking

By default, every visit to a short URL creates a `Visit` record and enqueues an IP geolocation lookup job. You can disable this on a per-URL basis by setting `tracked: false`:

```ruby
# Via the helper
short_url("https://example.com/page", tracked: false)

# Via the model
RailsUrlShortener::Url.generate("https://example.com/page", tracked: false)
```

When `tracked` is `false`, no `Visit` record is created and no `IpCrawlerJob` is enqueued — the visitor is simply redirected. This is useful for high-traffic links where you don't need analytics, or for privacy-sensitive URLs.

### Custom Host

By default, all short URLs use the global `RailsUrlShortener.host`. You can serve different short URLs from different domains by assigning a logical `custom_host` key and mapping it to an actual hostname per environment.

First, define the mapping in your initializer:

```ruby
# config/initializers/rails_url_shortener.rb
RailsUrlShortener.custom_hosts = {
  'marketing' => ENV.fetch('MARKETING_SHORT_HOST', 'lvh.me:3000'),
  'support'   => ENV.fetch('SUPPORT_SHORT_HOST', 'lvh.me:3000'),
}
```

String and symbol keys are both supported:

```ruby
RailsUrlShortener.custom_hosts = {
  marketing: ENV.fetch('MARKETING_SHORT_HOST', 'lvh.me:3000'),
  support:   ENV.fetch('SUPPORT_SHORT_HOST', 'lvh.me:3000'),
}
```

Then create URLs with a logical key:

```ruby
# Via the helper
short_url("https://example.com/page", custom_host: "marketing")

# Via the model
url = RailsUrlShortener::Url.generate("https://example.com/page", custom_host: "marketing")
url.to_short_url # => "https://mkt.example.com/shortener/abc123" (in production)
```

The `custom_host` column stores the logical key (`"marketing"`), not an actual hostname. This keeps your database environment-agnostic — the same records work in development (where the key resolves to `lvh.me:3000`) and production (where it resolves to `mkt.example.com`).

If a `custom_host` key is not found in the mapping, or is `nil`/blank, the global `RailsUrlShortener.host` is used as a fallback.

You can also resolve hosts programmatically:

```ruby
RailsUrlShortener.resolve_host('marketing') # => "mkt.example.com"
RailsUrlShortener.resolve_host('unknown')   # => RailsUrlShortener.host (fallback)
RailsUrlShortener.resolve_host(nil)         # => RailsUrlShortener.host (fallback)
```

### Host Constraint

When the engine is mounted at a path like `/` or a catch-all route, requests intended for your main app may accidentally match the shortener. You can restrict the engine to only respond on configured short-link hosts by mounting the engine with `RailsUrlShortener::HostConstraint`:

```ruby
# config/routes.rb
mount RailsUrlShortener::Engine, at: '/', constraints: RailsUrlShortener::HostConstraint
```

With this mount, the engine route only matches requests whose `Host` header matches `RailsUrlShortener.host` or any value in `RailsUrlShortener.custom_hosts`. Requests from other hosts receive a 404.

The allowed hosts are derived automatically from your existing configuration — no need to list them twice:

```ruby
RailsUrlShortener.host = ENV.fetch('SHORT_HOST', 'lvh.me:3000')
RailsUrlShortener.custom_hosts = {
  'gt'  => ENV.fetch('SHORT_HOST_GT', 'lvh.me:3000'),
  'thr' => ENV.fetch('SHORT_HOST_THR', 'lvh.me:3000'),
}

# In production: only short.go-thassos.gr, short.thr.gr serve short URLs
# In development: lvh.me:3000 serves all short URLs
```

The constraint checks both `request.host` and `request.host_with_port`, so hosts configured with ports (e.g., `lvh.me:3000`) work correctly.

### Root Blocking

When the engine is mounted at `/`, a request to the bare root (`GET /`) would otherwise fall through to your main app.
Enable `block_root` to have the engine handle it directly:

```ruby
# config/initializers/rails_url_shortener.rb
RailsUrlShortener.block_root = true
```

The behavior depends on `default_redirect`:

| `default_redirect`                 | Response                  |
|------------------------------------|---------------------------|
| Set (e.g. `'/404'`)                | 302 redirect to that URL  |
| Blank / `nil`                      | 404                       |

This is particularly useful when combined with a constrained mount — together they ensure a dedicated short-link domain never exposes your main app's routes:

```ruby
mount RailsUrlShortener::Engine, at: '/', constraints: RailsUrlShortener::HostConstraint
# config/initializers/rails_url_shortener.rb
RailsUrlShortener.block_root       = true
RailsUrlShortener.default_redirect = '/404'
```

### Redirect Status

By default, short URL redirects use HTTP 301 (Moved Permanently). You can customize this globally or per-URL to use other 30X status codes (302, 303, 307, 308).

Set a global redirect status in your initializer:

```ruby
# config/initializers/rails_url_shortener.rb
RailsUrlShortener.redirect_status = 302  # Found (Temporary)
```

Or override it per-URL:

```ruby
# Via the helper
short_url("https://example.com/page", redirect_status: 307)

# Via the model
RailsUrlShortener::Url.generate("https://example.com/page", redirect_status: 307)
```

Supported redirect codes:
- `301` - Moved Permanently (browser caches the redirect)
- `302` - Found (Temporary redirect, browser doesn't cache)
- `303` - See Other (forces GET on destination)
- `307` - Temporary Redirect (preserves request method)
- `308` - Permanent Redirect (preserves request method)

For Madmin forms, use the `REDIRECT_STATUSES` const:

```ruby
RailsUrlShortener::Url::REDIRECT_STATUSES  # => { 301 => 'Moved Permanently', 302 => 'Found (Temporary)', ... }
```

### Madmin Integration

If you use [Madmin](https://github.com/excid3/madmin) as your admin panel, you can generate resources for the engine's models to manage them from the admin interface.

Generate resources for each model:

```bash
rails g madmin:resource RailsUrlShortener::Url
rails g madmin:resource RailsUrlShortener::Visit
rails g madmin:resource RailsUrlShortener::Ipgeo
```

This creates resource files in `app/madmin/resources/` and registers the routes automatically. You can then customize the generated resource files to control which attributes appear in the index, show, and form views.

### Pundit Integration

If you use [Pundit](https://github.com/varvet/pundit) for authorization, you can generate policy classes for the engine's models:

```bash
rails g pundit:policy rails_url_shortener/url
rails g pundit:policy rails_url_shortener/visit
rails g pundit:policy rails_url_shortener/ipgeo
```

This creates policy files in `app/policies/rails_url_shortener/`:

* `url_policy.rb`
* `visit_policy.rb`
* `ipgeo_policy.rb`

Each policy inherits from `ApplicationPolicy`. Customize the generated policies to match your authorization rules:

```ruby
# app/policies/rails_url_shortener/url_policy.rb

class RailsUrlShortener::UrlPolicy < ApplicationPolicy
  def index?
    user.admin?
  end

  def show?
    true
  end

  def create?
    user.admin?
  end

  def destroy?
    user.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(owner: user)
      end
    end
  end
end
```

Then use Pundit as usual in your controllers:

```ruby
@urls = policy_scope(RailsUrlShortener::Url)
authorize @url
```

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Linting

Run all linters:

```bash
rake lint
```

### Ruby

```bash
rake lint:ruby
```

### Spelling

```bash
rake lint:spelling
```

This runs [cspell](https://cspell.org/) via npx. You'll need Node.js installed.

### Markdown

```bash
rake lint:markdown
```

This runs [markdownlint](https://github.com/DavidAnson/markdownlint) via npx. You'll need Node.js installed.

## Testing

Run the test suite with:

```bash
rake test
```

After running tests, you can view the coverage report by opening `coverage/index.html` in your browser of choice.

## Annotations

This project uses [annotate](https://github.com/ctran/annotate_models) to keep schema information in model files, tests, and fixtures up to date. After running migrations, update the annotations with:

```bash
rake annotate
```

## License

The gem is available as open source under the terms of the [GPL-3.0 License](https://www.github.com/a-chacon/rails-url-shortener/blob/main/LICENSE).

by: [a-chacon](https://a-chacon.com)

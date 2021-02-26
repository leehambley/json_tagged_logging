# JsonTaggedLogging

JSONTaggedLogger is a simple Gem which re-packages [ActiveSupport::TaggedLogging] in a useful way.

When using ActiveSupportTagged like this:

```
ActiveSupport::TaggedLogging.new(ActiveSupport::Logger.new(STDOUT))
```

The logger's formatter will be overwritten to prefix the "tags text" on the beginning of the line; that means even if you configure a JSON log formatter, your tags will be prepended to the log lines. Maybe this is what you want, but there's no way to opt out of it, and it's not what *I* wanted.

## Handling of tags

From the Rails docs, here's how tagged logging works:

```
logger = ActiveSupport::TaggedLogging.new(Logger.new(STDOUT))
logger.tagged("BCX").info "Stuff"                 # Logs "[BCX] Stuff"
logger.tagged("BCX", "Jason").info "Stuff"        # Logs "[BCX] [Jason] Stuff"
logger.tagged("BCX").tagged("Jason").info "Stuff" # Logs "[BCX] [Jason] Stuff"
```

If you have a JSON formatter which wraps `msg` you might be able to get something like:

```
logger.tagged("BCX").info "Stuff" # Logs "[BCX] {"msg":"Stuff}"
```

However what we really want is this:

```
logger.tagged("BCX").info "Stuff" # Logs "{"BCX": "", "msg":"Stuff}"
```

### Different kinds of tags

Rails supports pushing all kinds of things onto the log tags, k/v pairs in hashes, hashes with multiple keys, single symbols with or without special meaning (e.g `:request_id` has a special meaning to a Rack middleware that injects tags, but `:mything` is just a symbol). It's also possible to push a Proc/callable onto the tag list, which the framework will resolve into a list of tags (hashes, symbols, etc) before deferring to the logger.

Because JSON doesn't have a clean way to serialize a single "key" (`:mything`) without a value, here's how things are handled:

```
# Config
dynamic_tags = ->(request) do
  [{a: "b"}, {c: "d", "e" => "f"}]
end
Rails.application.configure do 
  config.log_tags = [:mything, :request_id, dynamic_tags]
end
logger.tagged("BCX").info "Stuff" 
```

Will log something like:

```
{
  "msg": "Stuff", 
  "mything": "",    # note key with no value for any simple :mything tags
  "request_id": "d6b18dea-5067-45cc-ba43-969922c976d7", 
  "a": "b", 
  "c": "d", 
  "e": "f"
}
```

## Interoperability with lograge (and others?)

[Lograge](https://github.com/roidrage/lograge) hooks into ActionController logs and rewrites the usual controller logs:

```
...
  Rendered layouts/_assets.html.erb (2.0ms)
  Rendered layouts/_top.html.erb (2.6ms)
  Rendered layouts/_about.html.erb (0.3ms)
  Rendered layouts/_google_analytics.html.erb (0.4ms)
Completed 200 OK in 79ms (Views: 78.8ms | ActiveRecord: 0.0ms)
```

in a way that looks like this:

```
method=GET path=/jobs/833552.json format=json controller=JobsController  action=show status=200 duration=58.33 view=40.43 db=15.26
```

They also have a JSON formatter which makes their logs look like this:

```
{"method":"GET", "path":"/jobs/833552.json", "format":"JSON"...}
```

This interacts poorly with other loggers, because the `msg` those loggers are asked to serialize is _already_ JSON.

This means naïvely the incoming `msg` from lograge would be printed as escaped JSON inside the `msg` field of the lines from this library, that's probably not what we want, so we check if we can decode JSON in the `msg`. Then merge the new hash of tags in.

## Usage

Somewhere in your Rails app set-up do this:

```
Rails.logger = JSONTaggedLogging.new(ActiveSupport::Logger.new(STDOUT))
```

## Gem Packaging

This gem is not published on rubygems.org. It's open source to comply with the license requirements of MIT and being a good citizen, but I don't intend to support it except for my employer, and I can't recommend that you use it.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT). This is a propagation of the Rails licence. This bulk of this code is lifted verbatim from ActiveSupport.

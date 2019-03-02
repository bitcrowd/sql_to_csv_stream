# SqlToCsvStream

This is your favorite gem to produce CSV or JSON directly from SQL queries.
It queries a PostgreSQL with a [`COPY`](https://www.postgresql.org/docs/current/sql-copy.html) statement and streams the result as CSV/JSON directly into a ruby enumerator.

This gem can be used in all ruby applications, but ships with a special renderer for Rails to easily render downloads from your rails controller.

Note: This is project is still in a proof-of-concept phase. We may rename some things, make the code more readable and very likely add some tests :)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sql_to_csv_stream'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sql_to_csv_stream

If you use rails, you may register the new stream renderers in an initializer.

```ruby
require 'sql_to_csv_stream'

SqlToCsvStream.register_rails_renderer
```

## Usage

In Rails, you can use the stream renderer from a Controller:

```ruby
class UsersController < ApplicationController
  def index
    @users = User.all.where(deleted_at: null)

    respond_to do |format|
      format.csv do
        render csv_stream: @users, filename: 'users.csv'
      end
      format.json do
        render json_stream: @users, filename: 'users.json'
      end
    end
  end
end
```

This, unlike many other CSV/JSON rendering techniques, instantly sends results to the user by streaming the content while it is being generated.
This is light on memory. By streaming the data instantly, even large files (that need longer to generate than the HTTP server connection timeout value) can be produced without the connection being interrupted by a connection timeout.

The streaming renderer automatically responds with a gzipped encoding if the client accepts it. This drastically reduces file sizes we need to send over the wire.

Any SQL string the PostgreSQL [`COPY` command](https://www.postgresql.org/docs/current/sql-copy.html) accepts can be given to the renderer.
Alternatively, any object may be given that produces such SQL on `.to_sql` or `to_s`.
So you can use your favorite query-object pattern :)

If you are not in Rails or want to process CSV/JSON in any other way from within Rails, you can use the `Stream` classes.

```ruby
file = File.open('users.csv', 'w')
SqlToCsvStream::CsvStream.new('SELECT * FROM users;').each do |csv_row|
  file.write
end
file.close
```

Or write the compressed file with:

```ruby
file = File.open('users.csv.gz', 'w')
SqlToCsvStream::CsvStream.new('SELECT * FROM users;', use_gzip: true).each do |csv_row|
  file.write
end
file.close
```

Writing a JSON file works similarly:

```ruby
file = File.open('users.json', 'w')
SqlToCsvStream::JsonStream.new('SELECT * FROM users;').each do |csv_row|
  file.write
end
file.close
```

For more options, see the class documentation of the `CsvStream` or `JsonStream` class.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tessi/sql_to_csv_stream. New feature ideas are welcome too -- please present your ideas in an issue first so we can together discuss whether this idea fits into the scope of this project.
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the SqlToCsvStream project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/tessi/sql_to_csv_stream/blob/master/CODE_OF_CONDUCT.md).

## Previous work

We didn't invent streaming, nor did we were the first to have the idea to integrate this in ruby and/or rails. Some previous approaches are described [here](https://shift.infinite.red/fast-csv-report-generation-with-postgres-in-rails-d444d9b915ab), [here](https://www.smartly.io/blog/streaming-data-with-ruby-enumerators), [here](https://medium.com/table-xi/stream-csv-files-in-rails-because-you-can-46c212159ab7), or [here](https://gist.github.com/stereoscott/6996507). We are thankful for the previous work done which led us into the right direction and enabled us to (hopefully) improve upon it.

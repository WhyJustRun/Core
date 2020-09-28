FROM ruby:2.5
RUN apt-get update -qq && apt-get install -y nodejs
RUN mkdir /application
WORKDIR /application
COPY Gemfile /application/Gemfile
COPY Gemfile.lock /application/Gemfile.lock
RUN bundle install

# Add a script to be executed every time the container starts.
COPY docker-entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
EXPOSE 3000

# Start the main process.
CMD ["rails", "server", "-b", "0.0.0.0"]
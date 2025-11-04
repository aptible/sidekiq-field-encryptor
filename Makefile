lint:
	bundle exec rubocop

test:
	bundle exec rspec

all: lint test
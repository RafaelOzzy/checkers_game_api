Checkers Game API
This is a Checkers game API built with Ruby on Rails. The API allows players to create and join games, move pieces, and check the game status.

Requirements
Ruby 3.1.0
Rails 7.0
PostgreSQL
Node.js
Yarn

Setup
Follow these steps to set up the project on your local machine:

1. Clone the repository

git clone https://github.com/yourusername/checkers_game_api.git
cd checkers_game_api

2. Install dependencies
Ensure you have the correct versions of Ruby and Rails installed. You can use tools like rbenv or rvm to manage Ruby versions.

rbenv install 3.1.0
rbenv global 3.1.0
gem install bundler
bundle install

3. Set up the database
Ensure you have PostgreSQL installed and running. Create the database and run migrations:

rails db:create
rails db:migrate

4. Install JavaScript dependencies
Ensure you have Node.js and Yarn installed. Install JavaScript dependencies:

yarn install

5. Run the server
Start the Rails server:

rails server

By default, the server will run at http://localhost:3000.

Running Tests
To run the test suite, execute:

bundle exec rspec

This project uses RSpec for unit and integration testing.

API Endpoints
Here are the main endpoints available in the API:

POST /games - Create a new game
POST /games/:id/join - Join an existing game
GET /games/:id/status - Get the status of the game
GET /games/:id/pieces - Get the pieces of the game
GET /games/:id/moves/:piece_id - Get possible moves for a piece
POST /games/:id/move - Move a piece

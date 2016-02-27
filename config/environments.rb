# THe environment variable DATABASE_URL should be in the following format:
# => postgres://{user}:{password}@{host}:{port}/path

configure :production, :development do
  db = URI.parse(ENV['DATABASE_URL'] || 'postgres://localhost/mydb') 

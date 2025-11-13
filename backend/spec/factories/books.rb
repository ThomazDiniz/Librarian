FactoryBot.define do
  factory :book do
    title { Faker::Book.title }
    author { Faker::Book.author }
    genre { Faker::Book.genre }
    sequence(:isbn) { |n| "978030#{format('%06d', n)}" }
    total_copies { 2 }
    description { Faker::Lorem.paragraph }
  end
end

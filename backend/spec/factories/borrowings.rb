FactoryBot.define do
  factory :borrowing do
    association :user
    association :book
    borrowed_at { Time.current }
    due_at { 2.weeks.from_now }
    returned_at { nil }

    trait :returned do
      returned_at { 1.day.ago }
    end

    trait :overdue do
      borrowed_at { 3.weeks.ago }
      due_at { 1.week.ago }
    end
  end
end

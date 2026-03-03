# frozen_string_literal: true

# Interactive Form - Huh Forms Example
#
# Demonstrates building interactive forms with validation
# using the Huh library.
#
# Run: ruby interactive-form.rb
#
# Note: Requires huh gem from GitHub:
#   gem "huh", github: "marcoroth/huh-ruby"

require "huh"

# Create a multi-step user registration form
form = Huh::Form.new(theme: :charm) do |f|
  # Step 1: Basic Information
  f.group do |g|
    g.note :welcome,
      title: "👋 Welcome!",
      description: "Let's set up your account. Press Enter to continue."

    g.input :name,
      title: "What's your name?",
      placeholder: "John Doe",
      validate: ->(v) {
        return "Name is required" if v.strip.empty?
        return "Name must be at least 2 characters" if v.strip.length < 2
        nil
      }

    g.input :email,
      title: "Email address",
      placeholder: "you@example.com",
      validate: ->(v) {
        return "Email is required" if v.strip.empty?
        return "Please enter a valid email" unless v.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
        nil
      }
  end

  # Step 2: Account Type
  f.group do |g|
    g.select :account_type,
      title: "What type of account?",
      options: [
        { value: "personal", label: "Personal", description: "For individual use" },
        { value: "team", label: "Team", description: "For small teams (2-10 people)" },
        { value: "enterprise", label: "Enterprise", description: "For large organizations" }
      ]

    g.select :role,
      title: "What's your primary role?",
      options: %w[Developer Designer Manager Other]
  end

  # Step 3: Preferences
  f.group do |g|
    g.multi_select :features,
      title: "Which features interest you?",
      options: [
        { value: "api", label: "API Access" },
        { value: "analytics", label: "Analytics Dashboard" },
        { value: "export", label: "Data Export" },
        { value: "integrations", label: "Third-party Integrations" },
        { value: "support", label: "Priority Support" }
      ],
      min: 1

    g.confirm :newsletter,
      title: "Subscribe to our newsletter?",
      affirmative: "Yes, keep me updated",
      negative: "No thanks"
  end

  # Step 4: Confirmation
  f.group do |g|
    g.confirm :terms,
      title: "Do you agree to the Terms of Service?",
      affirmative: "I agree",
      negative: "I don't agree"
  end
end

# Run the form
puts "\n"
result = form.run

if result.cancelled?
  puts "\n❌ Registration cancelled.\n\n"
  exit 1
end

unless result[:terms]
  puts "\n❌ You must agree to the Terms of Service.\n\n"
  exit 1
end

# Display results
puts <<~RESULT

  ✅ Registration Complete!

  Name:         #{result[:name]}
  Email:        #{result[:email]}
  Account Type: #{result[:account_type].capitalize}
  Role:         #{result[:role]}
  Features:     #{result[:features].join(", ")}
  Newsletter:   #{result[:newsletter] ? "Yes" : "No"}

RESULT
